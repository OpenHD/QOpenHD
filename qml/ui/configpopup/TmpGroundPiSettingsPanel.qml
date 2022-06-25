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
                    text: model.unique_id
                    font.bold: true
                }
                Label {
                    text: "Curr:"+model.value
                }
                Button {
                    text: "GET"
                }
                TextInput {
                    width: 50
                    text: ""+model.value
                    cursorVisible: false
                }
                Button {
                    text: "SET"
                }
            }
        }
    }

    ScrollView{
        anchors.fill: parent

        ListView {
            width: parent.width
            model: _airPiSettingsModel
            delegate: delegateAirPiSettingsValue
        }
    }
}
