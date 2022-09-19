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

    void test();
private:
    MMAL_COMPONENT_T* m_Renderer;
    MMAL_PORT_T* m_InputPort;
};

#endif // RPIMMALDISPLAY_H
