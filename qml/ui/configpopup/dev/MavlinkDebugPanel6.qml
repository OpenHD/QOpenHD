import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import OpenHD 1.0

// Qt6-compatible version of MavlinkDebugPanel using ListView instead of Controls1.TableView

Rectangle {
    id: root
    width: parent.width
    height: parent.height
    color: "#eaeaea"

    property real columnSysWidth: 40
    property real columnCompWidth: 40
    property real columnMsgWidth: 40
    property real columnOriginWidth: 60
    property real columnMessageWidth: 260
    property real columnLastSeenWidth: 80
    property real columnCountWidth: 50
    property var decodedMessageDetails: ({messageName: "", messageId: 0, fieldCount: 0, fields: []})

    TabBar {
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("Mavlink Debug")
        }
    }

    ColumnLayout {
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 10

        RowLayout {
            spacing: 10
            Button {
                text: qsTr("Ping all systems")
                onClicked: _mavlinkTelemetry.ping_all_systems()
            }
            Button {
                text: qsTr("Clear table")
                onClicked: _mavlinkMessageStatsModel.clear()
            }
            Button {
                text: qsTr("Start")
                enabled: !_mavlinkMessageStatsModel.enabled
                onClicked: _mavlinkMessageStatsModel.setEnabled(true)
            }
            Button {
                text: qsTr("Stop")
                enabled: _mavlinkMessageStatsModel.enabled
                onClicked: _mavlinkMessageStatsModel.setEnabled(false)
            }
            Text {
                text: qsTr("Incoming Mavlink messages (grouped by sys/comp/msg)")
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Text {
                text: _mavlinkMessageStatsModel.enabled ? qsTr("Capturing") : qsTr("Paused")
                color: _mavlinkMessageStatsModel.enabled ? "#1b5e20" : "#b71c1c"
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Header row
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#f0f0f0"

            Row {
                anchors.fill: parent

                Rectangle {
                    width: root.columnSysWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Sys")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnCompWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Cmp")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnMsgWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Msg")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnOriginWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Origin")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnMessageWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Message")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnLastSeenWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Last seen")
                        font.bold: true
                    }
                }
                Rectangle {
                    width: root.columnCountWidth
                    height: parent.height
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Count")
                        font.bold: true
                    }
                }
            }
        }

        // Message list
        ListView {
            id: messageList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: _mavlinkMessageStatsModel

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                id: delegateRoot
                width: messageList.width
                height: 36
                color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"

                required property int index
                required property string system_id
                required property string component_id
                required property string message_id
                required property string origin_category
                required property string message_name
                required property string last_seen_readable
                required property string update_count

                Row {
                    anchors.fill: parent

                    Rectangle {
                        width: root.columnSysWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ("000" + delegateRoot.system_id).slice(-3)
                            font.family: "monospace"
                        }
                    }
                    Rectangle {
                        width: root.columnCompWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ("000" + delegateRoot.component_id).slice(-3)
                            font.family: "monospace"
                        }
                    }
                    Rectangle {
                        width: root.columnMsgWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ("000" + delegateRoot.message_id).slice(-3)
                            font.family: "monospace"
                        }
                    }
                    Rectangle {
                        width: root.columnOriginWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.origin_category
                        }
                    }
                    Rectangle {
                        width: root.columnMessageWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.message_name
                            elide: Text.ElideRight
                            width: parent.width - 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessageDetails(delegateRoot.index)
                                decodeDialog.open()
                            }
                        }
                    }
                    Rectangle {
                        width: root.columnLastSeenWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.last_seen_readable
                        }
                    }
                    Rectangle {
                        width: root.columnCountWidth
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.update_count
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: decodeDialog
        title: qsTr("Message details")
        modal: true
        standardButtons: Dialog.Ok
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        width: root.width * 0.9
        height: root.height * 0.9

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            anchors.topMargin: 50
            spacing: 12

            GridLayout {
                columns: 2
                columnSpacing: 8
                rowSpacing: 6
                Layout.fillWidth: true
                Label { text: qsTr("Name"); font.bold: true }
                Label { text: root.decodedMessageDetails.messageName }
                Label { text: qsTr("ID"); font.bold: true }
                Label { text: root.decodedMessageDetails.messageId }
                Label { text: qsTr("Field count"); font.bold: true }
                Label { text: root.decodedMessageDetails.fieldCount }
            }

            // Field details header
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: "#f0f0f0"

                Row {
                    anchors.fill: parent

                    Rectangle {
                        width: 180
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Field")
                            font.bold: true
                        }
                    }
                    Rectangle {
                        width: 80
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Type")
                            font.bold: true
                        }
                    }
                    Rectangle {
                        width: 80
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Array length")
                            font.bold: true
                        }
                    }
                    Rectangle {
                        width: 220
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Value")
                            font.bold: true
                        }
                    }
                }
            }

            // Field details list
            ListView {
                id: fieldList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.decodedMessageDetails.fields

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: fieldList.width
                    height: 32
                    color: index % 2 === 0 ? "#ffffff" : "#f7f7f7"

                    required property int index
                    required property var modelData

                    Row {
                        anchors.fill: parent

                        Rectangle {
                            width: 180
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name || ""
                                elide: Text.ElideRight
                                width: parent.width - 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Rectangle {
                            width: 80
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.type || ""
                            }
                        }
                        Rectangle {
                            width: 80
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.arrayLength > 1 ? modelData.arrayLength : ""
                            }
                        }
                        Rectangle {
                            width: 220
                            height: parent.height
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.value || ""
                                elide: Text.ElideRight
                                width: parent.width - 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
