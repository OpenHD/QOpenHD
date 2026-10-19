import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/status" as Status

Item {
    id: scene
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
        property color lineColor: "#304057"
    }
    QtObject {
        id: statusPanel
        function syncFocus(item) {}
        function moveFocus(step) {}
    }
    Component {
        id: craftCard
        Status.StatusCard {
            width: 300; height: 319
            title: "Flight controller"; systemType: 2; alive: true; actionsAvailable: false
            bodyComponent: Component { Item {} }
        }
    }
    SignalSpy { id: cardSpy; signalName: "detailsRequested" }
    QtObject {
        id: mock
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
        property bool remote_id_busy: false
        property string requestedRemoteId: ""
        property bool requestedOperatorId: false
        function set_remote_id_async(isOperator, value) { requestedOperatorId=isOperator; requestedRemoteId=value }
        function set_battery_capacity_async(value) { requestedCapacity = value }
    }
    Status.CraftDetailsPanel { id: panel; anchors.fill: parent; fc: mock; fcAction: mockAction }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "CraftDetails"
        when: windowShown
        function test_remote_id_card() {
            mock.telemetry_active=true;mock.armed=false;panel.selectedTab=0
            mock.remote_id_status={aircraftId: "FC-BOARD-ID", idType: 1, locationReceivedMs: 9900}
            wait(50)
            var card=findChild(panel,"craftRemoteIdCard")
            verify(card!==null)
            verify(panel.remoteIdStatus().indexOf("ready") < 0)
            panel.openRemoteId();wait(50)
            var dialog=findChild(panel,"craftRemoteIdDialog")
            verify(dialog.opened)
            verify(!findChild(panel,"craftRemoteAircraftId").visible)
            var readonlyImage=grabImage(scene)
            if (readonlyImage.width > 0) readonlyImage.save("QOpenHD/build/remote-id-readonly.png")
            dialog.close()
            mock.remote_id_status={aircraftId: "MODULE-ID", armStatus: 0, armStatusReceivedMs: 9900,
                operatorParameter: {id: "OPERATOR_ID", value: "OLD-ID", sys: 1, comp: 236, type: 11}}
            panel.openRemoteId();wait(50)
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
            panel.selectedTab = 0
            mock.craft_diagnostics = {nowMs: 10000, observed: {packVoltage: {value: 12, receivedMs: 9990}}, messages: [], sensors: [], events: []}
            mock.battery_capacity_parameter = {id: "BATT_CAPACITY", value: 3300, type: 6}
            wait(50)
            var tile = findChild(panel, "craftBatteryCapacityCard")
            verify(tile !== null)
            compare(tile.height, findChild(panel, "craftTelemetryTile_BATTERY").height)
            compare(panel.telemetryCards()[panel.telemetryCards().length - 1].key, "capacity")
            var dialog = findChild(panel, "craftBatteryCapacityDialog")
            verify(!dialog.visible)
            screenshot("capacity-card")
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
            verify(findChild(panel, "craftBatteryCapacityCard") === null)
            mock.telemetry_active = true
            mock.craft_diagnostics = savedDiagnostics
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
            wait(200)
            compare(panel.firmwareLabel, "INAV")
            compare(findChild(panel, "craftFirmwareTitle").text, "INAV \u00b7 Quadrotor")
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
            compare(themes.filter(function(value, index, array) { return array.indexOf(value) === index }).length, 4)
            mock.firmware_identity = original
            mouseClick(findChild(panel, "craftHealthTab"))
            compare(panel.selectedTab, 1)
            wait(100)
            screenshot("health")
            mouseClick(findChild(panel, "craftMessagesTab"))
            compare(panel.selectedTab, 2)
            var packet = findChild(panel, "craftMessage0")
            verify(packet !== null)
            panel.expandedMessages = [0]
            verify(packet.expanded)
            var snapshot = JSON.parse(JSON.stringify(mock.craft_diagnostics))
            snapshot.messages[0].count = 32
            mock.craft_diagnostics = snapshot
            wait(50)
            compare(findChild(panel, "craftMessage0"), packet, "Updating telemetry must preserve the delegate and focus")
            verify(packet.expanded)
            compare(packet.row.count, 32)
            screenshot("messages")
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
            mouseClick(findChild(panel, "craftOverviewTab"))
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
