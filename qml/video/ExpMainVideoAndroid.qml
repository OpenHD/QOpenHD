import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0

import OpenHD 1.0

// TODO remove me ?
//import QtMultimedia 5.15

// Written in c++ and exposed to qml
SurfaceTexture {
        id: videoItem
        anchors.fill: parent
        width:parent.width
        height:parent.height

        //z: 13

        // Set media player's video out
        Component.onCompleted: {
            _mediaPlayer.videoOut = videoItem;
            //_mediaPlayer.playFile("https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4");
            //_mediaPlayer.playFile("https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4")
            //_mediaPlayer.playFile("rtp://234.x.x.x:xxxx");
        }
 }
