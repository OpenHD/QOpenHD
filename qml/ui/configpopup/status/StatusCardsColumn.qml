import QtQuick 2.12
import QtQuick.Layouts 1.12

GridLayout {
    id: cards
    signal craftDetailsRequested()
    signal unitDetailsRequested(int systemType)
    property real availableHeight: Number.POSITIVE_INFINITY
    readonly property real rowHeightBudget: columns === 3 ? Math.max(294, availableHeight) : Number.POSITIVE_INFINITY
    readonly property int responsiveColumns: width >= 744 ? 3 : (width >= 560 ? 2 : 1)
    readonly property real overviewScale: Math.max(0.55, Math.min((width - (columns - 1) * columnSpacing) / columns / 490, rowHeightBudget / 535))
    columns: responsiveColumns
    columnSpacing: width < 840 ? 12 : 22
    rowSpacing: columnSpacing

    function actionButtons() {
        return groundCard.actionButtons().concat(airCard.actionButtons()).concat(fcCard.actionButtons())
    }

    StatusCard {
        id: groundCard
        onDetailsRequested: cards.unitDetailsRequested(0)
        visible: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        maximumCardHeight: cards.rowHeightBudget
        cardScale: cards.overviewScale
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignTop
        title: qsTr("Ground station")
        iconText: "\uf519"
        iconColor: "#43a1ff"
        alive: _ohdSystemGround.is_alive
        systemType: 0
        bodyComponent: Component { StatusCardBodyOpenHD { m_is_ground: true } }
    }
    StatusCard {
        id: airCard
        onDetailsRequested: cards.unitDetailsRequested(1)
        visible: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        maximumCardHeight: cards.rowHeightBudget
        cardScale: cards.overviewScale
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignTop
        title: qsTr("Air unit")
        iconText: "\uf1d8"
        iconColor: "#38a5ff"
        alive: _ohdSystemAir.is_alive
        systemType: 1
        bodyComponent: Component { StatusCardBodyOpenHD { m_is_ground: false } }
    }
    StatusCard {
        id: fcCard
        objectName: "statusCraftCard"
        onDetailsRequested: cards.craftDetailsRequested()
        visible: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        maximumCardHeight: cards.rowHeightBudget
        cardScale: cards.overviewScale
        Layout.preferredHeight: implicitHeight
        Layout.alignment: Qt.AlignTop
        title: qsTr("Flight controller")
        iconText: "\uf2db"
        alive: _fcMavlinkSystem.telemetry_active
        actionsAvailable: false // No writable FC commands are inferred from a firmware label.
        systemType: 2
        bodyComponent: Component { StatusCardBodyFC {} }
    }

}
