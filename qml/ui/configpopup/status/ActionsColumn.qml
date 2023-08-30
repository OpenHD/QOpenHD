import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Holds the ping, fetch, ... buttons for this panel
// NOTE : Not the power action buttons
Item{


    ColumnLayout{
        // 2 Rows
        RowLayout{
            id: actions_1
            width: parent.width
            RowLayout{
                ButtonIconInfo{
                    onClicked: {
                        _messageBoxInstance.set_text_and_show("Ping all systems, aka check if they respond to the mavlink ping command. Both OpenHD air and ground support
     this command, FC only ardupilot / px4 support this command. The command is lossy, aka you might need to use it more than once to get a response from all systems.
     No response after >10 tries is a hint that one of your systems is not functioning properly.")
                    }
                }
                Button{
                    text: "Ping all systems"
                    onClicked: _mavlinkTelemetry.ping_all_systems()
                }
            }
            RowLayout{
                ButtonIconInfo{
                    onClicked: {
                        _messageBoxInstance.set_text_and_show("Request openhd air / ground station version. Lossy, might need a couple of tries.")
                    }
                }
                Button{
                    text: "Fetch version"
                    onClicked: _ohdAction.request_openhd_version_async()
                }
            }
        }

        RowLayout {
            width: parent.width

            RowLayout{
                ButtonIconInfo{
                    onClicked: {
                        _messageBoxInstance.set_text_and_show("Stops QOpenHD and disables the autostart service until the next reboot. Can be used to get into terminal on rpi.")
                    }
                }
                Button{
                    //font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true

                    text: qsTr("DEV! Cancel QOpenHD")

                    onPressed: {
                        // disables the service (such that qopenhd doesn't get restarted), then quits qopenhd
                        // NOTE: only works on images where the QT auto restart service is active
                        _qopenhd.disable_service_and_quit()
                    }
                }
            }
            RowLayout{
                ButtonIconInfo{
                    onClicked: {
                        _messageBoxInstance.set_text_and_show("Stops QOpenHD and lets the autostart service restart it (RPI)")
                    }
                }
                Button {
                    //font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Orange
                    highlighted: true

                    text: qsTr("DEV! Restart QOpenHD")

                    onPressed: {
                          // Will be restarted by the service
                         _qopenhd.quit_qopenhd()
                    }
                }

            }
        }
    }
}
