import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Contains a list of all the settings on the left, and opens up a parameter editor instance on
// the right if the user wants to edit any mavlink settings
Rectangle {
    width: parent.width
    height: parent.height
    property int paramEditorWidth: 300

    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this should be replaced by the proper instance for air or camera
    property var m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
    // figure out if the system is alive
    property var m_instanceCheckIsAvlie: _ohdSystemGround

    property string m_name: "undefined"

    //color: "red"
    //color: "transparent"
    color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : "white"

    // Refetch all button
    Button {
        height: 48
        anchors.top: parent.top
        id: fetchAllButtonId
        text:"ReFetch All "+m_name
        enabled: m_instanceCheckIsAvlie.is_alive
        onClicked: {
            parameterEditor.visible=false
            //var result=m_instanceMavlinkSettingsModel.try_fetch_all_parameters()
            /*var result=m_instanceMavlinkSettingsModel.try_fetch_all_parameters_long_running()
            if(!result){
                _messageBoxInstance.set_text_and_show("Fetch all failed, please try again",5)
            }else{
                 _messageBoxInstance.set_text_and_show("SUCCESS",1)
            }*/
            m_instanceMavlinkSettingsModel.try_refetch_all_parameters()
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
    Switch{
        id: screen_settings_openhd_parameters_transparentSwitch
        anchors.top: parent.top
        anchors.left: fetchAllButtonInfoId.right
        anchors.leftMargin: 20
        checked: settings.screen_settings_openhd_parameters_transparent
        onCheckedChanged: settings.screen_settings_openhd_parameters_transparent = checked
    }
    Button{
        id: bUp
        anchors.top: parent.top
        anchors.left: screen_settings_openhd_parameters_transparentSwitch.right
        anchors.leftMargin: 20
        text:"DOWN"
        onClicked: {
            paramListScrollView.ScrollBar.vertical.position += 0.1
        }
    }
    Button{
        id: bDown
        anchors.top: parent.top
        anchors.left: bUp.right
        anchors.leftMargin: 20
        text:"UP"
        onClicked: {
            paramListScrollView.ScrollBar.vertical.position -= 0.1
        }
    }

    Component {
        id: delegateMavlinkSettingsValue

        Rectangle{
            //color: (index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
            //color: "transparent"
            color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : ((index % 2 == 0) ? "#8cbfd7f3" : "#00000000")
            //color: "green"
            //implicitHeight: elementsRow.implicitHeight
            //implicitWidth: elementsRow.implicitWidth
            //height: 64
            //width: 200
            height: 64
            width: listView.width
            Row {
                id: elementsRow
                //anchors.fill: parent
                spacing: 5
                //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                height: 64
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    //font.pixelSize: 20
                    width:150
                    text: model.unique_id
                    font.bold: true
                    //color: settings.screen_settings_openhd_parameters_transparent ? "green" : "black"
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                Text {
                    width:150
                    //font.pixelSize: 20
                    text: model.extraValue
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    //background: settings.screen_settings_openhd_parameters_transparent ? "white" : "transparent"
                    //styleColor: settings.color_glow
                    //background: "yellow"
                    //opacity: 1.0
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "EDIT"
                    onClicked: {
                        // this initializes and opens up the param editor
                        parameterEditor.setup_for_parameter(model.unique_id,model)
                    }
                    // gray out the button for read-only params
                    enabled: !model.read_only
                }
                // Empty item for padding
                Item{
                    width: 16
                    height: parent.height
                }
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "INFO"
                    Material.background:Material.LightBlue
                    onClicked: {
                        var text = model.shortDescription
                        if(text==="TODO"){
                            text = "This parameter is not documented yet";
                         }
                        if(model.read_only){
                            text ="This parameter is read-only (cannot be edited)\n"+text;
                        }
                        _messageBoxInstance.set_text_and_show(text)
                    }
                }
            }
        }
    }

    // Left part: multiple colums of param value
    Rectangle{
        id: scrollViewRectangle
        width: parent.width
        height: parent.height - fetchAllButtonId.height
        anchors.top: fetchAllButtonId.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        //color: "green"
        //opacity: 0.5
        color: settings.screen_settings_openhd_parameters_transparent ? "transparent" :  "white"

        ScrollView{
            id: paramListScrollView
            width: parent.width
            height: parent.height
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            // Always show the scroll bar (sometimes the interactive might not work) but allow interactive also
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ScrollBar.vertical.interactive: true
            ListView {
                id: listView
                width: parent.width
                model: m_instanceMavlinkSettingsModel
                delegate: delegateMavlinkSettingsValue
            }
        }
    }

    // Right part: the parameter edit element.
    // Drawn over the parameters list if needed
    MavlinkParamEditor{
        id: parameterEditor
        total_width: paramEditorWidth
        instanceMavlinkSettingsModel: m_instanceMavlinkSettingsModel
    }

    /*BusyIndicator{
        width: 48
        height: 48
        anchors.centerIn: parent
        running: _xParamUI.is_busy
        //visible: _xParamUI.is_busy
    }*/

}
