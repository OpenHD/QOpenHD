import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Rectangle {
    id: eePanel
    color: "#eaeaea"

    Image {
        id: ee1
        visible:true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: "../../resources/master1.png"
        MouseArea {
                anchors.fill: parent
                onClicked:{
                    ee1.visible=false
                    ee2.visible=true
                }
         }
    }
    Image {
        id: ee2
        visible:false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: "../../resources/master2.png"
        MouseArea {
                anchors.fill: parent
                onClicked:{
                    ee2.visible=false
                    ee3.visible=true
                }
        }
    }
    Image {
        id: ee3
        visible:false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: "../../resources/master3.png"
        MouseArea {
                anchors.fill: parent
                onClicked:{
                    ee3.visible=false
                    ee4.visible=true
                }
        }
    }
    Image {
        id: ee4
        visible:false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: "../../resources/master4.png"
        MouseArea {
                anchors.fill: parent
                onClicked:{
                    ee4.visible=false
                    ee1.visible=true
                }
        }
    }
}
