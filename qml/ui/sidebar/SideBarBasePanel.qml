import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"


Rectangle {
    width: secondaryUiWidth
    height: secondaryUiHeight
    color: secondaryUiColor
    opacity: secondaryUiOpacity

    property string override_title: "OVERRIDE ME"

    Rectangle {
        id: header
        width: secondaryUiWidth
        height: secondaryUiHeight/8
        color: highlightColor
        opacity: 1.0
        Text {
            anchors.centerIn: parent
            text: override_title
            font.pixelSize: 21
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
    }
}
