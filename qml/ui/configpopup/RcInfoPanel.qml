import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// For joystick debugging
Rectangle {
    id: rcInfoPanel
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Text {
            id: decr
            text: qsTr("Values read from your Joystick RC if enabled. range: 1000-2000, unused:65535")
        }

        Text {
            id: curr0
            text: qsTr("1  (channel): ")+_ohdSystemGround.curr_joystick_pos0
        }
        Text {
            id: curr1
            text: qsTr("2  (channel): ")+_ohdSystemGround.curr_joystick_pos1
        }
        Text {
            id: curr2
            text: qsTr("3  (channel): ")+_ohdSystemGround.curr_joystick_pos2
        }
        Text {
            id: curr3
            text: qsTr("4  (channel): ")+_ohdSystemGround.curr_joystick_pos3
        }
        Text {
            id: curr4
            text: qsTr("5  (channel): ")+_ohdSystemGround.curr_joystick_pos4
        }
        Text {
            id: curr5
            text: qsTr("6  (channel): ")+_ohdSystemGround.curr_joystick_pos5
        }
        Text {
            id: curr6
            text: qsTr("7  (channel): ")+_ohdSystemGround.curr_joystick_pos6
        }
        Text {
            id: curr7
            text: qsTr("8  (channel): ")+_ohdSystemGround.curr_joystick_pos7
        }
        Text {
            id: curr8
            text: qsTr("9  (channel): ")+_ohdSystemGround.curr_joystick_pos8
        }
        Text {
            id: curr9
            text: qsTr("10 (channel): ")+_ohdSystemGround.curr_joystick_pos9
        }
        Text {
            id: curr10
            text: qsTr("11 (channel): ")+_ohdSystemGround.curr_joystick_pos10
        }
        Text {
            id: curr11
            text: qsTr("12 (channel): ")+_ohdSystemGround.curr_joystick_pos11
        }
    }
}
