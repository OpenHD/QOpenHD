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

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true

                Text {
                    text: qsTr("Always use software video decoder")
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
                    checked: settings.enable_software_video_decoder
                    onCheckedChanged: settings.enable_software_video_decoder = checked
                }
            }

            ListModel {
                id: itemsVideoCodec
                ListElement { text: "H264"; }
                ListElement { text: "H265";  }
                ListElement { text: "MJPEG"; }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("Video Codec primary")
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
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("Video Codec Secondary")
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

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true

                Text {
                    text: qsTr("Hide warning watermark")
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
                    checked: settings.hide_watermark
                    onCheckedChanged: settings.hide_watermark = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true

                Text {
                    text: qsTr("Background Transparent")
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
                    checked: settings.app_background_transparent
                    onCheckedChanged: settings.app_background_transparent = checked
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
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("dev_rpi_use_external_omx_decode_service")
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
                    checked: settings.dev_rpi_use_external_omx_decode_service
                    onCheckedChanged: settings.dev_rpi_use_external_omx_decode_service = checked
                }
            }
        }
    }
}
