#include "allwinnerv4l2display.h"

#include <arpa/inet.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>
#include <cstring>
#include <iostream>
#include <vector>

namespace {
constexpr int kVideoWidth = 1280;
constexpr int kVideoHeight = 720;
constexpr int kOutputBuffers = 4;
constexpr int kCaptureBuffers = 4;
}

AllwinnerV4L2Display::AllwinnerV4L2Display(int udp_port, bool h265)
    : m_port(udp_port), m_h265(h265) {}

AllwinnerV4L2Display::~AllwinnerV4L2Display() { stop(); }

bool AllwinnerV4L2Display::start() {
  if (!setup_network()) {
    std::cerr << "Failed to setup network" << std::endl;
    return false;
  }
  if (!setup_drm()) {
    std::cerr << "Failed to setup DRM" << std::endl;
    return false;
  }
  if (!setup_v4l2()) {
    std::cerr << "Failed to setup V4L2" << std::endl;
    return false;
  }
  m_running = true;
  m_thread = std::thread(&AllwinnerV4L2Display::decode_loop, this);
  return true;
}

void AllwinnerV4L2Display::stop() {
  if (!m_running) return;
  m_running = false;
  if (m_thread.joinable()) m_thread.join();

  if (m_sock >= 0) {
    close(m_sock);
    m_sock = -1;
  }
  if (m_v4l2_fd >= 0) {
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    ioctl(m_v4l2_fd, VIDIOC_STREAMOFF, &type);
    type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    ioctl(m_v4l2_fd, VIDIOC_STREAMOFF, &type);
    close(m_v4l2_fd);
    m_v4l2_fd = -1;
  }
  if (m_drm_fd >= 0) {
    modeset_cleanup(m_drm_fd, &m_output);
    close(m_drm_fd);
    m_drm_fd = -1;
  }
}

