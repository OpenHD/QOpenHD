import QtQuick 2.0


// Loads the proper (platform-dependent) video widget for the main (primary) video

Loader {
    anchors.fill: parent
    z: 1.0
    source: {
        if (EnableGStreamer && EnableMainVideo) {
            return "MainVideoGStreamer.qml";
        }
        if (IsAndroid && EnableVideoRender && EnableMainVideo) {
            return "MainVideoRender.qml";
        }
        if (IsRaspPi && EnableVideoRender && EnableMainVideo) {
            return "MainVideoRender.qml";
        }

        if (IsMac && EnableVideoRender && EnableMainVideo) {
            return "MainVideoRender.qml";
        }
        if (IsiOS && EnableVideoRender && EnableMainVideo) {
            return "MainVideoRender.qml";
        }
        return ""
    }
}
