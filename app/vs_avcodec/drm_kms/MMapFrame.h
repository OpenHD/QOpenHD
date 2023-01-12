//
// Created by consti10 on 28.02.22.
//

#ifndef HELLO_DRMPRIME_MMAPFRAME_H
#define HELLO_DRMPRIME_MMAPFRAME_H

#include <sys/mman.h>

extern "C" {
#include "libavutil/frame.h"
#include "libavutil/hwcontext.h"
#include "libavutil/hwcontext_drm.h"
#include "libavutil/pixdesc.h"
}
#include "../../common_consti/Logger.hpp"
#include <fcntl.h>
#include <unistd.h>
#include <string>

static void memcpy_uint8_loop(uint8_t* dst,const uint8_t* src,size_t length){
  for(int i=0;i<length;i++){
	dst[i]=src[i];
  }
}

static void memcpy_uint8(uint8_t* dst,const uint8_t* src,size_t length){
  //memcpy_uint8_neon(dst,src,length);
  //memcpy_uint8_neon(dst,src,length);
  memcpy_uint8_loop(dst,src,length);
}

// MMap a drm prime ffmpeg frame
class MMapFrame{
public:
    uint8_t* map=NULL;
    int map_size=0;
    int image_data_size=0;
    static constexpr const int PROT_READ_WRITE=(PROT_READ | PROT_WRITE);
    explicit MMapFrame(AVFrame* frame,int prot=PROT_READ_WRITE,const std::string& tag="NoTag"){
        mapFrame(frame,prot,tag);
    }
    void mapFrame(AVFrame* frame,int prot,const std::string& tag){
        const AVDRMFrameDescriptor *desc = (AVDRMFrameDescriptor *)frame->data[0];
        mapFrameDescriptor(desc,prot,tag);
    }
    void mapFrameDescriptor(const AVDRMFrameDescriptor * desc,int prot,const std::string& tag){
        if(desc->nb_objects!=1){
            fprintf(stderr,"Unexpected desc->nb_objects: %d\n",desc->nb_objects);
        }
        const AVDRMObjectDescriptor *obj = &desc->objects[0];
        // from https://blog.eiler.eu/posts/20210117/
        // The total size of the buffer (in luminance and chrominance cases) is width * stride2, where stride2 is >= (height+1)*stride1.
        map = (uint8_t *) mmap(0, obj->size, prot, MAP_SHARED,
                               obj->fd, 0);
        if (map == MAP_FAILED) {
            fprintf(stderr,"Cannot map buffer %s size %ld\n",tag.c_str(),obj->size);
            map = NULL;
            return;
        }
        map_size=obj->size;
        //MLOGD<<"Mapped buffer size:" << obj->size << "\n";
    }
    void unmap(){
        if(map!=NULL){
            const auto ret=munmap(map,map_size);
            if(ret!=0){
                MLOGD<<"unmap failed:"<<ret<<"\n";
            }
        }
    }
};

// copy data from one AVFrame drm prime frame to another via mmap
static void mmap_and_copy_frame_data(AVFrame* dst, AVFrame* src){
    MMapFrame dstMap(dst,PROT_WRITE,"Dst");
    MMapFrame srcMap(src,PROT_READ,"Src");
    if(dstMap.map_size!=srcMap.map_size){
        fprintf(stderr,"Cannot copy data from mapped buffer size %d to buff size %d",srcMap.map_size,dstMap.map_size);
    }else{
        //printf("Copying start\n");
        memcpy_uint8(dstMap.map,srcMap.map,srcMap.map_size);
        //memcpy_uint8(dstMap.map,srcMap.map,1280*720*12/8);
        //memcpy_uint8(dstMap.map,srcMap.map,128*100);
        //printf("Copying stop\n");
    }
    //copy data
    dstMap.unmap();
    srcMap.unmap();
}

static void mmap_and_copy_frame2(MMapFrame& dstMap,AVFrame* src){
    MMapFrame srcMap(src,PROT_READ,"Src");
    if(dstMap.map_size!=srcMap.map_size){
        fprintf(stderr,"Cannot copy data from mapped buffer size %d to buff size %d",srcMap.map_size,dstMap.map_size);
    }else{
        //printf("Copying start\n");
        memcpy_uint8(dstMap.map,srcMap.map,srcMap.map_size);
        //memcpy_uint8(dstMap.map,srcMap.map,1280*720*12/8);
        //memcpy_uint8(dstMap.map,srcMap.map,128*100);
        //printf("Copying stop\n");
    }
    srcMap.unmap();
}


#endif //HELLO_DRMPRIME_MMAPFRAME_H
