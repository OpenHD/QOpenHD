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
    bw_verbose_name: "VIBRATION"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
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
                xScale: bw_current_scale
                yScale: bw_current_scale
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
                    opacity: bw_current_opacity

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
                    opacity: bw_current_opacity
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
                    opacity: bw_current_opacity

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
                    opacity: bw_current_opacity
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
                    opacity: bw_current_opacity

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
                    opacity: bw_current_opacity
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
                    opacity: bw_current_opacity
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
                    opacity: bw_current_opacity
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
