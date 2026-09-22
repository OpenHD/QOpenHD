import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import OpenHD 1.0

import ".."
import "../openhd_settings"

AdvancedPage {
    id: root
    pageIcon: "\uf1eb"
    pageTitle: qsTr("Extras")
    pageSubtitle: qsTr("ADS-B traffic, audio, RC Lua, data link and FleetControl")
    initialFocusItem: audioTab
    onBackRequested: settings_form.side_bar_regain_focus()

    property int airRevision: _ohdSystemAirSettingsModel.update_count
    property int groundRevision: _ohdSystemGroundSettings.update_count
    property bool adsbAirParameterAvailable: airRevision >= 0 &&
                                                 _ohdSystemAirSettingsModel.param_int_exists("ADSB_ENABLE")
    property bool rcLuaAvailable: airRevision >= 0 &&
                                  _ohdSystemAirSettingsModel.param_int_exists("RC_OHD_CTRL") &&
                                  _ohdSystemAirSettingsModel.param_int_exists("RC_SET_BASE")
    property int rcLuaBaseChannel: {
        airRevision
        return _ohdSystemAirSettingsModel.param_int_exists("RC_SET_BASE")
                ? _ohdSystemAirSettingsModel.get_cached_int("RC_SET_BASE") : 0
    }

    function setAirInt(id, value) {
        if (!_ohdSystemAirSettingsModel.param_int_exists(id)) return
        var error = _ohdSystemAirSettingsModel.try_update_parameter_int(id, value)
        if (error !== "") _hudLogMessagesModel.signalAddLogMessage(4, error)
    }
    function setAirString(id, value) {
        if (!_ohdSystemAirSettingsModel.param_string_exists(id)) return
        var error = _ohdSystemAirSettingsModel.try_update_parameter_string(id, value)
        if (error !== "") _hudLogMessagesModel.signalAddLogMessage(4, error)
    }
    function setBoth(id, value) {
        if (_ohdSystemAirSettingsModel.param_int_exists(id)) setAirInt(id, value)
        if (_ohdSystemGroundSettings.param_int_exists(id)) {
            var error = _ohdSystemGroundSettings.try_update_parameter_int(id, value)
            if (error !== "") _hudLogMessagesModel.signalAddLogMessage(4, error)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        TabBar {
            id: tabs
            Layout.fillWidth: true
            spacing: 6
            background: Item { }
            AdvancedTabButton { id: audioTab; text: qsTr("AUDIO"); iconText: "\uf028" }
            AdvancedTabButton { text: qsTr("ADS-B"); iconText: "\uf072" }
            AdvancedTabButton { text: qsTr("RC LUA"); iconText: "\uf11b" }
            AdvancedTabButton { text: qsTr("DATA LINK"); iconText: "\uf1eb" }
            AdvancedTabButton { text: qsTr("FLEETCONTROL"); iconText: "\uf0c0" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            ScrollView {
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    AdvancedCard {
                        Layout.fillWidth: true; implicitHeight: audioAirColumn.implicitHeight + 32
                        ColumnLayout {
                            id: audioAirColumn; anchors.fill: parent; spacing: 10
                            Label { text: qsTr("AUDIO INPUT & OUTPUT"); color: settings_form.primaryText; font.bold: true }
                            Label {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Choose the air-unit microphone and this device's audio output. Audio is disabled by default.")
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Streaming mode"); color: settings_form.primaryText; Layout.fillWidth: true }
                                CompactLinkComboBox {
                                    id: audioMode
                                    property var values: [1, 0, 100]
                                    model: [qsTr("Off"), qsTr("Microphone"), qsTr("Test tone")]
                                    currentIndex: {
                                        root.airRevision
                                        if (!_ohdSystemAirSettingsModel.param_int_exists("AUDIO_ENABLE")) return 0
                                        var i = values.indexOf(_ohdSystemAirSettingsModel.get_cached_int("AUDIO_ENABLE"))
                                        return i < 0 ? 0 : i
                                    }
                                    enabled: _ohdSystemAirSettingsModel.param_int_exists("AUDIO_ENABLE")
                                    onActivated: root.setAirInt("AUDIO_ENABLE", values[index])
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Microphone"); color: settings_form.primaryText; Layout.fillWidth: true }
                                CompactLinkComboBox {
                                    id: captureDevice
                                    Layout.preferredWidth: Math.min(420, root.width * 0.48)
                                    property var ids: []
                                    model: []
                                    function reload() {
                                        var nextNames = [qsTr("System default")]
                                        var nextIds = [""]
                                        for (var i = 0; i < 8; ++i) {
                                            var id = "AUD_DEV_" + i
                                            if (!_ohdSystemAirSettingsModel.param_string_exists(id)) continue
                                            var raw = String(_ohdSystemAirSettingsModel.get_cached_string(id))
                                            if (!raw.length) continue
                                            var split = raw.indexOf("|")
                                            nextIds.push(split < 0 ? raw : raw.substring(0, split))
                                            nextNames.push(split < 0 ? raw : raw.substring(split + 1))
                                        }
                                        ids = nextIds; model = nextNames
                                        var selected = _ohdSystemAirSettingsModel.param_string_exists("AUDIO_DEVICE") ? String(_ohdSystemAirSettingsModel.get_cached_string("AUDIO_DEVICE")) : ""
                                        currentIndex = Math.max(0, nextIds.indexOf(selected))
                                    }
                                    Component.onCompleted: reload()
                                    onActivated: root.setAirString("AUDIO_DEVICE", ids[index])
                                    Connections { target: _ohdSystemAirSettingsModel; onUpdate_countChanged: captureDevice.reload() }
                                }
                                Button { text: "\uf2f1"; font.family: "Font Awesome 5 Free"; onClicked: _ohdSystemAirSettingsModel.try_refetch_all_parameters_async(false) }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Microphone gain"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Slider {
                                    id: gainSlider; Layout.preferredWidth: Math.min(360, root.width * 0.4); from: 0; to: 200; stepSize: 1
                                    value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("AUDIO_GAIN") ? _ohdSystemAirSettingsModel.get_cached_int("AUDIO_GAIN") : 100 }
                                    enabled: _ohdSystemAirSettingsModel.param_int_exists("AUDIO_GAIN")
                                    onMoved: gainValue.text = Math.round(value) + "%"
                                    onPressedChanged: if (!pressed) root.setAirInt("AUDIO_GAIN", Math.round(value))
                                }
                                Label { id: gainValue; text: Math.round(gainSlider.value) + "%"; color: settings_form.primaryText; Layout.preferredWidth: 48 }
                            }
                            Loader {
                                Layout.fillWidth: true
                                active: QOPENHD_AUDIO_PLAYBACK_AVAILABLE
                                sourceComponent: audioPlaybackControls
                            }
                            Label {
                                visible: !QOPENHD_AUDIO_PLAYBACK_AVAILABLE
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Output selection, volume and VU meters are unavailable in this build.")
                            }
                        }
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width; spacing: 12
                    AdvancedCard {
                        Layout.fillWidth: true; implicitHeight: adsbColumn.implicitHeight + 32
                        ColumnLayout {
                            id: adsbColumn; anchors.fill: parent; spacing: 12
                            Label { text: qsTr("ADS-B TRAFFIC"); color: settings_form.primaryText; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle { width: 12; height: 12; radius: 6; color: AdsbVehicleManager.status === 2 ? "#35d36b" : (AdsbVehicleManager.status === 1 ? "#ff5a5a" : "#7d8790") }
                                Label {
                                    Layout.fillWidth: true; color: settings_form.primaryText
                                    text: AdsbVehicleManager.status === 2 ? qsTr("dump1090 connected") : (AdsbVehicleManager.status === 1 ? qsTr("dump1090 unavailable") : qsTr("ADS-B disabled"))
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Show ADS-B traffic on map"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_enable; onToggled: settings.adsb_enable = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Internet traffic source"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_show_internet_data; onToggled: settings.adsb_show_internet_data = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("SDR / OpenHD traffic source"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_show_sdr_data; onToggled: settings.adsb_show_sdr_data = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Enable receiver on connected air unit"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch {
                                    enabled: root.adsbAirParameterAvailable
                                    checked: { root.airRevision; return enabled && _ohdSystemAirSettingsModel.get_cached_int("ADSB_ENABLE") !== 0 }
                                    onToggled: root.setAirInt("ADSB_ENABLE", checked ? 1 : 0)
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Display radius"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Slider { id: radiusSlider; Layout.preferredWidth: Math.min(360, root.width * 0.4); from: 5000; to: 200000; stepSize: 5000; value: settings.adsb_radius; onMoved: settings.adsb_radius = value }
                                Label { text: Math.round(radiusSlider.value / 1000) + " km"; color: settings_form.primaryText; Layout.preferredWidth: 62 }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Show unknown / zero altitude"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_show_unknown_or_zero_alt; onToggled: settings.adsb_show_unknown_or_zero_alt = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Show three closest aircraft widget"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_show_nearest_widget; onToggled: settings.adsb_show_nearest_widget = checked }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Show aircraft direction on OSD"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch { checked: settings.adsb_show_osd_markers; onToggled: settings.adsb_show_osd_markers = checked }
                            }
                            Label {
                                visible: !root.adsbAirParameterAvailable
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Connect to an OpenHD air unit with ADS-B support to enable its SDR receiver.")
                            }
                        }
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width; spacing: 12
                    AdvancedCard {
                        Layout.fillWidth: true; implicitHeight: rcLuaSetupColumn.implicitHeight + 32
                        ColumnLayout {
                            id: rcLuaSetupColumn; anchors.fill: parent; spacing: 11
                            Label { text: qsTr("EDGETX / OPENTX LUA SETTINGS"); color: settings_form.primaryText; font.bold: true }
                            Label {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Lets the OpenHD Lua tool change frequency, bandwidth, MCS and TX power, or disable FHSS. Assign the OHDSET mixer outputs to four consecutive receiver channels in this order: D2, D1, D0, CLK.")
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Enable Lua settings protocol"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch {
                                    enabled: root.rcLuaAvailable && root.rcLuaBaseChannel > 0
                                    checked: { root.airRevision; return enabled && _ohdSystemAirSettingsModel.get_cached_int("RC_OHD_CTRL") !== 0 }
                                    onToggled: root.setAirInt("RC_OHD_CTRL", checked ? 1 : 0)
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("First RC channel"); color: settings_form.primaryText; Layout.fillWidth: true }
                                SpinBox {
                                    id: rcLuaBase
                                    from: 0; to: 15; editable: true
                                    value: root.rcLuaBaseChannel
                                    textFromValue: function(value) { return value === 0 ? qsTr("Disabled") : qsTr("CH %1").arg(value) }
                                    onValueModified: root.setAirInt("RC_SET_BASE", value)
                                }
                            }
                            Label {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.primaryText
                                text: root.rcLuaBaseChannel > 0
                                      ? qsTr("Mapping: CH %1 = D2, CH %2 = D1, CH %3 = D0, CH %4 = CLK")
                                            .arg(root.rcLuaBaseChannel).arg(root.rcLuaBaseChannel + 1)
                                            .arg(root.rcLuaBaseChannel + 2).arg(root.rcLuaBaseChannel + 3)
                                      : qsTr("Select a first channel. Four consecutive channels are required.")
                            }
                            Label {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("The four channels must otherwise be unused. Configure RC_OHD_CTRL only after checking that all four live values reach the Air unit.")
                            }
                        }
                    }

                    AdvancedCard {
                        Layout.fillWidth: true; implicitHeight: rcLuaDebugColumn.implicitHeight + 32
                        ColumnLayout {
                            id: rcLuaDebugColumn; anchors.fill: parent; spacing: 8
                            Label { text: qsTr("LUA PROTOCOL DEBUG"); color: settings_form.primaryText; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle { width: 12; height: 12; radius: 6; color: _rcchannelsmodelfc.is_alive ? "#35d36b" : "#ff5a5a" }
                                Label {
                                    Layout.fillWidth: true; color: settings_form.primaryText
                                    text: _rcchannelsmodelfc.is_alive ? qsTr("RC channel data received") : qsTr("No RC channel data from the flight controller")
                                }
                            }
                            Label {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Data lines must be near 1000 or 2000 µs. The clock must alternate while a command is sent. Mid-position values are invalid.")
                            }
                            Repeater {
                                model: _rcchannelsmodelfc
                                delegate: RowLayout {
                                    property int protocolOffset: index - root.rcLuaBaseChannel + 1
                                    visible: root.rcLuaBaseChannel > 0 && protocolOffset >= 0 && protocolOffset < 4
                                    Layout.fillWidth: true
                                    Label {
                                        Layout.preferredWidth: 110; color: settings_form.primaryText; font.bold: true
                                        text: protocolOffset === 0 ? "D2" : (protocolOffset === 1 ? "D1" : (protocolOffset === 2 ? "D0" : "CLK"))
                                    }
                                    Label { Layout.preferredWidth: 70; color: settings_form.secondaryText; text: qsTr("CH %1").arg(index + 1) }
                                    ProgressBar { Layout.fillWidth: true; from: 1000; to: 2000; value: model.curr_value }
                                    Label {
                                        Layout.preferredWidth: 120; horizontalAlignment: Text.AlignRight
                                        color: model.curr_value >= 900 && model.curr_value <= 1300 ? "#35d36b"
                                               : (model.curr_value >= 1700 && model.curr_value <= 2100 ? "#35d36b" : "#ff5a5a")
                                        text: model.curr_value + " µs  " +
                                              (model.curr_value >= 900 && model.curr_value <= 1300 ? "0"
                                               : (model.curr_value >= 1700 && model.curr_value <= 2100 ? "1" : qsTr("INVALID")))
                                    }
                                }
                            }
                            Label {
                                visible: root.rcLuaBaseChannel === 0
                                Layout.fillWidth: true; color: settings_form.secondaryText
                                text: qsTr("Select the first RC channel to display protocol inputs.")
                            }
                        }
                    }
                    Label {
                        visible: !root.rcLuaAvailable
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                        text: qsTr("Connect an Air unit containing the RC Lua settings protocol to configure it.")
                    }
                }
            }

            ScrollView {
                clip: true; contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width; spacing: 12
                    AdvancedCard {
                        Layout.fillWidth: true; implicitHeight: dataColumn.implicitHeight + 32
                        ColumnLayout {
                            id: dataColumn; anchors.fill: parent; spacing: 11
                            Label { text: qsTr("UNIVERSAL UDP DATA LINK"); color: settings_form.primaryText; font.bold: true }
                            Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText; text: qsTr("Bridges localhost UDP through encrypted wifibroadcast. FEC overhead is deducted from the configured RF budget.") }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: qsTr("Enabled on air and ground"); color: settings_form.primaryText; Layout.fillWidth: true }
                                Switch {
                                    enabled: _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_ENABLE") && _ohdSystemGroundSettings.param_int_exists("WB_UDP_ENABLE")
                                    checked: { root.airRevision; root.groundRevision; return enabled && _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_ENABLE") !== 0 && _ohdSystemGroundSettings.get_cached_int("WB_UDP_ENABLE") !== 0 }
                                    onToggled: root.setBoth("WB_UDP_ENABLE", checked ? 1 : 0)
                                }
                            }
                            Label { text: qsTr("Channel bandwidth"); color: settings_form.primaryText }
                            CompactLinkComboBox { Layout.fillWidth: true; model: [5, 10, 20, 40]; currentIndex: Math.max(0, model.indexOf(_ohdSystemAir.curr_channel_width_mhz)); onActivated: _wbLinkSettingsHelper.change_param_air_channel_width_async(model[index], true) }
                            Label { text: qsTr("FEC overhead (%)"); color: settings_form.primaryText }
                            SpinBox {
                                Layout.fillWidth: true; from: 0; to: 100; editable: true
                                value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_FEC") ? _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_FEC") : 20 }
                                onValueModified: root.setBoth("WB_UDP_FEC", value)
                            }
                            Label { text: qsTr("RF link budget (%)"); color: settings_form.primaryText }
                            SpinBox {
                                Layout.fillWidth: true; from: 1; to: 80; editable: true
                                value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_BUDGET") ? _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_BUDGET") : 10 }
                                onValueModified: root.setBoth("WB_UDP_BUDGET", value)
                            }
                            Label { text: qsTr("Maximum payload (kbit/s, 0 = automatic)"); color: settings_form.primaryText }
                            SpinBox {
                                Layout.fillWidth: true; from: 0; to: 100000; stepSize: 100; editable: true
                                value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_MAX_KBPS") ? _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_MAX_KBPS") : 0 }
                                onValueModified: root.setBoth("WB_UDP_MAX_KBPS", value)
                            }
                            Label { text: qsTr("UDP input / output ports"); color: settings_form.primaryText }
                            RowLayout {
                                Layout.fillWidth: true
                                SpinBox {
                                    Layout.fillWidth: true; from: 1024; to: 65535; editable: true
                                    value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_IN_PORT") ? _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_IN_PORT") : 5602 }
                                    onValueModified: root.setBoth("WB_UDP_IN_PORT", value)
                                }
                                SpinBox {
                                    Layout.fillWidth: true; from: 1024; to: 65535; editable: true
                                    value: { root.airRevision; return _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_OUT_PORT") ? _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_OUT_PORT") : 5603 }
                                    onValueModified: root.setBoth("WB_UDP_OUT_PORT", value)
                                }
                            }
                            Label {
                                visible: !_ohdSystemAirSettingsModel.param_int_exists("WB_UDP_ENABLE") || !_ohdSystemGroundSettings.param_int_exists("WB_UDP_ENABLE")
                                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: settings_form.secondaryText
                                text: qsTr("Connect compatible OpenHD air and ground units to configure the data link.")
                            }
                        }
                    }
                }
            }

            FleetControlSettingsPanel {
                onBackRequested: root.backRequested()
            }
        }
    }

    Component {
        id: audioPlaybackControls
        ColumnLayout {
            id: playbackColumn
            width: parent ? parent.width : implicitWidth
            spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Play received audio"); color: settings_form.primaryText; Layout.fillWidth: true }
                    Switch { checked: _audioControl.playing; onToggled: { settings.dev_enable_live_audio_playback = checked; _audioControl.setPlaybackEnabled(checked) } }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Output"); color: settings_form.primaryText; Layout.fillWidth: true }
                    CompactLinkComboBox {
                        id: outputDevice; Layout.preferredWidth: Math.min(420, root.width * 0.48); model: _audioControl.outputDeviceNames
                        currentIndex: Math.max(0, _audioControl.outputDeviceIds.indexOf(_audioControl.selectedOutputDevice))
                        onActivated: _audioControl.selectedOutputDevice = _audioControl.outputDeviceIds[index]
                    }
                    Button { text: "\uf2f1"; font.family: "Font Awesome 5 Free"; onClicked: _audioControl.refreshDevices() }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Playback volume"); color: settings_form.primaryText; Layout.fillWidth: true }
                    Slider { id: volumeSlider; Layout.preferredWidth: Math.min(360, root.width * 0.4); from: 0; to: 100; stepSize: 1; value: _audioControl.playbackVolume; onMoved: _audioControl.playbackVolume = Math.round(value) }
                    Label { text: Math.round(volumeSlider.value) + "%"; color: settings_form.primaryText; Layout.preferredWidth: 48 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Input VU"); color: settings_form.primaryText; Layout.preferredWidth: 130 }
                    ProgressBar { Layout.fillWidth: true; from: 0; to: 100; value: _audioControl.inputLevel }
                    Label { text: _audioControl.inputLevel + "%"; color: settings_form.primaryText; Layout.preferredWidth: 48 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Output VU"); color: settings_form.primaryText; Layout.preferredWidth: 130 }
                    ProgressBar { Layout.fillWidth: true; from: 0; to: 100; value: _audioControl.outputLevel }
                    Label { text: _audioControl.outputLevel + "%"; color: settings_form.primaryText; Layout.preferredWidth: 48 }
                }
        }
    }
}
