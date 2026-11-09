import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: intro
    objectName: "albatrossStartupIntro"
    color: "black"
    focus: true
    property var audioController
    property bool running: false
    property bool hudReady: false
    property int qtMajorVersion: 5
    property bool animationDone: false
    property bool soundTriggered: false
    property bool complete: animationDone && hudReady
    property url movieComponent: qtMajorVersion >= 6 ? "StartupMovieQt6.qml" : "StartupMovieQt5.qml"
    signal finished()

    function startSound() {
        if (soundTriggered) return
        soundTriggered = true
        console.info("Albatross startup: starting soundtrack")
        if (audioController) audioController.playStartupSound()
    }
    function finishAnimation() {
        if (animationDone) return
        startSound()
        animationDone = true
    }
    function movieFailed() {
        startSound()
        fallback.start()
    }
    onCompleteChanged: if (complete) {
        console.info("Albatross startup: presenting flight display")
        finished()
    }

    Image {
        anchors.fill: parent
        source: "qrc:/boot-video-last.png"
        fillMode: Image.PreserveAspectFit
        visible: intro.animationDone || fallback.running
    }
    Loader {
        id: movie
        objectName: "startupMovieLoader"
        anchors.fill: parent
        source: intro.movieComponent
        visible: !intro.animationDone && !fallback.running
        onLoaded: item.running = Qt.binding(function() { return intro.running && !intro.animationDone })
        onStatusChanged: if (status === Loader.Error) intro.movieFailed()
    }
    Connections {
        target: movie.item
        function onPlaybackStarted() { intro.startSound() }
        function onPlaybackFinished() { intro.finishAnimation() }
        function onPlaybackFailed() { intro.movieFailed() }
    }
    Timer { id: fallback; objectName: "startupMovieFallback"; interval: 5900; onTriggered: intro.finishAnimation() }
    Timer {
        interval: 10000
        running: intro.running && !intro.animationDone
        onTriggered: intro.finishAnimation()
    }
    // Startup is skippable; neither touch nor keyboard can get trapped here.
    Button {
        text: qsTr("Continue")
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        visible: intro.hudReady
        onClicked: intro.finishAnimation()
        opacity: hovered || activeFocus ? 1.0 : 0.55
    }
    MouseArea { anchors.fill: parent; z: -1 }
    Keys.onEscapePressed: if (intro.hudReady) intro.finishAnimation()
}
