import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt.labs.platform 1.1 as Platform

Rectangle {
    color: "white"
    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 12
            Label { text: qsTr("Connect to FleetControl"); font.pixelSize: 22; font.bold: true }
            Label { text: qsTr("One craft, one video upload. Connect Air first; add Ground to the same craft whenever you need it."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { text: qsTr("1. Your FleetControl account"); font.bold: true }
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                enabled: !_fleetControlConnection.busy
                Label { text: qsTr("Server") }
                TextField { id: server; text: "https://openhd.tech"; Layout.fillWidth: true; inputMethodHints: Qt.ImhUrlCharactersOnly }
                Label { text: qsTr("Username / email") }
                TextField { id: username; Layout.fillWidth: true }
                Label { text: qsTr("Account password") }
                TextField { id: accountPassword; echoMode: TextInput.Password; Layout.fillWidth: true }
            }
            RowLayout {
                Button { text: qsTr("Sign in"); enabled: !_fleetControlConnection.busy && username.text.length > 0 && accountPassword.text.length > 0; onClicked: { _fleetControlConnection.login(server.text, username.text, accountPassword.text); accountPassword.clear() } }
                Label { text: _fleetControlConnection.authenticated ? qsTr("Signed in") : ""; color: "#14835c" }
            }
            ColumnLayout {
                visible: _fleetControlConnection.authenticated
                Layout.fillWidth: true
                Label { text: qsTr("2. Choose your craft"); font.bold: true }
                ComboBox { id: craft; model: _fleetControlConnection.crafts; textRole: "name"; Layout.fillWidth: true; enabled: !_fleetControlConnection.busy }
                RowLayout {
                    TextField { id: craftName; placeholderText: qsTr("New craft name"); Layout.fillWidth: true }
                    Button { text: qsTr("Create craft"); enabled: !_fleetControlConnection.busy && craftName.text.trim().length >= 2; onClicked: _fleetControlConnection.createCraft(craftName.text) }
                }
                Label { text: qsTr("A valid craft license is required. If you have one available license, FleetControl binds it automatically."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            Label { text: qsTr("3. Connect your OpenHD device"); font.bold: true }
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                enabled: !_fleetControlConnection.busy
                Label { text: qsTr("Device") }
                ComboBox { id: role; model: [qsTr("Air ? video and telemetry"), qsTr("Ground ? telemetry, same craft")]; Layout.fillWidth: true }
                Label { text: qsTr("Device address") }
                TextField { id: deviceAddress; placeholderText: qsTr("IP address or hostname"); Layout.fillWidth: true; inputMethodHints: Qt.ImhUrlCharactersOnly }
                Label { text: qsTr("Device password") }
                TextField { id: devicePassword; echoMode: TextInput.Password; placeholderText: qsTr("Password for the openhd user"); Layout.fillWidth: true }
            }
            Label { text: qsTr("Use the device's LAN or VPN address. Installing a profile restarts its OpenHD link; do this before flight."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Button {
                text: role.currentIndex === 0 ? qsTr("Connect Air") : qsTr("Add Ground to this craft")
                enabled: !_fleetControlConnection.busy && _fleetControlConnection.authenticated && craft.currentIndex >= 0 && deviceAddress.text.length > 0 && devicePassword.text.length > 0
                onClicked: _fleetControlConnection.connectCraft(_fleetControlConnection.crafts[craft.currentIndex].id, role.currentIndex === 0 ? "air" : "ground", deviceAddress.text.trim(), devicePassword.text)
            }
            RowLayout {
                BusyIndicator { running: _fleetControlConnection.busy; visible: running; Layout.preferredWidth: 26; Layout.preferredHeight: 26 }
                Label { text: _fleetControlConnection.statusText; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            Label { text: _fleetControlConnection.deviceStatus; visible: text.length > 0; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { text: qsTr("Already downloaded a device profile?"); font.bold: true }
            RowLayout {
                Button { text: qsTr("Load profile?"); enabled: !_fleetControlConnection.busy; onClicked: profileDialog.open() }
                Button { text: qsTr("Install loaded profile"); enabled: !_fleetControlConnection.busy && deviceAddress.text.length > 0 && devicePassword.text.length > 0; onClicked: _fleetControlConnection.installOnDevice(deviceAddress.text.trim(), devicePassword.text) }
            }
            Label {
                text: _ohdSystemAir.is_alive && _ohdSystemAir.fleetcontrol_lte_active ? qsTr("Air VPN connected ? upload %1 kbit/s").arg(_ohdSystemAir.fleetcontrol_lte_upload_kbit) : ""
                visible: text.length > 0
                color: "#14835c"
            }
        }
    }
    Platform.FileDialog {
        id: profileDialog
        title: qsTr("Select OpenHD FleetControl device profile")
        nameFilters: [qsTr("OpenHD profile (*.conf)")]
        onAccepted: _fleetControlConnection.importProfile(file)
    }
    Dialog {
        id: deviceTrust
        property string hostName
        property string fingerprint
        anchors.centerIn: parent
        width: Math.min(parent.width - 30, 550)
        title: qsTr("Trust this OpenHD device?")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        Label { width: parent.width; wrapMode: Text.WrapAnywhere; text: qsTr("Device: %1\n\nCertificate SHA-256:\n%2\n\nApprove only if this is your device. The certificate is remembered, and a change requires approval again.").arg(deviceTrust.hostName).arg(deviceTrust.fingerprint) }
        onAccepted: _fleetControlConnection.trustDevice(true)
        onRejected: _fleetControlConnection.trustDevice(false)
    }
    Connections {
        target: _fleetControlConnection
        function onDeviceTrustRequired(host, fingerprint) {
            deviceTrust.hostName = host
            deviceTrust.fingerprint = fingerprint
            deviceTrust.open()
        }
    }
}
