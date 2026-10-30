import QtQuick 2.12
import QtQuick.Controls 2.12

Switch {
    id: control
    implicitWidth: 46
    implicitHeight: 32
    padding: 0
    indicator: Rectangle {
        x: (control.width-width)/2
        y: (control.height-height)/2
        width: 42; height: 24; radius: 12
        color: control.checked ? settings_form.accentColor : "#465766"
        border.color: control.activeFocus ? "#b4e7ff" : "transparent"
        border.width: control.activeFocus ? 2 : 0
        Rectangle {
            width: 20; height: 20; radius: 10
            x: control.checked ? parent.width-width-2 : 2
            y: 2
            color: control.checked ? "#edf9ff" : "#b8c6d2"
            Behavior on x { NumberAnimation { duration: 100 } }
        }
    }
    background: Item {}
    contentItem: Item {}
}
