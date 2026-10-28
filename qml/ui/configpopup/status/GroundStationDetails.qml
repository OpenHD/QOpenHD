import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../elements"

Popup {
    id: dialog
    objectName: "groundStationDetailsPopup"
    parent: Overlay.overlay
    anchors.centerIn: parent
    readonly property real uiScale: Math.min(1, (parent.width - 24) / 1080, (parent.height - 24) / 800)
    width: 1080 * uiScale
    height: 800 * uiScale
    padding: 0
    modal: true; dim: true; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#af000b12" }
    readonly property var unit: _ohdSystemGround
    readonly property var params: _ohdSystemGroundSettings
    readonly property bool preview: _qopenhd.debugMenuPreview
    readonly property bool live: unit.is_alive
    readonly property bool hotspotWritable: !preview && live && params.has_params_fetched && params.param_int_exists("WIFI_HOTSPOT_E")
    readonly property int hotspotMode: {
        var revision = params.update_count
        return live && params.has_params_fetched && params.param_int_exists("WIFI_HOTSPOT_E") ? params.get_cached_int("WIFI_HOTSPOT_E") : -1
    }
    readonly property var details: live && unit.ground_details ? unit.ground_details : ({})
    function storageText(prefix) {
        var used=details[prefix+"_used_bytes"],total=details[prefix+"_total_bytes"]
        if (!(total > 0) || used < 0 || used > total) return unavailable
        return qsTr("%1 / %2 GiB (%3 %)").arg((used/1073741824).toFixed(1)).arg((total/1073741824).toFixed(1)).arg(Math.round(used*100/total))
    }
    readonly property string unavailable: qsTr("Not reported")
    // OpenHD's legacy ONBOARD_COMPUTER_STATUS sends RAM usage as a percentage.
    readonly property real ramPercent: live && unit.onboard_ram_usage_mib >= 0 && unit.onboard_ram_usage_mib <= 100 ? unit.onboard_ram_usage_mib : -1
    // The OpenHD producer forwards MemTotal from /proc/meminfo in KiB,
    // despite the historical QOpenHD property name ending in _mib.
    readonly property real ramTotal: unit.onboard_ram_total_mib / 1024
    function open_dialoque(system) { open() }
    function chemistryChanged(index) {
        settings.ground_battery_type = index
        var limits = [[33, 37, 42], [27, 34, 42], [31, 35, 37]]
        if (index < limits.length) {
            settings.ground_battery_low = limits[index][0]
            settings.ground_battery_mid = limits[index][1]
            settings.ground_battery_full = limits[index][2]
        }
    }
    function channelText() {
        if (!live || unit.wifi_hotspot_frequency <= 0) return unavailable
        var frequency = unit.wifi_hotspot_frequency
        var channel = frequency === 2484 ? 14 : frequency < 2500 ? (frequency - 2407) / 5 : (frequency - 5000) / 5
        return qsTr("%1 (%2 GHz)").arg(channel).arg(frequency < 2500 ? "2.4" : "5")
    }
    background: Rectangle { radius: 16 * dialog.uiScale; color: "#041d2c"; border.color: "#0089c4" }
    contentItem: Item {
        Item {
            id: canvas
            width: 1080; height: 800
            scale: dialog.uiScale; transformOrigin: Item.TopLeft
            Text { x: 36; y: 32; text: qsTr("Ground Station Details"); font.family: "Archivo"; font.pixelSize: 28; font.bold: true; color: "#edf4fa" }
            ToolButton {
                objectName: "groundDetailsClose"
                x: 1016; y: 22; width: 44; height: 44
                text: "\uf00d"; font.family: "Font Awesome 5 Free"; font.pixelSize: 26
                Accessible.name: qsTr("Close ground station details")
                onClicked: dialog.close()
                background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? "#153c53" : "transparent" }
                contentItem: Text { text: parent.text; font: parent.font; color: "#edf4fa"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Rectangle {
                id: resourcePanel
                x: 22; y: 96; width: 516; height: 340; radius: 14
                color: "#051f2f"; border.color: "#0d4059"
                Text { x: 24; y: 21; text: "\uf2db"; font.family: "Font Awesome 5 Free"; font.pixelSize: 28; color: "#bbd9ec" }
                Text { x: 74; y: 23; text: qsTr("System Resources"); font.family: "Archivo"; font.pixelSize: 21; font.bold: true; color: "#edf4fa" }
                Repeater {
                    model: [
                        {label: qsTr("CPU Usage"), icon: "\uf2db", value: dialog.live && (unit.onboard_uptime_ms >= 0 || unit.curr_soc_temp_degree > 0) ? unit.curr_cpuload_perc + " %" : dialog.unavailable},
                        {label: qsTr("RAM Usage"), icon: "\uf538", value: dialog.ramPercent >= 0 && dialog.ramTotal > 0 ? (dialog.ramTotal * dialog.ramPercent / 100 / 1024).toFixed(1) + " GB / " + (dialog.ramTotal / 1024).toFixed(1) + " GB (" + dialog.ramPercent + " %)" : dialog.unavailable},
                        {label: qsTr("Storage (System)"), icon: "\uf0a0", value: dialog.details.system_total_bytes > 0 ? dialog.storageText("system") : dialog.live && unit.curr_space_left_mb > 0 ? qsTr("%1 GiB free").arg((unit.curr_space_left_mb / 1024).toFixed(1)) : dialog.unavailable},
                        {label: qsTr("Storage (Logs)"), icon: "\uf15c", value: dialog.storageText("logs")}
                    ]
                    Item {
                        x: 16; y: 62 + index * 58; width: resourcePanel.width - 32; height: 58
                        Rectangle { width: parent.width; height: 1; color: "#11384b" }
                        Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#d5e8f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                        Text { x: 62; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }
                        Text { anchors.right: parent.right; anchors.rightMargin: 4; y: index >= 2 ? 11 : 19; text: modelData.value; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }

                    }
                }
            }
            Rectangle {
                id: network
                x: 556; y: 96; width: 502; height: 340; radius: 14
                color: "#051f2f"; border.color: "#0d4059"
                Text { x: 24; y: 21; text: "\uf1eb"; font.family: "Font Awesome 5 Free"; font.pixelSize: 28; color: "#009fff" }
                Text { x: 74; y: 23; text: qsTr("Network / Hotspot"); font.family: "Archivo"; font.pixelSize: 21; font.bold: true; color: "#edf4fa" }
                Repeater {
                    model: [
                        {label: qsTr("Hotspot Mode"), icon: "\uf1eb", value: ""},
                        {label: qsTr("Hotspot Channel"), icon: "\uf012", value: ""},
                        {label: qsTr("Connected Clients"), icon: "\uf0c0", value: dialog.details.hotspot_clients !== undefined ? String(dialog.details.hotspot_clients) : dialog.unavailable},
                        {label: qsTr("Local IP (Hotspot)"), icon: "\uf0e8", value: dialog.details.hotspot_ip || dialog.unavailable},
                        {label: qsTr("Public IP (WAN)"), icon: "\uf0ac", value: dialog.details.public_ip || dialog.unavailable}
                    ]
                    Item {
                        x: 16; y: 62 + index * 53; width: network.width - 32; height: 53
                        Rectangle { width: parent.width; height: 1; color: "#11384b" }
                        Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#d5e8f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                        Text { x: 62; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }
                        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }
                    }
                }
                Row {
                    x: 240; y: 69; spacing: 0
                    Repeater {
                        model: [{label: qsTr("Off"), value: 1}, {label: qsTr("On"), value: 2}, {label: qsTr("Auto"), value: 0}]
                        Button {
                            objectName: "groundHotspotMode" + modelData.value
                            width: 80; height: 44
                            enabled: dialog.hotspotWritable
                            text: modelData.label
                            onClicked: params.try_set_param_int_async("WIFI_HOTSPOT_E", modelData.value, true)
                            background: Rectangle { radius: 7; color: dialog.hotspotMode === modelData.value ? "#009cff" : "#062b42"; border.color: "#006997" }
                            contentItem: Text { text: parent.text; color: parent.enabled ? "#edf4fa" : "#7694a7"; font.family: "Archivo"; font.pixelSize: 19; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
                DarkComboBox {
                    id: channelCombo
                    popupScale: dialog.uiScale
                    objectName: "groundHotspotChannel"
                    indicator: Text { x: channelCombo.width - 28; anchors.verticalCenter: parent.verticalCenter; text: "\uf078"; color: "#7694a7"; font.family: "Font Awesome 5 Free"; font.pixelSize: 14 }
                    x: 288; y: 122; width: 192; height: 44
                    model: [dialog.channelText()]
                    enabled: false // Current firmware selects this automatically and has no channel parameter.
                    background: Rectangle { color: "#06263a"; radius: 7; border.color: "#006997" }
                    contentItem: Text { text: parent.displayText; leftPadding: 12; color: "#a9c2d3"; font.family: "Archivo"; font.pixelSize: 18; verticalAlignment: Text.AlignVCenter }
                }
            }
            Rectangle {
                id: battery
                x: 22; y: 454; width: 1036; height: 236; radius: 14
                color: "#051f2f"; border.color: "#0d4059"
                Text { x: 24; y: 19; text: "\uf2c2"; font.family: "Font Awesome 5 Free"; font.pixelSize: 28; color: "#d5e8f5" }
                Text { x: 74; y: 21; text: qsTr("Battery Configuration"); font.family: "Archivo"; font.pixelSize: 21; font.bold: true; color: "#edf4fa" }
                Rectangle { x: 16; y: 56; width: parent.width - 32; height: 1; color: "#11384b" }
                Repeater {
                    model: [{label: qsTr("Battery Chemistry"), icon: "\uf0ae"}, {label: qsTr("Capacity"), icon: "\uf2c2"}, {label: qsTr("Cell Count"), icon: "\uf009"}]
                    Item {
                        x: 24; y: 64 + index * 54; height: 44
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#d5e8f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                        Text { x: 68; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }
                    }
                }
                DarkComboBox {
                    id: chemistryCombo
                    objectName: "groundBatteryChemistry"

                    x: 310; y: 64; width: 200; height: 44
                    model: ["Li-Po", "Li-Ion", "LiFe", qsTr("Custom")]
                    currentIndex: settings.ground_battery_type
                    enabled: !dialog.preview
                    onActivated: dialog.chemistryChanged(currentIndex)
                    font.pixelSize: 18
                    popupWidth: 270
                    popupScale: dialog.uiScale
                    optionDetails: [
                        {icon: "\uf243", color: "#28adf1", description: qsTr("Lithium Polymer")},
                        {icon: "\uf243", color: "#58bd8b", description: qsTr("Lithium Ion")},
                        {icon: "\uf243", color: "#f3c653", description: qsTr("Lithium Iron Phosphate")},
                        {icon: "\uf013", color: "#ac7bed", description: qsTr("User defined parameters")}
                    ]
                }
                TextField {
                    objectName: "groundBatteryCapacity"
                    x: 310; y: 118; width: 148; height: 44
                    text: settings.ground_battery_capacity_mah > 0 ? settings.ground_battery_capacity_mah.toString() : ""
                    placeholderText: qsTr("Not set")
                    enabled: !dialog.preview
                    validator: IntValidator { bottom: 1; top: 1000000 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    onEditingFinished: if (acceptableInput) settings.ground_battery_capacity_mah = parseInt(text, 10)
                    color: "#edf4fa"; font.family: "Archivo"; font.pixelSize: 18
                    background: Rectangle { color: "#06263a"; radius: 7; border.color: parent.activeFocus ? "#21b1ff" : "#006997" }
                }
                Text { x: 470; y: 130; text: "mAh"; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: 18 }
                SpinBox {
                    id: cellCount
                    objectName: "groundBatteryCells"
                    up.indicator: Text { x: cellCount.width - 30; y: 0; width: 30; height: 22; text: "\uf077"; color: "#d5e8f5"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "Font Awesome 5 Free"; font.pixelSize: 13 }
                    down.indicator: Text { x: cellCount.width - 30; y: 22; width: 30; height: 22; text: "\uf078"; color: "#d5e8f5"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "Font Awesome 5 Free"; font.pixelSize: 13 }
                    x: 310; y: 172; width: 132; height: 44
                    from: 1; to: 16; value: settings.ground_battery_cells
                    enabled: !dialog.preview
                    onValueModified: settings.ground_battery_cells = value
                    background: Rectangle { color: "#06263a"; radius: 7; border.color: "#006997" }
                    contentItem: Text { text: parent.value; leftPadding: 14; color: "#edf4fa"; font.family: "Archivo"; font.pixelSize: 18; verticalAlignment: Text.AlignVCenter }
                }
            }
            Rectangle { x: 22; y: 708; width: 1036; height: 1; color: "#115071" }
            Repeater {
                model: [{label: qsTr("Reboot"), reboot: true}, {label: qsTr("Shutdown"), reboot: false}]
                Button {
                    objectName: modelData.reboot ? "groundDetailsReboot" : "groundDetailsShutdown"
                    x: 22 + index * 528; y: 724; width: 508; height: 58
                    enabled: dialog.live && !dialog.preview
                    onClicked: { dialog.close(); statusPanel.open_power_action_dialoque(0, modelData.reboot) }
                    background: Rectangle { radius: 12; color: index === 0 ? "#063552" : "#8d1e2a"; border.color: index === 0 ? "#006a9a" : "#a42c37"; opacity: parent.enabled ? 1 : 0.45 }
                    contentItem: Item {
                      Row {
                        anchors.centerIn: parent
                        spacing: 20
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf011"; color: "#edf4fa"; font.family: "Font Awesome 5 Free"; font.pixelSize: 25 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#edf4fa"; font.family: "Archivo"; font.pixelSize: 20 }
                      }
                    }
                }
            }
        }
    }
    onClosed: if (statusPanel.visible) statusPanel.gainFocus()
}
