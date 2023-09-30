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

    cardBody: ColumnLayout {
        Row {
            spacing: 12
            leftPadding: 18

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
                text: qsTr("QOpenHD-evo-2.5.1-alpha")
                font.pixelSize: 36
            }
        }

        RowLayout{
            height: 14
            width: parent.width
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            Text {
                id: qopenhd_version
                color: "#ff3a3a3a"
                text: qsTr(QOPENHD_GIT_VERSION)
            }

            Text {
                id: license
                color: "#ff3a3a3a"
                text: qsTr("License: GPLv3")
                onLinkActivated: {
                    Qt.openUrlExternally("https://github.com/OpenHD/QOpenHD/blob/master/LICENSE")
                }
            }

            Text {
                id: qopenhd_commit_hash
                color: "#ff3a3a3a"
                text: qsTr(QOPENHD_GIT_COMMIT_HASH)
            }
        }
    }
}
