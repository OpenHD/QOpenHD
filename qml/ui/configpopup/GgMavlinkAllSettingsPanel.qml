import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

/* -Parent panel for OpenHD Mavlink air and ground settings (!!!! NOT QOPENHD SETTINGS !!!)
*  -THIS FILE IS THE GOGGLE VERSION MENU THEME
*/
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300

    function openOhdPanel(){
        //console.log("openOhdPanel OpenHD/MAVLINK reached");
        if(fromSubMenu==false){//first time opening menu
            selectItemInStackLayoutBar.visible=true
            selectItemInStackLayoutBar.x = -80 //app menu slide in animation
        }
        fromSubMenu=false //reset this
        zeroBtnOhd.forceActiveFocus()
    }

    function closeOhdPanel(){
        console.log("closeOhdPanel OpenHD/MAVLINK reached");
        ohdSettingsStack.visible=false //reset and cleanup
        fromSubMenu=false
        openhdSettingsBtn.forceActiveFocus()
        selectItemInStackLayoutBar.x = -300 //app menu slide away animation
        sidebar.opacity=1 //main menu fade back in
    }

    // Tab bar for selecting items in stack layout
    TabBar {
        id: selectItemInStackLayoutBar

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
            //console.log("ggAppSettingsPanel focus changed");
        }

        Behavior on x { //when settings are opened animation
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutBack
            }
        }



        TabButton {
            id: zeroBtnOhd //numbered based on index number
            text: qsTr("WB Link freq")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            contentItem: Text {
                text: zeroBtnOhd.text
                color: selectItemInStackLayoutBar.currentIndex == 0 ? "#33aaff" :"#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectItemInStackLayoutBar.currentIndex == 0 ? "grey" :
                                                                      zeroBtnOhd.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                ohdSettingsStack.visible=true
                selectItemInStackLayoutBar.currentIndex = 0
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeOhdPanel()
                                else if (event.key === Qt.Key_Return)
                                zeroBtnOhd.clicked()
                                else if (event.key === Qt.Key_Equal){
                                    closeButton.forceActiveFocus()
                                    fromSubMenu=true
                                }
                                else if (event.key === Qt.Key_Minus)
                                oneBtnOhd.forceActiveFocus()
                            }
        }
        TabButton {
            id: oneBtnOhd //numbered based on index number
            text: qsTr("Air Camera 1")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: zeroBtnOhd.bottom
            contentItem: Text {
                text: oneBtnOhd.text
                color: selectItemInStackLayoutBar.currentIndex == 1 ? "#33aaff" :"#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectItemInStackLayoutBar.currentIndex == 1 ? "grey" :
                                                                      oneBtnOhd.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                ohdSettingsStack.visible=true
                selectItemInStackLayoutBar.currentIndex = 1
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeOhdPanel()
                                else if (event.key === Qt.Key_Return)
                                oneBtnOhd.clicked()
                                else if (event.key === Qt.Key_Equal){
                                    zeroBtnOhd.forceActiveFocus()
                                }
                                else if (event.key === Qt.Key_Minus)
                                twoBtnOhd.forceActiveFocus()
                            }
        }
        TabButton {
            id: twoBtnOhd //numbered based on index number
            text: qsTr("Air (TMP)")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: oneBtnOhd.bottom
            contentItem: Text {
                text: twoBtnOhd.text
                color: selectItemInStackLayoutBar.currentIndex == 2 ? "#33aaff" :"#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectItemInStackLayoutBar.currentIndex == 2 ? "grey" :
                                                                      twoBtnOhd.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                ohdSettingsStack.visible=true
                selectItemInStackLayoutBar.currentIndex = 2
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeOhdPanel()
                                else if (event.key === Qt.Key_Return)
                                twoBtnOhd.clicked()
                                else if (event.key === Qt.Key_Equal){
                                    oneBtnOhd.forceActiveFocus()
                                }
                                else if (event.key === Qt.Key_Minus)
                                threeBtnOhd.forceActiveFocus()
                            }
        }
        TabButton {
            id: threeBtnOhd //numbered based on index number
            text: qsTr("Ground (TMP)")
            width: 100
            height: 48
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: twoBtnOhd.bottom
            contentItem: Text {
                text: threeBtnOhd.text
                color: selectItemInStackLayoutBar.currentIndex == 3 ? "#33aaff" :"#dde4ed"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectItemInStackLayoutBar.currentIndex == 3 ? "grey" :
                                                                      threeBtnOhd.activeFocus ? "grey" : "transparent"
                opacity: .3
            }
            onClicked: {
                ohdSettingsStack.visible=true
                selectItemInStackLayoutBar.currentIndex = 3
            }
            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeOhdPanel()
                                else if (event.key === Qt.Key_Return)
                                threeBtnOhd.clicked()
                                else if (event.key === Qt.Key_Equal){
                                    twoBtnOhd.forceActiveFocus()
                                }
                                //else if (event.key === Qt.Key_Minus)
                                //twoBtnOhd.forceActiveFocus()
                            }
        }
    }

    // placed right below the top bar
    StackLayout {
        id: ohdSettingsStack
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: selectItemInStackLayoutBar.right
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        visible: false
        //currentIndex: selectItemInStackLayoutBar.currentIndex
        currentIndex:     {
            //console.log("ohd index:"+selectItemInStackLayoutBar.currentIndex);
            return selectItemInStackLayoutBar.currentIndex;
        }

        MavlinkExtraWBParamPanel{
            id: xX_WBLinkSettings
        }

        MavlinkParamPanel{
            id: x1_AirCameraSettingsPanel
            m_name: "Camera1"
            m_instanceMavlinkSettingsModel: _airCameraSettingsModel
            m_instanceCheckIsAvlie: _ohdSystemAir
        }

        MavlinkParamPanel{
            id: x2_AirSettingsPanel
            m_name: "Air"
            m_instanceMavlinkSettingsModel: _airPiSettingsModel
            m_instanceCheckIsAvlie: _ohdSystemAir
        }

        MavlinkParamPanel{
            id: x3_GroundSettingsPanel
            m_name: "Ground"
            m_instanceMavlinkSettingsModel: _groundPiSettingsModel
            m_instanceCheckIsAvlie: _ohdSystemGround
        }
    }
}
