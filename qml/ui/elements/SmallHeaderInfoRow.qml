import QtQuick 2.12

Item {
    width: parent.width
    height: 40

    property string m_text: "FILL ME"
    property string m_info_text: "FILL ME"

    Text{
        anchors.fill: parent
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignLeft
        text: m_text
        font.pixelSize: 18
        font.bold: true
        color: "white"
    }
    ButtonIconInfo{
        anchors.right: parent.right
        width: parent.height
        height: parent.height
        onClicked: {
            _messageBoxInstance.set_text_and_show(m_info_text)
        }
    }
}
