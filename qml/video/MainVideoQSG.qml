import QtQuick 2.0

import OpenHD 1.0

// note that this
// element hoocks directly into the QT render thread, and therefore cannot be scaled, repositioned or similar
// aka it is not a "normal" QT ui elements - doesn't need to, since primary video is always full screen, behind the HUD
// requires avcodec enabled at compile time
// Written in c++ and exposed to qml
QSGVideoTextureItem {
    id: my_QSGVideoTextureItem
}
