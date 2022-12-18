import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    property alias gaugeAngle: throttleArc.sweepAngle

    property alias gaugeAngleGlow: throttleArcGlow.sweepAngle

    id: throttleWidget
    width: 96
    height: 68

    visible: settings.show_throttle

    widgetIdentifier: "throttle_widget"

    defaultAlignment: 2
    defaultXOffset: 96
    defaultYOffset: 72
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    widgetDetailComponent: ScrollView {

        contentHeight: throttleSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: throttleSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: throttleSettingsTitle
                    text: qsTr("THROTTLE")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: throttleSettingsTitleUL
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
                    id: throttle_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.throttle_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.throttle_opacity = throttle_opacity_Slider.value
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
                    id: throttle_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.throttle_scale
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.throttle_scale = throttle_size_Slider.value
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
                text_off: _fcMavlinkSystem.armed ? qsTr("DISARM") : qsTr("ARM")

                onCheckedChanged: {
                    if (checked == true){ //must be true since switch reverts to false
                        if (_fcMavlinkSystem.armed == true) {
                            _fcMavlinkSystem.arm_fc_async(false)
                        }
                        else {
                            _fcMavlinkSystem.arm_fc_async(true)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.throttle_opacity

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale {
                origin.x: 48
                origin.y: 34
                xScale: settings.throttle_scale
                yScale: settings.throttle_scale
            }

            Text {
                id: throttle_percent
                y: 0
                width: 24
                height: 18
                color: settings.color_text
                text: _fcMavlinkSystem.throttle
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Shape {
                id: throttleGauge
                anchors.fill: parent
                scale: 1.0

                ShapePath {
                    id: throttleShapeGlow

                    fillColor: "transparent"
                    strokeColor: settings.color_glow
                    strokeWidth: 11
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        id: throttleArcGlow
                        centerX: 48
                        centerY: 48
                        radiusX: 32
                        radiusY: 32
                        startAngle: -180
                    }
                }

                ShapePath {
                    id: throttleShape

                    fillColor: "transparent"
                    strokeColor: settings.color_shape
                    strokeWidth: 9
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        id: throttleArc
                        centerX: 48
                        centerY: 48
                        radiusX: 32
                        radiusY: 32
                        startAngle: -180
                    }
                }
            }

            Text {
                id: throttle_description
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: qsTr("throttle")
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
