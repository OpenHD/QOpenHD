import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: distancesensorwidget
    width: 40
    height: 25
    defaultAlignment: 3
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 128+40
    dragging: false

    visible: settings.show_distance_sensor_widget

    widgetIdentifier: "distance_sensor_widget"
    bw_verbose_name: "DISTANCE SENSOR"

    hasWidgetDetail: true

    // Number(
    //settings.enable_imperial ? (settings.speed_second_use_groundspeed ? _fcMavlinkSystem.speed * 0.621371 : _fcMavlinkSystem.airspeed * 0.621371) : (settings.speed_second_use_groundspeed ? _fcMavlinkSystem.speed : _fcMavlinkSystem.airspeed)).toLocaleString(
    //Qt.locale(), 'f', 0)

    function calc_distance(){
        var distance_cm=_fcMavlinkSystem.distance_sensor_distance_cm
        if(distance_cm===-1)return "N/A"
        return ""+_fcMavlinkSystem.distance_sensor_distance_cm*0.01+"m"
    }

    property string m_distance_m : calc_distance()

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: parent.width
                height: 32
                //
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        scale: bw_current_scale

        Text {
            id: second_alt_text
            color: settings.color_text
            opacity: bw_current_opacity
            font.pixelSize: 14
            font.family: settings.font_text
            width: 40
            anchors.left: parent.left
            anchors.rightMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            text: m_distance_m
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        /*Text {
            id: widgetGlyph
            width: 40
            height: parent.height
            color: settings.color_shape
            opacity: bw_current_opacity
            text: "\uf3fd"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }*/

        antialiasing: true
    }
}
