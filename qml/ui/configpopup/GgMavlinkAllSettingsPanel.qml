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

    function openMenu(){
        //console.log("openMenu OpenHD/MAVLINK reached");
        if(fromSubMenu==false){//first time opening menu
        selectItemInStackLayoutBar.visible=true
        selectItemInStackLayoutBar.x = 0 //app menu slide in animation
        }
        fromSubMenu=false //reset this
        zeroBtn.forceActiveFocus()
    }

    function closeMenu(){
        console.log("closeMenu OpenHD/MAVLINK reached");
        selectItemInStackLayoutBar.visible=false //reset and cleanup
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
              text: qsTr("WB Link freq")
              width: 100
              height: 48
              font.pixelSize: 13
              anchors.horizontalCenter: parent.horizontalCenter
              contentItem: Text {
                  text: zeroBtn.text
                  color: selectItemInStackLayoutBar.currentIndex == 0 ? "#33aaff" :"#dde4ed"
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
              }
              background: Rectangle {
                  color: selectItemInStackLayoutBar.currentIndex == 0 ? "grey" :
                                                            zeroBtn.activeFocus ? "grey" : "transparent"
                  opacity: .3
              }
              onClicked: {
                  selectItemInStackLayoutBar.visible=true
                  selectItemInStackLayoutBar.currentIndex = 0
              }
              Keys.onPressed: (event)=> {
                                  if (event.key === Qt.Key_Escape)
                                  closeMenu()
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
              id: oneBtn //numbered based on index number
              text: qsTr("Air Camera 1")
              width: 100
              height: 48
              font.pixelSize: 13
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: zeroBtn.bottom
              contentItem: Text {
                  text: oneBtn.text
                  color: selectItemInStackLayoutBar.currentIndex == 1 ? "#33aaff" :"#dde4ed"
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
              }
              background: Rectangle {
                  color: selectItemInStackLayoutBar.currentIndex == 1 ? "grey" :
                                                            oneBtn.activeFocus ? "grey" : "transparent"
                  opacity: .3
              }
              onClicked: {
                  selectItemInStackLayoutBar.visible=true
                  selectItemInStackLayoutBar.currentIndex = 1
              }
              Keys.onPressed: (event)=> {
                                  if (event.key === Qt.Key_Escape)
                                  closeMenu()
                                  else if (event.key === Qt.Key_Return)
                                  oneBtn.clicked()
                                  else if (event.key === Qt.Key_Equal){
                                      zeroBtn.forceActiveFocus()
                                  }
                                  else if (event.key === Qt.Key_Minus)
                                  twoBtn.forceActiveFocus()
                              }
          }
          TabButton {              
              id: twoBtn //numbered based on index number
              text: qsTr("Air (TMP)")
              width: 100
              height: 48
              font.pixelSize: 13
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: oneBtn.bottom
              contentItem: Text {
                  text: twoBtn.text
                  color: selectItemInStackLayoutBar.currentIndex == 2 ? "#33aaff" :"#dde4ed"
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
              }
              background: Rectangle {
                  color: selectItemInStackLayoutBar.currentIndex == 2 ? "grey" :
                                                            twoBtn.activeFocus ? "grey" : "transparent"
                  opacity: .3
              }
              onClicked: {
                  selectItemInStackLayoutBar.visible=true
                  selectItemInStackLayoutBar.currentIndex = 2
              }
              Keys.onPressed: (event)=> {
                                  if (event.key === Qt.Key_Escape)
                                  closeMenu()
                                  else if (event.key === Qt.Key_Return)
                                  twoBtn.clicked()
                                  else if (event.key === Qt.Key_Equal){
                                      oneBtn.forceActiveFocus()
                                  }
                                  else if (event.key === Qt.Key_Minus)
                                  threeBtn.forceActiveFocus()
                              }
          }
          TabButton {              
              id: threeBtn //numbered based on index number
              text: qsTr("Ground (TMP)")
              width: 100
              height: 48
              font.pixelSize: 13
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: twoBtn.bottom
              contentItem: Text {
                  text: threeBtn.text
                  color: selectItemInStackLayoutBar.currentIndex == 3 ? "#33aaff" :"#dde4ed"
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
              }
              background: Rectangle {
                  color: selectItemInStackLayoutBar.currentIndex == 3 ? "grey" :
                                                            threeBtn.activeFocus ? "grey" : "transparent"
                  opacity: .3
              }
              onClicked: {
                  selectItemInStackLayoutBar.visible=true
                  selectItemInStackLayoutBar.currentIndex = 3
              }
              Keys.onPressed: (event)=> {
                                  if (event.key === Qt.Key_Escape)
                                  closeMenu()
                                  else if (event.key === Qt.Key_Return)
                                  threeBtn.clicked()
                                  else if (event.key === Qt.Key_Equal){
                                      twoBtn.forceActiveFocus()
                                  }
                                  //else if (event.key === Qt.Key_Minus)
                                  //twoBtn.forceActiveFocus()
                              }
          }
    }

    // placed right below the top bar
    StackLayout {
          width: parent.width
          height: parent.height-selectItemInStackLayoutBar.height
          anchors.top: selectItemInStackLayoutBar.bottom
          anchors.topMargin: 15
          anchors.left: selectItemInStackLayoutBar.left
          anchors.leftMargin: 15
          anchors.bottom: parent.bottom
          currentIndex: selectItemInStackLayoutBar.currentIndex
          MavlinkExtraWBParamPanel{
              id: xX_WBLinkSettings
          }
        //   MavlinkSetupPiCameraPanel{
        //       id: x1_WBPiCameraSettings
        //   }
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
