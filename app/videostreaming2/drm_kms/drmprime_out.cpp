/*
 * Copyright (c) 2020 John Cox for Raspberry Pi Trading
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */


// *** This module is a work in progress and its utility is strictly
//     limited to testing.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <pthread.h>
#include <semaphore.h>

#include <xf86drm.h>
#include <xf86drmMode.h>

#include "../../common_consti/TimeHelper.hpp"
#include "../../common_consti/Logger.hpp"
#include "../../common_consti/ThreadsafeQueue.hpp"

#include "MMapFrame.h"
#include "extra_drm.h"
#include "../color_helper.h"
#include "drmprime_out.h"

#include "drm_fourcc.h"
#include "../avcodec_helper.hpp"

AvgCalculator avgDisplayThreadQueueLatency{"DisplayThreadQueue"};
AvgCalculator avgTotalDecodeAndDisplayLatency{"TotalDecodeDisplayLatency"};
Chronometer chronoVsync{"VSYNC"};
Chronometer chronometerDaUninit{"DA_UNINIT"};
//
Chronometer chronometerDaInit{"DA_INIT"};
Chronometer chronometerDaInitAddFb{"DA_INIT_ADD_FB"};
Chronometer chronometerDaInitSetPlane{"DA_INIT_SET_PLANE"};
Chronometer chronoCopyFrameMMap{"CopyFrameMMap"};

#define ERRSTR strerror(errno)

// on success, writes into pplane_id the id of a plane that supports
// 1) The given crtc
// 2) the given format
// skip index: skip the first n planes, then try and find the one to use
static int find_plane(const int drmfd, const int crtcidx, const uint32_t format,
                      uint32_t& pplane_id,int skip_index=0){
    drmModePlaneResPtr planes;
    drmModePlanePtr plane;
    unsigned int i;
    unsigned int j;
    int ret = 0;
    planes = drmModeGetPlaneResources(drmfd);
    if (!planes) {
        fprintf(stderr, "drmModeGetPlaneResources failed: %s\n", ERRSTR);
        return -1;
    }
	std::cout<<"find_plane: count_planes:"<<planes->count_planes<<"\n";
    for (i = skip_index; i < planes->count_planes; ++i) {
        plane = drmModeGetPlane(drmfd, planes->planes[i]);
        if (!plane) {
            fprintf(stderr, "drmModeGetPlane failed: %s\n", ERRSTR);
            break;
        }
        if (!(plane->possible_crtcs & (1 << crtcidx))) {
		    // pane does nor work with this crtc
            drmModeFreePlane(plane);
            continue;
        }
		std::cout<<"Plane "<<i<<" count_formats:"<<plane->count_formats<<"\n";
        for (j = 0; j < plane->count_formats; ++j) {
            if (plane->formats[j] == format) {
			  std::cout<<"Found matching plane,index:"<<i<<" plane_id:"<<plane->plane_id<<"\n";
			  break;
			}
        }
        if (j == plane->count_formats) {
		  // we haven't found a plane that supports the given format
            drmModeFreePlane(plane);
            continue;
        }
        pplane_id = plane->plane_id;
        drmModeFreePlane(plane);
        break;
    }
    if (i == planes->count_planes) ret = -1;
    drmModeFreePlaneResources(planes);
    return ret;
}

// clears up the drm_aux to be reused with a new frame
// Note that if this drm_aux is currently read out, this call
// might block. Otherwise, it will return almost immediately
static void da_uninit(DRMPrimeOut *const de, DRMPrimeOut::drm_aux *da){
    //std::cout<<"da_uninit()begin\n";
    chronometerDaUninit.start();
    unsigned int i;
    if (da->fb_id != 0) {
        drmModeRmFB(de->drm_fd, da->fb_id);
        da->fb_id = 0;
    }
    for (i = 0; i != AV_DRM_MAX_PLANES; ++i) {
        if (da->bo_handles[i]) {
            struct drm_gem_close gem_close = {.handle = da->bo_handles[i]};
            drmIoctl(de->drm_fd, DRM_IOCTL_GEM_CLOSE, &gem_close);
            da->bo_handles[i] = 0;
        }
    }
	if(da->frame){
	  av_frame_free(&da->frame);
	}
    chronometerDaUninit.stop();
    chronometerDaUninit.printInIntervals(CALCULATOR_LOG_INTERVAL);
  	//std::cout<<"da_uninit()end\n";
}

