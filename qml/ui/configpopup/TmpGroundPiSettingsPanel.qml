import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0
import MavlinkTelemetry 1.0

import "../../ui" as Ui
import "../elements"

// Temporary dummy
Item {

    Layout.fillHeight: true
    Layout.fillWidth: true

    //width: parent.width
    //height: 600

    property int rowHeight: 64
    property int elementHeight: 48

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
                    text: "Curr:"+model.value
                }
                Button {
                    text: "GET"
                    onClicked: _airPiSettingsModel.try_fetch_parameter(model.unique_id)
                }
                TextInput {
                    id: xTextInput
                    width:100
                    text: ""+model.value
                    cursorVisible: false
                }
                Button {
                    text: "SET"
                    onClicked: _airPiSettingsModel.try_update_parameter( model.unique_id,xTextInput.text)
                }
            }
        }
    }

    ScrollView{
        anchors.fill: parent

        /*Label{
            width:200
            height:64
            text: "Not found yet"
            visible: _airPiSettingsModel.rowCount() > 0
        }*/

        ListView {
            width: parent.width
            model: _airPiSettingsModel
            delegate: delegateAirPiSettingsValue
        }
    }
}
