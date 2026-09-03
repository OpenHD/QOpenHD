import QtQuick 2.12
import QtQuick.Layouts 1.12

GridLayout {
    id: cards
    readonly property int onlineCount: (_ohdSystemGround.is_alive ? 1 : 0)
                                       + (_ohdSystemAir.is_alive ? 1 : 0)
                                       + (_fcMavlinkSystem.is_alive ? 1 : 0)
    readonly property int responsiveColumns: width >= 680 ? 3 : (width >= 440 ? 2 : 1)
    columns: Math.max(1, Math.min(onlineCount, responsiveColumns))
    columnSpacing: width < 800 ? 8 : 14
    rowSpacing: columnSpacing
    implicitHeight: onlineCount > 0
                    ? Math.ceil(onlineCount / columns) * 319
                      + (Math.ceil(onlineCount / columns) - 1) * rowSpacing
                    : 120

    function actionButtons() {
        return groundCard.actionButtons().concat(airCard.actionButtons()).concat(fcCard.actionButtons())
    }

    StatusCard {
        id: groundCard
        visible: alive
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        title: qsTr("Ground station")
        iconText: "\uf519"
        iconColor: "#43a1ff"
        alive: _ohdSystemGround.is_alive
        systemType: 0
        bodyComponent: Component { StatusCardBodyOpenHD { m_is_ground: true } }
    }
    StatusCard {
        id: airCard
        visible: alive
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        title: qsTr("Air unit")
        iconText: "\uf1d8"
        iconColor: "#6fb2ff"
        alive: _ohdSystemAir.is_alive
        systemType: 1
        bodyComponent: Component { StatusCardBodyOpenHD { m_is_ground: false } }
    }
    StatusCard {
        id: fcCard
        visible: alive
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        title: qsTr("Flight controller")
        iconText: "\uf2db"
        iconColor: "#a486ff"
        alive: _fcMavlinkSystem.is_alive
        systemType: 2
        bodyComponent: Component { StatusCardBodyFC {} }
    }

    Rectangle {
        visible: cards.onlineCount === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        radius: 12
        color: settings_form.panelBackground
        border.color: settings_form.lineColor
        Column {
            anchors.centerIn: parent
            spacing: 7
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\uf1eb"
                color: settings_form.secondaryText
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 22
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Waiting for systems")
                color: settings_form.primaryText
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
