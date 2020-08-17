import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

Item {
    property alias save: save
    property alias showSavedCheckmark: savedCheckmark.visible
    property bool isPreset: groundPiSettings.currentIndex == 0

    Layout.fillHeight: true
    Layout.fillWidth: true

    TabBar {
        id: groundPiSettingsBar
        height: 48
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        clip: true

        TabButton {
            y: 0
            text: qsTr("Presets")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
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

        GroundPiSettingsPresetView {
            id: presetTab
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        GroundPiSettingsListView {
            id: generalTab
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: generalSettingsModel
        }

        GroundPiSettingsListView {
            id: radioTab
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: radioSettingsModel
        }

        GroundPiSettingsListView {
            id: videoTab
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: videoSettingsModel
        }

        GroundPiSettingsListView {
            id: rcTab
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: rcSettingsModel
        }

        GroundPiSettingsListView {
            id: hotspotTab
            model: hotspotSettingsModel
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        GroundPiSettingsListView {
            id: smartSyncTab
            model: smartSyncSettingsModel
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        GroundPiSettingsListView {
            id: otherTab
            model: otherSettingsModel
            Layout.fillHeight: true
            Layout.fillWidth: true
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
                text: groundPiSettingsBar.currentIndex == 0 ? qsTr("Apply preset") : qsTr("Save")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                enabled: !openHDSettings.loading && !openHDSettings.saving
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
            running: openHDSettings.loading || openHDSettings.saving
            visible: openHDSettings.loading || openHDSettings.saving
        }

        Item {
            id: savedCheckmark
            visible: false

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: button_row.left
            anchors.rightMargin: 0

            Text {
                id: savedText
                text: qsTr("saved")
                font.pixelSize: 20
                height: parent.height
                anchors.right: savedIcon.left
                anchors.rightMargin: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: savedIcon
                text: "\uf00c"
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 20
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: 0
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
