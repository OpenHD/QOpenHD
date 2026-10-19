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
            title: "Flight controller"; systemType: 2; alive: true
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
    Status.CraftDetailsPanel { id: panel; anchors.fill: parent; fc: mock }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "CraftDetails"
        when: windowShown
        function test_card_click_and_keyboard() {
            var card = createTemporaryObject(craftCard, scene, {z: 10})
            verify(card !== null)
            cardSpy.target = card
            var button = findChild(card, "craftDetailsButton")
            verify(button !== null)
            waitForRendering(card)
            verify(button.visible)
            verify(button.height > 0)
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
    }
}
