#ifndef RPIMMALDISPLAY_H
#define RPIMMALDISPLAY_H


#include <interface/mmal/mmal.h>
#include <interface/mmal/util/mmal_util.h>
#include <interface/mmal/util/mmal_util_params.h>
#include <interface/mmal/util/mmal_default_components.h>


class RpiMMALDisplay
{
public:
    RpiMMALDisplay();
    static RpiMMALDisplay& instance();

    void init(int video_width=1280,int video_height=720);
    void cleanup();
    void updateDisplayRegion();
    void display_frame(AVFrame* frame);
private:
    MMAL_COMPONENT_T* m_Renderer=nullptr;
    MMAL_PORT_T* m_InputPort=nullptr;
    static void InputPortCallback(MMAL_PORT_T* port, MMAL_BUFFER_HEADER_T* buffer);
};

#endif // RPIMMALDISPLAY_H
