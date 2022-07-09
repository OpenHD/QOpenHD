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
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int elementHeight: 48

    TabBar {
          id: bar
          width: parent.width
          TabButton {
              text: qsTr("Video/Camera")
          }
          TabButton {
              text: qsTr("Ground (TMP)")
          }
          TabButton {
              text: qsTr("Air (TMP)")
          }
    }


    StackLayout {
          width: parent.width
          currentIndex: bar.currentIndex
          Item {
              id: tabVideoCamera
          }
          Item {
              id: tabAir
          }
          Item {
              id: tabGround
          }
      }

}
