import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: vsiWidget
    width: 64
    height: 25

    defaultAlignment: 2
    //defaultXOffset: 40
    //defaultYOffset: 100
    defaultXOffset: 12
    defaultYOffset: 64+20

    defaultHCenter: false
    defaultVCenter: false

    visible: settings.show_vertical_speed_simple_widget

    widgetIdentifier: "vertical_speed_simple_widget"
    bw_verbose_name: "VERTICAL SPEED (CLIMB)"

    property double m_vertical_speed_m_per_second: _fcMavlinkSystem.vertical_speed_indicator_mps

    function get_v_speed_number(){
        var vertical_speed_m_per_second=_fcMavlinkSystem.vertical_speed_indicator_mps
        if(settings.enable_imperial){
            // feet per second
            return vertical_speed_m_per_second*3.28084;
        }
        return vertical_speed_m_per_second;
    }

    function get_v_speed_unit(){
        if(settings.enable_imperial){
            return " ft/s";
        }
        return " m/s";
    }

    function get_text_vertical_speed(){
        var vert_speed = get_v_speed_number()
        if(settings.vertical_speed_simple_widget_show_up_down_arrow){
            // remove the "-" since we show a icon instead
            if(vert_speed<0){
                vert_speed*=-1;
            }
        }
        var ret=Number(vert_speed).toLocaleString( Qt.locale(), 'f', 0)
        if(settings.vertical_speed_simple_widget_show_unit && vert_speed <99){
            ret+=get_v_speed_unit();
        }
        return ret;
    }

    function get_text_icon_vertical_speed(){
        var vert_speed=get_v_speed_number()
        if(vert_speed>0.0){
            return "\uf062";
        }else if(vert_speed<0.0){
            return "\uf063";
        }
        return "";
    }

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_vertical_lock: true

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show unit")
                    horizontalAlignment: Text.AlignRight
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.vertical_speed_simple_widget_show_unit
                    onCheckedChanged: settings.vertical_speed_simple_widget_show_unit = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show up / down arrow")
                    horizontalAlignment: Text.AlignRight
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.vertical_speed_simple_widget_show_up_down_arrow
                    onCheckedChanged: settings.vertical_speed_simple_widget_show_up_down_arrow = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Text {
            id: speedtext
            anchors.fill: parent
            anchors.centerIn: parent
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            text: get_text_vertical_speed();
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
        // This is an 'icon' indication movement up / down
        Text{
            height: parent.height
            width: parent.width / 3;
            anchors.right: speedtext.left
            anchors.bottom: speedtext.bottom
            color: settings.color_shape
            font.pixelSize: 14
            font.family: "Font Awesome 5 Free"
            text: get_text_icon_vertical_speed()
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
            visible: settings.vertical_speed_simple_widget_show_up_down_arrow
        }
    }
}
