import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtMultimedia 5.12

import OpenHD 1.0


VideoOutput {
    id: display
    objectName: "mainDisplay"
    source: mainSurface

    OpenHDRender {
        id: mainSurface
        objectName: "mainSurface"
    }

    Text {
        id: watermark
        z: 2.0
        color: "#89ffffff"
        visible: !settings.hide_watermark
        font.pixelSize: 18
        text: "Do not fly with this app! Video is not stable yet!"
        horizontalAlignment: Text.AlignHCenter
        height: 24
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 96
        style: Text.Outline
        styleColor: "black"
    }
}
