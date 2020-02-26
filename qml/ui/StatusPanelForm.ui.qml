import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.3

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"

Rectangle {
    id: element2
    width: 504
    height: 300

    Label {
        id: ohdLabel
        color: "black"
        text: "Last openhd heartbeat: " + (OpenHD.last_openhd_heartbeat >= 0 && OpenHD.last_openhd_heartbeat <= 300000 ? OpenHD.last_openhd_heartbeat + "ms" : "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 12
        anchors.leftMargin: 24

        z: 1.1
    }

    Label {
        id: mavLabel
        color: "black"
        text: "Last telemetry heartbeat: " + (OpenHD.last_telemetry_heartbeat >= 0 && OpenHD.last_telemetry_heartbeat <= 300000 ? OpenHD.last_telemetry_heartbeat  + "ms": "N/A")
        font.pixelSize: 12
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 12
        anchors.rightMargin: 142

        z: 1.1
    }

    ScrollView {
        id: legend
        width: 118
        contentHeight: legendColumn.height
        leftPadding: 0
        rightPadding: 0
        topPadding: 12
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        property int fontSize: 14

        anchors {
            top: parent.top
            topMargin: 0
            right: parent.right
            rightMargin: 0
            bottom: parent.bottom
            bottomMargin: 0
        }

        Column {
            id: legendColumn
            width: legend.width
            spacing: 12

            ColoredCheckbox {
                padding: 0
                Layout.row: 0
                Layout.column: 0
                text: "Air CPU"
                font.pixelSize: legend.fontSize
                boxColor: airCPUAxis.color
                checked: airCPUAxis.visible
                onCheckedChanged: airCPUAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 0
                Layout.column: 1
                text: "Air Temp"
                font.pixelSize: legend.fontSize
                boxColor: airTempAxis.color
                checked: airTempAxis.visible
                onCheckedChanged: airTempAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 0
                Layout.column: 2
                text: "Gnd CPU"
                font.pixelSize: legend.fontSize
                boxColor: gndCPUAxis.color
                checked: gndCPUAxis.visible
                onCheckedChanged: gndCPUAxis.visible = checked
            }
            ColoredCheckbox {
                padding: 0
                Layout.row: 1
                Layout.column: 0
                text: "Gnd Temp"
                font.pixelSize: legend.fontSize
                boxColor: gndTempAxis.color
                checked: gndTempAxis.visible
                onCheckedChanged: gndTempAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 1
                Layout.column: 1
                text: "Lost Pkt"
                font.pixelSize: legend.fontSize
                boxColor: lostPacketAxis.color
                checked: lostPacketAxis.visible
                onCheckedChanged: lostPacketAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 1
                Layout.column: 2
                text: "Damage Blk"
                font.pixelSize: legend.fontSize
                boxColor: damagedBlockAxis.color
                checked: damagedBlockAxis.visible
                onCheckedChanged: damagedBlockAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 1
                Layout.column: 3
                text: "Down RSSI"
                font.pixelSize: legend.fontSize
                boxColor: downlinkRSSIAxis.color
                checked: downlinkRSSIAxis.visible
                onCheckedChanged: downlinkRSSIAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 0
                Layout.column: 3
                text: "Up RSSI"
                font.pixelSize: legend.fontSize
                boxColor: uplinkRSSIAxis.color
                checked: uplinkRSSIAxis.visible
                onCheckedChanged: uplinkRSSIAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 0
                Layout.column: 4
                text: "Inj. Fail"
                font.pixelSize: legend.fontSize
                boxColor: injectionFailAxis.color
                checked: injectionFailAxis.visible
                onCheckedChanged: injectionFailAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 1
                Layout.column: 4
                text: "Skip Pkt"
                font.pixelSize: legend.fontSize
                boxColor: skippedPacketAxis.color
                checked: skippedPacketAxis.visible
                onCheckedChanged: skippedPacketAxis.visible = checked
            }

            ColoredCheckbox {
                padding: 0
                Layout.row: 2
                Layout.column: 0
                text: "Bitrate"
                font.pixelSize: legend.fontSize
                boxColor: bitrateAxis.color
                checked: bitrateAxis.visible
                onCheckedChanged: bitrateAxis.visible = checked
            }

        }
    }

    ChartView {
        id: chart
        legend.visible: false

        backgroundColor: "#00000000"

        anchors {
            top: parent.top
            topMargin: -12
            left: parent.left
            leftMargin: -18
            right: legend.left
            rightMargin: -18
            bottom: parent.bottom
            bottomMargin: -12
        }

        antialiasing: true


        property int chartData: 0


        property int lostPacketsLast: 0
        property int lostPacketsMax: 0

        property int damagedBlocksLast: 0
        property int damagedBlocksMax: 0

        property int injectionFailLast: 0
        property int injectionFailMax: 0

        property int skippedPacketsLast: 0
        property int skippedPacketsMax: 0

        ValueAxis {
            id: valueAxis
            min: 0
            max: 300
            labelsVisible: false
            color: "black"
        }

        ValueAxis {
            id: dbYAxis
            min: -90
            max: 0
            labelFormat: "%d dB"
            tickCount: 11
            color: "black"
        }

        ValueAxis {
            id: countYAxis
            min: 0
            max: 100
            tickCount: 11
            labelFormat: "%d"
            color: "black"
        }

        LineSeries {
            id: airCPUAxis
            name: "Air CPU"
            axisX: valueAxis
            axisY: countYAxis
            color: "green"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: gndCPUAxis
            name: "Ground CPU"
            axisX: valueAxis
            axisY: countYAxis
            color: "blue"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: gndTempAxis
            name: "Ground Temp"
            axisX: valueAxis
            axisY: countYAxis
            color: "red"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: airTempAxis
            name: "Air Temp"
            axisX: valueAxis
            axisYRight: countYAxis
            color: "orange"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: lostPacketAxis
            name: "Lost Packets"
            axisX: valueAxis
            axisY: countYAxis
            color: "purple"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: damagedBlockAxis
            name: "Damaged Blocks"
            axisX: valueAxis
            axisY: countYAxis
            color: "brown"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: downlinkRSSIAxis
            name: "Downlink RSSI"
            axisX: valueAxis
            axisYRight: dbYAxis
            color: "lime"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: uplinkRSSIAxis
            name: "Uplink RSSI"
            axisX: valueAxis
            axisYRight: dbYAxis
            color: "tan"
            width: 2
            useOpenGL: true
        }


        LineSeries {
            id: injectionFailAxis
            name: "Injection Fail"
            axisX: valueAxis
            axisY: countYAxis
            color: "teal"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: skippedPacketAxis
            name: "Skipped packets"
            axisX: valueAxis
            axisY: countYAxis
            color: "violet"
            width: 2
            useOpenGL: true
        }

        LineSeries {
            id: bitrateAxis
            name: "Bitrate"

            axisX: valueAxis
            axisY: countYAxis
            color: "blue"
            width: 2
            useOpenGL: true
        }

        Timer {
            id: chartTimer
            running: true
            interval: 1000
            repeat: true
            onTriggered: {
                if (chart.lostPacketsLast != 0) {
                    var lostPacketsDifference = OpenHD.lost_packet_cnt - chart.lostPacketsLast;
                    lostPacketAxis.append(chart.chartData, lostPacketsDifference);
                }
                chart.lostPacketsLast = OpenHD.lost_packet_cnt;

                if (chart.damagedBlocksLast != 0) {
                    var damagedBlocksDifference = OpenHD.damaged_block_cnt - chart.damagedBlocksLast;
                    damagedBlockAxis.append(chart.chartData, damagedBlocksDifference);
                }
                chart.damagedBlocksLast = OpenHD.damaged_block_cnt;

                if (chart.injectionFailLast != 0) {
                    var injectionFailDifference = OpenHD.injection_fail_cnt - chart.injectionFailLast;
                    injectionFailAxis.append(chart.chartData, injectionFailDifference);
                }
                chart.injectionFailLast = OpenHD.injection_fail_cnt;

                if (chart.skippedPacketsLast != 0) {
                    var skippedPacketDifference = OpenHD.skipped_packet_cnt - chart.skippedPacketsLast;
                    skippedPacketAxis.append(chart.chartData, skippedPacketDifference);
                }
                chart.skippedPacketsLast = OpenHD.skipped_packet_cnt;

                airCPUAxis.append(chart.chartData, OpenHD.cpuload_air);
                gndCPUAxis.append(chart.chartData, OpenHD.cpuload_gnd);
                airTempAxis.append(chart.chartData, OpenHD.temp_air);
                gndTempAxis.append(chart.chartData, OpenHD.temp_gnd);
                downlinkRSSIAxis.append(chart.chartData, OpenHD.downlink_rssi);
                uplinkRSSIAxis.append(chart.chartData, OpenHD.current_signal_joystick_uplink);

                bitrateAxis.append(chart.chartData, OpenHD.kbitrate / 1024);

                chart.chartData++;

                if (chart.chartData > 300) {
                    valueAxis.min++;
                    valueAxis.max++;

                    lostPacketAxis.remove(1);
                    damagedBlockAxis.remove(1);

                    airCPUAxis.remove(1);
                    gndCPUAxis.remove(1);
                    airTempAxis.remove(1);
                    gndTempAxis.remove(1);

                    downlinkRSSIAxis.remove(1);
                    uplinkRSSIAxis.remove(1);

                    injectionFailAxis.remove(1);
                    skippedPacketAxis.remove(1);

                    bitrateAxis.remove(1);
                }
            }
        }
    }
}
