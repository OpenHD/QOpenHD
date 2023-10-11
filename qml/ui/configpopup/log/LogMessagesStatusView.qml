import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

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
            text: qsTr("LOG GND")
        }
        TabButton {
            text: qsTr("LOG OpenHD AIR")
        }
        TabButton {
            text: qsTr("LOG FC")
        }
    }

    // placed right below the top bar
    StackLayout {
        width: parent.width
        height: parent.height-selectItemInStackLayoutBar.height
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: selectItemInStackLayoutBar.left
        anchors.bottom: parent.bottom
        currentIndex: selectItemInStackLayoutBar.currentIndex

        LogMessagesView{
            m_log_model: _logGround
        }

        LogMessagesView{
            m_log_model: _logOpenhdAir
        }

        LogMessagesView{
            m_log_model: _logFC
        }
    }
}
