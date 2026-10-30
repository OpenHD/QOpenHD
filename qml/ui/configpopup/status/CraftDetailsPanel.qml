import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

Rectangle {
    id: root
    color: "#041d2c"
    radius: 14
    signal closeRequested()
    property var fc: _fcMavlinkSystem
    property var diagnosticSource: null
    property bool subscriptionReady: false
    function updateDiagnosticSubscription() {
        var target = subscriptionReady && visible ? fc : null
        if (diagnosticSource === target) return
        if (diagnosticSource && typeof diagnosticSource.release_diagnostics === "function")
            diagnosticSource.release_diagnostics()
        diagnosticSource = target
        if (diagnosticSource && typeof diagnosticSource.acquire_diagnostics === "function")
            diagnosticSource.acquire_diagnostics()
    }
    onVisibleChanged: updateDiagnosticSubscription()
    onFcChanged: updateDiagnosticSubscription()
    Component.onDestruction: {
        subscriptionReady = false
        updateDiagnosticSubscription()
    }
    property var fcAction: _fcMavlinkAction
    readonly property var remoteId: fc.remote_id_status || ({})
    readonly property bool hasRemoteId: Object.keys(remoteId).length > 0
    onRemoteIdChanged: syncRows(telemetryRows, telemetryCards())
    onHasRemoteIdChanged: syncRows(telemetryRows, telemetryCards())
    readonly property var capacityParameter: fc.battery_capacity_parameter || ({})
    readonly property bool hasCapacity: Object.keys(capacityParameter).length > 0
    readonly property var identity: fc.firmware_identity || ({})
    readonly property var observed: diagnostics.observed || ({})
    readonly property string firmwareName: identity.name || qsTr("Flight controller")
    readonly property string firmwareLabel: firmwareName
    readonly property bool hasHealth: (diagnostics.sensors || []).length > 0 || (diagnostics.events || []).length > 0
    readonly property var diagnostics: fc.craft_diagnostics || ({})
    readonly property bool online: fc.telemetry_active
    readonly property color accent: "#38a5ff"
    onCapacityParameterChanged: syncRows(telemetryRows, telemetryCards())
    onHasCapacityChanged: syncRows(telemetryRows, telemetryCards())
    function gainFocus() { backButton.forceActiveFocus() }

    ListModel { id: sensorRows; dynamicRoles: true }
    ListModel { id: eventRows; dynamicRoles: true }
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
    }
    Component.onCompleted: {
        subscriptionReady = true
        updateDiagnosticSubscription()
        syncRows(telemetryRows, telemetryCards())
        syncRows(sensorRows, diagnostics.sensors || [])
        syncRows(eventRows, diagnostics.events || [])
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
                cards.push({key: key, label: title, value: root.reading(key, digits, suffix),
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
        if (hasRemoteId) cards.push({key: "remoteId", label: qsTr("REMOTE ID"),
            value: remoteId.aircraftId || qsTr("Data received"),
            detail: !root.online ? qsTr("Last received ? Click for details") : qsTr("Click for details")})
        if (hasCapacity) cards.push({key: "capacity", label: qsTr("BATTERY CAPACITY"),
            value: Number(capacityParameter.value).toLocaleString(Qt.locale(), "f", 0) + " mAh",
            detail: root.fc.armed ? qsTr("Disarm to edit") : root.online ? qsTr("Click to edit") : qsTr("Last received")})
        return cards
    }
    function identityRows() {
        var rows = []
        var v = Number(identity.ver || 0)
        var major = (v >>> 24) & 255
        var minor = (v >>> 16) & 255
        // Betaflight CalVer encodes the year relative to 2000 in MAVLink.
        if (identity.type === 4 && major >= 25 && minor >= 1 && minor <= 12) major += 2000
        if ((v >>> 24) > 0 && v !== 4294967295) rows.push(qsTr("Firmware version: %1.%2.%3").arg(major).arg(minor).arg((v >>> 8) & 255))
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

    function openCapacityEditor() {
        if (!hasCapacity || !online || fc.armed) return
        capacityInput.value = Math.max(100, capacityParameter.value || 100)
        capacityDialog.open()
    }
    AdvancedDialog {
        id: capacityDialog; objectName: "craftBatteryCapacityDialog"
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(340, parent.width - 24)
        title: qsTr("Battery capacity")
        modal: true; focus: true
        onAccepted: root.fcAction.set_battery_capacity_async(capacityInput.value)
        ColumnLayout {
            width: parent.width; spacing: 10
            RowLayout {
                SpinBox { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    id: capacityInput; objectName: "craftBatteryCapacity"
                    Layout.fillWidth: true
                    from: 100; to: 100000; stepSize: 100; editable: true
                    enabled: root.online && !root.fc.armed
                    Accessible.name: qsTr("Battery capacity in mAh")
                }
                Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; text: "mAh" }
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: root.capacityParameter.id === "BAT1_CAPACITY"
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("Restart PX4 for this change to take effect.")
            }
        }
        footer: DialogButtonBox {
            padding: 16; spacing: 10
            background: Item {}
            AdvancedDialogButton { text: qsTr("Cancel"); onClicked: capacityDialog.reject() }
            AdvancedDialogButton {
                objectName: "craftBatteryCapacityApply"
                text: qsTr("Save")
                enabled: root.online && !root.fc.armed && capacityInput.value !== root.capacityParameter.value
                onClicked: capacityDialog.accept()
            }
        }
    }

    function openRemoteId() {
        aircraftIdInput.text = (remoteId.aircraftParameter || {}).value || ""
        operatorIdInput.text = (remoteId.operatorParameter || {}).value || ""
        remoteIdDialog.open()
    }
    function remoteIdStatus() {
        if (remoteId.armStatus === undefined) return qsTr("Module readiness not reported")
        var ageMs = (diagnostics.nowMs || 0) - remoteId.armStatusReceivedMs
        var old = !online || ageMs > 4000
        var status = remoteId.armStatus === 0 ? qsTr("Module reports ready") : qsTr("Module reports a fault")
        return old ? qsTr("Last report: %1").arg(status) : status
    }
    AdvancedDialog {
        id: remoteIdDialog; objectName: "craftRemoteIdDialog"
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2); y: Math.round((parent.height - height) / 2)
        width: Math.min(420, parent.width - 24)
        title: qsTr("Remote ID"); modal: true; focus: true
        standardButtons: Dialog.Close
        ColumnLayout {
            width: parent.width; spacing: 10
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; Layout.fillWidth: true; wrapMode: Text.Wrap; text: root.remoteIdStatus() }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("Aircraft ID: %1").arg(root.remoteId.aircraftId || qsTr("Not reported"))
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: root.remoteId.idType !== undefined
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("ID type: %1").arg(root.remoteId.idType === 1 ? qsTr("Serial number")
                    : root.remoteId.idType === 2 ? qsTr("Registration ID") : root.remoteId.idType === 3
                    ? qsTr("UTM UUID") : root.remoteId.idType === 4 ? qsTr("Session ID") : qsTr("Unspecified"))
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: root.remoteId.operatorId !== undefined
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("Reported operator ID: %1").arg(root.remoteId.operatorId || qsTr("Empty"))
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: root.remoteId.error !== undefined && root.remoteId.error !== ""
                Layout.fillWidth: true; wrapMode: Text.Wrap; text: root.remoteId.error || ""
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("MAVLink reports do not confirm Bluetooth/Wi-Fi broadcasting.")
                color: settings_form.secondaryText
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: !root.remoteId.aircraftParameter && !root.remoteId.operatorParameter
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: qsTr("This device does not expose ID editing over MAVLink.")
                color: settings_form.secondaryText
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; visible: !!root.remoteId.aircraftParameter; text: qsTr("Aircraft ID") }
            RowLayout {
                visible: !!root.remoteId.aircraftParameter; Layout.fillWidth: true
                TextField { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    id: aircraftIdInput; objectName: "craftRemoteAircraftId"
                    Layout.fillWidth: true; maximumLength: 20; selectByMouse: true
                    enabled: root.online && !root.fc.armed && !root.fcAction.remote_id_busy
                }
                AdvancedDialogButton {
                    objectName: "craftRemoteAircraftIdSave"; text: qsTr("Save")
                    enabled: aircraftIdInput.enabled && aircraftIdInput.text.length > 0
                        && aircraftIdInput.text !== (root.remoteId.aircraftParameter || {}).value
                    onClicked: root.fcAction.set_remote_id_async(false, aircraftIdInput.text)
                }
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; visible: !!root.remoteId.operatorParameter; text: qsTr("Operator ID") }
            RowLayout {
                visible: !!root.remoteId.operatorParameter; Layout.fillWidth: true
                TextField { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                    id: operatorIdInput; objectName: "craftRemoteOperatorId"
                    Layout.fillWidth: true; maximumLength: 20; selectByMouse: true
                    enabled: root.online && !root.fc.armed && !root.fcAction.remote_id_busy
                }
                AdvancedDialogButton {
                    objectName: "craftRemoteOperatorIdSave"; text: qsTr("Save")
                    enabled: operatorIdInput.enabled && operatorIdInput.text.length > 0
                        && operatorIdInput.text !== (root.remoteId.operatorParameter || {}).value
                    onClicked: root.fcAction.set_remote_id_async(true, operatorIdInput.text)
                }
            }
            Label { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                visible: !!root.remoteId.aircraftParameter || !!root.remoteId.operatorParameter
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: root.fcAction.remote_id_busy ? qsTr("Waiting for device confirmation?")
                    : qsTr("ID changes require confirmation from the device.")
                color: settings_form.secondaryText
            }
        }
    }


    function display(key, digits, suffix) {
        return has(key) && observed[key].valid !== false ? reading(key,digits,suffix) : qsTr("Not reported")
    }
    readonly property bool heartbeatFresh: online && diagnostics.heartbeatAge >= 0 && diagnostics.heartbeatAge < 5
    readonly property bool sensorsFresh: online && diagnostics.statusAge >= 0 && diagnostics.statusAge < 5
    readonly property bool healthWarning: sensorsFresh && (diagnostics.sensors || []).some(function(sensor) {return sensor.enabled && !sensor.healthy})
    readonly property string healthText: !sensorsFresh || !(diagnostics.sensors || []).length ? qsTr("Not reported") : healthWarning ? qsTr("Warning") : qsTr("Healthy")
    readonly property color healthColor: healthText === qsTr("Not reported") ? "#94a9b9" : healthWarning ? "#ff6470" : "#25d780"

    ColumnLayout {
        anchors.fill: parent; anchors.margins: root.width < 500 ? 16 : 24; spacing: 12
        RowLayout {
            Layout.fillWidth: true; spacing: 18
            Text { text: "\uf2db"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.pageIcon; color: "#d5e8f5" }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: qsTr("Flight Controller Details"); color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.pageTitle; font.bold: true }
                Text { objectName: "craftFirmwareTitle"; Layout.fillWidth: true; text: root.firmwareLabel + (root.hasMessage(0) ? " - " + root.fc.mav_type_str : ""); color: "#d5e8f5"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; elide: Text.ElideRight }
                Text { text: root.heartbeatFresh ? qsTr("Connected - System %1 - Last heartbeat %2 ago").arg(root.fc.for_osd_sys_id).arg(root.age(root.diagnostics.heartbeatAge)) : root.online ? qsTr("Telemetry received - waiting for heartbeat") : qsTr("Disconnected - last received values retained"); color: root.heartbeatFresh ? "#00d684" : "#f0bb67"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
            }
            ToolButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                id: backButton; objectName: "craftBack"; Layout.alignment: Qt.AlignTop; implicitWidth: 44; implicitHeight: 44
                text: "\uf00d"; onClicked: root.closeRequested(); Accessible.name: qsTr("Close flight controller details")
                background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? "#153c53" : "transparent" }
                contentItem: Text { text: parent.text; color: "#edf4fa"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
        ScrollView {
            id: scroll; objectName: "craftDetailsScroll"
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: scroll.availableWidth; spacing: 14
                FcDetailsSection {
                    title: qsTr("Flight Status"); icon: "\uf1d8"; Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true; spacing: 20
                        Rectangle {
                            Layout.preferredWidth: Math.min(285,root.width * .28); Layout.minimumWidth: 0; Layout.preferredHeight: 144
                            color: "#102839"; radius: 7; clip: true
                            readonly property bool validAttitude: root.online && root.has("roll") && root.has("pitch")
                            Item {
                                anchors.centerIn: parent; width: parent.width*3; height: parent.height*3
                                visible: parent.validAttitude; rotation: -root.fc.roll
                                Rectangle { anchors.fill: parent; color: "#185e91" }
                                Rectangle { width: parent.width; height: parent.height; y: parent.height/2 + root.fc.pitch*1.4; color: "#584b3a" }
                                Rectangle { width: parent.width; height: 2; y: parent.height/2 + root.fc.pitch*1.4; color: "#d2e7ed" }
                            }
                            Repeater { model: 5; Rectangle { x: parent.width/2-width/2; y: parent.height/2+(index-2)*20; width: index===2?110:20; height: 1; color: index===2?"#ffe399":"#9fbed3"; visible: parent.validAttitude } }
                            Text { anchors.centerIn: parent; text: parent.validAttitude ? "- + -" : qsTr("Not reported"); color: "#ffe399"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.metric }
                            Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 7; anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("ATTITUDE"); color: "white"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
                        }
                        ColumnLayout {
                            Layout.preferredWidth: Math.min(230,root.width * .23); Layout.maximumWidth: Math.min(230,root.width * .23); Layout.minimumWidth: 0; spacing: 6
                            Row { spacing: 12
                                Text { text: "\uf3ed"; color: "#12a8f3"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.pageIcon }
                                Column { spacing: 3
                                    Text { text: root.heartbeatFresh ? (root.fc.armed ? qsTr("ARMED") : qsTr("DISARMED")) : qsTr("Not reported"); color: root.fc.armed ? "#ff6470" : "#12a8f3"; font.bold: true; font.family: MenuTypography.family; font.pixelSize: MenuTypography.sectionTitle }
                                    Text { text: root.heartbeatFresh ? root.fc.flight_mode : qsTr("Not reported"); color: "#a9c2d3"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
                                }
                            }
                            FcDetailsRow { label: qsTr("Roll"); value: root.display("roll",1," deg"); implicitHeight: 29 }
                            FcDetailsRow { label: qsTr("Pitch"); value: root.display("pitch",1," deg"); implicitHeight: 29 }
                            FcDetailsRow { label: qsTr("Heading"); value: root.display("heading",0," deg"); implicitHeight: 29 }
                        }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 150; color: "#10384b" }
                        ColumnLayout { Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 4
                            FcDetailsRow { icon: "\uf1d8"; label: qsTr("Flight mode"); value: root.heartbeatFresh ? root.fc.flight_mode : qsTr("Not reported") }
                            FcDetailsRow { icon: "\uf0e8"; label: qsTr("Type"); value: root.hasMessage(0) ? root.fc.mav_type_str : qsTr("Not reported") }
                            FcDetailsRow { icon: "\uf2db"; label: qsTr("Firmware"); value: root.firmwareLabel }
                        }
                    }
                }
                GridLayout {
                    Layout.fillWidth: true; columns: root.width >= 650 ? 2 : 1; columnSpacing: 14; rowSpacing: 14
                    FcDetailsSection {
                        title: qsTr("Power"); icon: "\uf243"; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; Layout.fillHeight: true
                        FcDetailsRow {
                            objectName: "craftTelemetryTile_BATTERY"; icon: "\uf2c2"; label: qsTr("Battery")
                            value: root.display(root.has("packVoltage")?"packVoltage":"batteryPackVoltage",2," V") + (root.has("batteryPercent") ? " ("+root.reading("batteryPercent",0," %")+")" : "")
                            percent: root.has("batteryPercent") && root.observed.batteryPercent.valid !== false ? Number(root.observed.batteryPercent.value) : -1
                        }
                        FcDetailsRow { icon: "\uf5df"; label: qsTr("Average cell"); value: root.display("cellAverage",2," V") }
                        FcDetailsRow { icon: "\uf0e7"; label: qsTr("Current"); value: root.display("current",2," A") }
                        FcDetailsRow { icon: "\uf2db"; label: qsTr("Consumed"); value: root.display("consumedMah",0," mAh") }
                    }
                    FcDetailsSection {
                        title: qsTr("Navigation"); icon: "\uf3c5"; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; Layout.fillHeight: true
                        FcDetailsRow { icon: "\uf3c5"; label: qsTr("GPS"); value: root.has("gpsFix") ? root.fc.gps_status_fix_type_str : qsTr("Not reported"); detail: root.has("satellites") ? root.reading("satellites",0,qsTr(" satellites")) : "" }
                        FcDetailsRow { icon: "\uf21a"; label: qsTr("Relative altitude"); value: root.display("relativeAltitude",1," m") }
                        FcDetailsRow { icon: "\uf062"; label: qsTr("Climb rate"); value: root.display("climb",1," m/s") }
                        FcDetailsRow { icon: "\uf3fd"; label: qsTr("Ground speed"); value: root.display("groundSpeed",1," m/s") }
                    }
                }
                FcDetailsSection {
                    title: qsTr("Controller Health"); icon: "\uf2db"; Layout.fillWidth: true
                    GridLayout {
                        Layout.fillWidth: true; columns: root.width >= 650 ? 5 : 2; columnSpacing: 14
                        Repeater {
                            model: [{label: qsTr("FC load"),icon:"\uf2db",value:root.display("load",1," %")},
                                    {label:qsTr("RC signal"),icon:"\uf012",value:root.display("rcRssi",0," %")},
                                    {label:qsTr("Sensor temperature"),icon:"\uf2c9",value:root.display("sensorTemperature",1," C")},
                                    {label:qsTr("System health"),icon:"\uf071",value:root.healthText}]
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 7
                                Row { spacing: 9
                                    Text { text: modelData.icon; font.family:"Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon;color:"#b8d9ec" }
                                    Text { text: modelData.label; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;color:"#a9c2d3" }
                                }
                                Text { text:modelData.value;font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;color:index===3?root.healthColor:"#edf4fa" }
                            }
                        }
                        AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            objectName: "craftReboot"; text: qsTr("Reboot"); implicitWidth: 140; implicitHeight: MenuTypography.controlHeight
                            enabled: root.heartbeatFresh && !root.fc.armed && typeof root.fcAction.send_command_reboot === "function" && !(typeof _qopenhd !== "undefined" && _qopenhd.debugMenuPreview)
                            onClicked: rebootDialog.open()

                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; visible: root.hasCapacity || root.hasRemoteId
                    AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; objectName:"craftBatteryCapacityCard"; visible:root.hasCapacity; enabled:root.online&&!root.fc.armed; text:qsTr("Battery capacity: %1 mAh").arg(root.capacityParameter.value || "");onClicked:root.openCapacityEditor() }
                    AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; objectName:"craftRemoteIdCard"; visible:root.hasRemoteId; text:qsTr("Remote ID");onClicked:root.openRemoteId() }
                }
                ColumnLayout {
                    objectName:"craftHealthEvents";Layout.fillWidth:true;spacing:8;visible:root.hasHealth
                    Repeater { model:sensorRows; delegate: FcDetailsRow { icon:"\uf2db";label:entry.name;value:!root.sensorsFresh?qsTr("Not reported"):!entry.enabled?qsTr("Disabled"):entry.healthy?qsTr("Healthy"):qsTr("Fault");valueColor:entry.healthy?"#25d780":"#ff6470" } }
                    Text { visible:eventRows.count>0;text:qsTr("Recent FC Events");font.family: MenuTypography.family; font.pixelSize: MenuTypography.sectionTitle;font.bold:true;color:"#edf4fa";Layout.topMargin:8 }
                    Repeater { model:eventRows;delegate:Rectangle {
                        objectName:"craftEvent_"+index;Layout.fillWidth:true;implicitHeight:eventLabel.implicitHeight+42;radius:10;color:"#051f2f";border.color:"#0d4059"
                        Column { anchors.fill:parent;anchors.margins:12;spacing:6
                            Text { id:eventLabel;width:parent.width;text:entry.text;wrapMode:Text.WordWrap;color:entry.severity<=4?"#ff9b86":"#edf4fa";font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
                            Text {text:qsTr("%1 s ago - %2 occurrences").arg(Math.max(0,(root.diagnostics.nowMs-entry.receivedMs)/1000).toFixed(0)).arg(entry.count);font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;color:"#a9c2d3"}
                        }
                    } }
                }
            }
        }
    }
    AdvancedDialog {
        id: rebootDialog; objectName: "craftRebootDialog"
        title:qsTr("Reboot flight controller?");parent:Overlay.overlay;anchors.centerIn:parent
        width: Math.min(420, parent.width - 24)
        contentItem: Text { text: qsTr("The flight controller will briefly disconnect while it restarts."); wrapMode: Text.WordWrap; color: "#a9c2d3"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
        footer: DialogButtonBox {
            padding: 16; spacing: 10; background: Item {}
            AdvancedDialogButton { text: qsTr("Cancel"); onClicked: rebootDialog.reject() }
            AdvancedDialogButton { objectName: "craftRebootConfirm"; text: qsTr("Reboot"); destructive: true; enabled: root.heartbeatFresh && !root.fc.armed; onClicked: rebootDialog.accept() }
        }
        onAccepted: if(root.heartbeatFresh && !root.fc.armed) root.fcAction.send_command_reboot(true)
    }
}
