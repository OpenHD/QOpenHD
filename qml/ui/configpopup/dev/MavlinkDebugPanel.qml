import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import OpenHD 1.0
import QtQuick.Controls 1.4 as Controls1

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

        Controls1.TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            columnSpacing: 6
            rowSpacing: 2
            model: _mavlinkMessageStatsModel

            delegate: Rectangle {
                implicitHeight: 32
                color: (row % 2 === 0) ? "#ffffff" : "#f5f5f5"
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

            Controls1.TableViewColumn { role: "source_label"; title: qsTr("Source (sys/comp/msg)"); width: 160 }
            Controls1.TableViewColumn { role: "origin_category"; title: qsTr("Origin"); width: 90 }
            Controls1.TableViewColumn { role: "message_name"; title: qsTr("Message"); width: 140 }
            Controls1.TableViewColumn { role: "last_seen_readable"; title: qsTr("Last seen" ); width: 140 }
            Controls1.TableViewColumn { role: "update_count"; title: qsTr("Count"); width: 70 }
        }
    }
}
