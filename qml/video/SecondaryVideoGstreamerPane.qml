import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// QT creator might show "not found" on this import, this is okay, annoying qt specifics
import org.freedesktop.gstreamer.GLVideoItem 1.0;

import OpenHD 1.0

import "../ui/elements"

GstGLVideoItem {
    id: secondaryVideoGStreamer
    objectName: "secondaryVideoGStreamer"
    z: 0.0

    Component.onCompleted: {
        console.log("secondaryVideoGStreamer (Qmlglsink) created")
        _secondary_video_gstreamer_qml.check_common_mistakes_then_init(secondaryVideoGStreamer)
    }
}
