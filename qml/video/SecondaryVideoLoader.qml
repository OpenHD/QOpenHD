import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: {
        if (EnableGStreamer && EnablePiP) {
            return "SecondaryVideoGstreamer.qml";
        }
        return ""
    }
    // the video only shows up if this property is set to true
    property bool isRunning: OpenHD.pip_video_running
}
