import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 50

    widgetIdentifier: "fpv_widget"

    defaultHCenter: true
    defaultVCenter: true

    Item {
        id: widgetInner
        height: 40
        anchors.left: parent.left
        //so that fpv sits aligned in horizon must add margin
        anchors.leftMargin: 9
        width: 40
        anchors.verticalCenter: parent.verticalCenter

        transformOrigin: Item.Center
        rotation: -OpenHD.roll_raw
        transform: Translate {
            x: OpenHD.vy
            y: OpenHD.vz
        }
        antialiasing: true

        Image {
            id: image
            height: 35
            width: 40
            anchors.right: parent.right
            anchors.left: parent.left
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            source: "flight-path-vector.png"
        }
    }
}
