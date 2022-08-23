#if defined(ENABLE_GSTREAMER)

#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>
#include <qquickitem.h>

#include <QtQml>
#include <gst/gst.h>

#include "QOpenHDVideoHelper.hpp"

/**
 * Consti10
 * This video player works purely in software (Gstreamer), but supports all the 3 OpenHD live video formats (h264,h265 and mjpeg).
 * Its inputs and outputs are easily defined:
 * 1) Input -> a udp port from which rtp video data is received.
 * 2) Output -> a qml window ???? not sure yet exactly how to call that.
 */
class GstVideoStream : public QObject{
    Q_OBJECT
public:
    /**
     * The constructor is delayed, remember to use init().
     */
    GstVideoStream(QObject *parent = nullptr);
    virtual ~GstVideoStream();
    /**
     * @brief after setting the output window, this does not immediately start streaming -
     * it starts a timer that checks in regular intervalls if any video-related settings (like the videoCodec) have changed
     * and then starts / re-starts the decoding and display process.
     * @param videoOutputWindow the qt window where the decoded data is displayed.
     * @param primaryStream primary and secondary stream use different UDP ports
     */
    void init(QQuickItem* videoOutputWindow,bool primaryStream);
    // for checking if video data actually arrives
    // public because set by static method
    qint64 lastDataTimeout = 0;
    void startVideo();
    void stopVideoSafe();
    // If we get error message(s) from gstreamer, we restart the stream in the hopes that fixes the issue
    // e.g. a fucked decoder from corrupted packets
    bool has_decoder_error=false;
    // This is called when the user clicks the dev restart video
    Q_INVOKABLE void dev_restart_stream();
private:
    /**
     * @brief fired by m_timer.
     * Checks every second if the video settings have changed, if so we restart the
     * stream and let the the pipeline be reconstructed using whichever video source is now enabled.
     */
    void timerCallback();
    // Where the video is output to.
    QQuickItem* m_videoOutputWindow;
    // The gstreamer pipeline
    GstElement * m_pipeline=nullptr;
    // the current configuration, is continously synced with settings
    QOpenHDVideoHelper::VideoStreamConfig m_videoStreamConfig;
    // runs every 1 second
    QTimer* timer = nullptr;
    bool m_isPrimaryStream=true;
    bool firstCheck=true;
};

#endif // OpenHDVideoStream_H

#endif
