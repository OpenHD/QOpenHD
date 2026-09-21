#include "gstrtpaudioplayer.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QSettings>
#include <QStandardPaths>
#include <QtMath>
#include <gst/gst.h>
#include <logging/logmessagesmodel.h>

G_BEGIN_DECLS
#if defined(__android__) || defined(__ios__)
GST_PLUGIN_STATIC_DECLARE(coreelements);
GST_PLUGIN_STATIC_DECLARE(playback);
GST_PLUGIN_STATIC_DECLARE(libav);
GST_PLUGIN_STATIC_DECLARE(rtp);
GST_PLUGIN_STATIC_DECLARE(rtsp);
GST_PLUGIN_STATIC_DECLARE(udp);
GST_PLUGIN_STATIC_DECLARE(videoparsersbad);
GST_PLUGIN_STATIC_DECLARE(x264);
GST_PLUGIN_STATIC_DECLARE(rtpmanager);
GST_PLUGIN_STATIC_DECLARE(isomp4);
GST_PLUGIN_STATIC_DECLARE(matroska);
GST_PLUGIN_STATIC_DECLARE(mpegtsdemux);
GST_PLUGIN_STATIC_DECLARE(opengl);
GST_PLUGIN_STATIC_DECLARE(tcp);
GST_PLUGIN_STATIC_DECLARE(app);
#if defined(__android__)
GST_PLUGIN_STATIC_DECLARE(androidmedia);
#elif defined(__ios__)
GST_PLUGIN_STATIC_DECLARE(applemedia);
#endif
#endif
GST_PLUGIN_STATIC_DECLARE(qmlgl);
GST_PLUGIN_STATIC_DECLARE(qgc);
G_END_DECLS

namespace {
QString quoteGst(QString value)
{
    value.replace('\\', "\\\\");
    value.replace('"', "\\\"");
    return QStringLiteral("\"") + value + QStringLiteral("\"");
}
}

GstRtpAudioPlayer::GstRtpAudioPlayer(QObject *parent) : QObject(parent)
{
#if defined(__android__) || defined(__ios__)
    GST_PLUGIN_STATIC_REGISTER(coreelements);
    GST_PLUGIN_STATIC_REGISTER(playback);
    GST_PLUGIN_STATIC_REGISTER(libav);
    GST_PLUGIN_STATIC_REGISTER(rtp);
    GST_PLUGIN_STATIC_REGISTER(rtsp);
    GST_PLUGIN_STATIC_REGISTER(udp);
    GST_PLUGIN_STATIC_REGISTER(videoparsersbad);
    GST_PLUGIN_STATIC_REGISTER(x264);
    GST_PLUGIN_STATIC_REGISTER(rtpmanager);
    GST_PLUGIN_STATIC_REGISTER(isomp4);
    GST_PLUGIN_STATIC_REGISTER(matroska);
    GST_PLUGIN_STATIC_REGISTER(mpegtsdemux);
    GST_PLUGIN_STATIC_REGISTER(opengl);
    GST_PLUGIN_STATIC_REGISTER(tcp);
    GST_PLUGIN_STATIC_REGISTER(app);
#if defined(__android__)
    GST_PLUGIN_STATIC_REGISTER(androidmedia);
#elif defined(__ios__)
    GST_PLUGIN_STATIC_REGISTER(applemedia);
#endif
#endif
    QSettings settings;
    m_selectedOutputDevice = settings.value("audio_output_device", "").toString();
    m_playbackVolume = qBound(0, settings.value("audio_playback_volume", 100).toInt(), 100);
    m_busTimer.setInterval(50);
    connect(&m_busTimer, &QTimer::timeout, this, &GstRtpAudioPlayer::pollBus);
}

GstRtpAudioPlayer::~GstRtpAudioPlayer() { stop_playing(); }

GstRtpAudioPlayer &GstRtpAudioPlayer::instance()
{
    static GstRtpAudioPlayer instance{};
    return instance;
}

