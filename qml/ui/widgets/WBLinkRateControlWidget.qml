import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {

    id: wblinkratewidget
    width: 90
    height: 40

    visible: settings.wb_link_rate_control_widget_show

    widgetIdentifier: "wb_link_rate_control_widget"
    bw_verbose_name: "WB LIVE RATE CONTROL"

    defaultAlignment: 0
    defaultXOffset: 400
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    property int m_widget_action_w:  256
    property int m_widget_action_h: 300;
    widgetActionWidth: m_widget_action_w
    widgetActionHeight: m_widget_action_h


    property int m_curr_mcs_index: _ohdSystemAir.curr_mcs_index

    property int m_curr_fec_perc: _cameraStreamModelPrimary.curr_fec_percentage
    property int m_curr_keyframe_i: _cameraStreamModelPrimary.curr_keyframe_interval

    function get_text_mcs(){
        return m_curr_mcs_index==-1 ? "MCS: NA" : "MCS: "+m_curr_mcs_index;
    }

    function get_text_fec_keyframe(){
        var ret=""
        if(m_curr_fec_perc==-1){
            ret+="N/A"
        }else{
            ret+=m_curr_fec_perc+"%"
        }
        ret+="-"
        if(m_curr_keyframe_i==-1){
            ret+="N/A"
        }else{
            ret+= m_curr_keyframe_i;
        }
        return ret;
    }

    function set_keyframe_interval(interval){
        var success=_airCameraSettingsModel.set_param_keyframe_interval(interval)
        if(success!==true){
            return;
        }
        if(settings.dev_qopenhd_n_cameras==2){
            _airCameraSettingsModel2.set_param_keyframe_interval(interval)
        }
    }
    function set_fec_percentage(percentage){
        var success=_airPiSettingsModel.set_param_fec_percentage(percentage)
    }


    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        width: parent.width
        height: parent.height

        ColumnLayout {
            width: 200
            height:  m_widget_action_h -30
            spacing: 10

            Rectangle{
                id: areaMCS
                width: parent.width
                height: parent.height /2;
                //color: "red"
                color: "black"
                ColumnLayout{
                    width: parent.width
                    height:  parent.height
                    spacing: 5
                    Item {
                        height: 32
                        width: parent.width
                        id: itemDescriptionMCS
                        Text {
                            id: simpleDescription
                            text: "Trade Range/Quality"
                            color: "white"
                            font.bold: true
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                        }
                        Button{
                            height: 32
                            width: 32
                            text: "\uf05a"
                            anchors.left: simpleDescription.right
                            anchors.top: simpleDescription.top
                            Material.background:Material.LightBlue
                            anchors.leftMargin: 5
                            onClicked: {
                                _messageBoxInstance.set_text_and_show("
By reducing the MCS (modulation and coding) index you increase range on the cost of less bitrate. You can change this
value during flight, either using this widget or conveniently from your RC using the channel switcher (see wiki). If you exceed the max range at a given MCS,
your loss quickly increases and the video stops - reduce the MCS to get more range and keep flying. NOTE:  Requires supported HW (see wiki).")
                            }
                        }
                    }
                    Item{
                        width: parent.width
                        height: parent.height -32;
                        id: itemMcsChoices
                        //color: "green"
                        GridLayout{
                            width: parent.width
                            height: parent.height
                            rows: 2
                            columns: 2
                            Button{
                                text: "MCS0"
                                onClicked: {
                                    _synchronizedSettings.change_param_air_only_mcs(0,true)
                                }
                                highlighted: m_curr_mcs_index==0
                            }
                            Button{
                                text: "MCS1"
                                onClicked: {
                                    _synchronizedSettings.change_param_air_only_mcs(1,true)
                                }
                                highlighted: m_curr_mcs_index==1
                            }
                            Button{
                                text: "MCS2"
                                onClicked: {
                                    _synchronizedSettings.change_param_air_only_mcs(2,true)
                                }
                                highlighted: m_curr_mcs_index==2
                            }
                            Button{
                                text: "MCS3"
                                onClicked: {
                                    _synchronizedSettings.change_param_air_only_mcs(3,true)
                                }
                                highlighted: m_curr_mcs_index==3
                            }
                        }
                    }
                }
            }
            Rectangle{
                id: areaKeyframe
                width: parent.width
                height: parent.height /2;
                //color: "green"
                color: "black"
                ColumnLayout{
                    width: parent.width
                    height:  parent.height
                    spacing: 5
                    Item {
                        height: 32
                        width: parent.width
                        id: itemDescriptionKeyframe
                        //anchors.top: itemMcsChoices.bottom
                        Text {
                            id: simpleDescriptionKeyframe
                            text: "Trade Quality/Stability"
                            color: "white"
                            font.bold: true
                            font.pixelSize: detailPanelFontPixels
                            anchors.left: parent.left
                        }
                        Button{
                            height: 32
                            width: 32
                            text: "\uf05a"
                            anchors.left: simpleDescriptionKeyframe.right
                            anchors.top: simpleDescriptionKeyframe.top
                            Material.background:Material.LightBlue
                            anchors.leftMargin: 5
                            onClicked: {
                                _messageBoxInstance.set_text_and_show("
Make the video more stable (less microfreezes) on the cost of less image quality.
Internally, this changes the encode keyframe interval and/ or FEC overhead in percent.")
                            }
                        }
                    }
                    Item{
                        width: parent.width
                        height: parent.height -32;
                        //color: "green"
                        GridLayout{
                            width: parent.width
                            height: parent.height
                            rows: 2
                            columns: 2
                            Button{
                                text: "POLLUTED"
                                onClicked: {
                                    set_keyframe_interval(2)
                                    set_fec_percentage(30)
                                }
                                highlighted:  m_curr_keyframe_i == 2 && m_curr_fec_perc==30
                            }
                            Button{
                                text: "CITY"
                                onClicked: {
                                    set_keyframe_interval(3)
                                    set_fec_percentage(30)
                                }
                                highlighted:  m_curr_keyframe_i == 3 && m_curr_fec_perc==30
                            }
                            Button{
                                text: "DEFAULT"
                                onClicked: {
                                    set_keyframe_interval(5)
                                    set_fec_percentage(20)
                                }
                                highlighted:  m_curr_keyframe_i == 5 && m_curr_fec_perc==20
                            }
                            /*Button{
                                text: "MISSION"
                                onClicked: {
                                    set_keyframe_interval(10)
                                    set_fec_percentage(10)
                                }
                                highlighted:  m_curr_keyframe_i == keyframe && m_curr_fec_perc==fec_p
                            }*/
                        }
                    }
                }
            }

        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        scale: bw_current_scale

        Item {
            anchors.fill: parent
            anchors.centerIn: parent

            Text {
                id: mcsText
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: get_text_mcs()
                anchors.top: parent.top
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Text {
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: get_text_fec_keyframe()
                //anchors.bottom: parent.bottom
                //anchors.bottomMargin: 0
                anchors.left: parent.left
                anchors.top: mcsText.bottom
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }

        }
    }
}
