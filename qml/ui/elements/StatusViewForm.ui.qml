import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import SortFilterProxyModel 0.2

Item {
    ListView {
        id: messageList

        model: sortModel

        anchors.fill: parent

        topMargin: 12
        bottomMargin: 12

        delegate: messageDelegate

        Component.onCompleted: {
            messageList.positionViewAtEnd()
        }
    }

    Connections {
        target: AirStatusMicroservice
        function onStatusMessage() {
            messageList.positionViewAtEnd()
        }
    }

    Connections {
        target: GroundStatusMicroservice
        function onStatusMessage() {
            messageList.positionViewAtEnd()
        }
    }


    SortFilterProxyModel {
        id: sortModel
        sourceModel: StatusLogModel
        sorters: RoleSorter {
            roleName: "timestamp";
            sortOrder: Qt.AscendingOrder
        }
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
}