void GstRtpAudioPlayer::refreshDevices()
{
    QStringList names{tr("System default")};
    QStringList ids{QString()};
    GstDeviceMonitor *monitor = gst_device_monitor_new();
    gst_device_monitor_add_filter(monitor, "Audio/Sink", nullptr);
    if (gst_device_monitor_start(monitor)) {
        GList *devices = gst_device_monitor_get_devices(monitor);
        for (GList *entry = devices; entry; entry = entry->next) {
            auto *device = GST_DEVICE(entry->data);
            GstElement *element = gst_device_create_element(device, nullptr);
            if (!element) continue;
            GstElementFactory *factory = gst_element_get_factory(element);
            const gchar *factoryName = factory ? gst_plugin_feature_get_name(GST_PLUGIN_FEATURE(factory)) : nullptr;
            gchar *deviceValue = nullptr;
            if (g_object_class_find_property(G_OBJECT_GET_CLASS(element), "device"))
                g_object_get(element, "device", &deviceValue, nullptr);
            const QString id = QString::fromUtf8(factoryName ? factoryName : "") + "|" + QString::fromUtf8(deviceValue ? deviceValue : "");
            const QString name = QString::fromUtf8(gst_device_get_display_name(device));
            if (factoryName && !ids.contains(id)) {
                ids.append(id);
                names.append(name.isEmpty() ? id : name);
            }
            if (deviceValue) g_free(deviceValue);
            gst_object_unref(element);
        }
        g_list_free_full(devices, gst_object_unref);
        gst_device_monitor_stop(monitor);
    }
    gst_object_unref(monitor);
    m_outputDeviceNames = names;
    m_outputDeviceIds = ids;
    if (!m_selectedOutputDevice.isEmpty() && !ids.contains(m_selectedOutputDevice)) {
        m_selectedOutputDevice.clear();
        QSettings().setValue("audio_output_device", m_selectedOutputDevice);
        emit selectedOutputDeviceChanged();
    }
    emit outputDevicesChanged();
}

void GstRtpAudioPlayer::setPlaybackEnabled(bool enabled)
{
    QSettings().setValue("dev_enable_live_audio_playback", enabled);
    enabled ? start_playing() : stop_playing();
}

void GstRtpAudioPlayer::setSelectedOutputDevice(const QString &deviceId)
{
    if (m_selectedOutputDevice == deviceId) return;
    m_selectedOutputDevice = deviceId;
    QSettings().setValue("audio_output_device", deviceId);
    emit selectedOutputDeviceChanged();
    restartIfPlaying();
}

void GstRtpAudioPlayer::setPlaybackVolume(int volume)
{
    volume = qBound(0, volume, 100);
    if (m_playbackVolume == volume) return;
    m_playbackVolume = volume;
    QSettings().setValue("audio_playback_volume", volume);
    if (m_pipeline) {
        GstElement *element = gst_bin_get_by_name(GST_BIN(m_pipeline), "playback_volume");
        if (element) {
            g_object_set(element, "volume", volume / 100.0, nullptr);
            gst_object_unref(element);
        }
    }
    emit playbackVolumeChanged();
}

void GstRtpAudioPlayer::setRecording(bool recording)
{
    if (m_recording == recording) return;
    m_recording = recording;
    emit recordingChanged();
    restartIfPlaying();
}

QString GstRtpAudioPlayer::sinkDescription() const
{
    const QStringList parts = m_selectedOutputDevice.split('|');
    if (parts.size() != 2 || parts[0].isEmpty()) return QStringLiteral("autoaudiosink sync=false");
    QString sink = parts[0];
    if (!parts[1].isEmpty()) sink += QStringLiteral(" device=") + quoteGst(parts[1]);
    return sink + QStringLiteral(" sync=false");
}

