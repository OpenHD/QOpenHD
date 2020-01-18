import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: bitrateWidget
    width: 104
    height: 24

    visible: settings.show_bitrate

    widgetIdentifier: "bitrate_widget"

    defaultAlignment: 0
    defaultXOffset: 60
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text { text: "Measured:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text {
                text: Number(OpenHD.kbitrate_measured/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
                color: "white";
                font.bold: true;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
            }
        }
        Item {
            width: parent.width
            height: 24
            Text { text: "Set:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text {
                text: Number(OpenHD.kbitrate_set/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
                color: "white";
                font.bold: true;
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
            }
        }
    }


    Item {
        id: widgetInner

        anchors.fill: parent
        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 24
            color: "#ffffff"
            text: Number(OpenHD.kbitrate/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignTop
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: 0
            verticalAlignment: Text.AlignTop
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignRight
        }
    }
}
