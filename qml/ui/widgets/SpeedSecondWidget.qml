import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedsecondWidget
    width: 80
    height: 25
    defaultAlignment: 3
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 128
    dragging: false

    visible: settings.show_speed_second && !sidebar.m_is_active

    widgetIdentifier: "speed_second_widget"
    bw_verbose_name: "SECOND SPEED"

    hasWidgetDetail: true

    function get_speed_number(){
        var speed_m_per_second=settings.speed_second_use_groundspeed ? _fcMavlinkSystem.ground_speed_meter_per_second : _fcMavlinkSystem.air_speed_meter_per_second;
        if(settings.enable_imperial){
            return speed_m_per_second*2.23694;
        }
        if(settings.speed_second_use_kmh){
            return speed_m_per_second*3.6;
        }
        return speed_m_per_second;
    }

    function get_speed_unit(){
        if(settings.enable_imperial){
            return " mph";
        }
        if(settings.speed_second_use_kmh){
            return " kph";
        }
        return " m/s";
    }

    function get_text_speed(){
        var speed = get_speed_number()
        var ret=Number(speed).toLocaleString( Qt.locale(), 'f', 0)
        if(settings.speed_second_show_unit && speed <99){
            ret+=get_speed_unit();
        }
        return ret;
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
                    text: qsTr("Use groundspeed")
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
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Use km/h")
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
                    checked: settings.speed_second_use_kmh
                    onCheckedChanged: settings.speed_second_use_kmh = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show unit")
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
                    checked: settings.speed_second_show_unit
                    onCheckedChanged: settings.speed_second_show_unit = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        scale: bw_current_scale

        Text {
            id: widgetGlyph
            width: 20
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
        }

        Text {
            id: second_alt_text
            color: settings.color_text
            opacity: bw_current_opacity
            font.pixelSize: 14
            font.family: settings.font_text
            width: 40
            anchors.left: widgetGlyph.right
            anchors.rightMargin: 0
            anchors.verticalCenter: widgetGlyph.verticalCenter
            text: get_text_speed()
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }

        antialiasing: true
    }
}
