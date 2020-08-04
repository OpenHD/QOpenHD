import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12



Item {
    id: card

    property alias cardName: cardHeader.text
    property Item cardBody: Item {}
    property Item cardFooter: Item {}
    property bool hasFooter: false

    property bool hasHeader: true
    property int cardRadius: 6
    property color cardNameColor: "#33aaff"

    Rectangle {
        id: innerCard
        radius: cardRadius
        color: "white"
        anchors.fill: parent
    }

    DropShadow {
        cached: true
        anchors.fill: innerCard
        horizontalOffset: 0
        verticalOffset: 1
        radius: cardRadius
        samples: 17
        color: "#6a000000"
        source: innerCard
    }

    Item {
        id: cardID
        width: parent.width
        height: hasHeader ? 32 : 0
        visible: hasHeader

        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: cardHeader
            width: parent.width
            height: 24
            color: cardNameColor
            font.bold: true
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.top: parent.top
            leftPadding: 12
            topPadding: 3
        }
    }

    Item {
        anchors.top: cardID.bottom
        anchors.topMargin: 6
        width: parent.width
        children: cardBody
    }

    Rectangle {
        color: "#4c000000"
        width: parent.width
        height: 1
        anchors.bottom: cardFooterInner.top
        anchors.bottomMargin: 0
        visible: hasFooter
    }

    Rectangle {
        id: cardFooterInner
        anchors.bottom: parent.bottom
        width: parent.width
        children: cardFooter
        visible: hasFooter
        height: 64
        color: "#f6f6f6"
    }
}
