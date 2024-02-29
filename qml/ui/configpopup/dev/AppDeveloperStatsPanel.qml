import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12


import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Dirty here i place stuff that can be usefully during development
Rectangle {
    id: elementAppDeveloperStats
    width: parent.width
    height: parent.height

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    function yes_or_no_as_string(yes){
        if(yes) return "Y"
        return "N"
    }

    function get_features_string(){
        var ret = ""
        ret += "AVCODEC:" + yes_or_no_as_string(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC) + ", "
        ret += "MMAL:" + yes_or_no_as_string(QOPENHD_HAVE_MMAL) + ", "
        ret += "GSTREAMER_QMLGLSINK:" + yes_or_no_as_string(QOPENHD_ENABLE_GSTREAMER_QMLGLSINK) + ", "
        return ret;
    }
    TabBar {
        // This screen doesn't tab, but we use the tab bar element for a consistent style
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("Developer Menu")
        }
    }
    ScrollView{
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 5
        contentHeight: main_column_layout.height
        contentWidth: main_column_layout.width
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true

        Column {
            id: main_column_layout
            width: parent.width
            spacing: 6
            Text{
                height: 23
                text: qsTr("QOpenHD version: " + _qopenhd.version_string + " for " + Qt.platform.os)
            }
            Text {
                height: 23
                text: qsTr("FEATURES:  " + get_features_string())
            }
            Text {
                height: 23
                text: qsTr("Resolution: " +" Screen "+ _qrenderstats.screen_width_height_str+" ADJ:"+_qrenderstats.display_width_height_str + " Window: "+ _qrenderstats.window_width+"x"+_qrenderstats.window_height)
            }
            Text {
                height: 23
                text: qsTr("Art Horizon mavlink update rate:" + _fcMavlinkSystem.curr_update_rate_mavlink_message_attitude + " Hz")
            }
            Text {
                height: 23
                text: qsTr("Tele in" + _mavlinkTelemetry.telemetry_pps_in + " pps")
            }
            Switch{
                text: "SHOW DEV OVERLAY"
                checked: settings.show_dev_stats_overlay
                onCheckedChanged: {
                    settings.show_dev_stats_overlay=checked
                }
            }
            Button {
                text: "Restart local OHD service"
                onClicked: {
                    _qopenhd.restart_local_oenhd_service()
                }
            }
            Button {
                id: local_ip_button
                text: "Show local IP"
                onClicked: {
                    var text = _qopenhd.show_local_ip()
                    local_ip_button.text = text
                }
            }
            Button {
                text: "Set Tele rates"
                onClicked: {
                    _mavlinkTelemetry.re_apply_rates()
                }
            }
            Row {
                spacing: 5
                visible: _qopenhd.is_linux()
                Button {
                    text: "Start openhd"
                    onClicked: {
                        _qopenhd.sysctl_openhd(0);
                    }
                }
                Button {
                    text: "Stop openhd"
                    onClicked: {
                        _qopenhd.sysctl_openhd(1);
                    }
                }
                Button {
                    text: "Enable openhd"
                    onClicked: {
                        _qopenhd.sysctl_openhd(2);
                    }
                }
                Button {
                    text: "Disable openhd"
                    onClicked: {
                        _qopenhd.sysctl_openhd(3);
                    }
                }
            }
            Row {
                spacing: 5
                Button {
                    font.capitalization: Font.MixedCase
                    text: qsTr("Restart QOpenHD")
                    onPressed: {
                        qopenhdservicedialoque.open_dialoque(0)
                    }
                }
                Button {
                    font.capitalization: Font.MixedCase
                    text: qsTr("Cancel QOpenHD")
                    onPressed: {
                        qopenhdservicedialoque.open_dialoque(1)
                    }
                }
            }
        }
    }

    QOpenHDServiceDialoque{
        id: qopenhdservicedialoque
    }
}
