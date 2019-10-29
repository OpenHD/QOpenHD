import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

import QGroundControl.QgcQtGStreamer 1.0


BaseWidget {
    id: pipVideoWidget
    width: 240
    height: 180

    widgetIdentifier: "pip_video_widget"

    defaultAlignment: 0
    defaultXOffset: 12
    defaultYOffset: 64
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: false

    Item {
        id: widgetInner

        anchors.fill: parent

        VideoItem {
            anchors.fill: parent
            id: videoPiP
            surface: pipVideoStream.videoReceiver.videoSurface
            z: 1.0
        }
    }
}
