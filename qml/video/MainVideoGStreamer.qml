import QtQuick 2.12


import org.freedesktop.gstreamer.GLVideoItem 1.0;

// NOTE: Deprecated, gstreamer and qmlglsink is not a valid solution for low latency video playback

GstGLVideoItem {
    anchors.fill: parent
    id: mainVideoGStreamer
    objectName: "mainVideoGStreamer"

    Component.onCompleted: {
        console.log("mainVideoGStreamer (Qmlglsink) created")
        _primary_video_gstreamer_qml.check_common_mistakes_then_init(mainVideoGStreamer)
    }

}
