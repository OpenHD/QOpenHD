import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedsecondWidget
    width: 40
    height: 25
    defaultAlignment: 3
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 128
    dragging: false

    visible: settings.show_speed_second

    widgetIdentifier: "speed_second_widget"
    bw_verbose_name: "SECOND SPEED"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: parent.width
                height: 32
                Text {
                    id: mslTitle
                    text: qsTr("Airspeed / Groundspeed")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.speed_second_use_groundspeed
                    onCheckedChanged: settings.speed_second_use_groundspeed = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        scale: settings.speed_second_size

        Text {
            id: second_alt_text
            color: settings.color_text
            opacity: settings.speed_second_opacity
            font.pixelSize: 14
            font.family: settings.font_text
            width: 40
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.verticalCenter: widgetGlyph.verticalCenter
            text: Number(
                      settings.enable_imperial ? (settings.speed_second_use_groundspeed ? _fcMavlinkSystem.speed * 0.621371 : _fcMavlinkSystem.airspeed * 0.621371) : (settings.speed_second_use_groundspeed ? _fcMavlinkSystem.speed : _fcMavlinkSystem.airspeed)).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: widgetGlyph
            width: 40
            height: parent.height
            color: settings.color_shape
            opacity: settings.speed_second_opacity
            text: "\uf3fd"
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        antialiasing: true
    }
}
