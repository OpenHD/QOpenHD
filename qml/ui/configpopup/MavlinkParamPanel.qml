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
    // figure out if the system is alive
    property var m_instanceCheckIsAvlie: _ohdSystemGround

    property string m_name: "undefined"


    Component {
        id: delegateMavlinkSettingsValue
        Item {
            id: item
            width: listView.width
            //width: ListView.view.width
            height: 64
            Row {
                //anchors.fill: parent
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
        enabled: m_instanceCheckIsAvlie.is_alive
        onClicked: {
            parameterEditor.visible=false
            var result=m_instanceMavlinkSettingsModel.try_fetch_all_parameters()
            if(!result){
                 _messageBoxInstance.set_text_and_show("Fetch all failed, please try again")
            }
        }
    }
    Button {
        height: 48
        anchors.top: parent.top
        anchors.left: fetchAllButtonId.right
        anchors.leftMargin: 20
        id: fetchAllButtonInfoId
        text:"INFO"
        Material.background:Material.LightBlue
        onClicked: {
            var text="Refresh your complete parameter set by fetching it from the openhd air/ground unit. Might need a couple of tries"
            _messageBoxInstance.set_text_and_show(text)
        }
    }
    /*Button {
        height: 48
        anchors.top: fetchAllButtonId.top
        anchors.left: fetchAllButtonId.right
        id: infoButton
        text:"Info"
        enabled: true
        onClicked: {

        }
    }*/

    // Left part: multiple colums of param value
    Rectangle{
        id: scrollViewRectangle
        width: parent.width - paramEditorWidth
        height: parent.height-64
        anchors.top: fetchAllButtonId.bottom
        anchors.bottom: parent.bottom

        ScrollView{
            //height: parent.height
            anchors.fill: parent

            contentWidth: availableWidth

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            // allow dragging without using the vertical scroll bar
            ScrollBar.vertical.interactive: true

            ListView {
                id: listView
                //top: fetchAllButtonId.bottom
                //width: parent.width
                model: m_instanceMavlinkSettingsModel
                delegate: delegateMavlinkSettingsValue
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
