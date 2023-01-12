import QtQuick 2.12
import QtGraphicalEffects 1.12

import org.freedesktop.gstreamer.GLVideoItem 1.0;

// R.n the only impl. for secondar video we have is using gstreamer & qmlglsink.
// This probably won't change - qmlglsink is easier to use, and the latency on the seconadry
// stream doesn't matter as much, since most of the time it is a thermal camera or similar
GstGLVideoItem {
    id: secondaryVideoGStreamer
    objectName: "secondaryVideoGStreamer"
}
