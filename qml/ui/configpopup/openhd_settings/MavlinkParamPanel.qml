import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
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

    property int m_progress_perc : m_instanceMavlinkSettingsModel.curr_get_all_progress_perc;

    SimpleProgressBar{
        id: fetch_all_progress
        width: parent.width
        height:  15
        anchors.top: parent.top
        visible: m_progress_perc>=0 && m_progress_perc<=100
        impl_curr_progress_perc: m_progress_perc
        impl_curr_color: "#333c4c"
    }

    RowLayout{
        id: upper_action_row
        width: parent.width
        height: 48
        anchors.top: fetch_all_progress.bottom
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.leftMargin: 12
        ButtonIconWarning{
            onClicked: {
                _messageBoxInstance.set_text_and_show(""+m_name+ " not alive, parameters unavailable. Please check status view.");
            }
            visible: !m_instanceCheckIsAvlie.is_alive
        }
        Button {
            text:"REFETCH "+m_name
            visible: m_instanceCheckIsAvlie.is_alive
            onClicked: {
                parameterEditor.visible=false
                m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
            }
        }
        Button {
            text:"INFO"
            Material.background:Material.LightBlue
            visible: m_instanceCheckIsAvlie.is_alive
            onClicked: {
                var text="Refresh your complete parameter set by fetching it from the openhd air/ground unit."
                _messageBoxInstance.set_text_and_show(text)
            }
        }
        Switch{
            checked: settings.screen_settings_openhd_parameters_transparent
            onCheckedChanged: settings.screen_settings_openhd_parameters_transparent = checked
        }
        Button{
            text:"DOWN"
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position += 0.1
            }
        }
        Button{
            text:"UP"
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position -= 0.1
            }
        }
        Item{ // Filler
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    /*ProgressBar{
        width: parent.width
        height: 50
        from: 0
        to: 100
        value: m_progress_perc
        //visible: m_progress_perc>=0
        anchors.top: fetchAllButtonId.top
    }*/

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
            width: listView.width-12
            Row {
                id: elementsRow
                //anchors.fill: parent
                spacing: 5
                //color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                height: 64
                anchors.left: parent.left
                anchors.leftMargin: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width:160
                    text: model.unique_id
                    font.bold: true
                    font.pixelSize: 14
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                Text {
                    width:160
                    text: model.extraValue
                    font.bold: true
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
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
        height: parent.height - upper_action_row.height
        anchors.top: upper_action_row.bottom
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

    BusyIndicator{
        width: 96
        height: 96
        anchors.centerIn: parent
        running: m_instanceMavlinkSettingsModel.ui_is_busy
        //visible: _xParamUI.is_busy
    }

}
