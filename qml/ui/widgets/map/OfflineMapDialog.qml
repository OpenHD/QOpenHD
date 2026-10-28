import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

// The map canvas is loaded only when requested, keeping QtLocation off the boot path.
Popup {
    id: root
    property var builder: typeof _offlineMapBuilder !== "undefined" ? _offlineMapBuilder : null
    property real initialLatitude: 0
    property real initialLongitude: 0
    property string mapboxApiKey: ""
    property color panelColor: typeof settings_form !== "undefined" ? settings_form.panelBackgroundRaised : "#15283b"
    property color textColor: typeof settings_form !== "undefined" ? settings_form.primaryText : "#f2f6fb"
    Material.theme: typeof settings_form !== "undefined" && !settings_form.darkMode ? Material.Light : Material.Dark
    Material.accent: typeof settings_form !== "undefined" ? settings_form.accentColor : "#278cff"
    Material.foreground: textColor
    Material.background: panelColor
    signal mapReady(string filePath)
    parent: Overlay.overlay
    width: Math.min(parent.width - 24, 1000)
    height: Math.min(parent.height - 24, 720)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    padding: 16
    closePolicy: builder && (builder.busy || builder.searching) ? Popup.NoAutoClose : Popup.CloseOnEscape
    background: Rectangle { color: root.panelColor; radius: 12; border.color: "#526775" }

    Connections {
        target: root.builder || null
        function onGenerated(filePath) { root.mapReady(filePath) }
    }
    onOpened: {
        if (root.mapboxApiKey.trim()) root.builder.setMapboxKey(root.mapboxApiKey)
        if (!canvas.active || (canvas.item && canvas.item.usingMapbox !== (root.mapboxApiKey.trim().length > 0))) {
            canvas.active = false
            canvas.setSource("OfflineMapSelection.qml", {
                "initialLatitude": root.initialLatitude,
                "initialLongitude": root.initialLongitude,
                "tileCacheDirectory": root.mapboxApiKey.trim()
                    ? root.builder.mapCacheDirectory("preview_mapbox") : root.builder.previewCacheDirectory,
                "tileHost": root.mapboxApiKey.trim() ? root.builder.mapboxBaseUrl : "https://tile.openstreetmap.org/",
                "usingMapbox": root.mapboxApiKey.trim().length > 0
            })
            canvas.active = true
        }
    }

    contentItem: Rectangle {
        objectName: "offlineMapDialogContent"
        color: root.panelColor
        ColumnLayout {
        anchors.fill: parent
        spacing: 6
        Label { text: qsTr("Create an offline map"); color: root.textColor; font.bold: true; font.pixelSize: 20 }
        Label {
            Layout.fillWidth: true
            text: qsTr("1. Find a place   2. Tap a centre for a 50 km radius, or draw an area   3. Create map")
            color: root.textColor; wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: region
                objectName: "offlineRegionSearch"
                Layout.fillWidth: true
                placeholderText: qsTr("Town or region")
                enabled: !root.builder.busy && !root.builder.searching
                selectByMouse: true
                onAccepted: root.builder.search(text)
            }
            OfflineMapButton {
                text: root.builder.searching ? qsTr("Searching...") : qsTr("Find region")
                enabled: region.text.trim().length > 0 && !root.builder.busy && !root.builder.searching
                onClicked: root.builder.search(region.text)
            }
        }
        ComboBox {
            id: results
            Layout.fillWidth: true
            visible: count > 0
            model: root.builder.searchResults
            textRole: "name"
            enabled: !root.builder.busy
            displayText: currentIndex >= 0 ? currentText : qsTr("Choose a region")
            onActivated: {
                if (canvas.item) canvas.item.fitRegion(model[index])
                region.text = model[index].name.split(",")[0]
            }
            onCountChanged: {
                currentIndex = -1
                if (count === 1 && canvas.item) {
                    currentIndex = 0
                    activated(0)
                }
            }
        }
        Loader {
            id: canvas
            objectName: "offlineMapCanvas"
            enabled: !root.builder.busy && !root.builder.searching
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.minimumHeight: 120
            active: false
        }
        Label {
            visible: canvas.status === Loader.Error
            text: qsTr("Map preview is unavailable. Install the Qt Location and Positioning modules.")
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: root.textColor
        }
        RowLayout {
            Layout.fillWidth: true
            OfflineMapButton {
                objectName: "selectRadius"
                text: qsTr("50 km radius")
                enabled: canvas.item !== null && !root.builder.busy
                onClicked: canvas.item.selectCenterRadius()
            }
            OfflineMapButton {
                text: canvas.item && canvas.item.drawing ? qsTr("Move map") : qsTr("Draw rectangle")
                enabled: canvas.item !== null && !root.builder.busy
                onClicked: { canvas.item.radiusMode = false; canvas.item.drawing = !canvas.item.drawing }
            }
            ComboBox {
                id: detail
                Layout.preferredWidth: 180
                model: [qsTr("Overview"), qsTr("Standard detail"), qsTr("High detail"), qsTr("Maximum detail")]
                currentIndex: 1
                enabled: !root.builder.busy
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap; color: root.textColor
                readonly property int count: canvas.item && canvas.item.selectionValid
                    ? root.builder.tileCount(canvas.item.south, canvas.item.west, canvas.item.north, canvas.item.east, 13 + detail.currentIndex) : 0
                text: count < 0 ? qsTr("Area exceeds limits or crosses a polar / date-line boundary. Lower detail or choose another area.")
                      : count > 0 ? qsTr("%1 tiles · size depends on map detail").arg(count)
                                  : qsTr("Move and zoom, then tap a centre or draw your area.")
                id: estimate
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: root.textColor
            text: root.builder.status
        }
        ProgressBar {
            objectName: "offlineMapProgress"
            Layout.fillWidth: true
            visible: root.builder.busy || root.builder.searching
            indeterminate: root.builder.searching || root.builder.progress === 0
            value: root.builder.progress
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true; color: root.textColor; font.pixelSize: 11; wrapMode: Text.WordWrap
                text: qsTr("Free road and waterway map · © OpenStreetMap contributors")
            }
            OfflineMapButton {
                objectName: "cancelOfflineMap"
                text: root.builder.busy || root.builder.searching ? qsTr("Cancel") : qsTr("Close")
                onClicked: {
                    if (root.builder.busy || root.builder.searching) root.builder.cancel()
                    else root.close()
                }
            }
            OfflineMapButton {
                objectName: "createOfflineMap"
                primary: true
                text: qsTr("Create map")
                enabled: canvas.item !== null && canvas.item.selectionValid && estimate.count > 0
                         && !root.builder.busy && !root.builder.searching
                onClicked: root.builder.generate(region.text, canvas.item.south, canvas.item.west,
                                                canvas.item.north, canvas.item.east, 13 + detail.currentIndex)
            }
        }
    }
    }
}
