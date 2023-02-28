import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Contains a list of all the settings on the left, and opens up a parameter editor instance on
// the right if the user wants to edit any mavlink settings
Pane {
    width: parent.width
    height: parent.height
    property int paramEditorWidth: 300

    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this should be replaced by the proper instance for air or camera
    property var m_instanceMavlinkSettingsModel: _groundPiSettingsModel
    // figure out if the system is alive
    property var m_instanceCheckIsAvlie: _ohdSystemGround

    property string m_name: "undefined"

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

    Component {
        id: delegateMavlinkSettingsValue
        Rectangle{
            color: (index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
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
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    //font.pixelSize: 20
                    width:150
                    text: model.unique_id
                    font.bold: true
                }
                Label {
                    width:150
                    //font.pixelSize: 20
                    text: model.extraValue
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
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

        ScrollView{
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

}
