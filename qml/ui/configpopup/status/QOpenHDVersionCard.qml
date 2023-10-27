import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Card {
    id: qopenhdVersionPanel
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.top: parent.top
    anchors.topMargin: 12

    hasHeader: false

    property string m_qopenhd_version: _qopenhd.version_string

    /*Item{
        width: 200
        height: 50
        anchors.centerIn: parent
        Image{
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.height
            height: parent.height
            source: "qrc:/round.png"
            fillMode: Image.PreserveAspectFit
        }
        Text{
            anchors.top: parent.top
            anchors.right: parent.right
            width: parent.width * 2/3
            text: "QOpenHD"
            font.pixelSize: 20
            verticalAlignment: Qt.AlignCenter
        }
    }*/
    Text{
        width: parent.width
        height: parent.height
        text: "QOpenHD"
        font.pixelSize: 20
        anchors.centerIn: parent
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
    }

    Text {
        text: qsTr("GPLv3")
        height: 60
        color: "#ff3a3a3a"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -35
        anchors.right: parent.right
        rightPadding: 12
        font.pixelSize: 12
        onLinkActivated: {
            Qt.openUrlExternally("https://github.com/OpenHD/QOpenHD/blob/master/LICENSE")
        }
    }
    Text {
        text: qsTr(m_qopenhd_version)
        height: 60
        color: "#ff3a3a3a"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -35
        anchors.left: parent.left
        rightPadding: 12
        font.pixelSize: 12
    }
}
