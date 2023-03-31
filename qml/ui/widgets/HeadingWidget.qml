import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: headingWidget
    width: 48
    height: 48

    visible: settings.show_heading

    defaultYOffset: 50

    widgetIdentifier: "heading_widget"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: headingSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: headingSettingsColumn
            spacing: 0
            clip: true
            Item {
                width: 230
                height: 42
                Text {
                    id: headingSettingsTitle
                    text: qsTr("HEADING")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: headingSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: opacityText
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: heading_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.heading_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.heading_opacity = heading_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Width")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: heading_width_Slider
                    orientation: Qt.Horizontal
                    from: 100
                    value: settings.heading_width
                    to: 1000
                    stepSize: 50
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.heading_width = heading_width_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: sizeText
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: heading_size_Slider
                    orientation: Qt.Horizontal
                    from: .7
                    value: settings.heading_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.heading_size = heading_size_Slider.value
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
                width: 230
                height: 32
                Text {
                    text: qsTr("Show ticks")
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
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.show_heading_ladder
                    onCheckedChanged: settings.show_heading_ladder = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show N/S/E/W")
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
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.heading_ladder_text
                    onCheckedChanged: settings.heading_ladder_text = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.heading_opacity

        Item {
            id: headingLadder

            width: parent.width * settings.heading_size
            anchors.horizontalCenter: parent.horizontalCenter
            y: 27
            x: width/2

            transform: Scale {
                origin.x: width/2*settings.heading_size //24
                origin.y: 15
                xScale: settings.heading_size
                yScale: settings.heading_size
            }

            HeadingLadder {
                id: headingLadderC
                anchors.centerIn: parent
                width: settings.heading_width
                height: 50
                clip: false
                showHeadingLadderText: settings.heading_ladder_text
                showHorizonHeadingLadder: settings.show_heading_ladder
                showHorizonHome: settings.show_heading_ladder //you dont want a floating home icon
                //turned off data smoothing because of compass wrapping issue
                //Behavior on heading {NumberAnimation { duration: settings.smoothing }}
                heading: _fcMavlinkSystem.hdg
                //Behavior on homeHeading {NumberAnimation { duration: settings.smoothing }}
                homeHeading: _fcMavlinkSystem.home_heading
                color: settings.color_shape
                glow: settings.color_glow
                fontFamily: settings.font_text
            }
        }

        Text {
            id: hdg_text
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height +20 //-24
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: width/2 //24
                origin.y: 40 //34
                xScale: settings.heading_size
                yScale: settings.heading_size
            }
            text: Number(_fcMavlinkSystem.hdg).toLocaleString(Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Shape {
            id: outlineGlow
            anchors.fill: parent

            transform: Scale {
                origin.x: width/2 //24
                origin.y: 40-20*settings.heading_size
                xScale: settings.heading_size
                yScale: settings.heading_size
            }
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_glow
                strokeWidth: 3
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 4
                startY: 0-20*settings.heading_size
                PathLine {
                    x: 4
                    y: 0-20*settings.heading_size
                }
                PathLine {
                    x: 44
                    y: 0-20*settings.heading_size
                }
                PathLine {
                    x: 44
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 32
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 24
                    y: 25-20*settings.heading_size
                }
                PathLine {
                    x: 16
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 4
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 4
                    y: 0-20*settings.heading_size
                }
            }
        }
        Shape {
            id: outline
            anchors.fill: parent

            transform: Scale {
                origin.x: width/2 //24
                origin.y: 40-20*settings.heading_size
                xScale: settings.heading_size
                yScale: settings.heading_size
            }
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 4
                startY: 0-20*settings.heading_size
                PathLine {
                    x: 4
                    y: 0-20*settings.heading_size
                }
                PathLine {
                    x: 44
                    y: 0-20*settings.heading_size
                }
                PathLine {
                    x: 44
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 32
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 24
                    y: 25-20*settings.heading_size
                }
                PathLine {
                    x: 16
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 4
                    y: 20-20*settings.heading_size
                }
                PathLine {
                    x: 4
                    y: 0-20*settings.heading_size
                }
            }
        }
    }
}
