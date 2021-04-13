import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

//import OpenHD 1.0

BaseWidget {
    id: blackboxWidget
    width: 380
    height: 80
    defaultAlignment: 2
    defaultXOffset: 100
    defaultYOffset: 100
    defaultHCenter: false
    defaultVCenter: false

    visible: settings.show_blackbox

    widgetIdentifier: "blackbox_widget"

    property var count: 0

    Connections {
        target: BlackBoxModel
        function onDataChanged() {
            count= BlackBoxModel.rowCount();
            blackboxmodel_count_text.text= Number(count).toLocaleString( Qt.locale(), 'f', 0)
            blackbox_play_Slider.to=count;
        }
    }

    property bool play_pause: true
    property bool telemetry_pause: false

    function playPause() {
        //console.log("playPause from:" , blackbox_play_Slider.value);

        OpenHD.pauseBlackBox(true, blackbox_play_Slider.value);

        if (play_pause==false){
            playTimer.start();
        }
        else {
            playTimer.stop();
        }

    }

    Timer {
        id: playTimer
        interval: 1000
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: blackbox_play_Slider.value= blackbox_play_Slider.value+1;
    }

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView{

        contentHeight: blackboxSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: blackboxSettingsColumn
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: blackbox_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.blackbox_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.blackbox_opacity = blackbox_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: blackbox_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.blackbox_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.blackbox_size = blackbox_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Horizontal Center")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: {
                        // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Vertical Center")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: {
                        // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.blackbox_opacity

        Rectangle
        {
            id: background
            anchors.fill: parent
            opacity: .1
            color: "white"
            border.color: "grey"
            border.width: 2
            radius: 10

            MouseArea {
                //adding this disables the ability to move the widget and open menu
                //another solution might need to be found to prevent propogation of clicks thru the layer
                propagateComposedEvents: false
                anchors.fill: parent
            }
        }

        Item {
            width: parent.width
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10

            Text {
                id:playText
                text: blackbox_play_Slider.value
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.right: blackbox_play_Slider.left
                anchors.top: parent.top
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: blackbox_play_Slider
                orientation: Qt.Horizontal
                from: 0
                value: 0
                //to: 100
                stepSize: 1
                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: 45
                anchors.top: parent.top
                enabled:{count >= 1;}

                width: parent.width - 135
                // @disable-check M223
                onValueChanged: {
                    //console.log("play slider=",blackbox_play_Slider.value);
                    telemetry_pause=true;

                    if (play_pause == false){
                        playPauseBtn.text="\uf04c";
                    }
                    else{
                        playPauseBtn.text="\uf04b";
                    }

                    OpenHD.pauseBlackBox(telemetry_pause, blackbox_play_Slider.value);
                }
            }

            Button {
                id: playPauseBtn
                text: "\uf04c"
                font.pixelSize: 12
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                font.family: "Font Awesome 5 Free"
                enabled: {count >= 1;}

                onClicked: {// play_pause true == looks like play, false == looks like pause
                    if (play_pause==true)
                    {play_pause = false;}
                    else {play_pause = true;}

                    playPause()

                    if (play_pause == false){
                        playPauseBtn.text="\uf04c";
                    }
                    else{
                        playPauseBtn.text="\uf04b";
                    }
                }

                contentItem: Text {
                    text: playPauseBtn.text
                    font.family: "Font Awesome 5 Free"
                    opacity: enabled ? 1.0 : 0.3
                    color: playPauseBtn.down ? "white" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    id: btnBackground
                    implicitWidth: 25
                    implicitHeight: 25
                    opacity: enabled ? 1 : 0.3
                    color: "grey"
                    border.color: playPauseBtn.down ? "white" : "black"
                    border.width: 1
                    radius: 5
                }
            }

            Text {
                id: blackboxmodel_count_text
                color: "white"
                anchors.left: blackbox_play_Slider.right
                anchors.top: parent.top
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
        }
        Button {
            id: resumeTelemetryBtn
            visible: telemetry_pause
            text: "restart telemetry"
            //height: 25
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            onClicked: {
                playTimer.stop();
                play_pause=true;
                playPauseBtn.text="\uf04c";
                telemetry_pause=false;
                OpenHD.pauseBlackBox(telemetry_pause, blackbox_play_Slider.value);
            }

            contentItem: Text {
                text: resumeTelemetryBtn.text
                opacity: enabled ? 1.0 : 0.3
                color: resumeTelemetryBtn.down ? "white" : "black"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                id: resumeTelemetryBackground
                //implicitWidth: 25
                implicitHeight: 25
                opacity: enabled ? 1 : 0.3
                color: "grey"
                border.color: resumeTelemetryBtn.down ? "white" : "black"
                border.width: 1
                radius: 5
            }
        }
    }
}
