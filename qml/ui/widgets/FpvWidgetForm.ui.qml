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
        height: 50
        width: 50
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        transformOrigin: Item.Center
        rotation: -OpenHD.roll_raw
        transform: Translate {
            x: OpenHD.vy
            y: OpenHD.vz
        }
        antialiasing: true

        Image {
            id: image
            height: 41
            anchors.right: parent.right
            anchors.left: parent.left
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            source: "flight-path-vector.png"
        }
    }
}



