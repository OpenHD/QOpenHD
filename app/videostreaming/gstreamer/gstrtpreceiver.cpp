#include "gstrtpreceiver.h"

#include <gst/gst.h>
#include <gst/gstparse.h>
#include <gst/gstpipeline.h>
#include <gst/app/gstappsink.h>

#include "gst_helper.hpp"
#include <nalu/NALU.hpp>

#include <QtCore/QDebug>

#include <cassert>
#include <cstring>
#include <chrono>
#include <thread>
#include <mutex>
#include <sstream>
#include <memory>
#include <vector>
#include <cstdlib>

// === Static plugin hooks (harmless if using gst-full, but kept for compatibility) ===
G_BEGIN_DECLS
#if defined(__android__) || defined(__ios__)
    GST_PLUGIN_STATIC_DECLARE(coreelements);
    GST_PLUGIN_STATIC_DECLARE(playback);
    GST_PLUGIN_STATIC_DECLARE(rtp);
    GST_PLUGIN_STATIC_DECLARE(rtsp);
    GST_PLUGIN_STATIC_DECLARE(udp);
    GST_PLUGIN_STATIC_DECLARE(videoparsersbad);
    GST_PLUGIN_STATIC_DECLARE(rtpmanager);
    GST_PLUGIN_STATIC_DECLARE(isomp4);
    GST_PLUGIN_STATIC_DECLARE(matroska);
    GST_PLUGIN_STATIC_DECLARE(mpegtsdemux);
    GST_PLUGIN_STATIC_DECLARE(opengl);
    GST_PLUGIN_STATIC_DECLARE(tcp);
    GST_PLUGIN_STATIC_DECLARE(app);
#  if defined(__android__)
    GST_PLUGIN_STATIC_DECLARE(androidmedia);
#  elif defined(__ios__)
    GST_PLUGIN_STATIC_DECLARE(applemedia);
#  endif
#endif

// Only reference these on non-Android so this TU doesn't pull them into the Android link.
#if !defined(__android__)
    GST_PLUGIN_STATIC_DECLARE(qmlgl);
    GST_PLUGIN_STATIC_DECLARE(qgc);
#endif
G_END_DECLS

// --- Make sure GStreamer is initialized exactly once ---
namespace {
void ensureGstInited()
{
    static std::once_flag once;
    std::call_once(once, [](){
        // With gst-full we don't want any runtime scanning/registry writes
        setenv("GST_PLUGIN_SYSTEM_PATH_1_0", "", 1);
        setenv("GST_PLUGIN_PATH_1_0", "", 1);
        setenv("GST_REGISTRY_DISABLE", "yes", 1);
        setenv("GST_DEBUG_NO_COLOR", "1", 1);
        if (!getenv("GST_DEBUG")) setenv("GST_DEBUG", "3", 1);

        gst_init(nullptr, nullptr);
        gst_debug_set_active(TRUE);
        gst_debug_set_default_threshold(GST_LEVEL_INFO);
        g_message("GStreamer initialized");

#if defined(__android__) || defined(__ios__)
        // Register statically linked essentials (no-op if not present in the final link)
        GST_PLUGIN_STATIC_REGISTER(coreelements);
        GST_PLUGIN_STATIC_REGISTER(playback);
        GST_PLUGIN_STATIC_REGISTER(rtp);
        GST_PLUGIN_STATIC_REGISTER(rtsp);
        GST_PLUGIN_STATIC_REGISTER(udp);
        GST_PLUGIN_STATIC_REGISTER(videoparsersbad);
        GST_PLUGIN_STATIC_REGISTER(rtpmanager);
        GST_PLUGIN_STATIC_REGISTER(isomp4);
        GST_PLUGIN_STATIC_REGISTER(matroska);
        GST_PLUGIN_STATIC_REGISTER(mpegtsdemux);
        GST_PLUGIN_STATIC_REGISTER(opengl);
        GST_PLUGIN_STATIC_REGISTER(tcp);
        GST_PLUGIN_STATIC_REGISTER(app);
#  if defined(__android__)
        GST_PLUGIN_STATIC_REGISTER(androidmedia);
#  elif defined(__ios__)
        GST_PLUGIN_STATIC_REGISTER(applemedia);
#  endif
#endif

        // Keep qmlgl/qgc out of Android builds of this TU
#if !defined(__android__)
        GST_PLUGIN_STATIC_REGISTER(qmlgl);
        GST_PLUGIN_STATIC_REGISTER(qgc);
#endif
    });
}
} // namespace

// --- Helpers ---
static std::shared_ptr<std::vector<uint8_t>> gst_copy_buffer(GstBuffer* buffer)
{
    assert(buffer);
    const gsize buff_size = gst_buffer_get_size(buffer);
    auto ret = std::make_shared<std::vector<uint8_t>>(static_cast<size_t>(buff_size));
    GstMapInfo map;
    if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
        assert(map.size == buff_size);
        std::memcpy(ret->data(), map.data, static_cast<size_t>(buff_size));
        gst_buffer_unmap(buffer, &map);
    }
    return ret;
}

