import QtQuick 2.0

Item{
    property string m_left_text: ""
    property string m_right_text: ""
    width: parent.width
    height: 20
    property bool m_use_red: false

    Text{
        id: left
        width: 80
        height: 20
        text: qsTr(m_left_text)
        font.pixelSize: 14
        color: m_use_red ? "red" : "#ff05ff00"
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignCenter
    }
    Text{
        width: parent.width-left.width
        height: 20
        anchors.left: left.right
        text: qsTr(m_right_text)
        font.pixelSize: 14
        color: m_use_red ? "red" : "#ff05ff00"
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignCenter
    }
}
