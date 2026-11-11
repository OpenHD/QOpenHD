import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Button {
    id: control
    objectName: "settingsBackButton"
    property bool darkMode: true
    implicitWidth: 64
    implicitHeight: 76
    padding: 6
    leftPadding: 6; rightPadding: 6; topPadding: 6; bottomPadding: 6
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    hoverEnabled: true
    activeFocusOnTab: true
    text: ""
    Accessible.name: qsTr("Back to video")

    background: Rectangle {
        radius: 8
        color: control.down ? "#1477d4" : (control.darkMode ? "#153c53" : "#dcecf8")
        border.width: control.activeFocus ? 2 : 1
        border.color: control.hovered || control.activeFocus ? "#08a5df" : (control.darkMode ? "#41677e" : "#829fb7")
    }
    contentItem: Item {
        Image {
            objectName: "settingsBackLogo"
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: control.darkMode ? "settings-logo-dark.png" : "settings-logo-light.png"
            fillMode: Image.PreserveAspectFit
            sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
            sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
            smooth: true
        }
    }
}
