import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_horizon

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
        rotation: -OpenHD.roll
        transform: Translate {
            x: Item.Center
            y: OpenHD.pitch
        }
        antialiasing: true

        Rectangle {
            id: left_line
            width: 100
            height: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }

        Glow {
            anchors.fill: left_line
            radius: 4
            samples: 17
            color: "black"
            source: left_line
        }

        Rectangle {
            id: right_line
            width: 100
            height: 2
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }

        Glow {
            anchors.fill: right_line
            radius: 4
            samples: 17
            color: "black"
            source: right_line
        }
    }
}
