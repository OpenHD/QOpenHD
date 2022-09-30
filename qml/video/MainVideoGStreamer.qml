import QtQuick 2.12
import QtGraphicalEffects 1.12

import org.freedesktop.gstreamer.GLVideoItem 1.0;

// NOTE: Deprecated, gstreamer and qmlglsink is not a valid solution for low latency video playback

GstGLVideoItem {
    anchors.fill: parent
    id: mainVideoGStreamer
    objectName: "mainVideoGStreamer"
}
