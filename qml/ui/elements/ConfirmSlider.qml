import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0


ConfirmSliderForm {

    property bool checked: false

    property bool timer_reset: true
    property var timer_time: 5000

    property var slider_height:32
    property var slider_width: 180

    property string text_off:"MANUAL"
    property string text_on: text_off //might be bad practice

    property var msg_id: 0 //the actual msg id sent from the widget

    property var text_color_on: "black"
    property var text_color_off: "white"

    property var color_on: "green"
    property var color_off: "#02324d"

    property var slider_x: 0

    Timer {
        id: selectionResetTimer
        running: false
        interval: timer_time
        repeat: false
        onTriggered: {
            checked = false;
            slider_x= 0;
        }
    }
}

