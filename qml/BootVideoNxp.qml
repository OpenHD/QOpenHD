import QtQuick 2.12
import OpenHD 1.0

Item {
    id: bootVideo
    property bool running: true
    property bool timedOut: false
    readonly property bool finished: movie.finished || timedOut
    BootSplash { anchors.fill: parent }
    Image {
        anchors.fill: parent
        source: "qrc:/boot-video-last.png"
        fillMode: Image.PreserveAspectFit
    }
    NxpVideoItem {
        id: movie
        anchors.fill: parent
        bootAnimation: true
        running: bootVideo.running && !bootVideo.timedOut
        visible: !bootVideo.finished
    }
    Timer {
        interval: 12000
        running: bootVideo.running && !bootVideo.finished
        onTriggered: {
            console.warn("QOpenHD NXP boot video: timeout; loading HUD")
            bootVideo.timedOut = true
        }
    }
}
