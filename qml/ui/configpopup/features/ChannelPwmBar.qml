import QtQuick 2.12

Item {
    id: root
    property int value: -1
    readonly property bool valid: value >= 800 && value <= 2200
    readonly property real fraction: Math.max(0, Math.min(1, (value-900)/1200))
    implicitWidth: 140
    implicitHeight: 20
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 12; radius: 6
        color: settings_form.darkMode ? "#344c5d" : "#d6e3ed"
        Rectangle { width: root.valid ? parent.width*root.fraction : 0; height: parent.height; radius: 6; color: "#12b5ed" }
    }
    Rectangle {
        visible: root.valid
        x: Math.max(0, Math.min(parent.width-width, root.fraction*parent.width-width/2))
        anchors.verticalCenter: parent.verticalCenter
        width: 9; height: 18; radius: 3
        color: "#effaff"; border.color: "#9adfff"
    }
}
