import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Dirty here i place stuff that can be usefaully during development
Rectangle {
    id: elementAppDeveloperStats
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    function yes_or_no_as_string(yes){
        if(yes)return "Y"
        return "N"
    }

    function get_features_string(){
        var ret=""
        ret+="AVCODEC:"+yes_or_no_as_string(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC)+", "
        ret+="MMAL:"+yes_or_no_as_string(QOPENHD_HAVE_MMAL)+", "
        ret+="GSTREAMER:"+yes_or_no_as_string(QOPENHD_ENABLE_GSTREAMER) //+", "
        return ret;
    }

    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Button{
            height: 24
            text: "Restart local OHD service"
            onClicked:{
                _qopenhd.restart_local_oenhd_service()
            }
        }
        Button{
            id: local_ip_button
            height: 24
            text: "Show local IP"
            onClicked:{
                var text=_qopenhd.show_local_ip()
                local_ip_button.text=text
            }
        }

        /*Button{
            height: 24
            text: "Run dhclient eth0 (might block UI for N seconds)"
            onClicked:{
                _qopenhd.run_dhclient_eth0()
            }
        }*/
        Text {
            id: test1
            text: qsTr("Art Horizon mavlink update rate:"+_fcMavlinkSystem.curr_update_rate_mavlink_message_attitude+" Hz")
        }
        // air
        Text {
            id: test2
            text: qsTr("video0 FEC encode:  "+_cameraStreamModelPrimary.curr_video0_fec_encode_time_avg_min_max)
        }
        Text {
            id: test4
            text: qsTr("video0 FEC block length:  "+_cameraStreamModelPrimary.curr_video0_fec_block_length_min_max_avg)
        }
        // ground
        Text {
            id: test3
            text: qsTr("video0 FEC decode:  "+_cameraStreamModelPrimary.curr_video0_fec_decode_time_avg_min_max)
        }

        Text {
            id: test5
            text: qsTr("FEATURES:  "+get_features_string())
        }
    }
}
