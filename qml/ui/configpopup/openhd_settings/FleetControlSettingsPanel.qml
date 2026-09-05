import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12

ScrollView {
    id: root
    clip: true
    font.pixelSize: 12
    contentWidth: availableWidth
    signal backRequested()
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised
    property var selectedCraft: craftBox.currentIndex >= 0 && craftBox.currentIndex < _fleetControlLte.crafts.length ? _fleetControlLte.crafts[craftBox.currentIndex] : null
    property var selectedLicense: {
        if (!selectedCraft) return null
        for (var i = 0; i < _fleetControlLte.licenses.length; ++i)
            if (_fleetControlLte.licenses[i].id === selectedCraft.licenseId) return _fleetControlLte.licenses[i]
        return null
    }
    property bool encryptionAvailable: false
    property bool encryptionEnabled: false
    property bool pendingEncryption: false
    readonly property bool working: _fleetControlLte.busy || _fleetControlConnection.busy
    function gainFocus() { (_fleetControlLte.authenticated ? craftBox : username).forceActiveFocus() }
    function syncEncryption() {
        encryptionAvailable = _airCameraSettingsModel.param_int_exists("HIGH_ENCRYPTION")
        encryptionEnabled = encryptionAvailable && _airCameraSettingsModel.get_cached_int("HIGH_ENCRYPTION") === 1
    }
    Component.onCompleted: syncEncryption()
    Connections {
        target: _fleetControlLte
        function onStatusChanged() {
            if (root.pendingEncryption && !_fleetControlLte.busy) {
                root.pendingEncryption = false
                if (_fleetControlLte.certificateInstalled)
                    _airCameraSettingsModel.try_set_param_int_async("HIGH_ENCRYPTION", 1, true)
            }
        }
    }
    Timer { interval: 1500; running: root.visible && _fleetControlLte.authenticated; repeat: true; onTriggered: root.syncEncryption() }
    Keys.onEscapePressed: root.backRequested()
    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        Label { text: qsTr("FleetControl"); font.pixelSize: 18; font.bold: true; Layout.topMargin: 12; Layout.leftMargin: 12 }
        ColumnLayout {
            visible: !_fleetControlLte.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 10
            Label { text: qsTr("Sign in to your FleetControl account"); color: settings_form.secondaryText; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            TextField { id: username; objectName: "fleetUsername"; Layout.fillWidth: true; placeholderText: qsTr("Username or email"); selectByMouse: true; enabled: !root.working; onAccepted: password.forceActiveFocus() }
            TextField { id: password; objectName: "fleetPassword"; Layout.fillWidth: true; placeholderText: qsTr("Password"); echoMode: TextInput.Password; enabled: !root.working; onAccepted: { if (signIn.enabled) signIn.clicked() } }
            Button {
                id: signIn; objectName: "fleetSignIn"; text: qsTr("Sign in"); Layout.alignment: Qt.AlignRight
                enabled: !root.working && username.text.trim().length > 0 && password.text.length > 0
                onClicked: { _fleetControlLte.login(username.text, password.text); password.clear() }
            }
        }
        ColumnLayout {
            visible: _fleetControlLte.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: _fleetControlLte.accountName; elide: Text.ElideRight; color: settings_form.secondaryText }
                Button { text: qsTr("Sign out"); enabled: !root.working; onClicked: _fleetControlLte.logout() }
            }
            GroupBox {
                title: qsTr("Connection"); Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: qsTr("Craft") }
                        ComboBox { id: craftBox; objectName: "fleetCraft"; Layout.fillWidth: true; model: _fleetControlLte.crafts; textRole: "name"; enabled: !root.working }
                        Button { text: qsTr("Add"); enabled: !root.working; onClicked: newCraft.open() }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { Layout.fillWidth: true; text: _fleetControlConnection.deviceStatus || (_fleetControlLte.active ? qsTr("Connected") : qsTr("Connect Air or Ground to this craft")); color: settings_form.secondaryText; wrapMode: Text.WordWrap }
                        Button { text: qsTr("Connect device"); enabled: !root.working && root.selectedCraft !== null; onClicked: deviceDialog.open() }
                    }
                }
            }
            GroupBox {
                title: qsTr("Video"); Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: qsTr("Quality"); Layout.fillWidth: true }
                        Label { text: qsTr("480p / 15 fps / 1 Mbit/s"); color: settings_form.secondaryText }
                    }
                    Label { text: qsTr("Standard FleetControl quality"); font.pixelSize: 11; color: settings_form.secondaryText }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: qsTr("Video encryption"); Layout.fillWidth: true }
                        Switch {
                            id: encryption; objectName: "fleetEncryption"
                            checked: root.encryptionEnabled
                            enabled: root.encryptionAvailable && !root.working && (root.encryptionEnabled || (root.selectedLicense && root.selectedLicense.status !== "expired" && root.selectedLicense.video1Allowed))
                            onClicked: {
                                if (checked && !_fleetControlLte.certificateInstalled) {
                                    root.pendingEncryption = true
                                    _fleetControlLte.requestVideoCertificate(root.selectedLicense.id)
                                } else {
                                    _airCameraSettingsModel.try_set_param_int_async("HIGH_ENCRYPTION", checked ? 1 : 0, true)
                                }
                                checked = Qt.binding(function() { return root.encryptionEnabled })
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11; color: settings_form.secondaryText
                        text: !root.encryptionAvailable ? qsTr("Connect Air to change video encryption.") : qsTr("Additional Air video encryption. The FleetControl connection is always encrypted.")
                    }
                }
            }
            GroupBox {
                title: qsTr("Licence"); Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: root.selectedLicense ? root.selectedLicense.plan : qsTr("No licence assigned"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        Label { text: root.selectedLicense ? root.selectedLicense.status : ""; color: settings_form.secondaryText }
                    }
                    Label {
                        objectName: "fleetLicenceExpiry"; Layout.fillWidth: true; wrapMode: Text.WordWrap
                        text: root.selectedLicense ? (root.selectedLicense.status === "expired" ? qsTr("Expired on %1").arg(root.selectedLicense.expiresAt) : qsTr("Active until %1 (%2 days remaining)").arg(root.selectedLicense.expiresAt).arg(Math.max(0, root.selectedLicense.daysRemaining))) : qsTr("Choose a licence for this craft.")
                        color: settings_form.secondaryText
                    }
                    RowLayout {
                        visible: !root.selectedLicense; Layout.fillWidth: true
                        ComboBox { id: licenceBox; Layout.fillWidth: true; model: _fleetControlLte.licenses; textRole: "plan" }
                        Button { text: qsTr("Assign"); enabled: !root.working && root.selectedCraft && licenceBox.currentIndex >= 0 && !_fleetControlLte.licenses[licenceBox.currentIndex].craftId; onClicked: _fleetControlLte.bindLicense(_fleetControlLte.licenses[licenceBox.currentIndex].id, root.selectedCraft.id) }
                    }
                    Label { visible: _fleetControlLte.certificateExpiresAt.length > 0; text: qsTr("Video certificate valid until %1").arg(_fleetControlLte.certificateExpiresAt); Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: 11 }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.margins: 12
            BusyIndicator { running: root.working; visible: running; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
            Label { Layout.fillWidth: true; text: _fleetControlLte.statusText; color: settings_form.secondaryText; wrapMode: Text.WordWrap; font.pixelSize: 11 }
        }
    }
    Dialog {
        id: newCraft; title: qsTr("Add craft"); modal: true; anchors.centerIn: parent; width: Math.min(root.width - 24, 380)
        standardButtons: Dialog.Ok | Dialog.Cancel
        TextField { id: craftName; width: parent.width; placeholderText: qsTr("Craft name"); maximumLength: 60 }
        onAccepted: { _fleetControlLte.createCraft(craftName.text); craftName.clear() }
    }
    Dialog {
        id: deviceDialog; title: qsTr("Connect device"); modal: true; anchors.centerIn: parent
        width: Math.min(root.width - 24, 480); height: Math.min(root.height - 24, 440); standardButtons: Dialog.Close
        FleetControlConnectionView { anchors.fill: parent; craftId: root.selectedCraft ? root.selectedCraft.id : "" }
    }
}
