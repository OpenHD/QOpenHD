import QtQuick 2.12
import QtQuick.Controls 2.12
import "MenuTypography.js" as MenuTypography

Button {
    id: control
    objectName: "settingsBackButton"
    property bool darkMode: true
    implicitWidth: 64
    implicitHeight: 76
    padding: 10
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    hoverEnabled: true
    activeFocusOnTab: true
    text: qsTr("Back")
    Accessible.name: qsTr("Back to video")
    ToolTip.visible: hovered
    ToolTip.text: qsTr("Back to video")
    readonly property color foreground: darkMode ? "#f3f7fb" : "#163d62"

    background: Rectangle {
        radius: 8
        color: control.down ? "#1477d4" : (control.darkMode ? "#153c53" : "#dcecf8")
        border.width: control.activeFocus ? 2 : 1
        border.color: control.hovered || control.activeFocus ? "#08a5df" : (control.darkMode ? "#41677e" : "#829fb7")
    }
    contentItem: Column {
        spacing: 6
        // Scene-graph geometry stays crisp on embedded/software renderers and
        // does not depend on Canvas framebuffer support or an icon font.
        Item {
            width: 32; height: 28
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { x: 3; y: 12; width: 28; height: 4; radius: 2; color: control.foreground }
            Rectangle { x: 3; y: 12; width: 17; height: 4; radius: 2; rotation: -45; transformOrigin: Item.Left; color: control.foreground }
            Rectangle { x: 3; y: 12; width: 17; height: 4; radius: 2; rotation: 45; transformOrigin: Item.Left; color: control.foreground }
        }
        Text {
            width: parent.width
            text: control.text
            horizontalAlignment: Text.AlignHCenter
            color: control.foreground
            font.family: MenuTypography.family
            font.pixelSize: MenuTypography.body
            font.bold: true
        }
    }
}
