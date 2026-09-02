import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import OpenHD 1.0

Rectangle {
    id: root
    color: "transparent"
    focus: false

    property bool connected: _ohdSystemAir.is_alive || _ohdSystemGround.is_alive
    property bool isScanning: false
    property bool showConnectionModeInfo: false
    property int scanProgress: 0
    property int scanIndex: 1
    property int scanMax: 254
    property int keyboardIndex: 0
    property string scanPrefix: "192.168.0"

    ListModel { id: scanResultsModel }

    Timer {
        id: scanTimer
        interval: 120
        repeat: true
        onTriggered: {
            if (root.scanIndex > root.scanMax) {
                root.isScanning = false
                root.scanProgress = 100
                stop()
                return
            }
            var candidateIp = root.scanPrefix + "." + root.scanIndex
            if (_qopenhd.ping_ip(candidateIp))
                scanResultsModel.append({ ip: candidateIp })
            root.scanProgress = Math.min(100, Math.round((root.scanIndex / root.scanMax) * 100))
            root.scanIndex++
        }
    }

    function derivePrefix() {
        var parts = settings.qopenhd_mavlink_connection_manual_tcp_ip.split(".")
        return parts.length === 4 ? parts[0] + "." + parts[1] + "." + parts[2] : "192.168.0"
    }
    function startScan() {
        if (isScanning)
            return
        scanPrefix = derivePrefix()
        scanResultsModel.clear()
        scanIndex = 1
        scanProgress = 0
        isScanning = true
        scanTimer.start()
    }
    function setMode(mode) {
        if (settings.qopenhd_mavlink_connection_mode !== mode) {
            _mavlinkTelemetry.change_telemetry_connection_mode(mode)
            settings.qopenhd_mavlink_connection_mode = mode
        }
        if (mode !== 2 && isScanning) {
            scanTimer.stop()
            isScanning = false
            scanProgress = 0
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
        var all = [autoMode, udpMode, tcpMode, infoButton]
        if (settings.qopenhd_mavlink_connection_mode === 0 && showConnectionModeInfo)
            all = all.concat([androidButton, ethernetForwardButton, ethernetHotspotButton])
        if (settings.qopenhd_mavlink_connection_mode === 2)
            all = all.concat([ipField, saveButton, scanButton])
        for (var i = 0; i < resultsRepeater.count; ++i)
            all.push(resultsRepeater.itemAt(i))
        var available = []
        for (var j = 0; j < all.length; ++j) {
            if (all[j] && all[j].visible && all[j].enabled)
                available.push(all[j])
        }
        return available
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
                        Text { anchors.centerIn: parent; text: "\uf1eb"; color: root.connected ? settings_form.goodColor : "#d97706"; font.family: "Font Awesome 5 Free"; font.pixelSize: 16 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: root.connected ? qsTr("OpenHD connected") : qsTr("Waiting for OpenHD"); color: settings_form.primaryText; font.pixelSize: 14; font.bold: true }
                        Text { text: _mavlinkTelemetry.telemetry_connection_status; color: settings_form.secondaryText; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
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
                        Text { text: qsTr("CONNECTION MODE"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                        Button {
                            id: infoButton
                            width: 34; height: 30
                            text: "\uf05a"
                            font.family: "Font Awesome 5 Free"; font.pixelSize: 13
                            onClicked: root.showConnectionModeInfo = !root.showConnectionModeInfo
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(infoButton)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 8; color: infoButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; border.color: infoButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: infoButton.activeFocus ? 2 : 1 }
                            contentItem: Text { text: infoButton.text; font: infoButton.font; color: settings_form.secondaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            id: autoMode
                            Layout.fillWidth: true; height: 40
                            text: qsTr("AUTO")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 0
                            onClicked: root.setMode(0)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(autoMode)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: autoMode.highlighted ? settings_form.accentColor : settings_form.panelBackgroundRaised; border.color: autoMode.activeFocus ? (autoMode.highlighted ? "white" : settings_form.accentColor) : settings_form.lineColor; border.width: autoMode.activeFocus ? 2 : 1 }
                            contentItem: Text { text: autoMode.text; color: autoMode.highlighted ? "white" : settings_form.primaryText; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        Button {
                            id: udpMode
                            Layout.fillWidth: true; height: 40
                            text: qsTr("MANUAL UDP")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 1
                            onClicked: root.setMode(1)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(udpMode)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: udpMode.highlighted ? settings_form.accentColor : settings_form.panelBackgroundRaised; border.color: udpMode.activeFocus ? (udpMode.highlighted ? "white" : settings_form.accentColor) : settings_form.lineColor; border.width: udpMode.activeFocus ? 2 : 1 }
                            contentItem: Text { text: udpMode.text; color: udpMode.highlighted ? "white" : settings_form.primaryText; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        Button {
                            id: tcpMode
                            Layout.fillWidth: true; height: 40
                            text: qsTr("MANUAL TCP")
                            highlighted: settings.qopenhd_mavlink_connection_mode === 2
                            onClicked: root.setMode(2)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(tcpMode)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: tcpMode.highlighted ? settings_form.accentColor : settings_form.panelBackgroundRaised; border.color: tcpMode.activeFocus ? (tcpMode.highlighted ? "white" : settings_form.accentColor) : settings_form.lineColor; border.width: tcpMode.activeFocus ? 2 : 1 }
                            contentItem: Text { text: tcpMode.text; color: tcpMode.highlighted ? "white" : settings_form.primaryText; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: settings.qopenhd_mavlink_connection_mode === 0
                              ? qsTr("Automatically detects USB tethering, Ethernet and hotspot connections.")
                              : (settings.qopenhd_mavlink_connection_mode === 1
                                 ? qsTr("Receives forwarded MAVLink telemetry on UDP port 5600.")
                                 : qsTr("Connects directly to a selected OpenHD TCP address on port 5760."))
                        color: settings_form.secondaryText; font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: autoColumn.implicitHeight + 26
                visible: settings.qopenhd_mavlink_connection_mode === 0 && root.showConnectionModeInfo
                radius: 12; color: settings_form.panelBackground; border.color: settings_form.lineColor
                ColumnLayout {
                    id: autoColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 13
                    spacing: 8
                    Text { text: qsTr("AUTOMATIC CONNECTION OPTIONS"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                    Button {
                        id: androidButton
                        Layout.fillWidth: true; height: 40
                        text: qsTr("Open Android tethering settings")
                        onClicked: _qopenhd.is_android() ? _qopenhd.android_open_tethering_settings() : _messageBoxInstance.set_text_and_show(qsTr("This feature is only available on Android"))
                        onActiveFocusChanged: if (activeFocus) root.syncFocus(androidButton)
                        Keys.onPressed: root.handleButtonKey(event)
                        background: Rectangle { radius: 9; color: androidButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; border.color: androidButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: androidButton.activeFocus ? 2 : 1 }
                        contentItem: Text { text: androidButton.text; color: settings_form.primaryText; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                    Button {
                        id: ethernetForwardButton
                        Layout.fillWidth: true; height: 40
                        text: qsTr("Ethernet forward + internet instructions")
                        onClicked: _messageBoxInstance.set_text_and_show(qsTr("Set Ethernet to FORWARD+INTERNET, reboot the ground unit, then connect this device by Ethernet. Video and telemetry forwarding start automatically."))
                        onActiveFocusChanged: if (activeFocus) root.syncFocus(ethernetForwardButton)
                        Keys.onPressed: root.handleButtonKey(event)
                        background: Rectangle { radius: 9; color: ethernetForwardButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; border.color: ethernetForwardButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: ethernetForwardButton.activeFocus ? 2 : 1 }
                        contentItem: Text { text: ethernetForwardButton.text; color: settings_form.primaryText; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                    Button {
                        id: ethernetHotspotButton
                        Layout.fillWidth: true; height: 40
                        text: qsTr("Ethernet hotspot instructions")
                        onClicked: _messageBoxInstance.set_text_and_show(qsTr("Set Ethernet to HOTSPOT, reboot the ground unit, then connect this device by Ethernet. You may need to disable Wi-Fi and cellular data."))
                        onActiveFocusChanged: if (activeFocus) root.syncFocus(ethernetHotspotButton)
                        Keys.onPressed: root.handleButtonKey(event)
                        background: Rectangle { radius: 9; color: ethernetHotspotButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; border.color: ethernetHotspotButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: ethernetHotspotButton.activeFocus ? 2 : 1 }
                        contentItem: Text { text: ethernetHotspotButton.text; color: settings_form.primaryText; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
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
                    Text { text: qsTr("TCP TARGET"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        TextField {
                            id: ipField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.minimumHeight: 40
                            Layout.maximumHeight: 40
                            text: settings.qopenhd_mavlink_connection_manual_tcp_ip
                            placeholderText: qsTr("192.168.x.x")
                            color: settings_form.primaryText
                            font.pixelSize: 12
                            leftPadding: 12
                            rightPadding: 12
                            topPadding: 0
                            bottomPadding: 0
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            validator: RegExpValidator { regExp: /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/ }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onAccepted: root.applyTcpTarget(text)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(ipField)
                            Keys.onUpPressed: root.moveFocus(-1)
                            Keys.onDownPressed: root.moveFocus(1)
                            Keys.onEscapePressed: settings_form.side_bar_regain_focus()
                            background: Rectangle { radius: 9; color: settings_form.panelBackgroundRaised; border.color: ipField.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: ipField.activeFocus ? 2 : 1 }
                        }
                        Button {
                            id: saveButton
                            Layout.preferredWidth: 90
                            Layout.minimumWidth: 90
                            Layout.maximumWidth: 90
                            Layout.preferredHeight: 40
                            Layout.minimumHeight: 40
                            Layout.maximumHeight: 40
                            text: qsTr("SAVE")
                            onClicked: root.applyTcpTarget(ipField.text)
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(saveButton)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: saveButton.hovered ? "#176fc7" : settings_form.accentColor; border.color: saveButton.activeFocus ? "white" : "transparent"; border.width: 2 }
                            contentItem: Text { text: saveButton.text; color: "white"; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            id: scanButton
                            Layout.fillWidth: true; height: 40
                            text: root.isScanning ? qsTr("SCANNING %1%").arg(root.scanProgress) : qsTr("SCAN ETHERNET FOR OPENHD")
                            enabled: !root.isScanning
                            onClicked: root.startScan()
                            onActiveFocusChanged: if (activeFocus) root.syncFocus(scanButton)
                            Keys.onPressed: root.handleButtonKey(event)
                            background: Rectangle { radius: 9; color: scanButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; opacity: scanButton.enabled ? 1 : 0.5; border.color: scanButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: scanButton.activeFocus ? 2 : 1 }
                            contentItem: Text { text: scanButton.text; color: settings_form.primaryText; opacity: scanButton.enabled ? 1 : 0.5; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                        }
                        Text { text: root.scanPrefix + ".x"; color: settings_form.secondaryText; font.pixelSize: 11 }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 5; radius: 3
                        visible: root.isScanning || root.scanProgress > 0
                        color: settings_form.lineColor
                        Rectangle { width: parent.width * root.scanProgress / 100; height: parent.height; radius: parent.radius; color: settings_form.accentColor }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: scanResultsModel.count === 0
                              ? (root.isScanning ? qsTr("Searching for responsive hosts…") : qsTr("No devices discovered yet."))
                              : qsTr("Discovered devices")
                        color: settings_form.secondaryText; font.pixelSize: 11
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            id: resultsRepeater
                            model: scanResultsModel
                            delegate: Button {
                                id: resultButton
                                Layout.fillWidth: true; height: 40
                                text: ip + "    " + qsTr("CONNECT")
                                onClicked: root.applyTcpTarget(ip)
                                onActiveFocusChanged: if (activeFocus) root.syncFocus(resultButton)
                                Keys.onPressed: root.handleButtonKey(event)
                                background: Rectangle { radius: 9; color: resultButton.hovered ? settings_form.panelBackgroundRaised : "transparent"; border.color: resultButton.activeFocus ? settings_form.accentColor : settings_form.lineColor; border.width: resultButton.activeFocus ? 2 : 1 }
                                contentItem: Text { text: resultButton.text; color: settings_form.primaryText; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; Layout.preferredHeight: 8 }
        }
    }
}
