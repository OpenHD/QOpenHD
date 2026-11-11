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

import "colorwheel"
import "../configpopup"

Rectangle {
    id: osdCustomizer

    width: parent ? Math.min(280, parent.width - 24) : 280
    height: parent ? Math.min(col.implicitHeight, parent.height - 24) : col.implicitHeight

    color: "#cc000000"

    property bool stateVisible: visible

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

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        Column {
            id: col
            width: osdCustomizer.width
            spacing: 6
            rightPadding: 12
            leftPadding: 12
            topPadding: 12
            bottomPadding: 12

            Item {
                width: parent.width - 24
                height: 48

                Text {
                    text: qsTr("Shape Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    color: settings.color_text
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: 48
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        colorPicker.previousColor = settings.color_shape
                        colorPicker.currentColorType = ColorPicker.ColorType.ShapeColor
                        colorPicker.visible = true
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ((parent.width<parent.height?parent.width:parent.height))-20
                        height: width
                        radius: width*0.5
                        color: settings.color_shape
                    }
                }
            }


            Item {
                width: parent.width - 24
                height: 48

                Text {
                    text: qsTr("Glow Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    color: settings.color_text
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: 48
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        colorPicker.previousColor = settings.color_glow
                        colorPicker.currentColorType = ColorPicker.ColorType.GlowColor
                        colorPicker.visible = true
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ((parent.width<parent.height?parent.width:parent.height))-20
                        height: width
                        radius: width*0.5
                        color: settings.color_glow
                    }
                }
            }

            Item {
                width: parent.width - 24
                height: 48

                Text {
                    text: qsTr("Text Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    color: settings.color_text
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: 48
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        colorPicker.previousColor = settings.color_text
                        colorPicker.currentColorType = ColorPicker.ColorType.TextColor
                        colorPicker.visible = true
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ((parent.width<parent.height?parent.width:parent.height))-20
                        height: width
                        radius: width*0.5
                        color: settings.color_text
                    }
                }
            }

            Item {
                height: 60
                width: parent.width - 24


                Text {
                    id: fontBoxDescription
                    text: qsTr("Font")
                    height: 20
                    color: settings.color_text
                    font.bold: true
                    font.pixelSize: 14
                }

                FontSelect {
                    id: fontBox
                    width: parent.width
                    height: 40
                    anchors.top: fontBoxDescription.bottom
                    anchors.topMargin: 6
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }

            AdvancedActionButton {
                width: parent.width - 24
                text: qsTr("Done")
                primary: true

                onClicked: {
                    osdCustomizer.visible = false
                    if (IsRaspPi) {
                        piSettingsTimer.start();
                    }
                }
            }
        }
    }
}
