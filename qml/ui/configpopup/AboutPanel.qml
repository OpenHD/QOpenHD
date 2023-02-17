import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


Rectangle {
    id: element2
    Layout.fillHeight: true
    Layout.fillWidth: true
    property alias license: license

    property int rowHeight: 64
    property int text_minHeight: 20

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
                    text: qsTr("QOpenHD-evo")
                    font.pixelSize: 36
                }
            }


            Text {
                id: qopenhd_version
                width: 173
                height: 14
                color: "#ff3a3a3a"
                text: QOPENHD_GIT_VERSION
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

            Text {
                id: qopenhd_commit_hash
                width: 173
                height: 14
                color: "#ff3a3a3a"
                text: QOPENHD_GIT_COMMIT_HASH
                font.pixelSize: 14
                leftPadding: 80
            }
        }
    }


    RowLayout {
        id: groundAndAirCardsId
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
            cardBody:
            ColumnLayout {
                // from https://doc.qt.io/qt-6/qml-qtquick-layouts-rowlayout.html
                anchors.fill: parent
                spacing: 2
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("OpenHD Version:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemAir.openhd_version
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Last Ping:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemAir.last_ping_result_openhd
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Alive: ")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemAir.is_alive ? "Yes" : "No"
                        color: _ohdSystemAir.is_alive ? "GREEN" : "RED"
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
            }
        }

        Card {
            id: groundBox
            height: 128
            Layout.fillWidth: true
            cardName: qsTr("Ground")
            cardBody:
            ColumnLayout {
                // from https://doc.qt.io/qt-6/qml-qtquick-layouts-rowlayout.html
                anchors.fill: parent
                spacing: 2
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("OpenHD Version:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemGround.openhd_version
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Last Ping:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemGround.last_ping_result_openhd
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Alive: ")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _ohdSystemGround.is_alive ? "Yes" : "No"
                        color: _ohdSystemGround.is_alive ? "GREEN" : "RED"
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
            }
        }

        // ------------
        Card {
            id: flightControllBox
            height: 128
            Layout.fillWidth: true
            cardName: qsTr("FC")
            cardBody:
            ColumnLayout {
                // from https://doc.qt.io/qt-6/qml-qtquick-layouts-rowlayout.html
                anchors.fill: parent
                spacing: 2
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("MAV type:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _fcMavlinkSystem.mav_type
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Last Ping:")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _fcMavlinkSystem.last_ping_result_flight_ctrl
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Alive: ")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _fcMavlinkSystem.is_alive ? "Yes" : "No"
                        color: _fcMavlinkSystem.is_alive ? "GREEN" : "RED"
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.minimumHeight: text_minHeight
                    spacing: 6
                    Text {
                        text: qsTr("Sys id: ")
                        height: 24
                        font.pixelSize: 14
                        font.bold: true
                        leftPadding: 12
                    }
                    Text {
                        text: _fcMavlinkSystem.for_osd_sys_id == -1 ? "na" : qsTr(""+_fcMavlinkSystem.for_osd_sys_id)
                        height: 24
                        width: 256
                        font.pixelSize: 14
                        leftPadding: 6
                    }
                }
            }
        }
        // --------------
    }
    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: groundAndAirCardsId.bottom
        anchors.left: parent.left
        anchors.margins: 10
        Button{
            height: 24
            text: "Ping all systems"
            onClicked: _mavlinkTelemetry.ping_all_systems()
        }
        Button{
            height: 24
            text: "Request version"
            onClicked: _mavlinkTelemetry.request_openhd_version()
        }
    }
}

/*##^##
Designer {
    D{i:1;anchors_width:224;anchors_x:71;anchors_y:8}D{i:2;anchors_height:15;anchors_width:488;anchors_x:8;anchors_y:91}
D{i:3;anchors_height:106;anchors_width:282;anchors_x:35;anchors_y:110}
}
##^##*/
