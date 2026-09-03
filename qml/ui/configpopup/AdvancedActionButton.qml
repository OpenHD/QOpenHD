import QtQuick 2.12
import QtQuick.Controls 2.12

Button {
    id: control
    property bool primary: false
    property bool destructive: false
    property string iconText: ""
    implicitHeight: 38
    implicitWidth: Math.max(112, contentRow.implicitWidth + 30)
    hoverEnabled: true
    activeFocusOnTab: true
    font.capitalization: Font.MixedCase

    readonly property var _sf: { try { return settings_form } catch(e) { return null } }
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

    background: Rectangle {
        radius: 8
        color: control.primary ? _theme.accentColor
                               : (control.down || control.hovered
                                  ? _theme.panelBackgroundRaised
                                  : _theme.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? _theme.accentColor
                                         : (control.destructive ? _theme.errorColor : _theme.lineColor)
    }
    contentItem: Row {
        id: contentRow
        spacing: 8
        anchors.centerIn: parent
        Text {
            visible: control.iconText.length > 0
            text: control.iconText
            color: control.primary ? "white" : (control.destructive ? _theme.errorColor : _theme.primaryText)
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
        }
        Text {
            text: control.text
            color: control.primary ? "white" : (control.destructive ? _theme.errorColor : _theme.primaryText)
            font.pixelSize: 13
            font.bold: true
        }
    }
}
