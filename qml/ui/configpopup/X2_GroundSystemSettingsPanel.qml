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

    // OpenHD uses mW (milli watt) but the iw dev command run in OpenHD converts that to milli dBm
    // Here I have the (at least theoretical) mapping
    ListModel{
        id: wifiCardTxPowerModel
        ListElement {title: "10mW  (10dBm)"; value: 10}
        ListElement {title: "25mW  (14dBm)"; value: 25}
        ListElement {title: "100mW (20dBm)"; value: 100}
        ListElement {title: "200mW (23dBm)"; value: 200}
        ListElement {title: "500mW (27dBm)"; value: 500}
        ListElement {title: "1000mW(30dBm)"; value: 1000}
    }
    function find_index(model,value){
        for(var i = 0; i < model.count; ++i) if (model.get(i).value===value) return i
        return -1
    }
    // try and update the combobox to the retrieved value(value != index)
    function update_combobox(_combobox,_value){
        var _index=find_index(_combobox.model,_value)
        if(_index >= 0){
            _combobox.currentIndex=_index;
        }
    }

    Component {
        id: delegateGroundPiSettingsValue
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
                    text: "Val: "+model.value
                    font.bold: true
                }
                Button {
                    text: "GET"
                    onClicked: _groundPiSettingsModel.try_fetch_parameter(model.unique_id)
                }
                TextInput {
                    id: xTextInput
                    width:100
                    text: ""+model.value
                    cursorVisible: false
                }
                Button {
                    text: "SET"
                    onClicked: _groundPiSettingsModel.try_update_parameter( model.unique_id,xTextInput.text)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        /*Label{
            width:200
            height:64
            text: "Not found yet"
            visible: _groundPiSettingsModel.rowCount() > 0
        }*/

        Button {
            height: 48
            id: fetchAllButtonId
            text:"FetchAll Ground"
            enabled: _ohdSystemGround.is_alive
            onClicked: {
                var result=_groundPiSettingsModel.try_fetch_all_parameters()
            }
        }
        Rectangle{
            width:parent.width
            height: parent.height-64

            ScrollView{
                anchors.fill: parent

                ListView {
                    //top: fetchAllButtonId.bottom
                    width: parent.width
                    model: _groundPiSettingsModel
                    delegate: delegateGroundPiSettingsValue
                }
            }
        }
    }
}
