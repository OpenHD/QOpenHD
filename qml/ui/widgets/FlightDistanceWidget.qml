import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightDistanceWidget
    width: 96
    height: 24

    visible: settings.show_flight_distance

    widgetIdentifier: "flight_distance_widget"
    bw_verbose_name: "TOTAL FLIGHT DISTANCE"

    defaultAlignment: 2
    defaultXOffset: 100
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    function get_text_flight_distance(){
        var distance = _fcMavlinkSystem.flight_distance_m / 1000.0
        var unit = "km"
        var use_imperial = settings.value("enable_imperial", false)
        // QML settings can return strings for booleans on some platforms so we check
        if (use_imperial === true || use_imperial === 1
                || use_imperial === "true") {
            unit = "mi"
            distance /= 1.609344
        }
        return distance.toLocaleString(Qt.locale(), "f", 1) + unit
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: bw_current_scale
        opacity: bw_current_opacity

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            clip: true
            color: settings.color_shape
            text: "\uf018"
            anchors.right: flight_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: flight_distance_text
            width: 68
            height: 24
            clip: true

            color: settings.color_text
            text: get_text_flight_distance()
            elide: Text.ElideNone
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
