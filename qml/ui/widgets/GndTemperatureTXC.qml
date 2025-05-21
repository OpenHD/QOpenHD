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
    bw_verbose_name: "GND_RCX_TEMP"
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

                Canvas {
                    id: gaugeCanvas
                    anchors.centerIn: parent
                    width: tempGauge.normalizedSize
                    height: tempGauge.normalizedSize

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width * 0.45;
                        var start = Math.PI * 0.75;
                        var end = Math.PI * 2.25;

                        ctx.lineWidth = width * 0.08;
                        ctx.strokeStyle = "#333";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.stroke();

                        var zones = [
                                    { color: settings.color_text, from: start, to: start + Math.PI * 1.0 },
                                    { color: "red", from: start + Math.PI * 1.0, to: end }
                                ];

                        for (var i = 0; i < zones.length; i++) {
                            var z = zones[i];
                            ctx.strokeStyle = z.color;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, z.from, z.to);
                            ctx.stroke();
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
                    text: gndTemp1.toFixed(1) + "°C"
                    font.pixelSize: tempGauge.normalizedSize * 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: gaugeCanvas.bottom
                    anchors.topMargin: 4
                    color: settings.color_text
                }
                Text {
                    id: gndTemp2_text
                    text: "[2]" + gndTemp2.toFixed(1) + "°C"
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

