import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import Qt.labs.settings 1.0

import "./widgets"

Item {
    property alias messageHUD: messageHUD
    signal settingsButtonClicked

    Image {
        id: settingsButton
        width: 48
        height: 48
        fillMode: Image.PreserveAspectFit
        z: 2.2

        source: "../ic128.png"
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 0

        MouseArea {
            id: settingsButtonMouseArea
            anchors.fill: parent

            onClicked: {
                hudOverlayGrid.settingsButtonClicked()
            }
        }
    }

    // + 0% cpu
    MessageHUD {
        id: messageHUD
    }

    GroundPowerWidget {
        id: groundPowerWidget
    }

    // + 0% cpu
    AirBatteryWidget {
        id: air_battery
    }

    // + 0% cpu
    FlightModeWidget {
        id: flight_mode
    }

    // + 0% cpu
    GPSWidget {
        id: gps
    }

    // + 0% cpu
    HomeDistanceWidget {
        id: home_distance
    }

    // + 0% cpu
    FlightTimerWidget {
        id: flight_timer
    }

    // + 0% cpu
    FlightDistanceWidget {
        id: flight_distance
    }

    // + 0% cpu
    FlightMahWidget {
        id: flight_mah
    }

    // + 0% cpu
    FlightMahKmWidget {
        id: flight_mah_km
    }

    // + 0% cpu
    BitrateWidget {
        id: bitrate
    }

    // + 0% cpu
    ImuTempWidget {
        id: imu_temp
    }

    // + 0% cpu
    PressTempWidget {
        id: press_temp
    }

    // + 0% cpu
    EscTempWidget {
        id: esc_temp
    }

    // + 0% cpu
    AirStatusWidget {
        id: air_status
    }

    // + 0% cpu
    GroundStatusWidget {
        id: ground_status
    }

    // + 0% cpu
    DownlinkRSSIWidget {
        id: downlink
    }

    // + 0% cpu
    UplinkRSSIWidget {
        id: uplink
    }

    // + 0% cpu
    RcRSSIWidget {
        id: rcRSSIWidget
    }

    // + 12% cpu
    HorizonWidget {
        id: horizonWidget
    }

    // + 7% cpu
    FpvWidget {
        id: fpvWidget
    }

    // + 4% cpu
    AltitudeWidget {
        id: altitudeWidget
    }

    // + 0% cpu
    AltitudeSecondWidget {
        id: altitudesecondWidget
    }

    // + 17% cpu
    SpeedWidget {
        id: speedWidget
    }

    SpeedSecondWidget {
        id: speedSecondWidget
    }

    // +3% cpu
    HeadingWidget {
        id: headingWidget
    }

    // + 0% cpu
    ArrowWidget {
        id: arrowWidget
    }

    // + 0% cpu
    ThrottleWidget {
        id: throttleWidget
        scale: 0.7
    }

    // + 0% cpu
    ControlWidget {
        id: controlWidget
        //   scale: 0.7
    }

    // + 3% cpu
    Loader {
        source: EnablePiP ? "./widgets/VideoWidget.qml" : ""
    }

    // + 2% cpu
    MapWidget {
        id: mapWidget
    }

    // + 0% cpu
    GPIOWidget {
        id: gpioWidget
    }

    // + 3% cpu
    VibrationWidget {
        id: vibrationWidget
    }

    // + 6% cpu
    VsiWidget {
        id: vsiWidget
    }

    // + 0% cpu
    WindWidget {
        id: windWidget
    }

    // + 3% cpu
    RollWidget {
        id: rollWidget
    }

    // + 0% cpu
    BlackBoxWidget {
        id: blackboxWidget
    }

    // + 0% cpu
    AdsbWidget {
        id: adsbWidget
    }

    // UNTESTED CPU USAGE!!
    VROverlayWidget {
        id: vrOverlayWidget
    }

    MissionWidget {
        id: missionWidget
    }

    CameraWidget {
        id: cameraWidget
    }

    ExampleWidget {
        id: exampleWidget
    }
}



