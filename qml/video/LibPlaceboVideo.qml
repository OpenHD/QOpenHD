import QtQuick 2.0

import OpenHD 1.0

// Video rendering using libplacebo for V4L2 decoded frames.
// This element hooks directly into the QT render thread, and therefore cannot be scaled,
// repositioned or similar - it is not a "normal" QT UI element.
// Primary video is always full screen, behind the HUD.
// Requires ENABLE_V4L2_GL_PLAYER enabled at compile time.
PlaceboVideoItem {
    id: placeboVideoItem
    anchors.fill: parent
}
