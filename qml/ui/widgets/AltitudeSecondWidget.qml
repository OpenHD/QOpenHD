import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudesecondWidget
    width: 40
    height: 25
    defaultAlignment: 2
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 64
    dragging: false

    visible: settings.show_altitude_second

    widgetIdentifier: "altitude_second_widget"
    bw_verbose_name: "SECOND ALTITUDE"

    hasWidgetDetail: true

    function get_text_altitude(){
        var altitude_m=settings.altitude_second_msl_rel ? _fcMavlinkSystem.altitude_msl_m : _fcMavlinkSystem.altitude_rel_m;
        return Number(altitude_m).toLocaleString(Qt.locale(), 'f', 0)
    }

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
                    text: qsTr("Relative / MSL")
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
                    checked: settings.altitude_second_msl_rel
                    onCheckedChanged: settings.altitude_second_msl_rel = checked
                }
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
            anchors.left: widgetGlyph.right
            anchors.leftMargin: 0
            anchors.verticalCenter: widgetGlyph.verticalCenter
            text: get_text_altitude()
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: widgetGlyph
            width: 16
            height: parent.height
            color: settings.color_shape
            opacity: bw_current_opacity
            text: "\uf338"
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
