import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

Rectangle {
    id: root
    color: "transparent"
    signal backRequested()

    property var selectedCraft: craftBox.currentIndex >= 0 && craftBox.currentIndex < _fleetControlLte.crafts.length
                                ? _fleetControlLte.crafts[craftBox.currentIndex] : null
    property var selectedLicense: licenseBox.currentIndex >= 0 && licenseBox.currentIndex < _fleetControlLte.licenses.length
                                  ? _fleetControlLte.licenses[licenseBox.currentIndex] : null
    property bool syncingStreams: false
    property bool connectingDevice: true
    FleetControlConnectionView {
        anchors.fill: parent
        anchors.topMargin: 38
        visible: root.connectingDevice
    }
    Button {
        anchors.top: parent.top
        anchors.right: parent.right
        text: root.connectingDevice ? qsTr("Licenses & certificates") : qsTr("Connect Air / Ground")
        onClicked: root.connectingDevice = !root.connectingDevice
    }

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    function gainFocus() {
        if (_fleetControlLte.authenticated) craftBox.forceActiveFocus()
        else usernameField.forceActiveFocus()
    }

    function syncStreamControls() {
        syncingStreams = true
        mavlinkSwitch.checked = selectedCraft ? selectedCraft.mavlink : false
        videoOneSwitch.checked = selectedCraft ? selectedCraft.video1 : false
        videoTwoSwitch.checked = selectedCraft ? selectedCraft.video2 : false
        syncingStreams = false
    }

    function selectedCraftLicense() {
        if (!selectedCraft || !selectedCraft.licenseId) return null
        for (var i = 0; i < _fleetControlLte.licenses.length; ++i)
            if (_fleetControlLte.licenses[i].id === selectedCraft.licenseId)
                return _fleetControlLte.licenses[i]
        return null
    }

    Keys.onEscapePressed: root.backRequested()
    onSelectedCraftChanged: syncStreamControls()

    Connections {
        target: _fleetControlLte
        onStatusChanged: {
            if (craftBox.currentIndex >= _fleetControlLte.crafts.length)
                craftBox.currentIndex = _fleetControlLte.crafts.length ? 0 : -1
            if (licenseBox.currentIndex >= _fleetControlLte.licenses.length)
                licenseBox.currentIndex = _fleetControlLte.licenses.length ? 0 : -1
            root.syncStreamControls()
        }
    }

    Flickable {
        visible: !root.connectingDevice
        anchors.fill: parent
        anchors.topMargin: 38
        anchors.margins: 8
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 9

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                radius: 9
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                    Rectangle {
                        width: 38; height: 38; radius: 10
                        color: _fleetControlLte.authenticated
                               ? Qt.rgba(0.1, 0.8, 0.35, 0.13)
                               : Qt.rgba(0.1, 0.55, 1.0, 0.13)
                        Text {
                            anchors.centerIn: parent; text: "\uf0c0"
                            font.family: "Font Awesome 5 Free"; font.pixelSize: 17
                            color: _fleetControlLte.authenticated ? settings_form.goodColor : settings_form.accentColor
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: qsTr("FLEETCONTROL"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: _fleetControlLte.authenticated
                                  ? qsTr("Signed in as %1").arg(_fleetControlLte.accountName)
                                  : qsTr("License, craft identity and encrypted Air uplink")
                            color: settings_form.secondaryText; font.pixelSize: 9; elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        width: sessionText.implicitWidth + 16; height: 23; radius: 7
                        color: _fleetControlLte.authenticated
                               ? Qt.rgba(0.1, 0.8, 0.35, 0.12)
                               : Qt.rgba(1.0, 0.65, 0.1, 0.12)
                        Text {
                            id: sessionText; anchors.centerIn: parent
                            text: _fleetControlLte.authenticated ? qsTr("CONNECTED") : qsTr("SIGN IN")
                            color: _fleetControlLte.authenticated ? settings_form.goodColor : "#f0a43c"
                            font.pixelSize: 8; font.bold: true
                        }
                    }
                }
            }

            Rectangle {
                visible: !_fleetControlLte.authenticated
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? loginColumn.implicitHeight + 24 : 0
                radius: 9; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                ColumnLayout {
                    id: loginColumn
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 14; spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: qsTr("FLEETCONTROL ACCOUNT"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: serviceText.implicitWidth + 22
                            Layout.preferredHeight: 27
                            radius: 8
                            color: settings_form.panelBackground
                            border.color: settings_form.lineColor
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "\uf023"; font.family: "Font Awesome 5 Free"; font.pixelSize: 9; color: settings_form.goodColor }
                                Text { id: serviceText; text: qsTr("openhd.tech"); color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Sign in with your FleetControl operator account. The secure OpenHD service is configured automatically.")
                        color: settings_form.secondaryText
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }
                    GridLayout {
                        Layout.fillWidth: true; columns: root.width < 650 ? 1 : 2; columnSpacing: 10; rowSpacing: 8
                        TextField { id: usernameField; Layout.fillWidth: true; placeholderText: qsTr("Operator ID or email"); selectByMouse: true; onAccepted: passwordField.forceActiveFocus() }
                        TextField { id: passwordField; Layout.fillWidth: true; placeholderText: qsTr("Password"); echoMode: TextInput.Password; passwordCharacter: "●"; selectByMouse: true; onAccepted: loginButton.clicked() }
                    }
                    Button {
                        id: loginButton; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 150
                        text: _fleetControlLte.busy ? qsTr("CONNECTING...") : qsTr("SIGN IN")
                        enabled: !_fleetControlLte.busy && usernameField.text.length > 0 && passwordField.text.length > 0
                        onClicked: _fleetControlLte.login(usernameField.text, passwordField.text)
                    }
                }
            }

            RowLayout {
                visible: _fleetControlLte.authenticated
                Layout.fillWidth: true; spacing: 9
                Button { text: qsTr("REFRESH"); enabled: !_fleetControlLte.busy; onClicked: _fleetControlLte.refreshAccount() }
                Item { Layout.fillWidth: true }
                Button { text: qsTr("SIGN OUT"); enabled: !_fleetControlLte.busy; onClicked: _fleetControlLte.logout() }
            }

            GridLayout {
                visible: _fleetControlLte.authenticated
                Layout.fillWidth: true
                columns: root.width >= 800 ? 2 : 1
                columnSpacing: 9; rowSpacing: 9

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 164
                    radius: 9; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 11; spacing: 7
                        Text { text: qsTr("1  CRAFT IDENTITY"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: qsTr("Choose an existing craft or create a new server identity. LTE hardware is detected separately on Air."); color: settings_form.secondaryText; font.pixelSize: 9; wrapMode: Text.WordWrap }
                        ComboBox { id: craftBox; Layout.fillWidth: true; model: _fleetControlLte.crafts; textRole: "label"; currentIndex: model.length ? 0 : -1; onActivated: root.syncStreamControls() }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: craftNameField; Layout.fillWidth: true; placeholderText: qsTr("New craft name"); maximumLength: 60; selectByMouse: true }
                            Button { text: qsTr("CREATE ID"); enabled: !_fleetControlLte.busy && craftNameField.text.trim().length >= 2; onClicked: { _fleetControlLte.createCraft(craftNameField.text); craftNameField.clear() } }
                        }
                        Text { Layout.fillWidth: true; text: root.selectedCraft ? root.selectedCraft.id : qsTr("No craft identity yet"); color: settings_form.accentColor; font.pixelSize: 8; elide: Text.ElideMiddle }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 164
                    radius: 9; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 11; spacing: 7
                        Text { text: qsTr("2  LICENSE"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { Layout.fillWidth: true; text: qsTr("Verify the signed license, then bind it permanently to the selected craft."); color: settings_form.secondaryText; font.pixelSize: 9; wrapMode: Text.WordWrap }
                        ComboBox { id: licenseBox; Layout.fillWidth: true; model: _fleetControlLte.licenses; textRole: "label"; currentIndex: model.length ? 0 : -1 }
                        RowLayout {
                            Layout.fillWidth: true
                            Button { Layout.fillWidth: true; text: qsTr("VERIFY"); enabled: !_fleetControlLte.busy && root.selectedLicense; onClicked: _fleetControlLte.verifyLicense(root.selectedLicense.id) }
                            Button { Layout.fillWidth: true; text: qsTr("BIND TO CRAFT"); enabled: !_fleetControlLte.busy && root.selectedLicense && root.selectedCraft && !root.selectedLicense.craftId; onClicked: _fleetControlLte.bindLicense(root.selectedLicense.id, root.selectedCraft.id) }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.selectedLicense && root.selectedLicense.craftId
                                  ? qsTr("Bound to %1").arg(root.selectedLicense.craftId)
                                  : (_fleetControlLte.licenseVerification || qsTr("Not verified in this session"))
                            color: _fleetControlLte.licenseValid ? settings_form.goodColor : settings_form.secondaryText
                            font.pixelSize: 8; elide: Text.ElideMiddle
                        }
                    }
                }
            }

            Rectangle {
                visible: _fleetControlLte.authenticated
                Layout.fillWidth: true
                Layout.preferredHeight: 202
                radius: 9; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 11; spacing: 7
                    Text { text: qsTr("3  AIR STREAMING"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedCraft && root.selectedCraft.licenseId
                              ? qsTr("Only OpenHD Air uploads these selected streams. Ground never duplicates them.")
                              : qsTr("Bind a valid license to this craft before enabling streams.")
                        color: settings_form.secondaryText; font.pixelSize: 9; wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 16
                        CheckBox { id: mavlinkSwitch; Layout.fillWidth: true; text: qsTr("MAVLink"); enabled: root.selectedCraft && root.selectedCraft.licenseId && !_fleetControlLte.busy }
                        CheckBox { id: videoOneSwitch; Layout.fillWidth: true; text: qsTr("Video 1"); enabled: root.selectedCraft && root.selectedCraft.licenseId && !_fleetControlLte.busy }
                        CheckBox { id: videoTwoSwitch; Layout.fillWidth: true; text: qsTr("Video 2"); enabled: root.selectedCraft && root.selectedCraft.licenseId && !_fleetControlLte.busy }
                        Button {
                            Layout.preferredWidth: 150; text: qsTr("SAVE STREAMS")
                            enabled: root.selectedCraft && root.selectedCraft.licenseId && !_fleetControlLte.busy
                            onClicked: _fleetControlLte.saveStreams(root.selectedCraft.id, mavlinkSwitch.checked, videoOneSwitch.checked, videoTwoSwitch.checked)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 16
                        CheckBox {
                            id: encryptVideoOne
                            Layout.fillWidth: true; text: qsTr("Encrypt Video 1")
                            enabled: _fleetControlLte.certificateInstalled &&
                                     _airCameraSettingsModel.param_int_exists("HIGH_ENCRYPTION")
                            checked: _airCameraSettingsModel.param_int_exists("HIGH_ENCRYPTION") &&
                                     _airCameraSettingsModel.get_cached_int("HIGH_ENCRYPTION") === 1
                            onClicked: _airCameraSettingsModel.try_set_param_int_async("HIGH_ENCRYPTION", checked ? 1 : 0, true)
                        }
                        CheckBox {
                            id: encryptVideoTwo
                            Layout.fillWidth: true; text: qsTr("Encrypt Video 2")
                            enabled: _fleetControlLte.certificateInstalled &&
                                     _airCameraSettingsModel2.param_int_exists("HIGH_ENCRYPTION")
                            checked: _airCameraSettingsModel2.param_int_exists("HIGH_ENCRYPTION") &&
                                     _airCameraSettingsModel2.get_cached_int("HIGH_ENCRYPTION") === 1
                            onClicked: _airCameraSettingsModel2.try_set_param_int_async("HIGH_ENCRYPTION", checked ? 1 : 0, true)
                        }
                        Button {
                            Layout.preferredWidth: 150; text: qsTr("RENEW CERTIFICATE")
                            enabled: root.selectedCraftLicense() && !_fleetControlLte.busy
                            onClicked: _fleetControlLte.requestVideoCertificate(root.selectedCraftLicense().id)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: _fleetControlLte.certificateInstalled
                              ? qsTr("30-day certificate active until %1. Encryption is fail-closed when requested.").arg(_fleetControlLte.certificateExpiresAt)
                              : _fleetControlLte.certificateStatus
                        color: _fleetControlLte.certificateInstalled ? settings_form.goodColor : settings_form.secondaryText
                        font.pixelSize: 8; elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 8
                color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                RowLayout {
                    anchors.fill: parent; anchors.margins: 9; spacing: 8
                    BusyIndicator { running: _fleetControlLte.busy; visible: running; width: 22; height: 22 }
                    Text { Layout.fillWidth: true; text: _fleetControlLte.statusText; color: _fleetControlLte.licenseValid ? settings_form.goodColor : settings_form.secondaryText; font.pixelSize: 9; elide: Text.ElideRight }
                    Rectangle { width: 7; height: 7; radius: 4; color: _fleetControlLte.authenticated ? settings_form.goodColor : "#f0a43c" }
                }
            }
        }
    }
}
