import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import "../configpopup/status/SystemHealth.js" as SystemHealth

SideBarBasePanel {
    id: status
    override_title: "Status"
    headerIcon: "\uf21e"

    readonly property var air: _ohdSystemAir
    readonly property var ground: _ohdSystemGround
    readonly property bool flightControllerOnline: _fcMavlinkSystem.is_alive
    readonly property color mutedText: "#acbfd1"
    readonly property color onlineColor: "#62e6a8"

    function takeover_control() {
        detailsButton.forceActiveFocus()
        ensure_body_item_visible(detailsButton)
    }

    ColumnLayout {
        x: 24
        y: 14
        width: parent.width - 48
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [status.air, status.ground]

                Rectangle {
                    id: unitCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 130
                    radius: 14
                    color: "#213548"
                    border.color: "#365169"

                    readonly property var unit: modelData
                    readonly property bool online: unit.is_alive
                    readonly property bool hasTemp: online && unit.curr_soc_temp_degree > 0
                    readonly property bool hasCpu: online && unit.curr_cpuload_perc >= 0
                        && unit.curr_cpuload_perc <= 100 && (unit.onboard_uptime_ms >= 0 || hasTemp)
                    readonly property var health: SystemHealth.evaluate(unit, index === 1, settings)
                    readonly property color statusColor: !online ? status.mutedText
                        : health.severity === 2 ? "#ff9292"
                        : health.severity === 1 ? "#ffcb76" : status.onlineColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        Label {
                            text: index === 0 ? qsTr("Air unit") : qsTr("Ground unit")
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            color: "#f2f8ff"
                        }
                        Label {
                            Layout.fillWidth: true
                            text: !unitCard.online ? qsTr("Offline")
                                : unitCard.health.severity === 2 ? qsTr("Warning")
                                : unitCard.health.severity === 1 ? qsTr("Caution") : qsTr("Online")
                            color: unitCard.statusColor
                            font.pixelSize: 19
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: {
                                if (!unitCard.online) return "\u2014"
                                var metrics = []
                                if (unitCard.hasTemp) metrics.push(qsTr("%1 \u00b0C").arg(unitCard.unit.curr_soc_temp_degree))
                                if (unitCard.hasCpu) metrics.push(qsTr("%1% CPU").arg(unitCard.unit.curr_cpuload_perc))
                                return metrics.length ? metrics.join("  \u00b7  ") : qsTr("No readings yet")
                            }
                            font.pixelSize: 18
                            color: status.mutedText
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 12
            color: "#1a2b3b"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 16

                Repeater {
                    model: [
                        { label: qsTr("Downlink signal"),
                          value: status.ground.is_alive && status.ground.current_rx_rssi > -128 && status.ground.current_rx_rssi < 0
                              ? qsTr("%1 dBm").arg(status.ground.current_rx_rssi) : "\u2014" },
                        { label: qsTr("Packet loss"),
                          value: status.ground.is_alive && status.ground.curr_rx_packet_loss_perc >= 0 && status.ground.curr_rx_packet_loss_perc <= 100
                              ? qsTr("%1%").arg(status.ground.curr_rx_packet_loss_perc) : "\u2014" }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 1
                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: status.mutedText
                            font.pixelSize: 17
                            elide: Text.ElideRight
                        }
                        Label {
                            text: modelData.value
                            color: "#f2f8ff"
                            font.pixelSize: 21
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Label {
                Layout.fillWidth: true
                text: qsTr("Flight controller")
                color: "#e5eef7"
                font.pixelSize: 20
                elide: Text.ElideRight
            }
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: status.flightControllerOnline ? status.onlineColor : status.mutedText
            }
            Label {
                text: status.flightControllerOnline ? qsTr("Online") : qsTr("Offline")
                color: status.flightControllerOnline ? status.onlineColor : status.mutedText
                font.pixelSize: 19
            }
        }

        Button {
            id: detailsButton
            objectName: "sidebarStatusDetails"
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            text: qsTr("Open system status")
            font.pixelSize: 20
            font.weight: Font.DemiBold

            onClicked: {
                sidebar.close()
                hudOverlayGrid.open_config_popup(true)
            }
            Keys.onUpPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onDownPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onLeftPressed: sidebar.regain_control_on_sidebar_stack()
            Keys.onRightPressed: clicked()
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()

            background: Rectangle {
                radius: 12
                color: detailsButton.down || detailsButton.activeFocus ? "#235778" : "#203b53"
                border.color: detailsButton.activeFocus ? "#71d4ff" : "#395c77"
                border.width: detailsButton.activeFocus ? 2 : 1
            }
            contentItem: Label {
                text: detailsButton.text
                font: detailsButton.font
                color: "#e7f6ff"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
