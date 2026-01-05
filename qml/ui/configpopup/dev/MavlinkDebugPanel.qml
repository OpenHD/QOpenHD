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
    property real columnMessageWidth: Math.max(190, width * 0.26)
    property real columnLastSeenWidth: Math.max(140, width * 0.2)
    property real columnCountWidth: Math.max(90, width * 0.1)
    property string decodedMessageDetails: ""

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
                                    root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessage(model.message_id)
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
        visible: false
        contentItem: Item {
            width: 420
            implicitHeight: decodeText.paintedHeight + 40
            Flickable {
                anchors.fill: parent
                contentWidth: decodeText.paintedWidth
                contentHeight: decodeText.paintedHeight
                clip: true
                Text {
                    id: decodeText
                    width: parent.width - 20
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        top: parent.top
                        topMargin: 10
                    }
                    wrapMode: Text.Wrap
                    text: root.decodedMessageDetails
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
