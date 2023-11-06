import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"


/*
 * @brief QOpenHD settings (Application-specific settings)
 * !!!! Note that OpenHD-Specific settings should not make it into here. !!!
 * @Stephen: This file should be refactored in a way that isn't so fragile and verbose. The rows are
 * all manually defined and every one of them has a manually vertical offset to position it
 * inside the scroll view.
 */
Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true

    color: "white"

    property int rowHeight: 64
    property int elementHeight: 48

    /*Keys.onPressed: (event)=> {
                        if (event.key == Qt.Key_Return) {
                            console.log("enter was pressed from menu");
                            event.accepted = true;
                        }
                    }*/

    TabBar {
        id: appSettingsBar
        height: 48
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        clip: true
        onActiveFocusChanged: {
            console.log("menu focus changed");
        }

        TabButton {
            text: qsTr("Widgets")
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
            y: 0
            text: qsTr("Vehicle")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }

        TabButton {
            text: qsTr("Screen")
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
            text: qsTr("Dev")
            width: implicitWidth
            height: 48
            font.pixelSize: 13
        }
    }

    StackLayout {
        id: appSettings
        anchors.top: appSettingsBar.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        currentIndex: appSettingsBar.currentIndex

        AppWidgetSettingsView{
            id: appWidgetSettingsView
        }
        AppGeneralSettingsView{
            id: appGeneralSettingsView
        }
        AppVehicleSettingsView{
            id: appVehicleSettingsView
        }
        AppScreenSettingsView{
            id: appScreenSettingsView
        }
        AppVideoSettingsView{
            id: appVideoSettingsView
        }
        AppDevSettingsView{
            id: appManageSettingsView
        }
    }
}
