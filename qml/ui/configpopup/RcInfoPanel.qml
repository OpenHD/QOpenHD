import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Item {
    width: parent.width
    height: parent.height
    // Tab bar for selecting items in stack layout
    TabBar {
          id: selectItemInStackLayoutBar
          width: parent.width
          height: 100
          TabButton {
              text: qsTr("About")
          }
          TabButton {
              text: qsTr("RC over OpenHD - debug")
          }
          TabButton {
              text: qsTr("FC channels - debug")
          }
    }

    // placed right below the top bar
    StackLayout {
          width: parent.width
          height: parent.height-selectItemInStackLayoutBar.height
          anchors.top: selectItemInStackLayoutBar.bottom

          currentIndex: selectItemInStackLayoutBar.currentIndex

          RcInfoScreen{

          }
          RcDebugScreenOpenHD{

          }
          RcDebugScreenFC{

          }
      }
}
