#ifndef RPIMMALDISPLAY_H
#define RPIMMALDISPLAY_H


#include <interface/mmal/mmal.h>
#include <interface/mmal/util/mmal_util.h>
#include <interface/mmal/util/mmal_util_params.h>
#include <interface/mmal/util/mmal_default_components.h>


#include "avcodec_helper.hpp"

// MMAL display, works with avcodec mmal wrapper (but this wrapper sucks), does not work with the rpimmaldecoder (yet)
// Which is why r.n the all in one rpimmaldecodedisplay is used
class RpiMMALDisplay
{
public:
    RpiMMALDisplay();
    static RpiMMALDisplay& instance();

    bool prepareDecoderContext(AVCodecContext* context, AVDictionary** options);

    void cleanup();
    void updateDisplayRegion();
    void display_frame(AVFrame* frame);

    void display_mmal_frame(MMAL_BUFFER_HEADER_T* buffer);

    void extra_init(int width,int height);

    void extra_set_format(MMAL_ES_FORMAT_T *format_out);
private:
    void init(int video_width,int video_height);

    MMAL_COMPONENT_T* m_Renderer=nullptr;
    MMAL_PORT_T* m_InputPort=nullptr;
    static void InputPortCallback(MMAL_PORT_T* port, MMAL_BUFFER_HEADER_T* buffer);
    //
    int m_VideoWidth, m_VideoHeight;
    int m_lastScreenWidth,m_lastScreenHeight;
    bool display_region_needs_update=true;

    bool has_been_initialized=false;
};

#endif // RPIMMALDISPLAY_H
