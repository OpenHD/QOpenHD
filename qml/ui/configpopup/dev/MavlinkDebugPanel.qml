import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import OpenHD 1.0

Rectangle {
    id: root
    width: parent.width
    height: parent.height
    color: "#eaeaea"
    property real columnSourceWidth: Math.max(160, width * 0.2)
    property real columnOriginWidth: Math.max(120, width * 0.14)
    property real columnMessageWidth: Math.max(120, width * 0.14)
    property real columnLastSeenWidth: Math.max(140, width * 0.2)
    property real columnCountWidth: Math.max(90, width * 0.1)
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
        property real columnSourceWidth: Math.max(150, messageList.width * 0.2)
        property real columnOriginWidth: Math.max(110, messageList.width * 0.16)
        property real columnMessageWidth: Math.max(110, messageList.width * 0.16)
        property real columnLastSeenWidth: Math.max(140, messageList.width * 0.1)
        property real columnCountWidth: Math.max(80, messageList.width * 0.1)

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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: root.columnSourceWidth; Layout.maximumWidth: root.columnSourceWidth; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Source (sys/comp/msg)"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: root.columnOriginWidth; Layout.maximumWidth: root.columnOriginWidth; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Origin"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: root.columnMessageWidth; Layout.maximumWidth: root.columnMessageWidth; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Message"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: root.columnLastSeenWidth; Layout.maximumWidth: root.columnLastSeenWidth; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Last seen"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: root.columnCountWidth; Layout.maximumWidth: root.columnCountWidth; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Count"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            ListView {
                id: messageList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: _mavlinkMessageStatsModel

                delegate: Rectangle {
                    width: messageList.width
                    implicitHeight: 32
                    color: (index % 2 === 0) ? "#ffffff" : "#f5f5f5"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8
                        Text {
                            text: model.source_label
                            Layout.minimumWidth: root.columnSourceWidth
                            Layout.maximumWidth: root.columnSourceWidth
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: model.origin_category
                            Layout.minimumWidth: root.columnOriginWidth
                            Layout.maximumWidth: root.columnOriginWidth
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Item {
                            Layout.minimumWidth: root.columnMessageWidth
                            Layout.maximumWidth: root.columnMessageWidth
                            height: parent.height
                            Text {
                                id: messageText
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.message_name
                                width: parent.width
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessageDetails(model.message_id)
                                    decodeDialog.open()
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Text {
                            text: model.last_seen_readable
                            Layout.minimumWidth: root.columnLastSeenWidth
                            Layout.maximumWidth: root.columnLastSeenWidth
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: model.update_count
                            Layout.minimumWidth: root.columnCountWidth
                            Layout.maximumWidth: root.columnCountWidth
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
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

            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: "#f0f0f0"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12
                    Label {
                        text: qsTr("Field")
                        font.bold: true
                        Layout.preferredWidth: decodeDialog.width * 0.35
                    }
                    Label {
                        text: qsTr("Type")
                        font.bold: true
                        Layout.preferredWidth: decodeDialog.width * 0.25
                    }
                    Label {
                        text: qsTr("Array length")
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: fieldList
                    anchors.fill: parent
                    spacing: 2
                    model: root.decodedMessageDetails.fields
                    delegate: Rectangle {
                        width: fieldList.width
                        height: 32
                        color: (index % 2 === 0) ? "#ffffff" : "#f7f7f7"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12
                            Label {
                                text: modelData.name
                                Layout.preferredWidth: decodeDialog.width * 0.35
                                elide: Text.ElideRight
                            }
                            Label {
                                text: modelData.type
                                Layout.preferredWidth: decodeDialog.width * 0.25
                                elide: Text.ElideRight
                            }
                            Label {
                                text: modelData.arrayLength > 1 ? modelData.arrayLength : ""
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }
}
