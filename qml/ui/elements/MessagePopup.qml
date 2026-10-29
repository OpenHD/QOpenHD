import QtQuick 2.12
import QtQuick.Controls 2.12
import "../configpopup"
import "../configpopup/MenuTypography.js" as MenuTypography

AdvancedDialog {
    id: control
    property string message: ""
    property bool showOkayButton: true
    width: Math.min(420, parent ? parent.width - 32 : 420)
    height: Math.min(implicitHeight, parent ? parent.height - 32 : implicitHeight)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    z: 100
    standardButtons: showOkayButton ? Dialog.Ok : Dialog.NoButton
    contentItem: ScrollView {
        implicitHeight: Math.min(messageText.implicitHeight + 8,
                                 Math.max(48, control.parent ? control.parent.height - 210 : 280))
        clip: true
        contentWidth: availableWidth
        Text {
            id: messageText
            objectName: "messageText"
            width: parent.width
            text: control.message
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: "#edf4fa"
            font.family: MenuTypography.family
            font.pixelSize: MenuTypography.body
        }
    }
}
