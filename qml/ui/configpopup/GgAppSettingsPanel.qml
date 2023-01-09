import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


/*
 * @brief QOpenHD settings (Application-specific settings)
 * !!!! Note that OpenHD-Specific settings should not make it into here. !!!
 * @Stephen: This file should be refactored in a way that isn't so fragile and verbose. The rows are
 * all manually defined and every one of them has a manually vertical offset to position it
 * inside the scroll view.
 *
 * THIS FILE IS THE GOGGLE VERSION MENU THEME
 */

//TODO override the tabbar blue line at the bottom of active tab..doesnt move now
//and put on side of tab

Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48

    function openAppMenu(){
        //console.log("openAppMenu reached");
        if(fromSubMenu==false){//first time opening menu
        appSettingsBar.x = 0 //app menu slide in animation
        }
        fromSubMenu=false //reset this
        zeroBtn.forceActiveFocus()
    }

    function closeAppMenu(){
        console.log("closeAppMenu reached");
        appSettingsStack.visible=false //reset and cleanup
        fromSubMenu=false
        appSettingsBtn.forceActiveFocus()
        appSettingsBar.x = -300 //app menu slide away animation
        sidebar.opacity=1 //main menu fade back in
    }

    TabBar {
        id: appSettingsBar

        height: parent.height
        width: 100
        x:-300 //for animation
        anchors.top: parent.top
        background: Rectangle {
            color: "#333c4c"
            border.width: 1
            border.color: "#4c000000"
        }
        clip: false
        onActiveFocusChanged: {
            console.log("ggAppSettingsPanel focus changed");
        }

        Behavior on x { //when settings are opened animation
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutBack
            }
        }

        TabButton {
            id: zeroBtn //numbered based on index number
            text: qsTr("General")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            contentItem: Text {
                text: zeroBtn.text
                color: appSettingsBar.currentIndex == 0 ? "#33aaff" :"#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 0 ? "grey" :
                                                          zeroBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 0
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                zeroBtn.clicked()
                                else if (event.key === Qt.Key_Equal){
                                closeButton.forceActiveFocus()
                                fromSubMenu=true
                                }
                                else if (event.key === Qt.Key_Minus)
                                oneBtn.forceActiveFocus()
                            }
        }

        TabButton {
            id: oneBtn
            text: qsTr("Vehicle")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.top: zeroBtn.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            contentItem: Text {
                text: oneBtn.text
                color: appSettingsBar.currentIndex == 1 ? "#33aaff" : "#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 1 ? "grey" :
                                                          oneBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 1
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                oneBtn.clicked()
                                else if (event.key === Qt.Key_Equal)
                                zeroBtn.forceActiveFocus()
                                else if (event.key === Qt.Key_Minus)
                                twoBtn.forceActiveFocus()
                            }
        }

        TabButton {
            id: twoBtn
            text: qsTr("Widgets")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.top: oneBtn.bottom
            contentItem: Text {
                text: twoBtn.text
                color: appSettingsBar.currentIndex == 2 ? "#33aaff" : "#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 2 ? "grey" :
                                                          twoBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 2
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                twoBtn.clicked()
                                else if (event.key === Qt.Key_Equal)
                                oneBtn.forceActiveFocus()
                                else if (event.key === Qt.Key_Minus)
                                threeBtn.forceActiveFocus()
                            }
        }

        TabButton {
            id: threeBtn
            text: qsTr("Screen")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.top: twoBtn.bottom
            contentItem: Text {
                text: threeBtn.text
                color: appSettingsBar.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 3 ? "grey" :
                                                          threeBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 3
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                threeBtn.clicked()
                                else if (event.key === Qt.Key_Equal)
                                twoBtn.forceActiveFocus()
                                else if (event.key === Qt.Key_Minus)
                                fourBtn.forceActiveFocus()
                            }
        }

        TabButton {
            id: fourBtn
            text: qsTr("Video")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.top: threeBtn.bottom
            contentItem: Text {
                text: fourBtn.text
                color: appSettingsBar.currentIndex == 4 ? "#33aaff" : "#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 4 ? "grey" :
                                                          fourBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 4
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                fourBtn.clicked()
                                else if (event.key === Qt.Key_Equal)
                                threeBtn.forceActiveFocus()
                                else if (event.key === Qt.Key_Minus)
                                fiveBtn.forceActiveFocus()
                            }
        }

        TabButton {
            id: fiveBtn
            text: qsTr("Dev")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.top: fourBtn.bottom
            contentItem: Text {
                text: fiveBtn.text
                color: appSettingsBar.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: appSettingsBar.currentIndex == 5 ? "grey" :
                                                          fiveBtn.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                appSettingsStack.visible=true
                appSettingsBar.currentIndex = 5
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppMenu()
                                else if (event.key === Qt.Key_Return)
                                fiveBtn.clicked()
                                else if (event.key === Qt.Key_Equal)
                                fourBtn.forceActiveFocus()
                                // else if (event.key === Qt.Key_Minus)
                                // twoBtn.forceActiveFocus()
                            }
        }
    }

    StackLayout {
        id: appSettingsStack
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: appSettingsBar.right
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        visible: false

        currentIndex:     {
            // console.log("index:"+appSettingsBar.currentIndex);
            return appSettingsBar.currentIndex;
        }

        AppGeneralSettingsView{
            id: appGeneralSettingsView
        }
        AppVehicleSettingsView{
            id: appVehicleSettingsView
        }
        AppWidgetSettingsView{
            id: appWidgetSettingsView
        }
        AppScreenSettingsView{
            id: appScreenSettingsView
        }
        AppVideoSettingsView{
            id: appVideoSettingsView
        }
        AppManageSettingsView{
            id: appManageSettingsView
        }
    }
}
