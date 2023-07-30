import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

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

    function get_text_vertical_speed(){
        var vertical_speed_m_per_second=_fcMavlinkSystem.vertical_speed_indicator_mps
        var vs_as_str=Number(vertical_speed_m_per_second).toLocaleString(Qt.locale(), 'f', 1);
        if(settings.vertical_speed_simple_widget_show_unit){
            vs_as_str+=" m/s";
        }
        if(vertical_speed_m_per_second>0.01){
            return "+"+vs_as_str;
        }else if(vertical_speed_m_per_second<-0.01){
            return vs_as_str;
        }
        return vs_as_str;
    }

    function get_text_icon_vertical_speed(){
        var vertical_speed_m_per_second=_fcMavlinkSystem.vertical_speed_indicator_mps
        if(vertical_speed_m_per_second>=0.01){
            return "\uf062";
        }else if(vertical_speed_m_per_second<=0.01){
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
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.vertical_speed_simple_widget_show_unit
                    onCheckedChanged: settings.vertical_speed_simple_widget_show_unit = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        Text {
            id: speedtext
            anchors.fill: parent
            anchors.centerIn: parent
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            text: get_text_vertical_speed()
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text{
            anchors.right: speedtext.left
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            text: get_text_icon_vertical_speed()
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
