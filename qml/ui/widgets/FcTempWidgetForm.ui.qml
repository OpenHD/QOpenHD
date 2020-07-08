import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fcTempWidget
    width: 30
    height:30

    visible: settings.show_fc_temp

    widgetIdentifier: "fc_temp_widget"

    defaultAlignment: 1
    defaultXOffset: 93
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
                id: fc_temp_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.fc_temp_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fc_temp_opacity = fc_temp_opacity_Slider.value
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        visible: settings.show_fc_temp
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.control_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner

        anchors.fill: parent


        Text {
            id: temp_glyph
            color: OpenHD.fc_temp >= 65 ? (OpenHD.fc_temp >= 75 ? "#ff0000" : "#fbfd15") : settings.color_shape
            opacity: settings.fc_temp_opacity
            text: OpenHD.fc_temp >= 65 ? (OpenHD.fc_temp >= 75 ? "\uf2c7" : "\uf2c9") : "\uf2cb"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 16
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight

        }

        Text {
            id: fc_temp
            color: OpenHD.fc_temp >= 65 ? (OpenHD.fc_temp >= 75 ? "#ff0000" : "#fbfd15") : settings.color_text
            opacity: settings.fc_temp_opacity
            text: OpenHD.fc_temp == 0 ? qsTr("N/A") : OpenHD.fc_temp + "°"
            anchors.left: temp_glyph.right
            anchors.leftMargin: 2
            anchors.bottom: parent.bottom
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight

        }       
    }
}
