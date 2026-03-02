import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0
import OpenHD 1.0
import "../../../ui" as Ui
import "../../elements"

// This hereby functions as a copyrighted declaration. Any unpermitted alteration, suppression, or eradication of this page is expressly forbidden unless granted explicit authorization by the OpenHD development team.

Rectangle {
    id: creditsRectangle
    Layout.fillHeight: true
    color: "#eaeaea"
    property int devPhotoSize: Math.round(creditsRectangle.width / 5)

    GridLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        columns: 4
        rows: 2
        columnSpacing: 10
        rowSpacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Raphael")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Image {
                    id: ee1
                    visible: true
                    source: "../../../resources/rapha.png"
                    width: creditsRectangle.devPhotoSize
                    height: creditsRectangle.devPhotoSize
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        id: rotation1
                        origin.x: ee1.width / 2
                        origin.y: ee1.height / 2
                        angle: 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            animation1.start()
                        }
                    }
                    SequentialAnimation {
                        id: animation1
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: rotation1
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 4000
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Max")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Image {
                    id: ee2
                    visible: true
                    source: "../../../resources/max.png"
                    width: creditsRectangle.devPhotoSize
                    height: creditsRectangle.devPhotoSize
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        id: rotation2
                        origin.x: ee2.width / 2
                        origin.y: ee2.height / 2
                        angle: 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            animation2.start()
                        }
                    }
                    SequentialAnimation {
                        id: animation2
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: rotation2
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 4000
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"
            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Former Developers")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "   "
                    color: "black"
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.2
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Repeater {
                    model: ["", "", "consti10", "steveatinfincia", "rodizio1", "befinitv"]

                    Text {
                        text: modelData
                        color: "black"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        Rectangle {
            Layout.rowSpan: 2
            Layout.row: 0
            Layout.column: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#333c4c"

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Honorable Mentions")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "   "
                    color: "white"
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.2
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Repeater {
                    model: ["pilotnbr1", "limitlessgreen", "michell", "roman", "jweijs", "user1321",
                            "flavio", "hdfpv", "htcohio", "raymond", "yes21", "mjc506", "cq112358",
                            "norbert", "macdaddyfpv", "ivan"]

                    Text {
                        text: modelData
                        color: "white"
                        font.pixelSize: settings.qopenhd_general_font_pixel_size
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"
            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Thomas")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Image {
                    id: ee4
                    visible: true
                    source: "../../../resources/thomas.png"
                    width: creditsRectangle.devPhotoSize
                    height: creditsRectangle.devPhotoSize
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        id: rotation4
                        origin.x: ee4.width / 2
                        origin.y: ee4.height / 2
                        angle: 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            animation4.start()
                        }
                    }
                    SequentialAnimation {
                        id: animation4
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: rotation4
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 4000
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"
            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Pete")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Image {
                    id: ee5
                    visible: true
                    source: "../../../resources/pete.png"
                    width: creditsRectangle.devPhotoSize
                    height: creditsRectangle.devPhotoSize
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        id: rotation5
                        origin.x: ee5.width / 2
                        origin.y: ee5.height / 2
                        angle: 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            animation5.start()
                        }
                    }
                    SequentialAnimation {
                        id: animation5
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: rotation5
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 4000
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f6f6f6"
            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: qsTr("Luka")
                    font.bold: true
                    font.pixelSize: settings.qopenhd_general_font_pixel_size*1.1
                    color: "black"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Image {
                    id: ee6
                    visible: true
                    source: "../../../resources/luka.png"
                    width: creditsRectangle.devPhotoSize
                    height: creditsRectangle.devPhotoSize
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        id: rotation6
                        origin.x: ee6.width / 2
                        origin.y: ee6.height / 2
                        angle: 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            animation6.start()
                        }
                    }
                    SequentialAnimation {
                        id: animation6
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: rotation6
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 4000
                        }
                    }
                }
            }
        }
    }
}
