import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth
    signal backRequested()
    readonly property var fleetBackend: (typeof _fleetControlLte !== "undefined") ? _fleetControlLte : null
    property string selectedLicenseId: ""
    readonly property int licenseIndex: {
        var licenses = fleetBackend ? fleetBackend.licenses : []
        for (var i = 0; i < licenses.length; ++i)
            if (licenses[i].id === selectedLicenseId) return i
        return licenses.length ? 0 : -1
    }
    readonly property var selectedLicense: licenseIndex >= 0 && fleetBackend ? fleetBackend.licenses[licenseIndex] : null
    readonly property var availableCrafts: {
        var result = []
        if (!selectedLicense) return result
        var crafts = fleetBackend ? fleetBackend.crafts : []
        var licenses = fleetBackend ? fleetBackend.licenses : []
        for (var i = 0; i < crafts.length; ++i) {
            var craft = crafts[i]
            if (selectedLicense.craftId) {
                if (craft.id === selectedLicense.craftId) result.push(craft)
            } else {
                var assigned = !!craft.licenseId
                for (var j = 0; j < licenses.length; ++j)
                    if (licenses[j].craftId === craft.id) assigned = true
                if (!assigned) result.push(craft)
            }
        }
        return result
    }
    readonly property var selectedCraft: craftBox.currentIndex >= 0 && craftBox.currentIndex < availableCrafts.length ? availableCrafts[craftBox.currentIndex] : null
    readonly property bool craftAssigned: !!(selectedLicense && selectedCraft && selectedLicense.craftId === selectedCraft.id)
    readonly property bool transmissionEnabled: craftAssigned && !!(selectedCraft.mavlink || selectedCraft.video1 || selectedCraft.video2)
    readonly property bool canStartTransmission: craftAssigned && selectedLicense.status !== "expired" && !!(selectedLicense.mavlinkAllowed || selectedLicense.video1Allowed)
    readonly property bool working: fleetBackend ? fleetBackend.busy : false
    function gainFocus() { (fleetBackend && fleetBackend.authenticated ? certificateBox : username).forceActiveFocus() }
    function dateText(value) {
        // The backend supplies an ISO 8601 date. Keeping that representation
        // avoids Qt 6.2's incompatible JavaScript-Date conversion in formatDate.
        return String(value)
    }
    Keys.onEscapePressed: root.backRequested()

    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        RowLayout {
            Layout.fillWidth: true; Layout.margins: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Text { Layout.fillWidth: true; text: qsTr("FleetControl"); color: settings_form.primaryText; font.pixelSize: MenuTypography.sectionTitle; font.family: MenuTypography.family; font.bold: true }
                Text { Layout.fillWidth: true; text: "openhd.tech"; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family }
            }
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; visible: root.fleetBackend && root.fleetBackend.authenticated; text: qsTr("Sign out"); enabled: !root.working; opacity: enabled ? 1 : 0.5; onClicked: { if (root.fleetBackend) root.fleetBackend.logout() } }
        }
        ColumnLayout {
            visible: !root.fleetBackend || !root.fleetBackend.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 10

            TextField { verticalAlignment: TextInput.AlignVCenter; topPadding: 6; bottomPadding: 6;
                id: username; objectName: "fleetUsername"; Layout.fillWidth: true; Layout.preferredHeight: MenuTypography.controlHeight
                placeholderText: qsTr("Username or email"); selectByMouse: true; enabled: !root.working; onAccepted: password.forceActiveFocus()
                font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; color: settings_form.primaryText; placeholderTextColor: settings_form.secondaryText
                leftPadding: 12; rightPadding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackground; border.color: username.activeFocus ? settings_form.accentColor : settings_form.lineColor }
            }
            TextField { verticalAlignment: TextInput.AlignVCenter; topPadding: 6; bottomPadding: 6;
                id: password; objectName: "fleetPassword"; Layout.fillWidth: true; Layout.preferredHeight: MenuTypography.controlHeight
                placeholderText: qsTr("Password"); echoMode: TextInput.Password; enabled: !root.working; onAccepted: { if (signIn.enabled) signIn.clicked() }
                font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; color: settings_form.primaryText; placeholderTextColor: settings_form.secondaryText
                leftPadding: 12; rightPadding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackground; border.color: password.activeFocus ? settings_form.accentColor : settings_form.lineColor }
            }
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                id: signIn; objectName: "fleetSignIn"; text: qsTr("Sign in"); primary: true; Layout.alignment: Qt.AlignRight
                enabled: !root.working && username.text.trim().length > 0 && password.text.length > 0; opacity: enabled ? 1 : 0.5
                onClicked: { if (root.fleetBackend) root.fleetBackend.login(username.text, password.text); password.clear() }
            }
        }
        ColumnLayout {
            visible: root.fleetBackend && root.fleetBackend.authenticated
            Layout.fillWidth: true; Layout.margins: 12; spacing: 12
            Text { Layout.fillWidth: true; text: root.fleetBackend ? root.fleetBackend.accountName : ""; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; elide: Text.ElideRight }
            Pane {
                Layout.fillWidth: true; padding: 12
                background: Rectangle { radius: 8; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor }
                contentItem: ColumnLayout {
                    spacing: 10
                    Text { text: qsTr("Certificate"); color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                    CompactLinkComboBox {
                        id: certificateBox; objectName: "fleetCertificate"; Layout.fillWidth: true; Layout.preferredHeight: MenuTypography.controlHeight; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        model: root.fleetBackend ? root.fleetBackend.licenses.map(function(license) { return license.plan + " · " + license.id.slice(-6) }) : []
                        currentIndex: root.licenseIndex; enabled: !root.working && count > 1
                        displayText: root.selectedLicense ? model[root.licenseIndex] : qsTr("No certificates in this account")
                        onActivated: { if (root.fleetBackend) root.selectedLicenseId = root.fleetBackend.licenses[currentIndex].id }
                    }
                    Text {
                        objectName: "fleetLicenceExpiry"; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        text: !root.selectedLicense ? qsTr("Your licences will appear here after they are added to your account.")
                              : root.selectedLicense.status === "expired" ? qsTr("Expired %1").arg(root.dateText(root.selectedLicense.expiresAt))
                              : qsTr("Active until %1 · %2 days left").arg(root.dateText(root.selectedLicense.expiresAt)).arg(Math.max(0, root.selectedLicense.daysRemaining))
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                    Text { text: qsTr("Craft"); color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                    CompactLinkComboBox {
                        id: craftBox; objectName: "fleetCraft"; Layout.fillWidth: true; Layout.preferredHeight: MenuTypography.controlHeight; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        model: root.availableCrafts.map(function(craft) { return craft.name })
                        enabled: !root.working && root.selectedLicense && !root.selectedLicense.craftId && count > 0
                        displayText: root.selectedCraft ? root.selectedCraft.name : qsTr("No available craft")
                    }
                    Text {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        text: root.selectedLicense && root.selectedLicense.craftId ? qsTr("Assigned to this certificate")
                              : root.availableCrafts.length ? qsTr("Each certificate is permanently assigned to one craft.")
                              : !root.fleetBackend || !root.fleetBackend.crafts.length ? qsTr("No craft in this account yet.") : qsTr("All your craft already have a certificate.")
                    }
                    AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                        objectName: "fleetAssign"; text: qsTr("Assign craft"); primary: true; Layout.alignment: Qt.AlignRight
                        visible: root.selectedLicense && !root.selectedLicense.craftId
                        enabled: !root.working && root.selectedCraft && root.selectedLicense && root.selectedLicense.status !== "expired"
                        opacity: enabled ? 1 : 0.5
                        onClicked: { if (root.fleetBackend) root.fleetBackend.bindLicense(root.selectedLicense.id, root.selectedCraft.id) }
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
                        Text { text: qsTr("Transmission"); Layout.fillWidth: true; color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                        AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            objectName: "fleetTransmission"
                            text: root.transmissionEnabled ? qsTr("Stop transmission") : qsTr("Start transmission")
                            primary: !root.transmissionEnabled
                            enabled: !root.working && (root.transmissionEnabled || root.canStartTransmission)
                            opacity: enabled ? 1 : 0.5
                            onClicked: { if (root.fleetBackend) root.fleetBackend.setTransmission(root.selectedCraft.id, !root.transmissionEnabled) }
                        }
                    }
                    Text {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                        text: !root.craftAssigned ? qsTr("Assign a craft to start transmission.")
                              : root.transmissionEnabled ? qsTr("Transmission to openhd.tech is enabled.")
                              : qsTr("Transmission to openhd.tech is stopped.")
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Video quality"); Layout.fillWidth: true; color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                        Text { text: "480p · 15 fps · 1 Mbit/s"; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family }
                    }


                }
            }
        }
        Text {
            Layout.fillWidth: true; Layout.margins: 12; text: root.fleetBackend ? root.fleetBackend.statusText : ""
            color: settings_form.secondaryText; wrapMode: Text.WordWrap; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
        }
    }
}
