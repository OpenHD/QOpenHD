import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: EnablePiP ? "VideoWidgetForm.ui.qml" : ""

    Connections {
        target: PiPStream
        onVideoRunning: {
            if (running) {
                //console.log("PiP stream running");
            } else {
                //console.log("PiP stream lost");
            }
        }
    }
}
