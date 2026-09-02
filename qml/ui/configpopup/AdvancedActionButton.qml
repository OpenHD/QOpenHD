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

    background: Rectangle {
        radius: 8
        color: control.primary ? settings_form.accentColor
                               : (control.down || control.hovered
                                  ? settings_form.panelBackgroundRaised
                                  : settings_form.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? settings_form.accentColor
                                         : (control.destructive ? settings_form.errorColor : settings_form.lineColor)
    }
    contentItem: Row {
        id: contentRow
        spacing: 8
        anchors.centerIn: parent
        Text {
            visible: control.iconText.length > 0
            text: control.iconText
            color: control.primary ? "white" : (control.destructive ? settings_form.errorColor : settings_form.primaryText)
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
        }
        Text {
            text: control.text
            color: control.primary ? "white" : (control.destructive ? settings_form.errorColor : settings_form.primaryText)
            font.pixelSize: 13
            font.bold: true
        }
    }
}
