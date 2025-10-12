import QtQuick 2.12

import OpenHD 1.0

SurfaceTexture {
    id: secondaryAndroidVideo
    anchors.fill: parent

    Component.onCompleted: {
        if (typeof _secondaryMediaPlayer !== "undefined" && _secondaryMediaPlayer) {
            _secondaryMediaPlayer.videoOut = secondaryAndroidVideo
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
