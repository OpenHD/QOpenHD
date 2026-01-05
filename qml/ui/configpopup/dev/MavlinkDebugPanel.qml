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
        property real columnSourceWidth: Math.max(150, messageList.width * 0.24)
        property real columnOriginWidth: Math.max(110, messageList.width * 0.15)
        property real columnMessageWidth: Math.max(170, messageList.width * 0.24)
        property real columnLastSeenWidth: Math.max(140, messageList.width * 0.2)
        property real columnCountWidth: Math.max(80, messageList.width * 0.12)
        property string decodedMessageDetails: ""

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
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: columnSourceWidth; Layout.maximumWidth: columnSourceWidth; Layout.fillWidth: true; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Source (sys/comp/msg)"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: columnOriginWidth; Layout.maximumWidth: columnOriginWidth; Layout.fillWidth: true; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Origin"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: columnMessageWidth; Layout.maximumWidth: columnMessageWidth; Layout.fillWidth: true; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Message"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: columnLastSeenWidth; Layout.maximumWidth: columnLastSeenWidth; Layout.fillWidth: true; height: 32
                    Text { anchors.centerIn: parent; text: qsTr("Last seen"); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle { color: "#f0f0f0"; Layout.minimumWidth: columnCountWidth; Layout.maximumWidth: columnCountWidth; Layout.fillWidth: true; height: 32
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
                            Layout.minimumWidth: columnSourceWidth
                            Layout.maximumWidth: columnSourceWidth
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: model.origin_category
                            Layout.minimumWidth: columnOriginWidth
                            Layout.maximumWidth: columnOriginWidth
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Item {
                            Layout.minimumWidth: columnMessageWidth
                            Layout.maximumWidth: columnMessageWidth
                            Layout.fillWidth: true
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
                                    root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessage(model.message_id)
                                    decodeDialog.open()
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Text {
                            text: model.last_seen_readable
                            Layout.minimumWidth: columnLastSeenWidth
                            Layout.maximumWidth: columnLastSeenWidth
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: model.update_count
                            Layout.minimumWidth: columnCountWidth
                            Layout.maximumWidth: columnCountWidth
                            Layout.fillWidth: true
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
        visible: false
        contentItem: Item {
            width: 420
            implicitHeight: decodeText.paintedHeight + 20
            Text {
                id: decodeText
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 10
                    rightMargin: 10
                    top: parent.top
                    topMargin: 10
                }
                wrapMode: Text.Wrap
                text: root.decodedMessageDetails
            }
        }
    }
}
