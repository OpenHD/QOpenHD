import QtQuick 2.12

// This UI Element shows log messages coming from the c++
// Log model
Item {

    ListModel {
        id: modelX
        ListElement {
            serverity: 0 // Severity of this log message.
            log_tag: "AIR_PI" // string that tells where the message comes from (Ground, Air, ...)
            log_text: "SomeText" // the actual log message
        }
    }

    ListView {
        id: messageList

        //model: sortModel
        model: modelX

        anchors.fill: parent

        topMargin: 12
        bottomMargin: 12

        delegate: messageDelegate

        Component.onCompleted: {
            messageList.positionViewAtEnd()
        }
    }


    Component {
        id: messageDelegate

        Item {
            height: 16

            Text {
                id: log_tag_text_view
                text: log_tag
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 56
                color: {
                    if (severity == 0) {
                        return "#fa0000";
                    } else if (severity == 1) {
                        return "#fa0000";
                    } else if (severity == 2) {
                        return "#fa0000";
                    } else if (severity == 3) {
                        return "#fa0000";
                    } else if (severity == 4) {
                        return "#fffa00";
                    } else if (severity == 5) {
                        return "#00ea00";
                    } else if (severity == 6) {
                        return "#00ea00";
                    } else if (severity == 7) {
                        return "#0000ea";
                    }
                    return "white";
                }
                font.bold: true
            }
            Text {
                text: log_text
                font.pixelSize: 12
                anchors.left:  log_tag_text_view.right
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                color: "red"
            }
        }
    }
}

