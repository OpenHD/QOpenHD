import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: {
        if (EnableGStreamer && EnablePiP) {
            return "VideoWidgetGStreamerForm.ui.qml"
        }

        if (IsAndroid && EnableVideoRender && EnablePiP) {
            return "VideoWidgetRenderForm.ui.qml"
        }

        if (IsRaspPi && EnableVideoRender && EnablePiP) {
            return "VideoWidgetRenderForm.ui.qml"
        }

        if (IsMac && EnableVideoRender && EnablePiP) {
            return "VideoWidgetRenderForm.ui.qml"
        }

        if (IsiOS && EnableVideoRender && EnablePiP) {
            return "VideoWidgetRenderForm.ui.qml"
        }
        return ""
    }
    property bool isRunning: OpenHD.pip_video_running
}
