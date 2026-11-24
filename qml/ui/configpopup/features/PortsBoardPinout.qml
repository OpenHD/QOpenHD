import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../qopenhd_settings"
import "../MenuTypography.js" as Typography
import "PortsBoardProfiles.js" as Boards

MapSettingsCard {
    id: root
    objectName: "portsBoardPinout"

    property int platform: -1
    property bool air: true
    property bool advanced: false
    property bool connected: false
    property var settingsModel
    property int inspectedPin: 0
    signal backRequested()
    signal pinFocused(Item item)

    readonly property string deviceModel: {
        if (!connected || !settingsModel) return ""
        settingsModel.update_count
        var params = air ? ["FC_UART_CONN", "OHD_UART_TLM", "SBUS_DEV"] : ["TRACKER_UART_OUT", "OHD_UART_TLM"]
        for (var i = 0; i < params.length; ++i) {
            if (!settingsModel.param_string_exists(params[i])) continue
            var model = settingsModel.get_ui_metadata(params[i]).serialBoardModel
            if (model) return model
        }
        return ""
    }
    readonly property var profile: Boards.profile(platform, deviceModel)
    readonly property var pinNames: profile.pins
    readonly property var auxPins: profile.aux
    readonly property bool hasPinout: pinNames.length > 0
    readonly property bool schematic: !hasPinout
    readonly property bool raspberryGpio: ["pi-zero", "pi3", "pi4", "pi5"].indexOf(profile.art) >= 0
    readonly property var assignments: {
        if (!settingsModel) return []
        settingsModel.update_count
        var roles = air ? [{id: "FC_UART_CONN", label: qsTr("FC telemetry")}] :
                          [{id: "TRACKER_UART_OUT", label: qsTr("Tracker"), txOnly: true}]
        if (advanced && air)
            roles.push({id: "SBUS_DEV", enable: "SBUS_EN", label: qsTr("SBUS"), txOnly: true})
        if (advanced)
            roles.push({id: "OHD_UART_TLM", enable: "OHD_UART_EN", label: qsTr("OpenHD link")})

        return roles.reduce(function(list, role) {
            if (!settingsModel.param_string_exists(role.id) ||
                    (role.enable && (!settingsModel.param_int_exists(role.enable) ||
                                     !settingsModel.get_cached_int(role.enable)))) return list
            var value = settingsModel.get_cached_string(role.id)
            if (!value) return list
            var meta = settingsModel.get_ui_metadata(role.id)
            var port = meta.serialConfigured === value && meta.serialResolved ? meta.serialResolved : value
            var pins = hasPinout && meta.serialHeaderRoutes ? meta.serialHeaderRoutes[port] : null
            list.push({label: role.label, port: port, rx: pins && !role.txOnly ? pins.rx : 0,
                       tx: pins ? pins.tx : 0})
            return list
        }, [])
    }
    readonly property var highlights: {
        var result = {}
        if (!connected || !settingsModel || !hasPinout) return result
        settingsModel.update_count

        function add(pin, label, signal, color) {
            if (typeof pin !== "number" || pin % 1 !== 0 || pin < 1 || pin > pinNames.length) return
            var existing = result[pin]
            if (existing) {
                existing.label += " / " + label
                return
            }
            result[pin] = {label: label, signal: signal, color: color}
        }
        for (var i = 0; i < assignments.length; ++i) {
            var role = assignments[i]
            add(role.rx, role.label, "RX", "#16c4f3")
            add(role.tx, role.label, "TX", "#66e88a")
        }
        if (Object.keys(result).length && pinNames[5] === "GND")
            add(6, qsTr("Reference"), "GND", "#c0c9da")
        if (raspberryGpio) {
            var gpios = [{id: "GPIO_2", pin: 3}, {id: "GPIO_26", pin: 37}]
            for (var j = 0; j < gpios.length; ++j) {
                var gpio = gpios[j]
                if (!settingsModel.param_int_exists(gpio.id)) continue
                var value = settingsModel.get_cached_int(gpio.id)
                if (value === 1 || value === 2)
                    add(gpio.pin, pinNames[gpio.pin - 1], value === 1 ? qsTr("High") : qsTr("Low"), "#ffbb69")
            }
        }
        return result
    }
    readonly property bool sideBySide: contentWidth >= 650
    readonly property int rowPitch: sideBySide ? Math.min(22, Math.floor(contentWidth * 0.41 * boardArt.headerPitch / 298)) : 24
    readonly property real artScale: sideBySide ? rowPitch / boardArt.headerPitch : 0
    function functionForPin(pin) {
        return Boards.pinFunction(profile.art, pin)
    }

    readonly property var focusedAssignment: highlights[inspectedPin] || null

    onProfileChanged: inspectedPin = 0
    onAirChanged: inspectedPin = 0
    title: hasPinout ? qsTr("%1 · Pinout").arg(profile.name) : profile.name
    icon: "\uf2db"
    compact: true

    GridLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 0
        columns: root.hasPinout && root.sideBySide ? 2 : 1
        columnSpacing: 20
        rowSpacing: 10

        PortsBoardArt {
            id: boardArt
            objectName: "portsBoardArt"
            Layout.fillWidth: true
            Layout.preferredWidth: 220
            Layout.minimumWidth: 0
            Layout.preferredHeight: root.hasPinout && root.sideBySide ? root.artScale * boardArt.drawingHeight + 16 : root.hasPinout ? 220 : 150
            Layout.alignment: Qt.AlignTop
            alignedScale: root.hasPinout ? root.artScale : 0
            board: root.profile
            highlights: root.highlights
            inspectedPin: root.inspectedPin
        }

        Rectangle {
            visible: root.hasPinout
            Layout.fillWidth: true
            Layout.preferredWidth: 315
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignTop
            implicitHeight: headerColumn.implicitHeight + 20
            color: settings_form.pageBackground
            border.color: settings_form.lineColor
            radius: 10

            ColumnLayout {
                id: headerColumn
                x: 10
                y: 10
                width: parent.width - 20
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    id: headerTitle
                    text: qsTr("GPIO header · 2 × %1").arg(root.pinNames.length / 2)
                    color: settings_form.primaryText
                    font.family: Typography.family
                    font.pixelSize: Typography.sectionTitle
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: root.sideBySide
                        ? Math.max(0, boardArt.pinCenterY(1) - headerColumn.y -
                                   headerTitle.implicitHeight - headerColumn.spacing - root.rowPitch / 2) : 0
                    columns: 2
                    columnSpacing: 9
                    rowSpacing: 1

                    Repeater {
                        model: root.pinNames.length
                        delegate: Button {
                            id: pinButton
                            readonly property int pin: index + 1
                            readonly property bool odd: pin % 2 === 1
                            readonly property var assignment: root.highlights[pin] || null
                            readonly property string pinName: root.pinNames[index]
                            readonly property string alternate: root.functionForPin(pin)
                            readonly property color pinColor: assignment ? assignment.color :
                                pinName === "GND" ? settings_form.secondaryText :
                                pinName.indexOf(" V") >= 0 ? "#d89c52" : settings_form.lineColor

                            objectName: "portsHeaderPin" + pin
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: root.rowPitch - 1
                            Layout.minimumHeight: Layout.preferredHeight
                            Layout.maximumHeight: Layout.preferredHeight
                            padding: 2
                            topInset: 0
                            bottomInset: 0
                            leftInset: 0
                            rightInset: 0
                            hoverEnabled: true
                            Accessible.name: qsTr("Pin %1, %2").arg(pin).arg(pinName) +
                                (alternate ? ", " + qsTr("Alternate function: %1").arg(alternate) : "") +
                                (assignment ? ", " + assignment.label + " " + assignment.signal : "")
                            onClicked: root.inspectedPin = root.inspectedPin === pin ? 0 : pin
                            onActiveFocusChanged: if (activeFocus) root.pinFocused(pinButton)
                            ToolTip.visible: hovered
                            ToolTip.delay: 350
                            ToolTip.text: Accessible.name
                            Keys.onEscapePressed: root.backRequested()
                            background: Rectangle {
                                radius: 5
                                color: pinButton.hovered || root.inspectedPin === pinButton.pin || pinButton.assignment
                                       ? settings_form.panelBackgroundRaised : "transparent"
                                border.width: pinButton.visualFocus || root.inspectedPin === pinButton.pin ? 1 : 0
                                border.color: settings_form.accentColor
                            }
                            contentItem: RowLayout {
                                layoutDirection: pinButton.odd ? Qt.RightToLeft : Qt.LeftToRight
                                spacing: 4
                                Rectangle {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    radius: pinButton.pin === 1 ? 3 : 7
                                    color: settings_form.panelBackground
                                    border.width: pinButton.assignment ? 2 : 1
                                    border.color: pinButton.pinColor
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 5; height: 5; radius: 3
                                        color: pinButton.pinColor
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: 19
                                    text: pinButton.pin
                                    color: settings_form.primaryText
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Typography.family
                                    font.pixelSize: Typography.helper
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: pinButton.assignment ? pinButton.assignment.signal + " · " + pinButton.assignment.label
                                                               : pinButton.pinName + (pinButton.alternate ? " · " + pinButton.alternate : "")
                                    horizontalAlignment: pinButton.odd ? Text.AlignRight : Text.AlignLeft
                                    elide: Text.ElideRight
                                    color: pinButton.assignment && settings_form.darkMode ? pinButton.pinColor : settings_form.secondaryText
                                    font.family: Typography.family
                                    font.pixelSize: Typography.helper
                                    font.bold: !!pinButton.assignment
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.schematic
        text: root.deviceModel && root.deviceModel !== root.profile.name
              ? qsTr("%1 · Connector pinout unavailable").arg(root.deviceModel)
              : qsTr("Connector pinout unavailable")
        color: settings_form.secondaryText
        font.family: Typography.family
        font.pixelSize: Typography.helper
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.auxPins.length > 0

        Text {
            text: qsTr("Auxiliary GPIO header · 1 × %1").arg(root.auxPins.length)
            color: settings_form.primaryText
            font.family: Typography.family
            font.pixelSize: Typography.sectionTitle
            font.bold: true
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            columns: Math.max(1, Math.min(root.auxPins.length, Math.floor(root.contentWidth / 58)))
            rowSpacing: 5
            columnSpacing: 5

            Repeater {
                model: root.auxPins
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 53
                    Layout.preferredHeight: 24
                    color: settings_form.pageBackground
                    border.color: settings_form.lineColor
                    radius: 5
                    Text {
                        id: auxLabel
                        anchors.centerIn: parent
                        text: (index + 1) + " · " + modelData
                        color: settings_form.secondaryText
                        font.family: Typography.family
                        font.pixelSize: Typography.helper
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.inspectedPin > 0
        text: root.inspectedPin ? qsTr("Pin %1 · %2").arg(root.inspectedPin).arg(root.pinNames[root.inspectedPin - 1]) +
              (root.functionForPin(root.inspectedPin) ? " · " + root.functionForPin(root.inspectedPin) : "") +
              (root.focusedAssignment ? " · " + root.focusedAssignment.label + " " + root.focusedAssignment.signal : "") : ""
        color: settings_form.primaryText
        font.family: Typography.family
        font.pixelSize: Typography.body
        wrapMode: Text.Wrap
    }

    Repeater {
        model: root.connected ? root.assignments.filter(function(role) { return !role.rx && !role.tx }) : []
        Text {
            Layout.fillWidth: true
            text: qsTr("%1 · %2 · No header mapping reported").arg(modelData.label).arg(modelData.port)
            color: settings_form.secondaryText
            font.family: Typography.family
            font.pixelSize: Typography.helper
            wrapMode: Text.Wrap
        }
    }
}
