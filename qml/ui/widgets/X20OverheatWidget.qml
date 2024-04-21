import QtQuick 2.12

Item {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30
    width: 100
    height: 30

    Text{
        anchors.fill: parent
        text: "LOOOL \ue040"
        font.pixelSize: 15
        color: "red"
    }
}
