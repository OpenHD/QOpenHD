import QtQuick 2.12

Item {    
    property var presetSettingsMap: ([
        { title: "USB H.264 webcam as 2nd camera",
          info: "This preset will configure ground+air for a 2nd camera, and enable a USB h.264 camera as the video source ",
          settings: [{setting: "IsBandSwicherEnabled", value: "1"},
                     {setting: "SecondaryCamera", value: "USB"},
                     {setting: "LoadFlirDriver", value: "Y"},
                     {setting: "IsCamera1Enabled", value: "1"},
                     {setting: "IsCamera2Enabled", value: "1"},
                     {setting: "USBCamera", value: "gst-launch-1.0 uvch264src device=/dev/video0 initial-bitrate=\$1 average-bitrate=\$1 iframe-period=1000 name=src auto-start=true src.vidsrc ! queue ! video/x-h264,width=1280,height=720,framerate=30/1 ! h264parse ! rtph264pay ! udpsink host=127.0.0.1 port=5600"}],
        },
        { title: "FLIR One as 2nd camera (thermal view)",
          info: "This preset will configure ground+air for a 2nd camera, and enable the FLIR thermal camera sensor as the video source",
          settings: [{setting: "IsBandSwicherEnabled", value: "1"},
                     {setting: "SecondaryCamera", value: "USB"},
                     {setting: "LoadFlirDriver", value: "Y"},
                     {setting: "IsCamera1Enabled", value: "1"},
                     {setting: "IsCamera2Enabled", value: "1"},
                     {setting: "USBCamera", value: "gst-launch-1.0 v4l2src device=/dev/video3 ! video/x-raw,width=160,height=128,framerate=10/1 ! videoconvert ! v4l2h264enc ! h264parse config-interval=3 ! rtph264pay ! udpsink host=127.0.0.1 port=5600"}],
        },
        { title: "FLIR One as 2nd camera (visual view)",
          info: "This preset will configure ground+air for a 2nd camera, and enable the FLIR visual camera sensor as the video source",
          settings: [{setting: "IsBandSwicherEnabled", value: "1"},
                     {setting: "SecondaryCamera", value: "USB"},
                     {setting: "LoadFlirDriver", value: "Y"},
                     {setting: "IsCamera1Enabled", value: "1"},
                     {setting: "IsCamera2Enabled", value: "1"},
                     {setting: "USBCamera", value: "gst-launch-1.0 v4l2src device=/dev/video2 ! video/x-raw,width=640,height=480,framerate=10/1 ! videoconvert ! v4l2h264enc ! h264parse config-interval=3 ! rtph264pay ! udpsink host=127.0.0.1 port=5600"}],
        },
    ])
}
