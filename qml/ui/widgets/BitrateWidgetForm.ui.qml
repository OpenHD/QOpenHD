import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: bitrateWidget
    width: 112
    height: 48

    visible: settings.show_bitrate

    widgetIdentifier: "bitrate_widget"

    defaultAlignment: 1
    defaultXOffset: 224
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true


    //----------------------------- DETAIL BELOW ----------------------------------


    widgetDetailComponent: ScrollView{

        contentHeight: bitrateSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: bitrateSettingsColumn

            /*            Shape {
                id: line
                height: 32
                width: parent.width

                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: line.height / 2
                    PathLine { x: 0;          y: line.height / 2 }
                    PathLine { x: line.width; y: line.height / 2 }
                }
            }
*/
            Item {
                width: parent.width
                height: 42
                Text {
                    id: bitrateSettingsTitle
                    text: qsTr("BITRATE")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: bitrateSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    id: opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: bitrate_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.bitrate_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.bitrate_opacity = bitrate_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: bitrate_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.bitrate_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.bitrate_size = bitrate_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Horizontal Center")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: {
                        // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Vertical Center")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: {
                        // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
            }


            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show skip / fail count")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.bitrate_show_skip_fail_count
                    onCheckedChanged: settings.bitrate_show_skip_fail_count = checked
                }
            }
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------

    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200
            //----------------------------live setting------------------------------------------

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Cam Brightness")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: cam_brightness_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.cam_brightness
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (cam_brightness_Slider.pressed==false){
                            settings.cam_brightness = cam_brightness_Slider.value
                            console.log("Cam brightness slider changed");
                            //TODO only setup to test mavlink command
                            MavlinkTelemetry.requested_Cam_Brightness_Changed(settings.cam_brightness);
                        }
                    }
                }
                Text {
                    text: Number(cam_brightness_Slider.value).toLocaleString(Qt.locale(), 'f', 0) + "%";
                    anchors.left: cam_brightness_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Cam Contrast")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: cam_contrast_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.cam_contrast
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (cam_contrast_Slider.pressed==false){
                            settings.cam_contrast = cam_contrast_Slider.value
                            console.log("Cam contrast slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.cam_contrast);
                        }
                    }
                }
                Text {
                    text: Number(cam_contrast_Slider.value).toLocaleString(Qt.locale(), 'f', 0) + "%";
                    anchors.left: cam_contrast_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Cam Saturation")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: cam_saturation_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.cam_saturation
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (cam_saturation_Slider.pressed==false){
                            settings.cam_saturation = cam_saturation_Slider.value
                            console.log("Cam saturation slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.cam_saturation);
                        }
                    }
                }
                Text {
                    text: Number(cam_saturation_Slider.value).toLocaleString(Qt.locale(), 'f', 0) + "%";
                    anchors.left: cam_saturation_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Cam Sharpness")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: cam_sharpness_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.cam_sharpness
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (cam_sharpness_Slider.pressed==false){
                            settings.cam_sharpness = cam_sharpness_Slider.value
                            console.log("Cam sharpness slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.cam_sharpness);
                        }
                    }
                }
                Text {
                    text: Number(cam_sharpness_Slider.value).toLocaleString(Qt.locale(), 'f', 0) + "%";
                    anchors.left: cam_sharpness_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Video Blocks")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vid_blocks_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.vid_blocks
                    to: 10
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (vid_blocks_Slider.pressed==false){
                            settings.vid_blocks = vid_blocks_Slider.value
                            console.log("Vid Blocks slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.cam_sharpness);
                        }
                    }
                }
                Text {
                    text: Number(vid_blocks_Slider.value).toLocaleString(Qt.locale(), 'f', 0);
                    anchors.left: vid_blocks_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Block Length")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vid_block_length_Slider
                    orientation: Qt.Horizontal
                    from: 600
                    value: settings.vid_block_length
                    to: 2100
                    stepSize: 12
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (vid_block_length_Slider.pressed==false){
                            settings.vid_block_length = vid_block_length_Slider.value
                            console.log("Vid block_length slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.vid_block_length);
                        }
                    }
                }
                Text {
                    text: Number(vid_block_length_Slider.value).toLocaleString(Qt.locale(), 'f', 0);
                    anchors.left: vid_block_length_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("KeyFrame Rate")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vid_keyframerate_Slider
                    orientation: Qt.Horizontal
                    from: 2
                    value: settings.vid_keyframerate
                    to: 24
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (vid_keyframerate_Slider.pressed==false){
                            settings.vid_keyframerate = vid_keyframerate_Slider.value
                            console.log("Vid keyframerate slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.vid_keyframerate);
                        }
                    }
                }
                Text {
                    text: Number(vid_keyframerate_Slider.value).toLocaleString(Qt.locale(), 'f', 0);
                    anchors.left: vid_keyframerate_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("FEC Blocks")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vid_fec_blocks_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.vid_fec_blocks
                    to: 12
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onPressedChanged: {
                        if (vid_fec_blocks_Slider.pressed==false){
                            settings.vid_fec_blocks = vid_fec_blocks_Slider.value
                            console.log("Vid fec_bocks slider changed");
                            //TODO   Not wired to anything
                            //   MavlinkTelemetry.requested_Cam_XXX_Changed(settings.vid_fec_blocks);
                        }
                    }
                }
                Text {
                    text: Number(vid_fec_blocks_Slider.value).toLocaleString(Qt.locale(), 'f', 0);
                    anchors.left: vid_fec_blocks_Slider.right
                    font.pixelSize: detailPanelFontPixels;
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }
            }

            //----------------------------end live settings----------------------------------
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Measured:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.kbitrate_measured/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Set:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.kbitrate_set/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Skipped packets:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.skipped_packet_cnt).toLocaleString(Qt.locale(), 'f', 0);
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Injection failed:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(OpenHD.injection_fail_cnt).toLocaleString(Qt.locale(), 'f', 0);
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: settings.bitrate_opacity
        scale: settings.bitrate_size

        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 48
            color: settings.color_text
            text: Number(OpenHD.kbitrate/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 18
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 48
            color: {
                if (OpenHD.kbitrate_measured <= 0.1) {
                    return settings.color_shape;
                }

                return (OpenHD.kbitrate / OpenHD.kbitrate_measured) >= 0.70 ? ((OpenHD.kbitrate / OpenHD.kbitrate_measured) >= 0.80 ? "#ff0000" : "#fbfd15") : settings.color_shape
            }
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: -2
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: allDataText
            visible: settings.bitrate_show_skip_fail_count
            text: Number(OpenHD.injection_fail_cnt).toLocaleString(Qt.locale(), 'f', 0) + "/" + Number(OpenHD.skipped_packet_cnt).toLocaleString(Qt.locale(), 'f', 0)
            color: settings.color_text
            anchors.top: kbitrate.bottom
            anchors.topMargin: -16
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
