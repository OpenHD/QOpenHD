import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel {
    override_title: "Status"

    property int status_top_padding: 8

    Rectangle {
        color: "#171d25"
        anchors.top: parent.top
        anchors.topMargin: status_top_padding
        height: secondaryUiHeight - headerHeight - status_top_padding
        width: secondaryUiWidth

        ColumnLayout {
            spacing: 10
            anchors.fill: parent
            anchors.margins: 12

            InfoElement2 {
                override_text_left: qsTr("Connection:")
                override_color_right: {
                    if (_ohdSystemAir.is_alive || _ohdSystemGround.is_alive) {
                        return _ohdSystemAir.is_alive && _ohdSystemGround.is_alive ? "#20b383" : "#df4c7c";
                    }
                    return "#df4c7c";
                }
                override_text_right: {
                    if (_ohdSystemAir.is_alive || _ohdSystemGround.is_alive) {
                        return _ohdSystemAir.is_alive && _ohdSystemGround.is_alive
                            ? qsTr("Connected")
                            : (_ohdSystemAir.is_alive ? qsTr("AIR only") : qsTr("GND only"));
                    }
                    return qsTr("Not connected");
                }
            }            InfoElement2 {
                override_text_left: qsTr("QOpenHD Version:")
                override_color_right: "#20b383"
                override_text_right: {
                    return _qopenhd.version_string;
                }
            }
            InfoElement2 {
                override_text_left: qsTr("OpenHD Version:")
                override_color_right: {
                    if (_ohdSystemGround.openhd_version !== "N/A") {
                        return _ohdSystemGround.openhd_version !== _ohdSystemAir.openhd_version ? "#df4c7c" : "#20b383";
                    }
                    return "#df4c7c";
                }
                override_text_right: {
                    if (_ohdSystemGround.openhd_version !== "N/A") {
                        return _ohdSystemGround.openhd_version !== _ohdSystemAir.openhd_version
                            ? qsTr("Version mismatch")
                            : _ohdSystemGround.openhd_version;
                    }
                    return qsTr("Not connected");
                }
            }
            InfoElement2 {
                override_text_left: qsTr("Chipset GND:")
                override_color_right: _ohdSystemGround.is_alive ? "#20b383" : "#df4c7c"
                override_text_right: {
                    if (_ohdSystemGround.is_alive) {
                        return _ohdSystemGround.card_type_as_string || qsTr("Unknown");
                    }
                    return qsTr("Not connected");
                }
            }
            InfoElement2 {
                override_text_left: qsTr("Chipset AIR:")
                override_color_right: _ohdSystemAir.is_alive ? "#20b383" : "#df4c7c"
                override_text_right: {
                    if (_ohdSystemAir.is_alive) {
                        return _ohdSystemAir.card_type_as_string || qsTr("Unknown");
                    }
                    return qsTr("Not connected");
                }
            }
            InfoElement2 {
                override_text_left: qsTr("Camera:")
                override_color_right: _ohdSystemAir.is_alive ? "#20b383" : "#df4c7c"
                override_text_right: _ohdSystemAir.is_alive ? _ohdSystemAir.ohd_cam_type : qsTr("Not connected")
            }
            Button {
                Layout.alignment: Qt.AlignHCenter
                id: button
                text: qsTr("Advanced Menu")
                onClicked: {
                    settings_panel.visible = true
                }
            }
        }
    }
}
