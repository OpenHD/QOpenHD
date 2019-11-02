import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    widgetIdentifier: "horizon_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Invert Pitch"
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
                Component.onCompleted: checked = settings.value("invert_pitch",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("invert_pitch", checked)
            }
        }
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Invert Roll"
                color: "white"
                font.bold: true
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value("invert_roll",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("invert_roll", checked)
            }
        }
    }

    Item {
        id: widgetInner
        height: 2
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        transformOrigin: Item.Center
        rotation: -OpenHD.roll_raw
        transform: Translate {
            x: Item.Center
            y: OpenHD.pitch_raw
        }
        antialiasing: true

        Rectangle {
            width: 100
            height: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }

        Rectangle {
            width: 100
            height: 2
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }
    }
}
