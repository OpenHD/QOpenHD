import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

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
    bw_verbose_name: "HEADING"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true

    // Bound extra, a bit complicated
    property double m_extra_size: bw_current_scale

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
        //opacity: bw_current_opacity

        Item {
            id: headingLadder

            width: parent.width * m_extra_size
            anchors.horizontalCenter: parent.horizontalCenter
            y: 27
            x: width/2

            transform: Scale {
                origin.x: width/2*m_extra_size //24
                origin.y: 15
                xScale: m_extra_size
                yScale: m_extra_size
            }

            HeadingLadder {
                id: headingLadderC
                anchors.centerIn: parent
                width: 250
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
                custom_font_scale: bw_qquickpainteditem_font_scale
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
                xScale: m_extra_size
                yScale: m_extra_size
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
                origin.y: 40-20*m_extra_size
                xScale: m_extra_size
                yScale: m_extra_size
            }
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_glow
                strokeWidth: 3
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 4
                startY: 0-20*m_extra_size
                PathLine {
                    x: 4
                    y: 0-20*m_extra_size
                }
                PathLine {
                    x: 44
                    y: 0-20*m_extra_size
                }
                PathLine {
                    x: 44
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 32
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 24
                    y: 25-20*m_extra_size
                }
                PathLine {
                    x: 16
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 4
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 4
                    y: 0-20*m_extra_size
                }
            }
        }
        Shape {
            id: outline
            anchors.fill: parent

            transform: Scale {
                origin.x: width/2 //24
                origin.y: 40-20*m_extra_size
                xScale: m_extra_size
                yScale: m_extra_size
            }
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 4
                startY: 0-20*m_extra_size
                PathLine {
                    x: 4
                    y: 0-20*m_extra_size
                }
                PathLine {
                    x: 44
                    y: 0-20*m_extra_size
                }
                PathLine {
                    x: 44
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 32
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 24
                    y: 25-20*m_extra_size
                }
                PathLine {
                    x: 16
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 4
                    y: 20-20*m_extra_size
                }
                PathLine {
                    x: 4
                    y: 0-20*m_extra_size
                }
            }
        }
    }
}
