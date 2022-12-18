import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: homeDistanceWidget
    width: 96
    height: 24

    visible: settings.show_home_distance

    widgetIdentifier: "home_distance_widget"

    defaultAlignment: 2
    defaultXOffset: 0
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    //----------------------------- DETAIL BELOW ----------------------------------
    widgetDetailComponent: ScrollView {

        contentHeight: homedistanceSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: homedistanceSettingsColumn


            /*         Shape {
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
                    PathLine {
                        x: 0
                        y: line.height / 2
                    }
                    PathLine {
                        x: line.width
                        y: line.height / 2
                    }
                }
            }
*/
            Item {
                width: parent.width
                height: 42
                Text {
                    id: homedistanceSettingsTitle
                    text: qsTr("HOME DISTANCE")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: homedistanceSettingsTitleUL
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
                    id: home_distance_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.home_distance_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.home_distance_opacity = home_distance_opacity_Slider.value
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
                    id: home_distance_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.home_distance_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.home_distance_size = home_distance_size_Slider.value
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
                        var _hCenter = settings.value(hCenterIdentifier,
                                                      defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1
                                || _hCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier,
                                                        checked)
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
                        var _vCenter = settings.value(vCenterIdentifier,
                                                      defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1
                                || _vCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier,
                                                        checked)
                }
            }
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            width: 200
            spacing: 10

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Lat:")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(_fcMavlinkSystem.homelat).toLocaleString(Qt.locale(),
                                                                'f', 6)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Lon:")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(_fcMavlinkSystem.homelon).toLocaleString(Qt.locale(),
                                                                'f', 6)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                height: 32
                Text {
                    text: "Only For Ardupilot/PX4"
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                }
            }

            ConfirmSlider {

                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("RTL")
                msg_id: 11

                onCheckedChanged: {
                    if (checked == true) {

                        //double check.... not really needed
                        _fcMavlinkSystem.pass_cmd_long(msg_id);
                        //console.log("selected");
                    }
                }
            }

            //-----------------------Split from plane to copter
            ConfirmSlider {

                visible: _fcMavlinkSystem.mav_type == "ARDUCOPTER"

                text_off: qsTr("RTL")
                msg_id: 6

                onCheckedChanged: {
                    if (checked == true) {

                        //double check.... not really needed
                        _fcMavlinkSystem.pass_cmd_long(msg_id);
                        //console.log("selected");
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: settings.home_distance_size

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.home_distance_opacity
            text: "\uf015"
            anchors.right: home_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: home_distance_text
            width: 64
            height: 24
            color: settings.color_text
            opacity: settings.home_distance_opacity
            // @disable-check M222
            text: {
                var distance = _fcMavlinkSystem.home_distance
                var unit = "m"
                var use_imperial = settings.value("enable_imperial", false)
                // QML settings can return strings for booleans on some platforms so we check
                if (use_imperial === true || use_imperial === 1
                        || use_imperial === "true") {
                    unit = "ft"
                    distance = distance * 3.28084
                }

                return distance.toLocaleString(Qt.locale(), "f", 1) + unit
            }
            elide: Text.ElideNone
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
