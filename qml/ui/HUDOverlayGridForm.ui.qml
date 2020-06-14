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

    ExampleWidget {
        id: exampleWidget
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

