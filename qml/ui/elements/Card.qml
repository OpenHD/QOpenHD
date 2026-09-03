import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

Item {
    id: card

    property alias cardName: cardHeader.text
    property Item cardBody: Item {}
    property Item cardFooter: Item {}
    property bool hasFooter: false

    property bool hasHeader: true
    property bool hasHeaderImage: false

    property int cardRadius: 14
    property color cardNameColor: _theme.primaryText
    property color borderColor: _theme.lineColor
    property color cardBackgroundColor: _theme.panelBackgroundRaised
    property color cardFooterColor: _theme.panelBackground
    readonly property bool dangerTitle: cardNameColor === "#ff0000" || cardNameColor === "red"

    property bool m_style_error: false

    // Resolve settings_form from the parent tree; fall back to built-in
    // defaults when Card is used outside ConfigPopup (e.g. message boxes).
    readonly property var _sf: {
        try { return settings_form } catch(e) { return null }
    }
    QtObject {
        id: _fallback
        readonly property bool darkMode: true
        readonly property color primaryText: "#f2f6fb"
        readonly property color secondaryText: "#aebdcb"
        readonly property color lineColor: "#26394c"
        readonly property color panelBackground: "#102235"
        readonly property color panelBackgroundRaised: "#15283b"
        readonly property color accentColor: "#278cff"
        readonly property color errorColor: "#ff4e5d"
    }
    readonly property var _theme: _sf ? _sf : _fallback

    Material.theme: _theme.darkMode ? Material.Dark : Material.Light
    Material.accent: _theme.accentColor
    Material.foreground: _theme.primaryText
    Material.background: _theme.panelBackgroundRaised

    Rectangle {
        id: background
        radius: cardRadius
        //color: m_style_error ? "red" : "white"
        color: cardBackgroundColor
        anchors.fill: parent
        border.width: 1
        border.color: borderColor
        //border.width: m_style_error ? 10: 1
        //border.color: m_style_error ? "red" : borderColor
    }

    Item {
        id: cardID
        width: parent.width
        height: hasHeader ? 48 : 0
        visible: hasHeader

        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: cardHeaderImage
            width: hasHeaderImage ? 24 : 0
            height: hasHeaderImage ? 24 : 0
            visible: hasHeaderImage
            color: _theme.darkMode ? "#ffbf69" : "#a85b00"
            font.bold: true
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            anchors.top: parent.top
            text: "\uf071"
            font.family: "Font Awesome 5 Free"
            leftPadding: 14
        }

        Text {
            id: cardHeader
            width: parent.width
            height: parent.height
            color: dangerTitle ? (_theme.darkMode ? "#ff6577" : "#c6283e") : _theme.primaryText
            font.bold: true
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.top: parent.top
            anchors.left: cardHeaderImage.right
            leftPadding: hasHeaderImage ? 14 : 18
        }
    }

    Item {
        id: cardBodyHolder
        anchors.top: cardID.bottom
        anchors.topMargin: 2
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: hasFooter ? cardFooterInner.top : parent.bottom
        anchors.bottomMargin: 10
        //anchors.bottom: cardFooterInner.top
        //anchors.bottomMargin: 3
        clip: true
        children: cardBody
    }

    Rectangle{
        anchors.fill: background
        color: "lightgrey"
        opacity: 0.6
        visible: m_style_error
    }

    Rectangle {
        id: cardFooterInner
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        children: cardFooter
        visible: hasFooter
        height: 62
        color: cardFooterColor
        border.width: 0
        Rectangle { anchors.top: parent ? parent.top : undefined; width: parent ? parent.width : 0; height: 1; color: card.borderColor }
    }

    /*Rectangle{
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 3
        radius: 6
        visible: m_style_error
    }*/
    /*Rectangle{
        anchors.fill: cardBodyHolder
        color: "gray"
        opacity: 0.8
        visible: m_style_error
    }*/
}
