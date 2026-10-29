import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"
import "../openhd_settings"

ScrollView {
    id: appVideoSettingsView
    width: parent.width
    height: parent.height
    contentHeight: videoColumn.height

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    Item {
        anchors.fill: parent

        Column {
            id: videoColumn
            spacing: 5
            anchors.left: parent.left
            anchors.right: parent.right

            ListModel {
                id: itemsVideoCodec
                ListElement { text: qsTr("H264"); }
                ListElement { text: qsTr("H265");  }
            }
            SettingBaseElement{
                m_short_description: qsTr("Scale primary video to fit screen")

                Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
                    m_short_description: qsTr("Switch primary / secondary video")
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
                m_description: qsTr("Advanced video settings")
                m_hide_elements: true

                SettingBaseElement{
                    m_short_description: qsTr("Primary video codec")
                    CompactLinkComboBox {
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
                    m_short_description: qsTr("Use low latency RTP parser")
                    visible: _qopenhd.debugMenuPreview || (_qopenhd.is_platform_nxp())
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_use_low_latency_parser_when_possible
                        onCheckedChanged: settings.dev_use_low_latency_parser_when_possible = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Enable audio playback (experimental)")
                    m_long_description: qsTr("Plays the incoming audio stream on the ground station. Requires audio streaming to be enabled on the air unit.")
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_enable_live_audio_playback
                        onCheckedChanged: settings.dev_enable_live_audio_playback = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Use Software Decode")
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
                    m_short_description: qsTr("Primary video udp port")
                    SpinBox {
                        height: elementHeight
                        width: 210
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                    m_short_description: qsTr("Secondary video codec")
                    // only show to dualcam users
                    visible: _qopenhd.debugMenuPreview || (settings.dev_qopenhd_n_cameras==2)
                    CompactLinkComboBox {
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
                    m_short_description: qsTr("Secondary video udp port")
                    visible: _qopenhd.debugMenuPreview || (settings.dev_qopenhd_n_cameras==2)
                    SpinBox {
                        height: elementHeight
                        width: 210
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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

                SettingBaseElement{
                    m_short_description: qsTr("Secondary video input (Android dev)")
                    visible: _qopenhd.debugMenuPreview || (_qopenhd.is_android())
                    CompactLinkComboBox {
                        width: 320
                        height: elementHeight
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.verticalCenter: parent.verticalCenter
                        model: ListModel {
                            ListElement { text: qsTr("UDP secondary port") }
                            ListElement { text: qsTr("UDP primary port") }
                            ListElement { text: qsTr("HTTP test clip") }
                        }
                        Component.onCompleted: {
                            if(settings.dev_secondary_video_input_mode < 0 || settings.dev_secondary_video_input_mode > 2){
                                settings.dev_secondary_video_input_mode = 0;
                            }
                            currentIndex = settings.dev_secondary_video_input_mode
                        }
                        onCurrentIndexChanged: settings.dev_secondary_video_input_mode = currentIndex
                    }
                }

                SettingBaseElement{
                    m_short_description: qsTr("Disable primary video (Android)")
                    m_long_description: qsTr("Stops rendering the primary stream on Android to debug the secondary feed. Requires restart.")
                    visible: _qopenhd.debugMenuPreview || (_qopenhd.is_android())
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_disable_primary_video
                        onCheckedChanged: {
                            const actually_changed = settings.dev_disable_primary_video !== checked
                            settings.dev_disable_primary_video = checked
                            if (actually_changed) {
                                _restartqopenhdmessagebox.show()
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: rowHeight
                    radius: 7
                    color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
                    border.color: settings_form.lineColor
                    border.width: Positioner.index % 2 === 0 ? 1 : 0
                    StyledText {
                        text: qsTr("Video test mode")
                        font.weight: Font.Bold
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: elementHeight
                        anchors.left: parent.left
                    }
                    CompactLinkComboBox {
                        width: 320
                        height: elementHeight
                        anchors.right: parent.right
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizonatalCenter
                        model: ListModel {
                            ListElement { text: qsTr("DISABLE"); }
                            ListElement { text: qsTr("RAW_VIDEO");  }
                            ListElement { text: qsTr("RAW_DECODE_ENCODE"); }
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
                    radius: 7
                    color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
                    border.color: settings_form.lineColor
                    border.width: Positioner.index % 2 === 0 ? 1 : 0
                    StyledText {
                        text: qsTr("Limit FPS in test file")
                        font.weight: Font.Bold
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                //     color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
                //     visible:false


                //     StyledText {
                //         text: qsTr("Draw RGB dummy frames")
                //         font.weight: Font.Bold
                //         font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                //     color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
                //     visible:false


                //     StyledText {
                //         text: qsTr("dev_use_low_latency_parser_when_possible")
                //         font.weight: Font.Bold
                //         font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                //     color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
                //     visible:false


                //     StyledText {
                //         text: qsTr("dev_feed_incomplete_frames_to_decoder")
                //         font.weight: Font.Bold
                //         font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
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
                    m_short_description: qsTr("Use RPI decoding")
                    //m_long_description: "On by default, RPI specific."
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
                    m_short_description: qsTr("Use external decoding service")
                    //m_long_description: "Video decode is not done via QOpenHD, but rather in an extra service (started and stopped by QOpenHD). For platforms other than rpi"
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.dev_always_use_generic_external_decode_service
                        onCheckedChanged: settings.dev_always_use_generic_external_decode_service = checked
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Use KMS DRM overlay renderer (experimental)")
                    m_long_description: qsTr("Linux only. Requires restart. Disable external decode service for this to take effect.")
                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.enable_kms_renderer
                        onCheckedChanged: settings.enable_kms_renderer = checked
                    }
                }
            }
            SettingsCategory {
                m_description: qsTr("Screen & display")
                m_hide_elements: false

                SettingBaseElement{
                    m_short_description: qsTr("Screen Scale")
                    StyledText {
                        text: Number(settings.global_scale).toLocaleString(Qt.locale(), 'f', 1) + "x";
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        anchors.right: screenScaleSpinBox.left
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: elementHeight

                    }

                    Slider {
                        id: screenScaleSpinBox
                        height: elementHeight
                        width: 210
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        from : 0.3
                        to : 2.5
                        // Important: Looks as without .1 steps, we can get rendering artfacts
                        stepSize: .1

                        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                        value: settings.global_scale

                        onValueChanged: {
                            if(settings.global_scale != value){
                                _restartqopenhdmessagebox.show();
                            }
                            settings.global_scale = value
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Auto hide cursor")

                    Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        width: 32
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: settings.enable_cursor_auto_hide
                        onCheckedChanged: {
                            if(settings.enable_cursor_auto_hide!=checked){
                                settings.enable_cursor_auto_hide=checked;
                                _mouseHelper.set_hide_cursor_inactive_enable(settings.enable_cursor_auto_hide);
                            }
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Set cursor Skin")
                    SpinBox {
                        width: 210
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        from: 0
                        to: 7
                        stepSize: 1
                        value: settings.custom_cursor_type
                        onValueChanged: {
                            settings.custom_cursor_type = value
                            _mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)
                        }
                    }
                }
                SettingBaseElement{
                    m_short_description: qsTr("Cursor Scale")

                    SpinBox {
                        width: 210
                        font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        height: elementHeight
                        anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        from: 0
                        to: 7
                        stepSize: 1
                        value: settings.custom_cursor_scale
                        onValueChanged: {
                            settings.custom_cursor_scale = value
                            _mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)
                        }
                    }
                }
                SettingsCategory{
                m_description: qsTr("Advanced screen settings")
                    m_hide_elements: true

                    SettingBaseElement{
                        m_short_description: qsTr("Screen rotation")
                        // anything other than 0 and 180 can breaks things
                        CompactLinkComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            width: 320
                            model: ListModel {
                                id: screen_rotations
                                ListElement { text: qsTr("0°") ; value: 0 }
                                ListElement { text: qsTr("90° (WARNING)") ; value: 90 }
                                ListElement { text: qsTr("180°") ; value: 180 }
                                ListElement { text: qsTr("270° (WARNING)") ; value: 270 }
                            }
                            textRole: "text"
                            Component.onCompleted: {
                                for (var i = 0; i < model.count; i++) {
                                    var choice = model.get(i);
                                    if (choice.value == settings.general_screen_rotation) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onCurrentIndexChanged: {
                                settings.general_screen_rotation = screen_rotations.get(currentIndex).value
                            }
                        }
                    }
                    SettingBaseElement{
                        m_short_description: qsTr("Transparent Background")

                        Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
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
                        m_short_description: qsTr("Full screen")

                        Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.dev_force_show_full_screen
                            onCheckedChanged: settings.dev_force_show_full_screen = checked
                        }
                    }
                    SettingBaseElement{
                        m_short_description: qsTr("Swap interval 0")
                        m_long_description: qsTr("Can decrease latency on x86 / laptop. Requires restart. Experimental.")

                        Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.dev_set_swap_interval_zero
                            onCheckedChanged: settings.dev_set_swap_interval_zero = checked
                        }
                    }

                    // SettingBaseElement{
                    //     m_short_description: "Settings window scale"

                    //     SpinBox {
                    //         width: 210
                    //         font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    //         height: elementHeight
                    //         anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    //         anchors.right: parent.right
                    //         anchors.verticalCenter: parent.verticalCenter

                    //         from: 50
                    //         to: 100
                    //         stepSize: 1
                    //         value: settings.screen_settings_overlay_size_percent
                    //         onValueChanged: {
                    //             settings.screen_settings_overlay_size_percent = value
                    //         }
                    //     }
                    // }
                    SettingBaseElement{
                        m_short_description: qsTr("Transparent settings")

                        Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            width: 32
                            height: elementHeight
                            anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: settings.screen_settings_openhd_parameters_transparent
                            onCheckedChanged: settings.screen_settings_openhd_parameters_transparent = checked
                        }
                    }
                    SettingBaseElement{
                        m_short_description: qsTr("Font DPI")
                        m_long_description: qsTr("Scale the text / line size of the artifical horizon / ladders, requires restart of QOpenHD.")
                        CompactLinkComboBox {
                            height: elementHeight
                            anchors.right: parent.right
                            anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizonatalCenter
                            width: 320
                            model: ListModel {
                                ListElement { text: qsTr("-1 Disable") ; value: -1 }
                                ListElement { text: qsTr("0 Auto (Recommended)") ; value: 0 }
                                ListElement { text: qsTr("50 (ultra small)") ; value: 50 }
                                ListElement { text: qsTr("72 (smaller)") ; value: 72 }
                                ListElement { text: qsTr("100") ; value: 100 }
                                ListElement { text: qsTr("120 (bigger)") ; value: 120 }
                                ListElement { text: qsTr("150 (ultra big)") ; value: 150 }
                            }
                            textRole: "text"
                            Component.onCompleted: {
                                for (var i = 0; i < model.count; i++) {
                                    var choice = model.get(i);
                                    if (choice.value == settings.screen_custom_font_dpi) {
                                        currentIndex = i;
                                    }
                                }
                            }
                            onActivated:{
                                const value_fdpi = model.get(currentIndex).value
                                if(settings.screen_custom_font_dpi != value_fdpi){
                                    console.log("font dpi changed from :"+settings.screen_custom_font_dpi+" to:"+value_fdpi);
                                    _restartqopenhdmessagebox.show();
                                    settings.screen_custom_font_dpi = value_fdpi
                                }

                            }
                        }
                    }
                }
            }
        }
    }
}
