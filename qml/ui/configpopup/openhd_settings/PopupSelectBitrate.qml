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

PopupBigGeneric{

    m_title: "Bitrate Selector"
    onCloseButtonClicked: {
        close();
    }


    function open(){
        visible=true
        enabled=true
    }
    function close(){
        visible=false;
        enabled=false;
    }


}
