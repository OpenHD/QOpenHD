import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../qopenhd_settings"
import "../MenuTypography.js" as Typography

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

    // Platform IDs from openhd_platform.h. Compute-module carrier mappings vary.
    readonly property bool radxa: platform === 20
    readonly property bool supported: radxa || platform === 11 || platform === 13
    readonly property var pinNames: radxa ? [
        "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "GPIO3_C4", "GPIO0_D1",
        "GND", "GPIO0_D0", "GPIO3_A1", "GPIO3_A3", "GPIO3_A2", "GND", "GPIO3_B0", "GPIO3_B1",
        "3.3 V", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "GPIO3_C1", "GPIO4_C2", "GPIO4_C6",
        "GND", "NC", "GPIO4_B2", "GPIO4_B3", "GPIO3_B3", "GND", "GPIO3_B4", "GPIO3_C2",
        "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A7", "GPIO1_A4", "GPIO3_A6", "GND", "GPIO3_A5"
    ] : [
        "3.3 V", "5 V", "GPIO 2", "5 V", "GPIO 3", "GND", "GPIO 4", "GPIO 14",
        "GND", "GPIO 15", "GPIO 17", "GPIO 18", "GPIO 27", "GND", "GPIO 22", "GPIO 23",
        "3.3 V", "GPIO 24", "GPIO 10", "GND", "GPIO 9", "GPIO 25", "GPIO 11", "GPIO 8",
        "GND", "GPIO 7", "GPIO 0", "GPIO 1", "GPIO 5", "GND", "GPIO 6", "GPIO 12",
        "GPIO 13", "GND", "GPIO 19", "GPIO 16", "GPIO 26", "GPIO 20", "GND", "GPIO 21"
    ]
    readonly property var assignments: {
        if (!settingsModel || !supported) return []
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
            var pins = radxa && meta.serialHeaderRoutes ? meta.serialHeaderRoutes[port] : null
            list.push({label: role.label, port: port, rx: pins && !role.txOnly ? pins.rx : 0,
                       tx: pins ? pins.tx : 0})
            return list
        }, [])
    }
    readonly property var highlights: {
        var result = {}
        if (!connected || !settingsModel || !supported) return result
        settingsModel.update_count

        function add(pin, label, signal, color) {
            if (typeof pin !== "number" || pin % 1 !== 0 || pin < 1 || pin > 40) return
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
        if (Object.keys(result).length)
            add(6, qsTr("Reference"), "GND", "#c0c9da")
        if (!radxa) {
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
    readonly property var focusedAssignment: highlights[inspectedPin] || null

    onPlatformChanged: inspectedPin = 0
    onAirChanged: inspectedPin = 0
    title: radxa ? qsTr("Radxa ZERO 3W · Pinout") : platform === 13 ? qsTr("Raspberry Pi 5 · Pinout") : qsTr("Raspberry Pi 4 Model B · Pinout")
    headerNote: air ? qsTr("Air") : qsTr("Ground")
    icon: "\uf2db"
    compact: true

    GridLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 0
        columns: root.sideBySide ? 2 : 1
        columnSpacing: 20
        rowSpacing: 10

        PortsBoardArt {
            id: boardArt
            objectName: "portsBoardArt"
            Layout.fillWidth: true
            Layout.preferredWidth: 220
            Layout.minimumWidth: 0
            Layout.preferredHeight: root.sideBySide ? root.artScale * 426 + 16 : 220
            Layout.alignment: Qt.AlignTop
            alignedScale: root.artScale
            platform: root.platform
            highlights: root.highlights
            inspectedPin: root.inspectedPin
        }

        Rectangle {
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
                    text: qsTr("GPIO header · 2 × 20")
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
                        model: 40
                        delegate: Button {
                            id: pinButton
                            readonly property int pin: index + 1
                            readonly property bool odd: pin % 2 === 1
                            readonly property var assignment: root.highlights[pin] || null
                            readonly property string pinName: root.pinNames[index]
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
                                    text: pinButton.assignment ? pinButton.assignment.signal + " · " + pinButton.assignment.label : pinButton.pinName
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
        visible: root.inspectedPin > 0
        text: root.inspectedPin ? qsTr("Pin %1 · %2").arg(root.inspectedPin).arg(root.pinNames[root.inspectedPin - 1]) +
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
