import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Templates 2.12 as T
import ".."
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
    property real viewportHeight: 750
    property int inspectedPin: 0
    property int inspectedAuxPin: 0
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
            list.push({label: role.label, port: port,
                       rx: pins && !role.txOnly && isHeaderPin(pins.rx) ? pins.rx : 0,
                       tx: pins && isHeaderPin(pins.tx) ? pins.tx : 0})
            return list
        }, [])
    }
    readonly property var highlights: {
        var result = {}
        if (!connected || !settingsModel || !hasPinout) return result
        settingsModel.update_count

        function add(pin, label, signal, color) {
            if (!isHeaderPin(pin)) return
            var existing = result[pin]
            if (existing) {
                existing.label += " / " + label
                return
            }
            result[pin] = {label: label, signal: signal, color: color}
        }
        for (var i = 0; i < assignments.length; ++i) {
            var role = assignments[i]
            add(role.rx, role.label, "RX", "#36dafa")
            add(role.tx, role.label, "TX", "#7aefa7")
        }
        if (profile.raspberryGpio) {
            var gpios = [{id: "GPIO_2", pin: 3}, {id: "GPIO_26", pin: 37}]
            for (var j = 0; j < gpios.length; ++j) {
                var gpio = gpios[j]
                if (!settingsModel.param_int_exists(gpio.id)) continue
                var value = settingsModel.get_cached_int(gpio.id)
                if (value === 1 || value === 2)
                    add(gpio.pin, pinNames[gpio.pin - 1], value === 1 ? qsTr("High") : qsTr("Low"),
                        value === 1 ? "#ffc064" : "#d8a7ff")
            }
        }
        return result
    }
    readonly property bool compactView: contentWidth < 665 || viewportHeight < 540 || (hasPinout && fittedRowPitch < 14)
    readonly property bool compactBesideArt: hasPinout && compactView && contentWidth >= 400
    readonly property int chartHeaderHeight: 42
    readonly property int artSlotWidth: Math.max(0, contentWidth - 20 - Math.max(300, Math.ceil(contentWidth * 0.43)))
    readonly property int fittedRowPitch: boardArt.geometry.header
        ? Math.min(19,
                   Math.floor((artSlotWidth - 8) * boardArt.geometry.header.pitch / boardArt.geometry.w),
                   Math.floor((viewportHeight - 95) * boardArt.geometry.header.pitch / boardArt.geometry.h))
        : 0
    readonly property bool sideBySide: hasPinout && !compactView && fittedRowPitch >= 14
    readonly property int rowPitch: sideBySide ? fittedRowPitch : 26
    readonly property real artScale: sideBySide ? rowPitch / boardArt.geometry.header.pitch : 0
    readonly property real compactHeight: Math.max(134, Math.min(245, Math.floor(viewportHeight - 94)))
    readonly property real previewHeight: compactBesideArt ? compactHeight
        : compactView ? Math.max(105, Math.min(170, Math.floor(viewportHeight * 0.42))) : 190
    readonly property int compactArtWidth: Math.round(Math.min(250, contentWidth * 0.34))
    readonly property var focusedAssignment: highlights[inspectedPin] || null
    readonly property int firstAssignedPin: {
        var pins = Object.keys(highlights)
        return pins.length ? Math.min.apply(null, pins.map(Number)) : 0
    }
    readonly property real firstRowY: sideBySide
        ? boardArt.topForScale(artScale) + boardArt.geometry.header.y * artScale : chartHeaderHeight + rowPitch / 2

    function isHeaderPin(pin) {
        return typeof pin === "number" && pin % 1 === 0 && pin >= 1 && pin <= pinNames.length
    }

    function functionForPin(pin) {
        return Boards.pinFunction(profile.art, pin)
    }

    function pinAtSlot(index) {
        var header = boardArt.geometry.header
        return header ? boardArt.pinForSlot(Math.floor(index / header.columns), index % header.columns, header)
                      : index + 1
    }

    function selectPin(pin, auxiliary) {
        var toggle = auxiliary ? inspectedAuxPin === pin : inspectedPin === pin
        inspectedPin = !auxiliary && !toggle ? pin : 0
        inspectedAuxPin = auxiliary && !toggle ? pin : 0
        if (!auxiliary && inspectedPin) revealPin(inspectedPin)
    }

    function revealPin(pin, center) {
        if (!compactView || !isHeaderPin(pin) || !boardArt.geometry.header) return
        pinList.revealRow(boardArt.slotForPin(pin, boardArt.geometry.header).row, center)
    }

    function clearSelection() {
        inspectedPin = 0
        inspectedAuxPin = 0
        pinList.contentY = 0
    }

    onProfileChanged: {
        clearSelection()
        Qt.callLater(revealPin, firstAssignedPin, true)
    }
    onAirChanged: clearSelection()
    onFirstAssignedPinChanged: if (!inspectedPin) Qt.callLater(revealPin, firstAssignedPin, true)
    onCompactViewChanged: if (compactView) Qt.callLater(revealPin, inspectedPin || firstAssignedPin, true)
    title: hasPinout ? qsTr("%1 · Pinout").arg(profile.name) : profile.name
    icon: "\uf2db"
    compact: true

    GridLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 0
        columns: root.sideBySide || root.compactBesideArt ? 2 : 1
        columnSpacing: root.compactBesideArt ? 10 : 20
        rowSpacing: 10

        PortsBoardArt {
            id: boardArt
            objectName: "portsBoardArt"
            Layout.fillWidth: true
            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: root.sideBySide ? root.artSlotWidth
                                 : root.compactBesideArt ? root.compactArtWidth : root.contentWidth
            Layout.minimumWidth: 0
            Layout.preferredHeight: root.sideBySide ? alignedHeight : root.previewHeight
            Layout.alignment: Qt.AlignTop
            alignedScale: root.artScale
            alignedFirstRow: root.chartHeaderHeight + root.rowPitch / 2
            artwork: root.profile.art
            highlights: root.highlights
            inspectedPin: root.inspectedPin
            inspectedAuxPin: root.inspectedAuxPin
            onPinPicked: function(pin, auxiliary) { root.selectPin(pin, auxiliary) }
        }

        Rectangle {
            id: pinChart
            objectName: "portsPinChart"
            visible: root.hasPinout
            Layout.fillWidth: true
            Layout.row: root.sideBySide || root.compactBesideArt ? 0 : 1
            Layout.column: root.sideBySide || root.compactBesideArt ? 1 : 0
            Layout.preferredWidth: root.sideBySide ? root.contentWidth - root.artSlotWidth - 20
                                 : root.compactBesideArt ? root.contentWidth - root.compactArtWidth - 10 : root.contentWidth
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignTop
            implicitHeight: pinList.y + pinList.height + 8
            color: settings_form.pageBackground
            border.color: settings_form.lineColor
            radius: 10

            Text {
                anchors.top: parent.top
                anchors.topMargin: 11
                anchors.left: parent.left
                anchors.right: parent.right
                text: boardArt.geometry.header && boardArt.geometry.header.columnGap > boardArt.geometry.header.pitch * 3
                      ? qsTr("Edge pins · 2 × %1").arg(root.pinNames.length / 2)
                      : qsTr("GPIO header · 2 × %1").arg(root.pinNames.length / 2)
                color: settings_form.primaryText
                font.family: Typography.family
                font.pixelSize: Typography.sectionTitle
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Flickable {
                id: pinList
                objectName: "portsPinList"
                x: 8
                y: Math.round(root.firstRowY - root.rowPitch / 2)
                width: Math.max(0, parent.width - (root.compactView ? 20 : 16))
                height: root.compactView
                        ? Math.min(contentHeight, Math.max(2, Math.floor((root.compactHeight - y - 8) / root.rowPitch)) * root.rowPitch)
                        : contentHeight
                contentWidth: width
                contentHeight: Math.ceil(root.pinNames.length / 2) * root.rowPitch
                clip: root.compactView
                interactive: root.compactView && contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                onMovementEnded: {
                    var row = Math.round(contentY / root.rowPitch)
                    contentY = Math.max(0, Math.min(contentHeight - height, row * root.rowPitch))
                }

                ScrollBar.vertical: ScrollBar {
                    parent: pinChart
                    x: pinChart.width - width - 2
                    y: pinList.y
                    width: 10
                    height: pinList.height
                    policy: pinList.interactive ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                function revealRow(row, center) {
                    if (!interactive) return
                    var top = row * root.rowPitch
                    if (center) {
                        var first = Math.max(0, row - Math.floor(height / root.rowPitch / 2))
                        contentY = Math.min(contentHeight - height, first * root.rowPitch)
                    } else if (top < contentY)
                        contentY = top
                    else if (top + root.rowPitch > contentY + height)
                        contentY = top + root.rowPitch - height
                }

                Repeater {
                    model: root.pinNames.length
                    delegate: T.Button {
                        id: pinButton
                        readonly property int pin: root.pinAtSlot(index)
                        readonly property bool odd: index % 2 === 0
                        readonly property int row: Math.floor(index / 2)
                        readonly property var assignment: root.highlights[pin] || null
                        readonly property string pinName: root.pinNames[pin - 1]
                        readonly property string alternate: root.functionForPin(pin)
                        readonly property bool inspected: root.inspectedPin === pin
                        readonly property int padSize: Math.min(16, root.rowPitch - 4)
                        readonly property color pinColor: assignment ? assignment.color :
                            pinName === "GND" ? settings_form.secondaryText :
                            pinName.indexOf(" V") >= 0 ? "#d89c52" : settings_form.lineColor

                        objectName: "portsHeaderPin" + pin
                        width: Math.max(0, (pinList.width - 8) / 2)
                        height: root.rowPitch - 2
                        x: odd ? 0 : width + 8
                        y: row * root.rowPitch + 1
                        padding: 0
                        leftPadding: 5
                        rightPadding: 5
                        hoverEnabled: true
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Pin %1, %2").arg(pin).arg(pinName) +
                            (alternate ? ", " + qsTr("Alternate function: %1").arg(alternate) : "") +
                            (assignment ? ", " + assignment.label + " " + assignment.signal : "")
                        onClicked: root.selectPin(pin, false)
                        onActiveFocusChanged: if (activeFocus) {
                            pinList.revealRow(row)
                            root.pinFocused(pinButton)
                        }
                        ToolTip.visible: hovered
                        ToolTip.delay: 350
                        ToolTip.text: Accessible.name
                        Keys.onEscapePressed: root.backRequested()
                        background: Rectangle {
                            radius: 4
                            color: pinButton.assignment
                                   ? Qt.tint(settings_form.pageBackground, Qt.rgba(pinButton.pinColor.r, pinButton.pinColor.g,
                                                                                  pinButton.pinColor.b, 0.16))
                                   : pinButton.hovered || pinButton.inspected ? settings_form.panelBackgroundRaised : "transparent"
                            border.width: pinButton.visualFocus || pinButton.inspected ? 1 : 0
                            border.color: settings_form.accentColor

                            Rectangle {
                                visible: !!pinButton.assignment
                                width: 2
                                height: Math.max(5, parent.height - 6)
                                x: pinButton.odd ? 1 : parent.width - width - 1
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 1
                                color: pinButton.pinColor
                            }
                        }
                        contentItem: RowLayout {
                            layoutDirection: pinButton.odd ? Qt.RightToLeft : Qt.LeftToRight
                            spacing: 4
                            Rectangle {
                                objectName: "pinPad"
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: pinButton.padSize
                                Layout.preferredHeight: pinButton.padSize
                                radius: pinButton.pin === 1 ? 3 : width / 2
                                color: pinButton.assignment ? pinButton.pinColor : settings_form.panelBackground
                                border.width: pinButton.assignment ? 2 : 1
                                border.color: pinButton.pinColor
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.max(3, parent.width * 0.35)
                                    height: width
                                    radius: width / 2
                                    color: pinButton.assignment ? "#102633" : pinButton.pinColor
                                }
                            }
                            Text {
                                objectName: "pinNumber"
                                Layout.preferredWidth: 19
                                Layout.fillHeight: true
                                text: pinButton.pin
                                color: settings_form.primaryText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: Typography.family
                                font.pixelSize: Typography.helper
                                font.bold: true
                            }
                            Text {
                                objectName: "pinDescription"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                text: pinButton.assignment ? pinButton.assignment.signal + " · " + pinButton.assignment.label
                                                           : pinButton.pinName + (pinButton.alternate ? " · " + pinButton.alternate : "")
                                horizontalAlignment: pinButton.odd ? Text.AlignRight : Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                color: pinButton.assignment ? settings_form.primaryText : settings_form.secondaryText
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

    Text {
        Layout.fillWidth: true
        visible: root.schematic || !boardArt.geometry.pcb
        text: root.profile.art === "pc" ? qsTr("GPIO connectors depend on the host")
            : !boardArt.geometry.pcb ? qsTr("Exact board or carrier model unavailable")
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
                AdvancedActionButton {
                    id: auxPinButton
                    objectName: "portsAuxPin" + (index + 1)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 53
                    text: (index + 1) + " · " + modelData
                    primary: root.inspectedAuxPin === index + 1
                    onClicked: root.selectPin(index + 1, true)
                    onActiveFocusChanged: if (activeFocus) root.pinFocused(auxPinButton)
                    Keys.onEscapePressed: root.backRequested()
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.inspectedPin > 0 || root.inspectedAuxPin > 0
        text: root.inspectedAuxPin > 0 ? qsTr("Auxiliary pin %1 · %2").arg(root.inspectedAuxPin)
                                           .arg(root.auxPins[root.inspectedAuxPin - 1])
            : root.inspectedPin ? qsTr("Pin %1 · %2").arg(root.inspectedPin).arg(root.pinNames[root.inspectedPin - 1]) +
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
