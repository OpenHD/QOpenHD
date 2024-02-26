import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
 

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

import QtCharts 2.15

//
// Template for a big (e.g. almost full screen) item with a header and close button
//
Rectangle{
    id: main_background
    anchors.fill: parent
    anchors.centerIn: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    color: "#333c4c"

    // These should be overridden by implementation !
    property string m_title: "FILL ME"
    signal closeButtonClicked();

    property int dirty_top_margin_for_implementation: 40

    // The Header / title
    // (Description and close button)
    Item {
        id: header_item
        width: parent.width
        height: rowHeight*2 / 3;

        Rectangle{
            anchors.fill: parent
            color: "#8cbfd7f3"
        }

        Rectangle{
            width: parent.width
            height: 2
            color: "black"
            anchors.bottom: parent.bottom
        }

        Text{
            text: qsTr(m_title)
            font.weight: Font.Bold
            font.pixelSize: 13
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        Button {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: 2
            id:closeButton
            text: "X"
            height: parent.height
            width: parent.height
            background: Rectangle {
                Layout.fillHeight: parent
                Layout.fillWidth: parent
                color: closeButton.hovered ? "darkgrey" : "lightgrey"
            }
            onClicked: {
                closeButtonClicked();
            }
        }
    }
}

