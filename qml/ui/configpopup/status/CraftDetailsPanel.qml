import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    color: settings_form.pageBackground
    radius: 14
    signal closeRequested()
    property var fc: _fcMavlinkSystem
    readonly property var identity: fc.firmware_identity || ({})
    readonly property var observed: diagnostics.observed || ({})
    readonly property string firmwareName: identity.name || qsTr("Flight controller")
    readonly property string firmwareLabel: firmwareName
    readonly property bool hasHealth: (diagnostics.sensors || []).length > 0 || (diagnostics.events || []).length > 0
    readonly property var diagnostics: fc.craft_diagnostics || ({})
    readonly property bool online: fc.telemetry_active
    readonly property color accent: identity.type === 3 ? "#23b9e6" : identity.type === 4 ? "#ffb400"
        : identity.type === 2 ? "#52d6a0" : identity.type === 1 ? "#54bfff" : "#b39aff"
    property int selectedTab: 0
    property var expandedMessages: []
    function gainFocus() { backButton.forceActiveFocus() }

    ListModel { id: sensorRows; dynamicRoles: true }
    ListModel { id: eventRows; dynamicRoles: true }
    ListModel { id: messageRows; dynamicRoles: true }
    ListModel { id: telemetryRows; dynamicRoles: true }
    function syncRows(target, rows) {
        for (var i = 0; i < rows.length; ++i) {
            if (i < target.count) target.setProperty(i, "entry", rows[i])
            else target.append({entry: rows[i]})
        }
        while (target.count > rows.length) target.remove(target.count - 1)
    }
    onDiagnosticsChanged: {
        syncRows(telemetryRows, telemetryCards())
        syncRows(sensorRows, diagnostics.sensors || [])
        syncRows(eventRows, diagnostics.events || [])
        syncRows(messageRows, diagnostics.messages || [])
        if (selectedTab === 1 && !hasHealth) selectedTab = 0
    }
    Component.onCompleted: {
        syncRows(telemetryRows, telemetryCards())
        syncRows(sensorRows, diagnostics.sensors || [])
        syncRows(eventRows, diagnostics.events || [])
        syncRows(messageRows, diagnostics.messages || [])
    }

    function has(key) { return observed[key] !== undefined }
    function hasMessage(id) {
        var messages = diagnostics.messages || []
        for (var i = 0; i < messages.length; ++i) if (messages[i].id === id) return true
        return false
    }
    function reading(key, digits, suffix) {
        if (!has(key) || observed[key].valid === false) return "\u2014"
        return Number(observed[key].value).toFixed(digits) + (suffix || "")
    }
    function telemetryCards() {
        var cards = []
        function add(key, title, digits, suffix, detail) {
            if (root.has(key)) {
                var old = !root.online || root.diagnostics.nowMs - root.observed[key].receivedMs > 4000
                cards.push({label: title, value: root.reading(key, digits, suffix),
                    detail: old ? qsTr("Last received %1 ago").arg(root.age((root.diagnostics.nowMs - root.observed[key].receivedMs) / 1000)) : detail || ""})
            }
        }
        var voltage = has("packVoltage") ? "packVoltage" : "batteryPackVoltage"
        add(voltage, qsTr("BATTERY"), 2, " V", has("batteryPercent") ? reading("batteryPercent", 0, "%") : "")
        add("cellAverage", qsTr("AVERAGE CELL"), 2, " V", qsTr("FC reported average"))
        add("current", qsTr("CURRENT"), 2, " A")
        add("consumedMah", qsTr("CONSUMED"), 0, " mAh")
        add("batteryTemperature", qsTr("BATTERY TEMPERATURE"), 1, "\u00b0C")
        if (has("gpsFix")) cards.push({label: qsTr("GPS"), value: root.online ? root.fc.gps_status_fix_type_str : "\u2014",
            detail: has("satellites") ? reading("satellites", 0, qsTr(" satellites")) : ""})
        if (has("gpsFix") && observed.gpsFix.value >= 3) {
            add("groundSpeed", qsTr("GROUND SPEED"), 1, " m/s")
            add("latitude", qsTr("LATITUDE"), 6, "\u00b0")
            add("longitude", qsTr("LONGITUDE"), 6, "\u00b0")
        }
        add("relativeAltitude", qsTr("RELATIVE ALTITUDE"), 1, " m", qsTr("FC estimate"))
        add("climb", qsTr("CLIMB"), 1, " m/s")
        add("load", qsTr("FC LOAD"), 1, "%")
        add("rcRssi", qsTr("RC SIGNAL"), 0, "%", qsTr("FC receiver"))
        add("throttle", qsTr("THROTTLE"), 0, "%")
        add("sensorTemperature", qsTr("SENSOR TEMPERATURE"), 1, "\u00b0C")
        add("pressure", qsTr("PRESSURE"), 1, " hPa")
        return cards
    }
    function identityRows() {
        var rows = []
        var v = Number(identity.ver || 0)
        if ((v >>> 24) > 0 && v !== 4294967295) rows.push(qsTr("Firmware version: %1.%2.%3").arg((v >>> 24) & 255).arg((v >>> 16) & 255).arg((v >>> 8) & 255))
        if (diagnostics.boardVersion) rows.push(qsTr("Board revision: %1").arg(diagnostics.boardVersion))
        if (diagnostics.vendorId || diagnostics.productId) rows.push(qsTr("Vendor / product: %1 / %2").arg(diagnostics.vendorId).arg(diagnostics.productId))
        if (diagnostics.uid && diagnostics.uid !== "0") rows.push(qsTr("UID: %1").arg(diagnostics.uid))
        return rows
    }

    function number(value, digits, suffix) {
        return online && isFinite(value) ? Number(value).toFixed(digits) + (suffix || "") : "—"
    }
    function age(value) { return value === undefined || value < 0 ? qsTr("Not received") : Number(value).toFixed(1) + " s" }
    function known(value) { return value === undefined || value === "" ? qsTr("Not reported") : String(value) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: root.width < 500 ? 12 : 20
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: qsTr("CRAFT / FLIGHT CONTROLLER"); color: root.accent; font.pixelSize: 11; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    objectName: "craftFirmwareTitle"
                    text: root.firmwareLabel + (root.hasMessage(0) ? " · " + root.fc.mav_type_str : "")
                    color: settings_form.primaryText; font.pixelSize: root.width < 500 ? 18 : 24; font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: root.online ? (root.fc.is_alive
                        ? qsTr("LIVE · System %1 · Last heartbeat %2 ago").arg(root.fc.for_osd_sys_id).arg(root.age(root.diagnostics.heartbeatAge))
                        : qsTr("TELEMETRY LIVE · System %1 · Last heartbeat %2 ago").arg(root.fc.for_osd_sys_id).arg(root.age(root.diagnostics.heartbeatAge)))
                                      : qsTr("OFFLINE · Last received values are retained")
                    color: root.online ? settings_form.goodColor : "#f6b85b"; font.pixelSize: 11
                }
            }
            Button { id: backButton; objectName: "craftBack"; text: qsTr("Back"); onClicked: root.closeRequested(); Accessible.name: qsTr("Back to system status") }
        }

        TabBar {
            id: craftTabs
            Layout.fillWidth: true
            currentIndex: root.selectedTab
            onCurrentIndexChanged: root.selectedTab = currentIndex
            TabButton { width: craftTabs.availableWidth / (root.hasHealth ? 3 : 2); objectName: "craftOverviewTab"; text: qsTr("Overview") }
            TabButton { visible: root.hasHealth; width: root.hasHealth ? craftTabs.availableWidth / 3 : 0; objectName: "craftHealthTab"; text: qsTr("Health / events") }
            TabButton { width: craftTabs.availableWidth / (root.hasHealth ? 3 : 2); objectName: "craftMessagesTab"; text: qsTr("MAVLink") }
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
            width: scroll.availableWidth
            ColumnLayout {
                Layout.fillWidth: true; spacing: 12
                visible: root.selectedTab === 0

                Rectangle {
                    visible: root.has("roll") && root.has("pitch")
                    Layout.fillWidth: true; implicitHeight: 162
                    color: settings_form.panelBackground; radius: 12; border.color: settings_form.lineColor
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 18
                        Rectangle {
                            Layout.preferredWidth: Math.min(160, root.width * 0.29)
                            Layout.fillHeight: true
                            color: "#121c2d"; radius: 8; clip: true
                            Item {
                                anchors.centerIn: parent; width: parent.width * 3; height: parent.height * 3
                                rotation: -root.fc.roll
                                Rectangle { width: parent.width; height: parent.height / 2; color: "#254e78"; y: root.fc.pitch * 1.4 }
                                Rectangle { width: parent.width; height: parent.height / 2; y: parent.height / 2 + root.fc.pitch * 1.4; color: "#614b3f" }
                                Rectangle { width: parent.width; height: 2; y: parent.height / 2 + root.fc.pitch * 1.4; color: "#b9d7f0" }
                            }
                            Text { anchors.centerIn: parent; text: "— + —"; color: "#ffe399"; font.pixelSize: 24; font.bold: true }
                            Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 8; text: qsTr("ATTITUDE"); font.pixelSize: 9; color: "white" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 7
                            Text { text: root.fc.armed ? qsTr("ARMED") : qsTr("DISARMED"); color: root.fc.armed ? "#ff7d85" : root.accent; font.pixelSize: 20; font.bold: true }
                            Text { text: root.fc.flight_mode; color: settings_form.primaryText; font.pixelSize: 14 }
                            Text { text: qsTr("Roll %1   Pitch %2").arg(root.number(root.fc.roll, 1, "°")).arg(root.number(root.fc.pitch, 1, "°")); color: settings_form.secondaryText; font.pixelSize: 12 }
                            Text { text: qsTr("Heading %1").arg(root.number(root.fc.hdg, 0, "°")); color: settings_form.secondaryText; font.pixelSize: 12 }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true; columns: root.width >= 600 ? 3 : 2; columnSpacing: 10; rowSpacing: 10
                    Repeater {
                        model: telemetryRows
                        delegate: Rectangle {
                            objectName: "craftTelemetryTile_" + entry.label
                            Layout.fillWidth: true; implicitHeight: 100
                            color: settings_form.panelBackground; radius: 10; border.color: settings_form.lineColor
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                Text { text: entry.label; font.pixelSize: 9; font.bold: true; color: root.accent }
                                Text { Layout.fillWidth: true; text: entry.value; font.pixelSize: 21; font.bold: true; color: settings_form.primaryText; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: entry.detail; font.pixelSize: 10; color: settings_form.secondaryText; elide: Text.ElideRight }
                            }
                        }
                    }
                }
                Label { visible: root.identityRows().length > 0; text: qsTr("IDENTIFICATION"); color: root.accent; font.bold: true; font.pixelSize: 11 }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.fc.battery_capacity_parameter !== undefined && Object.keys(root.fc.battery_capacity_parameter).length > 0
                    Label { text: qsTr("FC BATTERY CAPACITY"); color: root.accent; font.bold: true }
                    RowLayout {
                        SpinBox {
                            id: capacityInput; objectName: "craftBatteryCapacity"
                            from: 100; to: 100000; stepSize: 100; editable: true
                            value: root.fc.battery_capacity_parameter ? Math.max(100, root.fc.battery_capacity_parameter.value || 100) : 100
                            enabled: root.online && !root.fc.armed
                        }
                        Label { text: "mAh"; color: settings_form.secondaryText }
                        Button {
                            text: qsTr("Apply to FC"); enabled: root.online && !root.fc.armed
                            onClicked: _fcMavlinkAction.set_battery_capacity_async(capacityInput.value)
                        }
                    }
                    Label {
                        text: root.fc.battery_capacity_parameter && root.fc.battery_capacity_parameter.id === "BAT1_CAPACITY"
                            ? qsTr("PX4: restart the FC for this change to take effect.") : qsTr("The FC confirms the value with a matching parameter response.")
                        color: settings_form.secondaryText; wrapMode: Text.Wrap; Layout.fillWidth: true
                    }
                }
                Repeater {
                    model: root.identityRows()
                    delegate: Label { Layout.fillWidth: true; wrapMode: Text.Wrap; text: modelData; color: settings_form.secondaryText; font.pixelSize: 12 }
                }

            }

            // Keep each tab's content in the same scrolling surface without rebuilding the popup.
            ColumnLayout {
                Layout.fillWidth: true; spacing: 10; visible: root.selectedTab === 1
                Label { visible: (root.diagnostics.sensors || []).length > 0; text: qsTr("SENSOR & SUBSYSTEM HEALTH"); color: root.accent; font.bold: true; font.pixelSize: 11 }
                Repeater {
                    model: sensorRows
                    delegate: Rectangle {
                        Layout.fillWidth: true; implicitHeight: 38; radius: 8; color: settings_form.panelBackground
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10
                            Text { Layout.fillWidth: true; text: model.entry.name; color: settings_form.primaryText; font.pixelSize: 12 }
                            Text {
                                readonly property bool fresh: root.online && root.diagnostics.statusAge < 4
                                text: !fresh ? qsTr("STALE") : !model.entry.enabled ? qsTr("DISABLED") : model.entry.healthy ? qsTr("HEALTHY") : qsTr("FAULT")
                                color: !fresh || !model.entry.enabled ? settings_form.secondaryText : model.entry.healthy ? settings_form.goodColor : "#ff8a85"
                                font.pixelSize: 11; font.bold: true
                            }
                        }
                    }
                }
                Label { Layout.fillWidth: true; text: qsTr("Health flags are reported by the FC; calibration and arming messages can provide additional detail."); color: settings_form.secondaryText; wrapMode: Text.Wrap; font.pixelSize: 11 }
                Label { visible: (root.diagnostics.events || []).length > 0; text: qsTr("RECENT FC EVENTS"); color: root.accent; font.bold: true; font.pixelSize: 11; Layout.topMargin: 12 }
                Repeater {
                    model: eventRows
                    delegate: Rectangle {
                        Layout.fillWidth: true; implicitHeight: eventText.implicitHeight + 42
                        color: settings_form.panelBackground; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 5
                            Text { id: eventText; Layout.fillWidth: true; text: model.entry.text; wrapMode: Text.Wrap; color: model.entry.severity <= 4 ? "#ffb18a" : settings_form.primaryText; font.pixelSize: 13 }
                            Text { text: qsTr("%1 s ago · %2 occurrences · severity %3").arg(Math.max(0, (root.diagnostics.nowMs - model.entry.receivedMs) / 1000).toFixed(0)).arg(model.entry.count).arg(model.entry.severity); color: settings_form.secondaryText; font.pixelSize: 10 }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 8; visible: root.selectedTab === 2
                Label { text: qsTr("MAVLINK INSPECTOR · %1 packets received").arg(root.diagnostics.total || 0); color: root.accent; font.bold: true; font.pixelSize: 11 }
                Label { Layout.fillWidth: true; text: qsTr("Expand a message to inspect its latest payload. Rates measure arrivals at QOpenHD; ages keep increasing when telemetry stops."); wrapMode: Text.Wrap; color: settings_form.secondaryText; font.pixelSize: 11 }
                Repeater {
                    model: messageRows
                    delegate: Rectangle {
                        id: packet
                        readonly property var row: model.entry
                        objectName: "craftMessage" + model.entry.id
                        readonly property bool expanded: root.expandedMessages.indexOf(model.entry.id) >= 0
                        Layout.fillWidth: true; implicitHeight: packetColumn.implicitHeight + 16
                        color: settings_form.panelBackground; radius: 8; border.color: settings_form.lineColor
                        ColumnLayout {
                            id: packetColumn
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                            Button {
                                Layout.fillWidth: true
                                text: (packet.expanded ? "▾ " : "▸ ") + model.entry.id + " · " + model.entry.name
                                onClicked: {
                                    var ids = root.expandedMessages.slice()
                                    var index = ids.indexOf(model.entry.id)
                                    if (index >= 0) ids.splice(index, 1)
                                    else ids.push(model.entry.id)
                                    root.expandedMessages = ids
                                }
                                contentItem: Text { text: parent.text; color: settings_form.primaryText; elide: Text.ElideRight; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: parent.hovered ? "#20b39aff" : "transparent"; radius: 5; border.color: parent.activeFocus ? root.accent : "transparent" }
                            }
                            Text { text: qsTr("%1 Hz · %2 packets · %3 s old · component %4").arg(Number(model.entry.rate).toFixed(1)).arg(model.entry.count).arg(Number(model.entry.age).toFixed(1)).arg(model.entry.component); color: model.entry.age > 4 ? "#f6b85b" : settings_form.secondaryText; font.pixelSize: 10 }
                            Repeater {
                                model: packet.expanded ? (packet.row.fields || []) : []
                                delegate: Text {
                                    Layout.fillWidth: true
                                    text: modelData.name + ": " + modelData.value
                                    wrapMode: Text.WrapAnywhere; font.family: "monospace"; font.pixelSize: 11
                                    color: settings_form.primaryText
                                }
                            }
                            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; visible: packet.expanded; text: qsTr("WIRE PAYLOAD · raw field values above use MAVLink units"); color: settings_form.secondaryText; font.pixelSize: 9 }
                            Text { Layout.fillWidth: true; visible: packet.expanded; text: model.entry.payload || qsTr("Empty payload"); wrapMode: Text.WrapAnywhere; font.family: "monospace"; font.pixelSize: 11; color: root.accent }
                        }
                    }
                }
            }
            }
        }
    }
    onSelectedTabChanged: scroll.contentItem.contentY = 0
}
