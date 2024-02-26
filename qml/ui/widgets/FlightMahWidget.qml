import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightMahWidget
    width: 96
    height: 24

    visible: settings.show_flight_mah

    widgetIdentifier: "flight_mah_widget"
    bw_verbose_name: "MAH (FC CONSUMED)"

    defaultAlignment: 3
    defaultXOffset: 110
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

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

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            clip: true
            color: settings.color_shape
            opacity: bw_current_opacity
            text: "\uf0e7"
            anchors.right: flight_mah_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: flight_mah_text
            width: 68
            height: 24
            clip: false
            color: settings.color_text
            opacity: bw_current_opacity
            text:  _fcMavlinkSystem.battery_consumed_mah+ "mAh"
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