static void modeset_page_flip_event(int fd, unsigned int frame,unsigned int sec, unsigned int usec,void *data){
    MLOGD<<"Got modeset_page_flip_event for frame "<<frame<<"\n";
}

static void registerModesetPageFlipEvent(DRMPrimeOut *const de){
    drmEventContext ev;
    memset(&ev, 0, sizeof(ev));
    ev.version = 2;
    ev.page_flip_handler = modeset_page_flip_event;
    drmHandleEvent(de->drm_fd, &ev);
}

static int countLol=0;

// initializes the drm_aux for the new frame, including the raw frame data
// unfortunately blocks until the ? VSYNC or some VSYNC related time point ?
static int da_init(DRMPrimeOut *const de, DRMPrimeOut::drm_aux *da,AVFrame* frame){
    chronometerDaInit.start();
    chronometerDaInitAddFb.start();
    const AVDRMFrameDescriptor *desc = (AVDRMFrameDescriptor *)frame->data[0];
    uint32_t pitches[4] = { 0 };
    uint32_t offsets[4] = { 0 };
    uint64_t modifiers[4] = { 0 };
    uint32_t bo_handles[4] = { 0 };
    da->frame = frame;
    memset(da->bo_handles, 0, sizeof(da->bo_handles));
    //for (int i = 0; i < desc->nb_objects; ++i) {
    if (drmPrimeFDToHandle(de->drm_fd, desc->objects[0].fd, da->bo_handles) != 0) {
        fprintf(stderr, "drmPrimeFDToHandle[%d](%d) failed: %s\n", 0, desc->objects[0].fd, ERRSTR);
        return -1;
    }
    //}
	// we always get frames with 1 layer
	assert(desc->nb_layers==1);
    //for (int i = 0; i < desc->nb_layers; ++i) {
    for (int j = 0; j < desc->layers[0].nb_planes; ++j) {
        const AVDRMPlaneDescriptor *const p = desc->layers[0].planes + j;
        const AVDRMObjectDescriptor *const obj = desc->objects + p->object_index;
        MLOGD<<"Plane "<<j<<" has pitch:"<<p->pitch<<" offset:"<<p->offset<<" object_index:"<<p->object_index<<" modifier:"<<obj->format_modifier
			<<" bo_handle:"<<da->bo_handles[p->object_index]<<"\n";
        pitches[j] = p->pitch;
        offsets[j] = p->offset;
        //DRM_FORMAT_MOD_INVALID
        //MLOGD<<"X:"<<DRM_FORMAT_MOD_BROADCOM_SAND32<<"Y:"<<DRM_FORMAT_MOD_BROADCOM_SAND128<<"Z:"<<DRM_FORMAT_MOD_BROADCOM_SAND256<<"\n";
        modifiers[j] = obj->format_modifier;
        bo_handles[j] = da->bo_handles[p->object_index];
    }
    //}
    //MLOGD<<"desc->nb_objects:"<<desc->nb_objects<<"desc->nb_layers"<<desc->nb_layers<<"\n";
    if (drmModeAddFB2WithModifiers(de->drm_fd,
                                   x_av_frame_cropped_width(frame),
								   x_av_frame_cropped_height(frame),
                                   desc->layers[0].format, bo_handles,
                                   pitches, offsets, modifiers,
                                   &da->fb_id, DRM_MODE_FB_MODIFIERS /** 0 if no mods */) != 0) {
        fprintf(stderr, "drmModeAddFB2WithModifiers failed: %s\n", ERRSTR);
        return -1;
    }
    chronometerDaInitAddFb.stop();
    chronometerDaInitAddFb.printInIntervals(CALCULATOR_LOG_INTERVAL);
    chronometerDaInitSetPlane.start();
	// In theory, I think we should be able to do a page flip on the second frame and any following frame(s)
	// as long as the format doesn't change. Doesn't work though.
	static bool xFirst= true;
    MLOGD<<"Compose:"<<de->setup.compose.x<<","<<de->setup.compose.y<<" "<<de->setup.compose.width<<"x"<<de->setup.compose.height<<"\n";
	MLOGD<<"AV frame width:"<<(x_av_frame_cropped_width(frame) << 16)<<" height:"<<x_av_frame_cropped_height(frame) << 16<<"\n";
	// https://github.com/grate-driver/libdrm/blob/master/xf86drmMode.c#L988
	// https://github.com/raspberrypi/linux/blob/aeaa2460db088fb2c97ae56dec6d7d0058c68294/drivers/gpu/drm/drm_ioctl.c#L670
	// https://github.com/raspberrypi/linux/blob/rpi-5.10.y/drivers/gpu/drm/drm_plane.c#L800
	// https://github.com/raspberrypi/linux/blob/rpi-5.10.y/drivers/gpu/drm/drm_plane.c#L771
	if(xFirst){
	  if(drmModeSetPlane(de->drm_fd, de->setup.planeId, de->setup.crtcId,
						 da->fb_id, DRM_MODE_PAGE_FLIP_ASYNC | DRM_MODE_ATOMIC_NONBLOCK,
						 de->setup.compose.x, de->setup.compose.y,
						 de->setup.compose.width,
						 de->setup.compose.height,
						 0, 0,
						 x_av_frame_cropped_width(frame) << 16,
						 x_av_frame_cropped_height(frame) << 16)!=0){
		fprintf(stderr, "drmModeSetPlane failed: %s\n", ERRSTR);
		return -1;
	  }
	}else{
	  drmSetClientCap(de->drm_fd,DRM_CLIENT_CAP_ATOMIC,de->setup.planeId);
	  drmModeAtomicReq *req= drmModeAtomicAlloc();
	  auto tmp_plane=drmModeGetPlane(de->drm_fd,de->setup.planeId);
	  std::cout<<"Plane fb_id:"<<tmp_plane->fb_id<<"\n";
	  auto tmp_fb= drmModeGetFB2(de->drm_fd,da->fb_id);
	  std::cout<<"tmp_fb w:"<<tmp_fb->width<<"\n";
	  drmModeAtomicAddProperty(req,de->setup.planeId,DRM_MODE_OBJECT_CRTC,de->setup.crtcId);
	  drmModeAtomicAddProperty(req,de->setup.planeId,DRM_MODE_OBJECT_FB,da->fb_id);
	  auto props= drmModeObjectGetProperties(de->drm_fd,de->setup.planeId,DRM_MODE_OBJECT_PLANE);
	  for(unsigned int i=0;i<props->count_props;i++){
		auto prop= drmModeGetProperty(de->drm_fd,props->props[i]);
		std::cout<<"X:["<<prop->name<<"]"<<prop->prop_id<<"\n";
	  }
	  if(drmModeAtomicCommit(de->drm_fd, req,
							 //0
							 /*DRM_MODE_PAGE_FLIP_ASYNC | DRM_MODE_ATOMIC_NONBLOCK*/
							 DRM_MODE_ATOMIC_ALLOW_MODESET
							 , NULL)!=0){
		std::cerr<<"Cannot perform drmModeAtomicCommit"<<strerror(errno)<<"\n";
	  }else{
		std::cout<<"Performed commit\n";
	  }
	  drmModeAtomicFree(req);
	}
  	chronometerDaInitSetPlane.stop();
  	chronometerDaInitSetPlane.printInIntervals(CALCULATOR_LOG_INTERVAL);
	// drmModePageFlip doesn't work, but I made it an user option anyways
	if(de->m_use_page_flip_on_second_frame){
	  xFirst= false;
	}
    chronometerDaInit.stop();
    chronometerDaInit.printInIntervals(CALCULATOR_LOG_INTERVAL);
    return 0;
}

