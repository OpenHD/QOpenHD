import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    width: applicationWindow.width -165
    //the -150 is the tab on the left +15margin
    height: parent.height
    // Tab bar for selecting items in stack layout
    TabBar {
          id: selectItemInStackLayoutBar
          height: 48
          anchors.right: parent.right
          anchors.rightMargin: 0
          anchors.left: parent.left
          anchors.leftMargin: 0
          anchors.top: parent.top
          clip: true

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
