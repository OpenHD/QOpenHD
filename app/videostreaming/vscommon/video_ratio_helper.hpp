#ifndef VIDEO_RATIO_HELPER_H
#define VIDEO_RATIO_HELPER_H

#include <cmath>
#include <stdint.h>

namespace helper::ratio{

// Helper for the common case where we want to keep the video(s) aspect ratio, but also fill as much space as available.
struct MGLViewptort{
    int x,y,width,height;
};
static MGLViewptort calculate_viewport_video_fullscreen(int surface_width,int surface_height,int texture_width,int texture_height){
    MGLViewptort ret;
    // We setup the viewport surch that we preserve the original ratio of the teture ( width / height).
    // One could also just transform the vertex coordinates, but setting the vieport accordingly is easier.
    const double surface_aspect_ratio=(double)surface_width / (double)surface_height;
    const double texture_aspect_ratio=(double)texture_width / (double)texture_height;
    //qDebug()<<"Surface "<< surface_width<<"x"<<surface_height<<" ratio:"<<surface_aspect_ratio;
    //qDebug()<<"Texture "<<texture_width<<"x"<<texture_height<<" ratio:"<<texture_aspect_ratio;
    int x_viewport_width=0;
    int x_viewport_height=0;
    if(surface_aspect_ratio>texture_aspect_ratio){
        // we use the full height, and andjust the width.
        // Example case: 16/9 (1.7) surface  and 4:3 (1.3) (video) texture
        x_viewport_height=surface_height;
        auto tmp= surface_height * texture_aspect_ratio;
        x_viewport_width=std::lround(tmp);
        int x_offset=(surface_width-x_viewport_width)/2;
        //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
        ret.x=x_offset;
        ret.y=0;
        ret.width=x_viewport_width;
        ret.height=x_viewport_height;
    }else{
         // we use the full width, and adjust the height
        x_viewport_width=surface_width;
        auto tmp= surface_width * (1.0/texture_aspect_ratio);
        x_viewport_height=std::lround(tmp);
        int y_offset=(surface_height-x_viewport_height)/2;
        //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
        ret.x=0;
        ret.y=y_offset;
        ret.width=x_viewport_width;
        ret.height=x_viewport_height;
    }
    return ret;
}

static MGLViewptort calculate_viewport(int surface_width,int surface_height,int texture_width,int texture_height,bool scale_to_fit=false){
    if(scale_to_fit){
        return {0,0,surface_width,surface_height};
    }
    return calculate_viewport_video_fullscreen(surface_width,surface_height,texture_width,texture_height);
}

}

#endif // VIDEO_RATIO_HELPER_H
