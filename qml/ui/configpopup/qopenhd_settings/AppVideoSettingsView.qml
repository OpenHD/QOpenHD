import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    id: appVideoSettingsView
    width: parent.width
    height: parent.height
    contentHeight: videoColumn.height

    clip: true

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
            }
            SettingBaseElement{
                m_short_description:  "Number of Cameras" //will be removed in the future, we just should autodetect it

                SpinBox {
                    id: dev_qopenhd_n_cameras_spinbox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 2
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.dev_qopenhd_n_cameras
                    onValueChanged: {
                        var actually_changed=settings.dev_qopenhd_n_cameras!=value
                        settings.dev_qopenhd_n_cameras = value
                        if(actually_changed){
                            _restartqopenhdmessagebox.show()
                        }
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Scale primary video to fit screen"

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.primary_video_scale_to_fit
                    onCheckedChanged: settings.primary_video_scale_to_fit = checked
                    enabled: _qopenhd.is_android() || (_qopenhd.is_linux() && (!_qopenhd.is_platform_rock() && !_qopenhd.is_platform_rpi()))
                }
            }
            SettingBaseElement{
                    m_short_description: "Switch primary / secondary video"
                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.qopenhd_switch_primary_secondary
                        onCheckedChanged: settings.qopenhd_switch_primary_secondary = checked
                    }
                }


            SettingsCategory{
                m_description: "Advanced Settings"
                m_hide_elements: true

                SettingBaseElement{
                    m_short_description: "Primary video codec"
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
                            if(settings.qopenhd_primary_video_codec>2 || settings.qopenhd_primary_video_codec<0){
                                settings.qopenhd_primary_video_codec=0;
                            }
                            currentIndex = settings.qopenhd_primary_video_codec;
                        }
                        onCurrentIndexChanged:{
                            console.debug("VideoCodec:"+itemsVideoCodec.get(currentIndex).text + ", "+currentIndex)
                            settings.qopenhd_primary_video_codec=currentIndex;
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: "Use Software Decode"
                    Switch {
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.qopenhd_primary_video_force_sw
                        onCheckedChanged: {
                        settings.qopenhd_primary_video_force_sw = checked
                        settings.qopenhd_secondary_video_force_sw = checked
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: "Primary video udp port"
                    SpinBox {
                        height: elementHeight
                        width: 210
                        font.pixelSize: 14
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        from: 1
                        to: 6900
                        stepSize: 1
                        editable: true
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        value: settings.qopenhd_primary_video_rtp_input_port
                        onValueChanged: settings.qopenhd_primary_video_rtp_input_port = value
                    }
                }
                SettingBaseElement{
                    m_short_description: "Secondary video codec"
                    // only show to dualcam users
                    visible: settings.dev_qopenhd_n_cameras==2
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
                            if(settings.qopenhd_secondary_video_codec >2 || settings.qopenhd_secondary_video_codec<0){
                                settings.qopenhd_secondary_video_codec=0;
                            }
                            currentIndex = settings.qopenhd_secondary_video_codec;
                        }
                        onCurrentIndexChanged:{
                            console.debug("VideoCodec:"+itemsVideoCodec.get(currentIndex).text + ", "+currentIndex)
                            settings.qopenhd_secondary_video_codec=currentIndex;
                        }
                    }
                }
                // SettingBaseElement{
                //     m_short_description: "Secondary video force SW"
                //     m_long_description: "Force SW decode for secondary video stream (unless it already defaulted to sw decode). Can fix bug(s) in rare hardware incompability cases."
                //     // only show to dualcam users
                //     visible: false //settings.dev_qopenhd_n_cameras==2
                //     Switch {
                //         width: 32
                //         height: elementHeight
                //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                //         anchors.right: parent.right
                //         anchors.verticalCenter: parent.verticalCenter
                //         checked: settings.qopenhd_secondary_video_force_sw
                //         onCheckedChanged: settings.qopenhd_secondary_video_force_sw = checked
                //     }
                // }
                SettingBaseElement{
                    m_short_description: "Secondary video udp port"
                    visible: settings.dev_qopenhd_n_cameras==2
                    SpinBox {
                        height: elementHeight
                        width: 210
                        font.pixelSize: 14
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        from: 1
                        to: 6900
                        stepSize: 1
                        editable: true
                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        value: settings.qopenhd_secondary_video_rtp_input_port
                        onValueChanged: settings.qopenhd_secondary_video_rtp_input_port = value
                    }
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                    Text {
                        text: qsTr("Video test mode")
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
                        text: qsTr("Limit FPS in test file")
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
                // Rectangle {
                //     width: parent.width
                //     height: rowHeight
                //     color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                //     visible:false


                //     Text {
                //         text: qsTr("Draw RGB dummy frames")
                //         font.weight: Font.Bold
                //         font.pixelSize: 13
                //         anchors.leftMargin: 8
                //         verticalAlignment: Text.AlignVCenter
                //         anchors.verticalCenter: parent.verticalCenter
                //         width: 224
                //         height: elementHeight
                //         anchors.left: parent.left
                //     }
                //     Switch {
                //         width: 32
                //         height: elementHeight
                //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                //         anchors.right: parent.right
                //         anchors.verticalCenter: parent.verticalCenter
                //         checked: settings.dev_draw_alternating_rgb_dummy_frames
                //         onCheckedChanged: settings.dev_draw_alternating_rgb_dummy_frames = checked
                //     }
                // }
                // Rectangle {
                //     width: parent.width
                //     height: rowHeight
                //     color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                //     visible:false


                //     Text {
                //         text: qsTr("dev_use_low_latency_parser_when_possible")
                //         font.weight: Font.Bold
                //         font.pixelSize: 13
                //         anchors.leftMargin: 8
                //         verticalAlignment: Text.AlignVCenter
                //         anchors.verticalCenter: parent.verticalCenter
                //         width: 224
                //         height: elementHeight
                //         anchors.left: parent.left
                //     }
                //     Switch {
                //         width: 32
                //         height: elementHeight
                //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                //         anchors.right: parent.right
                //         anchors.verticalCenter: parent.verticalCenter
                //         checked: settings.dev_use_low_latency_parser_when_possible
                //         onCheckedChanged: settings.dev_use_low_latency_parser_when_possible = checked
                //     }
                // }
                // Rectangle {
                //     width: parent.width
                //     height: rowHeight
                //     color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                //     visible:false


                //     Text {
                //         text: qsTr("dev_feed_incomplete_frames_to_decoder")
                //         font.weight: Font.Bold
                //         font.pixelSize: 13
                //         anchors.leftMargin: 8
                //         verticalAlignment: Text.AlignVCenter
                //         anchors.verticalCenter: parent.verticalCenter
                //         width: 224
                //         height: elementHeight
                //         anchors.left: parent.left
                //     }
                //     Switch {
                //         width: 32
                //         height: elementHeight
                //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                //         anchors.right: parent.right
                //         anchors.verticalCenter: parent.verticalCenter
                //         checked: settings.dev_feed_incomplete_frames_to_decoder
                //         onCheckedChanged: settings.dev_feed_incomplete_frames_to_decoder = checked
                //     }
                // }

                // dirty
                SettingBaseElement{
                    m_short_description: "Use RPI decoding"
                    //m_long_description: "On by default, RPI specific."
                    Switch {
                        width: 32
                        height: elementHeight
                        visible: true
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_rpi_use_external_omx_decode_service
                        onCheckedChanged: settings.dev_rpi_use_external_omx_decode_service = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: "Use external decoding service"
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
}
