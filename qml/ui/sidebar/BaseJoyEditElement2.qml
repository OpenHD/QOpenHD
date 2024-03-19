import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

//
// Base for an UI element that has the following properties:
// left / right: Increment / Decrement (model) value (If increment / decrement is available)
// top / bottom : Go to next / previous element
// MIDDLE: Show the current value
//
// It looks like this:
// |--------------------|
// |  TITLE   VALUE   * | -> Selector (can be opened)
// |--------------------|
//
// Joystick navigatable (focus) but also supports touch.
Item{
    id: base_joy_edit_element
    width: 320
    height: 70

    property string m_title: "FILL ME"

    property bool m_is_selected: false

    property string m_displayed_value: "VALUE T"

    property bool m_is_enabled: true

    // Allows the parent to override the text color
    // Right now only used by the change frequency element
    property bool override_show_red_text: false

    // Emitted if the the element is clicked (for non-joystick usage)
    signal base_joy_edit_element_clicked();

    function takeover_control(){
        focus=true;
    }

    Rectangle{
        width: parent.width
        height:parent.height
        border.color: "white"
        border.width: base_joy_edit_element.focus ? 3 : 0;
        color: "#333c4c"
        opacity: base_joy_edit_element.focus ? 1.0 : 0.3;
    }


    Text {
        id: title_str
        text: qsTr(m_title)
        width: parent.width/2
        height: parent.height
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: 18
        anchors.top: parent.top
        color: "white"
    }

    Text{
        id:value_string
        width: parent.width/2
        height: parent.height
        text: m_displayed_value
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: 15
        color: override_show_red_text? "red" :  "white"
        anchors.right: parent.right
    }


    Rectangle{
        width: parent.width
        height: parent.height
        color: "gray"
        opacity: 0.7
        visible: !m_is_enabled
    }

    MouseArea{
        anchors.fill: parent
        onClicked: {
            base_joy_edit_element_clicked()
        }
    }
}
