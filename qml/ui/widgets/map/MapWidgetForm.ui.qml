import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import QtQuick.Window 2.12
//import QtLocation 5.15

import "../";

import OpenHD 1.0

import "../../elements"

BaseWidget {
    id: mapWidget

    width: 200
    height: 135


    visible: settings.show_map
    property alias mapSettingsColumn: mapSettingsColumn
    property alias switch1: switch1
    property alias mini_zoomSlider: mini_zoomSlider
    property alias mini_sizeSlider: mini_sizeSlider
    property alias openclose_button: openclose_button
    property alias providerDropdown: providerDropdown
    property alias variantDropdown: variantDropdown
    property alias widgetInnerMap: widgetInnerMap
    property alias sidebar_wrapper: sidebar_wrapper
    property alias pluginModel: pluginModel

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


    //----------------------------- Widget Detail (popup options)------------------------
    widgetDetailComponent: ScrollView {

        contentHeight: popupmapSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: popupmapSettingsColumn
            Item {
                width: 230
                height: 42
                Text {
                    id: popupmapSettingsTitle
                    text: qsTr("MAP")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: popupmapSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }
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

                NewSlider {
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
                }
            }
            Item {
                width: 230
                height: 32

                Text {
                    id: mini_sizeTitle
                    height: parent.height
                    text: qsTr("Size")
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }

                NewSlider {
                    id: mini_sizeSlider
                    orientation: Qt.Horizontal
                    from: 0.25
                    value: settings.map_size
                    to: 8
                    stepSize: .05
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    anchors.leftMargin: 32
                    anchors.left: mini_sizeTitle.right
                    height: parent.height
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: mini_opacityTitle
                    text: qsTr("Transparency(S)") // Small / minimized transparency
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSlider {
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.map_opacity_minimized
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    onValueChanged: settings.map_opacity_minimized = value
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
                NewSwitch {
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
                Text {
                    text: qsTr("Show Drone Track")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.map_drone_track
                    onCheckedChanged: settings.map_drone_track = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show Mission waypoints")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.map_show_mission_waypoints
                    onCheckedChanged: settings.map_show_mission_waypoints = checked
                }
            }
        }
    }
//--- widgetInner only used to have something to shake ---
    Item {
        id: widgetInner
        anchors.fill: parent
        width: 100
        height: 100
        clip: false
        opacity: 0
        Rectangle {
            id: rect1
            width: parent.width
            height: parent.height
            color: "white"
            border.color: "white"
            border.width: 5
            radius: 5
        }

    }
//----------------------------- Widget Inner Map----------------------------------------
    Item {
        id: widgetInnerMap
        anchors.fill: parent
        opacity: mapExpanded ? settings.map_opacity_maximized : settings.map_opacity_minimized
/*
        Behavior on width {
            NumberAnimation {
                duration: 200
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 200
            }
        }
*/

        /*Button {
            id: openclose_button_overlay
            width: 48
            height: 48
            z: 3.0

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.horizontalCenter: parent.horizontalCenter

            flat: true

            visible: true

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

            height: mapExpanded ? 155 : 48
            width: settingsVisible ? 548 : 48
            clip: true

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
                    id: openclose_text
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Font Awesome 5 Free"
                    color: "white"
                    text: mapExpanded ? "\uf057" : "\uf085"
                    font.pixelSize: 20
                }
            }

            Button {
                id: follow_button

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

                        Component.onCompleted: currentIndex = settings.selected_map_provider

                    }

                    ComboBox {
                        id: variantDropdown
                        height: 48
                        width: parent.width

                        textRole: "description"
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

                        NewSlider {
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

                            onValueChanged: settings.map_zoom = zoomSlider.value
                        }
                    }

                    Item {
                        width: parent.width
                        height: 32

                        Text {
                            id: opacityTitle
                            text: qsTr("Transparency(B)") // opacity big (maximized)
                            color: "white"
                            height: parent.height
                            font.bold: true
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                            verticalAlignment: Text.AlignVCenter
                        }

                        NewSlider {
                            orientation: Qt.Horizontal
                            from: .1
                            value: settings.map_opacity_maximized
                            to: 1
                            stepSize: .1
                            height: parent.height
                            anchors.rightMargin: 0
                            anchors.right: parent.right
                            width: parent.width - 96

                            onValueChanged: settings.map_opacity_maximized = value
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

                        NewSwitch {
                            id: switch1
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
}
