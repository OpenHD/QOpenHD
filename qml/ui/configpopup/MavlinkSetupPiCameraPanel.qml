import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


// Dirty, for the 3 mavlink settings that need to be kept in sync on both air and ground

ScrollView {
    anchors.fill: parent
    clip:true
    contentHeight: gridViewRaspberry.height+gridViewArducam.height+gridViewVeye.height+200

    ColumnLayout {
        id: columnLayout
        x: 0
        y: 0
        width: maximumWidth
        height: maximumHeight
    }

    Text {
        id: header
        x: 15
        y: 15
        text: qsTr("Camera Setup")
        font.pixelSize: 15
    }


    Text {
        id: supplier1
        x: 15
        y: header.y+header.font.pixelSize+30
        text: qsTr("Raspberry Cameras")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewRaspberry
        x: 15
        y: 120
        width: columnLayout.width
        height: 150
        model: PiCameraConfigListOriginal {}
                delegate: Column {
                    Image {
                        width: 100; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                        anchors.fill: parent
                            onClicked: {
                            console.log("initial test 1")
                            }
                    }
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 120

    }

    Text {
        id: supplier2
        x: 15
        y: gridViewRaspberry.y+gridViewRaspberry.height
        text: qsTr("Arducam Cameras")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewArducam
        x: 15
        y: gridViewRaspberry.y+gridViewRaspberry.height+30
        width: columnLayout.width
        height: 150
        model: PiCameraConfigListArducam {}
                delegate: Column {
                    Image {
                        width: 100; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 120
    }

    Text {
        id: supplier3
        x: 15
        y: gridViewArducam.y+gridViewArducam.height
        text: qsTr("Arducam Veye")
        font.pixelSize: 15
    }

    GridView {
        id: gridViewVeye
        x: 15
        y: gridViewArducam.y+gridViewArducam.height+30
        width: columnLayout.width
        height: 300
        model: PiCameraConfigListVeye {}
                delegate: Column {
                    Image {
                        width: 100; height: 100
                        source: portrait; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
                cellWidth: 120
    }

}

/*##^##
Designer {
    D{i:0;autoSize:true;formeditorZoom:0.66;height:480;width:640}
}
##^##*/
