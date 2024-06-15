import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightTimeWidget
    width: 96
    height: 24

    visible: settings.show_flight_time && settings.show_widgets

    widgetIdentifier: "flight_time_widget"
    bw_verbose_name: "FLIGHT TIME"

    defaultAlignment: 2
    defaultXOffset: 0
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
            show_vertical_lock: true
            show_horizontal_lock: true
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: bw_current_scale

        Text {
            id: flight_time_text
            y: 0
            width: 64
            height: 24
            color: settings.color_text
            opacity: bw_current_opacity
            text: _fcMavlinkSystem.flight_time
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: time_icon
            x: 0
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: bw_current_opacity
            text: "\uf017"
            font.family: "Font Awesome 5 Free"
            anchors.right: flight_time_text.left
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            anchors.rightMargin: 6
            font.pixelSize: 14
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
