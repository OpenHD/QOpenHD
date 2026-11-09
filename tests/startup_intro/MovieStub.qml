import QtQuick 2.12
Item {
    property bool running: false
    signal playbackStarted()
    signal playbackFinished()
    signal playbackFailed()
}
