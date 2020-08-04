import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13


Item {
    anchors.fill: parent

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width / 2
        height: parent.height / 2
        color: "lightgray"

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: 3
            height: parent.height
            color: "black"
        }

        Text {
            id: smartSyncIcon
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 12
            text: "\uf021"
            font.family: "Font Awesome 5 Free"
            height: 64
            width: 64
            font.pixelSize: 42
            font.bold: true
            color: "white"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Glow {
            anchors.fill: smartSyncIcon
            radius: 2
            samples: 17
            color: "black"
            source: smartSyncIcon
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: smartSyncIcon.right
            anchors.leftMargin: 12
            text: qsTr("SmartSync")
            height: 64
            font.pixelSize: 22
            font.bold: true
            color: "#515151"
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: statusIdentifier
            anchors.top: smartSyncIcon.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 88
            text: qsTr("Status: ")
            height: 20
            font.pixelSize: 14
            font.bold: true
            color: "#515151"
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            anchors.top: statusIdentifier.top
            anchors.topMargin: 0
            anchors.left: statusIdentifier.right
            anchors.leftMargin: 6
            text: SmartSync.message
            height: 20
            font.pixelSize: 14
            font.bold: false
            color: "black"
            verticalAlignment: Text.AlignVCenter
        }

        ProgressBar {
            id: progressBar

            height: 24


            indeterminate: SmartSync.state === 0

            anchors.top: statusIdentifier.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 12

            anchors.right: parent.right
            anchors.rightMargin: 14

            from: 0
            to: 100


            value: SmartSync.progress
        }
    }


    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width / 2
        height: parent.height / 2
        color: "lightgray"
        Image {
            id: openhdIcon
            source: "qrc:///ic.png"
            width: 64
            height: 64
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 24
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: openhdIcon.right
            anchors.leftMargin: 12
            text: "Open.HD"
            height: 64
            font.pixelSize: 22
            font.bold: true
            color: "#515151"
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: groundVersionIdentifier
            anchors.top: openhdIcon.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 24
            text: qsTr("Ground version: ")
            height: 20
            font.pixelSize: 14
            font.bold: true
            color: "#515151"
        }

        Text {
            anchors.top: groundVersionIdentifier.top
            anchors.topMargin: 0
            anchors.left: groundVersionIdentifier.right
            anchors.leftMargin: 6
            text: GroundStatusMicroservice.openHDVersion
            height: 20
            font.pixelSize: 14
            font.bold: false
            color: "black"
        }

        Text {
            id: airVersionIdentifier
            anchors.top: groundVersionIdentifier.bottom
            anchors.topMargin: 6
            anchors.right: groundVersionIdentifier.right
            text: qsTr("Air version: ")
            height: 20
            font.pixelSize: 14
            font.bold: true
            color: "#515151"
        }

        Text {
            anchors.top: airVersionIdentifier.top
            anchors.topMargin: 0
            anchors.left: airVersionIdentifier.right
            anchors.leftMargin: 6
            text: AirStatusMicroservice.openHDVersion
            height: 20
            font.pixelSize: 14
            font.bold: false
            color: "black"
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom:  parent.bottom
        width: parent.width
        height: parent.height / 2
        color: "#2a2a2a"

        StatusView {
            anchors.fill: parent
            clip: true
        }
    }
}