static int getFormatForFrame(AVFrame* frame){
    const AVDRMFrameDescriptor *desc = (AVDRMFrameDescriptor *)frame->data[0];
    const uint32_t format = desc->layers[0].format;
    return format;
}

// If the crtc plane we have for video is not updated to use the same frame format (yet),
// do so. Only needs to be done once.
static int updateCRTCFormatIfNeeded(DRMPrimeOut *const de,const uint32_t frameFormat){
    const uint32_t format = frameFormat;
    if (de->setup.out_format != format) {
        if (find_plane(de->drm_fd, de->setup.crtcIdx, format, de->setup.planeId)) {
            fprintf(stderr, "No plane for format: %#x\n", format);
            return -1;
        }
        de->setup.out_format = format;
        printf("Changed drm_setup(aka CRTC) format to %#x\n",de->setup.out_format);
    }
    return 0;
}


static AVFrame* xLast=nullptr;

static bool first=true;
static int do_display(DRMPrimeOut *const de, AVFrame *frame){
    assert(frame!=NULL);
    avgDisplayThreadQueueLatency.addUs(getTimeUs()-frame->pts);
    avgDisplayThreadQueueLatency.printInIntervals(CALCULATOR_LOG_INTERVAL);
    DRMPrimeOut::drm_aux *da = &de->aux[de->ano];
    if(updateCRTCFormatIfNeeded(de, getFormatForFrame(frame))!=0){
        av_frame_free(&frame);
        return -1;
    }
    if(de->renderMode==0 || de->renderMode==1){
	    //std::cout<<"X\n";
        da_uninit(de, da);
	    //std::cout<<"Y\n";
        //
        da_init(de,da,frame);
        // use another de aux for the next frame
        de->ano = de->ano + 1 >= DRMPrimeOut::AUX_SIZE ? 0 : de->ano + 1;
	    //std::cout<<"Z\n";
    }else{
        if(first){
            da_uninit(de, da);
            //
            da_init(de,da,frame);
            first=false;
            AVFrame* extraFrame = av_frame_alloc();
            av_frame_ref(extraFrame, frame);
            da->mappedFrame=std::make_unique<MMapFrame>(da->frame,PROT_WRITE,"DstX");
        }else{
            // Instead of using any drm crap, just copy the raw data
            // takes longer than expected, though.
            chronoCopyFrameMMap.start();
            //mmap_and_copy_frame_data(da->frame,frame);
            mmap_and_copy_frame2(*da->mappedFrame.get(),frame);
            chronoCopyFrameMMap.stop();
            chronoCopyFrameMMap.printInIntervals(CALCULATOR_LOG_INTERVAL);
            //av_frame_free(&frame);
            //av_frame_free(&frame);
            // for some reason, we need to trail one frame behind when freeing it ?!
            if(xLast){
                av_frame_free(&xLast);
            }
		  	/*drm_clip_rect clip_rect{0,0,1920,1080};
		  	drmModeDirtyFB(de->drm_fd,da->fb_id,&clip_rect,1);*/
            xLast=frame;
            const AVDRMFrameDescriptor *desc1 = (AVDRMFrameDescriptor *)da->frame->data[0];
            const AVDRMFrameDescriptor *desc2 = (AVDRMFrameDescriptor *)frame->data[0];
            const AVDRMObjectDescriptor *obj1 = &desc1->objects[0];
            const AVDRMObjectDescriptor *obj2 = &desc2->objects[0];
            if(obj1->fd==obj2->fd){
                fprintf(stderr, "weird\n");
            }else{
                //fprintf(stderr, "okay\n");
                //av_frame_free(&frame);
            }
        }
    }
    avgTotalDecodeAndDisplayLatency.addUs(getTimeUs()- frame->pts);
    avgTotalDecodeAndDisplayLatency.printInIntervals(CALCULATOR_LOG_INTERVAL);
    return 0;
}

