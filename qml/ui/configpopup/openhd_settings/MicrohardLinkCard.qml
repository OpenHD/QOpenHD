import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    radius: 10; color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1
    function gainFocus() { parent.parent.forceActiveFocus() }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 7
        RowLayout { Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 8
            Text { text: "M"; color: "#36c88a"; font.pixelSize: 18; font.bold: true }
            Text { text: qsTr("Microhard Link 1"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Rectangle { width: activeText.implicitWidth + 14; height: 21; radius: 7; color: Qt.rgba(0.1, 0.8, 0.35, 0.12)
                Text { id: activeText; anchors.centerIn: parent; text: qsTr("ACTIVE"); color: settings_form.goodColor; font.pixelSize: 8; font.bold: true }
            }
        }
        GridLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 55; columns: 4; columnSpacing: 0
            Repeater { model: [
                {label: "RSSI", value: _ohdSystemGround.microhard_rssi + " dBm"},
                {label: "SNR", value: _ohdSystemGround.microhard_snr + " dB"},
                {label: qsTr("NOISE"), value: _ohdSystemGround.microhard_noise + " dBm"},
                {label: qsTr("TX POWER"), value: String(_ohdSystemGround.microhard_tx_pwr)}]
                delegate: Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 7; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 107; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            ColumnLayout { anchors.fill: parent; anchors.margins: 9; spacing: 8
                Text { text: qsTr("RADIO"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                GridLayout { Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 15
                    Text { text: qsTr("Frequency"); color: settings_form.secondaryText; font.pixelSize: 9 }
                    Text { text: _ohdSystemGround.microhard_freq + " MHz"; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                    Text { text: qsTr("Channel width"); color: settings_form.secondaryText; font.pixelSize: 9 }
                    Text { text: _ohdSystemGround.microhard_bw + " MHz"; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 92; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            GridLayout { anchors.fill: parent; anchors.margins: 9; columns: 2; rowSpacing: 9
                Text { text: qsTr("Telemetry TX"); color: settings_form.secondaryText; font.pixelSize: 9 }
                Text { text: _ohdSystemGround.curr_telemetry_tx_bps; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                Text { text: qsTr("Telemetry RX"); color: settings_form.secondaryText; font.pixelSize: 9 }
                Text { text: _ohdSystemGround.curr_telemetry_rx_bps; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
            }
        }
        Item { Layout.fillHeight: true }
        RowLayout { Layout.fillWidth: true; Layout.preferredHeight: 25
            Text { Layout.fillWidth: true; text: qsTr("Telemetry status reported by OpenHD"); color: settings_form.secondaryText; font.pixelSize: 7 }
            Rectangle { width: 7; height: 7; radius: 4; color: settings_form.goodColor }
        }
    }
}
