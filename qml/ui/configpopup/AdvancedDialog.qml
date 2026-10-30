import "MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Dialog {
    id: control
    modal: true; dim: true; focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 20
    font.family: MenuTypography.family; font.pixelSize: MenuTypography.body
    Material.theme: Material.Dark
    Material.accent: "#12a8f3"
    Material.foreground: "#edf4fa"
    Material.background: "#041d2c"
    palette.window: "#041d2c"
    palette.base: "#06263a"
    palette.text: "#edf4fa"
    palette.windowText: "#edf4fa"
    palette.button: "#063552"
    palette.buttonText: "#edf4fa"
    palette.highlight: "#12a8f3"
    background: Rectangle { radius: 14; color: "#041d2c"; border.color: "#0089c4" }
    Overlay.modal: Rectangle { color: "#af000b12" }
    header: Item {
        implicitHeight: titleText.implicitHeight + 38
        Text {
            id: titleText
            anchors.left: parent.left; anchors.right: closeButton.left; anchors.top: parent.top
            anchors.leftMargin: 20; anchors.topMargin: 20
            text: control.title; color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.dialogTitle; font.bold: true; wrapMode: Text.WordWrap
        }
        ToolButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
            id: closeButton; anchors.right: parent.right; anchors.rightMargin: 12; y: 12; width: MenuTypography.controlHeight; height: MenuTypography.controlHeight; padding: 0
            Accessible.name: qsTr("Close dialog")
            onClicked: control.reject()
            background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? "#153c53" : "transparent" }
            contentItem: Text { text: "\uf00d"; font.family: "Font Awesome 5 Free"; color: "#edf4fa"; font.pixelSize: MenuTypography.sectionIcon; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
    footer: DialogButtonBox {
        standardButtons: control.standardButtons
        visible: count > 0
        padding: 16; spacing: 10
        background: Rectangle { color: "transparent" }
        delegate: AdvancedDialogButton {}
        onAccepted: control.accept()
        onRejected: control.reject()
    }
}
