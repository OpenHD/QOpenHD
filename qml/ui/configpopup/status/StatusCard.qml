import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
    id: card
    implicitHeight: 319
    Layout.minimumWidth: 170

    property string title: ""
    property string iconText: "\uf1eb"
    property color iconColor: settings_form.accentColor
    property bool alive: false
    property int systemType: 0 // 0 ground, 1 air, 2 flight controller
    property Component bodyComponent

    function actionButtons() { return [rebootButton, shutdownButton, calibrationButton] }
    function showPowerActions() { return alive }
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
        height: 204
        sourceComponent: card.bodyComponent
    }

    Rectangle {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: card.width < 260 ? 10 : 16
        anchors.rightMargin: card.width < 260 ? 10 : 16
        anchors.top: bodyLoader.bottom
        anchors.topMargin: 8
        height: 38
        visible: card.showPowerActions()
        radius: 9
        color: "transparent"
        border.color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 5
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
