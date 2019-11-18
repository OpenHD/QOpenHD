import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import Qt.labs.settings 1.0

import "./widgets"

Item {

    property alias home_distance: home_distance
    property alias flight_timer: flight_timer
    property alias flight_mode: flight_mode
    property alias air_battery: air_battery
    property alias gps: gps

    property alias downlink: downlink
    property alias uplink: uplink
    property alias bitrate: bitrate
    property alias air_status: air_status
    property alias ground_status: ground_status
    property alias messageHUD: messageHUD

    property alias horizonWidget: horizonWidget
    property alias fpvWidget: fpvWidget

    property alias altitudeWidget: altitudeWidget
    property alias altitudesecondWidget: altitudesecondWidget
    property alias speedWidget: speedWidget
    property alias headingWidget: headingWidget
    property alias arrowWidget: arrowWidget

    property alias mapWidget: mapWidget

    property alias pipVideoWidget: pipVideoWidget

    MessageHUD {
        id: messageHUD
    }

    AirBatteryWidget {
        id: air_battery
    }

    FlightModeWidget {
        id: flight_mode
    }

    LatLonWidget {
        id: lat_lon
        visible: false
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

    VideoWidget {
        id: pipVideoWidget
        elementName: "pipVideoItem"
    }

    MapWidget {
        id: mapWidget
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

