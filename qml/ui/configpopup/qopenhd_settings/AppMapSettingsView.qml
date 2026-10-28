import QtQuick 2.12
import QtQuick.Controls 2.12
import "../../elements"
import ".."

ScrollView {
    id: root
    readonly property var mapTarget: hudOverlayGrid.mapSettingsTarget
    contentWidth: availableWidth
    contentHeight: mapColumn.height
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Loader {
        id: offlineMapDialog
        active: false
        source: "../../widgets/map/OfflineMapDialog.qml"
        onLoaded: {
            item.builder = _offlineMapBuilder
            item.mapboxApiKey = settings.map_api_key
            item.initialLatitude = applicationWindow.referenceLatitude
            item.initialLongitude = applicationWindow.referenceLongitude
            item.mapReady.connect(function(filePath) {
                _offlineMapTiles.reload()
                if (settings.selected_map_provider === 2) mapTarget.configure()
                else settings.selected_map_provider = 2
                item.close()
            })
            item.open()
        }
    }

    Column {
        id: mapColumn
        width: root.availableWidth
        spacing: 5
        AdvancedActionButton {
            text: qsTr("Create offline map...")
            onClicked: {
                if (offlineMapDialog.item) offlineMapDialog.item.open()
                else offlineMapDialog.active = true
            }
        }
        Text {
            width: parent.width - 24; x: 12
            text: qsTr("%1 offline map packages installed").arg(_offlineMapTiles.packageCount)
            color: settings_form.secondaryText
            wrapMode: Text.WordWrap
        }

        Text {
            objectName: "mapMenuAttribution"
            width: parent.width - 24
            x: 12
            text: '<a href="https://www.openstreetmap.org/copyright">\u00a9 OpenStreetMap contributors</a>'
            color: settings_form.secondaryText
            linkColor: settings_form.accentColor
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            onLinkActivated: Qt.openUrlExternally(link)
        }

        ComboBox {
            id: offlinePackages
            objectName: "offlinePackages"
            width: Math.min(400, parent.width)
            model: _offlineMapTiles.packages
            textRole: "name"
            visible: _qopenhd.debugMenuPreview || (count > 0)
        }
        AdvancedActionButton {
            objectName: "jumpToOfflineMap"
            text: qsTr("Jump to map")
            enabled: offlinePackages.currentIndex >= 0
            onClicked: {
                mapTarget.jumpToOfflineMap(_offlineMapTiles.packages[offlinePackages.currentIndex])
                settings_form.close_all()
            }
        }
        AdvancedActionButton {
            objectName: "toggleMapDemo"
            text: mapTarget.demoFlight ? qsTr("Stop demo flight") : qsTr("Debug: circling plane")
            onClicked: {
                mapTarget.demoFlight = !mapTarget.demoFlight
                if (mapTarget.demoFlight) {
                    settings.show_map = true
                    mapTarget.followDrone = true
                    settings_form.close_all()
                }
            }
        }
        SettingBaseElement {
            m_short_description: qsTr("Show map")

            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.show_map
                onToggled: settings.show_map = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Follow aircraft")
            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: mapTarget.followDrone
                onToggled: mapTarget.followDrone = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Map provider")

            ComboBox {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                objectName: "mapProvider"
                model: mapTarget.pluginModel
                textRole: "description"
                currentIndex: settings.selected_map_provider
                onActivated: settings.selected_map_provider = index
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Map style")

            ComboBox {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                model: mapTarget.supportedMapTypes
                textRole: "description"
                currentIndex: mapTarget.activeMapTypeIndex
                enabled: count > 0 && mapTarget.activeProviderName === "mapboxgl"
                onActivated: settings.selected_map_variant = index
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Mapbox API key")

            TextField {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: settings.map_api_key
                placeholderText: qsTr("pk.xxxxx")
                selectByMouse: true
                onEditingFinished: settings.map_api_key = text.trim()
            }
        }

        Text {
            width: parent.width - 24
            x: 12
            text: qsTr("Get a Mapbox public access token at account.mapbox.com under Tokens. Select OpenStreetMap or OpenHD Offline to use the map without a key.")
            color: settings_form.secondaryText
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        AdvancedActionButton {
            objectName: "reloadMap"
            text: qsTr("Reload map")
            onClicked: mapTarget.configure()
        }

        SettingBaseElement {
            m_short_description: qsTr("Zoom")

            Slider {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                from: 1; to: 30; stepSize: 1
                value: settings.map_zoom
                onMoved: settings.map_zoom = value
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Small map shape")
            ComboBox {
                objectName: "mapShape"
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                model: [qsTr("Rounded rectangle"), qsTr("Round")]
                currentIndex: settings.map_round ? 1 : 0
                onActivated: settings.map_round = index === 1
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Small map size")

            Slider {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                objectName: "mapSize"
                from: 0.25; to: 8; stepSize: 0.05
                value: settings.map_size
                onMoved: settings.map_size = value
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Small map opacity")

            Slider {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                from: 0.1; to: 1; stepSize: 0.1
                value: settings.map_opacity_minimized
                onMoved: settings.map_opacity_minimized = value
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Expanded map opacity")

            Slider {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                from: 0.1; to: 1; stepSize: 0.1
                value: settings.map_opacity_maximized
                onMoved: settings.map_opacity_maximized = value
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Lock map to drone direction")

            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.map_orientation
                onToggled: settings.map_orientation = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Show drone track")

            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.map_drone_track
                onToggled: settings.map_drone_track = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Show mission waypoints")

            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.map_show_mission_waypoints
                onToggled: settings.map_show_mission_waypoints = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("Enable ADS-B")

            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.adsb_enable
                onToggled: settings.adsb_enable = checked
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("ADS-B SDR source")
            visible: _qopenhd.debugMenuPreview || (settings.adsb_enable)
            Switch {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                checked: settings.adsb_source === 1
                onToggled: settings.adsb_source = checked ? 1 : 0
            }
        }

        SettingBaseElement {
            m_short_description: qsTr("ADS-B radius: %1 km").arg(Math.round(settings.adsb_radius / 1000))
            visible: _qopenhd.debugMenuPreview || (settings.adsb_enable)
            Slider {
                width: Math.min(260, parent.width * 0.46)
                height: elementHeight
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                from: 5000; to: 100000; stepSize: 1000
                value: settings.adsb_radius
                onMoved: settings.adsb_radius = value
            }
        }
    }
}
