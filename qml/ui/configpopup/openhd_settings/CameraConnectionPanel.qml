import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import ".."

FocusScope {
    id: root

    signal categoryRequested()
    signal backRequested()

    property var settingsModel
    property bool busy: false
    property int paramRevision: settingsModel ? settingsModel.update_count : 0
    property int airParamRevision: _ohdSystemAirSettingsModel.update_count

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    function pipelinePort(pipeline) {
        var match = String(pipeline).match(/rtsp:\/\/\{IP\}:(\d+)/)
        return match ? match[1] : "554"
    }

    function pipelinePath(pipeline) {
        var match = String(pipeline).match(/rtsp:\/\/\{IP\}:\d+([^\s]+)/)
        return match ? match[1] : "/stream=0"
    }

    function normalizedPath() {
        var path = pathField.text.trim()
        if (path.length === 0) return "/"
        return path.charAt(0) === "/" ? path : "/" + path
    }

    function generatedPipeline() {
        return "rtspsrc location=rtsp://{IP}:" + portField.text.trim() + normalizedPath() +
               " protocols=tcp latency=0 ! rtp{CODEC}depay"
    }

    function validIpv4(address) {
        var parts = String(address).trim().split(".")
        if (parts.length !== 4) return false
        for (var i = 0; i < parts.length; ++i) {
            if (!/^\d{1,3}$/.test(parts[i])) return false
            var value = Number(parts[i])
            if (value < 0 || value > 255) return false
        }
        return true
    }

    function loadValues() {
        if (!settingsModel || !settingsModel.has_params_fetched) return
        var pipeline = settingsModel.get_cached_string("IP_CAM_PIPELINE")
        addressField.text = settingsModel.get_cached_string("IP_CAM_ADDRESS")
        portField.text = pipelinePort(pipeline)
        pathField.text = pipelinePath(pipeline)
        pipelineField.text = pipeline

        if (portField.text === "8554" && pathField.text === "/main.264")
            profileBox.currentIndex = 0
        else if (portField.text === "554" && pathField.text === "/stream=0")
            profileBox.currentIndex = 1
        else
            profileBox.currentIndex = 2

        // Never hide a stored custom pipeline behind the generated editor. If it
        // differs from the standard RTSP source, keep it visible and untouched.
        expertPipeline.checked = pipeline.length > 0 && pipeline !== generatedPipeline()

        if (_ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS"))
            reservationBox.value = _ohdSystemAirSettingsModel.get_cached_int("V_IP_CAM_MBITS")
    }

    function applyConnection() {
        var address = addressField.text.trim()
        var port = Number(portField.text)
        if (!validIpv4(address)) {
            _qopenhd.show_toast(qsTr("Enter a valid IPv4 address"))
            addressField.forceActiveFocus()
            return
        }
        if (!/^\d+$/.test(portField.text.trim()) || port < 1 || port > 65535) {
            _qopenhd.show_toast(qsTr("Enter an RTSP port between 1 and 65535"))
            portField.forceActiveFocus()
            return
        }

        var pipeline = expertPipeline.checked ? pipelineField.text.trim() : generatedPipeline()
        if (pipeline.length === 0 || pipeline.length > 127) {
            _qopenhd.show_toast(qsTr("The GStreamer pipeline must contain 1 to 127 characters"))
            if (expertPipeline.checked) pipelineField.forceActiveFocus()
            return
        }

        var error = settingsModel.try_update_parameter_string("IP_CAM_ADDRESS", address)
        if (error !== "") {
            _qopenhd.show_toast(error)
            return
        }
        error = settingsModel.try_update_parameter_string("IP_CAM_PIPELINE", pipeline)
        if (error !== "") {
            _qopenhd.show_toast(error)
            return
        }
        pipelineField.text = pipeline
        _qopenhd.show_toast(qsTr("IP camera connection saved"))
    }

    function saveReservation() {
        if (!_ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS")) return
        _ohdSystemAirSettingsModel.try_set_param_int_async("V_IP_CAM_MBITS", reservationBox.value, true)
    }

    function controls() {
        return [profileBox, addressField, portField, pathField, webButton, applyButton,
                expertPipeline, pipelineField, reservationBox, reservationButton]
    }

    function focusControl(item) {
        if (!item || !item.visible || !item.enabled) return false
        item.forceActiveFocus()
        ensureVisible(item)
        return true
    }

    function gainFocus() {
        var list = controls()
        for (var i = 0; i < list.length; ++i)
            if (focusControl(list[i])) return
        forceActiveFocus()
    }

    function moveFocus(source, step) {
        var list = controls()
        var current = list.indexOf(source)
        if (current < 0) current = 0
        for (var i = current + step; i >= 0 && i < list.length; i += step) {
            if (focusControl(list[i])) return
        }
        if (step < 0) categoryRequested()
    }

    function handleNavigation(event, source) {
        if (event.key === Qt.Key_Up) {
            moveFocus(source, -1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            moveFocus(source, 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            backRequested()
            event.accepted = true
        }
    }

    function ensureVisible(item) {
        if (!item) return
        var point = item.mapToItem(formColumn, 0, 0)
        var top = point.y - 14
        var bottom = point.y + item.height + 14
        if (top < connectionFlick.contentY)
            connectionFlick.contentY = Math.max(0, top)
        else if (bottom > connectionFlick.contentY + connectionFlick.height)
            connectionFlick.contentY = Math.min(bottom - connectionFlick.height,
                                                Math.max(0, connectionFlick.contentHeight - connectionFlick.height))
    }

    onVisibleChanged: if (visible) Qt.callLater(loadValues)
    onParamRevisionChanged: if (visible && !activeFocus) loadValues()
    onAirParamRevisionChanged: if (visible && !activeFocus) loadValues()

    Flickable {
        id: connectionFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, formColumn.height + 24)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: formColumn
            width: Math.min(940, Math.max(300, connectionFlick.width - 28))
            x: Math.round((connectionFlick.width - width) / 2)
            y: 12
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: sourceLayout.implicitHeight + 32
                radius: 10
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor

                ColumnLayout {
                    id: sourceLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        Text {
                            text: "\uf1eb"
                            color: settings_form.accentColor
                            font.family: "Font Awesome 5 Free"
                            font.pixelSize: 14
                        }
                        Text {
                            text: qsTr("RTSP source")
                            color: settings_form.primaryText
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Connect an Ethernet camera using a preset, or enter its RTSP details manually.")
                        color: settings_form.secondaryText
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width >= 760 ? 2 : 1
                        columnSpacing: 16
                        rowSpacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("Camera preset"); color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                            CompactLinkComboBox {
                                id: profileBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                model: [qsTr("SIYI camera"), qsTr("Generic RTSP camera"), qsTr("Custom")]
                                popupWidth: Math.max(width, 240)
                                Keys.priority: Keys.BeforeItem
                                Keys.onPressed: root.handleNavigation(event, profileBox)
                                onActivated: {
                                    if (currentIndex === 0) {
                                        portField.text = "8554"
                                        pathField.text = "/main.264"
                                    } else if (currentIndex === 1) {
                                        portField.text = "554"
                                        pathField.text = "/stream=0"
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("Camera IPv4 address"); color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                            TextField {
                                id: addressField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "192.168.1.12"
                                maximumLength: 15
                                selectByMouse: true
                                inputMethodHints: Qt.ImhFormattedNumbersOnly | Qt.ImhNoPredictiveText
                                color: settings_form.primaryText
                                Keys.priority: Keys.BeforeItem
                                Keys.onPressed: root.handleNavigation(event, addressField)
                                background: Rectangle {
                                    radius: 8
                                    color: settings_form.panelBackground
                                    border.width: addressField.activeFocus ? 2 : 1
                                    border.color: addressField.activeFocus ? settings_form.accentColor : settings_form.lineColor
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("RTSP port"); color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                            TextField {
                                id: portField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "554"
                                maximumLength: 5
                                selectByMouse: true
                                inputMethodHints: Qt.ImhDigitsOnly
                                color: settings_form.primaryText
                                Keys.priority: Keys.BeforeItem
                                Keys.onPressed: root.handleNavigation(event, portField)
                                background: Rectangle {
                                    radius: 8
                                    color: settings_form.panelBackground
                                    border.width: portField.activeFocus ? 2 : 1
                                    border.color: portField.activeFocus ? settings_form.accentColor : settings_form.lineColor
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("Stream path"); color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "/stream=0"
                                maximumLength: 64
                                selectByMouse: true
                                color: settings_form.primaryText
                                Keys.priority: Keys.BeforeItem
                                Keys.onPressed: root.handleNavigation(event, pathField)
                                background: Rectangle {
                                    radius: 8
                                    color: settings_form.panelBackground
                                    border.width: pathField.activeFocus ? 2 : 1
                                    border.color: pathField.activeFocus ? settings_form.accentColor : settings_form.lineColor
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 7
                        color: settings_form.panelBackground
                        border.color: settings_form.lineColor
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 11; anchors.rightMargin: 11
                            text: "rtsp://" + (addressField.text.length ? addressField.text : qsTr("camera-ip")) +
                                  ":" + (portField.text.length ? portField.text : "554") + root.normalizedPath()
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            font.family: "monospace"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        Item { Layout.fillWidth: true }
                        AdvancedActionButton {
                            id: webButton
                            text: qsTr("Open camera WebUI")
                            iconText: "\uf35d"
                            enabled: root.validIpv4(addressField.text)
                            Keys.priority: Keys.BeforeItem
                            Keys.onPressed: root.handleNavigation(event, webButton)
                            onClicked: Qt.openUrlExternally("http://" + addressField.text.trim())
                        }
                        AdvancedActionButton {
                            id: applyButton
                            text: qsTr("Save connection")
                            iconText: "\uf0c7"
                            primary: true
                            enabled: !root.busy
                            Keys.priority: Keys.BeforeItem
                            Keys.onPressed: root.handleNavigation(event, applyButton)
                            onClicked: root.applyConnection()
                        }
                    }

                    CheckBox {
                        id: expertPipeline
                        text: qsTr("Expert: edit the GStreamer source pipeline")
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: root.handleNavigation(event, expertPipeline)
                        onCheckedChanged: if (checked && pipelineField.text.length === 0)
                                              pipelineField.text = root.generatedPipeline()
                    }

                    TextField {
                        id: pipelineField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        visible: expertPipeline.checked
                        maximumLength: 127
                        selectByMouse: true
                        color: settings_form.primaryText
                        placeholderText: qsTr("GStreamer source pipeline")
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: root.handleNavigation(event, pipelineField)
                        background: Rectangle {
                            radius: 8
                            color: settings_form.panelBackground
                            border.width: pipelineField.activeFocus ? 2 : 1
                            border.color: pipelineField.activeFocus ? settings_form.accentColor : settings_form.lineColor
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: {
                    var revision = root.airParamRevision
                    return _ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS")
                }
                implicitHeight: reservationLayout.implicitHeight + 32
                radius: 10
                color: settings_form.panelBackgroundRaised
                border.color: settings_form.lineColor

                RowLayout {
                    id: reservationLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { text: qsTr("Video-link reservation"); color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Reserve enough link capacity for the bitrate configured in the camera's WebUI.")
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }

                    SpinBox {
                        id: reservationBox
                        Layout.preferredWidth: 118
                        Layout.preferredHeight: 40
                        from: 1; to: 20
                        editable: true
                        textFromValue: function(value) { return value + qsTr(" Mbit/s") }
                        valueFromText: function(text) { return Number(String(text).replace(/[^0-9]/g, "")) }
                        enabled: !root.busy
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: root.handleNavigation(event, reservationBox)
                    }

                    AdvancedActionButton {
                        id: reservationButton
                        text: qsTr("Apply")
                        iconText: "\uf00c"
                        enabled: !root.busy
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: root.handleNavigation(event, reservationButton)
                        onClicked: root.saveReservation()
                    }
                }
            }

            Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }
        }
    }
}
