import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../../ui/elements"
import "../elements"

BaseWidget {
    id: gndTempTxc
    width: 50
    height: 50

    visible: _ohdSystemGround.curr_txc_temp_degree_1 > 5 && settings.show_widgets && settings.show_txc_temp_gnd

    widgetIdentifier: "Ground Transceiver Temperature"
    bw_verbose_name: qsTr("GND_RCX_TEMP")
    property real gndTemp1: _ohdSystemGround.curr_txc_temp_degree_1 
    property real gndTemp2: _ohdSystemGround.curr_txc_temp_degree_2

    defaultAlignment: 0
    defaultXOffset: 175
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: false
    hasWidgetAction: true

    widgetActionHeight: 164+50+30

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
        opacity: bw_current_opacity
        scale: bw_current_scale

        ColumnLayout{
            spacing:0
            Item {
                id: tempGauge
                width: 50
                height: 50

                property real normalizedSize: Math.min(width, height)

                Shape {
                    id: gaugeCanvas
                    anchors.centerIn: parent
                    width: tempGauge.normalizedSize
                    height: tempGauge.normalizedSize
                    layer.enabled: true
                    layer.samples: 4

                    property real cx: width / 2
                    property real cy: height / 2
                    property real r: width * 0.45
                    property real strokeW: width * 0.08

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: "#333"
                        strokeWidth: gaugeCanvas.strokeW
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: gaugeCanvas.cx
                            centerY: gaugeCanvas.cy
                            radiusX: gaugeCanvas.r
                            radiusY: gaugeCanvas.r
                            startAngle: 135
                            sweepAngle: 270
                        }
                    }
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: settings.color_text
                        strokeWidth: gaugeCanvas.strokeW
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: gaugeCanvas.cx
                            centerY: gaugeCanvas.cy
                            radiusX: gaugeCanvas.r
                            radiusY: gaugeCanvas.r
                            startAngle: 135
                            sweepAngle: 180
                        }
                    }
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: "red"
                        strokeWidth: gaugeCanvas.strokeW
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: gaugeCanvas.cx
                            centerY: gaugeCanvas.cy
                            radiusX: gaugeCanvas.r
                            radiusY: gaugeCanvas.r
                            startAngle: 315
                            sweepAngle: 90
                        }
                    }
                }

                // Needle group (for centered rotation)
                Item {
                    id: needleGroup
                    width: 1
                    height: 1
                    anchors.centerIn: gaugeCanvas

                    // Apply rotation to this whole group
                    rotation: (gndTemp1 / 100.0) * 270 + 20

                    Rectangle {
                        width: tempGauge.normalizedSize * 0.08
                        height: tempGauge.normalizedSize * 0.45
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        radius: width / 2
                        color: settings.color_text
                    }
                }
                Item {
                    id: needleGroup2
                    width: 1
                    height: 1
                    anchors.centerIn: gaugeCanvas

                    // Apply rotation to this whole group
                    rotation: (gndTemp2 / 100.0) * 270 + 20

                    Rectangle {
                        width: tempGauge.normalizedSize * 0.08
                        height: tempGauge.normalizedSize * 0.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        radius: width / 2
                        color: "green"
                    }
                }



                Rectangle {
                    width: tempGauge.normalizedSize * 0.06
                    height: tempGauge.normalizedSize * 0.06
                    radius: width / 2
                    color: settings.color_text
                    anchors.centerIn: needleGroup
                }

                Text {
                    text: "\uf1eb"
                    font.pixelSize: tempGauge.normalizedSize * 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: gaugeCanvas.bottom
                    anchors.topMargin: -80 * 0.3
                    color: settings.color_text
                }

                Text {
                    id: gndTemp1_text
                    text: qsTr("%1\u00B0C").arg(gndTemp1.toFixed(1))
                    font.pixelSize: tempGauge.normalizedSize * 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: gaugeCanvas.bottom
                    anchors.topMargin: 4
                    color: settings.color_text
                }
                Text {
                    id: gndTemp2_text
                    text: qsTr("[%1] %2\u00B0C").arg(2).arg(gndTemp2.toFixed(1))
                    visible: gndTemp2!=0
                    font.pixelSize: tempGauge.normalizedSize * 0.2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: gndTemp1_text.bottom
                    anchors.topMargin: 4
                    color: settings.color_text
                }

            }

        }
    }
}
