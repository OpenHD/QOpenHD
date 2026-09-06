import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth
    signal backRequested()
    property string selectedLicenseId: ""
    readonly property int licenseIndex: {
        for (var i = 0; i < _fleetControlLte.licenses.length; ++i)
            if (_fleetControlLte.licenses[i].id === selectedLicenseId) return i
        return _fleetControlLte.licenses.length ? 0 : -1
    }
    readonly property var selectedLicense: licenseIndex >= 0 ? _fleetControlLte.licenses[licenseIndex] : null
    readonly property var availableCrafts: {
        var result = []
        if (!selectedLicense) return result
        for (var i = 0; i < _fleetControlLte.crafts.length; ++i) {
            var craft = _fleetControlLte.crafts[i]
            if (selectedLicense.craftId) {
                if (craft.id === selectedLicense.craftId) result.push(craft)
            } else {
                var assigned = !!craft.licenseId
                for (var j = 0; j < _fleetControlLte.licenses.length; ++j)
                    if (_fleetControlLte.licenses[j].craftId === craft.id) assigned = true
                if (!assigned) result.push(craft)
            }
        }
        return result
    }
    readonly property var selectedCraft: craftBox.currentIndex >= 0 && craftBox.currentIndex < availableCrafts.length ? availableCrafts[craftBox.currentIndex] : null
    property bool encryptionAvailable: false
    property bool encryptionEnabled: false
    property string pendingEncryptionLicense: ""
    readonly property bool working: _fleetControlLte.busy
    function gainFocus() { (_fleetControlLte.authenticated ? certificateBox : username).forceActiveFocus() }
    function syncEncryption() {
        encryptionAvailable = _airCameraSettingsModel.param_int_exists("HIGH_ENCRYPTION")
        encryptionEnabled = encryptionAvailable && _airCameraSettingsModel.get_cached_int("HIGH_ENCRYPTION") === 1
    }
    function dateText(value) {
        var date = new Date(value)
        return isNaN(date.getTime()) ? value : Qt.formatDate(date, Qt.DefaultLocaleShortDate)
    }
    Component.onCompleted: syncEncryption()
    Connections {
        target: _fleetControlLte
        function onStatusChanged() {
            if (root.pendingEncryptionLicense && !_fleetControlLte.busy) {
                var requested = root.pendingEncryptionLicense
                root.pendingEncryptionLicense = ""
                if (_fleetControlLte.authenticated && root.selectedLicense && root.selectedLicense.id === requested
                        && _fleetControlLte.certificateInstalled && _fleetControlLte.certificateLicenseId === requested)
                    _airCameraSettingsModel.try_set_param_int_async("HIGH_ENCRYPTION", 1, true)
            }
        }
    }
    Timer { interval: 1500; running: root.visible && _fleetControlLte.authenticated; repeat: true; onTriggered: root.syncEncryption() }
    Keys.onEscapePressed: root.backRequested()

    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        RowLayout {
            Layout.fillWidth: true; Layout.margins: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Text { Layout.fillWidth: true; text: qsTr("FleetControl"); color: settings_form.primaryText; font.pixelSize: 18; font.bold: true }
                Text { Layout.fillWidth: true; text: "openhd.tech"; color: settings_form.secondaryText; font.pixelSize: 12 }
            }
            AdvancedActionButton { visible: _fleetControlLte.authenticated; text: qsTr("Sign out"); enabled: !root.working; opacity: enabled ? 1 : 0.5; onClicked: _fleetControlLte.logout() }
        }
        ColumnLayout {
            visible: !_fleetControlLte.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 10
            Text { text: qsTr("Sign in to assign your craft to a certificate."); color: settings_form.secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            TextField {
                id: username; objectName: "fleetUsername"; Layout.fillWidth: true; Layout.preferredHeight: 40
                placeholderText: qsTr("Username or email"); selectByMouse: true; enabled: !root.working; onAccepted: password.forceActiveFocus()
                font.pixelSize: 13; color: settings_form.primaryText; placeholderTextColor: settings_form.secondaryText
                leftPadding: 12; rightPadding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackground; border.color: username.activeFocus ? settings_form.accentColor : settings_form.lineColor }
            }
            TextField {
                id: password; objectName: "fleetPassword"; Layout.fillWidth: true; Layout.preferredHeight: 40
                placeholderText: qsTr("Password"); echoMode: TextInput.Password; enabled: !root.working; onAccepted: { if (signIn.enabled) signIn.clicked() }
                font.pixelSize: 13; color: settings_form.primaryText; placeholderTextColor: settings_form.secondaryText
                leftPadding: 12; rightPadding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackground; border.color: password.activeFocus ? settings_form.accentColor : settings_form.lineColor }
            }
            AdvancedActionButton {
                id: signIn; objectName: "fleetSignIn"; text: qsTr("Sign in"); primary: true; Layout.alignment: Qt.AlignRight
                enabled: !root.working && username.text.trim().length > 0 && password.text.length > 0; opacity: enabled ? 1 : 0.5
                onClicked: { _fleetControlLte.login(username.text, password.text); password.clear() }
            }
        }
        ColumnLayout {
            visible: _fleetControlLte.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 12
            Text { Layout.fillWidth: true; text: _fleetControlLte.accountName; color: settings_form.secondaryText; font.pixelSize: 12; elide: Text.ElideRight }
            Pane {
                Layout.fillWidth: true; padding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor }
                contentItem: ColumnLayout {
                    spacing: 10
                    Text { text: qsTr("Certificate"); color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                    CompactLinkComboBox {
                        id: certificateBox; objectName: "fleetCertificate"; Layout.fillWidth: true; Layout.preferredHeight: 40; font.pixelSize: 13
                        model: _fleetControlLte.licenses.map(function(license) { return license.plan + " · " + license.id.slice(-6) })
                        currentIndex: root.licenseIndex; enabled: !root.working && count > 1
                        displayText: root.selectedLicense ? model[root.licenseIndex] : qsTr("No certificates in this account")
                        onActivated: root.selectedLicenseId = _fleetControlLte.licenses[currentIndex].id
                    }
                    Text {
                        objectName: "fleetLicenceExpiry"; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: 12
                        text: !root.selectedLicense ? qsTr("Your licences will appear here after they are added to your account.")
                              : root.selectedLicense.status === "expired" ? qsTr("Expired %1").arg(root.dateText(root.selectedLicense.expiresAt))
                              : qsTr("Active until %1 · %2 days left").arg(root.dateText(root.selectedLicense.expiresAt)).arg(Math.max(0, root.selectedLicense.daysRemaining))
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                    Text { text: qsTr("Craft"); color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                    CompactLinkComboBox {
                        id: craftBox; objectName: "fleetCraft"; Layout.fillWidth: true; Layout.preferredHeight: 40; font.pixelSize: 13
                        model: root.availableCrafts.map(function(craft) { return craft.name })
                        enabled: !root.working && root.selectedLicense && !root.selectedLicense.craftId && count > 0
                        displayText: root.selectedCraft ? root.selectedCraft.name : qsTr("No available craft")
                    }
                    Text {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: 12
                        text: root.selectedLicense && root.selectedLicense.craftId ? qsTr("Assigned to this certificate")
                              : root.availableCrafts.length ? qsTr("Each certificate is permanently assigned to one craft.")
                              : !_fleetControlLte.crafts.length ? qsTr("No craft in this account yet.") : qsTr("All your craft already have a certificate.")
                    }
                    AdvancedActionButton {
                        objectName: "fleetAssign"; text: qsTr("Assign craft"); primary: true; Layout.alignment: Qt.AlignRight
                        visible: root.selectedLicense && !root.selectedLicense.craftId
                        enabled: !root.working && root.selectedCraft && root.selectedLicense && root.selectedLicense.status !== "expired"
                        opacity: enabled ? 1 : 0.5
                        onClicked: _fleetControlLte.bindLicense(root.selectedLicense.id, root.selectedCraft.id)
                    }
                }
            }
            Pane {
                Layout.fillWidth: true; padding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor }
                contentItem: ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Video quality"); Layout.fillWidth: true; color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                        Text { text: "480p · 15 fps · 1 Mbit/s"; color: settings_form.secondaryText; font.pixelSize: 12 }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Video encryption"); Layout.fillWidth: true; color: settings_form.primaryText; font.pixelSize: 13 }
                        Switch {
                            id: encryption; objectName: "fleetEncryption"; implicitWidth: 48; implicitHeight: 30; padding: 0
                            checked: root.encryptionEnabled
                            enabled: root.encryptionAvailable && !root.working && (root.encryptionEnabled || (root.selectedLicense && root.selectedLicense.craftId && root.selectedLicense.status !== "expired" && root.selectedLicense.video1Allowed))
                            opacity: enabled ? 1 : 0.5
                            indicator: Rectangle {
                                width: 44; height: 24; radius: 12; anchors.centerIn: parent
                                color: encryption.checked ? settings_form.accentColor : settings_form.panelBackground
                                border.color: encryption.activeFocus ? settings_form.accentColor : settings_form.lineColor
                                border.width: encryption.activeFocus ? 2 : 1
                                Rectangle { x: encryption.checked ? 23 : 3; y: 3; width: 18; height: 18; radius: 9; color: encryption.checked ? "white" : settings_form.secondaryText }
                            }
                            onClicked: {
                                if (checked && (!_fleetControlLte.certificateInstalled || _fleetControlLte.certificateLicenseId !== root.selectedLicense.id)) {
                                    root.pendingEncryptionLicense = root.selectedLicense.id
                                    _fleetControlLte.requestVideoCertificate(root.selectedLicense.id)
                                } else {
                                    _airCameraSettingsModel.try_set_param_int_async("HIGH_ENCRYPTION", checked ? 1 : 0, true)
                                }
                                checked = Qt.binding(function() { return root.encryptionEnabled })
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; color: settings_form.secondaryText
                        text: !root.encryptionAvailable ? qsTr("Connect Air to change video encryption.") : qsTr("Encrypt the Air video link. Streaming to openhd.tech is always encrypted.")
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true; Layout.margins: 12; text: _fleetControlLte.statusText
            color: settings_form.secondaryText; wrapMode: Text.WordWrap; font.pixelSize: 12
        }
    }
}