static void loop_pull_appsink_samples(
    bool& keep_looping,
    GstElement *app_sink_element,
    const GstRtpReceiver::NEW_FRAME_CALLBACK& out_cb)
{
    assert(app_sink_element);
    assert(out_cb);
    const guint64 timeout_ns =
        std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::milliseconds(100)).count();

    while (keep_looping) {
        GstSample* sample = gst_app_sink_try_pull_sample(GST_APP_SINK(app_sink_element), timeout_ns);
        if (!sample)
            continue;

        GstBuffer* buffer = gst_sample_get_buffer(sample);
        if (buffer) {
            auto buff_copy = gst_copy_buffer(buffer);
            out_cb(std::move(buff_copy));
        }
        gst_sample_unref(sample);
    }
}

// --- GstRtpReceiver ---
GstRtpReceiver::GstRtpReceiver(int udp_port, QOpenHDVideoHelper::VideoCodec video_codec)
    : m_port(udp_port)
    , m_video_codec(video_codec)
{
    ensureGstInited();
}

GstRtpReceiver::~GstRtpReceiver()
{
    // Ensure everything is stopped
    stop_receiving();
}

std::string GstRtpReceiver::construct_gstreamer_pipeline()
{
    const auto codec = pipeline::conv_codec(m_video_codec);
    std::stringstream ss;
    ss << "udpsrc port=" << m_port << " " << gst_create_rtp_caps(codec) << " ! ";
    ss << pipeline::create_rtp_depacketize_for_codec(codec);
    ss << pipeline::create_parse_for_codec(codec);
    ss << pipeline::create_out_caps(codec);
    ss << " appsink drop=true name=out_appsink";
    return ss.str();
}

void GstRtpReceiver::loop_pull_samples()
{
    assert(m_app_sink_element);
    auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample){
        this->on_new_sample(std::move(sample));
    };
    loop_pull_appsink_samples(m_pull_samples_run, m_app_sink_element, cb);
}

void GstRtpReceiver::on_new_sample(std::shared_ptr<std::vector<uint8_t>> sample)
{
    if (m_cb) {
        m_cb(std::move(sample));
        return;
    }
    // Fallback debug
    debug_sample(sample);
}

void GstRtpReceiver::debug_sample(std::shared_ptr<std::vector<uint8_t>> sample)
{
    if (m_video_codec == QOpenHDVideoHelper::VideoCodecH264) {
        NALU nalu(sample->data(), sample->size());
        qDebug() << "Got h264 frame:" << nalu.get_nal_unit_type_as_string().c_str();
    } else if (m_video_codec == QOpenHDVideoHelper::VideoCodecH265) {
        NALU nalu(sample->data(), sample->size(), true);
        qDebug() << "Got h265 frame:" << nalu.get_nal_unit_type_as_string().c_str();
    } else {
        qDebug() << "Got mjpeg frame";
    }
}

void GstRtpReceiver::start_receiving(NEW_FRAME_CALLBACK cb)
{
    qDebug() << "GstRtpReceiver::start_receiving begin";
    ensureGstInited();

    assert(m_gst_pipeline == nullptr);
    m_cb = std::move(cb);

    const auto pipeStr = construct_gstreamer_pipeline();
    qDebug() << "GSTREAMER PIPE = [" << pipeStr.c_str() << "]";

    GError *error = nullptr;
    m_gst_pipeline = gst_parse_launch(pipeStr.c_str(), &error);
    if (error) {
        qCritical() << "gst_parse_launch error:" << error->message;
        g_error_free(error);
        m_gst_pipeline = nullptr;
        return;
    }
    if (!m_gst_pipeline || !GST_IS_PIPELINE(m_gst_pipeline)) {
        qCritical() << "GST: Cannot construct pipeline";
        m_gst_pipeline = nullptr;
        return;
    }

    // Set PLAYING now; if elements missing, bus will report errors
    gst_element_set_state(m_gst_pipeline, GST_STATE_PLAYING);

    // Acquire appsink
    m_app_sink_element = gst_bin_get_by_name(GST_BIN(m_gst_pipeline), "out_appsink");
    if (!m_app_sink_element) {
        qCritical() << "GST: appsink 'out_appsink' not found";
        gst_element_set_state(m_gst_pipeline, GST_STATE_NULL);
        gst_object_unref(m_gst_pipeline);
        m_gst_pipeline = nullptr;
        return;
    }

    // Pull thread
    m_pull_samples_run = true;
    m_pull_samples_thread = std::make_unique<std::thread>(&GstRtpReceiver::loop_pull_samples, this);

    qDebug() << "GstRtpReceiver::start_receiving end";
}

void GstRtpReceiver::stop_receiving()
{
    m_pull_samples_run = false;

    if (m_pull_samples_thread) {
        m_pull_samples_thread->join();
        m_pull_samples_thread.reset();
    }

    if (m_app_sink_element) {
        gst_object_unref(m_app_sink_element);
        m_app_sink_element = nullptr;
    }

    if (m_gst_pipeline) {
        gst_element_send_event(GST_ELEMENT(m_gst_pipeline), gst_event_new_eos());
        gst_element_set_state(m_gst_pipeline, GST_STATE_PAUSED);
        gst_element_set_state(m_gst_pipeline, GST_STATE_NULL);
        gst_object_unref(m_gst_pipeline);
        m_gst_pipeline = nullptr;
    }
}
