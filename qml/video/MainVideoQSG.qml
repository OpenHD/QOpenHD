import QtQuick 2.0

import OpenHD 1.0
import "ColorPreviewMath.js" as ColorPreview

// note that this
// element hoocks directly into the QT render thread, and therefore cannot be scaled, repositioned or similar
// aka it is not a "normal" QT ui elements - doesn't need to, since primary video is always full screen, behind the HUD
// requires avcodec enabled at compile time
// Written in c++ and exposed to qml
QSGVideoTextureItem {
    id: my_QSGVideoTextureItem
    previewGain: settings.color_preview_enabled ? ColorPreview.gains(settings.color_preview_temperature, settings.color_preview_red, settings.color_preview_green, settings.color_preview_blue) : Qt.vector3d(1,1,1)
}
