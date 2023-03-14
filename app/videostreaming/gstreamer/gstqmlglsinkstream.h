#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>
#include <qquickitem.h>

#include <QtQml>
#include <gst/gst.h>

#include "QOpenHDVideoHelper.hpp"

/**
 * Consti10
 * This video player uses gstreamer + qmlglsink to display video inside qt.
 * It supports all the 3 OpenHD live video formats (h264,h265 and mjpeg), by falling back to sw decode when hw decode is not available.
 * Note that the qmlglsink path is not ideal, since for example on the rpi, each video frame is rendered 2x by OpenGl (first YUV->RGBA, then RGBA in the
 * qt scenegraph composer).
 * Its inputs and outputs are easily defined:
 * 1) Input -> a udp port from which rtp video data (h264,h265,mjpeg) is received.
 * 2) Output -> a qmlglsink with the item registered in qt (qml,GstGLVideoItem).
 * It allows dynamically changing the video resolution, framerate and/or video codec.
 */
class GstQmlGlSinkStream : public QObject{
    Q_OBJECT
public:
    /**
     * The constructor is delayed, remember to use init().
     * @param is_primary: weather to use the settings for primary or secondary video stream
     */
    GstQmlGlSinkStream(bool is_primary,QObject *parent = nullptr);
    virtual ~GstQmlGlSinkStream();
    // These are registered for qml
    static GstQmlGlSinkStream& instancePrimary();
    static GstQmlGlSinkStream& instanceSecondary();
    /**
     * @brief after setting the output window, this does not immediately start streaming -
     * it starts a timer that checks in regular intervalls if any video-related settings (like the videoCodec) have changed
     * and then starts / re-starts the decoding and display process.
     * @param videoOutputWindow the qt window where the decoded data is displayed.
     * @param primaryStream primary and secondary stream use different UDP ports
     */
    void init(QQuickItem* videoOutputWindow);
    // Avoid common bugs from qml that could crash the whole application when propagated to c++
    Q_INVOKABLE void check_common_mistakes_then_init(QQuickItem* qmlglsinkvideoitem);
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
    QQuickItem* m_videoOutputWindow=nullptr;
    // The gstreamer pipeline
    GstElement * m_pipeline=nullptr;
    // the current configuration, is continously synced with settings
    QOpenHDVideoHelper::VideoStreamConfig m_videoStreamConfig;
    // runs every 1 second
    QTimer* timer = nullptr;
    const bool m_isPrimaryStream;
    bool firstCheck=true;
    //
    int nTimesVideoQmlElementNotSet=0;
};

#endif // OpenHDVideoStream_H
