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

// Temporary dummy
Rectangle {

    Layout.fillHeight: true
    Layout.fillWidth: true

    //width: parent.width
    //height: 600

    property int rowHeight: 64
    property int elementHeight: 48

    property int paramEditorWidth: 300


    Component {
        id: delegateAirPiSettingsValue
        Item {
            id: item
            width: 200
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
                        parameterEditor.setup_for_parameter(model.unique_id,model)
                    }
                    enabled: !model.read_only
                }
            }
        }
    }


    // Left row: multiple colums of param value
    ColumnLayout {
        width: parent.width - paramEditorWidth
        height:parent.height

        Button {
            width: 100
            height: 48
            id: fetchAllButtonId
            text:"ReFetch All Air"
            enabled: _ohdSystemAir.is_alive
            onClicked: {
                parameterEditor.visible=false
                var result=_airPiSettingsModel.try_fetch_all_parameters()
                if(!result){
                     _messageBoxInstance.set_text_and_show("Fetch all failed, please try again")
                }
            }
        }
        Rectangle{
            width:parent.width
            height: parent.height-64

            ScrollView{
                anchors.fill: parent
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ListView {
                    //top: fetchAllButtonId.bottom
                    width: parent.width
                    model: _airPiSettingsModel
                    delegate: delegateAirPiSettingsValue
                }
            }
        }
    }

    // Right row: the parameter edit element
    ParameterEditor{
        id: parameterEditor
        total_width: 300
        instanceMavlinkSettingsModel: _airPiSettingsModel
    }



}
