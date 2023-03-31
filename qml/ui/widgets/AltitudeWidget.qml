import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudeWidget
    width: 64
    height: 24
    // resize with right side (technically top right, but it doesn't matter because VCenter is set)
    defaultAlignment: 1
    defaultXOffset: 40
    defaultVCenter: true

    visible: settings.show_altitude

    widgetIdentifier: "altitude_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: altSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Column {
            id: altSettingsColumn
            spacing: 0

            Item {
                width: parent.width
                height: 42
                Text {
                    id: altSettingsTitle
                    text: qsTr("ALTITUDE")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: altSettingsTitleUL
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
                    id: altitude_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.altitude_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.altitude_opacity = altitude_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    id: sizeTitle
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: altitude_size_Slider
                    orientation: Qt.Horizontal
                    from: .7
                    value: settings.altitude_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.altitude_size = altitude_size_Slider.value
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
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Relative / MSL")
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
                    checked: settings.altitude_rel_msl
                    onCheckedChanged: settings.altitude_rel_msl = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show ladder")
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
                    checked: settings.show_altitude_ladder
                    onCheckedChanged: settings.show_altitude_ladder = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: altitude_range_Slider
                    orientation: Qt.Horizontal
                    from: 40
                    value: settings.altitude_range
                    to: 150
                    stepSize: 10
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.altitude_range = altitude_range_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.altitude_opacity

        //-----------------------ladder start---------------
        Item {
            id: altLadder

            anchors.left: parent.left
            anchors.leftMargin: 20 //tweak ladder left or right

            visible: settings.show_altitude_ladder

            transform: Scale {
                origin.x: -5
                origin.y: 12
                xScale: settings.altitude_size
                yScale: settings.altitude_size
            }

            AltitudeLadder {
                id: altitudeLadderC
                anchors.centerIn: parent
                width: 50
                height: 300
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                altitudeRelMsl: settings.altitude_rel_msl
                altitudeRange: settings.altitude_range
                imperial: settings.enable_imperial
                Behavior on altMsl {NumberAnimation { duration: settings.smoothing }}
                altMsl: _fcMavlinkSystem.alt_msl
                Behavior on altRel {NumberAnimation { duration: settings.smoothing }}
                altRel: _fcMavlinkSystem.alt_rel
                fontFamily: settings.font_text
            }
        }
        //-----------------------ladder end---------------
        Item {
            id: altPointer
            anchors.fill: parent

            Text {
                id: alt_text
                color: settings.color_text

                font.pixelSize: 14
                font.family: settings.font_text
                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: settings.altitude_size
                    yScale: settings.altitude_size
                }
                text: Number(// @disable-check M222
                             settings.enable_imperial ? (settings.altitude_rel_msl ? (_fcMavlinkSystem.alt_msl * 3.28) : (_fcMavlinkSystem.alt_rel * 3.28)) : (settings.altitude_rel_msl ? _fcMavlinkSystem.alt_msl : _fcMavlinkSystem.alt_rel)).toLocaleString(
                          Qt.locale(), 'f', 0) // @disable-check M222
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Shape {
                id: outlineGlow
                anchors.fill: parent

                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: settings.altitude_size
                    yScale: settings.altitude_size
                }
                ShapePath {
                    strokeColor: settings.color_glow
                    strokeWidth: 3
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: 12
                    PathLine {
                        x: 0
                        y: 12
                    }
                    PathLine {
                        x: 12
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 24
                    }
                    PathLine {
                        x: 12
                        y: 24
                    }
                    PathLine {
                        x: 0
                        y: 12
                    }
                }
            }
            Shape {
                id: outline
                anchors.fill: parent

                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: settings.altitude_size
                    yScale: settings.altitude_size
                }
                ShapePath {
                    strokeColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: 12
                    PathLine {
                        x: 0
                        y: 12
                    }
                    PathLine {
                        x: 12
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 24
                    }
                    PathLine {
                        x: 12
                        y: 24
                    }
                    PathLine {
                        x: 0
                        y: 12
                    }
                }
            }
        }
    }
}
