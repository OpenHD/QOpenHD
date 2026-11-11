import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography
import "JoystickMapping.js" as Mapping
import "RcRanges.js" as Ranges

Rectangle {
    id: root
    property var controller
    readonly property bool compact: width < 900
    readonly property var actions: [
        {rangeId:"RC_BW_RANGES", defaults:"1500:20,2100:40", values:[10,20,40], id:"BW_VIA_RC", name:qsTr("OpenHD channel width"), icon:"\uf03d", limits:[900,1300,1700,2100], labels:["10 MHz","20 MHz","40 MHz"]},
        {rangeId:"RC_MCS_RANGES", defaults:"1300:0,1700:2,2100:3", values:[0,1,2,3,4], id:"MCS_VIA_RC", name:qsTr("MCS (dynamic)"), icon:"\uf012", limits:[900,1200,1400,1600,1800,2100], labels:["MCS 0","MCS 1","MCS 2","MCS 3","MCS 4"]},
        {values:[0,1,2], id:"TXMODE_VIA_RC", name:qsTr("Transmit mode"), icon:"\uf519", limits:[900,1300,1700,2100], labels:[qsTr("Off"),qsTr("Pit"),qsTr("Normal")]},
        {values:[0,1], id:"FHSS_VIA_RC", name:qsTr("Frequency hopping"), icon:"\uf362", limits:[900,1500,2100], labels:[qsTr("Off"),qsTr("On")]}
    ]
    property var fcValues: []
    readonly property var fc: typeof _rcchannelsmodelfc !== "undefined" ? _rcchannelsmodelfc : null
    height: overview.implicitHeight + 28
    radius: 10
    color: settings_form.panelBackground
    border.color: settings_form.lineColor
    onVisibleChanged: if (!visible) editor.close()

    function supported(action) {
        controller.airRevision
        return controller.airParams && controller.airParams.system_is_alive() && controller.airParams.param_int_exists(action.id)
    }
    function assignment(action) {
        controller.airRevision
        return supported(action) ? controller.airParams.get_cached_int(action.id) : 0
    }
    function rangesSupported(action) {
        controller.airRevision
        return !!(supported(action) && action.rangeId && controller.airParams.param_string_exists(action.rangeId))
    }
    function rangeString(action) {
        controller.airRevision
        if (rangesSupported(action)) return controller.airParams.get_cached_string(action.rangeId)
        return action.values.map(function(value, i) { return action.limits[i+1] + ":" + value }).join(",")
    }
    function assignedActions(channel) {
        controller.airRevision
        return actions.filter(function(action) { return root.assignment(action) === channel })
    }
    function channelName(channel) {
        var names = assignedActions(channel).map(function(action) { return action.name })
        if (controller.luaBase > 0 && channel >= controller.luaBase && channel < controller.luaBase + 4)
            names.push(qsTr("OpenHD Lua · %1").arg(["D2","D1","D0","CLK"][channel-controller.luaBase]))
        if (!names.length) names.push(controller.mapping[channel-1] > 0 ? qsTr("Joystick → flight controller") : qsTr("Unassigned"))
        return names.join(" + ")
    }
    function pwm(channel) { return fcValues.length === 18 ? fcValues[channel-1] : -1 }
    function valid(value) { return value >= 800 && value <= 2200 }
    function openChannel(channel) {
        editor.channel = channel
        editor.input = controller.mapping[channel-1] || 0
        editor.originalMap = controller.savedMap
        editor.originalAssignments = actions.map(function(action) { return root.assignment(action) })
        editor.originalRanges = actions.map(function(action) { return root.rangeString(action) })
        editor.ranges = editor.originalRanges.map(function(text) { return Ranges.parse(text) })
        editor.selected = actions.map(function(action) { return root.assignment(action) === channel })
        editor.error = ""
        editor.savedChanges = false
        editor.learningTicks = 0
        editor.open()
    }
    Timer {
        interval: 100; running: root.visible; repeat: true; triggeredOnStart: true
        onTriggered: root.fcValues = root.fc && root.fc.is_alive && typeof root.fc.channelValues === "function" ? root.fc.channelValues() : []
    }

    Column {
        id: overview
        x: 14; y: 14; width: parent.width - 28; spacing: 0
        Label {
            width: parent.width; bottomPadding: 16
            text: qsTr("Channels Overview")
            color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.sectionTitle; font.bold: true
        }
        Label {
            width: parent.width; bottomPadding: 12
            text: qsTr("Select a channel to configure its input and OpenHD functions. Live PWM is reported by the flight controller.")
            wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper
        }
        RowLayout {
            width: parent.width; height: implicitHeight + 10; spacing: 12
            Label { text: qsTr("CH"); Layout.preferredWidth: 62; color: settings_form.secondaryText }
            Label { text: qsTr("Function"); Layout.fillWidth: true; Layout.minimumWidth: 0; color: settings_form.secondaryText }
            Label { visible: !root.compact; text: qsTr("Live PWM"); Layout.preferredWidth: 200; Layout.minimumWidth: 200; Layout.maximumWidth: 200; color: settings_form.secondaryText }
            Label { visible: !root.compact; text: qsTr("Range (µs)"); Layout.preferredWidth: 110; color: settings_form.secondaryText }
            Label { visible: !root.compact; text: qsTr("Status"); Layout.preferredWidth: 72; color: settings_form.secondaryText }
        }
        Repeater {
            model: 18
            ItemDelegate {
                id: row
                objectName: "joystickChannel" + (index+1)
                readonly property int channel: index+1
                readonly property var assigned: root.assignedActions(channel)
                readonly property bool used: assigned.length > 0 || controller.mapping[index] > 0 || (controller.luaBase > 0 && channel >= controller.luaBase && channel < controller.luaBase+4)
                readonly property int value: root.pwm(channel)
                width: parent.width; implicitHeight: root.compact ? 100 : 64
                hoverEnabled: true
                onClicked: root.openChannel(channel)
                background: Rectangle {
                    radius: 8
                    color: row.hovered || row.activeFocus ? settings_form.panelBackgroundRaised : "transparent"
                    border.color: row.activeFocus || (editor.opened && editor.channel === row.channel) ? settings_form.accentColor : settings_form.lineColor
                }
                contentItem: ColumnLayout {
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Label { text: "›  CH " + row.channel; Layout.preferredWidth: 62; color: settings_form.primaryText; font.bold: true }
                        Label { text: row.assigned.length ? row.assigned[0].icon : "\uf11b"; font.family: "Font Awesome 5 Free"; color: row.assigned.length ? settings_form.accentColor : settings_form.secondaryText; Layout.preferredWidth: 24 }
                        Label { text: root.channelName(row.channel); Layout.fillWidth: true; Layout.minimumWidth: 0; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; color: settings_form.primaryText; font.pixelSize: Typography.body }
                        ChannelPwmBar { visible: !root.compact; Layout.preferredWidth: 140; value: row.value }
                        Label { visible: !root.compact; Layout.preferredWidth: 48; text: root.valid(row.value) ? row.value : "—"; color: settings_form.primaryText }
                        Label { visible: !root.compact; Layout.preferredWidth: 110; text: row.assigned.length ? "900 – 2100" : "—"; color: settings_form.secondaryText }
                        Label {
                            visible: !root.compact; Layout.preferredWidth: 72; padding: 6; horizontalAlignment: Text.AlignHCenter
                            text: row.used ? qsTr("Used") : qsTr("Unused"); color: row.used ? "#75dd9a" : settings_form.secondaryText
                            background: Rectangle { radius: 7; color: row.used ? "#193c32" : settings_form.panelBackgroundRaised; border.color: row.used ? "#29644b" : settings_form.lineColor }
                        }
                    }
                    RowLayout {
                        visible: root.compact; Layout.fillWidth: true
                        ChannelPwmBar { Layout.fillWidth: true; value: row.value }
                        Label { text: root.valid(row.value) ? row.value + " µs" : qsTr("No FC data"); color: settings_form.secondaryText }
                    }
                }
            }
        }
    }

    Popup {
        id: editor
        objectName: "channelEditor"
        property int channel: 1
        property int input: 0
        property string originalMap: ""
        property var originalAssignments: []
        property var selected: []
        property var ranges: []
        property var originalRanges: []
        property string error: ""
        property bool savedChanges: false
        property var learningBaseline: []
        property int learningTicks: 0
        onClosed: learningTicks = 0
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(780, parent.width - 24)
        height: Math.min(760, parent.height - 24)
        modal: true; focus: true; padding: width < 500 ? 16 : 24
        closePolicy: Popup.CloseOnEscape
        background: Rectangle {
            radius: 18; color: settings_form.panelBackground; border.color: settings_form.lineColor
            Rectangle { x: 24; y: 0; width: parent.width - 48; height: 2; radius: 1; color: settings_form.accentColor }
        }
        function setAction(index, enabled) {
            if (controller.armed || (enabled && !root.supported(root.actions[index]))) return
            var next = selected.slice(); next[index] = enabled; selected = next
        }
        function editRanges(index, next) {
            if (controller.armed || !root.rangesSupported(root.actions[index])) return
            var draft = ranges.slice(); draft[index] = next; ranges = draft
        }
        function apply() {
            if (controller.armed) { error = qsTr("Disarm before changing RC settings."); return }
            if (controller.savedMap !== originalMap || root.actions.some(function(action,i) { return root.assignment(action) !== editor.originalAssignments[i] || root.rangeString(action) !== editor.originalRanges[i] })) {
                error = qsTr("Settings changed while editing. Close and reopen this channel."); return
            }
            // Validate all drafts before the first device write.
            for (var check=0; check<root.actions.length; ++check) {
                if (!selected[check]) continue
                var checkedAction = root.actions[check]
                if (!Ranges.valid(ranges[check], checkedAction.values)) { error = qsTr("Invalid areas. Use increasing PWM boundaries covering 900–2100 µs."); return }
                if (Ranges.encode(ranges[check]) !== originalRanges[check] && !root.rangesSupported(checkedAction)) { error = qsTr("Update the Air firmware to customize ranges."); return }
            }
            // Save complete profiles before enabling a new channel assignment.
            for (var rangeIndex=0; rangeIndex<root.actions.length; ++rangeIndex) {
                if (!selected[rangeIndex]) continue
                var rangeAction = root.actions[rangeIndex], encoded = Ranges.encode(ranges[rangeIndex])
                if (encoded === originalRanges[rangeIndex]) continue
                if (!controller.write(controller.airParams, rangeAction.rangeId, encoded, true)) { error = controller.message; return }
                savedChanges = true
                var rangeSnapshot = originalRanges.slice(); rangeSnapshot[rangeIndex] = encoded; originalRanges = rangeSnapshot
            }
            for (var i=0; i<root.actions.length; ++i) {
                var action = root.actions[i]
                var next = selected[i] ? channel : (originalAssignments[i] === channel ? 0 : originalAssignments[i])
                if (next === originalAssignments[i]) continue
                if (!root.supported(action)) { error = qsTr("Air unit disconnected or function unavailable."); return }
                if (!controller.write(controller.airParams, action.id, next, false)) { error = controller.message; return }
                savedChanges = true
                var snapshot = originalAssignments.slice(); snapshot[i] = next; originalAssignments = snapshot
            }
            if (controller.mapping[channel-1] !== input && controller.mapping.length === 18) {
                if (!controller.available) { error = qsTr("Connect the Ground unit to save the input assignment."); return }
                var nextMap = controller.mapping.slice()
                if (controller.modern) nextMap = Mapping.assign(nextMap, channel-1, input)
                else nextMap[channel-1] = input
                if (!controller.write(controller.groundParams, "RC_CHAN_MAP", nextMap.join(","), true)) { error = controller.message; return }
                controller.mapping = nextMap
                controller.loadedMap = nextMap.join(",")
            }
            close()
        }
        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                RowLayout {
                    Layout.fillWidth: true; spacing: 14
                    Rectangle {
                        Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 13
                        color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                        Label { anchors.centerIn: parent; text: ("0" + editor.channel).slice(-2); font.family: Typography.family; font.pixelSize: 22; font.bold: true; color: settings_form.accentColor }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: qsTr("Channel %1").arg(editor.channel); font.family: Typography.family; font.bold: true; font.pixelSize: Typography.sectionTitle; color: settings_form.primaryText }
                        Label { text: qsTr("Input & functions"); color: settings_form.secondaryText; font.pixelSize: Typography.helper }
                    }
                    Label {
                        text: root.valid(root.pwm(editor.channel)) ? root.pwm(editor.channel) + " µs" : qsTr("No signal")
                        color: root.valid(root.pwm(editor.channel)) ? settings_form.accentColor : settings_form.secondaryText
                        font.family: Typography.family; font.pixelSize: Typography.helper
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                Flickable {
                    id: editorScroll
                    objectName: "channelEditorScroll"
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 0
                    clip: true; contentHeight: editorContent.implicitHeight; contentWidth: width
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }
                    Column {
                        id: editorContent; width: editorScroll.width; spacing: 16
                        Label { text: qsTr("Joystick input"); font.bold: true; color: settings_form.primaryText; font.pixelSize: Typography.body }
                        Label { width: parent.width; text: qsTr("Choose an input or move a control to detect it."); wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
                        CompactLinkComboBox {
                            objectName: "channelInput"; width: parent.width; popupWidth: width
                            property var sources: { var a=[]; if(controller.modern)a.push({text:qsTr("Unassigned"),value:0}); for(var j=1;j<=18;j++)a.push({text:Mapping.sourceName(j),value:j}); return a }
                            model: sources; textRole: "text"; currentIndex: editor.input-(controller.modern?0:1)
                            enabled: controller.available && !controller.armed
                            onActivated: editor.input = sources[currentIndex].value
                        }
                        AdvancedActionButton {
                            objectName: "channelDetectInput"; width: parent.width
                            iconText: "\uf05b"
                            text: editor.learningTicks > 0 ? qsTr("Move one stick or switch…") : qsTr("Detect input")
                            enabled: controller.monitoring && !controller.armed
                            onClicked: { editor.learningBaseline = controller.inputs.channelValues(); editor.learningTicks = 100; editor.error = "" }
                        }
                        Rectangle { width: parent.width; height: 1; color: settings_form.lineColor }
                        Label { text: qsTr("OpenHD functions"); font.bold: true; color: settings_form.primaryText; font.pixelSize: Typography.body }
                        CompactLinkComboBox {
                            id: functionPicker
                            objectName: "channelFunctionPicker"; width: parent.width; popupWidth: width
                            model: {
                                controller.airRevision
                                var options = [{text: qsTr("Add a function…"), actionIndex: -1}]
                                for (var i=0; i<root.actions.length; ++i) {
                                    if (editor.selected[i] || !root.supported(root.actions[i])) continue
                                    var assigned = root.assignment(root.actions[i])
                                    options.push({text: root.actions[i].name + (assigned > 0 && assigned !== editor.channel ? qsTr(" · move from CH %1").arg(assigned) : ""), actionIndex: i})
                                }
                                return options
                            }
                            textRole: "text"; currentIndex: 0
                            enabled: model.length > 1 && !controller.armed
                            onActivated: {
                                var actionIndex = model[currentIndex].actionIndex
                                if (actionIndex >= 0) editor.setAction(actionIndex, true)
                                currentIndex = 0
                            }
                        }
                        Label {
                            width: parent.width; visible: !editor.selected.some(function(value) { return value })
                            text: qsTr("Add one or more functions to this channel.")
                            wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper
                        }
                        Repeater {
                            model: root.actions
                            Rectangle {
                                id: actionSection
                                readonly property var action: modelData
                                readonly property int actionIndex: index
                                visible: editor.selected[actionIndex] === true
                                width: parent.width; height: actionContent.implicitHeight + 28; radius: 12
                                color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                                Column {
                                    id: actionContent
                                    x: 14; y: 14; width: parent.width - 28; spacing: 12
                                    RowLayout {
                                        width: parent.width; spacing: 10
                                        Label { text: actionSection.action.icon; font.family: "Font Awesome 5 Free"; color: settings_form.accentColor }
                                        Label { Layout.fillWidth: true; Layout.minimumWidth: 0; text: actionSection.action.name; wrapMode: Text.WordWrap; font.bold: true; font.pixelSize: Typography.body; color: settings_form.primaryText }
                                        ToolButton {
                                            objectName: "channelAction" + actionSection.actionIndex
                                            text: "×"; implicitWidth: 32; implicitHeight: 32; enabled: !controller.armed
                                            ToolTip.visible: hovered; ToolTip.text: qsTr("Remove function")
                                            contentItem: Label { text: parent.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: settings_form.secondaryText; font.pixelSize: 24 }
                                            onClicked: editor.setAction(actionSection.actionIndex, false)
                                            Accessible.name: qsTr("Remove %1").arg(actionSection.action.name)
                                        }
                                    }
                                    Label { width: parent.width; visible: !root.supported(actionSection.action); text: qsTr("Air unit disconnected or function unavailable."); wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
                                    ChannelRangeEditor {
                                        width: parent.width
                                        actionIndex: actionSection.actionIndex
                                        ranges: editor.ranges[actionIndex] || []
                                        options: actionSection.action.values.map(function(value, i) { return {text: actionSection.action.labels[i], value: value} })
                                        editable: root.rangesSupported(actionSection.action) && !controller.armed
                                        live: root.pwm(editor.channel)
                                        onEdited: function(next) { editor.editRanges(actionIndex, next) }
                                        onResetRequested: editor.editRanges(actionIndex, Ranges.parse(actionSection.action.defaults))
                                    }
                                    Label {
                                        width: parent.width; visible: !!actionSection.action.rangeId && !root.rangesSupported(actionSection.action)
                                        text: qsTr("Update the Air firmware to add areas and customize their values.")
                                        wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper
                                    }
                                }
                            }
                        }
                        Label { width: parent.width; text: qsTr("Ranges follow flight-controller PWM. Configure flight controls and modes in your flight controller."); wrapMode: Text.WordWrap; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
                    }
                }
                Label { Layout.fillWidth: true; visible: editor.error.length > 0; text: (editor.savedChanges ? qsTr("Some changes were saved. ") : "") + editor.error; wrapMode: Text.WordWrap; color: "#ff7b85"; font.pixelSize: Typography.helper }
                Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
                RowLayout {
                    Layout.fillWidth: true
                    AdvancedActionButton { text: qsTr("Cancel"); onClicked: editor.close() }
                    Item { Layout.fillWidth: true }
                    AdvancedActionButton { objectName: "channelApply"; text: qsTr("Apply"); primary: true; enabled: !controller.armed; onClicked: editor.apply() }
                }
            }
        }
        Timer {
            interval: 100; running: editor.opened && editor.learningTicks > 0; repeat: true
            onTriggered: {
                if (!controller.monitoring || controller.armed) { editor.learningTicks = 0; return }
                var moved = Mapping.movedInput(editor.learningBaseline, controller.inputs.channelValues())
                if (moved >= 0) { editor.input = moved+1; editor.learningTicks = 0 }
                else if (--editor.learningTicks === 0) editor.error = qsTr("No clear movement detected. Try again.")
            }
        }
    }
}
