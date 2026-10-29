
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0
import QtPositioning 5.15

import OpenHD 1.0

import "./ui"
import "./ui/widgets"
import "./ui/elements"
import "./ui/configpopup"
import "./video"

ApplicationWindow {
    id: applicationWindow
    visible: true

    // Map/ADS-B position priority: craft GPS, ground-device location, then IP.
    // The internet fallback is automatic and never becomes aircraft telemetry.
    readonly property bool fcPositionValid: _fcMavlinkSystem.is_alive && _fcMavlinkSystem.gps_fix_type >= 2
                                            && isFinite(_fcMavlinkSystem.lat)
                                            && isFinite(_fcMavlinkSystem.lon)
                                            && Math.abs(_fcMavlinkSystem.lat) <= 90.0
                                            && Math.abs(_fcMavlinkSystem.lon) <= 180.0
                                            && !(_fcMavlinkSystem.lat === 0.0
                                                 && _fcMavlinkSystem.lon === 0.0)
    property double ipLocationLatitude: Number.NaN
    property double ipLocationLongitude: Number.NaN
    property bool ipLocationRequestActive: false
    property var ipLocationRequest: null
    readonly property bool osPositionValid: {
        var coordinate = networkPositionSource.position.coordinate
        return coordinate && coordinate.isValid
                && isFinite(coordinate.latitude) && isFinite(coordinate.longitude)
                && !(coordinate.latitude === 0.0 && coordinate.longitude === 0.0)
    }
    readonly property bool ipPositionValid: isFinite(ipLocationLatitude)
                                             && isFinite(ipLocationLongitude)
                                             && ipLocationLatitude >= -90.0
                                             && ipLocationLatitude <= 90.0
                                             && ipLocationLongitude >= -180.0
                                             && ipLocationLongitude <= 180.0
                                             && !(ipLocationLatitude === 0.0
                                                  && ipLocationLongitude === 0.0)
    readonly property bool locationFallbackEnabled: settings.show_map || settings.adsb_enable
    readonly property bool roughPositionValid: osPositionValid || ipPositionValid
    readonly property bool referencePositionValid: fcPositionValid || roughPositionValid
    readonly property double referenceLatitude: fcPositionValid
                                                ? _fcMavlinkSystem.lat
                                                : (osPositionValid
                                                   ? networkPositionSource.position.coordinate.latitude
                                                   : (ipPositionValid ? ipLocationLatitude : 0.0))
    readonly property double referenceLongitude: fcPositionValid
                                                 ? _fcMavlinkSystem.lon
                                                 : (osPositionValid
                                                    ? networkPositionSource.position.coordinate.longitude
                                                    : (ipPositionValid ? ipLocationLongitude : 0.0))
    readonly property bool referencePositionIsRough: !fcPositionValid && roughPositionValid

    // Traffic polling also works when the map widget is disabled or unloaded.
    function updateAdsbReferencePosition() {
        AdsbVehicleManager.setReferencePosition(referencePositionValid ? referenceLatitude : Number.NaN,
                                               referencePositionValid ? referenceLongitude : Number.NaN)
    }
    onReferencePositionValidChanged: updateAdsbReferencePosition()
    onReferenceLatitudeChanged: updateAdsbReferencePosition()
    onReferenceLongitudeChanged: updateAdsbReferencePosition()
    Component.onCompleted: updateAdsbReferencePosition()

    PositionSource {
        id: networkPositionSource
        active: applicationWindow.locationFallbackEnabled && !applicationWindow.fcPositionValid
        updateInterval: 60000
        preferredPositioningMethods: PositionSource.AllPositioningMethods
    }

    onOsPositionValidChanged: {
        if (!osPositionValid) requestIpLocation()
    }

    function requestIpLocation() {
        if (!locationFallbackEnabled || fcPositionValid
                || osPositionValid || ipLocationRequestActive) return
        ipLocationRequestActive = true
        var request = new XMLHttpRequest()
        ipLocationRequest = request
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) return
            if (request !== ipLocationRequest) return
            ipLocationRequestActive = false
            ipLocationRequest = null
            if (request.status !== 200) {
                console.warn("IP location request failed with HTTP status", request.status)
                return
            }
            try {
                var response = JSON.parse(request.responseText)
                var latitude = response.latitude
                var longitude = response.longitude
                if (response.success === true && typeof latitude === "number" && typeof longitude === "number"
                        && isFinite(latitude) && isFinite(longitude)
                        && latitude >= -90.0 && latitude <= 90.0
                        && longitude >= -180.0 && longitude <= 180.0
                        && !(latitude === 0.0 && longitude === 0.0)) {
                    ipLocationLatitude = latitude
                    ipLocationLongitude = longitude
                    console.log("Using approximate IP location while FC position is unavailable")
                } else {
                    console.warn("IP location service returned no usable coordinate")
                }
            } catch (error) {
                console.warn("Cannot parse IP location response:", error)
            }
        }
        request.open("GET", "https://ipwho.is/?fields=success,latitude,longitude")
        request.send()
    }

    Timer {
        interval: 15000
        running: applicationWindow.ipLocationRequestActive
        repeat: false
        onTriggered: {
            if (applicationWindow.ipLocationRequest) {
                var timedOutRequest = applicationWindow.ipLocationRequest
                applicationWindow.ipLocationRequest = null
                applicationWindow.ipLocationRequestActive = false
                timedOutRequest.abort()
                console.warn("IP location request timed out")
            }
        }
    }

    Timer {
        // Retry promptly while unavailable; refresh occasionally in case the
        // public IP/network changes while QOpenHD remains open.
        interval: applicationWindow.ipPositionValid ? 1800000 : 300000
        running: applicationWindow.locationFallbackEnabled && !applicationWindow.fcPositionValid
        repeat: true
        triggeredOnStart: true
        onTriggered: applicationWindow.requestIpLocation()
    }


    //property int m_window_width: 1280
    //property int m_window_height: 720
    property int m_window_width: 850 // This is 480p 16:9
    property int m_window_height: 480

    //width: 850
    //height: 480
    width: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? m_window_height : m_window_width
    height: (settings.general_screen_rotation == 90 || settings.general_screen_rotation == 270) ? m_window_width : m_window_height

    onWidthChanged: {
        _qrenderstats.set_window_width(width)
    }
    onHeightChanged: {
        _qrenderstats.set_window_height(height)
    }

    contentOrientation: QOPENHD_ENABLE_NXP_VIDEO ? Qt.PrimaryOrientation :
                        (settings.general_screen_rotation===0 ? Qt.PortraitOrientation : Qt.LandscapeOrientation)
    contentItem.rotation: settings.general_screen_rotation

    //minimumWidth: 850
    //minimumHeight: 480
    title: qsTr("QOpenHD EVO")
    // Transparent background is needed when the video is not rendered via (OpenGL) inside QT,
    // but rather done independently by using a pipeline that directly goes to the HW composer (e.g. mmal on pi).
    //color: "transparent" //Consti10 transparent background
    //color : "#2C3E50" // reduce KREBS
    color: (QOPENHD_ENABLE_NXP_VIDEO || settings.app_background_transparent) ? "transparent" : "#2C3E50"
    //flags: Qt.WindowStaysOnTopHint| Qt.FramelessWindowHint| Qt.X11BypassWindowManagerHint;
    //flags: Qt.WindowStaysOnTopHint| Qt.X11BypassWindowManagerHint;
    //visibility: "FullScreen"
    // android / ios - specifc: We need to explicitly say full screen, otherwise things might be "cut off"
    visibility: (QOPENHD_ENABLE_NXP_VIDEO || settings.dev_force_show_full_screen || QOPENHD_IS_MOBILE) ? "FullScreen" : "AutomaticVisibility"

    // Local app settings. Uses the "user defaults" system on Mac/iOS, the Registry on Windows,
    // and equivalent settings systems on Linux and Android
    // On linux, they generally are stored under /home/username/.config/Open.HD
    // See https://doc.qt.io/qt-5/qsettings.html#platform-specific-notes for more info
    AppSettings {
        id: settings
    }
    CameraAutoDetection { settingsObject: settings }
    // Create the first frame before compiling and incubating the flight UI.
    readonly property bool bootSplashEnabled: _qopenhd.is_platform_rpi()
    property bool firstFrameShown: false
    onFrameSwapped: {
        if (!firstFrameShown) {
            firstFrameShown = true
            if (bootSplashEnabled)
                console.warn("QOpenHD startup splash: first frame")
        }
    }

    Loader {
        id: flightUi
        anchors.fill: parent
        focus: true
        active: !applicationWindow.bootSplashEnabled || applicationWindow.firstFrameShown
        asynchronous: applicationWindow.bootSplashEnabled
        source: "HudContent.qml"
        onLoaded: {
            console.warn("QOpenHD HUD: loaded")
        }
        onStatusChanged: {
            if (status === Loader.Error)
                console.error("Cannot load the QOpenHD flight UI")
        }
    }

    BootSplash {
        anchors.fill: parent
        visible: applicationWindow.bootSplashEnabled && flightUi.status !== Loader.Ready
        z: 10000
        failed: flightUi.status === Loader.Error
    }
}
