import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12


Item {
    id: slideSwitch
    property string switchText
    property string switchTextColor

    property bool triggered: false
    property alias dropArea: dropArea

    property string buttonText
    property string buttonTextColor

    Text {
        id: switchTextArea
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        font.pixelSize: 14

        horizontalAlignment: Text.AlignHCenter
        color: switchTextColor
        text: switchText
        verticalAlignment: Text.AlignVCenter
        z: 1.0
    }

    Glow {
        anchors.fill: switchTextArea
        radius: 2
        samples: 17
        color: "white"
        source: switchTextArea
    }

    BusyIndicator {
        id: busyIndicator
        width: 42
        height: parent.height

        z: 1.0

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 12
        running: slideSwitch.triggered
        visible: slideSwitch.triggered

        contentItem: Item {
            implicitWidth: parent.width
            implicitHeight: parent.height

            Item {
                id: item
                x: 0
                y: 0
                width: parent.width
                height: parent.height
                opacity: busyIndicator.running ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 250
                    }
                }

                RotationAnimator {
                    target: item
                    running: busyIndicator.visible && busyIndicator.running
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 1250
                }

                Repeater {
                    id: repeater
                    model: 6

                    Rectangle {
                        x: item.width / 2 - width / 2
                        y: item.height / 2 - height / 2
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: "white"
                        transform: [
                            Translate {
                                y: -Math.min(item.width, item.height) * 0.5 + 5
                            },
                            Rotation {
                                angle: index / repeater.count * 360
                                origin.x: 5
                                origin.y: 5
                            }
                        ]
                    }
                }
            }
        }
    }


    MouseArea {
        id: mouseArea
        drag.target: slider
        drag.axis: Drag.XAxis
        drag.minimumX: 12
        drag.maximumX: slideSwitch.width - mouseArea.width - 12

        width: 64
        height: parent.height
        z: 1.1

        onReleased: {
            slider.returning = true;
        }

        DropShadow {
            anchors.fill: slider
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8.0
            samples: 17
            color: "#60000000"
            source: slider
            visible: !slideSwitch.triggered
        }

        Rectangle {
            id: slider
            x: 12
            color: "white"
            width: 64
            height: parent.height

            radius: 12
            z: 1.1
            property bool returning: false
            visible: !slideSwitch.triggered

            Drag.active: mouseArea.drag.active
            Drag.hotSpot.x: 32
            Drag.hotSpot.y: 32

            Text {
                text: buttonText
                anchors.fill: parent
                color: buttonTextColor
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 20
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                visible: !slideSwitch.triggered
            }

            NumberAnimation {
                running: slider.returning
                target: slider;
                property: "x";
                to: 12;
                duration: 300;
                easing.type: Easing.InOutSine
                onFinished: slider.returning = false
            }
        }
    }



    DropArea {
        id: dropArea
        z: 1.0
        width: 48

        anchors.right: parent.right
        anchors.rightMargin: 0

        anchors.top: parent.top
        anchors.topMargin: 0

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
