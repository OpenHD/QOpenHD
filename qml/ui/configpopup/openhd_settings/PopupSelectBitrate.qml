import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle {
    width: parent.width
    height: parent.height
    anchors.centerIn: parent
    color: "#ADD8E6"
    border.color: "black"
    border.width: 3


    function open(){
        visible=true
        enabled=true
    }
    function close(){
        visible=false;
        enabled=false;
    }

    Column{
        anchors.fill: parent

        BaseHeaderItem2{
            m_text: "Bitrate Selector"
        }
        // 3 Rates can be selected


        Text{
            text: "Primary Camera: XXX"
        }
        Text{
            text: "Secondary Camera: XXX"
        }
        Text{
            text: "Switch primary & Secondary: XX"
        }
        Text{
            text: "Secondary cam bandwidth: XX";
        }

    }

}
