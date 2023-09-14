import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// QT creator might show "not found" on this import, this is okay, annoying qt specifics
import org.freedesktop.gstreamer.GLVideoItem 1.0;

import OpenHD 1.0

import "../ui/elements"

// R.n the only impl. for secondar video we have is using gstreamer & qmlglsink.
// This probably won't change - qmlglsink is easier to use, and the latency on the seconadry
// stream doesn't matter as much, since most of the time it is a thermal camera or similar
// Also, it is nice to automatically have all features needed for the secondary video like scaling, resizing ...

Item {
    // We use the full screen since while usually small in the lower left corner, the secondary video can be resized
    anchors.fill: parent
    anchors.left: parent.left
    anchors.bottom: parent.bottom

    // We start out minimized
    property bool has_been_maximized: false

    function get_video_width(){
        if(has_been_maximized){
            var maximize_factor = settings.secondary_video_maximize_factor_perc / 100;
            return settings.secondary_video_minimized_width * maximize_factor;
        }
        return settings.secondary_video_minimized_width;
    }
    function get_video_height(){
        if(has_been_maximized){
            var maximize_factor = settings.secondary_video_maximize_factor_perc / 100;
            return settings.secondary_video_minimized_height * maximize_factor;
        }
        return settings.secondary_video_minimized_height;
    }

    // This is for debugging / showing the video widget area at run time
    Rectangle{
        id: video_holder
        width: get_video_width()
        height: get_video_height()
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: "red"
        visible: popup.visible
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
            _secondary_video_gstreamer_qml.check_common_mistakes_then_init(secondaryVideoGStreamer)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                //console.log("Clicked")
                // Toggle between maximized and minimized
                has_been_maximized = !has_been_maximized;
            }
            onPressAndHold: {
                console.log("onPressAndHold");
                // open the popup containing the settings
                popup.open()
            }
        }
    }
    property int rowHeight: 64
    // This popup allows changing the settings for this element
    Popup {
        id: popup
        x: 100
        y: 100
        width: 500
        height: 300
        modal: true
        //focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        /*background: Rectangle {
            color: "gray"
            border.color: "black"
        }*/
        Pane{
            ColumnLayout {
                anchors.fill: parent
                anchors.centerIn: parent
                anchors.left: parent.Left
                anchors.right: parent.right

                RowLayout{
                    height:rowHeight
                    width:parent.width
                    Layout.fillWidth: true
                    Text{
                        width: 100
                        text: "Minimized Width (px)"
                    }
                    SpinBox {
                        stepSize: 1
                        editable: true
                        from:25
                        to: 500
                        value: settings.secondary_video_minimized_width
                        onValueChanged: settings.secondary_video_minimized_width = value
                    }
                }
                RowLayout{
                    height:rowHeight
                    width:parent.width
                    Layout.fillWidth: true
                    Text{
                        width: 100
                        text: "Minimized Height (px)"
                    }
                    SpinBox {
                        stepSize: 1
                        editable: true
                        from:25
                        to: 500
                        value: settings.secondary_video_minimized_height
                        onValueChanged: settings.secondary_video_minimized_height = value
                    }
                }
                RowLayout{
                    height:rowHeight
                    width:parent.width
                    Layout.fillWidth: true
                    Text{
                        width: 100
                        text: "Maximize factor %"
                    }
                    SpinBox {
                        stepSize: 1
                        editable: true
                        from:120
                        to: 800
                        value: settings.secondary_video_maximize_factor_perc
                        onValueChanged: settings.secondary_video_maximize_factor_perc = value
                    }
                }
            }
        }
    }
}

