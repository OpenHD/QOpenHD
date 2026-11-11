import QtQuick 2.12

// QOpenHD owns notification visibility and queue timing.
Item {
    id: toast
    z: 22

    property string m_text: ""
    readonly property int horizontalPadding: 10
    readonly property int verticalPadding: 6

    anchors.fill: parent

    onVisibleChanged: {
        if (visible) appear.restart()
    }

    Rectangle {
        id: surface
        objectName: "toastSurface"
        width: Math.min(360, Math.max(0, toast.width - 24),
                        message.implicitWidth + iconBadge.width + 3 * toast.horizontalPadding)
        height: Math.max(iconBadge.height, message.implicitHeight) + 2 * toast.verticalPadding
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(18, parent.height * 0.075)
        radius: 12
        border.color: "#41596d"
        gradient: Gradient {
            GradientStop { position: 0; color: "#1e3041" }
            GradientStop { position: 1; color: "#152433" }
        }

        NumberAnimation {
            id: appear
            target: surface
            property: "opacity"
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }

        Rectangle {
            id: iconBadge
            anchors.left: parent.left
            anchors.leftMargin: toast.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 7
            color: "#29465e"

            Text {
                anchors.centerIn: parent
                text: "\uf05a"
                color: "#9cdbff"
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 13
            }
        }

        Text {
            id: message
            anchors.left: iconBadge.right
            anchors.leftMargin: toast.horizontalPadding
            anchors.right: parent.right
            anchors.rightMargin: toast.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            text: toast.m_text
            textFormat: Text.PlainText
            color: "#eff7ff"
            font.pixelSize: 13
            font.weight: Font.Medium
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }
    }
}
