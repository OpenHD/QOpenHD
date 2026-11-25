import ".."
import "../MenuTypography.js" as MenuTypography
import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

Rectangle {
    id: root
    color: "transparent"
    focus: false

    property bool connected: _ohdSystemAir.is_alive || _ohdSystemGround.is_alive
    property int keyboardIndex: 0

    property bool ethernetTargetAir: false
    readonly property var ethernetUnit: ethernetTargetAir ? _ohdSystemAir : _ohdSystemGround
    readonly property var ethernetSettings: ethernetTargetAir ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings
    readonly property int ethernetMode: {
        ethernetSettings.update_count
        if (!ethernetUnit.is_alive || !ethernetSettings.has_params_fetched ||
                !ethernetSettings.param_int_exists("ETHERNET"))
            return -1
        return ethernetSettings.get_cached_int("ETHERNET")
    }

    component ModeButton: AdvancedActionButton {
        id: button
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        background: Rectangle {
            radius: 9
            color: button.highlighted ? settings_form.accentColor : settings_form.panelBackgroundRaised
            border.color: button.activeFocus ? (button.highlighted ? "white" : settings_form.accentColor) : settings_form.lineColor
            border.width: button.activeFocus ? 2 : 1
        }
        contentItem: Text {
            text: button.text
            color: button.highlighted ? "white" : (button.enabled ? settings_form.primaryText : settings_form.secondaryText)
            font.family: button.font.family
            font.pixelSize: button.font.pixelSize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        onActiveFocusChanged: if (activeFocus) root.syncFocus(button)
        Keys.onPressed: root.handleButtonKey(event)
    }

    function setMode(mode) {
        if (settings.qopenhd_mavlink_connection_mode !== mode) {
            _mavlinkTelemetry.change_telemetry_connection_mode(mode)
            settings.qopenhd_mavlink_connection_mode = mode
        }
    }
    function applyTcpTarget(ip) {
        if (!_qopenhd.is_valid_ip(ip)) {
            _qopenhd.show_toast(qsTr("Please enter a valid IP address"))
            return
        }
        ipField.text = ip
        settings.qopenhd_mavlink_connection_manual_tcp_ip = ip
        _mavlinkTelemetry.change_manual_tcp_ip(ip)
        setMode(2)
    }
    function controls() {
        var all = [autoMode, udpMode, tcpMode, tetheringButton, ethernetAir, ethernetGround]
        for (var i = 0; i < ethernetModes.count; ++i)
            all.push(ethernetModes.itemAt(i))
        for (var j = 0; j < lanRepeater.count; ++j) {
            var row = lanRepeater.itemAt(j)
            if (row) all.push(row.connectButton)
        }
        if (settings.qopenhd_mavlink_connection_mode === 2)
            all = all.concat([ipField, saveButton])
        return all.filter(function (control) { return control && control.visible && control.enabled })
    }
    function syncFocus(control) {
        var list = controls()
        for (var i = 0; i < list.length; ++i) {
            if (list[i] === control) {
                keyboardIndex = i
                return
            }
        }
    }
    function gainFocus() {
        var list = controls()
        if (list.length === 0)
            return
        keyboardIndex = Math.max(0, Math.min(keyboardIndex, list.length - 1))
        list[keyboardIndex].forceActiveFocus()
        scroller.ensureVisible(list[keyboardIndex])
    }
    function moveFocus(step) {
        var list = controls()
        if (list.length === 0)
            return
        keyboardIndex = (keyboardIndex + step + list.length) % list.length
        list[keyboardIndex].forceActiveFocus()
        scroller.ensureVisible(list[keyboardIndex])
    }
    function handleButtonKey(event) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
            moveFocus(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            moveFocus(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
            settings_form.side_bar_regain_focus()
            event.accepted = true
        }
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 20
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        function ensureVisible(item) {
            var point = item.mapToItem(scroller.contentItem, 0, 0)
            if (point.y < contentY + 6)
                contentY = Math.max(0, point.y - 6)
            else if (point.y + item.height > contentY + height - 6)
                contentY = Math.max(0, Math.min(contentHeight - height, point.y + item.height - height + 6))
        }

        ColumnLayout {
            id: contentColumn
            width: scroller.width
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 12
                color: settings_form.panelBackground
                border.color: settings_form.lineColor
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 16
                    spacing: 11
                    Rectangle {
                        width: 34; height: 34; radius: 9
                        color: root.connected ? Qt.rgba(0.03, 0.5, 0.25, 0.12) : Qt.rgba(0.75, 0.35, 0.05, 0.12)
                        Text { anchors.centerIn: parent; text: "\uf1eb"; color: root.connected ? settings_form.goodColor : "#d97706"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.rowIcon }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: root.connected ? qsTr("OpenHD connected") : qsTr("Waiting for OpenHD"); color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                        Text { text: _mavlinkTelemetry.telemetry_connection_status; color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    Rectangle { width: 9; height: 9; radius: 5; color: root.connected ? settings_form.goodColor : "#d97706" }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: modeColumn.implicitHeight + 26
                radius: 12
                color: settings_form.panelBackground
                border.color: settings_form.lineColor
                ColumnLayout {
                    id: modeColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 13
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("CONNECTION MODE"); color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true; Layout.fillWidth: true }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        ModeButton {
                            id: autoMode
                            text: qsTr("AUTO")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 0
                            onClicked: root.setMode(0)
                        }
                        ModeButton {
                            id: udpMode
                            text: qsTr("MANUAL UDP")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 1
                            onClicked: root.setMode(1)
                        }
                        ModeButton {
                            id: tcpMode
                            text: qsTr("MANUAL TCP")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 2
                            onClicked: root.setMode(2)
                        }
                    }

                    AdvancedActionButton {
                        id: tetheringButton
                        Layout.alignment: Qt.AlignLeft
                        visible: _qopenhd.is_android() && settings.qopenhd_mavlink_connection_mode === 0
                        text: qsTr("Tethering settings")
                        onClicked: _qopenhd.android_open_tethering_settings()
                        onActiveFocusChanged: if (activeFocus) root.syncFocus(tetheringButton)
                        Keys.onPressed: root.handleButtonKey(event)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ethernetColumn.implicitHeight + 26
                radius: 12
                color: settings_form.panelBackground
                border.color: settings_form.lineColor

                Column {
                    id: ethernetColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 13
                    spacing: 10

                    RowLayout {
                        width: parent.width
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("ETHERNET MODE")
                            color: settings_form.primaryText
                            font.family: MenuTypography.family
                            font.pixelSize: MenuTypography.body
                            font.bold: true
                        }

                        ModeButton {
                            id: ethernetAir
                            Layout.fillWidth: false
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 26
                            leftPadding: 4
                            rightPadding: 4
                            text: qsTr("Air")
                            highlighted: root.ethernetTargetAir
                            onClicked: root.ethernetTargetAir = true
                        }

                        ModeButton {
                            id: ethernetGround
                            Layout.fillWidth: false
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 26
                            leftPadding: 4
                            rightPadding: 4
                            text: qsTr("Ground")
                            highlighted: !root.ethernetTargetAir
                            onClicked: root.ethernetTargetAir = false
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            id: ethernetModes
                            model: [
                                { label: qsTr("UNMANAGED"), value: 0 },
                                { label: qsTr("HOTSPOT"), value: 1 },
                                { label: qsTr("FORWARD + INTERNET"), value: 2 }
                            ]
                            delegate: ModeButton {
                                leftPadding: 4
                                rightPadding: 4
                                text: modelData.label
                                enabled: root.ethernetMode >= 0
                                highlighted: root.ethernetMode === modelData.value
                                onClicked: {
                                    if (!root.ethernetSettings.ui_is_busy && !highlighted)
                                        root.ethernetSettings.try_set_param_int_async("ETHERNET", modelData.value, true)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: lanColumn.implicitHeight + 26
                radius: 12
                color: settings_form.panelBackground
                border.color: settings_form.lineColor

                ColumnLayout {
                    id: lanColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 13
                    spacing: 8

                    Text {
                        text: qsTr("LOCAL ETHERNET")
                        color: settings_form.primaryText
                        font.family: MenuTypography.family
                        font.pixelSize: MenuTypography.body
                        font.bold: true
                    }

                    Text {
                        visible: lanRepeater.count === 0
                        text: qsTr("Listening for OpenHD units…")
                        color: settings_form.secondaryText
                        font.family: MenuTypography.family
                        font.pixelSize: MenuTypography.body
                    }

                    Repeater {
                        id: lanRepeater
                        model: _mavlinkTelemetry.lan_platforms
                        delegate: RowLayout {
                            property alias connectButton: lanConnectButton
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: modelData.role === "AIR"
                                      ? qsTr("Air · %1").arg(modelData.ip)
                                      : qsTr("Ground · %1").arg(modelData.ip)
                                color: settings_form.primaryText
                                font.family: MenuTypography.family
                                font.pixelSize: MenuTypography.body
                            }

                            AdvancedActionButton {
                                id: lanConnectButton
                                text: qsTr("CONNECT")
                                font.family: MenuTypography.family
                                font.pixelSize: MenuTypography.body
                                onClicked: root.applyTcpTarget(modelData.ip)
                                onActiveFocusChanged: if (activeFocus) root.syncFocus(lanConnectButton)
                                Keys.onPressed: root.handleButtonKey(event)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: tcpColumn.implicitHeight + 26
                visible: settings.qopenhd_mavlink_connection_mode === 2
                radius: 12; color: settings_form.panelBackground; border.color: settings_form.lineColor
                ColumnLayout {
                    id: tcpColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 13
                    spacing: 10
                    Text { text: qsTr("TCP TARGET"); color: settings_form.primaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        TextField {
                            id: ipField
                            Layout.fillWidth: true
                            Layout.preferredHeight: MenuTypography.controlHeight
                            Layout.minimumHeight: 40
                            Layout.maximumHeight: 40
                            text: settings.qopenhd_mavlink_connection_manual_tcp_ip
                            placeholderText: qsTr("192.168.x.x")
                            color: settings_form.primaryText
                            font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                            leftPadding: 12
                            rightPadding: 12
                            topPadding: 0
                            bottomPadding: 0
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            validator: RegularExpressionValidator { regularExpression: /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/ }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onAccepted: root.applyTcpTarget(text)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(ipField)
                            Keys.onUpPressed: root.moveFocus(-1)
                            Keys.onDownPressed: root.moveFocus(1)
                            Keys.onEscapePressed: settings_form.side_bar_regain_focus()
                            background: Rectangle { radius: 9; color: settings_form.panelBackgroundRaised; border.color: ipField.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: ipField.activeFocus ? 2 : 1 }
                        }
                        AdvancedActionButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
                            id: saveButton
                            Layout.preferredWidth: 90
                            Layout.minimumWidth: 90
                            Layout.maximumWidth: 90
                            Layout.preferredHeight: MenuTypography.controlHeight
                            Layout.minimumHeight: 40
                            Layout.maximumHeight: 40
                            text: qsTr("SAVE")
                            onClicked: root.applyTcpTarget(ipField.text)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(saveButton)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: saveButton.hovered ? "#176fc7" : settings_form.accentColor; border.color: saveButton.activeFocus ? "white" : "transparent"; border.width: 2 }
                            contentItem: Text { text: saveButton.text; color: "white"; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; Layout.preferredHeight: 8 }
        }
    }
}
