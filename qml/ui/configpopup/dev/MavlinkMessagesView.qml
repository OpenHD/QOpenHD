import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf188"
    pageTitle: qsTr("MAVLink")
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
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; objectName:"mavlinkPingButton";id: pingButton; text: qsTr("Ping systems"); iconText: "\uf1ce"; onClicked: _mavlinkTelemetry.ping_all_systems(); KeyNavigation.right: clearButton }
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; objectName:"mavlinkClearButton";id: clearButton; text: qsTr("Clear"); iconText: "\uf2ed"; onClicked: _mavlinkMessageStatsModel.clear(); KeyNavigation.left: pingButton; KeyNavigation.right: captureButton }
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                objectName:"mavlinkCaptureButton";id: captureButton
                text: _mavlinkMessageStatsModel.enabled ? qsTr("Pause") : qsTr("Start")
                iconText: _mavlinkMessageStatsModel.enabled ? "\uf04c" : "\uf04b"
                primary: !_mavlinkMessageStatsModel.enabled
                onClicked: _mavlinkMessageStatsModel.setEnabled(!_mavlinkMessageStatsModel.enabled)
                KeyNavigation.left: clearButton
            }
            Item { Layout.fillWidth: true }
            Rectangle { width: 8; height: 8; radius: 4; color: _mavlinkMessageStatsModel.enabled ? settings_form.goodColor : settings_form.errorColor }
            Text { text: _mavlinkMessageStatsModel.enabled ? qsTr("CAPTURING") : qsTr("PAUSED"); color: _mavlinkMessageStatsModel.enabled ? settings_form.goodColor : settings_form.errorColor; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
        }

        AdvancedCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentMargin: 1
            ListView {
                id: messageTable
                anchors.fill: parent
                focus: true
                clip: true
                model: _mavlinkMessageStatsModel
                KeyNavigation.up: pingButton
                readonly property var columnWidths: [52, 58, 58, 78, Math.max(190, width - 430), 100, 78]
                headerPositioning: ListView.OverlayHeader
                header: Rectangle {
                    width: messageTable.width
                    height: MenuTypography.controlHeight
                    color: settings_form.panelBackgroundRaised
                    z: 2
                    Row {
                        Repeater {
                            model: [qsTr("SYS"), qsTr("COMP"), qsTr("MSG"), qsTr("ORIGIN"), qsTr("MESSAGE"), qsTr("LAST SEEN"), qsTr("COUNT")]
                            delegate: Text {
                                width: messageTable.columnWidths[index]; height: MenuTypography.controlHeight
                                text: modelData; color: settings_form.secondaryText
                                font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; font.bold: true
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
                delegate: Rectangle {
                    id: messageRow
                    width: messageTable.width; height: 34
                    color: ListView.isCurrentItem ? (settings_form.darkMode ? "#193d60" : "#e1effd")
                                                 : (index % 2 ? settings_form.panelBackgroundRaised : settings_form.panelBackground)
                    readonly property int rowIndex: index
                    readonly property var values: [model.system_id, model.component_id, model.message_id,
                        model.origin_category, model.message_name, model.last_seen_readable, model.update_count]
                    Row {
                        Repeater {
                            model: messageRow.values
                            delegate: Item {
                                width: messageTable.columnWidths[index]; height: 34
                                Text {
                                    anchors.fill: parent; anchors.margins: 6
                                    text: index <= 2 ? ("000" + modelData).slice(-3) : modelData
                                    color: settings_form.primaryText
                                    font.family: index <= 2 ? "Roboto Mono" : MenuTypography.family
                                    font.pixelSize: MenuTypography.body
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: index === 4 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        messageTable.currentIndex = messageRow.rowIndex
                                        if (index === 4) {
                                            root.decodedMessageDetails = _mavlinkMessageStatsModel.decodeMessageDetails(messageRow.rowIndex)
                                            decodeDialog.open()
                                        }
                                    }
                                }
                            }
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

    AdvancedDialog {
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
            Text { text: root.decodedMessageDetails.messageName; color: settings_form.primaryText; font.pixelSize: MenuTypography.sectionTitle; font.family: MenuTypography.family; font.bold: true }
            Text { text: qsTr("Message ID %1 · %2 fields").arg(root.decodedMessageDetails.messageId).arg(root.decodedMessageDetails.fieldCount); color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family }
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
                        Text { text: modelData.name; color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; Layout.preferredWidth: 180; elide: Text.ElideRight }
                        Text { text: modelData.type; color: settings_form.secondaryText; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; Layout.preferredWidth: 80 }
                        Text { text: modelData.value; color: settings_form.primaryText; font.family: "Roboto Mono"; font.pixelSize: MenuTypography.body; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }
            }
            AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; Layout.alignment: Qt.AlignRight; text: qsTr("Close"); primary: true; onClicked: decodeDialog.close() }
        }
    }
}
