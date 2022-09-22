#ifndef RPIMMALDISPLAY_H
#define RPIMMALDISPLAY_H


#include <interface/mmal/mmal.h>
#include <interface/mmal/util/mmal_util.h>
#include <interface/mmal/util/mmal_util_params.h>
#include <interface/mmal/util/mmal_default_components.h>


#include "avcodec_helper.hpp"

class RpiMMALDisplay
{
public:
    RpiMMALDisplay();
    static RpiMMALDisplay& instance();

    bool prepareDecoderContext(AVCodecContext* context, AVDictionary** options);
    //void renderFrame(AVFrame* frame);

    //void setupBackground(PDECODER_PARAMETERS params);
    //void updateDisplayRegion();



    void init(int video_width=1920,int video_height=1080);
    void cleanup();
    void updateDisplayRegion();
    void display_frame(AVFrame* frame);
private:
    MMAL_COMPONENT_T* m_Renderer=nullptr;
    MMAL_PORT_T* m_InputPort=nullptr;
    static void InputPortCallback(MMAL_PORT_T* port, MMAL_BUFFER_HEADER_T* buffer);
    //
    int m_VideoWidth, m_VideoHeight;
    int m_lastScreenWidth,m_lastScreenHeight;
};

#endif // RPIMMALDISPLAY_H
