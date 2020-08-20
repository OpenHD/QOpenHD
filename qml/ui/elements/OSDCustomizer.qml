
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "colorwheel"

Rectangle {
    id: osdCustomizer

    width: 196
    height: 312

    color: "#ffeaeaea"


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

    Item {
        anchors.fill: parent

        Column {
            id: col
            anchors.fill: parent
            spacing: 6
            rightPadding: 12
            leftPadding: 12
            topPadding: 12

            Item {
                width: parent.width - 24
                height: 48

                Text {
                    text: qsTr("Shape Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
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
                    text: "Font"
                    height: 20
                    color: "black"
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

            Button {
                height: 60
                width: parent.width - 24
                text: qsTr("Done")
                Material.accent: Material.Red
                highlighted: true

                onClicked: osdCustomizer.visible = false
            }
        }
    }
}
