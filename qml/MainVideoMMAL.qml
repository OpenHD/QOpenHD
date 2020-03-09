import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtMultimedia 5.12

import OpenHD 1.0


VideoOutput {
    id: display
    objectName: "mainMMALDisplay"
    source: mainMMALSurface

    OpenHDMMALRender {
        id: mainMMALSurface
        objectName: "mainMMALSurface"
    }
}
