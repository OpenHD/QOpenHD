import QtQuick 2.12

import OpenHD 1.0

SurfaceTexture {
    id: secondaryAndroidVideo
    anchors.fill: parent
    // Ensure the surface follows the container sizing logic from the surrounding
    // SecondaryVideoGStreamer component so Android mirrors the Linux behaviour.
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    // We only want the outer widget's mouse areas (for resize / maximize) to
    // react to clicks, so keep the texture itself passive.
    enabled: false

    Component.onCompleted: {
        if (typeof _secondaryMediaPlayer !== "undefined" && _secondaryMediaPlayer) {
            _secondaryMediaPlayer.videoOut = secondaryAndroidVideo
            _secondaryMediaPlayer.playDebugLoop()
        }
    }

    Component.onDestruction: {
        if (typeof _secondaryMediaPlayer !== "undefined" && _secondaryMediaPlayer) {
            if (_secondaryMediaPlayer.videoOut === secondaryAndroidVideo) {
                _secondaryMediaPlayer.videoOut = null
            }
        }
    }
}