static void* display_thread(void *v){
    DRMPrimeOut *const de = (DRMPrimeOut *)v;
    for (;;) {
        if(de->terminate)break;
        if(de->renderMode==0){
            AVFrame* frame=de->sbQueue->getBuffer();
            if(frame==NULL){
                MLOGD<<"Got NULL frame\n";
                break;
            }else{
                //MLOGD<<"Got frame\n";
            }
            do_display(de, frame);
        }else{
            const auto allBuffers=de->queue->getAllAndClear();
            if(allBuffers.size()>0){
                const int nDroppedFrames=allBuffers.size()-1;
                if(nDroppedFrames!=0){
                    MLOGD<<"N dropped:"<<nDroppedFrames<<"\n";
                }
                // don't forget to free the dropped frames
                for(int i=0;i<nDroppedFrames;i++){
                    av_frame_free(&allBuffers[i]->frame);
                }
                const auto mostRecent=allBuffers[nDroppedFrames];
                do_display(de, mostRecent->frame);
                // since the last swap probably returned at VSYNC, we can sleep almost 1 VSYNC period and
                // then get to do a (almost) immediate plane swap with the most recent video frame buffer
                // For a 60fps display a 12ms sleep seems to be the highest we can do before
                // we actually then miss a VSYNC again
                //busySleep(12*1000);
            }else{
                //MLOGD<<"Busy wait, no frame yet\n";
            }
        }
    }
    for (int i = 0; i != DRMPrimeOut::AUX_SIZE; ++i)
        da_uninit(de, de->aux + i);
    return nullptr;
}

