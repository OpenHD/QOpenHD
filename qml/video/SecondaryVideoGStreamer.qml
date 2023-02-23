import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import org.freedesktop.gstreamer.GLVideoItem 1.0;

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
        anchors.leftMargin: settings.secondVideoLeftMargin

        Component.onCompleted: {
            console.log("secondaryVideoGStreamer (Qmlglsink) created")
            _secondary_video_gstreamer.check_common_mistakes_then_init(secondaryVideoGStreamer)
        }
    }

    MouseArea {
        anchors.fill: parent
        drag.target: secondaryVideoGStreamer
        onPositionChanged: {
            secondaryVideoGStreamer.anchors.bottomMargin = parent.height - drag.activeY
            secondaryVideoGStreamer.anchors.leftMargin = drag.activeX

            savedSecondaryVideoBottomMargin = secondaryVideoGStreamer.anchors.bottomMargin
            savedSecondaryVideoLeftMargin = secondaryVideoGStreamer.anchors.leftMargin
           }

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
