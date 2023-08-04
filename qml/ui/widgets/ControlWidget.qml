import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: controlWidget
    width: 100
    height: 50

    visible: settings.show_control

    widgetIdentifier: "control_widget"
    bw_verbose_name: "CONTROL INPUTS"

    defaultAlignment: 1
    defaultXOffset: 20
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    // Assumes AETR
    property int m_control_yaw : settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_yaw : _rcchannelsmodelground.control_yaw
    property int m_control_roll: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_roll : _rcchannelsmodelground.control_roll
    property int m_control_pitch: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_pitch : _rcchannelsmodelground.control_pitch
    property int m_control_throttle: settings.control_widget_use_fc_channels ? _rcchannelsmodelfc.control_throttle : _rcchannelsmodelground.control_throttle

    function scale_ppm_us(value){
        if(value==-1)return 0; // N/A
        if(value<500){
            return -1;
        }
        if(value>2500){
            return 1;
        }
        if(value==0)return 0;
        return ((value-1500)/1000);
    }

    function get_scaled_yaw(){
        var tmp=scale_ppm_us(m_control_yaw);
        if(settings.control_rev_yaw){
            tmp*=-1;
        }
        return tmp;
    }
    function get_scaled_roll(){
        var tmp=scale_ppm_us(m_control_roll);
        if(settings.control_rev_roll){
            tmp*=-1;
        }
        return tmp;
    }
    function get_scaled_pitch(){
        var tmp=scale_ppm_us(m_control_pitch);
        if(settings.control_rev_pitch){
            tmp*=-1;
        }
        return tmp;
    }
    function get_scaled_throttle(){
        var tmp=scale_ppm_us(m_control_throttle);
        if(settings.control_rev_throttle){
            tmp*=-1;
        }
        return tmp;
    }


    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: 240
                height: 32
                Text {
                    id: displaySwitcher
                    text: qsTr("Show two controls")
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
                    checked: settings.double_control
                    onCheckedChanged: settings.double_control = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Use FC channels")
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
                    checked: settings.control_widget_use_fc_channels
                    onCheckedChanged: settings.control_widget_use_fc_channels = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Pitch")
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
                    checked: settings.control_rev_pitch
                    onCheckedChanged: settings.control_rev_pitch = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Roll")
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
                    checked: settings.control_rev_roll
                    onCheckedChanged: settings.control_rev_roll = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse yaw")
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
                    checked: settings.control_rev_yaw
                    onCheckedChanged: settings.control_rev_yaw = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Throttle")
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
                    checked: settings.control_rev_throttle
                    onCheckedChanged: settings.control_rev_throttle = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        height: parent.height
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        opacity: bw_current_opacity
        scale: bw_current_scale

        antialiasing: true

        ControlWidgetSubElement{
            id: elementLeft
            height: parent.height
            width: elementLeft.height
            anchors.left: parent.left

            position_x: get_scaled_pitch()
            position_y: get_scaled_throttle()
            //position_x: 1.0
            //position_y: 1.0
        }

        ControlWidgetSubElement{
            id: elementRight
            height: parent.height
            width: elementLeft.height
            visible: settings.double_control
            anchors.left: elementLeft.right

            position_x: get_scaled_yaw()
            position_y: get_scaled_roll()
        }
    }
}
