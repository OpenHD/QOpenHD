import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import OpenHD 1.0

import "../elements"

BaseWidget {
    id: root
    width: 112
    height: 40
    visible: settings.show_widgets
             && _ohdSystemAirSettingsModel.param_int_exists("WB_UDP_ENABLE")
    widgetIdentifier: "udp_data_link_debug_widget"
    bw_verbose_name: qsTr("UDP DATA LINK")
    defaultAlignment: 0
    defaultXOffset: 460
    defaultYOffset: 2
    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionWidth: 330
    widgetActionHeight: 430

    property int revision: _ohdSystemAirSettingsModel.update_count
    property bool enabled: revision >= 0
                           && _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_ENABLE") !== 0

    function setBoth(id, value) {
        var airError = _ohdSystemAirSettingsModel.try_update_parameter_int(id, value)
        var groundError = _ohdSystemGroundSettings.try_update_parameter_int(id, value)
        if (airError !== "") _hudLogMessagesModel.signalAddLogMessage(4, airError)
        if (groundError !== "") _hudLogMessagesModel.signalAddLogMessage(4, groundError)
    }

    function setBandwidth(value) {
        _wbLinkSettingsHelper.change_param_air_channel_width_async(value, true)
    }

    widgetDetailComponent: Text {
        color: "white"
        text: root.enabled ? qsTr("UDP ON") : qsTr("UDP OFF")
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    widgetActionComponent: ScrollView {
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 9
            Label { text: qsTr("UDP datalink debug"); color: "white"; font.bold: true }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#cccccc"
                text: qsTr("Bridges localhost UDP through encrypted wifibroadcast. The budget is a share of usable RF bitrate; FEC overhead is deducted automatically.")
            }
            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Enabled"); color: "white"; Layout.fillWidth: true }
                Switch { checked: root.enabled; onToggled: root.setBoth("WB_UDP_ENABLE", checked ? 1 : 0) }
            }
            Label { visible: root.enabled; text: qsTr("Channel bandwidth"); color: "white" }
            ComboBox {
                visible: root.enabled; Layout.fillWidth: true
                model: [5, 10, 20, 40]
                currentIndex: Math.max(0, model.indexOf(_ohdSystemAir.curr_channel_width_mhz))
                onActivated: root.setBandwidth(model[index])
            }
            Label { visible: root.enabled; text: qsTr("FEC overhead (%)"); color: "white" }
            SpinBox {
                visible: root.enabled; Layout.fillWidth: true; from: 0; to: 100
                value: _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_FEC")
                editable: true; onValueModified: root.setBoth("WB_UDP_FEC", value)
            }
            Label { visible: root.enabled; text: qsTr("Link budget (%)"); color: "white" }
            SpinBox {
                visible: root.enabled; Layout.fillWidth: true; from: 1; to: 80
                value: _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_BUDGET")
                editable: true; onValueModified: root.setBoth("WB_UDP_BUDGET", value)
            }
            Label { visible: root.enabled; text: qsTr("Hard payload limit (kbit/s, 0 = automatic)"); color: "white"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            SpinBox {
                visible: root.enabled; Layout.fillWidth: true; from: 0; to: 100000; stepSize: 100
                value: _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_MAX_KBPS")
                editable: true; onValueModified: root.setBoth("WB_UDP_MAX_KBPS", value)
            }
            Label { visible: root.enabled; text: qsTr("UDP input / output ports"); color: "white" }
            RowLayout {
                visible: root.enabled; Layout.fillWidth: true
                SpinBox { Layout.fillWidth: true; from: 1024; to: 65535; editable: true; value: _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_IN_PORT"); onValueModified: root.setBoth("WB_UDP_IN_PORT", value) }
                SpinBox { Layout.fillWidth: true; from: 1024; to: 65535; editable: true; value: _ohdSystemAirSettingsModel.get_cached_int("WB_UDP_OUT_PORT"); onValueModified: root.setBoth("WB_UDP_OUT_PORT", value) }
            }
        }
    }
}
