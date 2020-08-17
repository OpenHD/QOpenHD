import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"


Rectangle {
    id: element2
    Layout.fillHeight: true
    Layout.fillWidth: true
    property alias license: license

    color: "#eaeaea"

    Card {
        id: infoPanel
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12
        height: 128
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
                    text: qsTr("QOpenHD")
                    font.pixelSize: 36
                }
            }


            Text {
                id: qopenhd_version
                width: 173
                height: 14
                color: "#ff3a3a3a"
                text: QOPENHD_VERSION
                font.pixelSize: 14
                leftPadding: 80
            }

            Text {
                id: license
                color: "#ff3a3a3a"
                text: qsTr("License: GPLv3")
                onLinkActivated: {
                    Qt.openUrlExternally("https://github.com/OpenHD/QOpenHD/blob/master/LICENSE")
                }
                font.pixelSize: 14
                leftPadding: 80
            }
        }
    }


    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: infoPanel.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 6
        height: airBox.height


        Card {
            id: airBox
            height: 128
            Layout.fillWidth: true

            cardName: qsTr("Air")
            cardBody: Item {
                Text {
                    id: airVersionID
                    text: qsTr("OpenHD Version:")
                    anchors.left: parent.left
                    anchors.top: parent.top
                    height: 24
                    font.pixelSize: 14
                    font.bold: true
                    leftPadding: 12
                }

                Text {
                    text: AirStatusMicroservice.openHDVersion
                    anchors.left: airVersionID.right
                    anchors.horizontalCenter: airVersionID.horizontalCenter
                    height: 24
                    width: 256
                    font.pixelSize: 14
                    leftPadding: 6
                }
            }
        }

        Card {
            id: groundBox
            height: 128
            Layout.fillWidth: true
            cardName: qsTr("Ground")
            cardBody: Item {
                Text {
                    id: groundVersionID
                    text: qsTr("OpenHD Version:")
                    anchors.left: parent.left
                    anchors.top: parent.top
                    height: 24
                    font.pixelSize: 14
                    font.bold: true
                    leftPadding: 12
                }

                Text {
                    text: GroundStatusMicroservice.openHDVersion
                    anchors.left: groundVersionID.right
                    anchors.horizontalCenter: groundVersionID.horizontalCenter
                    height: 24
                    width: 256
                    font.pixelSize: 14
                    leftPadding: 6
                }
            }

        }
    }
}

/*##^##
Designer {
    D{i:1;anchors_width:224;anchors_x:71;anchors_y:8}D{i:2;anchors_height:15;anchors_width:488;anchors_x:8;anchors_y:91}
D{i:3;anchors_height:106;anchors_width:282;anchors_x:35;anchors_y:110}
}
##^##*/
