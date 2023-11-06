import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import OpenHD 1.0

import "../ui/elements"

// R.n the only impl. for secondar video we have is using gstreamer & qmlglsink.
// This probably won't change - qmlglsink is easier to use, and the latency on the seconadry
// stream doesn't matter as much, since most of the time it is a thermal camera or similar
// Also, it is nice to automatically have all features needed for the secondary video like scaling, resizing ...

Item {
    visible: settings.dev_qopenhd_n_cameras>1
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
        z: 0.0
        id: video_holder
        width: get_video_width()
        height: get_video_height()
        anchors.bottom: parent.bottom
        //width: get_video_width()
        //height: get_video_height()
        //anchors.bottom: parent.bottom
        //anchors.left: parent.left
        //color: "red"
        //color: popup.opened ? "red" : "transparent"
        color: "gray"
        opacity: 0.1
        //visible: popup.visible
    }

    Text{
        anchors.fill: video_holder
        text: {
            if (QOPENHD_ENABLE_GSTREAMER_QMLGLSINK){
                return "WAITING FOR\nSECONDARY VIDEO";
            }
            return "SECONDARY VIEO\nNOT AVAILABLE\nON THIS PLATFORM";
        }
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: 14
        color: "white"
    }

    Loader {
        z: 0.0
        anchors.fill: video_holder
        source: {
            if(settings.dev_qopenhd_n_cameras>1){
                // R.N the only implementation for secondary video
                if (QOPENHD_ENABLE_GSTREAMER_QMLGLSINK){
                    return "SecondaryVideoGstreamerPane.qml";
                }else{
                    console.warn("No secondary video implementation")
                }
            }else{
                console.debug("Scondary video disabled");
            }
            return "";
        }
    }

    /*Button{
        id: button_maximize
        text: "\uf31e";
        width: 24
        height: 24
        anchors.right: video_holder.right
        anchors.top: video_holder.top
        onClicked: {
            console.log("Button clicked");
            has_been_maximized = !has_been_maximized;
        }
    }*/
    /*Button{
        text:"S"
        anchors.right: button_maximize.left
        anchors.rightMargin: 2
        anchors.top: button_maximize.top
        onClicked: {
            popup.open()
        }
        visible: has_been_maximized
    }*/
    Text{
        id: button_maximize
        color: "white"
        text: "\uf31e"
        font.family: "Font Awesome 5 Free"
        width: 40
        height: 40
        anchors.right: video_holder.right
        anchors.top: video_holder.top
        font.pixelSize: 19
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
                has_been_maximized = !has_been_maximized;
            }
        }
    }
    Text{
        id: button_settings
        color: "white"
        text: "\uf013"
        font.family: "Font Awesome 5 Free"
        width: 40
        height: 40
        anchors.right: button_maximize.left
        anchors.rightMargin: 2
        anchors.top: button_maximize.top
        font.pixelSize: 19
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
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
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
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

