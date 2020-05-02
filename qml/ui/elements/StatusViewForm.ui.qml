import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12



Item {
    ListView {
        id: messageList

        model: messageModel

        anchors.fill: parent

        topMargin: 12
        bottomMargin: 12

        delegate: messageDelegate

        Component.onCompleted: {
            messageList.positionViewAtEnd()
        }
    }


    Connections {
        target: GroundStatusMicroservice
        onStatusMessage: {
            console.log("Received ground message: " + message + ":" + sysid + ":" + level)
            messageModel.append({ "sysid": sysid, "message": message, "level": level })
            listModelSort(messageModel, (a, b) => a.timestamp > b.timestamp)
            messageList.positionViewAtEnd()
        }
    }


    Connections {
        target: AirStatusMicroservice
        onStatusMessage: {
            console.log("Received air message: " + message + ":" + sysid + ":" + level)
            messageModel.append({ "sysid": sysid, "message": message, "level": level })
            listModelSort(messageModel, (a, b) => a.timestamp > b.timestamp)
        }
    }


    ListModel {
        id: messageModel
    }


    Component {
        id: messageDelegate

        Item {
            height: 16

            Text {
                id: sysidText
                text: sysid == 254 ? "[Ground]" : "[Air]"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 56
                color: {
                    if (level == 0) {
                        return "#fa0000";
                    } else if (level == 1) {
                        return "#fa0000";
                    } else if (level == 2) {
                        return "#fa0000";
                    } else if (level == 3) {
                        return "#fa0000";
                    } else if (level == 4) {
                        return "#fffa00";
                    } else if (level == 5) {
                        return "#00ea00";
                    } else if (level == 6) {
                        return "#00ea00";
                    } else if (level == 7) {
                        return "#0000ea";
                    }

                    return "white";
                }

                font.bold: true
            }
            Text {
                text: message
                font.pixelSize: 12
                anchors.left: sysidText.right
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                color: "white"
            }
        }
    }

    function listModelSort(listModel, compareFunction) {
        let indexes = [ ...Array(listModel.count).keys() ]

        indexes.sort((a, b) => compareFunction(listModel.get(a), listModel.get(b)))

        let sorted = 0

        while (sorted < indexes.length && sorted === indexes[sorted]) sorted++

        if (sorted === indexes.length) return

        for (let i = sorted; i < indexes.length; i++) {
            listModel.move(indexes[i], listModel.count - 1, 1)
            listModel.insert(indexes[i], { })
        }

        listModel.remove(sorted, indexes.length - sorted)
    }

}
