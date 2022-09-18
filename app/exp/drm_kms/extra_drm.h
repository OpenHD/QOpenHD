//
// Created by consti10 on 01.03.22.
//

#ifndef HELLO_DRMPRIME_EXTRA_DRM_H
#define HELLO_DRMPRIME_EXTRA_DRM_H

#include <xf86drm.h>
#include <xf86drmMode.h>
/*#include <cstdio>
#include <string>
#include <sys/mman.h>*/

#define Xmemclear(s) memset(&s, 0, sizeof(s))

static inline int XDRM_IOCTL(int fd, unsigned long cmd, void *arg)
{
    int ret = drmIoctl(fd, cmd, arg);
    return ret < 0 ? -errno : ret;
}

static int XdrmModeSetPlane(int fd, uint32_t plane_id, uint32_t crtc_id,
                            uint32_t fb_id, uint32_t flags,
                            int32_t crtc_x, int32_t crtc_y,
                            uint32_t crtc_w, uint32_t crtc_h,
                            uint32_t src_x, uint32_t src_y,
                            uint32_t src_w, uint32_t src_h)
{
    struct drm_mode_set_plane s{};
    Xmemclear(s);
    s.plane_id = plane_id;
    s.crtc_id = crtc_id;
    s.fb_id = fb_id;
    s.flags = flags;
    s.crtc_x = crtc_x;
    s.crtc_y = crtc_y;
    s.crtc_w = crtc_w;
    s.crtc_h = crtc_h;
    s.src_x = src_x;
    s.src_y = src_y;
    s.src_w = src_w;
    s.src_h = src_h;
    return XDRM_IOCTL(fd, DRM_IOCTL_MODE_SETPLANE, &s);
}

// frm librepi
static std::string connectorTypeToStr(uint32_t type) {
  switch (type) {
	case DRM_MODE_CONNECTOR_HDMIA: // 11
	  return "HDMIA";
	case DRM_MODE_CONNECTOR_DSI: // 16
	  return "DSI";
  }
  return "unknown";
}

static void printDrmModes(int fd) {
  drmVersionPtr version = drmGetVersion(fd);
  printf("version %d.%d.%d\nname: %s\ndate: %s\ndescription: %s\n", version->version_major, version->version_minor, version->version_patchlevel, version->name, version->date, version->desc);
  drmFreeVersion(version);
  drmModeRes * modes = drmModeGetResources(fd);
  for (int i=0; i < modes->count_fbs; i++) {
	printf("FB#%d: %x\n", i, modes->fbs[i]);
  }
  for (int i=0; i < modes->count_crtcs; i++) {
	printf("CRTC#%d: %d\n", i, modes->crtcs[i]);
	drmModeCrtcPtr crtc = drmModeGetCrtc(fd, modes->crtcs[i]);
	printf("  buffer_id: %d\n", crtc->buffer_id);
	printf("  position: %dx%d\n", crtc->x, crtc->y);
	printf("  size: %dx%d\n", crtc->width, crtc->height);
	printf("  mode_valid: %d\n", crtc->mode_valid);
	printf("  gamma_size: %d\n", crtc->gamma_size);
	printf("  Mode\n    clock: %d\n", crtc->mode.clock);
	drmModeModeInfo &mode = crtc->mode;
	printf("    h timings: %d %d %d %d %d\n", mode.hdisplay, mode.hsync_start, mode.hsync_end, mode.htotal, mode.hskew);
	printf("    v timings: %d %d %d %d %d\n", mode.vdisplay, mode.vsync_start, mode.vsync_end, mode.vtotal, mode.vscan);
	printf("    vrefresh: %d\n", mode.vrefresh);
	printf("    flags: 0x%x\n", mode.flags);
	printf("    type: %d\n", mode.type);
	printf("    name: %s\n", mode.name);
	drmModeFreeCrtc(crtc);
  }
  for (int i=0; i < modes->count_connectors; i++) {
	printf("Connector#%d: %d\n", i, modes->connectors[i]);
	drmModeConnectorPtr connector = drmModeGetConnector(fd, modes->connectors[i]);
	if (connector->connection == DRM_MODE_CONNECTED) puts("  connected!");
	std::string typeStr = connectorTypeToStr(connector->connector_type);
	printf("  ID: %d\n  Encoder: %d\n  Type: %d %s\n  type_id: %d\n  physical size: %dx%d\n", connector->connector_id, connector->encoder_id, connector->connector_type, typeStr.c_str(), connector->connector_type_id, connector->mmWidth, connector->mmHeight);
	for (int j=0; j < connector->count_encoders; j++) {
	  printf("  Encoder#%d:\n", j);
	  drmModeEncoderPtr enc = drmModeGetEncoder(fd, connector->encoders[j]);
	  printf("    ID: %d\n    Type: %d\n    CRTCs: 0x%x\n    Clones: 0x%x\n", enc->encoder_id, enc->encoder_type, enc->possible_crtcs, enc->possible_clones);
	  drmModeFreeEncoder(enc);
	}
	printf("  Modes: %d\n", connector->count_modes);
	for (int j=0; j < connector->count_modes; j++) {
	  printf("  Mode#%d:\n", j);
	  if (j > 1) break;
	  drmModeModeInfo &mode = connector->modes[j];
	  printf("    clock: %d\n", mode.clock);
	  printf("    h timings: %d %d %d %d %d\n", mode.hdisplay, mode.hsync_start, mode.hsync_end, mode.htotal, mode.hskew);
	  printf("    v timings: %d %d %d %d %d\n", mode.vdisplay, mode.vsync_start, mode.vsync_end, mode.vtotal, mode.vscan);
	  printf("    vrefresh: %d\n", mode.vrefresh);
	  printf("    flags: 0x%x\n", mode.flags);
	  printf("    type: %d\n", mode.type);
	  printf("    name: %s\n", mode.name);
	}
	drmModeFreeConnector(connector);
  }
  for (int i=0; i < modes->count_encoders; i++) {
	printf("Encoder#%d: %d\n", i, modes->encoders[i]);
  }
  printf("min size: %dx%d\n", modes->min_width, modes->min_height);
  printf("max size: %dx%d\n", modes->max_width, modes->max_height);
  drmModeFreeResources(modes);
}

#endif //HELLO_DRMPRIME_EXTRA_DRM_H
