import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import QtQuick.Window 2.12
//import QtLocation 5.15

import "../";
import "../../elements";

import OpenHD 1.0

BaseWidget {
    id: mapWidget

    width: 200 * settings.map_size
    height: 135 * settings.map_size


    visible: settings.show_map
    property alias openclose_button: openclose_button
    property alias widgetInnerMap: widgetInnerMap
    property alias sidebar_wrapper: sidebar_wrapper
    property alias pluginModel: pluginModel

    defaultAlignment: 1
    defaultXOffset: 12
    defaultYOffset: 48

    widgetIdentifier: "map_widget"

    hasWidgetDetail: false

    z: mapExpanded ? 2.0 : 1.0

    ListModel {
        id: pluginModel

        ListElement {
            name: "osm"
            description: "OpenStreetMap"
        }
        ListElement {
            name: "mapboxgl"
            description: "Mapbox (API key)"
        }
        ListElement {
            name: "openhd_offline"
            description: "OpenHD Offline"
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

            height: mapExpanded ? 96 : 48
            width: 48
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
                    text: mapExpanded ? "\uf057" : "\uf31e"
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

        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            visible: activeProviderName === "openhd_offline"
            text: "? OpenStreetMap contributors"
            color: "white"
            style: Text.Outline
            styleColor: "black"
            font.pixelSize: 10
            z: 2
        }
        Image {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 5
            width: Math.min(88, parent.width * 0.4)
            height: 23
            fillMode: Image.PreserveAspectFit
            visible: activeProviderName === "mapbox_raster"
            source: visible ? "MapboxLogo.png" : ""
            z: 2
        }

        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            visible: apiKeyMissing || mapFailure.length > 0 || (map && map.error !== 0)
            // Keep expand/collapse controls above provider errors.
            z: 1.0

            Column {
                anchors.centerIn: parent
                spacing: 8
                width: parent.width * 0.8
                Text {
                    text: apiKeyMissing ? qsTr("A Mapbox API key is required.")
                          : mapFailure.length > 0 ? mapFailure : qsTr("Map unavailable. Check your connection and API key.")
                    color: "white"
                    font.bold: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: qsTr("Open OSD & Application > Map to reload or choose another provider.")
                    color: "lightgray"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }
    }
}
