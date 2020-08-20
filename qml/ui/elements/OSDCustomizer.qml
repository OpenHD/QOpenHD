
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0


Rectangle {
    id: osdCustomizer

    width: 196
    height: 240

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

                ColorDialog {
                    id: colorDialogShape
                    title: qsTr("Choose a color")
                    onAccepted: {
                        settings.color_shape = colorDialogShape.color
                        colorDialogShape.close()
                    }
                    onRejected: {
                        colorDialogShape.close()
                    }
                    Component.onCompleted: visible = false
                }

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
                    onClicked: colorDialogShape.open()

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

                ColorDialog {
                    id: colorDialogGlow
                    title: qsTr("Choose a color")
                    onAccepted: {
                        settings.color_glow = colorDialogGlow.color
                        colorDialogGlow.close()
                    }
                    onRejected: {
                        colorDialogGlow.close()
                    }
                    Component.onCompleted: visible = false
                }

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
                    onClicked: colorDialogGlow.open()

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

                ColorDialog {
                    id: colorDialogText
                    title: qsTr("Choose a color")
                    onAccepted: {
                        settings.color_text = colorDialogText.color
                        colorDialogText.close()
                    }
                    onRejected: {
                        colorDialogText.close()
                    }
                    Component.onCompleted: visible = false
                }

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
                    onClicked: colorDialogText.open()

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
        }
    }
}
