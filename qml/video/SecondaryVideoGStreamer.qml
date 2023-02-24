import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import org.freedesktop.gstreamer.GLVideoItem 1.0;


// R.n the only impl. for secondar video we have is using gstreamer & qmlglsink.
// This probably won't change - qmlglsink is easier to use, and the latency on the seconadry
// stream doesn't matter as much, since most of the time it is a thermal camera or similar
// Also, it is nice to automatically have all features needed for the secondary video like scaling, resizing ...

Item {
    // We use the full screen since while usually small in the lower left corner, the secondary video can be resized
    anchors.fill: parent
    property bool has_been_maximized: false
    property int savedSecondaryVideoBottomMargin: settings.secondVideoBottomMargin
    property int savedSecondaryVideoLeftMargin: settings.secondVideoLeftMargin

    GstGLVideoItem {
        id: secondaryVideoGStreamer
        objectName: "secondaryVideoGStreamer"

        width: settings.secondVideoWidth
        height: settings.secondVideoHeight
        anchors.bottom: parent.bottom
         Component.onCompleted: {
            console.log("secondaryVideoGStreamer (Qmlglsink) created")
            _secondary_video_gstreamer.check_common_mistakes_then_init(secondaryVideoGStreamer)
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            console.log("longpress")
            if (has_been_maximized) {
                // minimize
               settings.secondVideoWidth = settings.secondVideoMinWidth;
                settings.secondVideoHeight = settings.secondVideoMinHeight;

                has_been_maximized = false;
            } else {
                // maximize
                settings.secondVideoWidth = settings.secondVideoMinWidth * settings.secondVideoMaximiseFaktor/100;
                settings.secondVideoHeight = settings.secondVideoMinHeight * settings.secondVideoMaximiseFaktor/100;
                has_been_maximized = true;
            }
        }
    }

   }
