import QtQuick 2.12
import QtQuick.Layouts 1.12

GridLayout {
    id: cards
    columns: width >= 680 ? 3 : (width >= 440 ? 2 : 1)
    columnSpacing: width < 800 ? 8 : 14
    rowSpacing: columnSpacing
    implicitHeight: Math.ceil(3 / columns) * 319 + (Math.ceil(3 / columns) - 1) * rowSpacing

    function actionButtons() {
        return groundCard.actionButtons().concat(airCard.actionButtons()).concat(fcCard.actionButtons())
    }

    StatusCard {
        id: groundCard
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
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        title: qsTr("Flight controller")
        iconText: "\uf2db"
        iconColor: "#a486ff"
        alive: _fcMavlinkSystem.is_alive
        systemType: 2
        bodyComponent: Component { StatusCardBodyFC {} }
    }
}
