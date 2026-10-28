import QtQuick 2.12
import QtLocation 5.15
import QtPositioning 5.15

Item {
    id: root
    property real initialLatitude: 0
    property real initialLongitude: 0
    property string tileCacheDirectory: ""
    property string tileHost: "https://tile.openstreetmap.org/"
    property bool usingMapbox: false
    property bool drawing: false
    property bool radiusMode: true
    property var radiusCenter: QtPositioning.coordinate(initialLatitude, initialLongitude)
    function selectRadius(coordinate) {
        if (!coordinate || !coordinate.isValid) return
        drawing = false
        radiusCenter = coordinate
        var angular = 50000 / 6371007.2
        var latitude = coordinate.latitude * Math.PI / 180
        var deltaLon = Math.asin(Math.sin(angular) / Math.cos(latitude)) * 180 / Math.PI
        south = coordinate.latitude - angular * 180 / Math.PI
        north = coordinate.latitude + angular * 180 / Math.PI
        west = coordinate.longitude - deltaLon
        east = coordinate.longitude + deltaLon
        selectionValid = isFinite(deltaLon) && south >= -85 && north <= 85 && west >= -180 && east <= 180
    }
    function selectCenterRadius() {
        radiusMode = true
        selectRadius(map.center)
    }
    property bool selectionValid: false
    property real south: 0
    property real west: 0
    property real north: 0
    property real east: 0

    function fitRegion(region) {
        drawing = false
        selectionValid = false
        map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(region.north, region.west),
                                                   QtPositioning.coordinate(region.south, region.east))
        if (radiusMode) {
            selectRadius(QtPositioning.coordinate((Number(region.north) + Number(region.south)) / 2,
                                                  (Number(region.west) + Number(region.east)) / 2))
            map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(north, west), QtPositioning.coordinate(south, east))
        }
    }
    Component.onCompleted: selectRadius(radiusCenter)
    onInitialLatitudeChanged: map.center = QtPositioning.coordinate(initialLatitude, initialLongitude)
    onInitialLongitudeChanged: map.center = QtPositioning.coordinate(initialLatitude, initialLongitude)

    Plugin {
        id: osm
        name: "osm"
        PluginParameter { name: "osm.useragent"; value: "OpenHD-OfflineMaps/1.0 (+https://openhd.org)" }
        PluginParameter { name: "osm.mapping.cache.directory"; value: root.tileCacheDirectory }
        PluginParameter { name: "osm.mapping.prefetching_style"; value: "NoPrefetching" }
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
        PluginParameter { name: "osm.mapping.custom.host"; value: root.tileHost }
        PluginParameter {
            name: "osm.mapping.custom.mapcopyright"
            value: root.usingMapbox
                ? '<a href="https://www.mapbox.com/about/maps/">© Mapbox</a> <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap</a> <a href="https://apps.mapbox.com/feedback/">Improve this map</a>'
                : "© OpenStreetMap contributors"
        }
    }
    Map {
        id: map
        objectName: "offlineSelectionMap"
        anchors.fill: parent
        plugin: osm
        center: QtPositioning.coordinate(root.initialLatitude, root.initialLongitude)
        zoomLevel: 10
        copyrightsVisible: true
        onMapReadyChanged: {
            if (mapReady && root.radiusMode && root.selectionValid)
                visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(root.north, root.west),
                                                       QtPositioning.coordinate(root.south, root.east))
        }
        gesture.enabled: !root.drawing
        gesture.acceptedGestures: MapGestureArea.PanGesture | MapGestureArea.FlickGesture | MapGestureArea.PinchGesture
        onSupportedMapTypesChanged: {
            if (supportedMapTypes.length) activeMapType = supportedMapTypes[supportedMapTypes.length - 1]
        }
        MapCircle {
            visible: root.selectionValid && root.radiusMode
            center: root.radiusCenter
            radius: 50000
            color: "#4030a8ff"
            border.color: "#30a8ff"; border.width: 2
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.radiusMode && !root.drawing
            onClicked: root.selectRadius(map.toCoordinate(Qt.point(mouse.x, mouse.y), false))
        }
        MapRectangle {
            visible: root.selectionValid && !root.radiusMode
            topLeft: QtPositioning.coordinate(root.north, root.west)
            bottomRight: QtPositioning.coordinate(root.south, root.east)
            color: "#4030a8ff"
            border.color: "#30a8ff"; border.width: 2
        }
    }
    Image {
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
        width: 88; height: 23; fillMode: Image.PreserveAspectFit
        visible: root.usingMapbox
        source: root.usingMapbox ? "MapboxLogo.png" : ""
    }
    MouseArea {
        anchors.fill: parent
        objectName: "offlineRectangleInput"
        enabled: root.drawing
        property var origin
        onPressed: {
            origin = map.toCoordinate(Qt.point(mouse.x, mouse.y), false)
            root.selectionValid = false
        }
        function selectAt(x, y) {
            var end = map.toCoordinate(Qt.point(Math.max(0, Math.min(width, x)), Math.max(0, Math.min(height, y))), false)
            if (!origin || !origin.isValid || !end.isValid) return
            root.south = Math.min(origin.latitude, end.latitude)
            root.north = Math.max(origin.latitude, end.latitude)
            root.west = Math.min(origin.longitude, end.longitude)
            root.east = Math.max(origin.longitude, end.longitude)
            root.selectionValid = root.north > root.south && root.east > root.west && root.east - root.west < 180
        }
        onPositionChanged: if (pressed) selectAt(mouse.x, mouse.y)
        onReleased: { selectAt(mouse.x, mouse.y); root.drawing = false }
        onCanceled: root.selectionValid = false
    }
    Column {
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
        spacing: 4
        Rectangle {
            width: 40; height: 40; color: "#182732"; radius: 4
            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 24 }
            MouseArea { anchors.fill: parent; onClicked: map.zoomLevel = Math.min(18, map.zoomLevel + 1) }
        }
        Rectangle {
            width: 40; height: 40; color: "#182732"; radius: 4
            Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 24 }
            MouseArea { anchors.fill: parent; onClicked: map.zoomLevel = Math.max(3, map.zoomLevel - 1) }
        }
    }
}
