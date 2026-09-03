import QtQuick 2.12

import OpenHD 1.0

// Windows has no qmlglsink backend. Decode both streams independently, then
// let the shared AVCodec renderer composite this stream into the requested box.
QSGVideoTextureItem {
    primaryStream: false
}
