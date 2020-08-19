
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0


Popup {
    id: osdCustomizer

    width: 196
    height: 240

    background: Rectangle {
        color: "#ffeaeaea"
    }

    /*
     * This centers the popup on the screen rather than positioning it
     * relative to the parent item
     *
     */
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)


    Item {
        anchors.fill: parent

        Column {
            id: col
            anchors.fill: parent
            spacing: 6

            Item {
                width: parent.width
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
                width: parent.width
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
                width: parent.width
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
                width: parent.width


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
