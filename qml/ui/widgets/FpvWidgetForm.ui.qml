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
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value("fpv_sensitivity",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("fpv_sensitivity", checked)
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
            x: OpenHD.vy*20
            //to get pitch relative to ahi add pitch in
            y: (OpenHD.vz*20)+ OpenHD.pitch_raw
        }
        antialiasing: true

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
            font.family: "Font Awesome 5 Free-Solid-900.otf"
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

