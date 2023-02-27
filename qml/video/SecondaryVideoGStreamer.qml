import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import org.freedesktop.gstreamer.GLVideoItem 1.0;

import OpenHD 1.0

// R.n the only impl. for secondar video we have is using gstreamer & qmlglsink.
// This probably won't change - qmlglsink is easier to use, and the latency on the seconadry
// stream doesn't matter as much, since most of the time it is a thermal camera or similar
// Also, it is nice to automatically have all features needed for the secondary video like scaling, resizing ...

Item {
    // We use the full screen since while usually small in the lower left corner, the secondary video can be resized
    anchors.fill: parent

    // We start out minimized
    property bool has_been_maximized: false

    function get_video_width(){
        if(has_been_maximized){
            return settings.secondary_video_minimized_width * 2;
        }
        return settings.secondary_video_minimized_width;
    }
    function get_video_height(){
        if(has_been_maximized){
            return settings.secondary_video_minimized_height * 2;
        }
        return settings.secondary_video_minimized_height;
    }

    GstGLVideoItem {
        id: secondaryVideoGStreamer
        objectName: "secondaryVideoGStreamer"

        width: get_video_width()
        height: get_video_height()
        // We are always anchored to the lower left corner
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        Component.onCompleted: {
            console.log("secondaryVideoGStreamer (Qmlglsink) created")
            _secondary_video_gstreamer.check_common_mistakes_then_init(secondaryVideoGStreamer)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                //console.log("Clicked")
                // Toggle between maximized and minimized
                has_been_maximized = !has_been_maximized;
            }
        }
    }
}
