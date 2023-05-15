import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

ScrollView {
    id: appVideoSettingsView
    width: parent.width
    height: parent.height
    contentHeight: videoColumn.height

    clip: true
    visible: appSettingsBar.currentIndex == 4

    Item {
        anchors.fill: parent

        Column {
            id: videoColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            ListModel {
                id: itemsVideoCodec
                ListElement { text: "H264"; }
                ListElement { text: "H265";  }
                ListElement { text: "MJPEG"; }
            }

            SettingBaseElement{
                m_short_description: "Video codec primary"
                m_long_description: "Video codec of primary stream (main video). Automatically fetched from OpenHD."
                ComboBox {
                    id: selectVideoCodecPrimary
                    width: 320
                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                    model: itemsVideoCodec
                    Component.onCompleted: {
                        // out of bounds checking
                        if(settings.selectedVideoCodecPrimary>2 || settings.selectedVideoCodecPrimary<0){
                            settings.selectedVideoCodecPrimary=0;
                        }
                        currentIndex = settings.selectedVideoCodecPrimary;
                    }
                    onCurrentIndexChanged:{
                        console.debug("VideoCodec:"+itemsVideoCodec.get(currentIndex).text + ", "+currentIndex)
                        settings.selectedVideoCodecPrimary=currentIndex;
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Primary video force SW"
                m_long_description: "Force SW decode for primary video stream (unless it already defaulted to sw decode). Can fix bug(s) in rare hardware incompability cases."
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.primary_enable_software_video_decoder
                    onCheckedChanged: settings.primary_enable_software_video_decoder = checked
                }
            }
            SettingBaseElement{
                m_short_description: "Video codec secondary"
                m_long_description: "Video codec of secondary stream (pip video). Automatically fetched from OpenHD."
                ComboBox {
                    id: selectVideoCodecSecondary
                    width: 320
                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                    model: itemsVideoCodec
                    Component.onCompleted: {
                        // out of bounds checking
                        if(settings.selectedVideoCodecSecondary >2 || settings.selectedVideoCodecSecondary<0){
                            settings.selectedVideoCodecSecondary=0;
                        }
                        currentIndex = settings.selectedVideoCodecSecondary;
                    }
                    onCurrentIndexChanged:{
                        console.debug("VideoCodec:"+itemsVideoCodec.get(currentIndex).text + ", "+currentIndex)
                        settings.selectedVideoCodecSecondary=currentIndex;
                    }
                }
            }

            SettingBaseElement{
                m_short_description: "Secondary video force SW"
                m_long_description: "Force SW decode for secondary video stream (unless it already defaulted to sw decode). Can fix bug(s) in rare hardware incompability cases."
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.secondary_enable_software_video_decoder
                    onCheckedChanged: settings.secondary_enable_software_video_decoder = checked
                }
            }


            SettingBaseElement{
                m_short_description: "Backgrund transparent"
                m_long_description: "Use a transparent surface, such that another application can play (hw composer accelerated) video behind the QOpenHD surface."

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.app_background_transparent
                    onCheckedChanged: settings.app_background_transparent = checked
                }
            }

            SettingBaseElement{
                m_short_description: "Scale primary video to fit"
                m_long_description: "Fit the primary video to the exact screen size (discards actual video aspect ratio,aka video is a bit distorted). Not supported on all platforms / implementations. Might require a restart."

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.primary_video_scale_to_fit
                    onCheckedChanged: settings.primary_video_scale_to_fit = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("DEV_TEST_VIDEO_MODE")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                ComboBox {
                  width: 320
                  height: elementHeight
                  anchors.right: parent.right
                  anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.horizontalCenter: parent.horizonatalCenter
                  model: ListModel {
                   ListElement { text: "DISABLE"; }
                   ListElement { text: "RAW_VIDEO";  }
                   ListElement { text: "RAW_DECODE_ENCODE"; }
                 }
                  Component.onCompleted: {
                      // out of bounds checking
                      if(settings.dev_test_video_mode>2 || settings.dev_test_video_mode<0){
                          settings.dev_test_video_mode=0;
                      }
                      currentIndex = settings.dev_test_video_mode;
                  }
                 onCurrentIndexChanged:{
                     //console.debug("Dev video testing::"+model.get(currentIndex).text + ", "+currentIndex)
                     settings.dev_test_video_mode=currentIndex;
                 }
                }
            }
            // temporary
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_limit_fps_on_test_file")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                SpinBox {
                    id: dev_limit_fps_on_test_fileSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: -1
                    to: 240
                    stepSize: 1
                    editable: true
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.dev_limit_fps_on_test_file
                    onValueChanged: settings.dev_limit_fps_on_test_file = value
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_draw_alternating_rgb_dummy_frames")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_draw_alternating_rgb_dummy_frames
                    onCheckedChanged: settings.dev_draw_alternating_rgb_dummy_frames = checked
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_use_low_latency_parser_when_possible")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_use_low_latency_parser_when_possible
                    onCheckedChanged: settings.dev_use_low_latency_parser_when_possible = checked
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_feed_incomplete_frames_to_decoder")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_feed_incomplete_frames_to_decoder
                    onCheckedChanged: settings.dev_feed_incomplete_frames_to_decoder = checked
                }
            }
            // temporary end
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_stream0_udp_rtp_input_port")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                SpinBox {
                    id: dev_stream0_udp_rtp_input_port_input
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    stepSize: 1
                    editable: true
                    from:0
                    to: 100000
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.dev_stream0_udp_rtp_input_port
                    onValueChanged: settings.dev_stream0_udp_rtp_input_port = value
                }
            }
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_stream0_udp_rtp_input_ip_address")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                TextInput{
                    id: dev_stream0_udp_rtp_input_ip_address_ti
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    text: settings.dev_stream0_udp_rtp_input_ip_address
                    onEditingFinished: {
                        settings.dev_stream0_udp_rtp_input_ip_address = dev_stream0_udp_rtp_input_ip_address_ti.text
                    }
                }
            }
            // dirty
            SettingBaseElement{
                m_short_description: "dev_rpi_use_external_omx_decode_service"
                //m_long_description: "On by default, RPI specific."
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_rpi_use_external_omx_decode_service
                    onCheckedChanged: settings.dev_rpi_use_external_omx_decode_service = checked
                }
            }
            SettingBaseElement{
                m_short_description: "dev_always_use_generic_external_decode_service"
                //m_long_description: "Video decode is not done via QOpenHD, but rather in an extra service (started and stopped by QOpenHD). For platforms other than rpi"
                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_always_use_generic_external_decode_service
                    onCheckedChanged: settings.dev_always_use_generic_external_decode_service = checked
                }
            }
        }
    }
}
