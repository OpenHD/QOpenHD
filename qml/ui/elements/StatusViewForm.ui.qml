import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12



Item {
    ListView {
        model: messageModel

        anchors.fill: parent

        topMargin: 12
        bottomMargin: 12

        delegate: messageDelegate
    }


    Connections {
        target: GroundStatusMicroservice
        onStatusMessage: {
            console.log("Received ground message: " + message + ":" + sysid + ":" + level)
            messageModel.append({ "sysid": sysid, "message": message })
        }
    }


    Connections {
        target: AirStatusMicroservice
        onStatusMessage: {
            console.log("Received air message: " + message + ":" + sysid + ":" + level)
            messageModel.append({ "sysid": sysid, "message": message })
        }
    }


    ListModel {
        id: messageModel

        ListElement { message: "Initializing WiFi";         level: 5; sysid: 254 }
        ListElement { message: "Checking SmartSync GPIO";   level: 5; sysid: 254 }
        ListElement { message: "Using profile 2";           level: 5; sysid: 254 }
        ListElement { message: "Begin SmartSync";           level: 5; sysid: 254 }
        ListElement { message: "Begin SmartSync";           level: 5; sysid: 253 }
        ListElement { message: "Transferring settings file";level: 5; sysid: 254 }
        ListElement { message: "Settings file received";    level: 5; sysid: 253 }
        ListElement { message: "Reconfiguring WiFi";        level: 5; sysid: 253 }
        ListElement { message: "Starting Hotspot";          level: 5; sysid: 254 }
        ListElement { message: "Error: hotspot band 5.8 not available on this hardware"; level: 3; sysid: 254 }
        ListElement { message: "Starting OSD";              level: 5; sysid: 254 }
        ListElement { message: "Starting video stream";     level: 5; sysid: 253 }
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

}
