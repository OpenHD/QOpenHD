#ifndef CONSTI10_DRMPRIME_OUT
#define CONSTI10_DRMPRIME_OUT

struct AVFrame;

#include <memory>
#include <stdio.h>
#include <stdlib.h>

#include <xf86drm.h>
#include <xf86drmMode.h>

extern "C" {
#include "libavutil/frame.h"
#include "libavutil/hwcontext.h"
#include "libavutil/hwcontext_drm.h"
#include "libavutil/pixdesc.h"
}

#include "../../common_consti/ThreadsafeQueue.hpp"
#include "MMapFrame.h"
#include <memory>
#include <thread>

class AVFrameHolder{
public:
    AVFrameHolder(AVFrame* f):frame(f){};
    ~AVFrameHolder(){
        //av_frame_free(f)
    };
    AVFrame* frame;
};

// Uses DRM Prime, kms / drm to display HW video frames
// requires to be run without XServer, otherwise we cannot become drm master
class DRMPrimeOut{
public:
    explicit DRMPrimeOut(int renderMode,bool drm_add_dummy_overlay,bool use_page_flip_on_second_frame);
    ~DRMPrimeOut();
    /**
     * Display this frame via drm prime. Depending on the rendering mode,
     * the flow is different, but in general, this pushes the frame into a queue
     * to be picked up by the display thread.
     * @param frame the frame to display
     */
    int queue_new_frame_for_display(struct AVFrame * src_frame);

    // --------
    struct drm_setup{
        int conId;
        uint32_t crtcId;
        int crtcIdx;
        uint32_t planeId;
        unsigned int out_format;// aka the video frame's format
        struct{
            int x, y, width, height;
        } compose;
    };
    struct drm_aux{
        unsigned int fb_id=0;
        // buffer out handles - set to the drm prime handles of the frame
        uint32_t bo_handles[AV_DRM_MAX_PLANES];
        AVFrame *frame= nullptr;
		// only used for CPU copy approach
        std::unique_ptr<MMapFrame> mappedFrame= nullptr;
    };
    // --------
    int drm_fd;
    uint32_t con_id;
    struct drm_setup setup{};
    enum AVPixelFormat avfmt;
    // multiple (frame buffer?) objects such that we can create a new one without worrying about the last one still in use.
    unsigned int ano=0;
    // Aux size should only need to be 2, but on a few streams (Hobbit) under FKMS
    // we get initial flicker probably due to dodgy drm timing
    static constexpr auto AUX_SIZE=5;
    drm_aux aux[AUX_SIZE];
    // the thread hat handles the drm display update, decoupled from decoder thread
	std::unique_ptr<std::thread> q_thread=nullptr;
    bool terminate=false;
    // used when frame drops are not wanted, aka how the original implementation was done
    std::unique_ptr<ThreadsafeSingleBuffer<AVFrame*>> sbQueue;
    // allows frame drops (higher video fps than display refresh).
    std::unique_ptr<ThreadsafeQueue<AVFrameHolder>> queue;
    // extra
    const int renderMode=0;
	const bool m_drm_add_dummy_overlay;
	const bool m_use_page_flip_on_second_frame;
	// hacky testing begin, from drm-howto -----------------------------------------------------------
	struct ModesetBuff {
	  uint32_t width;
	  uint32_t height;
	  uint32_t stride;
	  uint32_t size;
	  uint32_t handle;
	  uint8_t *map;
	  uint32_t fb;
	};
	// Adds a dummy RGBA plane that overlays the video - this so far serves to emulate the Qt OSD
	// I need to add later over the video
	void add_dummy_overlay_plane();
	static int modeset_create_fb(int fd, ModesetBuff *buf);
};

static int CALCULATOR_LOG_INTERVAL=10;

#endif //CONSTI10_DRMPRIME_OUT