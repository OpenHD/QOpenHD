import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Uses the c++ logmessagemodel under app/logging/logmessagesmodel
Rectangle{
    id: main_item
    width: parent.width
    height: parent.height
    //color: Qt.rgba(0.2, 0.2, 0.2, 1.0)
    color: "#eaeaea"
    //color: "transparent"

    // Overwritten in implementation
    property var m_log_model : _logQOpenHD

    ScrollView{
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        contentHeight: baseLogMessagesView.height
        contentWidth: baseLogMessagesView.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true

        ListView {
            id: baseLogMessagesView
            width: main_item.width
            //height: parent.height
            model: m_log_model

            delegate:
                Rectangle {
                //color: Qt.rgba(0.2, 0.2, 0.2, 1.0)
                //color: "#808080"
                //opacity: 0.3
                //color: "#eaeaea"
                //color: "#FF0000"
                //color: "#D0A197"
                //color: "#808080"
                color: "white"
                radius: 10

                height: 28
                width: baseLogMessagesView.width //parent.width for some reason we cannot just use parent.width here

                Text {
                    id: tagViewFC
                    text: model.tag
                    color: model.severity_color
                    anchors { left:parent.left }
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                    opacity: 1.0
                }
                Text {
                    text: model.message
                    anchors { left:tagViewFC.right; verticalCenter: tagViewFC.verticalCenter; leftMargin: 5 }
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                    opacity: 1.0
                }
            }
        }
    }
}
