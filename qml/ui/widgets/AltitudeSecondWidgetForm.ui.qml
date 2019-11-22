import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudesecondWidget
    width: 40
    height: 25
    defaultAlignment: 2
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 64
    dragging: false

    visible: settings.show_second_alt

    widgetIdentifier: "altitude_second_widget"

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "MSL or Relative"
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
                Component.onCompleted: checked = settings.value(
                                           "second_alt_msl_rel", true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("second_alt_msl_rel",
                                                    checked)
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            id: second_alt_text
            color: "white"
            text: qsTr(OpenHD.alt_msl)
            horizontalAlignment: Text.AlignRight
            topPadding: 2
            bottomPadding: 2
            anchors.fill: parent
        }

        Text {
            id: widgetGlyph
            y: 0
            width: 40
            height: 18
            color: "#ffffff"
            text: "\u21a8"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free-Solid-900.otf"
            font.pixelSize: 14
        }

        antialiasing: true
    }
}

/*##^##
Designer {
    D{i:0;invisible:true}
}
##^##*/

