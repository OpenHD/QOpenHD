import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    width: 300
    height: 170

    property string m_title: "FILL ME"

    property bool m_is_selected: false

    property string m_displayed_value: "VALUE T"

    property string m_displayed_extra_value: "EXTRA VALUE"

    property bool m_is_enabled: true

    function on_choice_left(){

    }
    function on_choice_right(){

    }

    Rectangle{
        width: parent.width
        height: parent.height
        border.color: "black"
        border.width: 3
        color: "green"
        //  "#8cbfd7f3" : "#00000000"
        //color: m_is_selected ? "green" : "black"
        //opacity: m_is_selected ? 1.0 : 0.5;
    }

    Text {
        id: title_str
        text: qsTr(m_title)
        width: parent.width
        height: parent.height * 1/3;
        anchors.top: parent.top
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: 13
    }

    Item{
        id: middle_element_holder
        width: parent.width
        height: 80
        anchors.top: title_str.bottom
        Rectangle{
            color: "white"
            width: parent.width /2;
            height: parent.height
            border.color: "black"
            border.width: 1
            anchors.centerIn: parent
            Text{
                id: middle_element
                width: parent.width
                height: parent.height
                text: m_displayed_value
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 13
            }
        }
        Button{
            id: button_left
            text: "L"
            anchors.left: parent.left
            height: parent.height
            width: height
            background: Item {
                // no background
            }
            onClicked: on_choice_left()
        }
        Button{
            id: button_right
            text: "R"
            anchors.right: parent.right
            height: parent.height
            width: height
            background: Item {

                // no background
            }
            onClicked: on_choice_right()
        }
    }

    Text{
        width: parent.width
        height: 40
        anchors.top: middle_element_holder.bottom
        text: m_displayed_extra_value
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
    }
    Rectangle{
        width: parent.width
        height: parent.height
        color: "gray"
        opacity: 0.7
        visible: !m_is_enabled
    }

}
