import "MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
Button {
    id: control
    property bool destructive: false
    implicitHeight: 42
    implicitWidth: Math.max(100, implicitContentWidth + 32)
    font.family: "Archivo"; font.pixelSize: MenuTypography.body
    contentItem: Text { text: control.text; font: control.font; color: control.enabled ? "#edf4fa" : "#7694a7"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    background: Rectangle { radius: 10; color: control.destructive ? (control.down ? "#701923" : "#8d1e2a") : control.down || control.hovered ? "#104b6a" : "#063552"; border.color: control.activeFocus ? "#38b9ff" : control.destructive ? "#b73946" : "#006997"; border.width: control.activeFocus ? 2 : 1 }
}
