import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"


Item {
    id: sidebar
    width: 64
    height: 24
    visible: settings.show_sidebar || m_extra_is_visible

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter


    property int secondaryUiWidth: 335
    property int secondaryUiHeight: 375
    property string secondaryUiColor: "#000"
    property real secondaryUiOpacity: 0.75
    property string mainDarkColor: "#302f30"
    property string highlightColor: "#555"
    property int m_control_yaw : settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_yaw : _rcchannelsmodelground.control_yaw
    property int m_control_roll: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_roll : _rcchannelsmodelground.control_roll
    property int m_control_pitch: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_pitch : _rcchannelsmodelground.control_pitch
    property int m_control_throttle: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_throttle : _rcchannelsmodelground.control_throttle
    property int selectedItemIndex: -1

    // Set to true if the sidebar is active (and some HUD elements shall be disabled)
    property bool m_is_active : false


    property bool m_extra_is_visible: false


    // Gives (keyboard / joystick) control to this element
    function open_and_take_control(){
        googleUI.visible = true
        linkUI.visible = true
        uiButton.visible = false
        m_is_active = true
        focus=true;
    }


    // This is called whenever the user clicks on the 'WBLIink' widget
    function open_link_category(){
        m_extra_is_visible=true;
        googleUI.visible = true
        linkUI.visible = true
        uiButton.visible = false
        m_is_active = true
    }


    ColumnLayout {
        id: uiButton
        width: 32
        height: 32
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            id: mouseArea1
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: {
                open_and_take_control()
            }

            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"

                RowLayout {
                    width: parent.width
                    height: parent.height

                    Text {
                        text: "\uf054"
                        font.pixelSize: 16
                        opacity: 1.0
                        font.family: "Font Awesome 5 Free"
                        color: "grey"
                    }
                }
            }
        }
    }


    ColumnLayout {
        spacing: 10
        visible: true
        anchors.verticalCenter: parent.verticalCenter



        RowLayout {
            spacing: 0


            Rectangle {
                id: googleUI
                width: secondaryUiHeight / 8 //number of items
                height: secondaryUiHeight
                color: highlightColor
                opacity: 0.7
                visible: false

                // Add a property to track the selected item index
                property int selectedItemIndex: 0

                ListView {
                    width: parent.width
                    height: parent.height
                    focus: true
                    keyNavigationEnabled: true
                    interactive: false

                    model: ListModel {
                        ListElement { text: " \uf1eb"; subText: "link" }
                        ListElement { text: " \uf11b"; subText: "rc" }
                        ListElement { text: " \uf03d"; subText: "video" }
                        ListElement { text: " \uf030"; subText: "camera" }
                        ListElement { text: " \uf0c7"; subText: "recording" }
                        ListElement { text: " \uf26c"; subText: "display" }
                        ListElement { text: " \uf55b"; subText: "drone" }
                        ListElement { text: " \uf053"; subText: "back" }
                    }

                    delegate: Item {
                        width: parent.width
                        height: secondaryUiHeight / 8 //number of items

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            onClicked: {
                                // Update the selected item index
                                googleUI.selectedItemIndex = index;

                                function hideElements() {
                                    linkUI.visible = false;
                                    videoUI.visible = false;
                                    cameraUI.visible = false;
                                    recordingUI.visible = false;
                                    displayUI.visible = false;
                                    miscUI.visible = false;
                                    rcUI.visible = false;
                                }

                                console.log("Item clicked: " + model.subText)
                                var uiElementName = model.subText + "UI";
                                if (model.subText === "back") {
                                    googleUI.visible = false;
                                    uiButton.visible = true;
                                    hideElements();
                                    m_is_active=false;
                                } else if (model.subText === "link") {
                                    hideElements();
                                    linkUI.visible = true;
                                } else if (model.subText === "rc") {
                                    hideElements();
                                    rcUI.visible = true;
                                } else if (model.subText === "video") {
                                    hideElements();
                                    videoUI.visible = true;
                                } else if (model.subText === "camera") {
                                    hideElements();
                                    cameraUI.visible = true;
                                } else if (model.subText === "recording") {
                                    hideElements();
                                    recordingUI.visible = true;
                                } else if (model.subText === "display") {
                                    hideElements();
                                    displayUI.visible = true;
                                } else if (model.subText === "drone") {
                                    hideElements();
                                    miscUI.visible = true;
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: index === googleUI.selectedItemIndex ? highlightColor : mainDarkColor
                            }

                            RowLayout {
                                width: parent.width
                                height: parent.height

                                Text {
                                    text: model.text
                                    font.pixelSize: secondaryUiHeight / 16
                                    opacity: 1.0
                                    font.family: "Font Awesome 5 Free"
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    text: model.subText
                                    visible: false
                                    font.pixelSize: secondaryUiHeight / 16
                                    opacity: 1.0
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // UI Starts here

            Rectangle {
                id: linkUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: linkUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "LINK"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: linkUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        EditFrequencyElement{
                            id: edit_frequency_element
                        }

                        EditChannelWidthElement{
                            id: edit_channel_width_element
                        }

                        EditRateElement{
                            id: edit_rate_element
                        }

                        /*Text{
                            text: "Range -> Quality" + "  (MCS" + _ohdSystemAir.curr_mcs_index + ")"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: valueSlider
                            from: 0
                            to: 3
                            stepSize: 1
                            //snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                // Handle the slider value change here
                                console.log("MCS Slider:", value)
                            }
                        }
                        Text{
                            text: "Frequency" + "   (" + _ohdSystemGround.curr_channel_mhz + ")"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ComboBox {
                            width: 200
                            model: [ "2312", "2332", "2352", "2372", "2392", "2412", "2432", "2452", "2472", "2492", "2512", "2532", "2572", "2592", "2612", "2632", "2652", "2672", "2692", "2712", "5180", "5200", "5220", "5240", "5260", "5280", "5300", "5320", "5500", "5520", "5540", "5560", "5580", "5600", "5620", "5640", "5660", "5680", "5700", "5745", "5765", "5785", "5805", "5825", "5845", "5865", "5885" ]
                        }
                        Text{
                            text: "TX Power Air" + "   (" + "TODO" + ")"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: txPowerAirSlider
                            from: 22
                            to: 58
                            stepSize: 4
                            //snapMode: Slider.SnapToStep
                            value: 22 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                // Handle the slider value change here
                                console.log("TX Power Air Slider:", value)
                            }
                        }
                        Text{
                            text: "Bandwith"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        TabBar {
                            id: control
                            Material.accent: "#fff"
                            Material.foreground: "white"
                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 40
                                color: secondaryUiColor
                            }
                            TabButton {
                                text: qsTr("20MHZ")
                            }
                            TabButton {
                                text: qsTr("40MHZ")
                            }
                        }*/
                    }
                }

            }
            Rectangle {
                id: rcUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: rcUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "OpenHD-RC"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: rcUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        /*Text{
                            text: "Enable RC"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        MavlinkSwitch{
                            m_param_name: "ENABLE_JOY_RC"
                        }*/
                        MavlinkIntChoiceElement{
                            m_title: "JOY RC"
                            m_param_id: "ENABLE_JOY_RC";
                            m_settings_model: _ohdSystemGroundSettings
                        }

                        Text{
                            text: "Channel 1"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ProgressBar {
                            id: progressBar1
                            from: 1000
                            to: 2000
                            value: m_control_yaw
                            Material.accent: Material.Grey
                        }
                        Text{
                            text: "Channel 2"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ProgressBar {
                            id: progressBar2
                            from: 1000
                            to: 2000
                            value: m_control_yaw
                            Material.accent: Material.Grey
                        }
                        Text{
                            text: "Channel 3"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ProgressBar {
                            id: progressBar3
                            from: 1000
                            to: 2000
                            value: m_control_yaw
                            Material.accent: Material.Grey
                        }
                        Text{
                            text: "Channel 4"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ProgressBar {
                            id: progressBar4
                            from: 1000
                            to: 2000
                            value: m_control_yaw
                            Material.accent: Material.Grey
                        }
                    }
                }

            }
            Rectangle {
                id: videoUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: videoUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Video"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: videoUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        EditResolutionElement{
                            id: edit_resolution_element
                        }

                        /*ComboBox {
                            id:raspberryCams3
                            visible: true
                            width: 200
                            model: [ "IMX708","IMX462","IMX477" ]
                        }
                        ComboBox {
                            id:rock5Cams3
                            visible: false
                            width: 200
                            model: [ "IMX415","IMX462","IMX708" ]
                        }
                        Text{
                            text: "Camera Mode"+ "   (" + "1080p,60fps" + ")"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: resolutionSlider3
                            from: 0
                            to: 2
                            stepSize: 1
                            //snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Resolution Slider:", value)
                            }
                        }
                        Text{
                            text: "Switch Cameras"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Switch {
                        }
                        TabBar {
                            id: cameraSwitch
                            Material.accent: "#fff"
                            Material.foreground: "white"
                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 40
                                color: secondaryUiColor
                            }
                            TabButton {
                                text: qsTr("Cam1")
                            }
                            TabButton {
                                text: qsTr("Cam2")
                            }
                        }*/
                    }
                }

            }
            Rectangle {
                id: cameraUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: cameraUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Camera"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: cameraUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        MavlinkIntChoiceElement{
                            m_title: "BRIGHTNESS"
                            m_param_id: "BRIGHTNESS"
                            m_settings_model: _airCameraSettingsModel
                        }
                        MavlinkIntChoiceElement{
                            m_title: "SATURATION"
                            m_param_id: "SATURATION_LC"
                            m_settings_model: _airCameraSettingsModel
                        }
                    }
                }

            }
            Rectangle {
                id: recordingUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: recordingUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Recording"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: recordingUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        MavlinkIntChoiceElement{
                            m_title: "RECORDING MODE"
                            m_param_id: "AIR_RECORDING_E"
                            m_settings_model: _airCameraSettingsModel
                        }

                        /*Text{
                            text: "Resolution 480p -> 1080p"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: recResolutionSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            //snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Resolution Slider:", value)
                            }
                        }
                        Text{
                            text: "Framerate 30 -> 60"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: recFramerateSlider
                            from: 0
                            to: 3
                            stepSize: 1
                            //snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Framerate Slider:", value)
                            }
                        }
                        Text{
                            text: "Bitrate"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: recBitrateSlider
                            from: 2
                            to: 18
                            stepSize: 2
                            //snapMode: Slider.SnapToStep
                            value: 8 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Birtate Slider:", value)
                            }
                        }
                        Text{
                            text: "Enable Recording"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Switch {
                        }*/
                    }
                }

            }
            Rectangle {
                id: displayUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: displayUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Misc"
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: displayUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        /*Text{
                            text: "Display Resolution"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        ComboBox {
                            id:displayResolution
                            visible: true
                            width: 200
                            model: [ "1080p","720p","480p" ]
                        }
                        Text{
                            text: "Enable wifi Hotspot"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Switch {
                            text: qsTr("Wifi Hotspot")
                        }
                        Text{
                            text: "Enable ethernet Hotspot"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Switch {
                            text: qsTr("Ethernet Hotspot")
                        }
                        Text{
                            text: "Connect to device"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        TextField {
                            Material.accent: Material.Grey
                            Material.theme: Material.Dark
                            placeholderText: qsTr("192.168.3.1")
                        }*/
                        MavlinkIntChoiceElement{
                            m_title: "AIR WIFI HS"
                            m_param_id: "WIFI_HOTSPOT_E"
                            m_settings_model: _ohdSystemAirSettingsModel
                        }
                        MavlinkIntChoiceElement{
                            m_title: "GND WIFI HS"
                            m_param_id: "WIFI_HOTSPOT_E"
                            m_settings_model: _ohdSystemGroundSettings
                        }
                    }
                }

            }
            Rectangle {
                id: miscUI
                width: secondaryUiWidth
                height: secondaryUiHeight
                color: secondaryUiColor
                opacity: secondaryUiOpacity
                visible: false
                Rectangle {
                    id: miscUiHeader
                    width: secondaryUiWidth
                    height: secondaryUiHeight/8
                    color: highlightColor
                    opacity: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Status "
                        font.pixelSize: 21
                        font.family: "AvantGarde-Medium"
                        color: "#ffffff"
                        smooth: true
                    }
                }
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: miscUiHeader.height/2
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        RowLayout {
                            Text {
                                text: "Status:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: "Connected"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }
                        RowLayout {
                            Text {
                                text: "Screen:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: applicationWindow.width + "x" + applicationWindow.height
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }

                        RowLayout {
                            Text {
                                text: "Frequency:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: _ohdSystemGround.curr_channel_mhz + "Mhz"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }
                        RowLayout {
                            Text {
                                text: "Wifi-Adapter:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                id: wifiMessage
                                property int wifiCode: _ohdSystemAir.ohd_wifi_type

                                function wifiName(code) {
                                    switch (code) {
                                    case 11: return "Asus AC56";
                                    case 12: return "8812AU CUSTOM";
                                    case 21: return "88XXBU";
                                    default: return "unknown";
                                    }
                                }

                                text: wifiName(wifiCode) + "("+_ohdSystemAir.ohd_wifi_type+")"
                                Layout.leftMargin: 12
                            }
                        }
                        RowLayout {
                            Text {
                                text: "Format:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: "1080p 60fps"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }
                        RowLayout {
                            Text {
                                text: "Version:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: "Todo"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }
                        RowLayout {
                            Text {
                                text: "Hardware Air:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                id: platformMessage
                                property int platformCode: _ohdSystemAir.ohd_platform_type

                                function platformName(code) {
                                    switch (code) {
                                    case 0: return "unknown";
                                    case 10: return "X20";
                                    case 20: return "x86";
                                    case 30: return "rpi";
                                    case 31: return "rpi 4";
                                    case 32: return "rpi 3";
                                    case 33: return "rpi 2";
                                    case 34: return "rpi 1";
                                    case 35: return "rpi 0";
                                    case 40: return "rock";
                                    case 41: return "rk3566";
                                    case 42: return "rock5a";
                                    case 43: return "rock5b";
                                    default: return "unknown";
                                    }
                                }

                                text: platformName(platformCode) + "("+_ohdSystemAir.ohd_platform_type+")"
                                Layout.leftMargin: 12
                            }
                        }
                        RowLayout {
                            Text {
                                text: "Hardware Ground:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: "Todo"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }

                        Button {
                            id: button
                            text: "Advanced Menu"

                            onClicked: {
                                settings_panel.visible = true
                            }
                        }
                    }
                }
            }

        }
    }
}
