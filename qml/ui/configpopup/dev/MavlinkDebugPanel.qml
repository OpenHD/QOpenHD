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
            Text {
                text: qsTr("Incoming Mavlink messages (grouped by sys/comp/msg)")
                font.pixelSize: 14
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
                Text { text: qsTr("Source (sys/comp/msg)"); font.bold: true; Layout.preferredWidth: 120 }
                Text { text: qsTr("Origin"); font.bold: true; Layout.preferredWidth: 90 }
                Text { text: qsTr("Message"); font.bold: true; Layout.preferredWidth: 130 }
                Text { text: qsTr("Last seen"); font.bold: true; Layout.preferredWidth: 120 }
                Text { text: qsTr("Count"); font.bold: true; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
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
                        Text { text: model.source_label; Layout.preferredWidth: 120; elide: Text.ElideRight }
                        Text { text: model.origin_category; Layout.preferredWidth: 90; elide: Text.ElideRight }
                        Text { text: model.message_name; Layout.preferredWidth: 130; elide: Text.ElideRight }
                        Text { text: model.last_seen_readable; Layout.preferredWidth: 120; elide: Text.ElideRight }
                        Text { text: model.update_count; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }
    }
}
