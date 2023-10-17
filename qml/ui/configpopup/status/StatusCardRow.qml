import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Hard-coded layouting:
// 1/3 for left text (For example VERSION)
// 2/3 for value text
// value text can be color coded red,
// in which case it is clickable
// The general idea behind this element is to be green / pretty when everything is okay
// and red if something is wrong (in which case the user should click on it for more info)
Item {
    Layout.minimumWidth: 50
    Layout.minimumHeight: 30
    //
    Layout.preferredWidth: 300
    Layout.preferredHeight: 30


    id: main_item
    property string m_left_text: "LEFT"

    property string m_right_text: "RIFGHT"

    property bool m_has_error: false

    property color m_right_text_color: "green"
    property color m_right_text_color_error: "red"

    property string m_error_text: "NONE"

    // For debugging
    /*Rectangle{
        implicitWidth: main_item.width
        implicitHeight: main_item.height
        color: "blue"
        border.width: 3
        border.color: "black"
    }*/

    Text{
        id: left_part
        width: parent.width/3
        height: parent.height
        anchors.left: parent.left
        anchors.top: parent.top
        text: m_left_text
    }

    Text{
        id: right_part
        width: parent.width/3*2;
        height: parent.height
        anchors.left: left_part.right
        anchors.top: left_part.top
        text: m_right_text
        color: m_has_error ? m_right_text_color_error : m_right_text_color
    }
    MouseArea {
        enabled: m_has_error
        anchors.fill: parent
        onClicked: {
            _messageBoxInstance.set_text_and_show(m_error_text)
        }
    }


}
