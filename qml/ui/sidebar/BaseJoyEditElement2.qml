import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

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
    width: secondaryUiWidth
    height: 58
    readonly property bool highlighted: activeFocus || (choiceSelector.visible && choiceSelector.m_parent === base_joy_edit_element)

    property string rowIcon: "\uf013"
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
        forceActiveFocus();
    }

    function ensure_visible_in_panel(){
        var p = parent;
        while(p && !p.ensure_body_item_visible){
            p = p.parent;
        }
        if(p){
            p.ensure_body_item_visible(base_joy_edit_element);
        }
    }

    onActiveFocusChanged: {
        if(activeFocus){
            ensure_visible_in_panel();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        radius: 12
        color: highlighted ? sidebar.highlightFill("#25455f", secondaryUiColor, 0.85) : "transparent"
        border.color: highlighted ? sidebar.highlightColor("#578bab") : "transparent"
        border.width: 1
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.leftMargin: 22
        width: 4
        radius: 2
        color: sidebar.highlightColor("#079eea")
        visible: highlighted
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 1
        color: "#33475a"
        visible: !highlighted
    }

    Text {
        x: 40; anchors.verticalCenter: parent.verticalCenter
        text: rowIcon; font.family: "Font Awesome 5 Free"; font.pixelSize: 23; color: highlighted ? sidebar.highlightColor("#89dbff") : sidebar.textColor("#b3c9db")
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 34; anchors.verticalCenter: parent.verticalCenter
        text: "\uf054"; font.family: "Font Awesome 5 Free"; font.pixelSize: 15; color: sidebar.textColor("#a2b9cc")
    }
    Text {
        id: title_str
        text: qsTr(m_title)
        width: parent.width * 0.57
        height: parent.height
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignLeft
        leftPadding: 94
        elide: Text.ElideRight
        font.pixelSize: 22
        anchors.top: parent.top
        color: sidebar.textColor("white")
    }

    Text{
        id:value_string
        width: parent.width * 0.43
        height: parent.height
        visible: !(m_title === "Pit Mode" && (m_displayed_value === "ON" || m_displayed_value === "OFF"))
        text: qsTr(m_displayed_value)
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignRight
        rightPadding: 65
        font.pixelSize: 20
        color: override_show_red_text ? "#ff9292" : sidebar.textColor("#d7e8f7")
        anchors.right: parent.right
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }


    Rectangle{
        width: parent.width
        height: parent.height
        color: "gray"
        opacity: 0.7
        visible: !m_is_enabled
    }

    Rectangle {
        visible: m_title === "Pit Mode" && (m_displayed_value === "ON" || m_displayed_value === "OFF")
        anchors.right: parent.right; anchors.rightMargin: 65; anchors.verticalCenter: parent.verticalCenter
        width: 56; height: 28; radius: 14
        color: m_displayed_value === "ON" ? sidebar.highlightColor(sidebar.controlColor("#00a8f5", 1.3)) : sidebar.controlColor("#52616c", 0.85)
        Rectangle { x: m_displayed_value === "ON" ? 30 : 2; y: 2; width: 24; height: 24; radius: 12; color: "white" }
    }
    MouseArea{
        anchors.fill: parent
        onClicked: {
            base_joy_edit_element_clicked()
        }
    }
}
