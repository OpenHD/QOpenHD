import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as Controls1
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import OpenHD 1.0

Rectangle {
    id: root
    width: parent.width
    height: parent.height
    color: "#eaeaea"
    property real columnSysWidth: 40
    property real columnCompWidth: 40
    property real columnMsgWidth: 40
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
        property real columnSysWidth: Math.max(root.columnSysWidth, messageTable.width * 0.06)
        property real columnCompWidth: Math.max(root.columnCompWidth, messageTable.width * 0.06)
        property real columnMsgWidth: Math.max(root.columnMsgWidth, messageTable.width * 0.06)
        property real columnOriginWidth: Math.max(root.columnOriginWidth, messageTable.width * 0.14)
        property real columnMessageWidth: Math.max(root.columnMessageWidth, messageTable.width * 0.18)
        property real columnLastSeenWidth: Math.max(root.columnLastSeenWidth, messageTable.width * 0.12)
        property real columnCountWidth: Math.max(root.columnCountWidth, messageTable.width * 0.1)

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

        Controls1.TableView {
            id: messageTable
            Layout.fillWidth: true
            Layout.fillHeight: true
            alternatingRowColors: false
            frameVisible: false
            headerVisible: true
            sortIndicatorVisible: false
            model: _mavlinkMessageStatsModel
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            verticalScrollBarPolicy: Qt.ScrollBarAsNeeded

            Controls1.TableViewColumn { role: "system_id"; title: qsTr("Sys"); width: columnSysWidth }
            Controls1.TableViewColumn { role: "component_id"; title: qsTr("Cmp"); width: columnCompWidth }
            Controls1.TableViewColumn { role: "message_id"; title: qsTr("Msg"); width: columnMsgWidth }
            Controls1.TableViewColumn { role: "origin_category"; title: qsTr("Origin"); width: columnOriginWidth }
            Controls1.TableViewColumn { role: "message_name"; title: qsTr("Message"); width: columnMessageWidth }
            Controls1.TableViewColumn { role: "last_seen_readable"; title: qsTr("Last seen"); width: columnLastSeenWidth }
            Controls1.TableViewColumn { role: "update_count"; title: qsTr("Count"); width: columnCountWidth }

            rowDelegate: Rectangle {
                height: 36
                color: styleData.selected ? "#d7e8ff" : (styleData.row % 2 === 0 ? "#ffffff" : "#f5f5f5")
            }

            headerDelegate: Rectangle {
                implicitHeight: 36
                color: "#f0f0f0"
                Text {
                    anchors.centerIn: parent
                    text: styleData.value
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            itemDelegate: Item {
                implicitHeight: 32
                anchors.fill: parent

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: styleData.column >= 3 ? 8 : 12
                    horizontalAlignment: styleData.column <= 2 ? Text.AlignHCenter : (styleData.column === 6 ? Text.AlignHCenter : Text.AlignLeft)
                    elide: Text.ElideRight
                    font.family: styleData.column <= 2 ? "monospace" : font.family
                    text: styleData.column <= 2 ? ("000" + styleData.value).slice(-3) : styleData.value
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: styleData.column === 4 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: styleData.column === 4
                    onClicked: {
                        var rowData = messageTable.model.get(styleData.row)
                        root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessageDetails(rowData.message_id)
                        decodeDialog.open()
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

            Controls1.TableView {
                id: fieldTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                frameVisible: false
                headerVisible: true
                alternatingRowColors: false
                model: root.decodedMessageDetails.fields
                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAsNeeded

                Controls1.TableViewColumn { role: "name"; title: qsTr("Field"); width: decodeDialog.width * 0.4 }
                Controls1.TableViewColumn { role: "type"; title: qsTr("Type"); width: decodeDialog.width * 0.32 }
                Controls1.TableViewColumn { role: "arrayLength"; title: qsTr("Array length"); width: decodeDialog.width * 0.2 }

                rowDelegate: Rectangle {
                    height: 32
                    color: styleData.selected ? "#d7e8ff" : (styleData.row % 2 === 0 ? "#ffffff" : "#f7f7f7")
                }

                headerDelegate: Rectangle {
                    implicitHeight: 32
                    color: "#f0f0f0"
                    Text {
                        anchors.centerIn: parent
                        text: styleData.value
                        font.bold: true
                    }
                }

                itemDelegate: Item {
                    implicitHeight: 28
                    anchors.fill: parent
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        elide: Text.ElideRight
                        horizontalAlignment: styleData.column === 2 ? Text.AlignRight : Text.AlignLeft
                        text: styleData.role === "arrayLength" ? (styleData.value > 1 ? styleData.value : "") : styleData.value
                    }
                }
            }
        }
    }
}