static int find_crtc(int drmfd, struct DRMPrimeOut::drm_setup *s, uint32_t *const pConId)
{
    int ret = -1;
    int i;
    drmModeRes *res = drmModeGetResources(drmfd);
    drmModeConnector *c;
    if (!res) {
        printf("drmModeGetResources failed: %s\n", ERRSTR);
        return -1;
    }
    if (res->count_crtcs <= 0) {
        printf("drm: no crts\n");
        goto fail_res;
    }
    if (!s->conId) {
        fprintf(stderr,
                "No connector ID specified.  Choosing default from list:\n");
        for (i = 0; i < res->count_connectors; i++) {
            drmModeConnector *con =
                drmModeGetConnector(drmfd, res->connectors[i]);
            drmModeEncoder *enc = NULL;
            drmModeCrtc *crtc = NULL;
            if (con->encoder_id) {
                enc = drmModeGetEncoder(drmfd, con->encoder_id);
                if (enc->crtc_id) {
                    crtc = drmModeGetCrtc(drmfd, enc->crtc_id);
                }
            }
            if (!s->conId && crtc) {
                s->conId = con->connector_id;
                s->crtcId = crtc->crtc_id;
            }
            fprintf(stderr, "Connector %d (crtc %d): type %d, %dx%d%s\n",
                   con->connector_id,
                   crtc ? crtc->crtc_id : 0,
                   con->connector_type,
                   crtc ? crtc->width : 0,
                   crtc ? crtc->height : 0,
                   (s->conId == (int)con->connector_id ?
                    " (chosen)" : ""));
        }
        if (!s->conId) {
            fprintf(stderr,
                   "No suitable enabled connector found.\n");
            return -1;;
        }
    }
    s->crtcIdx = -1;
    for (i = 0; i < res->count_crtcs; ++i) {
        if (s->crtcId == res->crtcs[i]) {
            s->crtcIdx = i;
            break;
        }
    }
    if (s->crtcIdx == -1) {
        fprintf(stderr, "drm: CRTC %u not found\n", s->crtcId);
        goto fail_res;
    }
    if (res->count_connectors <= 0) {
        fprintf(stderr, "drm: no connectors\n");
        goto fail_res;
    }
    c = drmModeGetConnector(drmfd, s->conId);
    if (!c) {
        fprintf(stderr, "drmModeGetConnector failed: %s\n", ERRSTR);
        goto fail_res;
    }
    if (!c->count_modes) {
        fprintf(stderr, "connector supports no mode\n");
        goto fail_conn;
    }
    {
        drmModeCrtc *crtc = drmModeGetCrtc(drmfd, s->crtcId);
		std::cout<<"CRTC x,y,w,h"<<crtc->x<<","<<crtc->y<<" "<<crtc->width<<"x"<<crtc->height<<"\n";
		const int xOffset=0;
        s->compose.x = crtc->x+xOffset;
        s->compose.y = crtc->y;
        s->compose.width = crtc->width-xOffset;
        s->compose.height = crtc->height;
		/*s->compose.x=0;
		s->compose.y=0;
		s->compose.width=1280;
		s->compose.height=720;*/
        drmModeFreeCrtc(crtc);
    }
    if (pConId) *pConId = c->connector_id;
    ret = 0;
fail_conn:
    drmModeFreeConnector(c);
fail_res:
    drmModeFreeResources(res);
    return ret;
}

