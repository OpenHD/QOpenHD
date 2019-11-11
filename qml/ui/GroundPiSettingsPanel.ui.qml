import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

Item {
    property alias save: save
    Layout.fillHeight: true
    Layout.fillWidth: true

    TabBar {
        id: groundPiSettingsBar
        width: parent.width
        height: 48
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top


        TabButton {
            y: 0
            text: qsTr("General")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("Radio")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("Video")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("RC")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("Hotspot")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("Smart Sync")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
        TabButton {
            text: qsTr("Other")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
    }

    StackLayout {
        id: groundPiSettings
        anchors.top: groundPiSettingsBar.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: button_background.top
        anchors.bottomMargin: 0


        currentIndex: groundPiSettingsBar.currentIndex

        GroundPiSettingsListView {
            id: generalTab
            width: parent.width
            height: parent.height
            model: generalSettingsModel
        }

        GroundPiSettingsListView {
            id: radioTab
            width: parent.width
            height: parent.height
            model: radioSettingsModel
        }

        GroundPiSettingsListView {
            id: videoTab
            width: parent.width
            height: parent.height
            model: videoSettingsModel
        }

        GroundPiSettingsListView {
            id: rcTab
            width: parent.width
            height: parent.height
            model: rcSettingsModel
        }

        GroundPiSettingsListView {
            id: hotspotTab
            model: hotspotSettingsModel
            width: parent.width
            height: parent.height
        }

        GroundPiSettingsListView {
            id: smartSyncTab
            model: smartSyncSettingsModel
            width: parent.width
            height: parent.height
        }

        GroundPiSettingsListView {
            id: otherTab
            model: otherSettingsModel
            width: parent.width
            height: parent.height
        }

    }


    Rectangle {
        color: "#4c000000"
        width: parent.width
        height: 1

        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: button_background.top
        anchors.bottomMargin: 0
    }

    Rectangle {
        id: button_background
        width: parent.width
        height: 64
        color: "#fafafa"
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        RowLayout {
            id: button_row
            height: parent.height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            anchors.rightMargin: 24
            anchors.leftMargin: 12

            Item {
                id: spacer9
                Layout.fillWidth: true
                Layout.rowSpan: 1
                Layout.columnSpan: 1
                Layout.preferredHeight: 14
                Layout.preferredWidth: 14
            }

            Button {
                id: save
                text: qsTr("Save")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                enabled: !openHDSettings.busy
                Layout.columnSpan: 1
                font.pixelSize: 13
            }
        }

        BusyIndicator {
            id: busyIndicator
            y: 0
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: button_row.left
            anchors.rightMargin: 0
            running: openHDSettings.busy
            visible: openHDSettings.busy
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
