import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 50

    visible: settings.show_fpv

    widgetIdentifier: "fpv_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Sensitivity"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
            }
            Slider {
                      id:fpvSlider
                      orientation: Qt.Horizontal
                      from: 1
                      value:settings.fpv_sensitivity
                      to: 20
                      stepSize: 1

                      onValueChanged: {
                          settings.fpv_sensitivity = fpvSlider.value
                      }
            }
        }
    }

    Item {
        id: widgetInner
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        //so that fpv sits aligned in horizon must add margin
        width: 40
        anchors.verticalCenter: parent.verticalCenter

        transformOrigin: Item.Center

        transform: Translate {
            x: OpenHD.vy*settings.fpv_sensitivity
            //to get pitch relative to ahi add pitch in
            y: (OpenHD.vz*settings.fpv_sensitivity)+ OpenHD.pitch_raw
        }
        antialiasing: true

        Glow {
            anchors.fill: widgetGlyph
            radius: 4
            samples: 17
            color: "black"
            source: widgetGlyph
        }

        Text {
            id: widgetGlyph
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\ufdd5"
            bottomPadding: 17
            leftPadding: 33
            horizontalAlignment: Text.AlignHCenter
            font.capitalization: Font.MixedCase
            renderType: Text.QtRendering
            textFormat: Text.AutoText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 24
        }
    }
}

/*##^##
Designer {
    D{i:3;anchors_height:24;anchors_width:24;anchors_y:0}
}
##^##*/

