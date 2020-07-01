import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: rcRSSIWidget
    width: 50
    height:30

    visible: settings.show_rc_rssi

    widgetIdentifier: "rc_rssi_widget"

    defaultAlignment: 1
    defaultXOffset: 350
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Transparency"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: rc_rssi_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.rc_rssi_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.rc_rssi_opacity = rc_rssi_opacity_Slider.value
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        visible: settings.show_rc_rssi
        radius: 2
        samples: 17
        color: settings.color_glow
        opacity: settings.control_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Rectangle {
            id: rcRSSI_0to20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 3
            height: 5
            color: {
                if(OpenHD.rc_rssi==0){
                    return "red";
                }
                else {
                    return settings.color_shape;
                }
            }
            //always visible
        }

        Rectangle {
            id: rcRSSI_21to40
            anchors.left: rcRSSI_0to20.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            width: 3
            height: 10
            color: {
                if(OpenHD.rc_rssi==0){
                    return "red";
                }
                else {
                    return settings.color_shape;
                }
            }
            visible: {
                if(OpenHD.rc_rssi>20 || OpenHD.rc_rssi==0){
                    return true;
                }
                else {
                    return false;
                }
            }
        }

        Rectangle {
            id: rcRSSI_41to60
            anchors.left: rcRSSI_21to40.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            width: 3
            height: 15
            color: {
                if(OpenHD.rc_rssi==0){
                    return "red";
                }
                else {
                    return settings.color_shape;
                }
            }
            visible: {
                if(OpenHD.rc_rssi>40 || OpenHD.rc_rssi==0){
                    return true;
                }
                else {
                    return false;
                }
            }
        }

        Rectangle {
            id: rcRSSI_61to80
            anchors.left: rcRSSI_41to60.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            width: 3
            height: 20
            color: {
                if(OpenHD.rc_rssi==0){
                    return "red";
                }
                else {
                    return settings.color_shape;
                }
            }
            visible: {
                if(OpenHD.rc_rssi>60 || OpenHD.rc_rssi==0){
                    return true;
                }
                else {
                    return false;
                }
            }
        }

        Rectangle {
            id: rcRSSI_81to100
            anchors.left: rcRSSI_61to80.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            width: 3
            height: 25
            color: {
                if(OpenHD.rc_rssi==0){
                    return "red";
                }
                else {
                    return settings.color_shape;
                }
            }
            visible: {
                if(OpenHD.rc_rssi>80 || OpenHD.rc_rssi==0){
                    return true;
                }
                else {
                    return false;
                }
            }
        }

        Text {
            id: percent_symbol
            color: settings.color_text
            opacity: settings.rc_rssi_opacity
            text: OpenHD.rc_rssi == 0 ? qsTr("") : "%"
            anchors.right: rcRSSI_21to40.left
            anchors.rightMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 10
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight

        }

        Text {
            id: rc_rssi
            color: settings.color_text
            opacity: settings.rc_rssi_opacity
            text: OpenHD.rc_rssi == 0 ? qsTr("N/A") : OpenHD.rc_rssi
            anchors.right: percent_symbol.left
            anchors.rightMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 0
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight

        }       
    }
}
