import QtQuick 2.12
import QtQuick.Layouts 1.12

Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 32

    property string m_text: "FILL ME"

    Rectangle{
        width: parent.width
        height: 2
        color: "black"
        anchors.bottom: parent.bottom
    }

    Text{
        text: qsTr(m_text)
        font.weight: Font.Bold
        font.pixelSize: 13
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

}
