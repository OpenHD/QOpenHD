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
    signal settingsButtonClicked();

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
                hudOverlayGrid.settingsButtonClicked();
            }
        }
    }


    MessageHUD {
        id: messageHUD
    }

    AirBatteryWidget {
        id: air_battery
    }

    FlightModeWidget {
        id: flight_mode
    }

    GPSWidget {
        id: gps
    }

    HomeDistanceWidget {
        id: home_distance
    }

    FlightTimerWidget {
        id: flight_timer
    }

    FlightDistanceWidget {
            id: flight_distance
        }

    FlightMahWidget {
            id: flight_mah
        }

    BitrateWidget {
        id: bitrate
    }

    FcTempWidget {
        id: fc_temp
    }

    AirStatusWidget {
        id: air_status
    }

    GroundStatusWidget {
        id: ground_status
    }

    DownlinkRSSIWidget {
        id: downlink
    }

    UplinkRSSIWidget {
        id: uplink
    }

    RcRSSIWidget {
        id: rcRSSIWidget
    }

    HorizonWidget {
        id: horizonWidget
    }

    FpvWidget {
        id: fpvWidget
    }

    AltitudeWidget {
        id: altitudeWidget
    }

    AltitudeSecondWidget {
        id: altitudesecondWidget
    }

    SpeedWidget {
        id: speedWidget
    }

    HeadingWidget {
        id: headingWidget
    }

    ArrowWidget {
        id: arrowWidget
    }

    ThrottleWidget {
        id: throttleWidget
        scale: 0.7
    }

    ControlWidget {
        id: controlWidget
     //   scale: 0.7
    }

    Loader {
        source: EnablePiP ? "./widgets/VideoWidget.qml" : ""
    }

    MapWidget {
        id: mapWidget
    }

    GPIOWidget {
        id: gpioWidget
    }

    VibrationWidget {
        id: vibrationWidget
    }

    VsiWidget {
        id: vsiWidget
    }

    WindWidget {
        id: windWidget
    }

    RollWidget {
        id: rollWidget
    }

    BlackBoxWidget {
        id: blackboxWidget
    }

    AdsbWidget {
        id: adsbWidget
    }

    ExampleWidget {
        id: exampleWidget
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

