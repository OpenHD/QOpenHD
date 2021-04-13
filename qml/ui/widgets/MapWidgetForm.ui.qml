import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import QtQuick.Window 2.12
import QtLocation 5.12
import QtPositioning 5.12

import OpenHD 1.0

BaseWidget {
    id: mapWidget

    width: 200
    height: 135

    visible: settings.show_map

    defaultAlignment: 1
    defaultXOffset: 12
    defaultYOffset: 48

    widgetIdentifier: "map_widget"

    hasWidgetDetail: mapExpanded ? true : false

    z: mapExpanded ? 2.0 : 1.0

    ListModel {
        id: pluginModel

        ListElement {
            name: "osm"
            description: "OpenStreetMap"
        }
    }

    function configure() {
        var provider = pluginModel.get(settings.selected_map_provider)
        switch (provider.name) {
        case "mapboxgl": {
            createMap(widgetInner, "mapboxgl");
            break;
        }
        case "osm": {
            createMap(widgetInner, "osm");
            break;
        }
        default: {
            createMap(widgetInner, "osm");
            break;
        }
        }

        if (map) {
            variantDropdown.model = map.supportedMapTypes;
            //settings.selected_map_variant = 0;
            variantDropdown.currentIndex = settings.selected_map_variant;
            map.activeMapType = map.supportedMapTypes[variantDropdown.currentIndex];
        }
    }


    Component.onCompleted: {
        if (!IsRaspPi) {
            pluginModel.append({"name": "mapboxgl", "description":"MapboxGL"})
        }
        configure();
    }

    function configureLargeMap(){
        if (mapExpanded==false){
            resetAnchors();
            setAlignment(0, 0, 48, false, false, true);
            map.gesture.enabled=true
            mapExpanded = !mapExpanded;
        }
    }

    function configureSmallMap(){
        resetAnchors();
        mapWidget.width = 200;
        mapWidget.height = 135;
        mapWidget.map
        loadAlignment();
        followDrone = true;
        settingsVisible = false;
        map.gesture.enabled=false
        mapExpanded = !mapExpanded;
    }

    function launchPopup(){
        mapWidget.hasWidgetDetail=true
        widgetDetail.open()
    }

    //----------------------------- Widget Detail (popup options)------------------------

    widgetDetailComponent: ScrollView{

        contentHeight: popupmapSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: popupmapSettingsColumn



            Item {
                width: 230
                height: 32

                Text {
                    id: mini_zoomTitle
                    height: parent.height
                    text: qsTr("Zoom")
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }

                Slider {
                    id: mini_zoomSlider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.map_zoom
                    to: 30
                    stepSize: 1
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    anchors.leftMargin: 32
                    anchors.left: mini_zoomTitle.right
                    height: parent.height

                    onValueChanged: {
                        settings.map_zoom = mini_zoomSlider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: mini_opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: mini_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.map_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.map_opacity = mini_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock map to drone direction")
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
                    checked: settings.map_orientation
                    onCheckedChanged: settings.map_orientation = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: EnableBlackbox
                Text {
                    text: qsTr("Show Drone Track")
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
                    checked: settings.map_drone_track
                    onCheckedChanged: settings.map_drone_track = checked
                }
            }
            /*
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Map shape Square / Round")
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
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.map_shape_circle
                    onCheckedChanged: settings.map_shape_circle = checked
                }
            }
            */
        }
    }

    //----------------------------- Widget Inner ----------------------------------------

    Item {
        id: widgetInner
        anchors.fill: parent
        //opacity: mapExpanded ? 100 : settings.map_shape_circle ? 0 : settings.map_opacity
        opacity: mapExpanded ? 100 : settings.map_opacity

        Behavior on width {
            NumberAnimation { duration: 200 }
        }

        Behavior on height {
            NumberAnimation { duration: 200 }
        }

        /*Button {
            id: openclose_button_overlay
            width: 48
            height: 48
            z: 3.0

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.horizontalCenter: parent.horizontalCenter

            flat: true

            visible: true //!mapExpanded && settings.map_shape_circle

            checkable: false

            Text {
                id : openclose_text_overlay
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: "Font Awesome 5 Free"
                color: "white"
                text: "\uf31e"
                font.pixelSize: 20
            }

            onClicked: {
                if (mapExpanded) {
                    resetAnchors();
                    mapWidget.width = 200;
                    mapWidget.height = 135;
                    loadAlignment();
                    settingsVisible = false;
                } else {
                    resetAnchors();
                    setAlignment(0, 0, 48, false, false, true);
                }
                mapExpanded = !mapExpanded;
            }
        }*/




        //----------------------------- Expanded map Sidebar Menu----------------------------

        Rectangle {
            id: sidebar_wrapper
            z: 2.1

            anchors.top: parent.top
            anchors.topMargin: mapExpanded ? 6 : 0
            anchors.left: parent.left
            anchors.leftMargin: mapExpanded ? 6 : 0

            radius: 12
            color: mapExpanded ? "#ff000000" : "#00000000"

            height: mapExpanded ? 192 : 48
            width: settingsVisible ? 548 : 48
            clip: true

            Behavior on width {
                NumberAnimation { duration: 200 }
            }

            Behavior on height {
                NumberAnimation { duration: 200 }
            }

            Button {
                id: openclose_button
                width: 48
                height: 48
                anchors.top: parent.top
                anchors.topMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
                flat: true

                checkable: false

                Text {
                    id : openclose_text
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: "white"
                    text: mapExpanded ? "\uf057" : "\uf085"
                    font.pixelSize: 20
                }

                onClicked: {
                    if (mapExpanded) {
                        console.log("X button clicked");
                        configureSmallMap()

                    } else {
                        console.log("gear button clicked");
                        launchPopup()
                    }
                }
            }


            Button {
                id: search_button

                width: 48
                height: 48
                anchors.top: parent.top
                anchors.topMargin: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                flat: true

                checkable: false

                visible: mapExpanded

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: "white"
                    text: "\uf002"
                    font.pixelSize: 20
                }
            }

            Button {
                id: follow_button

                width: 48
                height: 48
                anchors.top: parent.top
                anchors.topMargin: 96
                anchors.left: parent.left
                anchors.leftMargin: 0
                flat: true

                checkable: false

                visible: mapExpanded

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: followDrone ? "#ff00aeef" : "white"
                    text: "\uf05b"
                    font.pixelSize: 20
                }

                onClicked: followDrone = !followDrone
            }

            Button {
                id: settings_button

                width: 48
                height: 48
                anchors.top: parent.top
                anchors.topMargin: 144
                anchors.left: parent.left
                anchors.leftMargin: 0

                flat: true
                checkable: false

                visible: mapExpanded

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: settingsVisible ? "#ff00aeef" : "white"
                    text: "\uf085"
                    font.pixelSize: 20
                }

                onClicked: settingsVisible = !settingsVisible
            }

            ScrollView {
                contentHeight: mapSettingsColumn.height
                clip: true


                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom

                topPadding: 6
                leftPadding: 6
                rightPadding: 6
                bottomPadding: 6

                visible: mapExpanded

                Column {
                    id: mapSettingsColumn
                    spacing: 6
                    width: settingsVisible ? 488 : 0


                    ComboBox {
                        id: providerDropdown
                        height: 48
                        width: parent.width

                        model: pluginModel
                        textRole: "description"

                        Component.onCompleted: {
                            currentIndex = settings.selected_map_provider;
                        }

                        // @disable-check M223
                        onActivated: {
                            settings.selected_map_provider = index;
                            configure();
                        }
                    }

                    ComboBox {
                        id: variantDropdown
                        height: 48
                        width: parent.width

                        textRole: "description"

                        Component.onCompleted: {
                            currentIndex = settings.selected_map_variant;
                        }

                        // @disable-check M223
                        onActivated: {
                            settings.selected_map_variant = index;
                            map.activeMapType = map.supportedMapTypes[index];
                        }
                    }


                    Item {
                        width: parent.width
                        height: 32

                        Text {
                            id: zoomTitle
                            height: parent.height
                            text: qsTr("Zoom")
                            color: "white"
                            font.bold: true
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                            verticalAlignment: Text.AlignVCenter
                        }

                        Slider {
                            id: zoomSlider
                            orientation: Qt.Horizontal
                            from: 1
                            value: settings.map_zoom
                            to: 30
                            stepSize: 1
                            height: parent.height
                            anchors.rightMargin: 0
                            anchors.right: parent.right
                            width: parent.width - 96

                            onValueChanged: {
                                settings.map_zoom = zoomSlider.value
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 32

                        Text {
                            id: opacityTitle
                            text: qsTr("Transparency")
                            color: "white"
                            height: parent.height
                            font.bold: true
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                            verticalAlignment: Text.AlignVCenter
                        }

                        Slider {
                            id: map_opacity_Slider
                            orientation: Qt.Horizontal
                            from: .1
                            value: settings.map_opacity
                            to: 1
                            stepSize: .1
                            height: parent.height
                            anchors.rightMargin: 0
                            anchors.right: parent.right
                            width: parent.width - 96

                            onValueChanged: {
                                settings.map_opacity = map_opacity_Slider.value
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 32

                        Text {
                            text: qsTr("Lock map to drone direction")
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
                            anchors.rightMargin: 12
                            anchors.right: parent.right
                            checked: settings.map_orientation
                            onCheckedChanged: settings.map_orientation = checked
                        }
                    }
                }
            }
        }
    }
    /*
    Item {
            id: mask
            anchors.fill: widgetInner
            visible: true
            z:0
            Rectangle {
                anchors.centerIn: parent
                width: parent.width<parent.height?parent.width:parent.height
                height: width
                color: "red"
                radius: width*0.5

            }
        }

        OpacityMask {
            anchors.fill: widgetInner
            source: widgetInner
            maskSource: mask
            opacity: settings.map_shape_circle ? settings.map_opacity : 0
            z:0
        }
        */
}



