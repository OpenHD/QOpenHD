import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {

    Timer {
        id: autopingTimer
        running: false
        interval: 1000
        repeat: true
        onTriggered: {
            _mavlinkTelemetry.ping_all_systems()
        }
    }

    ColumnLayout {
        // 2 Rows
        anchors.left: parent.left
        anchors.leftMargin: 12

        RowLayout {
            id: actions_1
            width: parent.width
            ButtonIconInfo {
                onClicked: {
                    _messageBoxInstance.set_text_and_show("Ping all systems, aka check if they respond to the mavlink ping command. Both OpenHD air and ground support this command, FC only ardupilot / px4 support this command. The command is lossy, aka you might need to use it more than once to get a response from all systems. No response after >10 tries is a hint that one of your systems is not functioning properly.")
                }
            }
            Button {
                text: "Ping all systems"
                onClicked: _mavlinkTelemetry.ping_all_systems()
            }
            Switch {
                text: "Auto-ping"
                onCheckedChanged: {
                    if (checked) {
                        autopingTimer.start()
                    } else {
                        autopingTimer.stop()
                    }
                }
            }
            // Padding
            Item {
                // Padding
            }
        }
    }
}
