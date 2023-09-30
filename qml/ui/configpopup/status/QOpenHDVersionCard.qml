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

    cardBody:
        ColumnLayout {
        anchors.centerIn: parent

        Row {
            spacing: 12
            topPadding: 60

            Image {
                id: image
                width: 48
                height: 48
                source: "qrc:/round.png"
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: title.verticalCenter
            }

            Text {
                id: title
                height: 48
                color: "#ff3a3a3a"
                text: qsTr("QOpenHD")
                font.pixelSize: 36
            }
        }

        Text {
            id: qopenhd_version
            Layout.fillWidth: true
            Layout.leftMargin: 75
            height: 48
            color: "#ff3a3a3a"
            text: qsTr(QOPENHD_GIT_VERSION)
            font.pixelSize: 12
        }
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
}
