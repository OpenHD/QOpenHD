import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    id: appWidgetSettingsView
    width: parent.width
    height: parent.height
    contentHeight: widgetColumn.height

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: widgetColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            //SettingBaseElement
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                RowLayout{
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text{
                        Layout.alignment: Qt.AlignLeft
                        //text: "PRESETS\nColor/Font"
                        text: "Presets Color/Font"
                        font.weight: Font.Bold
                        font.pixelSize: 13
                    }
                    Item{ // filler
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Button{
                        text: "GREEN-Norbert"
                        Layout.alignment: Qt.AlignRight
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        onClicked: {
                            settings.color_caution="yellow"
                            settings.color_glow="black"
                            settings.color_shape="#ff14ff00"
                            settings.color_text="#ff05ff00"
                            settings.color_warn="red"
                            settings.font_text="Quicksand"
                        }
                    }
                    Button{
                        text: "RESET"
                        Layout.alignment: Qt.AlignRight
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        onClicked: {
                            settings.color_shape="white"
                            settings.color_text= "white"
                            settings.color_glow= "black"
                            settings.color_warn= "red"
                            settings.color_caution= "yellow"
                            settings.font_text= "Sans Serif"
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Shape Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
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


            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Glow Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
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

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Text Color")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                RoundButton {
                    //text: "Open"

                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
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



            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Text font")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                FontSelect {
                    id: fontSelectBox
                    height: elementHeight
                    width: 320
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                }
            }
        }
    }
}
