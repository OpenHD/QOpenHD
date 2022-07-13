import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Parent panel for OpenHD air and ground settings (!!!! NOT QOPENHD SETTINGS !!!)
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48

    // Tab bar for selecting items in stack layout
    TabBar {
          id: selectItemInStackLayoutBar
          width: parent.width
          TabButton {
              text: qsTr("Air/Camera")
          }
          TabButton {
              text: qsTr("Ground (TMP)")
          }
    }

    // placed right below the top bar
    StackLayout {
          width: parent.width
          height: parent.height-selectItemInStackLayoutBar.height
          anchors.top: selectItemInStackLayoutBar.bottom
          //top: bar.bottom
          currentIndex: selectItemInStackLayoutBar.currentIndex
          Item {
              id: tabAirCamera
              X1_AirSystemSettingsPanel{
                  id: x1_AirSystemSettingsPanel
              }
          }
          Item {
              id: tabGround
          }
      }

}
