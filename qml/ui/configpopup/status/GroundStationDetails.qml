import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../elements"

Popup {
    id: dialog
    objectName: systemType === 0 ? "groundStationDetailsPopup" : "airUnitDetailsPopup"
    property int systemType: 0
    readonly property bool isGround: systemType === 0
    readonly property real designHeight: 800
    readonly property string batteryPrefix: "ground_battery_"
    parent: Overlay.overlay
    anchors.centerIn: parent
    readonly property real uiScale: Math.min(1, (parent.width - 24) / 1080, (parent.height - 24) / designHeight)
    width: 1080 * uiScale
    height: designHeight * uiScale
    padding: 0
    modal: true; dim: true; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#af000b12" }
    readonly property var unit: isGround ? _ohdSystemGround : _ohdSystemAir
    readonly property var params: isGround ? _ohdSystemGroundSettings : _ohdSystemAirSettingsModel
    readonly property bool preview: _qopenhd.debugMenuPreview
    readonly property bool live: unit.is_alive
    readonly property bool hotspotWritable: !preview && live && !params.ui_is_busy && params.has_params_fetched && params.param_int_exists("WIFI_HOTSPOT_E")
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
    function open_dialoque(system) { systemType = system; open() }
    function chemistryChanged(index) {
        settings[batteryPrefix + "type"] = index
        var limits = [[33, 37, 42], [27, 34, 42], [31, 35, 37]]
        if (index < limits.length) {
            settings[batteryPrefix + "low"] = limits[index][0]
            settings[batteryPrefix + "mid"] = limits[index][1]
            settings[batteryPrefix + "full"] = limits[index][2]
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
            width: 1080; height: dialog.designHeight
            scale: dialog.uiScale; transformOrigin: Item.TopLeft
            Text { x: 36; y: 32; text: dialog.isGround ? qsTr("Ground Station Details") : qsTr("Air Unit Details"); font.family: "Archivo"; font.pixelSize: MenuTypography.pageTitle; font.bold: true; color: "#edf4fa" }
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
                Text { x: 74; y: 23; text: qsTr("System Resources"); font.family: "Archivo"; font.pixelSize: MenuTypography.sectionTitle; font.bold: true; color: "#edf4fa" }
                Repeater {
                    model: [
                        {label: qsTr("CPU Usage"), icon: "\uf2db", value: dialog.live && (unit.onboard_uptime_ms >= 0 || unit.curr_soc_temp_degree > 0) ? unit.curr_cpuload_perc + " %" : dialog.unavailable},
                        {label: qsTr("RAM Usage"), icon: "\uf538", value: dialog.ramPercent >= 0 && dialog.ramTotal > 0 ? (dialog.ramTotal * dialog.ramPercent / 100 / 1024).toFixed(1) + " GB / " + (dialog.ramTotal / 1024).toFixed(1) + " GB (" + dialog.ramPercent + " %)" : dialog.unavailable},
                        {label: qsTr("Storage (System)"), icon: "\uf0a0", value: dialog.details.system_total_bytes > 0 ? dialog.storageText("system") : dialog.live && unit.curr_space_left_mb > 0 ? qsTr("%1 GiB free").arg((unit.curr_space_left_mb / 1024).toFixed(1)) : dialog.unavailable}
                    ]
                    Item {
                        x: 16; y: 62 + index * 58; width: resourcePanel.width - 32; height: 58
                        Rectangle { width: parent.width; height: 1; color: "#11384b" }
                        Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#d5e8f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                        Text { x: 62; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                        Text { anchors.right: parent.right; anchors.rightMargin: 4; y: index >= 2 ? 11 : 19; text: modelData.value; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }

                    }
                }
            }
            Rectangle {
                id: network
                x: 556; y: 96; width: 502; height: 340; radius: 14
                color: "#051f2f"; border.color: "#0d4059"
                Text { x: 24; y: 21; text: "\uf1eb"; font.family: "Font Awesome 5 Free"; font.pixelSize: 28; color: "#009fff" }
                Text { x: 74; y: 23; text: qsTr("Network / Hotspot"); font.family: "Archivo"; font.pixelSize: MenuTypography.sectionTitle; font.bold: true; color: "#edf4fa" }
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
                        Text { x: 62; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                    }
                }
                Row {
                    x: 240; y: 69; spacing: 0
                    Repeater {
                        model: [{label: qsTr("Off"), value: 1}, {label: qsTr("On"), value: 2}, {label: qsTr("Auto"), value: 0}]
                        Button { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            objectName: "groundHotspotMode" + modelData.value
                            width: 80; height: 44
                            enabled: dialog.hotspotWritable
                            text: modelData.label
                            onClicked: params.try_set_param_int_async("WIFI_HOTSPOT_E", modelData.value, true)
                            background: Rectangle { radius: 7; color: dialog.hotspotMode === modelData.value ? "#009cff" : "#062b42"; border.color: "#006997" }
                            contentItem: Text { text: parent.text; color: parent.enabled ? "#edf4fa" : "#7694a7"; font.family: "Archivo"; font.pixelSize: MenuTypography.body; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
                Text {
                    objectName: "groundHotspotChannel"
                    enabled: false
                    x: 288; y: 122; width: 192; height: 44
                    text: dialog.channelText()
                    color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body
                    horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 74; y: 47; width: 410; height: 14
                    text: !dialog.live ? qsTr("Unit disconnected")
                        : params.last_updated_param_id === "WIFI_HOTSPOT_E" && params.last_updated_param_success === false ? qsTr("Hotspot update failed - retry")
                        : params.ui_is_busy ? qsTr("Applying hotspot setting...")
                        : unit.wifi_hotspot_state === 2 ? qsTr("Hotspot active - channel selected automatically")
                        : unit.wifi_hotspot_state === 1 ? qsTr("Hotspot off - Auto turns it off while armed")
                        : qsTr("No hotspot adapter reported")
                    font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; color: "#a9c2d3"; elide: Text.ElideRight
                }
            }
            Rectangle {
                id: battery
                visible: dialog.isGround
                x: 22; y: 454; width: 1036; height: 236; radius: 14
                color: "#051f2f"; border.color: "#0d4059"
                Text { x: 24; y: 19; text: "\uf2c2"; font.family: "Font Awesome 5 Free"; font.pixelSize: 28; color: "#d5e8f5" }
                Text { x: 74; y: 21; text: qsTr("Battery Configuration"); font.family: "Archivo"; font.pixelSize: MenuTypography.sectionTitle; font.bold: true; color: "#edf4fa" }
                Rectangle { x: 16; y: 56; width: parent.width - 32; height: 1; color: "#11384b" }
                Repeater {
                    model: [{label: qsTr("Battery Chemistry"), icon: "\uf0ae"}, {label: qsTr("Capacity"), icon: "\uf2c2"}, {label: qsTr("Cell Count"), icon: "\uf009"}]
                    Item {
                        x: 24; y: 64 + index * 54; height: 44
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#d5e8f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 27 }
                        Text { x: 68; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#dce7f0"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                    }
                }
                DarkComboBox {
                    id: chemistryCombo
                    objectName: "groundBatteryChemistry"

                    x: 310; y: 64; width: 200; height: 44
                    model: ["Li-Po", "Li-Ion", "LiFe"]
                    currentIndex: settings[dialog.batteryPrefix + "type"] >= 0 && settings[dialog.batteryPrefix + "type"] < count ? settings[dialog.batteryPrefix + "type"] : -1
                    displayText: currentIndex >= 0 ? currentText : qsTr("Choose chemistry")
                    enabled: !dialog.preview
                    onActivated: dialog.chemistryChanged(currentIndex)
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    popupWidth: 270
                    popupScale: dialog.uiScale
                    optionDetails: [
                        {icon: "\uf243", color: "#28adf1", description: qsTr("Lithium Polymer")},
                        {icon: "\uf243", color: "#58bd8b", description: qsTr("Lithium Ion")},
                        {icon: "\uf243", color: "#f3c653", description: qsTr("Lithium Iron Phosphate")}
                    ]
                }
                DarkComboBox {
                    id: capacityCombo
                    objectName: "groundBatteryCapacity"
                    x: 310; y: 118; width: 200; height: 44
                    readonly property var capacities: {
                        var values = [500, 650, 850, 1000, 1300, 1500, 1800, 2200, 2600, 3000,
                                      3300, 3500, 4000, 4500, 5000, 5200, 6000, 6600, 7000, 8000,
                                      10000, 12000, 16000, 20000, 22000, 24000, 30000]
                        var saved = settings[dialog.batteryPrefix + "capacity_mah"]
                        if (saved > 0 && values.indexOf(saved) < 0) {
                            values.push(saved)
                            values.sort(function(a,b) { return a-b })
                        }
                        return values
                    }
                    model: capacities.map(function(value) { return value + " mAh" })
                    currentIndex: capacities.indexOf(settings[dialog.batteryPrefix + "capacity_mah"])
                    displayText: currentIndex >= 0 ? currentText : qsTr("Choose capacity")
                    optionIcon: "\uf243"
                    optionDescription: qsTr("Rated battery pack capacity")
                    enabled: !dialog.preview
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    popupWidth: 270; popupScale: dialog.uiScale
                    onActivated: settings[dialog.batteryPrefix + "capacity_mah"] = capacities[index]
                }
                DarkComboBox {
                    id: cellCount
                    objectName: "groundBatteryCells"
                    x: 310; y: 172; width: 200; height: 44
                    model: ["2S", "3S", "4S", "5S", "6S", "7S", "8S"]
                    currentIndex: {
                        var cells = settings[dialog.batteryPrefix + "cells"]
                        return cells >= 2 && cells <= 8 ? cells - 2 : -1
                    }
                    displayText: currentIndex >= 0 ? currentText : qsTr("Choose cell count")
                    optionIcon: "\uf009"
                    optionDetails: {
                        var chemistry = settings[dialog.batteryPrefix + "type"]
                        var nominalCellVoltage = [3.7, 3.6, 3.2]
                        return [2,3,4,5,6,7,8].map(function(cells) {
                            return {description: chemistry === 0
                                ? qsTr("%1-%2 V - discharge to full").arg((cells * 3.5).toFixed(1)).arg((cells * 4.2).toFixed(1))
                                : chemistry === 1
                                  ? qsTr("%1-%2 V - discharge to full").arg((cells * 2.5).toFixed(1)).arg((cells * 4.2).toFixed(1))
                                  : chemistry >= 0 && chemistry < nominalCellVoltage.length
                                    ? qsTr("%1 V nominal").arg((cells * nominalCellVoltage[chemistry]).toFixed(1))
                                  : qsTr("Select chemistry for voltage")}

                        })
                    }
                    enabled: !dialog.preview
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    popupWidth: 270; popupScale: dialog.uiScale
                    onActivated: settings[dialog.batteryPrefix + "cells"] = index + 2
                }
            }
            Rectangle {
                id: camerasPanel
                objectName: "airCamerasPanel"
                visible: !dialog.isGround
                x: 22; y: 454; width: 1036; height: 236; radius: 14
                color: "#041e2d"; border.color: "#12607e"
                readonly property int reportedCount: !dialog.live ? 0
                    : ((typeof _cameraStreamModelPrimary !== "undefined" && _cameraStreamModelPrimary.camera_status >= 0) ? 1 : 0)
                    + ((typeof _cameraStreamModelSecondary !== "undefined" && _cameraStreamModelSecondary.camera_status >= 0) ? 1 : 0)
                Text { x: 24; y: 16; text: "\uf030"; font.family: "Font Awesome 5 Free"; font.pixelSize: 26; color: "#d5e8f5" }
                Text { x: 74; y: 18; text: qsTr("Camera Status"); font.family: "Archivo"; font.pixelSize: MenuTypography.sectionTitle; font.bold: true; color: "#edf4fa" }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 18; y: 16; width: countLabel.implicitWidth + 20; height: 28; radius: 7
                    color: "#052536"; border.color: "#10526c"
                    Text { id: countLabel; anchors.centerIn: parent; text: qsTr("%1 Cameras").arg(camerasPanel.reportedCount); font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; color: "#65bce8" }
                }
                Rectangle { x: 16; y: 54; width: parent.width - 32; height: 1; color: "#114357" }
                Repeater {
                    model: 2
                    Rectangle {
                        id: camera
                        readonly property int streamIndex: index
                        x: 16 + index * 510; y: 66; width: 494; height: 156; radius: 12
                        color: "#041c2a"; border.color: "#113e52"
                        readonly property var stream: index === 0
                            ? (typeof _cameraStreamModelPrimary !== "undefined" ? _cameraStreamModelPrimary : null)
                            : (typeof _cameraStreamModelSecondary !== "undefined" ? _cameraStreamModelSecondary : null)
                        readonly property bool reported: dialog.live && stream && stream.camera_status >= 0
                        readonly property string cameraName: {
                            if (!reported || !(stream.camera_type >= 0)) return dialog.unavailable
                            var name = stream.camera_type_to_string(stream.camera_type)
                            return name && name !== "N/A" ? name : dialog.unavailable
                        }
                        readonly property string cameraStatus: !reported ? dialog.unavailable
                            : stream.camera_status === 3 ? qsTr("Disabled")
                            : stream.camera_status === 1 ? qsTr("Streaming")
                            : stream.camera_status === 2 ? qsTr("Restarting") : qsTr("Not streaming")
                        readonly property color statusColor: !reported || stream.camera_status === 3 ? "#94a9b9"
                            : stream.camera_status === 1 ? "#49d77b" : stream.camera_status === 2 ? "#ff5c69" : "#f0bb67"
                        readonly property string videoFormat: {
                            if (!reported || !stream.curr_set_video_format) return dialog.unavailable
                            var match = String(stream.curr_set_video_format).match(/^(\d+)x(\d+)@(\d+(?:\.\d+)?)$/)
                            return match ? qsTr("%1 x %2 @ %3 FPS").arg(match[1]).arg(match[2]).arg(match[3]) : stream.curr_set_video_format
                        }
                        readonly property string codec: {
                            if (!reported) return dialog.unavailable
                            if (stream.encoding_codec === 0) return "H.264"
                            if (stream.encoding_codec === 1) return "H.265"
                            if (stream.encoding_codec === 2) return "MJPEG"
                            return dialog.unavailable
                        }
                        Text { x: 16; y: 10; text: "\uf030"; font.family: "Font Awesome 5 Free"; font.pixelSize: 20; color: "#d5e8f5" }
                        Text { x: 48; y: 10; text: qsTr("Camera %1").arg(camera.streamIndex + 1); font.family: "Archivo"; font.bold: true; font.pixelSize: MenuTypography.sectionTitle; color: "#edf4fa" }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 14; y: 7; height: 26; width: badgeText.implicitWidth + 30; radius: 10
                            color: "#082a31"; border.color: camera.statusColor
                            Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: camera.statusColor }
                            Text { id: badgeText; objectName: "airCamera" + camera.streamIndex + "Status"; x: 24; anchors.verticalCenter: parent.verticalCenter; text: camera.cameraStatus; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; color: camera.statusColor }
                        }
                        Rectangle { x: 1; y: 39; width: parent.width - 2; height: 1; color: "#11384b" }
                        Column {
                            x: 14; y: 40; width: parent.width - 28; spacing: 0
                            Repeater {
                                model: [
                                    {label: qsTr("Camera"), icon: "\uf2db", value: camera.cameraName},
                                    {label: qsTr("Video format"), icon: "\uf03d", value: camera.videoFormat},
                                    {label: qsTr("Encoder format"), icon: "\uf013", value: camera.codec},
                                    {label: qsTr("Encoder bitrate"), icon: "\uf012", value: camera.reported && camera.stream.curr_video_measured_encoder_bitrate_bps > 0 ? qsTr("%1 Mbit/s").arg((camera.stream.curr_video_measured_encoder_bitrate_bps / 1000000).toFixed(1)) : dialog.unavailable}
                                ]
                                Item {
                                    width: camera.width - 28; height: 27
                                    Text { x: 4; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: "#b8d9ec"; font.family: "Font Awesome 5 Free"; font.pixelSize: 17 }
                                    Text { x: 36; anchors.verticalCenter: parent.verticalCenter; width: 132; text: modelData.label; color: "#94b3c5"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                                    Text { objectName: "airCamera" + camera.streamIndex + "Value" + index; anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 180; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; text: modelData.value; color: "#e0edf6"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                                    Rectangle { x: 36; y: parent.height - 1; width: parent.width - 40; height: 1; visible: index < 3; color: "#11384b" }
                                }
                            }
                        }
                    }
                }
            }
            Rectangle { x: 22; y: 708; width: 1036; height: 1; color: "#115071" }
            Repeater {
                model: [{label: qsTr("Reboot"), reboot: true}, {label: qsTr("Shutdown"), reboot: false}]
                Button { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    objectName: modelData.reboot ? "groundDetailsReboot" : "groundDetailsShutdown"
                    x: 22 + index * 528; y: 724; width: 508; height: 58
                    enabled: dialog.live && !dialog.preview
                    onClicked: { dialog.close(); statusPanel.open_power_action_dialoque(dialog.systemType, modelData.reboot) }
                    background: Rectangle { radius: 12; color: index === 0 ? "#063552" : "#8d1e2a"; border.color: index === 0 ? "#006a9a" : "#a42c37"; opacity: parent.enabled ? 1 : 0.45 }
                    contentItem: Item {
                      Row {
                        anchors.centerIn: parent
                        spacing: 20
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf011"; color: "#edf4fa"; font.family: "Font Awesome 5 Free"; font.pixelSize: 25 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "#edf4fa"; font.family: "Archivo"; font.pixelSize: MenuTypography.body }
                      }
                    }
                }
            }
        }
    }
    onClosed: if (statusPanel.visible) statusPanel.gainFocus()
}
