import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
    id: card
    implicitHeight: footer.y + (footer.visible ? footer.height : 0) + 16
    Layout.minimumWidth: 170

    property string title: ""
    property string iconText: "\uf1eb"
    property color iconColor: settings_form.accentColor
    property bool alive: false
    property bool actionsAvailable: alive
    property int systemType: 0 // 0 ground, 1 air, 2 flight controller
    readonly property var unitModel: systemType === 0 ? _ohdSystemGround : (systemType === 1 ? _ohdSystemAir : null)
    readonly property var unitSettings: systemType === 0 ? _ohdSystemGroundSettings : (systemType === 1 ? _ohdSystemAirSettingsModel : null)
    property Component bodyComponent
    signal detailsRequested()

    function actionButtons() { return [hotspotButton, linkRatesButton, detailsButton, rebootButton, shutdownButton, calibrationButton] }
    function showPowerActions() { return actionsAvailable }
    function handleNavigation(event) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
            statusPanel.moveFocus(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            statusPanel.moveFocus(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
            settings_form.side_bar_regain_focus()
            event.accepted = true
        }
    }
    function openWarning() {
        if (systemType === 0) {
            dialoqueNotAlive.open_ground()
        } else if (systemType === 1) {
            if (_ohdSystemGround.is_alive)
                dialoqueNotAlive.open_air()
            else
                _messageBoxInstance.set_text_and_show(qsTr("Please make sure your ground unit is alive first."))
        } else {
            var message = !(_ohdSystemGround.is_alive && _ohdSystemAir.is_alive)
                    ? qsTr("Please make sure your air and ground unit are alive first.")
                    : qsTr("No flight controller detected. Check the UART wiring, baud rate and FC_UART_CONN setting.")
            _messageBoxInstance.set_text_and_show(message)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 17
        color: settings_form.panelBackground
        border.color: settings_form.lineColor
        border.width: 1
    }

    RowLayout {
        id: header
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: card.width < 260 ? 10 : 19
        anchors.rightMargin: card.width < 260 ? 10 : 19
        anchors.topMargin: 11
        height: 34
        spacing: card.width < 260 ? 6 : 11
        Rectangle {
            Layout.preferredWidth: card.width < 260 ? 31 : 36
            Layout.preferredHeight: Layout.preferredWidth
            radius: 8
            color: Qt.rgba(card.iconColor.r, card.iconColor.g, card.iconColor.b, 0.22)
            Text { anchors.centerIn: parent; text: card.iconText; color: card.iconColor; font.family: "Font Awesome 5 Free"; font.pixelSize: card.width < 260 ? 15 : 17 }
        }
        Text {
            Layout.fillWidth: true
            text: card.title.toUpperCase()
            color: settings_form.primaryText
            font.pixelSize: card.width < 260 ? 10 : 13
            font.bold: true
            elide: Text.ElideRight
        }
        Rectangle {
            Layout.preferredWidth: statusText.implicitWidth + (card.width < 260 ? 12 : 24)
            Layout.preferredHeight: 25
            radius: 8
            color: card.alive ? Qt.rgba(0.15, 0.75, 0.35, 0.10) : Qt.rgba(0.45, 0.50, 0.56, 0.10)
            border.color: card.alive ? Qt.rgba(0.2, 0.85, 0.4, 0.2) : settings_form.lineColor
            Text {
                id: statusText
                anchors.centerIn: parent
                text: card.alive ? qsTr("ONLINE") : qsTr("OFFLINE")
                color: card.alive ? settings_form.goodColor : settings_form.secondaryText
                font.pixelSize: card.width < 260 ? 8 : 10; font.bold: true
            }
        }
    }

    Loader {
        id: bodyLoader
        anchors.top: header.bottom; anchors.topMargin: 8
        anchors.left: parent.left; anchors.right: parent.right
        height: item ? item.implicitHeight : 0
        sourceComponent: card.bodyComponent
    }

    Rectangle {
        id: utilityActions
        objectName: "airUtilityStrip"
        radius: 9
        color: Qt.rgba(settings_form.accentColor.r, settings_form.accentColor.g, settings_form.accentColor.b, 0.16)
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: card.width < 260 ? 10 : 16
        anchors.rightMargin: card.width < 260 ? 10 : 16
        anchors.top: bodyLoader.bottom; anchors.topMargin: 8
        height: visible ? 38 : 0
        visible: card.systemType !== 2

        RowLayout {
            anchors.fill: parent
            spacing: 0
            Button {
                id: hotspotButton
                objectName: "wifiHotspotButton"
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.preferredWidth: 1; Layout.minimumWidth: 0
                visible: utilityActions.visible
                readonly property bool hotspotActive: card.alive && card.unitModel !== null
                                                     && card.unitModel.wifi_hotspot_state === 2
                text: qsTr("WiFi hotspot")
                Accessible.name: hotspotActive ? qsTr("WiFi hotspot active; deactivate hotspot")
                                              : qsTr("WiFi hotspot inactive; activate hotspot")
                font.pixelSize: card.width < 260 ? 9 : 11
                enabled: card.alive && card.unitSettings !== null && card.unitSettings.has_params_fetched
                         && card.unitSettings.param_int_exists("WIFI_HOTSPOT_E")
                onClicked: {
                    var active = card.unitModel.wifi_hotspot_state === 2
                    card.unitSettings.try_set_param_int_async("WIFI_HOTSPOT_E", active ? 1 : 2, true)
                }
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(hotspotButton)
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        clicked()
                        event.accepted = true
                    } else card.handleNavigation(event)
                }
                background: Rectangle { radius: 9; color: parent.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"; border.color: parent.activeFocus ? settings_form.accentColor : "transparent"; border.width: 2 }
                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: card.width < 260 ? 4 : 7
                        opacity: hotspotButton.enabled ? 1 : 0.5
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf1eb"; font.family: "Font Awesome 5 Free"; font.pixelSize: card.width < 260 ? 12 : 15; color: hotspotButton.hotspotActive ? settings_form.goodColor : settings_form.secondaryText }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: hotspotButton.text; font: hotspotButton.font; color: settings_form.accentColor }
                            Text { objectName: "hotspotStateText"; text: hotspotButton.hotspotActive ? qsTr("Active") : qsTr("Inactive"); font.pixelSize: card.width < 260 ? 8 : 9; color: hotspotButton.hotspotActive ? settings_form.goodColor : settings_form.secondaryText }
                        }
                    }
                }
            }
            Rectangle { visible: linkRatesButton.visible; Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: settings_form.accentColor; opacity: 0.45 }
            Button {
                id: linkRatesButton
                objectName: "setLinkRatesButton"
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.preferredWidth: 1; Layout.minimumWidth: 0
                visible: card.systemType === 1
                enabled: card.alive
                text: qsTr("Request FC Rates")
                font.pixelSize: card.width < 260 ? 9 : 11
                Accessible.name: qsTr("Reapply flight controller MAVLink message rates")
                onClicked: {
                    if (!settings.set_mavlink_message_rates) {
                        _qopenhd.show_toast(qsTr("Enable 'Set mavlink message rates' in Vehicle settings first"))
                        return
                    }
                    _mavlinkTelemetry.re_apply_rates()
                    _qopenhd.show_toast(qsTr("Flight controller link rate setup requested"))
                }
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(linkRatesButton)
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        clicked()
                        event.accepted = true
                    } else card.handleNavigation(event)
                }
                background: Rectangle { radius: 9; color: parent.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"; opacity: parent.enabled ? 1 : 0.5; border.color: parent.activeFocus ? settings_form.accentColor : "transparent"; border.width: 2 }
                contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; opacity: parent.enabled ? 1 : 0.5; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
    }

    Rectangle {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: card.width < 260 ? 10 : 16
        anchors.rightMargin: card.width < 260 ? 10 : 16
        anchors.top: utilityActions.visible ? utilityActions.bottom : bodyLoader.bottom
        anchors.topMargin: 8
        height: 38
        visible: card.systemType === 2 || card.showPowerActions()
        radius: 9
        color: "transparent"
        border.color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 5
            Button {
                id: detailsButton
                objectName: "craftDetailsButton"
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: card.systemType === 2
                enabled: visible
                text: qsTr("CRAFT DETAILS")
                font.pixelSize: card.width < 260 ? 9 : 11
                Accessible.name: qsTr("Open craft diagnostics")
                onClicked: card.detailsRequested()
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(detailsButton)
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        card.detailsRequested()
                        event.accepted = true
                    } else card.handleNavigation(event)
                }
                background: Rectangle {
                    radius: 8
                    color: parent.down ? "#0e64ba" : (parent.hovered ? "#217de0" : settings_form.accentColor)
                    border.color: parent.activeFocus ? "white" : "transparent"; border.width: 2
                }
                contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                id: rebootButton
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: card.showPowerActions()
                text: "\uf2f1  " + qsTr("REBOOT")
                font.family: "Font Awesome 5 Free"; font.pixelSize: card.width < 260 ? 9 : 11
                onClicked: open_power_action_dialoque(card.systemType, true)
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(rebootButton)
                Keys.onPressed: card.handleNavigation(event)
                background: Rectangle { radius: 8; color: parent.down ? "#0e64ba" : (parent.hovered ? "#217de0" : settings_form.accentColor); border.color: parent.activeFocus ? "white" : "transparent"; border.width: 2 }
                contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                id: shutdownButton
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: card.showPowerActions() && card.systemType !== 2
                text: "\uf011  " + qsTr("SHUTDOWN")
                font.family: "Font Awesome 5 Free"; font.pixelSize: card.width < 260 ? 9 : 11
                onClicked: open_power_action_dialoque(card.systemType, false)
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(shutdownButton)
                Keys.onPressed: card.handleNavigation(event)
                background: Rectangle { radius: 8; color: parent.hovered ? "#263b50" : "transparent"; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: parent.activeFocus ? 2 : 1 }
                contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                id: calibrationButton
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: card.showPowerActions() && card.systemType === 2
                text: "\uf14e  " + qsTr("CALIBRATE")
                font.family: "Font Awesome 5 Free"; font.pixelSize: card.width < 260 ? 8 : 11
                onClicked: {
                    var success = _fcMavlinkAction.send_command_compass_calibration()
                    _qopenhd.show_toast(success ? qsTr("Compass calibration requested") : qsTr("Compass calibration failed"))
                }
                onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(calibrationButton)
                Keys.onPressed: card.handleNavigation(event)
                background: Rectangle { radius: 8; color: parent.hovered ? "#263b50" : "transparent"; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: parent.activeFocus ? 2 : 1 }
                contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
    }

}
