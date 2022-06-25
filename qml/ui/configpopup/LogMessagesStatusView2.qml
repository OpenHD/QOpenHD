import QtQuick 2.0
import QtQuick.Controls 2.12

//ScrollView {
//    anchors.fill: parent
//    width: parent.width
//    height: parent.height

ListView {
    width: parent.width
    height: parent.height
    model: _logMessagesModel
    delegate: Rectangle {
        color: Qt.rgba(0.3,0.3,0.3)
        height: childrenRect.height
        width: parent.width

        Text {
            id: tagView
            text: model.tag
            color: model.severity_color
            anchors { left:parent.left }
        }
        Text {
            text: model.message
            anchors { left:tagView.right; verticalCenter: tagView.verticalCenter; leftMargin: 5 }
        }
    }
}
//}
