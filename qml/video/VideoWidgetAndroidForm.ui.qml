import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    width: 252
    height: 192

    visible: settings.show_pip_video && isRunning

    widgetIdentifier: "pip_video_widget"

    defaultAlignment: 0
    defaultXOffset: 12
    defaultYOffset: 64
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: false

    Rectangle {
        id: widgetInner

        color: "#ff000000"

        anchors.left: parent.left
        anchors.leftMargin: 6

        anchors.right: parent.right
        anchors.rightMargin: 6

        anchors.top: parent.top
        anchors.topMargin: 6

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6

        OpenHDAndroidRender {
            anchors.fill: parent

            id: pipAndroidSurface
            objectName: "pipAndroidSurface"
        }
    }
}
