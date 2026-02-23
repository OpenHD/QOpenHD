import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

import OpenHD 1.0

BaseWidget {
    id: linkOverviewWidgetRight
    width: 320
    height: 60

    visible: settings.show_link_overview_widget && settings.show_widgets

    widgetIdentifier: "link_overview_widget_right"
    bw_verbose_name: qsTr("LINK OVERVIEW RIGHT")

    defaultAlignment: 1
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property string linkFont: "Quicksand"
    property string linkMonoFont: "ShareTechMono"

    property var m_camera_stream_model: _cameraStreamModelPrimary
    property bool m_camera_is_currently_recording: _cameraStreamModelPrimary.air_recording_active
    property int rc_rssi_percentage: _fcMavlinkSystem.rc_rssi_percentage

    property int rcBlockCount: 8
    property real rcBlockWidth: 12
    property real rcBlockHeight: 8
    property real rcBlockSkew: 4
    property var rcBlockThresholds: [10, 20, 30, 40, 50, 60, 70, 80]

    function bitrate_color(curr_set_and_measured_bitrate_mismatch) {
        if (curr_set_and_measured_bitrate_mismatch === 1) {
            return "yellow";
        } else if (curr_set_and_measured_bitrate_mismatch === 2) {
            return "red";
        }
        return settings.color_text;
    }

    function get_frequency_text() {
        var freq = _ohdSystemAir.is_alive ? _ohdSystemAir.curr_channel_mhz : _ohdSystemGround.curr_channel_mhz;
        if (freq <= 0) {
            return "N/A";
        }
        return freq + "Mhz";
    }

    function bitrate_to_mbit_text(text) {
        if (text === "" || text === "N/A") {
            return "N/A";
        }
        var parts = text.split(" ");
        if (parts.length < 2) {
            return text;
        }
        var value = parseFloat(parts[0]);
        if (isNaN(value)) {
            return text;
        }
        var unit = parts[1];
        if (unit.indexOf("MBit") !== -1) {
            return Number(value).toLocaleString(Qt.locale(), 'f', value < 10 ? 1 : 0) + "Mbit";
        }
        if (unit.indexOf("KBit") !== -1) {
            var mbits = value / 1000.0;
            return Number(mbits).toLocaleString(Qt.locale(), 'f', mbits < 10 ? 1 : 0) + "Mbit";
        }
        if (unit.indexOf("Bit") !== -1) {
            var mbits_from_bits = value / 1000.0 / 1000.0;
            return Number(mbits_from_bits).toLocaleString(Qt.locale(), 'f', 2) + "Mbit";
        }
        return text;
    }

    function get_bitrate_text() {
        return bitrate_to_mbit_text(m_camera_stream_model.curr_received_bitrate_with_fec);
    }

    function rc_rssi_is_valid() {
        return rc_rssi_percentage > -1;
    }

    function set_recording_mode(mode) {
        if (!_ohdSystemAir.is_alive) {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("Air unit not alive, cannot set recording for CAM1"));
            return;
        }
        var result = _airCameraSettingsModel.try_update_parameter_int("AIR_RECORDING_E", mode) === "";
        if (result) {
            _hudLogMessagesModel.signalAddLogMessage(6, mode === 1 ? qsTr("Recording CAM1 enabled") : qsTr("Recording CAM1 disabled"));
        } else {
            _hudLogMessagesModel.signalAddLogMessage(6, qsTr("Update CAM1 failed"));
        }
    }

    function toggle_recording() {
        set_recording_mode(m_camera_is_currently_recording ? 0 : 1);
    }

    function format_temp(value) {
        if (value <= -127) {
            return "N/A";
        }
        return Math.round(value) + "C";
    }

    function format_cpu(value, alive) {
        if (!alive || value < 0) {
            return "N/A";
        }
        return Math.round(value) + "%";
    }

    function format_space_mb(value, alive) {
        if (!alive || value < 0) {
            return "N/A";
        }
        return Math.round(value) + " MB";
    }

    function uplink_ok() {
        if (_ohdSystemGround.tx_operating_mode == 1) {
            return false;
        }
        if (_ohdSystemGround.tx_operating_mode == 2) {
            return false;
        }
        if (!_ohdSystemAir.is_alive) {
            return false;
        }
        return _ohdSystemAir.curr_rx_last_packet_status_good;
    }

    function uplink_color() {
        return uplink_ok() ? "white" : "grey";
    }

    widgetDetailComponent: ScrollView {
        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements {
            id: idBaseWidgetDefaultUiControlElements
            show_transparency: false
            show_background_color: true
            background_color_target: linkOverviewWidgetRight

            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("Air CPU temp: %1").arg(format_temp(_ohdSystemAir.curr_soc_temp_degree))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("GND CPU temp: %1").arg(format_temp(_ohdSystemGround.curr_soc_temp_degree))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("Air CPU: %1").arg(format_cpu(_ohdSystemAir.curr_cpuload_perc, _ohdSystemAir.is_alive))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("GND CPU: %1").arg(format_cpu(_ohdSystemGround.curr_cpuload_perc, _ohdSystemGround.is_alive))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 28
                Text {
                    text: qsTr("Rec space: %1").arg(format_space_mb(_ohdSystemAir.curr_space_left_mb, _ohdSystemAir.is_alive))
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.family: linkFont
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale
        clip: true

        Shape {
            id: cutRect
            anchors.fill: parent
            opacity: 0.5
            property real cutXRatio: 0.80
            property color fillColor: bw_current_background_color

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: cutRect.fillColor
                startX: 0
                startY: 0
                PathLine { x: width; y: 0 }
                PathLine { x: width; y: height }
                PathLine { x: width * (1 - cutRect.cutXRatio); y: height }
                PathLine { x: 0; y: 0 }
            }
        }

        Item {
            id: recordButton
            width: 36
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: recordDot
                width: 16
                height: 16
                radius: 8
                anchors.centerIn: parent
                color: m_camera_is_currently_recording ? "red" : "transparent"
                border.width: 2
                border.color: m_camera_is_currently_recording ? "red" : settings.color_text
            }

            MouseArea {
                anchors.fill: parent
                onClicked: toggle_recording()
                preventStealing: true
            }
        }

        Item {
            id: infoArea
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: recordButton.left
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        Text {
            id: uplinkIcon
            text: "\uf519"
            color: uplink_color()
            font.pixelSize: 16
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            anchors.left: infoArea.left
            anchors.leftMargin: 40
            anchors.top: parent.top
            anchors.topMargin: 10
            height: 24
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Row {
            id: topRow
            anchors.right: infoArea.right
            anchors.rightMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 10
            height: 24
            spacing: 8

            Text {
                text: get_frequency_text()
                color: settings.color_text
                font.pixelSize: 16
                font.family: linkFont
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Text {
                text: get_bitrate_text()
                color: bitrate_color(m_camera_stream_model.curr_set_and_measured_bitrate_mismatch)
                font.pixelSize: 16
                font.family: linkFont
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }

        Row {
            id: rcRow
            anchors.right: infoArea.right
            anchors.rightMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            spacing: 2
            height: 14

            Row {
                id: rcBlocks
                spacing: rcRow.spacing
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: rcBlockCount
                    delegate: Shape {
                        width: rcBlockWidth + rcBlockSkew
                        height: rcBlockHeight
                        property bool isActive: rc_rssi_is_valid() && rc_rssi_percentage >= rcBlockThresholds[index]
                        property color shapeColor: settings.color_shape

                        ShapePath {
                            strokeWidth: 1
                            strokeColor: shapeColor
                            fillColor: isActive ? shapeColor : "transparent"
                            startX: 0
                            startY: height
                            PathLine { x: rcBlockSkew; y: 0 }
                            PathLine { x: rcBlockWidth + rcBlockSkew; y: 0 }
                            PathLine { x: rcBlockWidth; y: height }
                            PathLine { x: 0; y: height }
                        }
                    }
                }
            }
        }
    }
}
