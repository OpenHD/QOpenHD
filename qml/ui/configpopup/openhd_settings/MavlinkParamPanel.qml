import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Contains a list of all the settings on the left, and opens up a parameter editor instance on
// the right if the user wants to edit any mavlink settings
Rectangle {
    id: root
    signal backRequested()
    width: parent.width
    height: parent.height
    property int paramEditorWidth: 300

    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this should be replaced by the proper instance for air or camera
    property var m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
    // figure out if the system is alive
    property var m_instanceCheckIsAvlie: _ohdSystemGround
    // unly used for camera 1 / camera2
    property bool m_is_secondary_cam: false

    property string m_name: "undefined"
    property bool m_requires_alive_air: false
    property bool m_show_link_status: false
    property bool m_ip_camera_settings_available: m_instanceMavlinkSettingsModel.has_params_fetched &&
                                                   m_instanceMavlinkSettingsModel.param_string_exists("IP_CAM_PIPELINE")

    //color: "red"
    //color: "transparent"
    color: "transparent"
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    function gainFocus() { listView.forceActiveFocus() }

    function readableLinkName(name) {
        var key = String(name).trim().toUpperCase()
        if (key === "WIFIBROADCAST") return qsTr("WiFiBroadcast")
        // Older Air builds truncate the MAVLink string after the first letter.
        if (key === "E" || key === "ETH" || key === "ETHERNET") return qsTr("Ethernet")
        if (key === "MICROHARD") return qsTr("Microhard")
        if (key === "ARTOSYN") return qsTr("Artosyn")
        if (key === "MLRS") return qsTr("mLRS")
        if (key === "LTE" || key === "FLEETCONTROL" || key === "FLEETCONTROL LTE")
            return qsTr("FleetControl LTE")
        return name
    }

    function activeAirLinks() {
        // ACTIVE_LINKS is authoritative and also contains secondary transports
        // such as Ethernet. update_count keeps this binding live after a fetch.
        var unusedRevision = m_instanceMavlinkSettingsModel.update_count
        var links = []
        if (m_instanceMavlinkSettingsModel.param_string_exists("ACTIVE_LINKS")) {
            var raw = m_instanceMavlinkSettingsModel.get_cached_string("ACTIVE_LINKS")
            var values = raw.split("+")
            for (var i = 0; i < values.length; ++i) {
                var key = values[i].trim().toUpperCase()
                if (key.length > 0 && key !== "NONE")
                    links.push(readableLinkName(values[i]))
            }
        }

        // Older Air versions do not expose ACTIVE_LINKS yet.
        if (links.length === 0) {
            var artosyn = _ohdSystemAir.artosyn_link_detected || _ohdSystemAir.primary_link_type === 4
            var microhard = _ohdSystemAir.microhard_enabled > 0
            var wifi = (_wifi_card_air.alive && _wifi_card_air.card_type_as_string !== "ARTOSYN") ||
                       (_ohdSystemAir.is_alive && !artosyn && !microhard)
            if (wifi) links.push(qsTr("WiFiBroadcast"))
            if (microhard) links.push(qsTr("Microhard"))
            if (artosyn) links.push(qsTr("Artosyn"))
        }

        if (_ohdSystemAir.fleetcontrol_lte_active && links.indexOf(qsTr("FleetControl LTE")) < 0)
            links.push(qsTr("FleetControl LTE"))
        return links
    }

    property int m_progress_perc : m_instanceMavlinkSettingsModel.curr_get_all_progress_perc;
    property var activeLinkNames: activeAirLinks()

    property bool m_any_param_busy: _ohdSystemGroundSettings.ui_is_busy || _ohdSystemAirSettingsModel.ui_is_busy || _airCameraSettingsModel.ui_is_busy ||
                                    _airCameraSettingsModel2.ui_is_busy;
    property var collapsedGroups: ({})

    function groupIsCollapsed(groupName) {
        if(collapsedGroups[groupName] !== undefined) return collapsedGroups[groupName]
        return groupName !== "GENERAL"
    }

    function toggleGroup(groupName) {
        var updated = {}
        for(var key in collapsedGroups) updated[key] = collapsedGroups[key]
        updated[groupName] = !groupIsCollapsed(groupName)
        collapsedGroups = updated
    }

    function ipCameraPortFromPipeline(pipeline) {
        var match = pipeline.match(/rtsp:\/\/\{IP\}:(\d+)/)
        return match ? match[1] : "554"
    }

    function ipCameraPathFromPipeline(pipeline) {
        var match = pipeline.match(/rtsp:\/\/\{IP\}:\d+([^\s]+)/)
        return match ? match[1] : "/stream=0"
    }

    function generatedIpCameraPipeline() {
        var port = ipCameraPortField.text.trim()
        var path = ipCameraPathField.text.trim()
        if(path.length === 0) path = "/"
        if(path.charAt(0) !== "/") path = "/" + path
        return "rtspsrc location=rtsp://{IP}:" + port + path +
               " protocols=tcp latency=0 ! rtp{CODEC}depay"
    }

    function saveIpCameraConnection() {
        var port = parseInt(ipCameraPortField.text)
        if(ipCameraAddressField.text.length === 0 || isNaN(port) || port < 1 || port > 65535) {
            _qopenhd.show_toast(qsTr("Please enter a valid camera IP and RTSP port"))
            return
        }
        var pipeline = expertPipelineCheck.checked ? expertPipelineField.text : generatedIpCameraPipeline()
        if(pipeline.length === 0 || pipeline.length > 127) {
            _qopenhd.show_toast(qsTr("The generated pipeline is too long"))
            return
        }
        var error = m_instanceMavlinkSettingsModel.try_update_parameter_string("IP_CAM_ADDRESS", ipCameraAddressField.text)
        if(error !== "") {
            _qopenhd.show_toast(error)
            return
        }
        error = m_instanceMavlinkSettingsModel.try_update_parameter_string("IP_CAM_PIPELINE", pipeline)
        _qopenhd.show_toast(error === "" ? qsTr("IP camera connection saved") : error)
    }

    onVisibleChanged: {
        if(visible){
            if(!m_instanceCheckIsAvlie.is_alive){
                var message = m_requires_alive_air
                    ? qsTr("AIR not alive, parameters unavailable")
                    : qsTr("GND not alive, parameters unavailable");
                _qopenhd.show_toast(message);
            }else{
                if(! m_instanceMavlinkSettingsModel.has_params_fetched){
                   m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
                }
            }
        }
    }

    Component {
        id: delegateMavlinkSettingsValue

        Rectangle{
            //color: (index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
            //color: "transparent"
            color: ListView.isCurrentItem && listView.activeFocus
                   ? (settings_form.darkMode ? "#174d82" : "#dcecff")
                   : (index % 2 === 0 ? settings_form.panelBackgroundRaised : "transparent")
            property bool isIpCameraQuickSetting: model.unique_id === "IP_CAM_ADDRESS" || model.unique_id === "IP_CAM_PIPELINE"
            property bool isRawActiveLinks: root.m_show_link_status && model.unique_id === "ACTIVE_LINKS"
            property bool groupCollapsed: groupIsCollapsed(model.group)
            function activate() {
                inlineEditor.gainFocus()
            }
            height: (isIpCameraQuickSetting || isRawActiveLinks || groupCollapsed) ? 0 : rowHeight
            width: listView.width
            visible: !isIpCameraQuickSetting && !isRawActiveLinks && !groupCollapsed
            radius: 7
            border.color: ListView.isCurrentItem && listView.activeFocus
                          ? settings_form.accentColor : settings_form.lineColor
            border.width: ListView.isCurrentItem && listView.activeFocus ? 2 : (index % 2 === 0 ? 1 : 0)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: parent.width * 0.58
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: model.unique_id
                        font.bold: true
                        font.pixelSize: 13
                        color: settings_form.primaryText
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: model.shortDescription !== "TODO" && model.shortDescription.length > 0
                        text: model.shortDescription
                        font.pixelSize: 10
                        color: settings_form.secondaryText
                        elide: Text.ElideRight
                    }
                }
                InlineMavlinkParamControl {
                    id: inlineEditor
                    Layout.preferredWidth: Math.max(150, Math.min(280, root.width * 0.34))
                    Layout.preferredHeight: elementHeight
                    settingsModel: m_instanceMavlinkSettingsModel
                    paramId: model.unique_id
                    valueType: model.valueType
                    paramValue: model.value
                    displayValue: model.extraValue
                    readOnly: model.read_only
                    busy: m_any_param_busy || !m_instanceCheckIsAvlie.is_alive
                }
                ButtonIconWarning{
                    id: warning_whitelisted
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        _messageBoxInstance.set_text_and_show(qsTr("This param is whitelisted (You should not edit it from here / editing can break things))"))
                    }
                    visible: model.whitelisted
                }
            }
        }
    }

    // Left part: multiple colums of param value
    Rectangle{
        id: scrollViewRectangle
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        //color: "green"
        //opacity: 0.5
        color: "transparent"

        Item {
            id: linkStatusPanel
            visible: root.m_show_link_status
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            width: parent.width - 16
            height: visible ? Math.max(30, statusFlow.childrenRect.height) : 0

            Flow {
                id: statusFlow
                width: parent.width
                spacing: 8

                Item {
                    width: statusTitle.implicitWidth
                    height: 30
                    Row {
                        id: statusTitle
                        height: parent.height
                        spacing: 8
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            color: root.activeLinkNames.length > 0
                                   ? Qt.rgba(0.1, 0.8, 0.35, 0.13)
                                   : Qt.rgba(1.0, 0.65, 0.1, 0.13)
                            Text {
                                anchors.centerIn: parent
                                text: "\uf1eb"
                                font.family: "Font Awesome 5 Free"
                                font.pixelSize: 13
                                color: root.activeLinkNames.length > 0 ? settings_form.goodColor : "#f0a43c"
                            }
                        }
                        Text {
                            height: 30
                            text: qsTr("Active links")
                            color: settings_form.primaryText
                            font.pixelSize: 10
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Repeater {
                    model: root.activeLinkNames.length > 0
                           ? root.activeLinkNames : [qsTr("No active Air link")]
                    delegate: Rectangle {
                        width: linkName.implicitWidth + 30
                        height: 30
                        radius: 9
                        color: settings_form.panelBackgroundRaised
                        border.width: 1
                        border.color: root.activeLinkNames.length > 0
                                      ? Qt.rgba(0.25, 0.65, 1.0, 0.55) : settings_form.lineColor
                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.activeLinkNames.length > 0 ? settings_form.goodColor : "#f0a43c"
                            }
                            Text {
                                id: linkName
                                text: modelData
                                color: root.activeLinkNames.length > 0
                                       ? settings_form.primaryText : settings_form.secondaryText
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        ScrollView{
            id: paramListScrollView
            width: parent.width
            y: linkStatusPanel.visible
               ? linkStatusPanel.y + linkStatusPanel.height + 12
               : 0
            height: parent.height - y
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            // Always show the scroll bar (sometimes the interactive might not work) but allow interactive also
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ListView {
                id: listView
                width: parent.width
                model: m_instanceMavlinkSettingsModel
                delegate: delegateMavlinkSettingsValue
                keyNavigationWraps: false
                highlightMoveDuration: 100
                Keys.onReturnPressed: if (currentItem) currentItem.activate()
                Keys.onEnterPressed: if (currentItem) currentItem.activate()
                Keys.onLeftPressed: root.backRequested()
                Keys.onEscapePressed: root.backRequested()
                Keys.onUpPressed: {
                    if (currentIndex <= 0) {
                        root.backRequested()
                        event.accepted = true
                    }
                }
                section.property: "group"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle {
                    width: listView.width
                    height: rowHeight * 2 / 3
                    color: settings_form.panelBackgroundRaised
                    radius: 8
                    border.color: settings_form.lineColor
                    border.width: 1
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 42
                        anchors.verticalCenter: parent.verticalCenter
                        text: section
                        font.bold: true
                        font.pixelSize: 13
                        color: settings_form.primaryText
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: groupIsCollapsed(section) ? "\uf0d7" : "\uf0d8"
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 13
                        color: settings_form.accentColor
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleGroup(section)
                    }
                }
                visible: !please_fetch_item.visible && m_instanceCheckIsAvlie.is_alive
                header: Rectangle {
                    width: listView.width - 12
                    height: m_ip_camera_settings_available ? (expertPipelineCheck.checked ? 570 : 510) : 0
                    visible: m_ip_camera_settings_available
                    color: settings_form.panelBackgroundRaised
                    radius: 6
                    property string storedPipeline: m_instanceMavlinkSettingsModel.get_cached_string("IP_CAM_PIPELINE")

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5

                        Text {
                            text: qsTr("IP CAMERA SETUP")
                            font.bold: true
                            color: settings_form.primaryText
                        }
                        ComboBox {
                            id: ipCameraProfileField
                            Layout.fillWidth: true
                            model: [qsTr("SIYI camera"), qsTr("Generic RTSP camera"), qsTr("Custom")]
                            currentIndex: storedPipeline.indexOf(":8554/main.264") >= 0 ? 0 : 1
                            onActivated: {
                                if(index === 0) {
                                    ipCameraPortField.text = "8554"
                                    ipCameraPathField.text = "/main.264"
                                } else if(index === 1) {
                                    ipCameraPortField.text = "554"
                                    ipCameraPathField.text = "/stream=0"
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: qsTr("Camera IP"); color: settings_form.primaryText }
                            TextField {
                                id: ipCameraAddressField
                                Layout.fillWidth: true
                                placeholderText: "192.168.1.12"
                                text: m_instanceMavlinkSettingsModel.get_cached_string("IP_CAM_ADDRESS")
                                maximumLength: 15
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: qsTr("RTSP port"); color: settings_form.primaryText }
                            TextField {
                                id: ipCameraPortField
                                Layout.preferredWidth: 100
                                text: ipCameraPortFromPipeline(storedPipeline)
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 5
                            }
                            Text { text: qsTr("Stream path"); color: settings_form.primaryText }
                            TextField {
                                id: ipCameraPathField
                                Layout.fillWidth: true
                                text: ipCameraPathFromPipeline(storedPipeline)
                                placeholderText: "/main.264"
                                maximumLength: 48
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Generated RTSP link: rtsp://%1:%2%3").arg(ipCameraAddressField.text).arg(ipCameraPortField.text).arg(ipCameraPathField.text)
                            elide: Text.ElideMiddle
                            color: settings_form.secondaryText
                        }
                        Button {
                            Layout.fillWidth: true
                            text: qsTr("SAVE CAMERA CONNECTION")
                            enabled: !m_any_param_busy
                            onClicked: saveIpCameraConnection()
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: qsTr("Link reservation"); color: settings_form.primaryText }
                            SpinBox {
                                id: ipCameraBitrateField
                                from: 1
                                to: 20
                                value: _ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS") ? _ohdSystemAirSettingsModel.get_cached_int("V_IP_CAM_MBITS") : 2
                                editable: true
                            }
                            Button {
                                text: qsTr("Save Mbit/s")
                                enabled: _ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS") && !m_any_param_busy
                                onClicked: _ohdSystemAirSettingsModel.try_set_param_int_async("V_IP_CAM_MBITS", ipCameraBitrateField.value, true)
                            }
                            Button {
                                text: qsTr("Open WebUI")
                                enabled: ipCameraAddressField.text.length > 0
                                onClicked: Qt.openUrlExternally("http://" + ipCameraAddressField.text)
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("VIDEO_CODEC, RESOLUTION_FPS and BITRATE_MBITS below also configure a supported camera plugin.")
                            wrapMode: Text.WordWrap
                            color: settings_form.darkMode ? "#ffbf69" : "#9a4d00"
                        }
                        CheckBox {
                            id: expertPipelineCheck
                            text: qsTr("Expert: edit GStreamer pipeline")
                        }
                        TextField {
                            id: expertPipelineField
                            Layout.fillWidth: true
                            visible: expertPipelineCheck.checked
                            text: storedPipeline
                            maximumLength: 127
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: qsTr("Settings are sent directly to %1 via MAVLink.").arg(m_name)
                            color: settings_form.secondaryText
                        }
                    }
                }
            }
        }
        Item{
            id: please_fetch_item
            width: scrollViewRectangle.width
            height: scrollViewRectangle.height
            visible: !m_instanceMavlinkSettingsModel.has_params_fetched && m_instanceCheckIsAvlie.is_alive
            Text{
                anchors.centerIn: parent
                text: qsTr("Please fetch");
                font.bold: true
            }
        }
        Item{
            id: not_connected_overlay
            width: scrollViewRectangle.width
            height: scrollViewRectangle.height
            visible: !m_instanceCheckIsAvlie.is_alive
            /*Rectangle{
                anchors.fill: parent
                color: "gray"
                opacity: 0.5
            }*/
            Text {
                anchors.fill: parent
                text: qsTr("\uf127");
                font.family: "Font Awesome 5 Free";
                color: settings_form.secondaryText
                //fontSizeMode: Text.Fit
                //font.pointSize: 100000
                font.pixelSize: 100
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.5
            }
        }
    }

}
