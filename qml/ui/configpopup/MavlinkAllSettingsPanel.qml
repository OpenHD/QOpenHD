import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Parent panel for OpenHD Mavlink air and ground settings (!!!! NOT QOPENHD SETTINGS !!!)
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300

    // Tab bar for selecting items in stack layout
    TabBar {
          id: selectItemInStackLayoutBar
          width: parent.width
          TabButton {
              text: qsTr("WB Link freq")
          }
          TabButton {
              text: qsTr("Air Camera 1")
          }
          TabButton {
              text: qsTr("Air Camera 2")
              enabled: settings.dev_qopenhd_n_cameras>1
          }
          TabButton {
              text: qsTr("Air (TMP)")
          }
          TabButton {
              text: qsTr("Ground (TMP)")
          }
          //TabButton {
          //    text: qsTr("FC (EXP)")
          //}
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
          // exp
          MavlinkParamPanel{
              id: x1_AirCameraSettingsPanel2
              m_name: "Camera2"
              m_instanceMavlinkSettingsModel: _airCameraSettingsModel2
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
          // EXP
          /*MavlinkParamPanel{
              id: x4_fcSettingsPanel
              m_name: "FC"
              m_instanceMavlinkSettingsModel: _fcSettingsModel
              m_instanceCheckIsAvlie: _fcMavlinkSystem
          }*/
      }

}
