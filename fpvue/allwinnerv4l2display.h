#ifndef FPVUE_ALLWINNERV4L2DISPLAY_H
#define FPVUE_ALLWINNERV4L2DISPLAY_H

#include <atomic>
#include <thread>
#include <vector>

extern "C" {
#include "rtp.h"
#include "drm.h"
}

/**
 * Experimental display path for Allwinner A733 devices.
 * This class receives RTP frames on a UDP port, decodes them using
 * the V4L2 stateless decoder and presents the frames on a KMS plane
 * driven by the sunxi-drm driver.
 */
class AllwinnerV4L2Display {
public:
  AllwinnerV4L2Display(int udp_port, bool h265);
  ~AllwinnerV4L2Display();

  // Start the decoding/ display thread. Returns true on success.
  bool start();
  void stop();

private:
  bool setup_network();
  bool setup_drm();
  bool setup_v4l2();
  void decode_loop();

  int m_port;
  bool m_h265;

  std::atomic<bool> m_running{false};
  std::thread m_thread;

  int m_sock{-1};
  int m_v4l2_fd{-1};
  int m_drm_fd{-1};

  struct modeset_output m_output{};

  std::vector<void*> m_output_buffers;
  std::vector<void*> m_capture_buffers;
  std::vector<int> m_capture_fbs;
};

#endif // FPVUE_ALLWINNERV4L2DISPLAY_H
