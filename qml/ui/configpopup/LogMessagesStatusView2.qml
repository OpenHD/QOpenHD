import QtQuick 2.0

ListView {
    width: 300
    height: 200
    model: _logMessagesModel
    delegate: Rectangle {
        color: Qt.rgba(0.9,0.9,0.9)
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
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onDoubleClicked: {
                if (mouse.button === Qt.LeftButton) {
                    _myModel.duplicateData(model.index);
                } else if (mouse.button === Qt.RightButton) {
                    _myModel.removeData(model.index);
                }
            }
        }
    }
}
