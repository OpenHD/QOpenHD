import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle{
    width: parent.width
    height: parent.height
    ColumnLayout{
        anchors.fill: parent
        spacing: 6
        Text{
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: 50
            //width:parent.width
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignTop
            text: "When running QOpenHD on an external device (e.g. android phone)\n"+
                  "you have to use one of the given choices to connect the device to the OpenHD ground station"
        }
        Text{
            Layout.preferredHeight: 50
            text: "You are already connected to your ground station - nothing to do."
            color: "#706F1D" // dark green
            visible: m_is_connected_gnd
        }
        Text{
            Layout.preferredHeight: 50
            text: "Looks like you are not connected to your ground station - please use one of the given choices to connect."
            color: "red"
            visible: !m_is_connected_gnd
        }
        Item{
            Layout.fillHeight: true
            // filler
        }
    }
}
