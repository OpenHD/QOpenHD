#ifndef GSTRTPAUDIOPLAYER_H
#define GSTRTPAUDIOPLAYER_H

#include "gst/gstelement.h"

/**
 * @brief Input: "RTP audio"
 *        Output: Hopefully the system speaker ;)
 * Experimental
 */
class GstRtpAudioPlayer
{
public:
    GstRtpAudioPlayer();
    static GstRtpAudioPlayer& instance();
    void start_playing();
    void stop_playing();
private:
    // The gstreamer pipeline
    GstElement * m_gst_pipeline=nullptr;
};

#endif // GSTRTPAUDIOPLAYER_H
