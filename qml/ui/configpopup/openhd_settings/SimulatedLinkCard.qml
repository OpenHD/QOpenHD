import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    property string linkKind: "ethernet"
    readonly property bool simulated: ethernet ? settings.dev_simulate_ethernet_link : settings.dev_simulate_uart_link
    readonly property bool ethernet: linkKind === "ethernet"
    readonly property string title: ethernet ? qsTr("Ethernet Link") : qsTr("UART Link")
    readonly property string icon: ethernet ? "\uf796" : "\uf120"
    readonly property string endpoint: simulated ? (ethernet ? "192.168.2.2:5600" : "/dev/ttyS1") : qsTr("Reported by OpenHD")
    radius: 10
    color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1

    function gainFocus() { details.forceActiveFocus() }
    function leaveCard() { if (host) host.collapseCard(cardIndex) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text { text: root.icon; color: ethernet ? "#49a6ff" : "#c98cff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 19 }
            Text { text: root.title; color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Rectangle { Layout.preferredWidth: active.implicitWidth + 14; Layout.preferredHeight: 21; radius: 7; color: Qt.rgba(0.1, 0.8, 0.35, 0.12)
                Text { id: active; anchors.centerIn: parent; text: root.simulated ? qsTr("SIMULATED") : qsTr("ACTIVE"); color: settings_form.goodColor; font.pixelSize: 8; font.bold: true }
            }
        }
        LinkUsageMeter {
            visible: settings.dev_show_advanced_button
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? (root.width < 360 ? 100 : 78) : 0
            usage: root.host ? root.host.usageFor(root.linkKind) : null
            title: qsTr("Link Usage")
        }
        GridLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 58; columns: 3
            Repeater {
                model: ethernet
                       ? [{label: qsTr("CAPACITY"), value: root.host && root.host.usageFor("ethernet") && root.host.usageFor("ethernet").capacity_bps > 0 ? root.host.usageFor("ethernet").capacity_bps / 1000000 + " Mbit/s" : qsTr("N/A")}, {label: qsTr("LATENCY"), value: root.simulated ? "2 ms" : qsTr("N/A")}, {label: qsTr("LOSS"), value: root.simulated ? "0%" : qsTr("N/A")}]
                       : [{label: qsTr("CAPACITY"), value: root.host && root.host.usageFor("uart") && root.host.usageFor("uart").capacity_bps > 0 ? root.host.usageFor("uart").capacity_bps / 1000 + " kbit/s" : qsTr("N/A")}, {label: qsTr("PROTOCOL"), value: "MAVLink 2"}, {label: qsTr("LOSS"), value: root.simulated ? "0%" : qsTr("N/A")}]
                delegate: Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 7; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }
        Rectangle {
            id: details
            Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 7
            color: settings_form.panelBackground; border.color: settings_form.lineColor
            focus: true
            Keys.onPressed: function(event) { if (event.key === Qt.Key_Escape) { root.leaveCard(); event.accepted = true } }
            ColumnLayout { anchors.fill: parent; anchors.margins: 9; spacing: 4
                Text { text: root.simulated ? qsTr("FIXTURE DETAILS") : qsTr("LINK DETAILS"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                Text { text: root.endpoint; color: settings_form.primaryText; font.pixelSize: 11; font.bold: true }
                Text { text: ethernet ? qsTr("Air video and telemetry transport") : qsTr("Air flight-controller telemetry transport"); color: settings_form.secondaryText; font.pixelSize: 9; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
        }
        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; text: root.simulated ? qsTr("Developer fixture - no physical link is created.") : qsTr("Usage reported by OpenHD telemetry."); color: settings_form.secondaryText; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
    }
}
