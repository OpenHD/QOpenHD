import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as Controls1
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf188"
    pageTitle: qsTr("MAVLINK DEBUG")
    pageSubtitle: qsTr("Inspect incoming messages by system, component and type")
    initialFocusItem: pingButton
    onBackRequested: settings_form.side_bar_regain_focus()

    property var decodedMessageDetails: ({messageName: "", messageId: 0, fieldCount: 0, fields: []})
    onVisibleChanged: {
        if (!visible)
            _mavlinkMessageStatsModel.setEnabled(false)
    }
    Component.onCompleted: _mavlinkMessageStatsModel.setEnabled(false)

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            AdvancedActionButton { id: pingButton; text: qsTr("Ping systems"); iconText: "\uf1ce"; onClicked: _mavlinkTelemetry.ping_all_systems(); KeyNavigation.right: clearButton }
            AdvancedActionButton { id: clearButton; text: qsTr("Clear"); iconText: "\uf2ed"; onClicked: _mavlinkMessageStatsModel.clear(); KeyNavigation.left: pingButton; KeyNavigation.right: captureButton }
            AdvancedActionButton {
                id: captureButton
                text: _mavlinkMessageStatsModel.enabled ? qsTr("Pause") : qsTr("Start")
                iconText: _mavlinkMessageStatsModel.enabled ? "\uf04c" : "\uf04b"
                primary: !_mavlinkMessageStatsModel.enabled
                onClicked: _mavlinkMessageStatsModel.setEnabled(!_mavlinkMessageStatsModel.enabled)
                KeyNavigation.left: clearButton
            }
            Item { Layout.fillWidth: true }
            Rectangle { width: 8; height: 8; radius: 4; color: _mavlinkMessageStatsModel.enabled ? settings_form.goodColor : settings_form.errorColor }
            Text { text: _mavlinkMessageStatsModel.enabled ? qsTr("CAPTURING") : qsTr("PAUSED"); color: _mavlinkMessageStatsModel.enabled ? settings_form.goodColor : settings_form.errorColor; font.pixelSize: 11; font.bold: true }
        }

        AdvancedCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentMargin: 1
            Controls1.TableView {
                id: messageTable
                anchors.fill: parent
                focus: true
                alternatingRowColors: false
                frameVisible: false
                headerVisible: true
                sortIndicatorVisible: false
                model: _mavlinkMessageStatsModel
                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                KeyNavigation.up: pingButton

                Controls1.TableViewColumn { role: "system_id"; title: qsTr("SYS"); width: 52 }
                Controls1.TableViewColumn { role: "component_id"; title: qsTr("COMP"); width: 58 }
                Controls1.TableViewColumn { role: "message_id"; title: qsTr("MSG"); width: 58 }
                Controls1.TableViewColumn { role: "origin_category"; title: qsTr("ORIGIN"); width: 78 }
                Controls1.TableViewColumn { role: "message_name"; title: qsTr("MESSAGE"); width: Math.max(190, messageTable.width - 430) }
                Controls1.TableViewColumn { role: "last_seen_readable"; title: qsTr("LAST SEEN"); width: 100 }
                Controls1.TableViewColumn { role: "update_count"; title: qsTr("COUNT"); width: 78 }

                rowDelegate: Rectangle {
                    height: 34
                    color: styleData.selected ? (settings_form.darkMode ? "#193d60" : "#e1effd")
                                              : (styleData.row % 2 ? settings_form.panelBackgroundRaised : settings_form.panelBackground)
                }
                headerDelegate: Rectangle {
                    implicitHeight: 34
                    color: settings_form.panelBackgroundRaised
                    border.color: settings_form.lineColor
                    Text { anchors.centerIn: parent; text: styleData.value; color: settings_form.secondaryText; font.pixelSize: 10; font.bold: true }
                }
                itemDelegate: Item {
                    implicitHeight: 32
                    Text {
                        anchors.fill: parent
                        anchors.margins: 6
                        text: styleData.column <= 2 ? ("000" + styleData.value).slice(-3) : styleData.value
                        color: settings_form.primaryText
                        font.family: styleData.column <= 2 ? "Roboto Mono" : ""
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: styleData.column === 4
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessageDetails(styleData.row)
                            decodeDialog.open()
                        }
                    }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                        settings_form.side_bar_regain_focus(); event.accepted = true
                    }
                }
            }
        }
    }

    Dialog {
        id: decodeDialog
        modal: true
        closePolicy: Popup.CloseOnEscape
        width: Math.min(root.width * 0.86, 760)
        height: Math.min(root.height * 0.82, 620)
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        background: Rectangle { color: settings_form.panelBackground; radius: 12; border.color: settings_form.lineColor }
        contentItem: ColumnLayout {
            spacing: 10
            Text { text: root.decodedMessageDetails.messageName; color: settings_form.primaryText; font.pixelSize: 18; font.bold: true }
            Text { text: qsTr("Message ID %1 · %2 fields").arg(root.decodedMessageDetails.messageId).arg(root.decodedMessageDetails.fieldCount); color: settings_form.secondaryText; font.pixelSize: 11 }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.decodedMessageDetails.fields
                clip: true
                spacing: 3
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                delegate: Rectangle {
                    width: parent.width
                    height: 34
                    radius: 5
                    color: index % 2 ? settings_form.panelBackgroundRaised : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 9
                        Text { text: modelData.name; color: settings_form.primaryText; font.pixelSize: 11; Layout.preferredWidth: 180; elide: Text.ElideRight }
                        Text { text: modelData.type; color: settings_form.secondaryText; font.pixelSize: 10; Layout.preferredWidth: 80 }
                        Text { text: modelData.value; color: settings_form.primaryText; font.family: "Roboto Mono"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }
            }
            AdvancedActionButton { Layout.alignment: Qt.AlignRight; text: qsTr("Close"); primary: true; onClicked: decodeDialog.close() }
        }
    }
}
