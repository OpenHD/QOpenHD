import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: {
        if (EnableGStreamer && EnablePiP) {
            return "VideoWidgetForm.ui.qml"
        }

        return ""
    }
    property bool isRunning: false;

    Connections {
        target: PiPStream
        onVideoRunning: {
            if (running) {
                //console.log("PiP stream running");
            } else {
                //console.log("PiP stream lost");
            }

            isRunning = running;
        }
    }
}
