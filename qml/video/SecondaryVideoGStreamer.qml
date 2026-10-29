import QtQuick 2.12

import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import OpenHD 1.0

import "../ui/elements"

// The platform backend renders inside this shared secondary video panel.
// NXP uses native Hantro/EGL; the other platform renderers keep their existing
// sizing, minimize/maximize and settings controls here.

Item {
    id: secondary_video_item
    visible: settings.secondary_camera_available
    // We use the full screen since while usually small in the lower left corner, the secondary video can be resized
    anchors.fill: parent
    anchors.left: parent.left
    anchors.bottom: parent.bottom

    // We start out minimized
    property bool has_been_maximized: false

    function get_video_width(){
        var video_width = settings.secondary_video_minimized_width;
        if(has_been_maximized){
            const maximize_factor = settings.secondary_video_maximize_factor_perc / 100;
            video_width = video_width * maximize_factor;
        }
        const screen_width = secondary_video_item.width;
        return video_width < screen_width ? video_width : screen_width;
        //return video_width;
    }
    function get_video_height(){
        var video_height = settings.secondary_video_minimized_height;
        if(has_been_maximized){
            const maximize_factor = settings.secondary_video_maximize_factor_perc / 100;
            video_height = video_height * maximize_factor;
        }
        const screen_height = secondary_video_item.height;
        return video_height < screen_height ? video_height : screen_height;
        //return video_height;
    }

    // This is for debugging / showing the video widget area at run time
    Rectangle{
        z: 1.0
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
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("onClicked");
                has_been_maximized = !has_been_maximized;
            }
            onPressAndHold: {
                console.log("onPressAndHold");
                // open the popup containing the settings
                popup.open()
            }
        }

    }

    Text{
        anchors.fill: video_holder
        visible: !(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC || QOPENHD_ENABLE_NXP_VIDEO) || !_decodingStatistics.secondary_video_active
        text: {
            if (QOPENHD_ENABLE_GSTREAMER_QMLGLSINK || QOPENHD_ENABLE_VIDEO_VIA_AVCODEC || QOPENHD_ENABLE_NXP_VIDEO){
                return qsTr("WAITING FOR\nSECONDARY VIDEO");
            }
            return qsTr("SECONDARY VIDEO\nNOT AVAILABLE\nON THIS PLATFORM");
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
            if(settings.secondary_camera_available){
                if (QOPENHD_ENABLE_NXP_VIDEO)
                    return "SecondaryVideoNxp.qml";
                if (QOPENHD_ENABLE_VIDEO_VIA_ANDROID){
                    return "SecondaryVideoAndroid.qml";
                }
                // R.N the only implementation for secondary video
                if (QOPENHD_ENABLE_GSTREAMER_QMLGLSINK){
                    return "SecondaryVideoGstreamerPane.qml";
                }
                if (QOPENHD_ENABLE_VIDEO_VIA_AVCODEC)
                    return "SecondaryVideoQSG.qml";
                console.warn("No secondary video implementation")
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
    /*Text{
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
    }*/

    SecondaryVideoSettingsPopup { id: popup }
}
