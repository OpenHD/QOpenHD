import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

RowLayout {
    property string override_text_left: "TODO"
    property string override_text_right: "TODO"
    property string override_color_right: "#fff"

    Text {
        width: 150
        text: override_text_left
        font.pixelSize: 14
        font.bold: true
        font.family: "AvantGarde-Medium"
        color: "#ffffff"
        smooth: true
    }

    Text {
        text: override_text_right
        font.pixelSize: 14
        font.family: "AvantGarde-Medium"
        color: override_color_right
        smooth: true

    }
}
