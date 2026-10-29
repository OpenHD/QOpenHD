import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/status" as Status

Item {
    id: scene
    FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
    FontLoader { source: "../../qml/osdfonts/Archivo-Regular.ttf" }
    FontLoader { source: "../../qml/osdfonts/Archivo-Bold.ttf" }
    width: 960; height: 720
    FontLoader { id: testFont; source: Qt.platform.os === "windows" ? "file:///C:/Windows/Fonts/segoeui.ttf" : "" }
    Component.onCompleted: if (testFont.status === FontLoader.Ready) Qt.application.font = Qt.font({family: testFont.name, pixelSize: 13})
    QtObject {
        id: settings_form
        property color accentColor: "#43a1ff"
        property color pageBackground: "#101824"
        property color panelBackground: "#192536"
        property color primaryText: "#eef4ff"
        property color secondaryText: "#96a8bf"
        property color goodColor: "#65d99b"
        property color errorColor: "#ff6060"
        property color lineColor: "#304057"
    }
    QtObject {
        id: statusPanel
        function syncFocus(item) {}
        function moveFocus(step) {}
    }
    QtObject { id: settings; property bool set_mavlink_message_rates: true }
    QtObject {
        id: _mavlinkTelemetry
        property int rateRequests: 0
        function re_apply_rates() { rateRequests++ }
    }
    QtObject {
        id: _qopenhd
        property string toast: ""
        function show_toast(message) { toast = message }
    }
    QtObject { id: _ohdSystemAir; property int wifi_hotspot_state: 0 }
    QtObject { id: _ohdSystemGround; property int wifi_hotspot_state: 0 }
    QtObject {
        id: _ohdSystemAirSettingsModel
        property bool has_params_fetched: true
        property int requestedHotspot: -1
        function param_int_exists(id) { return id === "WIFI_HOTSPOT_E" }
        function try_set_param_int_async(id, value, log) { requestedHotspot = value }
    }
    property var _ohdSystemGroundSettings: _ohdSystemAirSettingsModel
    Component {
        id: craftCard
        Status.StatusCard {
            width: 300; height: 319
            title: "Flight controller"; systemType: 2; alive: true; actionsAvailable: false
            bodyComponent: Component { Item { implicitHeight: 204 } }
        }
    }
    Component {
        id: compactStatusBody
        Column {
            objectName: "compactStatusBody"
            width: parent.width
            spacing: 1
            property int rowCount: 4
            property bool extraBadge: false
            Item { width: parent.width; height: 29; visible: parent.extraBadge }
            Repeater {
                model: parent.rowCount
                Status.StatusCardRow {
                    m_left_text: ["Platform:", "Version:", "Link:", "System health:", "Shared:"][index]
                    m_right_text: ["RPI 4", "3.0.0-evo", "Devourer RTL8822C", "51 ?C ? 1% CPU", "1x"][index]
                }
            }
        }
    }
    SignalSpy { id: cardSpy; signalName: "detailsRequested" }
    QtObject {
        id: mock
        property int diagnosticsViewers: 0
        function acquire_diagnostics() { diagnosticsViewers++ }
        function release_diagnostics() { diagnosticsViewers-- }
        property bool is_alive: true
        property bool telemetry_active: true
        property string autopilot_type_str: "Generic"
        property string mav_type_str: "Quadrotor"
        property int for_osd_sys_id: 1
        property bool armed: false
        property string flight_mode: "ANGLE"
        property real roll: 3.5
        property real pitch: 2.7
        property real hdg: 21.3
        property real battery_voltage_volt: 12.06
        property int battery_percent: 80
        property int gps_fix_type: 1
        property string gps_status_fix_type_str: "No fix"
        property int satellites_visible: 0
        property real gps_hdop: 99.99
        property real ground_speed_meter_per_second: 0
        property real altitude_rel_m: 0
        property int rc_rssi_percentage: 0
        property var firmware_identity: ({type: 3, name: "INAV", confidence: "likely", evidence: "Empty PARAM_VALUE signature; likely INAV", ver: 0})
        property var remote_id_status: ({})
        property var battery_capacity_parameter: ({})
        property var craft_diagnostics: ({
            heartbeatAge: 0.2, statusAge: 0.2, load: 11.5, total: 128, nowMs: 10000,
            autopilotId: 0, vehicleTypeId: 2, customMode: 22,
            observed: {
                roll: {value: 3.5, receivedMs: 9900}, pitch: {value: 2.7, receivedMs: 9900},
                heading: {value: 21.3, receivedMs: 9900}, packVoltage: {value: 12.06, receivedMs: 9900},
                batteryPercent: {value: 80, receivedMs: 9900}, load: {value: 11.5, receivedMs: 9900},
                gpsFix: {value: 1, receivedMs: 9900}, satellites: {value: 0, receivedMs: 9900},
                rcRssi: {value: 0, receivedMs: 9900}, sensorTemperature: {value: 49.8, receivedMs: 9900}
            },
            sensors: [{name: "Compass", enabled: true, healthy: true}, {name: "RC receiver", enabled: true, healthy: false}],
            events: [{text: "COMPASS NOT CALIBRATED", severity: 5, count: 14, receivedMs: 9000}, {text: "UNABLE TO ARM", severity: 4, count: 12, receivedMs: 8000}],
            messages: [{id: 0, name: "HEARTBEAT", rate: 2, count: 30, age: 0.2, component: 1, payload: "16 00 00 00 02 00 51 02 03", fields: [{name: "custom_mode", value: "22"}, {name: "type", value: "2"}, {name: "autopilot", value: "0"}]},
                       {id: 30, name: "ATTITUDE", rate: 2, count: 30, age: 0.2, component: 1, payload: "59 ec 24 00 dd 35 7a 3d 17 2b 48 3d ed 71 bd 3e"}]
        })
    }
    Rectangle { anchors.fill: parent; color: settings_form.pageBackground }
    QtObject {
        id: mockAction
        property int requestedCapacity: 0
        property int rebootRequests: 0
        function send_command_reboot(flightController) { if (flightController) rebootRequests++ }
        property bool remote_id_busy: false
        property string requestedRemoteId: ""
        property bool requestedOperatorId: false
        function set_remote_id_async(isOperator, value) { requestedOperatorId=isOperator; requestedRemoteId=value }
        function set_battery_capacity_async(value) { requestedCapacity = value }
    }
    Status.CraftDetailsPanel { id: panel; anchors.fill: parent; fc: mock; fcAction: mockAction }
    Component { id: inspectorFactory; Status.CraftDetailsPanel { fc: mock; fcAction: mockAction } }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "CraftDetails"
        when: windowShown
        function test_small_confirmation_style_and_action() {
            mock.telemetry_active = true; mock.is_alive = true; mock.armed = false
            var dialog = findChild(panel, "craftRebootDialog")
            verify(dialog !== null)
            var before = mockAction.rebootRequests
            dialog.open()
            tryCompare(dialog, "opened", true)
            compare(String(dialog.background.color), "#041d2c")
            compare(String(dialog.background.border.color), "#0089c4")
            verify(dialog.width <= 420)
            verify(dialog.height < 300)
            verify(dialog.x >= 0 && dialog.y >= 0)
            verify(dialog.x + dialog.width <= scene.width)
            verify(dialog.y + dialog.height <= scene.height)
            var confirm = findChild(panel, "craftRebootConfirm")
            verify(confirm.enabled); verify(confirm.destructive)
            wait(100)
            var captured = false
            verify(scene.parent.grabToImage(function(shot) {
                verify(shot.saveToFile(Qt.resolvedUrl("../../build/craft-reboot-confirmation.png").toString().replace("file:///", "")))
                captured = true
            }))
            tryVerify(function() { return captured })
            dialog.reject()
            tryCompare(dialog, "visible", false)
            compare(mockAction.rebootRequests, before)
            dialog.open(); tryCompare(dialog, "opened", true)
            mock.armed = true
            verify(!confirm.enabled)
            dialog.accept()
            compare(mockAction.rebootRequests, before)
            mock.armed = false
            dialog.open(); tryCompare(dialog, "opened", true)
            mouseClick(confirm)
            tryCompare(mockAction, "rebootRequests", before + 1)
            dialog.close()
        }
        function test_diagnostic_subscription_lifecycle() {
            compare(mock.diagnosticsViewers, 1)
            panel.visible = false
            compare(mock.diagnosticsViewers, 0)
            panel.visible = true
            compare(mock.diagnosticsViewers, 1)
            var other = inspectorFactory.createObject(scene)
            compare(mock.diagnosticsViewers, 2)
            other.visible = false
            compare(mock.diagnosticsViewers, 1)
            other.visible = true
            compare(mock.diagnosticsViewers, 2)
            other.destroy()
            tryCompare(mock, "diagnosticsViewers", 1)
        }
        function test_remote_id_card() {
            mock.telemetry_active=true;mock.armed=false
            mock.remote_id_status={aircraftId: "FC-BOARD-ID", idType: 1, locationReceivedMs: 9900}
            wait(50)
            var card=findChild(panel,"craftRemoteIdCard")
            verify(card!==null)
            verify(panel.remoteIdStatus().indexOf("ready") < 0)
            panel.openRemoteId();wait(200)
            var dialog=findChild(panel,"craftRemoteIdDialog")
            tryCompare(dialog, "opened", true)
            verify(!findChild(panel,"craftRemoteAircraftId").visible)
            var readonlyImage=grabImage(scene)
            if (readonlyImage.width > 0) readonlyImage.save("QOpenHD/build/remote-id-readonly.png")
            dialog.close()
            mock.remote_id_status={aircraftId: "MODULE-ID", armStatus: 0, armStatusReceivedMs: 9900,
                operatorParameter: {id: "OPERATOR_ID", value: "OLD-ID", sys: 1, comp: 236, type: 11}}
            panel.openRemoteId();wait(200)
            var input=findChild(panel,"craftRemoteOperatorId")
            verify(input.visible);input.text="NEW-ID"
            var editorImage=grabImage(scene)
            if (editorImage.width > 0) editorImage.save("QOpenHD/build/remote-id-editor.png")
            var save=findChild(panel,"craftRemoteOperatorIdSave")
            verify(save.enabled);mouseClick(save)
            compare(mockAction.requestedRemoteId,"NEW-ID");verify(mockAction.requestedOperatorId)
            mock.remote_id_status={operatorParameter: {id: "OPERATOR_ID", value: "OLD-ID"}, locationReceivedMs: 9990}
            wait(20);compare(input.text,"NEW-ID")
            mock.armed=true;verify(!save.enabled)
            mock.armed=false;mock.telemetry_active=false;verify(!save.enabled)
            dialog.close();mock.telemetry_active=true;mock.remote_id_status={}
        }
        function test_battery_capacity_card() {
            var savedDiagnostics = mock.craft_diagnostics
            mock.telemetry_active = true
            mock.armed = false
            mock.craft_diagnostics = {nowMs: 10000, observed: {packVoltage: {value: 12, receivedMs: 9990}}, messages: [], sensors: [], events: []}
            mock.battery_capacity_parameter = {id: "BATT_CAPACITY", value: 3300, type: 6}
            wait(50)
            var tile = findChild(panel, "craftBatteryCapacityCard")
            verify(tile !== null)
            verify(tile.height > 0)
            compare(panel.telemetryCards()[panel.telemetryCards().length - 1].key, "capacity")
            var dialog = findChild(panel, "craftBatteryCapacityDialog")
            verify(!dialog.visible)
            screenshot("capacity-card")
            var capacityScroll=findChild(panel,"craftDetailsScroll")
            capacityScroll.contentItem.contentY=Math.max(0,tile.mapToItem(capacityScroll.contentItem,0,0).y-capacityScroll.height+tile.height+20)
            wait(50)
            mouseClick(tile)
            tryCompare(dialog, "visible", true)
            verify(dialog.width <= 340)
            compare(dialog.title, "Battery capacity")
            var input = findChild(panel, "craftBatteryCapacity")
            var apply = findChild(panel, "craftBatteryCapacityApply")
            compare(input.value, 3300)
            verify(!apply.enabled)
            input.value = 2500
            mock.craft_diagnostics = {nowMs: 10001, observed: {packVoltage: {value: 11.9, receivedMs: 10001}}, messages: [], sensors: [], events: []}
            compare(input.value, 2500, "Telemetry must preserve the edited capacity")
            mouseClick(apply)
            compare(mockAction.requestedCapacity, 2500)
            tryCompare(dialog, "visible", false)
            compare(panel.capacityParameter.value, 3300, "A click alone must not claim success")
            mock.battery_capacity_parameter = {id: "BATT_CAPACITY", value: 2500, type: 6}
            verify(panel.telemetryCards()[1].value.indexOf("2") >= 0)
            mock.armed = true
            panel.openCapacityEditor()
            verify(!dialog.visible)
            mock.armed = false
            mock.telemetry_active = false
            panel.openCapacityEditor()
            verify(!dialog.visible)
            mock.battery_capacity_parameter = {}
            verify(!findChild(panel, "craftBatteryCapacityCard").visible)
            mock.telemetry_active = true
            mock.craft_diagnostics = savedDiagnostics
        }
        function test_card_fits_body() {
            var card = createTemporaryObject(craftCard, scene, {systemType: 1, title: "Air unit", actionsAvailable: true,
                bodyComponent: compactStatusBody, z: 10})
            card.height = Qt.binding(function() { return card.implicitHeight })
            var body = findChild(card, "compactStatusBody")
            var strip = findChild(card, "airUtilityStrip")
            var power = card.actionButtons()[3]
            tryCompare(body, "height", 139)
            compare(strip.y, body.mapToItem(card, 0, body.height).y + 8)
            compare(card.height, power.mapToItem(card, 0, power.height).y + 16)
            captureCompactCard(card, "air")
            var airHeight = card.height
            body.extraBadge = true
            tryCompare(card, "height", airHeight + 30)
            body.extraBadge = false
            card.systemType = 0
            card.title = "Ground station"
            body.rowCount = 5
            tryCompare(body, "height", 174)
            compare(strip.y, body.mapToItem(card, 0, body.height).y + 8)
            compare(power.mapToItem(card, 0, 0).y, strip.y + strip.height + 8)
            compare(card.height, power.mapToItem(card, 0, power.height).y + 16)
            captureCompactCard(card, "ground")
        }
        function captureCompactCard(card, name) {
            waitForRendering(card)
            var path = decodeURIComponent(Qt.resolvedUrl("../../build/compact-" + name + ".png").toString())
                    .replace("file:///", Qt.platform.os === "windows" ? "" : "/")
            var captured = {done: false}
            if (card.grabToImage(function(result) { result.saveToFile(path); captured.done = true }))
                tryVerify(function() { return captured.done })
        }
        function test_air_utility_actions() {
            var card = createTemporaryObject(craftCard, scene, {systemType: 1, title: "Air unit", actionsAvailable: true, height: 362, z: 10})
            var rates = findChild(card, "setLinkRatesButton")
            var hotspot = findChild(card, "wifiHotspotButton")
            waitForRendering(card)
            verify(rates.visible)
            verify(rates.enabled, "Air availability must allow requests without FC telemetry")
            verify(!findChild(card, "craftDetailsButton").visible)
            var controls = card.actionButtons()
            var power = controls[3]
            verify(power.visible)
            compare(power.mapToItem(card, 0, 0).y - rates.mapToItem(card, 0, 0).y, 46)
            var before = _mavlinkTelemetry.rateRequests
            mouseClick(rates)
            compare(_mavlinkTelemetry.rateRequests, before + 1)
            rates.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(_mavlinkTelemetry.rateRequests, before + 2)
            settings.set_mavlink_message_rates = false
            mouseClick(rates)
            compare(_mavlinkTelemetry.rateRequests, before + 2)
            verify(_qopenhd.toast.indexOf("Enable") >= 0)
            settings.set_mavlink_message_rates = true
            var hotspotState = findChild(card, "hotspotStateText")
            compare(hotspotState.text, "Inactive")
            verify(!hotspot.hotspotActive)
            mouseClick(hotspot)
            compare(_ohdSystemAirSettingsModel.requestedHotspot, 2)
            verify(!hotspot.hotspotActive, "Show reported state until the unit actually activates its hotspot")
            _ohdSystemAir.wifi_hotspot_state = 2
            verify(hotspot.hotspotActive)
            compare(hotspotState.text, "Active")
            mouseClick(hotspot)
            compare(_ohdSystemAirSettingsModel.requestedHotspot, 1)
            _ohdSystemAir.wifi_hotspot_state = 0
            card.width = 220
            waitForRendering(card)
            verify(rates.width > 0 && hotspot.width > 0)
            verify(Math.abs(rates.width - hotspot.width) <= 1, "Both halves of the strip must remain usable at narrow widths")
            var capture = grabImage(card)
            var capturePath = decodeURIComponent(Qt.resolvedUrl("../../build/air-status-actions.png").toString())
                    .replace("file:///", Qt.platform.os === "windows" ? "" : "/")
            if (capture.width > 0) capture.save(capturePath)
            else {
                var captured = {done: false}
                if (card.grabToImage(function(result) { result.saveToFile(capturePath); captured.done = true }))
                    tryVerify(function() { return captured.done })
            }
            card.alive = false
            verify(!rates.enabled)
            card.systemType = 0
            card.alive = true
            verify(!rates.visible && hotspot.visible)
            verify(hotspot.enabled)
            compare(hotspotState.text, "Inactive")
            mouseClick(hotspot)
            compare(_ohdSystemGroundSettings.requestedHotspot, 2)
            _ohdSystemGround.wifi_hotspot_state = 2
            compare(hotspotState.text, "Active")
            _ohdSystemGround.wifi_hotspot_state = 0
            waitForRendering(card)
            var strip = findChild(card, "airUtilityStrip")
            compare(hotspot.width, strip.width, "Ground hotspot control must fill the strip and center its contents")
            card.systemType = 2
            verify(!rates.visible && !hotspot.visible)
        }
        function test_card_click_and_keyboard() {
            var card = createTemporaryObject(craftCard, scene, {z: 10})
            verify(card !== null)
            cardSpy.target = card
            var button = findChild(card, "craftDetailsButton")
            verify(button !== null)
            waitForRendering(card)
            verify(button.visible)
            compare(button.height, 38)
            verify(button.mapToItem(card, 0, 0).y > 250, "Craft details must be a footer button")
            mouseClick(button)
            compare(cardSpy.count, 1)
            card.alive = false
            verify(card.visible)
            verify(button.enabled, "Offline diagnostics must remain accessible")
            mouseClick(button)
            compare(cardSpy.count, 2)
            button.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(cardSpy.count, 3)
        }
        function screenshot(name) {
            var done = false
            verify(panel.grabToImage(function(image) {
                verify(image.saveToFile(Qt.resolvedUrl("../../build/craft-" + name + ".png").toString().replace("file:///", "")))
                done = true
            }))
            tryVerify(function() { return done })
        }
        function test_details() {
            findChild(panel,"craftDetailsScroll").contentItem.contentY=0
            wait(200)
            compare(panel.firmwareLabel, "INAV")
            compare(findChild(panel, "craftFirmwareTitle").text, "INAV - Quadrotor")
            verify(findChild(panel, "inavDshotBeeperSwitch") === null, "USB/MSP controls must not exist")
            verify(!panel.has("batteryTemperature"), "Unreported temperature must not be advertised")
            verify(!panel.has("throttle"), "Invalid throttle must not be advertised")
            compare(panel.telemetryCards().length, 5)
            screenshot("overview")
            var original = mock.firmware_identity
            var themes = []
            for (var type = 1; type <= 4; ++type) {
                mock.firmware_identity = {type: type, name: ["", "ArduPilot", "PX4", "INAV", "Betaflight"][type], confidence: type === 4 ? "candidate" : "identified"}
                wait(20)
                themes.push(String(panel.accent))
                screenshot("theme-" + type)
            }
            compare(themes.filter(function(value, index, array) { return array.indexOf(value) === index }).length, 1)
            mock.firmware_identity = original
            verify(findChild(panel, "craftHealthTab") === null)
            verify(findChild(panel, "craftOverviewTab") === null)
            wait(100)
            screenshot("health")
            verify(findChild(panel, "craftMessagesTab") === null)
            verify(findChild(panel, "craftHealthEvents").visible)
            var eventCard=findChild(panel,"craftEvent_0")
            verify(eventCard !== null)
            var scroller=findChild(panel,"craftDetailsScroll")
            verify(scroller.contentItem.contentHeight > 0)
            scroller.contentItem.contentY=Math.max(0,scroller.contentItem.contentHeight-scroller.height)
            wait(50)
            verify(eventCard.mapToItem(panel,0,eventCard.height).y > 0)

            verify(findChild(panel, "craftMessage0") === null)
            var snapshot = JSON.parse(JSON.stringify(mock.craft_diagnostics))
            mock.is_alive = false
            compare(panel.online, true, "Live telemetry must stay usable without a heartbeat")
            verify(findChild(panel, "craftBack").enabled)
            mock.telemetry_active = false
            compare(panel.online, false)
            snapshot.statusAge = 8
            mock.craft_diagnostics = snapshot
            panel.anchors.fill = undefined
            panel.width = 380
            panel.height = 680
            wait(100)
            screenshot("offline")
            mouseClick(findChild(panel, "craftBack"))
            compare(closeSpy.count, 1)
        }
        function test_dynamic_fields() {
            var saved = mock.craft_diagnostics
            mock.telemetry_active = true
            mock.craft_diagnostics = {nowMs: 10000, observed: {}, messages: [], sensors: [], events: []}
            compare(panel.telemetryCards().length, 0, "No fabricated zero-valued fields")
            mock.craft_diagnostics = {nowMs: 10000, observed: {batteryTemperature: {value: 25, receivedMs: 9990}}, messages: [], sensors: [], events: []}
            compare(panel.telemetryCards().length, 1)
            compare(panel.telemetryCards()[0].value, "25.0\u00b0C")
            mock.craft_diagnostics = {nowMs: 15000, observed: {batteryTemperature: {value: 25, receivedMs: 9990}}, messages: [], sensors: [], events: []}
            compare(panel.telemetryCards()[0].value, "25.0\u00b0C", "Retain the last reading when packets stop")
            verify(panel.telemetryCards()[0].detail.indexOf("Last received") >= 0)
            mock.craft_diagnostics = saved
        }
        function test_readings_update_in_place() {
            var saved = mock.craft_diagnostics
            mock.telemetry_active = true
            mock.craft_diagnostics = {nowMs: 10000, observed: {packVoltage: {value: 12, receivedMs: 9990}}, messages: [], sensors: [], events: []}
            var tile = findChild(panel, "craftTelemetryTile_BATTERY")
            verify(tile !== null)
            mock.craft_diagnostics = {nowMs: 10001, observed: {packVoltage: {value: 11.8, receivedMs: 10001}}, messages: [], sensors: [], events: []}
            compare(findChild(panel, "craftTelemetryTile_BATTERY"), tile)
            compare(panel.telemetryCards()[0].value, "11.80 V")
            mock.telemetry_active = false
            mock.craft_diagnostics = {nowMs: 50000, observed: {packVoltage: {value: 11.8, receivedMs: 10001}}, messages: [], sensors: [], events: []}
            compare(findChild(panel, "craftTelemetryTile_BATTERY"), tile)
            compare(panel.telemetryCards()[0].value, "11.80 V")
            compare(panel.firmwareName, "INAV")
            mock.telemetry_active = true
            mock.craft_diagnostics = saved
        }
        function test_betaflight_version_formats() {
            var saved = mock.firmware_identity
            mock.firmware_identity = {type: 4, name: "Betaflight", ver: 0x1a060200}
            compare(panel.identityRows()[0], "Firmware version: 2026.6.2")
            mock.firmware_identity = {type: 4, name: "Betaflight", ver: 0x040501ff}
            compare(panel.identityRows()[0], "Firmware version: 4.5.1")
            mock.firmware_identity = saved
        }
    }
}
