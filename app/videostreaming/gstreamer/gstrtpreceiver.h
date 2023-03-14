#ifndef GSTRTPRECEIVER_H
#define GSTRTPRECEIVER_H

#include "QOpenHDVideoHelper.hpp"
#include <gst/gst.h>
#include <thread>

/**
 * @brief Uses gstreamer and appsink to expose the functionality of receiving and parsing
 * rtp h264, h265 and mjpeg.
 */
class GstRtpReceiver {
public:
    /**
     * The constructor is delayed, remember to use start_receiving()
     */
    GstRtpReceiver(int udp_port,QOpenHDVideoHelper::VideoCodec video_codec);
    virtual ~GstRtpReceiver();
    // Depending on the codec, these are h264,h265 or mjpeg "frames" / frame buffers
    // The big advantage of gstreamer is that it seems to handle all those parsing quirks the best,
    // e.g. the frames on this cb should be easily passable to whatever decode api is available.
    typedef std::function<void(std::shared_ptr<std::vector<uint8_t>> frame)> NEW_FRAME_CALLBACK;
    void start_receiving(NEW_FRAME_CALLBACK cb);
    void stop_receiving();
    QOpenHDVideoHelper::VideoCodec get_codec()const{
        return m_video_codec;
    }
private:
    std::string construct_gstreamer_pipeline();
    void loop_pull_samples();
    void on_new_sample(std::shared_ptr<std::vector<uint8_t>> sample);
    void debug_sample(std::shared_ptr<std::vector<uint8_t>> sample);
private:
    // The gstreamer pipeline
    GstElement * m_gst_pipeline=nullptr;
    NEW_FRAME_CALLBACK m_cb;
    QOpenHDVideoHelper::VideoCodec m_video_codec;
    int m_port;
    // appsink
    GstElement *m_app_sink_element = nullptr;
    bool m_pull_samples_run;
    std::unique_ptr<std::thread> m_pull_samples_thread=nullptr;
};

#endif // GSTRTPRECEIVER_H
