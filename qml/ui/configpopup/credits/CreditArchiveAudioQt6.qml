import QtQuick 2.12
import QtMultimedia 6.0

Item {
    SoundEffect {
        id: soundtrack
        objectName: "creditArchiveAudio"
        // The bundled recording starts at 00:06, including on each loop.
        source: Qt.resolvedUrl("../../../resources/credits/02.wav")
        loops: SoundEffect.Infinite
        volume: 0.35
        onStatusChanged: {
            if (status === SoundEffect.Ready)
                play()
        }
    }
    Component.onDestruction: soundtrack.stop()
}
