import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12

import "colorwheel"


Card {
    id: colorPicker
    cardNameColor: "black"
    hasHeader: false
    hasHeaderImage: false
    visible: false

    property bool stateVisible: visible


    enum ColorType {
        ShapeColor,
        GlowColor,
        TextColor
    }

    property int currentColorType: ColorPicker.ColorType.ShapeColor

    property alias color: colorWheel.color

    signal cancelled
    signal colorChange


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
        Button {
            width: 96
            height: 48
            text: qsTr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase

            onPressed: {
                colorPicker.visible = false
                colorPicker.cancelled()
            }
        }

        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Red
            highlighted: true

            text:  qsTr("Select")

            onPressed: {
                colorPicker.visible = false
            }
        }
    }
}
