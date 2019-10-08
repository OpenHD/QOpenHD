import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import QGroundControl.QgcQtGStreamer 1.0

Item {
     property alias loaderItem: loader.item

    Component {
        id: video
        VideoItem {
            id: videoBackground
            surface: stream.videoReceiver.videoSurface
            z: 1.0
         }
     }

     Loader {
         id: loader
         anchors.fill: parent
         sourceComponent: video

         onLoaded: {
             stream.startVideo();
         }
     }

     OpenHDVideoStream {
         id: stream
     }
 }




