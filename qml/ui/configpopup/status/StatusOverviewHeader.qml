import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: header
    readonly property real headerScale: Math.max(0.45, Math.min(1, width / 1350))
    readonly property bool compactTelemetry: width < 700
    readonly property real contentHeight: (compactTelemetry ? 136 : 72) * headerScale
    property int lastAudibleVolume: 100
    readonly property var camera: typeof _cameraStreamModelPrimary !== "undefined" ? _cameraStreamModelPrimary : null
    readonly property var ground: typeof _ohdSystemGround !== "undefined" ? _ohdSystemGround : null
    readonly property var air: typeof _ohdSystemAir !== "undefined" ? _ohdSystemAir : null
    readonly property var audio: typeof _audioControl !== "undefined" ? _audioControl : null
    function videoFormat() {
        if (!air || !air.is_alive || !camera) return "--"
        var format = camera.curr_set_video_format || ""
        var match = format.match(/^\d+x(\d+)@(\d+)/)
        return match ? match[1] + "p" + match[2] : (format || "--")
    }
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    Timer { interval: 1000; running: header.visible; repeat: true; onTriggered: header.clockText = Qt.formatTime(new Date(), "hh:mm") }
    Item {
        width: header.width / header.headerScale; height: 72
        scale: header.headerScale; transformOrigin: Item.TopLeft
        Text { x: 0; y: 12; objectName: "menuHeaderIcon"; text: settings_form.menuPageIcon; color: "#38a5ff"; font.family: "Font Awesome 5 Free"; font.pixelSize: 40 }
        Text { x: 66; y: 5; objectName: "menuHeaderTitle"; text: settings_form.menuPageTitle; color: settings_form.primaryText; font.family: "Archivo"; font.pixelSize: settings_form.menuPageTitle.length > 15 ? 27 : 32; font.bold: true }
        Text { x: 66; y: 47; text: settings_form.menuPageSubtitle; color: settings_form.secondaryText; font.family: "Archivo"; font.pixelSize: 16 }
        Rectangle {
            x: header.compactTelemetry ? 0 : parent.width - 960; y: header.compactTelemetry ? 80 : 0; width: 424; height: 56; radius: 28
            color: "transparent"; border.color: "transparent"
            Row {
                anchors.centerIn: parent; spacing: 16
                Repeater {
                    model: [
                        {icon: "\uf0c1", value: header.ground && header.ground.is_alive && header.camera && header.camera.curr_received_bitrate_with_fec_bps > 0 ? (header.camera.curr_received_bitrate_with_fec_bps / 1000000).toFixed(1) + " Mbit/s" : "-- Mbit/s"},
                        {icon: "\uf1da", value: header.air && header.air.is_alive && parseFloat(header.air.last_ping_result_openhd) > 0 ? header.air.last_ping_result_openhd.trim() : "-- ms"},
                        {icon: "\uf03d", value: header.videoFormat()}
                    ]
                    Row {
                        spacing: 12
                        Rectangle { visible: index > 0; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 28; color: "#153c53" }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: index < 2 ? "#12a8f3" : "#d5e7f5"; font.family: "Font Awesome 5 Free"; font.pixelSize: 23 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: settings_form.primaryText; font.family: "Archivo"; font.pixelSize: 18; width: Math.min(implicitWidth, 126); elide: Text.ElideRight }
                    }
                }
            }
        }
        Rectangle {
            x: header.compactTelemetry ? 434 : parent.width - 526; y: header.compactTelemetry ? 80 : 0; width: 226; height: 56; radius: 28
            color: "transparent"; border.color: "transparent"
            Row {
                anchors.centerIn: parent; spacing: 28
                ToolButton {
                    id: soundButton
                    objectName: "statusSoundButton"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; padding: 0
                    enabled: header.audio !== null
                    hoverEnabled: true
                    Accessible.name: qsTr("Audio playback and volume")
                    onClicked: volumePopup.open()
                    background: Rectangle { radius: 8; color: soundButton.hovered || soundButton.activeFocus ? "#153c53" : "transparent" }
                    contentItem: Text {
                        text: header.audio && header.audio.playbackVolume > 0 ? "\uf028" : "\uf6a9"
                        color: soundButton.enabled ? "#d5e7f5" : settings_form.secondaryText
                        font.family: "Font Awesome 5 Free"; font.pixelSize: 23
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 28; spacing: 4
                    Repeater {
                        model: 4
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: 6; height: 9 + index * 6
                            color: header.ground && header.ground.is_alive && header.ground.current_rx_signal_quality > index * 25 ? "#38a5ff" : "#29475c"
                        }
                    }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: header.clockText; color: settings_form.primaryText; font.family: "Archivo"; font.pixelSize: 18 }
            }
        }
    }
    Popup {
        id: volumePopup
        objectName: "statusVolumePopup"
        parent: Overlay.overlay
        width: Math.min(280, parent ? parent.width - 24 : 280)
        height: volumeContent.implicitHeight + 32
        x: parent ? Math.max(12, Math.min(parent.width - width - 12, soundButton.mapToItem(parent, 0, 0).x)) : 0
        y: parent ? Math.max(12, Math.min(parent.height - height - 12, soundButton.mapToItem(parent, 0, soundButton.height).y + 8)) : 0
        padding: 16
        modal: false; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#102235"; radius: 14; border.color: "#278cff" }
        contentItem: Column {
            id: volumeContent
            spacing: 12
            Text { text: qsTr("Audio"); color: settings_form.primaryText; font.family: "Archivo"; font.pixelSize: 18; font.bold: true }
            Switch {
                objectName: "statusPlaybackSwitch"
                width: parent.width
                text: qsTr("Playback")
                enabled: header.audio !== null
                checked: header.audio ? header.audio.playing : false
                onToggled: {
                    if (typeof settings !== "undefined") settings.dev_enable_live_audio_playback = checked
                    header.audio.setPlaybackEnabled(checked)
                }
                contentItem: Text { text: parent.text; color: settings_form.primaryText; verticalAlignment: Text.AlignVCenter; leftPadding: parent.indicator.width + parent.spacing; font.pixelSize: 14 }
            }
            Text { text: qsTr("Volume: %1 %").arg(header.audio ? header.audio.playbackVolume : 0); color: settings_form.primaryText; font.pixelSize: 14 }
            Slider {
                id: volumeSlider
                objectName: "statusVolumeSlider"
                width: parent.width
                from: 0; to: 100; stepSize: 1
                enabled: header.audio !== null
                value: header.audio ? header.audio.playbackVolume : 0
                onMoved: header.audio.playbackVolume = Math.round(value)
                Accessible.name: qsTr("Playback volume")
            }
            Button {
                objectName: "statusMuteButton"
                width: parent.width
                enabled: header.audio !== null
                text: header.audio && header.audio.playbackVolume > 0 ? qsTr("Mute") : qsTr("Unmute")
                onClicked: {
                    if (header.audio.playbackVolume > 0) {
                        header.lastAudibleVolume = header.audio.playbackVolume
                        header.audio.playbackVolume = 0
                    } else header.audio.playbackVolume = header.lastAudibleVolume
                }
            }
        }
    }
    onVisibleChanged: if (!visible) volumePopup.close()

}
