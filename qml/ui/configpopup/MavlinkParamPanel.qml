import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Contains a list of all the settings on the left, and opens up a parameter editor instance on
// the right if the user wants to edit any mavlink settings
Rectangle {

    Layout.fillHeight: true
    Layout.fillWidth: true


    property int paramEditorWidth: 300

    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this should be replaced by the proper instance for air or camera
    property var m_instanceMavlinkSettingsModel: _groundPiSettingsModel

    property string m_name: "undefined"


    Component {
        id: delegateCamera0SettingsValue
        Item {
            id: item
            width: listView.width
            //width: ListView.view.width
            height: 64
            Row {
                anchors.fill: parent
                spacing: 5

                Label {
                    width:150
                    text: model.unique_id
                    font.bold: true
                }
                Label {
                    width:100
                    //text: "Val: "+model.value
                    //text: "Val: "+model.extraValue
                    text: model.extraValue
                    font.bold: true
                }
                Button {
                    text: "EDIT"
                    onClicked: {
                        // this initializes and opens up the param editor
                        parameterEditor.setup_for_parameter(model.unique_id,model)
                    }
                    // gray out the button for read-only params
                    enabled: !model.read_only
                }
            }
        }
    }


    // Refetch all button
    Button {
        height: 48
        anchors.top: parent.top
        id: fetchAllButtonId
        text:"ReFetch All "+m_name
        enabled: _ohdSystemAir.is_alive
        onClicked: {
            parameterEditor.visible=false
            var result=m_instanceMavlinkSettingsModel.try_fetch_all_parameters()
            if(!result){
                 _messageBoxInstance.set_text_and_show("Fetch all failed, please try again")
            }
        }
    }

    // Left part: multiple colums of param value
    Rectangle{
        id: scrollViewRectangle
        width: parent.width - paramEditorWidth
        height: parent.height-64
        anchors.top: fetchAllButtonId.bottom
        anchors.bottom: parent.bottom

        ScrollView{
            anchors.fill: parent
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            ListView {
                id: listView
                //top: fetchAllButtonId.bottom
                width: parent.width
                model: m_instanceMavlinkSettingsModel
                delegate: delegateCamera0SettingsValue
            }
        }
    }

    // Right part: the parameter edit element
    MavlinkParamEditor{
        id: parameterEditor
        total_width: paramEditorWidth
        instanceMavlinkSettingsModel: m_instanceMavlinkSettingsModel
    }



}