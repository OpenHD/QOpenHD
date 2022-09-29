#ifndef RPIMMALDECODER_H
#define RPIMMALDECODER_H

#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/vcos/vcos.h"

struct CONTEXT_T {
    VCOS_SEMAPHORE_T in_semaphore;
    VCOS_SEMAPHORE_T out_semaphore;
    MMAL_QUEUE_T *queue;
};


class RPIMMALDecoder
{
public:
    RPIMMALDecoder();
};

#endif // RPIMMALDECODER_H
