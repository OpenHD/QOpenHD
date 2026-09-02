import QtQuick 2.12

// Compact, theme-neutral HUD notification. Visibility and message queue timing
// continue to be owned by QOpenHD in C++.
Item {
    id: toast
    z: 22

    property string m_text: qsTr("FILL ME TEXT")

    width: parent.width
    height: parent.height

    Rectangle {
        id: surface
        width: Math.min(430, Math.max(240, toast.width - 32))
        height: Math.min(104, Math.max(48, message.implicitHeight + 20))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(22, parent.height * 0.075)
        radius: 12
        color: "#f2172738"
        border.width: 1
        border.color: "#526b83"
        opacity: toast.visible ? 1 : 0
        scale: toast.visible ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 18
            radius: 2
            color: "#3b9cff"
        }

        Rectangle {
            id: iconBackground
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 8
            color: "#263b9cff"

            Text {
                anchors.centerIn: parent
                text: "\uf05a"
                color: "#67b2ff"
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 14
            }
        }

        Text {
            id: message
            anchors.left: iconBackground.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: toast.m_text
            color: "#f5f8fc"
            font.pixelSize: 13
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