// We assume the caller frees the given src-frame once this function call returns,
// so we just create a new frame that references the fiven frame to keep it around.
int DRMPrimeOut::queue_new_frame_for_display(struct AVFrame *src_frame)
{
  assert(src_frame);
  //std::cout<<"DRMPrimeOut::drmprime_out_display "<<src_frame->width<<"x"<<src_frame->height<<"\n";
  AVFrame *frame;
  if ((src_frame->flags & AV_FRAME_FLAG_CORRUPT) != 0) {
	fprintf(stderr, "Discard corrupt frame: fmt=%d, ts=%" PRId64 "\n", src_frame->format, src_frame->pts);
	return 0;
  }
  if (src_frame->format == AV_PIX_FMT_DRM_PRIME) {
	frame = av_frame_alloc();
	assert(frame);
	av_frame_ref(frame, src_frame);
	//printf("format == AV_PIX_FMT_DRM_PRIME\n");
  } else if (src_frame->format == AV_PIX_FMT_VAAPI) {
	//printf("format == AV_PIX_FMT_VAAPI\n");
	frame = av_frame_alloc();
	assert(frame);
	frame->format = AV_PIX_FMT_DRM_PRIME;
	if (av_hwframe_map(frame, src_frame, 0) != 0) {
	  fprintf(stderr, "Failed to map frame (format=%d) to DRM_PRiME\n", src_frame->format);
	  av_frame_free(&frame);
	  return AVERROR(EINVAL);
	}
  } else {
	fprintf(stderr, "Frame (format=%d) not DRM_PRIME\n", src_frame->format);
	return AVERROR(EINVAL);
  }
  // Here the delay is still neglegible,aka ~0.15ms
  const auto delayBeforeDisplayQueueUs=getTimeUs()-frame->pts;
  MLOGD<<"delayBeforeDisplayQueue:"<<frame->pts<<" delay:"<<(delayBeforeDisplayQueueUs/1000.0)<<" ms\n";
  if(renderMode==0){
	// wait for the last buffer to be processed, then update. (Might) block
	sbQueue->setBuffer(frame);
  }else{
	// push it immediately, even though frame(s) might already be inside the queue
	queue->push(std::make_shared<AVFrameHolder>(frame));
  }
  return 0;
}

DRMPrimeOut::DRMPrimeOut(int renderMode1,bool drm_add_dummy_overlay,bool use_page_flip_on_second_frame):
renderMode(renderMode1),m_drm_add_dummy_overlay(drm_add_dummy_overlay),m_use_page_flip_on_second_frame(use_page_flip_on_second_frame)
{
   std::cout<<"DRMPrimeOut::DRMPrimeOut() begin\n";
    int rv;

    sbQueue=std::make_unique<ThreadsafeSingleBuffer<AVFrame*>>();
    queue=std::make_unique<ThreadsafeQueue<AVFrameHolder>>();

    const char *drm_module = "vc4";

    drm_fd = -1;
    con_id = 0;
    setup = (struct drm_setup) { 0 };
    terminate=false;

    if ((drm_fd = drmOpen(drm_module, NULL)) < 0) {
        rv = AVERROR(errno);
        // comp error fprintf(stderr, "Failed to drmOpen %s: %s\n", drm_module, av_err2str(rv));
        fprintf(stderr, "Failed to drmOpen %s: \n", drm_module);
        goto fail_free;
    }
	//exp
	if(drmSetMaster(drm_fd)<0){
	  fprintf(stderr, "Cannot set master %s\n", ERRSTR);
	}

    if (find_crtc(drm_fd, &setup, &con_id) != 0) {
        fprintf(stderr, "failed to find valid mode\n");
        rv = AVERROR(EINVAL);
        goto fail_close;
    }
	q_thread=std::make_unique<std::thread>([this](){
	  display_thread(this);
	});
  	printDrmModes(drm_fd);
    std::cout<<"DRMPrimeOut::DRMPrimeOut() end\n";
	// disable the dummy overlay plane for now
	if(m_drm_add_dummy_overlay){
	  add_dummy_overlay_plane();
	}
    return;
fail_close:
    close(drm_fd);
    drm_fd = -1;
fail_free:
    fprintf(stderr, ">>> %s: FAIL\n", __func__);
}

DRMPrimeOut::~DRMPrimeOut()
{
    terminate=true;
    sbQueue->terminate();
	// q_thread can be null if something went wrong during construction (initialization)
	if(q_thread && q_thread->joinable()){
	  q_thread->join();
	}
    // free any frames that might be inside some queues - since the queue thread
    // is now stopped, we don't have to worry about any synchronization
    if(sbQueue->unsafeGetFrame()!=NULL){
        AVFrame* frame=sbQueue->unsafeGetFrame();
        av_frame_free(&frame);
    }
    auto tmp=queue->getAllAndClear();
    for(int i=0;i<tmp.size();i++){
        auto element=tmp[i];
        av_frame_free(&element->frame);
    }
    if (drm_fd >= 0) {
        close(drm_fd);
        drm_fd = -1;
    }
    sbQueue.reset();
    queue.reset();
}

