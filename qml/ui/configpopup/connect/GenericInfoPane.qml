import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Pane {
    width: parent.width
    height: parent.height
    //color: "green"

    property string m_info_text: "I SHOULD NEVER APPEAR"

    ScrollView {
        id:mavlinkExtraWBParamPanel
        width: parent.width
        height: parent.height
        contentHeight: mainItem.height
        contentWidth: mainItem.width
        clip: true
        //ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.interactive: true
        ScrollBar.horizontal.interactive: true

        ColumnLayout{
            anchors.fill: parent
            id: mainItem
            spacing: 6

            Text{
                Layout.alignment: Qt.AlignTop
                width:parent.width
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignTop
                text: m_info_text
            }
        }
    }
}
