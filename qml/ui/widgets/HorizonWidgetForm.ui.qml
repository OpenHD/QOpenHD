import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_horizon

    widgetIdentifier: "horizon_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView{

        contentHeight: horizonSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            id: horizonSettingsColumn
            spacing:0
            clip: true

            Item {
                width: 230
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
                    id: horizon_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.horizon_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_opacity = horizon_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
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
                    id: horizon_size_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_size
                    to: 6
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_size = horizon_size_Slider.value
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
                    id: horizon_width_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_width
                    to: 10
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_width = horizon_width_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.show_horizon_ladder
                Text {
                    text: qsTr("Spacing")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_spacing_Slider
                    orientation: Qt.Horizontal
                    from: 40
                    value: settings.horizon_ladder_spacing
                    to: 180
                    stepSize: 10
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_ladder_spacing = horizon_spacing_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Invert Pitch")
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
                    checked: settings.horizon_invert_pitch
                    onCheckedChanged: settings.horizon_invert_pitch = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: invertTitle
                    text: qsTr("Invert Roll")
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
                    checked: settings.horizon_invert_roll
                    onCheckedChanged: settings.horizon_invert_roll = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show Ladder")
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
                    checked: settings.show_horizon_ladder
                    onCheckedChanged: settings.show_horizon_ladder = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show Home")
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
                    checked: settings.show_horizon_home
                    onCheckedChanged: settings.show_horizon_home = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show heading")
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
                    checked: settings.show_horizon_heading_ladder
                    onCheckedChanged: settings.show_horizon_heading_ladder = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.show_horizon_heading_ladder
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
            Item {
                width: 230
                height: 32
                visible: settings.show_horizon_heading_ladder
                Text {
                    text: qsTr("UAV is iNav")
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
                    checked: settings.heading_inav
                    onCheckedChanged: settings.heading_inav = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.horizon_opacity

        Item {
            id: horizonLadder

            anchors.centerIn: parent

            visible: settings.show_horizon

            transform: Scale { origin.x: 0; origin.y: 0; xScale: settings.horizon_size ; yScale: settings.horizon_size}


            HorizonLadder {
                id: horizonLadderC
                anchors.centerIn: parent
                /* could turn the width and height into settings and thereby clip the horizon
                  *even theough clipping is false it still clips
                */
                width: 1200
                height: 800
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                horizonInvertPitch: settings.horizon_invert_pitch
                horizonInvertRoll: settings.horizon_invert_roll
                horizonWidth: settings.horizon_width
                horizonSpacing: settings.horizon_ladder_spacing
                horizonShowLadder: settings.show_horizon_ladder
                horizonRange: settings.horizon_ladder_spacing

                pitch: OpenHD.pitch
                roll: OpenHD.roll

                heading: OpenHD.hdg
                homeHeading: OpenHD.home_heading

                showHeadingLadderText: settings.heading_ladder_text
                showHorizonHeadingLadder: settings.show_horizon_heading_ladder
                showHorizonHome: settings.show_horizon_home //you dont want a floating home icon

            }
        }

    }
}
