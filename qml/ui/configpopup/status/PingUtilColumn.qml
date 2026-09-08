import QtQuick 2.12
import QtQuick.Controls 2.12

import OpenHD 1.0

Item {
    id: root

    implicitHeight: width < 650 ? 118 : 75

    function actionButtons() { return [pingButton, autoPingSwitch] }

    Timer {
        id: autopingTimer
        running: false
        interval: 1000
        repeat: true
        onTriggered: {
            _mavlinkTelemetry.ping_all_systems()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 17
        color: settings_form.panelBackground
        border.color: settings_form.lineColor
        border.width: 1
    }

    Flow {
        id: actionFlow
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 16
        spacing: 10
        height: childrenRect.height

        Button {
            id: pingButton
            width: Math.min(176, Math.max(150, actionFlow.width * 0.25)); height: 43
            text: "\uf140  " + qsTr("PING ALL SYSTEMS")
            font.family: "Font Awesome 5 Free"; font.pixelSize: 11
            onClicked: _mavlinkTelemetry.ping_all_systems()
            background: Rectangle { radius: 10; color: parent.hovered ? "#20384f" : settings_form.panelBackgroundRaised; border.color: parent.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: parent.activeFocus ? 2 : 1 }
            contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Switch {
            id: autoPingSwitch
            width: 132; height: 43
            text: qsTr("Auto-ping")
            onToggled: autopingTimer.running = checked
            contentItem: Text { leftPadding: autoPingSwitch.indicator.width + autoPingSwitch.spacing; text: autoPingSwitch.text; color: settings_form.secondaryText; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
        }
    }
}
