import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

Item {
    id: root
    anchors.fill: parent

    readonly property bool hasError: video.status === MediaPlayer.InvalidMedia || video.status === MediaPlayer.NoMedia

    Video {
        id: video
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        autoPlay: true
        muted: true
        loops: MediaPlayer.Infinite
        source: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4"

        onError: {
            console.warn("SecondaryVideoAndroidTest: failed to play fallback video", errorString)
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.hasError
        color: "#80000000"

        Label {
            anchors.centerIn: parent
            width: parent.width - 24
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            text: qsTr("Unable to play Android secondary sample stream: %1").arg(video.errorString)
            color: "white"
        }
    }
}