QString GstRtpAudioPlayer::createRecordingPath() const
{
    QString base = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    if (base.isEmpty()) base = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QDir dir(base + QStringLiteral("/OpenHD"));
    dir.mkpath(QStringLiteral("."));
    return dir.filePath(QStringLiteral("audio_%1.wav").arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss")));
}

QString GstRtpAudioPlayer::constructPipeline()
{
    QString pipeline = QStringLiteral(
        "udpsrc port=5610 caps=\"application/x-rtp, media=(string)audio, clock-rate=(int)8000, encoding-name=(string)PCMA\" "
        "! rtppcmadepay ! audio/x-alaw, rate=8000, channels=1 ! alawdec ! audioconvert "
        "! level name=input_level interval=50000000 post-messages=true "
        "! volume name=playback_volume volume=%1 "
        "! level name=output_level interval=50000000 post-messages=true ! tee name=t "
        "t. ! queue ! %2").arg(m_playbackVolume / 100.0, 0, 'f', 2).arg(sinkDescription());
    if (m_recording) {
        m_recordingPath = createRecordingPath();
        emit recordingPathChanged();
        pipeline += QStringLiteral(" t. ! queue ! wavenc ! filesink location=%1").arg(quoteGst(m_recordingPath));
    }
    return pipeline;
}

void GstRtpAudioPlayer::start_playing()
{
    if (m_pipeline) return;
    const QByteArray pipeline = constructPipeline().toUtf8();
    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipeline.constData(), &error);
    if (error) {
        onError(QString::fromUtf8(error->message));
        g_error_free(error);
        if (m_pipeline) gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
        return;
    }
    if (!m_pipeline || !GST_IS_PIPELINE(m_pipeline)) {
        onError(QStringLiteral("Cannot construct audio pipeline"));
        if (m_pipeline) gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
        return;
    }
    gst_element_set_state(m_pipeline, GST_STATE_PLAYING);
    m_pipelineRecording = m_recording;
    m_busTimer.start();
    emit playingChanged();
}

void GstRtpAudioPlayer::stop_playing()
{
    if (!m_pipeline) return;
    m_busTimer.stop();
    gst_element_send_event(m_pipeline, gst_event_new_eos());
    if (m_pipelineRecording) {
        GstBus *bus = gst_element_get_bus(m_pipeline);
        GstMessage *message = gst_bus_timed_pop_filtered(bus, 2 * GST_SECOND,
                                                         static_cast<GstMessageType>(GST_MESSAGE_EOS | GST_MESSAGE_ERROR));
        if (message) gst_message_unref(message);
        gst_object_unref(bus);
    }
    gst_element_set_state(m_pipeline, GST_STATE_NULL);
    gst_object_unref(m_pipeline);
    m_pipeline = nullptr;
    m_pipelineRecording = false;
    if (m_inputLevel != 0) { m_inputLevel = 0; emit inputLevelChanged(); }
    if (m_outputLevel != 0) {
        m_outputLevel = 0;
        emit outputLevelChanged();
        emit audioLevelChanged();
    }
    emit playingChanged();
}

void GstRtpAudioPlayer::restartIfPlaying()
{
    if (!m_pipeline) return;
    stop_playing();
    start_playing();
}

void GstRtpAudioPlayer::pollBus()
{
    if (!m_pipeline) return;
    GstBus *bus = gst_element_get_bus(m_pipeline);
    while (GstMessage *message = gst_bus_pop_filtered(bus, static_cast<GstMessageType>(GST_MESSAGE_ELEMENT | GST_MESSAGE_ERROR))) {
        if (GST_MESSAGE_TYPE(message) == GST_MESSAGE_ERROR) {
            GError *error = nullptr; gchar *debug = nullptr;
            gst_message_parse_error(message, &error, &debug);
            onError(error ? QString::fromUtf8(error->message) : QStringLiteral("Audio pipeline error"));
            if (error) g_error_free(error);
            g_free(debug);
        } else {
            const GstStructure *structure = gst_message_get_structure(message);
            if (structure && gst_structure_has_name(structure, "level")) {
                const GValue *peaks = gst_structure_get_value(structure, "peak");
                if (peaks && GST_VALUE_HOLDS_LIST(peaks) && gst_value_list_get_size(peaks) > 0) {
                    const double db = g_value_get_double(gst_value_list_get_value(peaks, 0));
                    const int level = qBound(0, qRound((db + 60.0) * 100.0 / 60.0), 100);
                    const QString sourceName = QString::fromUtf8(GST_OBJECT_NAME(GST_MESSAGE_SRC(message)));
                    if (sourceName == QStringLiteral("input_level") && level != m_inputLevel) {
                        m_inputLevel = level;
                        emit inputLevelChanged();
                    } else if (sourceName == QStringLiteral("output_level") && level != m_outputLevel) {
                        m_outputLevel = level;
                        emit outputLevelChanged();
                        emit audioLevelChanged();
                    }
                }
            }
        }
        gst_message_unref(message);
    }
    gst_object_unref(bus);
}

void GstRtpAudioPlayer::onError(const QString &tag)
{
    qWarning() << "Audio:" << tag;
    LogMessagesModel::instanceGround().add_message_debug("QOpenHD", tag);
}
