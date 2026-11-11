import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography
import "RcRanges.js" as Ranges

Item {
    id: root
    property var controller
    readonly property bool compact: width < 900
    readonly property var actions: [
        {rangeId:"RC_BW_RANGES", defaults:"1500:20,2100:40", legacy:"1300:10,1700:20,2100:40", values:[10,20,40], id:"BW_VIA_RC", name:qsTr("OpenHD channel width"), icon:"\uf03d", labels:["10 MHz","20 MHz","40 MHz"]},
        {rangeId:"RC_MCS_RANGES", defaults:"1300:0,1700:2,2100:3", legacy:"1200:0,1400:1,1600:2,1800:3,2100:4", values:[0,1,2,3,4], id:"MCS_VIA_RC", name:qsTr("MCS (dynamic)"), icon:"\uf012", labels:["MCS 0","MCS 1","MCS 2","MCS 3","MCS 4"]},
        {rangeId:"RC_TX_RANGES", defaults:"1300:0,1700:1,2100:2", values:[0,1,2], id:"TXMODE_VIA_RC", name:qsTr("Transmit mode"), icon:"\uf519", labels:[qsTr("Off"),qsTr("Pit"),qsTr("Normal")]}
    ]
    readonly property int keyboardAction: actions.length
    readonly property var keyboardOptions: Ranges.keyboardOptions()
    readonly property var keyboardProfiles: Ranges.keyboardProfiles(settings.rc_keyboard_mappings)
    readonly property string defaultKeyboardRanges: "1500:0,2100:0"
    property var fcValues: []
    readonly property var fc: typeof _rcchannelsmodelfc !== "undefined" ? _rcchannelsmodelfc : null
    readonly property var airLink: typeof _ohdSystemAir !== "undefined" ? _ohdSystemAir : null
    height: overview.implicitHeight
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
        return action.legacy || action.defaults
    }
    function assignedActions(channel) {
        controller.airRevision
        return actions.filter(function(action) { return root.assignment(action) === channel })
    }
    function channelName(channel) {
        var names = assignedActions(channel).map(function(action) { return action.name })
        if (keyboardProfiles[channel]) names.push(qsTr("Keyboard"))
        if (controller.luaBase > 0 && channel >= controller.luaBase && channel < controller.luaBase + 4)
            names.push(qsTr("OpenHD Lua · %1").arg(["D2","D1","D0","CLK"][channel-controller.luaBase]))
        if (!names.length) names.push(qsTr("Unassigned"))
        return names.join(" + ")
    }
    function pwm(channel) { return fcValues.length === 18 ? fcValues[channel-1] : -1 }
    function valid(value) { return value >= 800 && value <= 2200 }
    function openChannel(channel) {
        editor.channel = channel
        editor.originalAssignments = actions.map(function(action) { return root.assignment(action) })
        editor.originalRanges = actions.map(function(action) { return root.rangeString(action) })
        editor.ranges = editor.originalRanges.map(function(text) { return Ranges.parse(text) })
        editor.keyboardRanges = keyboardProfiles[channel] || Ranges.parse(defaultKeyboardRanges)
        editor.selectedAction = keyboardProfiles[channel] ? keyboardAction : editor.originalAssignments.indexOf(channel)
        editor.error = ""
        editor.savedChanges = false
        editor.open()
    }
    Timer {
        interval: 100; running: root.visible; repeat: true; triggeredOnStart: true
        onTriggered: root.fcValues = root.fc && root.fc.is_alive && typeof root.fc.channelValues === "function" ? root.fc.channelValues() : []
    }

    Column {
        id: overview
        width: parent.width; spacing: 6
        Repeater {
            model: 18
            ItemDelegate {
                id: row
                objectName: "joystickChannel" + (index+1)
                readonly property int channel: index+1
                readonly property var assigned: root.assignedActions(channel)
                readonly property bool hasKeyboard: !!root.keyboardProfiles[channel]
                readonly property bool used: hasKeyboard || assigned.length > 0 || (controller.luaBase > 0 && channel >= controller.luaBase && channel < controller.luaBase+4)
                readonly property int value: root.pwm(channel)
                width: parent.width; implicitHeight: root.compact ? 100 : 64
                hoverEnabled: true
                onClicked: root.openChannel(channel)
                background: Rectangle {
                    radius: 8
                    color: row.hovered || row.activeFocus ? settings_form.panelBackgroundRaised : settings_form.panelBackground
                    border.color: row.activeFocus || (editor.opened && editor.channel === row.channel) ? settings_form.accentColor : settings_form.lineColor
                }
                contentItem: ColumnLayout {
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Label { text: "›  CH " + row.channel; Layout.preferredWidth: 62; color: settings_form.primaryText; font.bold: true }
                        Label { text: row.hasKeyboard ? "\uf11c" : row.assigned.length ? row.assigned[0].icon : "\uf1de"; font.family: "Font Awesome 5 Free"; color: row.used ? settings_form.accentColor : settings_form.secondaryText; Layout.preferredWidth: 24 }
                        Label { text: root.channelName(row.channel); Layout.fillWidth: true; Layout.minimumWidth: 0; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; color: settings_form.primaryText; font.pixelSize: Typography.body }
                        ChannelPwmBar { visible: !root.compact; Layout.preferredWidth: 140; value: row.value }
                        Label { visible: !root.compact; Layout.preferredWidth: 48; text: root.valid(row.value) ? row.value : "—"; color: settings_form.primaryText }
                        Label { visible: !root.compact; Layout.preferredWidth: 110; text: row.hasKeyboard || row.assigned.length ? "900 – 2100" : "—"; color: settings_form.secondaryText }
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
        property var originalAssignments: []
        property int selectedAction: -1
        readonly property var selected: root.actions.map(function(action, i) { return i === editor.selectedAction })
        property var ranges: []
        property var keyboardRanges: []
        property var originalRanges: []
        property string error: ""
        property bool savedChanges: false
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(780, parent.width - 24)
        height: Math.min(parent.height - 24, Math.max(300, editorContent.implicitHeight + padding*2 + 156))
        modal: true; focus: true; padding: width < 500 ? 16 : 24
        closePolicy: Popup.CloseOnEscape
        onAboutToShow: {
            if (typeof hudOverlayGrid !== "undefined" && hudOverlayGrid.rcKeyboardEditor !== undefined)
                hudOverlayGrid.rcKeyboardEditor = editor
        }
        background: Rectangle {
            radius: 18; color: settings_form.panelBackground; border.color: settings_form.lineColor
            Rectangle { x: 24; y: 0; width: parent.width - 48; height: 2; radius: 1; color: settings_form.accentColor }
        }
        function selectAction(index) {
            if (controller.armed || (index >= 0 && index !== root.keyboardAction && !root.supported(root.actions[index]))) return
            selectedAction = index
        }
        function editRanges(index, next) {
            if (controller.armed || !root.rangesSupported(root.actions[index])) return
            var draft = ranges.slice(); draft[index] = next; ranges = draft
        }
        function apply() {
            if (controller.armed) { error = qsTr("Disarm before changing RC settings."); return }
            if (selectedAction === root.keyboardAction &&
                    (!Ranges.valid(keyboardRanges, root.keyboardOptions.map(function(option) { return option.value }))
                     || !keyboardRanges.some(function(range) { return range.value !== 0 }))) {
                error = qsTr("Choose a direction for at least one PWM range.")
                return
            }
            if (root.actions.some(function(action,i) { return root.assignment(action) !== editor.originalAssignments[i] || root.rangeString(action) !== editor.originalRanges[i] })) {
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
            // Release the old function before assigning the replacement.
            for (var pass=0; pass<2; ++pass) {
                for (var i=0; i<root.actions.length; ++i) {
                    var action = root.actions[i]
                    var next = selected[i] ? channel : (originalAssignments[i] === channel ? 0 : originalAssignments[i])
                    if (next === originalAssignments[i] || (pass === 0 ? next !== 0 : next === 0)) continue
                    if (!root.supported(action)) { error = qsTr("Air unit disconnected or function unavailable."); return }
                    if (!controller.write(controller.airParams, action.id, next, false)) { error = controller.message; return }
                    savedChanges = true
                    var snapshot = originalAssignments.slice(); snapshot[i] = next; originalAssignments = snapshot
                }
            }
            if (selectedAction === root.keyboardAction || root.keyboardProfiles[channel]) {
                var profiles = Object.assign({}, root.keyboardProfiles)
                if (selectedAction === root.keyboardAction) profiles[channel] = keyboardRanges
                else delete profiles[channel]
                settings.rc_keyboard_mappings = Ranges.encodeKeyboardProfiles(profiles)
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
                        Label { text: qsTr("Function"); font.bold: true; color: settings_form.primaryText; font.pixelSize: Typography.body }
                        CompactLinkComboBox {
                            id: functionPicker
                            objectName: "channelFunctionPicker"; width: parent.width; popupWidth: width
                            model: {
                                controller.airRevision
                                var options = [{text: qsTr("Unassigned"), actionIndex: -1}]
                                for (var i=0; i<root.actions.length; ++i) {
                                    if (!root.supported(root.actions[i]) && editor.selectedAction !== i) continue
                                    options.push({text: root.actions[i].name, actionIndex: i})
                                }
                                options.push({text: qsTr("Keyboard"), actionIndex: root.keyboardAction})
                                return options
                            }
                            textRole: "text"
                            currentIndex: {
                                for (var i=0; i<model.length; ++i) if (model[i].actionIndex === editor.selectedAction) return i
                                return 0
                            }
                            enabled: !controller.armed
                            onActivated: {
                                editor.selectAction(model[currentIndex].actionIndex)
                            }
                        }
                        ChannelRangeEditor {
                            visible: editor.selectedAction === root.keyboardAction
                            width: parent.width
                            actionIndex: root.keyboardAction
                            addedAreaValue: 0
                            ranges: editor.keyboardRanges
                            options: root.keyboardOptions
                            editable: !controller.armed
                            live: root.pwm(editor.channel)
                            onEdited: function(next) { editor.keyboardRanges = next }
                            onResetRequested: editor.keyboardRanges = Ranges.parse(root.defaultKeyboardRanges)
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
                                    Label {
                                        objectName: "channelLiveRadio"
                                        visible: actionSection.action.id === "BW_VIA_RC"
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        color: settings_form.secondaryText
                                        font.pixelSize: Typography.helper
                                        text: root.airLink && root.airLink.is_alive && root.airLink.curr_channel_mhz > 0
                                            && root.airLink.curr_channel_width_mhz > 0
                                            ? qsTr("Air link: %1 MHz · %2 MHz width").arg(root.airLink.curr_channel_mhz).arg(root.airLink.curr_channel_width_mhz)
                                            : qsTr("Air link frequency and width unavailable")
                                    }
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
                                        visible: root.supported(actionSection.action) && !root.rangesSupported(actionSection.action)
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        color: settings_form.secondaryText
                                        font.pixelSize: Typography.helper
                                        text: qsTr("Update the Air firmware to edit these ranges.")
                                    }
                                }
                            }
                        }
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
    }
}
