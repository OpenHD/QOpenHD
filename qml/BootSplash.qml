import QtQuick 2.12

Rectangle {
    id: splash
    color: "black"
    property bool failed: false

    Image {
        id: logo
        width: Math.min(splash.width, splash.height) * 0.24
        height: width
        anchors.centerIn: parent
        source: "qrc:/round.png"
        fillMode: Image.PreserveAspectFit
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: logo.y + logo.height + 24
        spacing: 10
        Repeater {
            model: 3
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: "#00aeef"
                opacity: 0.25
                SequentialAnimation on opacity {
                    running: splash.visible && !splash.failed
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 140 }
                    OpacityAnimator { to: 1; duration: 280 }
                    OpacityAnimator { to: 0.25; duration: 280 }
                    PauseAnimation { duration: (2 - index) * 140 }
                }
            }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: logo.y + logo.height + 60
        visible: splash.failed
        text: qsTr("Unable to load the flight display")
        color: "white"
        font.pixelSize: 18
    }
}
