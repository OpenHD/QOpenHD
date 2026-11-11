/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0

import "colorwheel"
import "../configpopup"


Card {
    id: colorPicker
    cardNameColor: "black"
    hasHeader: false
    hasHeaderImage: false
    visible: false
    cardBackgroundColor: "#cc000000"
    cardFooterColor: "#b0000000"
    borderColor: "#444444"

    Material.theme: Material.Dark

    property bool stateVisible: visible


    enum ColorType {
        ShapeColor,
        GlowColor,
        TextColor,
        CustomColor
    }

    property int currentColorType: ColorPicker.ColorType.ShapeColor

    property var customTarget: null
    property string customProperty: ""
    property color customPreviousColor

    property alias color: colorWheel.color
    property alias showAlpha: colorWheel.showAlpha

    signal cancelled
    signal colorChange

    function openCustomColor(target, propertyName) {
        customTarget = null
        customProperty = propertyName
        customPreviousColor = target[propertyName]
        currentColorType = ColorPicker.ColorType.CustomColor
        colorWheel.setSelectedColor(customPreviousColor)
        customTarget = target
        visible = true
    }


    // used for saving the last color before the user opens the color picker, so they
    // can click cancel and get the old one back without having to figure out how to recreate it
    property color previousColor

    onCancelled: {
        if (colorPicker.currentColorType == ColorPicker.ColorType.ShapeColor) {
            settings.color_shape = colorPicker.previousColor
        }
        if (colorPicker.currentColorType == ColorPicker.ColorType.GlowColor) {
            settings.color_glow = colorPicker.previousColor
        }
        if (colorPicker.currentColorType == ColorPicker.ColorType.TextColor) {
            settings.color_text = colorPicker.previousColor
        }
        if (colorPicker.currentColorType == ColorPicker.ColorType.CustomColor) {
            if (colorPicker.customTarget && colorPicker.customProperty !== "") {
                colorPicker.customTarget[colorPicker.customProperty] = colorPicker.customPreviousColor
            }
        }
    }

    Connections {
        target: colorWheel

        function onColorChanged() {
            if (colorPicker.currentColorType == ColorPicker.ColorType.ShapeColor) {
                settings.color_shape = colorPicker.color
            }
            if (colorPicker.currentColorType == ColorPicker.ColorType.GlowColor) {
                settings.color_glow = colorPicker.color
            }
            if (colorPicker.currentColorType == ColorPicker.ColorType.TextColor) {
                settings.color_text = colorPicker.color
            }
            if (colorPicker.currentColorType == ColorPicker.ColorType.CustomColor) {
                if (colorPicker.customTarget && colorPicker.customProperty !== "") {
                    colorPicker.customTarget[colorPicker.customProperty] = colorPicker.color
                }
            }
        }

    }

    states: [
        State {
            when: colorPicker.stateVisible;
            PropertyChanges {
                target: colorPicker
                opacity: 1.0
            }
        },
        State {
            when: !colorPicker.stateVisible;
            PropertyChanges {
                target: colorPicker
                opacity: 0.0
            }
        }
    ]
    transitions: [ Transition { NumberAnimation { property: "opacity"; duration: 250}} ]

    cardBody: ColorWheel {
        id: colorWheel
        anchors.left: parent.left
        anchors.leftMargin: 24

        anchors.right: parent.right
        anchors.rightMargin: 24
        height: 192
    }

    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        AdvancedActionButton {
            width: 96
            text: qsTr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            onClicked: {
                colorPicker.visible = false
                colorPicker.cancelled()
            }
        }

        AdvancedActionButton {
            width: 140
            objectName: "colorPickerSelect"
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            primary: true

            text:  qsTr("Select")

            onClicked: {
                colorPicker.visible = false
            }
        }
    }
}
