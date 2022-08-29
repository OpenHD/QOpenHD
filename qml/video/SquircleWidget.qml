import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtMultimedia 5.12

import OpenHD 1.0


Squircle {
    SequentialAnimation on t {
        NumberAnimation { to: 1; duration: 2500; easing.type: Easing.InQuad }
        NumberAnimation { to: 0; duration: 2500; easing.type: Easing.OutQuad }
        loops: Animation.Infinite
        running: true
    }
}