void DRMPrimeOut::add_dummy_overlay_plane() {
  std::cout<<"DRMPrimeOut::add_dummy_overlay_plane() begin\n";
  //
  uint32_t pplane_id=0;
  if(find_plane(drm_fd,setup.crtcIdx,DRM_FORMAT_XRGB8888,pplane_id,1)){
	std::cout<<"Cannot find overlay plane \n";
	return;
  }
  std::cout<<"Found overlay plane, pplane_id:"<<pplane_id<<"\n";
  // add dummy framebuffer to that plane
  DRMPrimeOut::ModesetBuff modeset_buff{};
  modeset_buff.width=1280;
  modeset_buff.height=720;

  if(modeset_create_fb(drm_fd,&modeset_buff)){
	std::cout<<"Cannot create dummy fb\n";
	return;
  }
  std::cout<<"Created dummy fb"<<modeset_buff.width<<"x"<<modeset_buff.height<<" "<<modeset_buff.fb<<"\n";
  std::cout<<"stride:"<<modeset_buff.stride<<"\n";
  fillFrame(modeset_buff.map,modeset_buff.width,modeset_buff.height,modeset_buff.stride, createColor(0));

  if(drmModeSetPlane(drm_fd, pplane_id, setup.crtcId,
					 modeset_buff.fb, DRM_MODE_PAGE_FLIP_ASYNC | DRM_MODE_ATOMIC_NONBLOCK,
					 0, 0,
					 1280,
					 720,
					 0, 0,
					 modeset_buff.width,
					 modeset_buff.height)!=0){
	fprintf(stderr, "drmModeSetPlane failed: %s\n", ERRSTR);
  }
  //if(drmModePageFlip(drm_fd,setup.crtcId,modeset_buff.fb,0, nullptr)){
  //	fprintf(stderr, "drmModePageFlip failed: %s\n", ERRSTR);
  //}
  std::cout<<"DRMPrimeOut::add_dummy_overlay_plane() end\n";
}

int DRMPrimeOut::modeset_create_fb(int fd,DRMPrimeOut::ModesetBuff *buf)
{
	int ret;
	// create dumb buffer
    struct drm_mode_create_dumb creq;
	memset(&creq, 0, sizeof(creq));
	creq.width = buf->width;
	creq.height = buf->height;
	creq.bpp = 32;
	ret = drmIoctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq);
	if (ret < 0) {
		fprintf(stderr, "cannot create dumb buffer (%d): %m\n",
			errno);
		return -errno;
	}
	buf->stride = creq.pitch;
	buf->size = creq.size;
	buf->handle = creq.handle;

	// create framebuffer object for the dumb-buffer
	ret = drmModeAddFB(fd, buf->width, buf->height, 32, 32, buf->stride,
			   buf->handle, &buf->fb);
	if (ret) {
		fprintf(stderr, "cannot create framebuffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_destroy;
	}

	// prepare buffer for memory mapping
    struct drm_mode_map_dumb mreq;
	memset(&mreq, 0, sizeof(mreq));
	mreq.handle = buf->handle;
	ret = drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq);
	if (ret) {
		fprintf(stderr, "cannot map dumb buffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_fb;
	}

	// perform actual memory mapping
	buf->map = (uint8_t*)mmap(0, buf->size, PROT_READ | PROT_WRITE, MAP_SHARED,
		        fd, mreq.offset);
	if (buf->map == MAP_FAILED) {
		fprintf(stderr, "cannot mmap dumb buffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_fb;
	}

	/* clear the framebuffer to 0 */
	memset(buf->map, 0, buf->size);

	return 0;

err_fb:
	drmModeRmFB(fd, buf->fb);
err_destroy:
    struct drm_mode_destroy_dumb dreq;
	memset(&dreq, 0, sizeof(dreq));
	dreq.handle = buf->handle;
	drmIoctl(fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq);
	return ret;
}