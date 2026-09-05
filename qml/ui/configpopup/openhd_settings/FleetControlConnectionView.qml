import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

ScrollView {
    id: root
    property string craftId: ""
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        width: root.availableWidth; spacing: 10
        ComboBox { id: role; Layout.fillWidth: true; model: [qsTr("Air"), qsTr("Ground")]; enabled: !_fleetControlConnection.busy }
        TextField { id: host; Layout.fillWidth: true; placeholderText: qsTr("Device IP address"); selectByMouse: true; enabled: !_fleetControlConnection.busy }
        TextField { id: password; Layout.fillWidth: true; placeholderText: qsTr("OpenHD device password"); echoMode: TextInput.Password; enabled: !_fleetControlConnection.busy }
        Label { text: qsTr("Connecting restarts the device's OpenHD link."); wrapMode: Text.WordWrap; Layout.fillWidth: true; color: settings_form.secondaryText }
        Button {
            text: qsTr("Connect"); Layout.alignment: Qt.AlignRight
            enabled: !_fleetControlConnection.busy && root.craftId.length > 0 && host.text.trim().length > 0 && password.text.length > 0
            onClicked: _fleetControlConnection.connectCraft(root.craftId, role.currentIndex === 0 ? "air" : "ground", host.text.trim(), password.text)
        }
        Label { text: _fleetControlConnection.statusText; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText }
    }
    Dialog {
        id: trust
        property string hostName
        property string fingerprint
        title: qsTr("Trust OpenHD device"); modal: true; anchors.centerIn: parent; width: Math.min(root.width, 440)
        standardButtons: Dialog.Ok | Dialog.Cancel
        Label { width: parent.width; wrapMode: Text.WrapAnywhere; text: qsTr("Device: %1\nCertificate SHA-256:\n%2").arg(trust.hostName).arg(trust.fingerprint) }
        onAccepted: _fleetControlConnection.trustDevice(true)
        onRejected: _fleetControlConnection.trustDevice(false)
    }
    Connections {
        target: _fleetControlConnection
        function onDeviceTrustRequired(hostName, fingerprint) { trust.hostName = hostName; trust.fingerprint = fingerprint; trust.open() }
    }
}
