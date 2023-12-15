import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import QtQml 2.15

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: uavtmewidget
    width: 100
    height: 25
    defaultAlignment: 3
    defaultHCenter: false
    defaultVCenter: false
    defaultXOffset: 12
    defaultYOffset: 128+80
    dragging: false

    visible: settings.show_time_widget

    widgetIdentifier: "timer_widget"
    bw_verbose_name: "GPS TIME"

    hasWidgetDetail: true

    /*function get_time(){
        var unixTime=_fcMavlinkSystem.sys_time_unix_usec
        if(unixTime<1){
            return "Date N/A";
        }
        var timestamp=new QDateTime();
        //QDateTime timestamp;
        timestamp.setTime_t(unixTime);
        //return "TODO";
        return timestamp.toString(QSystemLocaleShortDate);
    }*/

    property string m_time: _fcMavlinkSystem.sys_time_unix_as_str //get_time()

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
            color: settings.color_text
            opacity: bw_current_opacity
            font.pixelSize: 14
            font.family: settings.font_text
            width: 40
            anchors.left: parent.left
            anchors.rightMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            text: m_time
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
