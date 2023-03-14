#ifndef RPIMMALDECODEDISPLAY_H
#define RPIMMALDECODEDISPLAY_H

#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/vcos/vcos.h"

#include "interface/mmal/util/mmal_graph.h"
//#include "interface/mmal/util/mmal_util_params.h"

//#include "ilclient.h"

#include <cstdint>
#include <optional>
#include <chrono>


/** Context for our application */
struct CONTEXT_T {
    VCOS_SEMAPHORE_T semaphore;
    MMAL_QUEUE_T *queue;
    MMAL_STATUS_T status;
};
// MMAL Decode and MMAL Display all in one.
// Based on https://github.com/t-moe/rpi_mmal_examples/blob/master/graph_decode_render.c
class RPIMMalDecodeDisplay
{
public:
    RPIMMalDecodeDisplay();
    // Config data: SPS and PPS
    // width and height: well, for some reason mmal wants the w and height even though it could infer that from the sps/pps
    // similar for fps, seems to have no effect anyways.
    bool initialize(const uint8_t* config_data,const int config_data_size,int width,int height,int fps);

    bool feed_frame(const uint8_t* frame_data,const int frame_data_size,std::optional<std::chrono::milliseconds> opt_upper_wait_limit=std::nullopt);

    void cleanup();

    CONTEXT_T m_context;

    MMAL_STATUS_T m_status = MMAL_EINVAL;

    MMAL_GRAPH_T *m_graph = 0;
    MMAL_COMPONENT_T *m_decoder = 0;
    MMAL_COMPONENT_T *m_renderer=0;
    MMAL_POOL_T *m_pool_in = 0;

private:
    void updateDisplayRegion();
    bool display_region_needs_update=true;
private:
    // Get an input buffer to copy frame data to.
    // Returns nullptr on failure, a valid mmal buffer pointer otherwise (note that the memory management is mmal inernal,
    // you do not need to free this buffer)

};

#endif // RPIMMALDECODEDISPLAY_H
