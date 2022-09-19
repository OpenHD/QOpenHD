#include "rpimmaldisplay.h"

#include <qdebug.h>


RpiMMALDisplay::RpiMMALDisplay()
{

}

RpiMMALDisplay &RpiMMALDisplay::instance()
{
    static RpiMMALDisplay instance;
    return instance;
}

void RpiMMALDisplay::test()
{
    qDebug()<<"Test MMAL";
    MMAL_STATUS_T status;
    status = mmal_component_create(MMAL_COMPONENT_DEFAULT_VIDEO_RENDERER, &m_Renderer);
   if (status != MMAL_SUCCESS) {
       qDebug()<<"MMAl error";
       return;
   }else{
       qDebug()<<"MMAL success";
   }

}
