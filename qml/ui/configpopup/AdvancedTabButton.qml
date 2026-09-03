import QtQuick 2.12
import QtQuick.Controls 2.12

TabButton {
    id: control
    property string iconText: ""
    implicitHeight: 34
    implicitWidth: Math.max(92, tabContent.implicitWidth + 26)
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0

    contentItem: Item {
        Row {
            id: tabContent
            anchors.centerIn: parent
            spacing: control.iconText.length > 0 ? 8 : 0

            Text {
                visible: control.iconText.length > 0
                width: visible ? 18 : 0
                height: Math.max(18, label.implicitHeight)
                text: control.iconText
                color: control.checked ? "white" : settings_form.secondaryText
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: label
                height: Math.max(18, implicitHeight)
                text: control.text
                color: control.checked ? "white" : settings_form.primaryText
                font.pixelSize: 11
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    background: Rectangle {
        radius: 7
        color: control.checked ? settings_form.accentColor
                               : (control.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? settings_form.accentColor : settings_form.lineColor
    }
}
