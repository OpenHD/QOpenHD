import QtQuick 2.12

Item {
    id: root
    width: 44; height: 44
    property real heading: 0
    property string hitObjectName: "planeFollowTarget"
    signal activated()
    Canvas {
        width: 36; height: 36
        anchors.centerIn: parent
        rotation: root.heading
            onPaint: {
                var c = getContext("2d")
                c.clearRect(0, 0, 36, 36)
                c.beginPath()
                c.moveTo(18, 2); c.lineTo(21, 15); c.lineTo(33, 23)
                c.lineTo(33, 26); c.lineTo(21, 22); c.lineTo(21, 29)
                c.lineTo(25, 32); c.lineTo(25, 34); c.lineTo(18, 32)
                c.lineTo(11, 34); c.lineTo(11, 32); c.lineTo(15, 29)
                c.lineTo(15, 22); c.lineTo(3, 26); c.lineTo(3, 23)
                c.lineTo(15, 15); c.closePath()
                c.fillStyle = "#eff6ff"; c.fill()
                c.strokeStyle = "#102235"; c.lineWidth = 1.5; c.stroke()
            }
    }
    MouseArea {
        objectName: root.hitObjectName
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