bool AllwinnerV4L2Display::setup_network() {
  m_sock = socket(AF_INET, SOCK_DGRAM, 0);
  if (m_sock < 0) {
    perror("socket");
    return false;
  }
  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(m_port);
  addr.sin_addr.s_addr = INADDR_ANY;
  if (bind(m_sock, (sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("bind");
    return false;
  }
  return true;
}

bool AllwinnerV4L2Display::setup_drm() {
  if (modeset_open(&m_drm_fd, "/dev/dri/card0") < 0) return false;
  if (modeset_prepare(m_drm_fd, &m_output, kVideoWidth, kVideoHeight, 60) <
      0)
    return false;
  return true;
}

bool AllwinnerV4L2Display::setup_v4l2() {
  m_v4l2_fd = open("/dev/video0", O_RDWR | O_NONBLOCK);
  if (m_v4l2_fd < 0) {
    perror("open v4l2");
    return false;
  }

  struct v4l2_format fmt;
  memset(&fmt, 0, sizeof(fmt));
  fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
  fmt.fmt.pix_mp.width = kVideoWidth;
  fmt.fmt.pix_mp.height = kVideoHeight;
  fmt.fmt.pix_mp.pixelformat =
      m_h265 ? V4L2_PIX_FMT_HEVC_SLICE : V4L2_PIX_FMT_H264_SLICE;
  fmt.fmt.pix_mp.num_planes = 1;
  if (ioctl(m_v4l2_fd, VIDIOC_S_FMT, &fmt) < 0) {
    perror("S_FMT output");
    return false;
  }

  memset(&fmt, 0, sizeof(fmt));
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
  fmt.fmt.pix_mp.width = kVideoWidth;
  fmt.fmt.pix_mp.height = kVideoHeight;
  fmt.fmt.pix_mp.pixelformat = V4L2_PIX_FMT_NV12M;
  fmt.fmt.pix_mp.num_planes = 2;
  if (ioctl(m_v4l2_fd, VIDIOC_S_FMT, &fmt) < 0) {
    perror("S_FMT capture");
    return false;
  }

  struct v4l2_requestbuffers req;
  memset(&req, 0, sizeof(req));
  req.count = kOutputBuffers;
  req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
  req.memory = V4L2_MEMORY_MMAP;
  if (ioctl(m_v4l2_fd, VIDIOC_REQBUFS, &req) < 0) {
    perror("REQBUFS output");
    return false;
  }
  m_output_buffers.resize(req.count);
  for (uint32_t i = 0; i < req.count; ++i) {
    struct v4l2_buffer buf;
    struct v4l2_plane planes[1];
    memset(&buf, 0, sizeof(buf));
    memset(planes, 0, sizeof(planes));
    buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    buf.length = 1;
    buf.m.planes = planes;
    if (ioctl(m_v4l2_fd, VIDIOC_QUERYBUF, &buf) < 0) {
      perror("QUERYBUF output");
      return false;
    }
    void *ptr = mmap(NULL, buf.m.planes[0].length, PROT_READ | PROT_WRITE,
                     MAP_SHARED, m_v4l2_fd, buf.m.planes[0].m.mem_offset);
    if (ptr == MAP_FAILED) {
      perror("mmap output");
      return false;
    }
    m_output_buffers[i] = ptr;
  }

  memset(&req, 0, sizeof(req));
  req.count = kCaptureBuffers;
  req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
  req.memory = V4L2_MEMORY_MMAP;
  if (ioctl(m_v4l2_fd, VIDIOC_REQBUFS, &req) < 0) {
    perror("REQBUFS capture");
    return false;
  }
  m_capture_buffers.resize(req.count);
  m_capture_fbs.resize(req.count);
  for (uint32_t i = 0; i < req.count; ++i) {
    struct v4l2_buffer buf;
    struct v4l2_plane planes[2];
    memset(&buf, 0, sizeof(buf));
    memset(planes, 0, sizeof(planes));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    buf.length = 2;
    buf.m.planes = planes;
    if (ioctl(m_v4l2_fd, VIDIOC_QUERYBUF, &buf) < 0) {
      perror("QUERYBUF capture");
      return false;
    }
    for (int p = 0; p < 2; ++p) {
      void *ptr =
          mmap(NULL, buf.m.planes[p].length, PROT_READ | PROT_WRITE, MAP_SHARED,
               m_v4l2_fd, buf.m.planes[p].m.mem_offset);
      if (ptr == MAP_FAILED) {
        perror("mmap capture");
        return false;
      }
      if (p == 0) m_capture_buffers[i] = ptr;
    }
    struct v4l2_exportbuffer expbuf;
    memset(&expbuf, 0, sizeof(expbuf));
    expbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    expbuf.index = i;
    expbuf.plane = 0;
    if (ioctl(m_v4l2_fd, VIDIOC_EXPBUF, &expbuf) < 0) {
      perror("EXPBUF");
      return false;
    }
    int prime_fd = expbuf.fd;
    uint32_t handles[4] = {};
    if (drmPrimeFDToHandle(m_drm_fd, prime_fd, &handles[0]) != 0) {
      perror("drmPrimeFDToHandle");
      close(prime_fd);
      return false;
    }
    uint32_t pitches[4] = {fmt.fmt.pix_mp.plane_fmt[0].bytesperline,
                           fmt.fmt.pix_mp.plane_fmt[1].bytesperline, 0, 0};
    uint32_t offsets[4] = {planes[0].data_offset, planes[1].data_offset, 0, 0};
    uint32_t fb_id = 0;
    if (drmModeAddFB2(m_drm_fd, kVideoWidth, kVideoHeight, DRM_FORMAT_NV12,
                      handles, pitches, offsets, &fb_id, 0) != 0) {
      perror("AddFB2");
      close(prime_fd);
      return false;
    }
    m_capture_fbs[i] = fb_id;
    close(prime_fd);

    if (ioctl(m_v4l2_fd, VIDIOC_QBUF, &buf) < 0) {
      perror("QBUF capture");
      return false;
    }
  }

  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
  ioctl(m_v4l2_fd, VIDIOC_STREAMON, &type);
  type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
  ioctl(m_v4l2_fd, VIDIOC_STREAMON, &type);
  return true;
}

void AllwinnerV4L2Display::decode_loop() {
  std::vector<uint8_t> rx_buffer(4096 + 8);
  std::vector<uint8_t> nal_buffer(1024 * 1024);
  uint32_t output_index = 0;

  while (m_running) {
    ssize_t rx = recv(m_sock, rx_buffer.data(), rx_buffer.size(), 0);
    if (rx <= 0) continue;
    uint32_t nal_size = 0;
    uint8_t *nal =
        decode_frame(rx_buffer.data(), rx, 0, nal_buffer.data(), &nal_size);
    if (!nal) continue;

    struct v4l2_buffer obuf;
    struct v4l2_plane oplanes[1];
    memset(&obuf, 0, sizeof(obuf));
    memset(oplanes, 0, sizeof(oplanes));
    obuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    obuf.memory = V4L2_MEMORY_MMAP;
    obuf.index = output_index;
    obuf.length = 1;
    obuf.m.planes = oplanes;
    oplanes[0].bytesused = nal_size;
    memcpy(m_output_buffers[output_index], nal, nal_size);
    if (ioctl(m_v4l2_fd, VIDIOC_QBUF, &obuf) < 0) {
      perror("QBUF output");
    }
    output_index = (output_index + 1) % m_output_buffers.size();

    struct v4l2_buffer cbuf;
    struct v4l2_plane cplanes[2];
    memset(&cbuf, 0, sizeof(cbuf));
    memset(cplanes, 0, sizeof(cplanes));
    cbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    cbuf.memory = V4L2_MEMORY_MMAP;
    cbuf.length = 2;
    cbuf.m.planes = cplanes;
    if (ioctl(m_v4l2_fd, VIDIOC_DQBUF, &cbuf) == 0) {
      int fb_id = m_capture_fbs[cbuf.index];
      extra_modeset_set_fb(m_drm_fd, &m_output, &m_output.video_plane, fb_id);
      ioctl(m_v4l2_fd, VIDIOC_QBUF, &cbuf);
    }

    if (ioctl(m_v4l2_fd, VIDIOC_DQBUF, &obuf) == 0) {
      // reuse output buffer
    }
  }
}

