import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: homeDistanceWidget
    width: 96
    height: 24

    visible: settings.show_home_distance

    widgetIdentifier: "home_distance_widget"

    defaultAlignment: 2
    defaultXOffset: 0
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text { text: "Lat:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text { text: OpenHD.homelat; color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right }
        }
        Item {
            width: parent.width
            height: 24
            Text { text: "Long:";  color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.left: parent.left }
            Text { text: OpenHD.homelon; color: "white"; font.bold: true; font.pixelSize: detailPanelFontPixels; anchors.right: parent.right }
        }
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Opacity"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Slider {
                id: home_distance_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.home_distance_opacity
                to: 1
                stepSize: .1

                onValueChanged: {
                    settings.home_distance_opacity = home_distance_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.home_distance_opacity
            text: "\uf015"
            anchors.right: home_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: home_distance_text
            width: 64
            height: 24
            color: settings.color_text
            opacity: settings.home_distance_opacity
            // @disable-check M222
            text: {
                var distance = OpenHD.home_distance;
                var unit = "m";
                var use_imperial = settings.value("enable_imperial", false);
                // QML settings can return strings for booleans on some platforms so we check
                if (use_imperial === true || use_imperial === 1 || use_imperial === "true") {
                    unit = "ft";
                    distance /= 3.28084;
                }

                return distance.toLocaleString(Qt.locale(), "f", 1) + unit
            }
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
        }
    }
}
