import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_horizon

    widgetIdentifier: "horizon_widget"
    bw_verbose_name: "ARTIFICIAL HORIZON"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailHeight: 250+250

    m_show_grid_when_dragging : true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_vertical_lock: true
            show_horizontal_lock: true
            show_quickpainteditem_font_scale: true

            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Clip area")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSlider {
                    orientation: Qt.Horizontal
                    from: .3
                    value: settings.horizon_clip_area_scale
                    to: 2.0
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_clip_area_scale = value
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
                NewSlider {
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
                NewSlider {
                    id: horizon_spacing_Slider
                    orientation: Qt.Horizontal
                    from: 10
                    value: settings.horizon_ladder_spacing
                    to: 500
                    stepSize: 1
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
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSlider {
                    id: horizon_range_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_range
                    to: 180
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_range = horizon_range_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Step")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSlider {
                    id: horizon_step_Slider
                    orientation: Qt.Horizontal
                    from: 5
                    value: settings.horizon_step
                    to: 90
                    stepSize: 5
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_step = horizon_step_Slider.value
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
                NewSwitch {
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
                NewSwitch {
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
                NewSwitch {
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
                NewSwitch {
                    x: 190
                    y: 0
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 8
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
                NewSwitch {
                    x: 190
                    y: 0
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 8
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
                NewSwitch {
                    x: 190
                    y: 0
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 8
                    anchors.right: parent.right
                    checked: settings.heading_ladder_text
                    onCheckedChanged: settings.heading_ladder_text = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show center indicator")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    x: 190
                    y: 0
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 8
                    anchors.right: parent.right
                    checked: settings.horizon_show_center_indicator
                    onCheckedChanged: settings.horizon_show_center_indicator = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        Item {
            id: horizonLadder
            visible: true

            anchors.centerIn: parent
            //width: parent.width * 0.3 * bw_current_scale
            //height: parent.height * 0.5 * bw_current_scale
            //width: 1200
            //height: 800

            transform: Scale {
                origin.x: 0
                origin.y: 0
                xScale: bw_current_scale
                yScale: bw_current_scale
            }

            HorizonLadder {
                id: horizonLadderC
                anchors.centerIn: parent
                //anchors.fill: parent

                // Note: By the width / height we also controll the clipping area (since the horizon is double drawn, into a texture, then onto the screen).
                // Ideally, we want to reduce the "overdraw" to save GPU resources, e.g. make this area as small as possible / as less pixels as possible.
                width: 400 * settings.horizon_clip_area_scale
                height: 400 * settings.horizon_clip_area_scale
                //width: applicationWindow.width *0.8 * settings.horizon_clip_area_scale
                //height: applicationWindow.height *0.8 * settings.horizon_clip_area_scale
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                horizonInvertPitch: settings.horizon_invert_pitch
                horizonInvertRoll: settings.horizon_invert_roll
                horizonWidth: settings.horizon_width
                horizonSpacing: settings.horizon_ladder_spacing
                horizonShowLadder: settings.show_horizon_ladder
                horizonRange: settings.horizon_range
                horizonStep: settings.horizon_step
                show_center_indicator: settings.horizon_show_center_indicator
                //line_stroke_strength_perc: settings.horizon_line_stroke_strength_perc

                Behavior on pitch {NumberAnimation { duration: settings.smoothing }}
                pitch: _fcMavlinkSystem.pitch
                Behavior on roll {NumberAnimation { duration: settings.smoothing }}
                roll: _fcMavlinkSystem.roll
                //turned off data smoothing because of compass wrapping issue
                //Behavior on heading {NumberAnimation { duration: settings.smoothing }}
                heading: _fcMavlinkSystem.hdg
                //Behavior on homeHeading {NumberAnimation { duration: settings.smoothing }}
                homeHeading: _fcMavlinkSystem.home_heading

                showHeadingLadderText: settings.heading_ladder_text
                showHorizonHeadingLadder: settings.show_horizon_heading_ladder
                showHorizonHome: settings.show_horizon_home //you dont want a floating home icon
                fontFamily: settings.font_text
                custom_font_scale: bw_qquickpainteditem_font_scale
            }
            Rectangle{ // For debugging the area where the horizon clips
                // debug
                color: "transparent"
                border.width: 4
                border.color: "green"
                width: horizonLadderC.width
                height: horizonLadderC.height
                anchors.centerIn: parent
                visible: dragging
            }
        }
    }
}
