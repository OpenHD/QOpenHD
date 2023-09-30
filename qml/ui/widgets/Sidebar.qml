import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: sidebar
    y: (applicationWindow.height/2) - (googleUI.height/2)
    visible: settings.show_sidebar
    widgetIdentifier: "sidebar"
    bw_verbose_name: "SIDEBAR"
    property int secondaryUiWidth: 335
    property int secondaryUiHeight: 335
    property string secondaryUiColor: "#000"
    property real secondaryUiOpacity: 0.85
    property int secondaryUizPos: 999


    property int selectedItemIndex: -1

    ColumnLayout {
        id: uiButton
        width: 32
        height: 32
        y: (googleUI.height/2)-(uiButton.height/2)
        z: 99

        MouseArea {
            id: mouseArea1
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: {
                googleUI.visible = true
                linkUI.visible = true
                uiButton.visible = false
                // Perform button action here or emit a signal
            }

            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent" // Transparent background

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


        RowLayout {
            spacing: 0


            Rectangle {
                id: googleUI
                width: 32
                height: 335
                color: "#302f30"
                opacity: 0.7
                visible: false
                z: 99

                ListView {
                    width: parent.width
                    height: parent.height
                    focus: true
                    snapMode: ListView.SnapOneItem
                    model: ListModel {
                        ListElement { text: " \uf1eb"; subText: "link" }
                        ListElement { text: " \uf03d"; subText: "video" }
                        ListElement { text: " \uf030"; subText: "camera" }
                        ListElement { text: " \uf0c7"; subText: "recording" }
                        ListElement { text: " \uf26c"; subText: "display" }
                        ListElement { text: " \uf55b"; subText: "drone" }
                        ListElement { text: " \uf053"; subText: "back" }
                    }

                    delegate: Item {
                        width: parent.width
                        height: 48

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            onClicked: {

                                function hideElements() {
                                    linkUI.visible = false;
                                    videoUI.visible = false;
                                    cameraUI.visible = false;
                                    recordingUI.visible = false;
                                    displayUI.visible = false;
                                    miscUI.visible = false;
                                }

                                sidebar.selectedItemIndex = index;
                                console.log("Item clicked: " + model.subText)
                                var uiElementName = model.subText + "UI";
                                if (model.subText==="back"){
                                    googleUI.visible=false
                                    uiButton.visible=true
                                    hideElements();
                                }
                                else if (model.subText==="link"){
                                    hideElements();
                                    linkUI.visible = true;
                                }
                                else if (model.subText==="video"){
                                    hideElements();
                                    videoUI.visible = true;
                                }
                                else if (model.subText==="camera"){
                                    hideElements();
                                    cameraUI.visible = true;
                                }
                                else if (model.subText==="recording"){
                                    hideElements();
                                    recordingUI.visible = true;
                                }
                                else if (model.subText==="display"){
                                    hideElements();
                                    displayUI.visible = true;
                                }
                                else if (model.subText==="drone"){
                                    hideElements();
                                    miscUI.visible = true;
                                }
                            }
                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: index === sidebar.selectedItemIndex ? "#555" : "#302f30"
                            }

                            RowLayout {
                                width: parent.width
                                height: parent.height

                                Text {
                                    text: model.text
                                    font.pixelSize: 16
                                    opacity: 1.0
                                    font.family: "Font Awesome 5 Free"
                                    color: "white"
                                }
                                Text {
                                    text: model.subText
                                    visible: false
                                    font.pixelSize: 16
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
                z: secondaryUizPos
                Item {
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text{
                            text: "Resilliancy -> Quality"
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
                            snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                // Handle the slider value change here
                                console.log("MCS Slider:", value)
                            }
                        }
                        Text{
                            text: "Frequency"
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
                                text: "TX Power"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }
                            Slider {
                                id: txPowerSlider
                                from: 22
                                to: 58
                                stepSize: 4
                                snapMode: Slider.SnapToStep
                                value: 22 // Initial value
                                Material.accent: Material.Grey
                                onValueChanged: {
                                    // Handle the slider value change here
                                    console.log("TX Power Slider:", value)
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
                z: secondaryUizPos
                Item {
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        ComboBox {
                            id:raspberryCams
                            visible: true
                            width: 200
                            model: [ "IMX708","IMX462","IMX477" ]
                        }
                        ComboBox {
                            id:rock5Cams
                            visible: false
                            width: 200
                            model: [ "IMX415","IMX462","IMX708" ]
                        }
                        Text{
                            text: "Resolution 480p -> 1080p"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: resolutionSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
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
                            id: framerateSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
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
                            id: bitrateSlider
                            from: 2
                            to: 18
                            stepSize: 2
                            snapMode: Slider.SnapToStep
                            value: 8 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Birtate Slider:", value)
                            }
                        }
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
                z: secondaryUizPos

                Item {
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        Text{
                            text: "ISO"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: isoSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Resolution Slider:", value)
                            }
                        }
                        Text{
                            text: "Exposure"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: exposureSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Framerate Slider:", value)
                            }
                        }
                        Text{
                            text: "Camera Mode"
                            font.pixelSize: 14
                            font.family: "AvantGarde-Medium"
                            color: "#ffffff"
                            smooth: true
                        }
                        Slider {
                            id: modeSlider
                            from: 0
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
                            value: 0 // Initial value
                            Material.accent: Material.Grey
                            onValueChanged: {
                                console.log("Resolution Slider:", value)
                            }
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
                z: secondaryUizPos

                Item {
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        Text{
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
                            snapMode: Slider.SnapToStep
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
                            to: 2
                            stepSize: 1
                            snapMode: Slider.SnapToStep
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
                            snapMode: Slider.SnapToStep
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
                            text: qsTr("Enable Recording")
                        }
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
                z: secondaryUizPos

                Item {
                    width: parent.width
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text{
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
                z: secondaryUizPos

                Item {
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
                                text: "Frequency:"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true
                            }

                            Text {
                                text: "5801"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

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
                                text: "OpenHD 2.5 evo"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

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
                                text: "X86"
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
                                text: "Core3566"
                                font.pixelSize: 14
                                font.family: "AvantGarde-Medium"
                                color: "#ffffff"
                                smooth: true

                            }
                        }

                        Button {
                            id: button
                            text: "Advanced Menu"
                            }
                    }
                }
            }

        }
    }
}
