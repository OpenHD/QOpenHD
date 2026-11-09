import QtQuick 2.12
import QtMultimedia 6.0

Item {
    id: movie
    property bool running: false
    readonly property int position: player.position
    readonly property bool hasVideoFrames: output.sourceRect.width > 0
    signal playbackStarted()
    signal playbackFinished()
    signal playbackFailed()
    property bool notified: false
    MediaPlayer {
        id: player
        source: "qrc:/boot-video.mp4"
        audioOutput: AudioOutput { muted: true }
        videoOutput: output
        loops: 1
        onPlaybackStateChanged: if (playbackState === MediaPlayer.PlayingState && !movie.notified) {
            movie.notified = true
            console.info("Albatross startup: movie playing")
            movie.playbackStarted()
        }
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.EndOfMedia) movie.playbackFinished()
        onErrorOccurred: function(error, errorString) {
            console.warn("Startup movie:", errorString)
            movie.playbackFailed()
        }
    }
    VideoOutput { id: output; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectFit }
    onRunningChanged: if (running) player.play(); else player.stop()
    Component.onCompleted: if (running) player.play()
    Component.onDestruction: player.stop()
}
