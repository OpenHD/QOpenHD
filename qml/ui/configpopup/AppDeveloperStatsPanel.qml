import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Dirty here i place stuff that one might want to read, but that changes quite often during development
Rectangle {
    id: elementAppDeveloperStats
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: groundAndAirCardsId.bottom
        anchors.left: parent.left
        anchors.margins: 10
        Text{
            height: 24
            text: "QT main thread frame time:"
        }

        Button{
            height: 24
            text: "Dummy1"
            onClicked:{

            }
        }
    }
}
