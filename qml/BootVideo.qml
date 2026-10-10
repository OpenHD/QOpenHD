import QtQuick 2.12
import QtMultimedia 5.12

Item {
    id: bootVideo
    property bool running: true
    property bool finished: false
    BootSplash { anchors.fill: parent }
    // Keep the still image rendered behind the movie from the first frame.
    // It is already on the GPU when the decoder clears its output at EOF.
    Image {
        anchors.fill: parent
        source: "qrc:/boot-video-last.png"
        fillMode: Image.PreserveAspectFit
    }
    MediaPlayer {
        id: player
        source: "qrc:/boot-video.mp4"
        autoPlay: true
        muted: true
        loops: 1
        onError: {
            bootVideo.finished = true
            console.warn("Boot video unavailable:", errorString)
        }
        onStatusChanged: if (status === MediaPlayer.EndOfMedia) {
            bootVideo.finished = true
            console.warn("QOpenHD boot video: finished")
        }
        onPlaybackStateChanged: if (playbackState === MediaPlayer.PlayingState)
                                    console.warn("QOpenHD boot video: playing")
    }
    VideoOutput {
        anchors.fill: parent
        source: player
        visible: !bootVideo.finished
        fillMode: VideoOutput.PreserveAspectFit
    }
    onRunningChanged: if (!running) player.stop()
    Component.onDestruction: player.stop()
}
