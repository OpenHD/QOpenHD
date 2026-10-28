import QtQuick 2.12
import QtQuick.Controls 2.12



import QtQuick.Window 2.12
//import QtLocation 5.15

import "../";
import "../../elements";

import OpenHD 1.0

BaseWidget {
    id: mapWidget

    width: compactWidth
    height: compactHeight


    visible: settings.show_map
    property alias widgetInnerMap: widgetInnerMap
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


    readonly property bool roundMap: settings.map_round && !mapExpanded
    readonly property real compactWidth: Math.max(184, 200 * settings.map_size) * (settings.map_round ? 0.7 : 1.0)
    readonly property real footerHeight: activeProviderName === "mapbox_raster" || activeProviderName === "mapboxgl" ? 32 : 16
    readonly property real compactHeight: settings.map_round ? compactWidth : compactWidth * 0.675

    Rectangle {
        id: mapSurface
        objectName: "mapSurface"
        anchors.fill: parent
        color: "#102235"
        radius: roundMap ? width / 2 : 16
        clip: true
        // Keep the native map, its markers and error overlays in the same mask.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.smooth: true
        layer.effect: ShaderEffect {
            property variant source
            property real surfaceWidth: mapSurface.width
            property real surfaceHeight: mapSurface.height
            property real cornerRadius: mapSurface.radius
            fragmentShader: "
                varying highp vec2 qt_TexCoord0;
                uniform sampler2D source;
                uniform lowp float qt_Opacity;
                uniform highp float surfaceWidth;
                uniform highp float surfaceHeight;
                uniform highp float cornerRadius;
                void main() {
                    highp vec2 size = vec2(surfaceWidth, surfaceHeight);
                    highp vec2 p = abs(qt_TexCoord0 * size - size * 0.5) - (size * 0.5 - vec2(cornerRadius));
                    highp float distance = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - cornerRadius;
                    lowp float mask = 1.0 - smoothstep(-1.0, 0.0, distance);
                    gl_FragColor = texture2D(source, qt_TexCoord0) * qt_Opacity * mask;
                }"
        }
        Item {
            id: widgetInnerMap
            anchors.fill: parent
            opacity: mapExpanded ? settings.map_opacity_maximized : settings.map_opacity_minimized
        }
        Rectangle {
            anchors.fill: parent
            radius: mapSurface.radius
            color: "transparent"
            border.width: 1
            border.color: "#7092a7bd"
            z: 4
        }
        Rectangle {
            anchors.fill: parent
            color: "#e6102235"
            visible: apiKeyMissing || mapFailure.length > 0 || (map && map.error !== 0)
            z: 1
            Text {
                anchors.centerIn: parent
                width: parent.width - (roundMap ? 48 : 24)
                color: "#edf4fc"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: apiKeyMissing ? qsTr("Add a Mapbox key in Map settings")
                      : mapFailure.length > 0 ? mapFailure : qsTr("Map unavailable. Open Map settings to retry.")
            }
        }
    }

    Rectangle {
        visible: demoFlight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: roundMap ? parent.height * 0.2 : 8
        width: demoLabel.implicitWidth + 12
        height: 22
        radius: 7
        color: "#e6102235"
        z: 6
        Text {
            id: demoLabel
            anchors.centerIn: parent
            text: qsTr("DEMO FLIGHT")
            font.pixelSize: 9
            font.bold: true
            color: "#62d8ff"
        }
    }

    // Compass labels stay upright while their positions follow the map bearing.
    Repeater {
        model: roundMap ? ["N", "E", "S", "W"] : []
        delegate: Text {
            objectName: "mapCompass" + modelData
            readonly property real compassBearing: map && map.bearing !== undefined ? map.bearing : 0
            readonly property real angle: (index * 90 - 90 - compassBearing) * Math.PI / 180
            readonly property real compassRadius: mapSurface.width / 2 + 10
            x: mapSurface.x + mapSurface.width / 2 + Math.cos(angle) * compassRadius - width / 2
            y: mapSurface.y + mapSurface.height / 2 + Math.sin(angle) * compassRadius - height / 2
            width: 16; height: 16
            text: modelData
            color: index === 0 ? "#ff6d7b" : "#eff6ff"
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: "#102235"
            z: 6
        }
    }

    function isWidgetEdge(x, y) {
        if (mapExpanded) return false
        var band = 18
        if (roundMap) {
            var dx = x - width / 2, dy = y - height / 2
            var distance = Math.sqrt(dx * dx + dy * dy)
            return distance >= width / 2 - band && distance <= width / 2
        }
        return x <= band || y <= band || x >= width - band || y >= height - band
    }
    MouseArea {
        id: edgeDrag
        objectName: "mapEdgeDrag"
        anchors.fill: parent
        z: 7
        preventStealing: true
        drag.target: null
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: Math.max(0, mapWidget.parent.width - mapWidget.width)
        drag.maximumY: Math.max(0, mapWidget.parent.height - mapWidget.height)
        property bool movingWidget: false
        onPressed: {
            if (!mapWidget.isWidgetEdge(mouse.x, mouse.y)) {
                mouse.accepted = false
                return
            }
            mapWidget._onPressAndHold(drag)
            movingWidget = mapWidget.dragging
            if (!movingWidget) mouse.accepted = false
        }
        function finishMove() {
            if (movingWidget) mapWidget._onClicked(drag)
            movingWidget = false
        }
        onReleased: finishMove()
        onCanceled: finishMove()
        onDoubleClicked: {
            finishMove()
            mapWidget.configureLargeMap()
        }
    }
    Column {
        objectName: "compactMapZoom"
        anchors.right: parent.right
        anchors.rightMargin: roundMap ? Math.max(12, parent.width * 0.06) : 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        z: 8
        MapControlButton {
            objectName: "compactMapZoomIn"
            width: 24; height: 24
            glyph: "plus"
            label: qsTr("Zoom in")
            tooltipsEnabled: false
            background: Rectangle { radius: 10; color: parent.down ? "#405e7e" : "#dc102235"; border.color: "#604d6a86" }
            onClicked: zoomMap(1)
        }
        MapControlButton {
            objectName: "compactMapZoomOut"
            width: 24; height: 24
            glyph: "minus"
            label: qsTr("Zoom out")
            tooltipsEnabled: false
            background: Rectangle { radius: 10; color: parent.down ? "#405e7e" : "#dc102235"; border.color: "#604d6a86" }
            onClicked: zoomMap(-1)
        }
    }
    Row {
        objectName: "mapAttribution"
        visible: mapExpanded
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: roundMap ? parent.height * 0.18 : 4
        spacing: 2
        z: 5
        width: roundMap ? parent.width * 0.68 : parent.width - 16
        Image {
            visible: activeProviderName === "mapbox_raster" || activeProviderName === "mapboxgl"
            source: visible ? "MapboxLogo.png" : ""
            width: visible ? 38 : 0
            height: 16
            fillMode: Image.PreserveAspectFit
        }
        Text {
            width: parent.width - (activeProviderName === "mapbox_raster" || activeProviderName === "mapboxgl" ? 40 : 0)
            text: activeProviderName === "mapbox_raster" || activeProviderName === "mapboxgl"
                  ? '<a href="https://www.mapbox.com/about/maps/">© Mapbox</a> | <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap</a> | <a href="https://apps.mapbox.com/feedback/">Improve map</a>'
                  : '<a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'
            color: "#ecf3fb"
            linkColor: color
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            style: Text.Outline
            styleColor: "#102235"
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }
}
