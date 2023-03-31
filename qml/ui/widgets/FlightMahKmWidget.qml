import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightMahKmWidget
    width: 130
    height: 24

    visible: settings.show_flight_mah_km

    widgetIdentifier: "flight_mah_km_widget"
    bw_verbose_name: "EFFICIENCY IN MAH/KM"

    defaultAlignment: 3
    defaultXOffset: 220
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property int curr_mah_per_km: _fcMavlinkSystem.battery_consumed_mah_per_km

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
        scale: settings.mah_km_size

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            clip: true
            color: settings.color_shape
            opacity: settings.mah_km_opacity
            text: "\uf0e7"
            anchors.right: flight_mah_km_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text {
            id: flight_mah_km_text
            width: 102
            height: 24
            clip: true
            color: settings.color_text
            opacity: settings.mah_km_opacity
            text: (curr_mah_per_km > 0)
                  && (curr_mah_per_km < 999) ? (curr_mah_per_km + "mAh/km") : "---mAh/km"
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
