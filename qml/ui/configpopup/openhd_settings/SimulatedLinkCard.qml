import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    implicitHeight: content.implicitHeight + 24
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    property string linkKind: "ethernet"
    readonly property bool simulated: ethernet ? settings.dev_simulate_ethernet_link : settings.dev_simulate_uart_link
    readonly property bool ethernet: linkKind === "ethernet"
    readonly property int linkSwitchRevision: _ohdSystemGroundSettings.update_count
    readonly property bool linkSwitchAvailable: ethernet && linkSwitchRevision >= 0 && _ohdSystemGroundSettings.param_int_exists("ETH_LINK_EN")
    readonly property bool linkRoutingEnabled: !linkSwitchAvailable || _ohdSystemGroundSettings.get_cached_int("ETH_LINK_EN") !== 0
    readonly property string title: ethernet ? qsTr("Ethernet Link") : qsTr("UART Link")
    readonly property string icon: ethernet ? "\uf796" : "\uf120"
    readonly property var usage: host ? host.usageFor(linkKind) : null
    function metric(name, divisor, suffix, decimals) {
        var value = usage ? usage[name] : undefined
        return value !== undefined && value !== null ? (Number(value) / divisor).toFixed(decimals) + suffix : qsTr("N/A")
    }
    function bitrate(name) { return metric(name, 1000000, " Mbit/s", 2) }

    radius: 10
    color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1

    function gainFocus() { if (linkSwitch.visible) linkSwitch.forceActiveFocus(); else root.forceActiveFocus() }
    function leaveCard() { if (host) host.collapseCard(cardIndex) }

    Keys.onPressed: function(event) { if (event.key === Qt.Key_Escape) { root.leaveCard(); event.accepted = true } }
    ColumnLayout {
        id: content
        anchors.fill: parent; anchors.margins: 12; spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text { text: root.icon; color: ethernet ? "#49a6ff" : "#c98cff"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon }
            Text { text: root.title; color: settings_form.primaryText; font.pixelSize: MenuTypography.sectionTitle; font.family: MenuTypography.family; font.bold: true; Layout.fillWidth: true }
            Switch { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                id: linkSwitch
                visible: root.linkSwitchAvailable && !root.simulated && root.host && root.host.bothMultiEnabled
                enabled: _ohdSystemGround.is_alive && !_ohdSystemGroundSettings.ui_is_busy
                text: checked ? qsTr("ENABLED") : qsTr("DISABLED")
                onClicked: _ohdSystemGroundSettings.try_set_param_int_async("ETH_LINK_EN", checked ? 1 : 0, true)
                Keys.onPressed: function(event) { if (event.key === Qt.Key_Escape) { root.leaveCard(); event.accepted = true } }
            }
            Binding { target: linkSwitch; property: "checked"; value: root.linkRoutingEnabled }
            Rectangle { visible: !linkSwitch.visible; Layout.preferredWidth: active.implicitWidth + 14; Layout.preferredHeight: 21; radius: 7; color: active.text === qsTr("NOT ROUTED") ? settings_form.panelBackground : Qt.rgba(0.1, 0.8, 0.35, 0.12)
                Text {
                    id: active
                    anchors.centerIn: parent
                    text: root.simulated ? qsTr("SIMULATED") :
                          (root.ethernet && root.host && root.host.bothSingleEnabled && root.host.wifiActive()
                           ? qsTr("NOT ROUTED") : qsTr("ACTIVE"))
                    color: text === qsTr("NOT ROUTED") ? settings_form.secondaryText : settings_form.goodColor
                    font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; font.bold: true
                }
            }
        }
        LinkUsageMeter {
            visible: root.host && root.host.showIndividualLinkUsage && settings_form.showAdvancedSettings
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? (root.width < 360 ? 100 : 78) : 0
            usage: root.host ? root.host.usageFor(root.linkKind) : null
            title: qsTr("Link Usage")
        }
        GridLayout {
            Layout.fillWidth: true; Layout.preferredHeight: root.ethernet ? 174 : 58; columns: 3
            Repeater {
                model: ethernet
                       ? [
                             {label: qsTr("PORT SPEED"), value: root.usage && root.usage.capacity_bps > 0 ? root.bitrate("capacity_bps") : qsTr("N/A")},
                             {label: qsTr("TX THROUGHPUT"), value: root.bitrate("tx_bps")},
                             {label: qsTr("RX THROUGHPUT"), value: root.bitrate("rx_bps")},
                             {label: qsTr("ROUND TRIP"), value: root.metric("rtt_us", 1000, " ms", 1)},
                             {label: qsTr("RTT JITTER"), value: root.metric("jitter_us", 1000, " ms", 1)},
                             {label: qsTr("PROBE LOSS"), value: root.metric("probe_loss_permille", 10, " %", 1)},
                             {label: qsTr("TX PACKETS"), value: root.metric("tx_pps", 1, " pps", 0)},
                             {label: qsTr("RX PACKETS"), value: root.metric("rx_pps", 1, " pps", 0)},
                             {label: qsTr("SEND ERRORS"), value: root.metric("send_errors", 1, "", 0)}
                         ]
                       : [{label: qsTr("CAPACITY"), value: root.host && root.host.usageFor("uart") && root.host.usageFor("uart").capacity_bps > 0 ? root.host.usageFor("uart").capacity_bps / 1000 + " kbit/s" : qsTr("N/A")}, {label: qsTr("PROTOCOL"), value: "MAVLink 2"}, {label: qsTr("LOSS"), value: root.simulated ? "0%" : qsTr("N/A")}]
                delegate: Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                    }
                }
            }
        }

    }
}
