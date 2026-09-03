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
    color: m_modern_style ? settings_form.panelBackground : "#333c4c"
    radius: m_modern_style ? 14 : 0
    border.color: m_modern_style ? settings_form.lineColor : "transparent"
    border.width: m_modern_style ? 1 : 0

    // These should be overridden by implementation !
    property string m_title: qsTr("FILL ME")
    property bool m_modern_style: true
    property alias closeButtonControl: closeButton
    signal closeButtonClicked();

    property int dirty_top_margin_for_implementation: m_modern_style ? 48 : 40

    // The Header / title
    // (Description and close button)
    Item {
        id: header_item
        width: parent.width
        height: m_modern_style ? 48 : rowHeight*2 / 3;

        Rectangle{
            anchors.fill: parent
            color: m_modern_style ? "transparent" : "#8cbfd7f3"
        }

        Rectangle{
            width: parent.width
            height: 2
            color: m_modern_style ? settings_form.lineColor : "black"
            anchors.bottom: parent.bottom
        }

        Text{
            text: m_title
            font.weight: Font.Bold
            anchors.fill: parent
            anchors.leftMargin: m_modern_style ? 15 : 0
            anchors.rightMargin: m_modern_style ? 50 : 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: m_modern_style ? Text.AlignLeft : Text.AlignHCenter
            color: m_modern_style ? settings_form.primaryText : "black"
            font.pixelSize: m_modern_style ? 13 : 13
        }
        Button {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: m_modern_style ? 9 : 2
            id:closeButton
            text: qsTr("X")
            height: m_modern_style ? 30 : parent.height
            width: m_modern_style ? 30 : parent.height
            font.pixelSize: m_modern_style ? 11 : 13
            background: Rectangle {
                radius: m_modern_style ? 9 : 0
                color: m_modern_style
                       ? (closeButton.hovered ? settings_form.panelBackgroundRaised : "transparent")
                       : (closeButton.hovered ? "darkgrey" : "lightgrey")
                border.color: m_modern_style
                              ? (closeButton.activeFocus ? settings_form.accentColor : settings_form.lineColor)
                              : "transparent"
                border.width: m_modern_style ? (closeButton.activeFocus ? 2 : 1) : 0
            }
            contentItem: Text {
                text: closeButton.text
                color: m_modern_style ? settings_form.secondaryText : "black"
                font: closeButton.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                closeButtonClicked();
            }
        }
    }
}

