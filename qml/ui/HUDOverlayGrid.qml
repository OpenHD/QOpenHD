import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import OpenHD 1.0

import Qt.labs.settings 1.0

import "./widgets"
import "./widgets/map"
import "../resources" as Resources

Item {
    signal settingsButtonClicked

    property bool globalDragLock: false

    // Called by the config popup when closed to give focus back
    function regain_focus(){
        settingsButton.focus=true
    }

    Image {
        id: settingsButton
        width: 48
        height: 48
        fillMode: Image.PreserveAspectFit
        z: 2.2

        source: "../resources/ic128.png"
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 0
        focus: true
        Keys.onPressed: (event)=> {
                console.log("Key was pressed:"+event);
                if (event.key == Qt.Key_Return) {
                    console.log("enter was pressed");
                    event.accepted = true;
                    hudOverlayGrid.settingsButtonClicked();
                    //settingsButton.focus=false;
                }
            }
        MouseArea {
            id: settingsButtonMouseArea
            anchors.fill: parent

            onClicked: {
                hudOverlayGrid.settingsButtonClicked()
            }
        }
    }
    /*BusyIndicator{
        width: 48
        height: 48
        anchors.top: settingsButton.bottom
        anchors.topMargin: 5
        //running: false
    }*/

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
    FlightTimeWidget {
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


    VideoBitrateWidgetPrimary {
        id: bitrate1
    }
    VideoBitrateWidgetSecondary {
        id: bitrate2
    }

    // exp
    QRenderStatsWidget {
        id: qRenderStatsWidget
    }

    // + 0% cpu
    ImuTempWidget {
        id: imu_temp
    }

    // + 0% cpu
    PressTempWidget {
        id: press_temp
    }
    RCRssiWidget {
        id: rc_rssi_widget
    }

    AirspeedTempWidget {
        id: airspeed_temp
    }

    // + 0% cpu
    EscTempWidget {
        id: esc_temp
    }

    // + 0% cpu
    SOCStatusWidgetAir {
        id: air_status
    }

    // + 0% cpu
    SOCStatusWidgetGround {
        id: ground_status
    }

    // + 0% cpu
    LinkDownRSSIWidget {
        id: downlink
    }

    // + 0% cpu
    LinkUpRSSIWidget {
        id: uplink
    }

    // + 12% cpu
    HorizonWidget {
        id: horizonWidget
    }

    PerformanceHorizonWidget{
        id: performanceHorizonWidget
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

    // + 0% cpu
    GPIOWidget {
        id: gpioWidget
    }

    // + 3% cpu
    VibrationWidget {
        id: vibrationWidget
    }

    VerticalSpeedSimpleWidget{
        id: vssimpleWidget
    }
    VerticalSpeedGaugeWidget{
        id: vsgaugewidget
    }

    // + 0% cpu
    WindWidget {
        id: windWidget
    }

    // + 3% cpu
    RollWidget {
        id: rollWidget
    }

    MissionWidget {
        id: missionWidget
    }

    AoaWidget {
        id: aoaWidget
    }

    MapWidget {
        id: mapWidget
    }

    ExampleWidget {
        id: exampleWidget
    }
    RecordVideoWidget {
        id: record_video_widget
    }

    WBLinkRateControlWidget{
        id: wBLinkRateControlWidget
    }

    DistanceSensorWidget{
        id: distancesensorwidget
    }

    UAVTimeWiget{
        id: uavtimewidget
    }
}



