import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: {
        if (EnableGStreamer && EnablePiP) {
            return "VideoWidgetForm.ui.qml"
        }


        if (IsRaspPi && EnableVideoRender && EnablePiP) {
            return "VideoWidgetMMALForm.ui.qml"
        }

        return ""
    }
    property bool isRunning: OpenHD.pip_video_running
}
