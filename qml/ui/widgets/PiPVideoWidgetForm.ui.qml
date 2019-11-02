import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

import QGroundControl.QgcQtGStreamer 1.0


BaseWidget {
    id: pipVideoWidget
    width: 252
    height: 192

    widgetIdentifier: "pip_video_widget"

    defaultAlignment: 0
    defaultXOffset: 12
    defaultYOffset: 64
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: false

    Item {
        id: widgetInner

        anchors.left: parent.left
        anchors.leftMargin: 6

        anchors.right: parent.right
        anchors.rightMargin: 6

        anchors.top: parent.top
        anchors.topMargin: 6

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6

        /*VideoItem {
            anchors.fill: parent
            id: videoPiP
            surface: pipVideoStream.videoReceiver.videoSurface
            z: 1.0
        }*/
    }
}
