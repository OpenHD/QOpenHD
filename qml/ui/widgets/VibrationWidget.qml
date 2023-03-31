import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: vibrationWidget
    width: 60
    height: 60
    defaultAlignment: 2
    defaultXOffset: 6
    defaultYOffset: 98
    defaultHCenter: false
    defaultVCenter: false

    visible: settings.show_vibration

    widgetIdentifier: "vibration_widget"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: vibrationSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: vibrationSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: vibrationSettingsTitle
                    text: qsTr("VIBRATION")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: vibrationSettingsTitleUL
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
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vibration_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.vibration_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.vibration_opacity = vibration_opacity_Slider.value
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
                    id: vibration_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.vibration_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.vibration_size = vibration_size_Slider.value
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

    Item {
        id: widgetInner
        anchors.fill: parent

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale {
                origin.x: 30
                origin.y: 30
                xScale: settings.vibration_size
                yScale: settings.vibration_size
            }

            Item {
                id: xAxis
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60

                Shape {
                    id: x_outline
                    anchors.fill: parent
                    opacity: settings.vibration_opacity

                    ShapePath {
                        strokeColor: settings.color_glow
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: settings.color_shape
                        startX: 2
                        startY: (40 + (_fcMavlinkSystem.vibration_x
                                       > 0 ? _fcMavlinkSystem.vibration_x * -1 : _fcMavlinkSystem.vibration_x) * .4)
                        PathLine {
                            x: 10
                            y: (40 + (_fcMavlinkSystem.vibration_x
                                      > 0 ? _fcMavlinkSystem.vibration_x * -1 : _fcMavlinkSystem.vibration_x) * .4)
                        }
                        PathLine {
                            x: 10
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: (40 + (_fcMavlinkSystem.vibration_x
                                      > 0 ? _fcMavlinkSystem.vibration_x * -1 : _fcMavlinkSystem.vibration_x) * .4)
                        }
                    }

                    ShapePath {
                        strokeColor: settings.color_shape
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: "transparent"
                        startX: 0
                        startY: 0
                        PathLine {
                            x: 12
                            y: 0
                        }
                        PathLine {
                            x: 12
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 0
                        }
                    }
                }
                Text {
                    id: x_text

                    color: settings.color_text
                    opacity: settings.vibration_opacity
                    font.pixelSize: 10
                    font.family: settings.font_text

                    text: qsTr("X")
                    leftPadding: 2
                    anchors.top: parent.top
                    anchors.topMargin: 0

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Item {
                id: yAxis
                anchors.left: xAxis.right
                anchors.leftMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60

                Shape {
                    id: y_outline
                    anchors.fill: parent
                    opacity: settings.vibration_opacity

                    ShapePath {
                        strokeColor: settings.color_glow
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: settings.color_shape
                        startX: 2
                        startY: (40 + (_fcMavlinkSystem.vibration_y
                                       > 0 ? _fcMavlinkSystem.vibration_y * -1 : _fcMavlinkSystem.vibration_y) * .4)
                        PathLine {
                            x: 10
                            y: (40 + (_fcMavlinkSystem.vibration_y
                                      > 0 ? _fcMavlinkSystem.vibration_y * -1 : _fcMavlinkSystem.vibration_y) * .4)
                        }
                        PathLine {
                            x: 10
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: (40 + (_fcMavlinkSystem.vibration_y
                                      > 0 ? _fcMavlinkSystem.vibration_y * -1 : _fcMavlinkSystem.vibration_y) * .4)
                        }
                    }
                    ShapePath {
                        strokeColor: settings.color_shape
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: "transparent"
                        startX: 0
                        startY: 0
                        PathLine {
                            x: 12
                            y: 0
                        }
                        PathLine {
                            x: 12
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 0
                        }
                    }
                }
                Text {
                    id: y_text

                    color: settings.color_text
                    opacity: settings.vibration_opacity
                    font.pixelSize: 10
                    font.family: settings.font_text

                    text: qsTr("Y")
                    leftPadding: 2
                    anchors.topMargin: 0
                    anchors.top: parent.top

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Item {
                id: zAxis
                anchors.left: yAxis.right
                anchors.leftMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60

                Shape {
                    id: z_outline
                    anchors.fill: parent
                    opacity: settings.vibration_opacity

                    ShapePath {
                        strokeColor: settings.color_glow
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: settings.color_shape
                        startX: 2
                        startY: (40 + (_fcMavlinkSystem.vibration_z
                                       > 0 ? _fcMavlinkSystem.vibration_z * -1 : _fcMavlinkSystem.vibration_z) * .4)
                        PathLine {
                            x: 10
                            y: (40 + (_fcMavlinkSystem.vibration_z
                                      > 0 ? _fcMavlinkSystem.vibration_z * -1 : _fcMavlinkSystem.vibration_z) * .4)
                        }
                        PathLine {
                            x: 10
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: 40
                        }
                        PathLine {
                            x: 2
                            y: (40 + (_fcMavlinkSystem.vibration_z
                                      > 0 ? _fcMavlinkSystem.vibration_z * -1 : _fcMavlinkSystem.vibration_z) * .4)
                        }
                    }
                    ShapePath {
                        strokeColor: settings.color_shape
                        strokeWidth: 1
                        strokeStyle: ShapePath.SolidLine
                        fillColor: "transparent"
                        startX: 0
                        startY: 0
                        PathLine {
                            x: 12
                            y: 0
                        }
                        PathLine {
                            x: 12
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 40
                        }
                        PathLine {
                            x: 0
                            y: 0
                        }
                    }
                }
                Text {
                    id: z_text

                    color: settings.color_text
                    opacity: settings.vibration_opacity
                    font.pixelSize: 10
                    font.family: settings.font_text

                    text: qsTr("Z")
                    leftPadding: 2
                    anchors.topMargin: 0
                    anchors.top: parent.top

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
            Item {
                id: tick_text
                anchors.right: parent.right
                anchors.rightMargin: 0

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60

                Text {
                    id: sixty_text

                    color: settings.color_text
                    opacity: settings.vibration_opacity
                    font.pixelSize: 10
                    font.family: settings.font_text

                    text: "-60"
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: -2
                    leftPadding: 2

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
                Text {
                    id: thirty_text

                    color: settings.color_text
                    opacity: settings.vibration_opacity
                    font.pixelSize: 10
                    font.family: settings.font_text

                    text: "-30"
                    anchors.right: parent.right
                    anchors.rightMargin: -2
                    leftPadding: 2
                    anchors.topMargin: 21
                    anchors.top: parent.top

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
        }
    }
}
