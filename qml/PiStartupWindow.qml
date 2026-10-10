import QtQuick 2.12
import QtQuick.Window 2.12

Window {
    id: startupWindow
    visible: true
    visibility: Window.FullScreen
    color: hudPresented && flightContent.item ? flightContent.item.windowColor : "black"
    title: "QOpenHD EVO"
    contentItem.rotation: flightContent.item ? flightContent.item.screenRotation : 0
    contentOrientation: flightContent.item && flightContent.item.screenRotation !== 0
                        ? Qt.LandscapeOrientation : Qt.PortraitOrientation
    readonly property bool hudReady: flightContent.item !== null && flightContent.item.hudReady
    readonly property bool videoFinished: videoSplash.item !== null && videoSplash.item.finished
    property bool hudPresented: false
    property int heldFrameCount: 0
    property int preparedHudFrameCount: 0
    onVideoFinishedChanged: if (videoFinished) startupWindow.update()
    onFrameSwapped: {
        if (!videoFinished) return
        if (!flightContent.active) {
            heldFrameCount++
            if (heldFrameCount >= 2)
                flightContent.active = true
            else
                startupWindow.update()
        } else if (hudReady && !hudPresented) {
            // Prepare the HUD's graphics while the final movie frame covers it.
            preparedHudFrameCount++
            if (preparedHudFrameCount >= 2)
                hudPresented = true
            else
                startupWindow.update()
        }
    }
    function loadFlightUi() {
        videoSplash.active = true
    }
    Loader {
        id: flightContent
        anchors.fill: parent
        active: false
        source: "PiFlightContent.qml"
    }
    Loader {
        id: videoSplash
        anchors.fill: parent
        z: 10001
        active: false
        visible: !startupWindow.hudPresented
        source: "BootVideo.qml"
        onVisibleChanged: if (!visible && item) item.running = false
    }
    BootSplash {
        anchors.fill: parent
        z: 10000
        visible: !flightContent.item || !flightContent.item.hudReady
        failed: flightContent.status === Loader.Error || (flightContent.item && flightContent.item.hudFailed)
    }
}
