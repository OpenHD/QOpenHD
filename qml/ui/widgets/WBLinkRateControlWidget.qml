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
    property int m_curr_bitrate_kbits: _ohdSystemAir.curr_bitrate_kbits

    property int m_curr_fine_adjustments: _ohdSystemAir.curr_n_rate_adjustments

    property int m_curr_fec_perc: _cameraStreamModelPrimary.curr_fec_percentage
    property int m_curr_keyframe_i: _cameraStreamModelPrimary.curr_keyframe_interval


    function get_text_channel(){
        if(!settings.wb_link_rate_control_widget_show_frequency){
            return "";
        }
        var ret="";
        var curr_channel_mhz = _ohdSystemGround.curr_channel_mhz;
        if(curr_channel_mhz>10){
            ret+=curr_channel_mhz;
        }else{
            ret+="Chan N/A";
        }
        if(_ohdSystemGround.curr_channel_width_mhz==40){
            ret+= " 40Mhz";
        }else if(_ohdSystemGround.curr_channel_width_mhz==20){
            ret+=" 20Mhz";
        }else{
            ret +=" N/A";
        }
        //ret+=" Mhz";
        return ret;
    }


    function bitrate_kbits_readable(kbits){
        var mbits=kbits/1000.0;
        if(mbits<10){
            return Number(mbits).toLocaleString(Qt.locale(), 'f', 1)+"MBit/s"
        }
        return Number(mbits).toLocaleString(Qt.locale(), 'f', 0)+"MBit/s"
    }

    function get_text_bitrate_mcs(){
        if(m_curr_bitrate_kbits==-1 || m_curr_mcs_index==-1){
            return "RATE N/A";
        }
        return bitrate_kbits_readable(m_curr_bitrate_kbits)+" ["+m_curr_mcs_index+"]"
    }

    function get_text_mcs(){
        return m_curr_mcs_index==-1 ? "MCS: NA" : "MCS: "+m_curr_mcs_index;
    }

    function get_text_detailed_bitrate(){
        if(m_curr_bitrate_kbits<=0){
            return "RATE N/A";
        }
        var ret=bitrate_kbits_readable(m_curr_bitrate_kbits);
        //if(m_curr_fine_adjustments>0){
            var fine_readable="-"+m_curr_fine_adjustments;
            ret+=fine_readable;
        //}
        ret += (" ["+m_curr_mcs_index+"]");
        return ret;
    }

    function get_text_bitrate(){
        if(settings.wb_link_rate_control_widget_show_bitrate_detailed){
            //return get_text_bitrate_mcs()
            return get_text_detailed_bitrate()
        }
        return get_text_bitrate_mcs()
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
             _hudLogMessagesModel.signalAddLogMessage(6,"cannot set cam1 keyframe interval")
            return;
        }
        if(settings.dev_qopenhd_n_cameras==2){
            _airCameraSettingsModel2.set_param_keyframe_interval(interval)
             _hudLogMessagesModel.signalAddLogMessage(6,"cannot set cam2 keyframe interval")
        }
    }
    function set_fec_percentage(percentage){
        var success=_airPiSettingsModel.set_param_fec_percentage(percentage)
        if(success!==true){
             _hudLogMessagesModel.signalAddLogMessage(6,"cannot set fec percentage")
        }
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
                    text: qsTr("Show frequency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wb_link_rate_control_widget_show_frequency
                    onCheckedChanged: settings.wb_link_rate_control_widget_show_frequency = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show bitrate")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wb_link_rate_control_widget_show_bitrate
                    onCheckedChanged: settings.wb_link_rate_control_widget_show_bitrate = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show fec and keyframe")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wb_link_rate_control_widget_show_fec_and_keyframe
                    onCheckedChanged: settings.wb_link_rate_control_widget_show_fec_and_keyframe = checked
                }
            }


            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Bitrate show detailed")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wb_link_rate_control_widget_show_bitrate_detailed
                    onCheckedChanged: settings.wb_link_rate_control_widget_show_bitrate_detailed = checked
                }
            }
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
Internally, this changes the encode keyframe interval and/ or FEC overhead in percent. DEFAULT is a good trade off regarding image quality and stability
and works in most cases. Use CITY/POLLUTED on polluted channels, DESERT if you have a completely clean channel.")
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
                                    set_fec_percentage(40)
                                }
                                highlighted:  m_curr_keyframe_i == 2 && m_curr_fec_perc==40
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
                            Button{
                                text: "DESERT"
                                onClicked: {
                                    set_keyframe_interval(8)
                                    set_fec_percentage(10)
                                }
                                highlighted:  m_curr_keyframe_i == 8 && m_curr_fec_perc==10
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
                id: channelText
                y: 0
                width: parent.width
                height: parent.height / 3
                color: settings.color_text
                text: get_text_channel()
                anchors.top: parent.top
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.wb_link_rate_control_widget_show_frequency
            }

            Text {
                id: mcsText
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: get_text_bitrate()
                anchors.top: channelText.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.wb_link_rate_control_widget_show_bitrate
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
                visible: settings.wb_link_rate_control_widget_show_fec_and_keyframe
            }

        }
    }
}
