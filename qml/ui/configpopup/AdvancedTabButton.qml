import QtQuick 2.12
import QtQuick.Controls 2.12

TabButton {
    id: control
    implicitHeight: 34
    implicitWidth: Math.max(105, label.implicitWidth + 28)
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0

    contentItem: Text {
        id: label
        text: control.text
        color: control.checked ? "white" : settings_form.primaryText
        font.pixelSize: 12
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 7
        color: control.checked ? settings_form.accentColor
                               : (control.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? settings_form.accentColor : settings_form.lineColor
    }
}
