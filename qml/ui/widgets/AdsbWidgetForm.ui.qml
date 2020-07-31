import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Extras 1.4

//import OpenHD 1.0

BaseWidget {
    id: adsbWidget
    width: 55
    height: 15

    z:4

    visible: settings.show_adsb

    widgetIdentifier: "adsb_widget"

    defaultAlignment: 1
    defaultXOffset: 93
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property double lastData: 0

    Timer {
        interval: 1000;
        running: true;
        repeat: true
        onTriggered: {
            var currentTime = (new Date).getTime();
            if (currentTime - lastData > 20000) {
                adsb_status.color = "red";
            }
        }
    }

    Connections {
        target: MarkerModel
        function onDataChanged() {
            console.log("MARKER MODEL DATA CHANGED");
            lastData = (new Date).getTime();
            adsb_status.active=true;
            adsb_status.color="green";
            adsb_status_animation.restart();
        }
    }

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
                id: adsb_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.adsb_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.adsb_opacity = adsb_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: adsb_text
            color: settings.color_shape
            opacity: settings.adsb_opacity
            text: "ADS-B"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        StatusIndicator {
            id: adsb_status
            width: 15
            height: 15
            anchors.left: adsb_text.right
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            active: false
        }
    }
}
