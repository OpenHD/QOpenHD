import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Dialog {
    id: control
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 18

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    background: Rectangle {
        radius: 14
        color: settings_form.panelBackgroundRaised
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? settings_form.accentColor : settings_form.lineColor
    }
    Overlay.modal: Rectangle { color: settings_form.darkMode ? "#99030d17" : "#660b1b2d" }
}
