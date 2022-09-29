#ifndef RPIMMALDECODEDISPLAY_H
#define RPIMMALDECODEDISPLAY_H

/*#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/vcos/vcos.h"

#include "interface/mmal/util/mmal_graph.h"
#include "interface/mmal/util/mmal_util_params.h"*/

#include <cstdint>


class rpimmaldecodedisplay
{
public:
    rpimmaldecodedisplay();

    void initialize(const uint8_t* config_data,const int config_data_size,int width,int height,int fps);

    void feed_frame(const uint8_t* frame_data,const int frame_data_size);

};

#endif // RPIMMALDECODEDISPLAY_H
