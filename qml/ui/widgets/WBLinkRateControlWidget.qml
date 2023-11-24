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
    defaultXOffset: 320
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    property int m_widget_action_w:  256
    property int m_widget_action_h: 300;
    widgetActionWidth: m_widget_action_w
    widgetActionHeight: m_widget_action_h

    property int m_curr_channel_width: _ohdSystemAir.curr_channel_width_mhz
    property int m_curr_mcs_index: _ohdSystemAir.curr_mcs_index
    property int m_curr_bitrate_kbits: _ohdSystemAir.curr_bitrate_kbits

    property int m_curr_fine_adjustments: _ohdSystemAir.curr_n_rate_adjustments

    property int m_curr_fec_perc: _cameraStreamModelPrimary.curr_fec_percentage
    property int m_curr_keyframe_i: _cameraStreamModelPrimary.curr_keyframe_interval

    //property bool m_is_armed: true
    property bool m_is_armed: _fcMavlinkSystem.armed

    property int m_row_height: 50


    ListModel{
        id: mcs_model
        ListElement {title: "MCS0 (LONG RANGE)"; value: 0}
        ListElement {title: "MCS1 (RANGE)"; value: 1}
        ListElement {title: "MCS2 (DEFAULT)"; value: 2}
        ListElement {title: "MCS3 (EXPERIMENTAL)"; value: 3}
        ListElement {title: "MCS4 (EXPERIMENTAL)"; value: 4}
    }
    ListModel{
        id: stability_model
        ListElement {title: "30%:2 POLLUTED"; value_fec: 30; value_keyframe: 2}
        ListElement {title: "30%:3 CITY"; value_fec: 30; value_keyframe: 3}
        ListElement {title: "20%:5 DEFAULT"; value_fec: 20; value_keyframe: 5}
        //ListElement {title: "10%:5 DESERT"; value_fec: 10; value_keyframe: 5}
    }

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
        _wbLinkSettingsHelper.set_param_keyframe_interval_async(interval)
    }
    function set_fec_percentage(percentage){
        _wbLinkSettingsHelper.set_param_fec_percentage_async(percentage)
    }
    function set_air_only_mcs(mcs_index){
        _wbLinkSettingsHelper.set_param_air_only_mcs_async(mcs_index)
    }

    function set_channel_width_async(channel_width_mhz){
        if(!_ohdSystemAir.is_alive){
            _hudLogMessagesModel.add_message_warning("Cannot change BW:"+channel_width_mhz+"Mhz, AIR not alive");
            return;
        }
        _wbLinkSettingsHelper.change_param_air_channel_width_async(channel_width_mhz,true);
    }
    function get_rate_for_mcs(mcs,is_40mhz){
        if(is_40mhz){
            if(mcs==0) return 7.4;
            if(mcs==1) return 15.3;
            if(mcs==2) return 22.6;
            if(mcs==3) return 25;
            if(mcs==4) return 30;
        }
        if(mcs==0) return 4.7;
        if(mcs==1) return 9.8;
        if(mcs==2) return 13;
        if(mcs==3) return 16.2;
        if(mcs==4) return 20;
        return -1;
    }
    function get_mcs_combobox_text(mcs){
        for(var i = 0; i < mcs_model.count; ++i) {
            if (mcs_model.get(i).value==mcs) return mcs_model.get(i).title
        }
        return "MCS "+m_curr_mcs_index;
    }

    function get_fec_keyframe_combobox_text(fec,keyframe){
        for(var i = 0; i < stability_model.count; ++i) {
            if (stability_model.get(i).value_fec==fec && stability_model.get(i).value_keyframe==keyframe) return stability_model.get(i).title
        }
        return "FEC:"+fec+"% : KEY:"+keyframe+" ?";
    }

    property string m_DESCRIPTION_CHANNEL_WIDTH: "
A higher bandwidth / 40Mhz channel width increases the bitrate significantly, but also increases interference and reduces the maximum range."+
"It is recommended to use a 40Mhz channel width if possible,"+
"and controll the MCS index for fine adjustments."

    property string m_DESCRIPTION_MCS: "
The lower the MCS (Modulation and coding) index, the less signal (dBm) is required to pick up data."+
"This means that with a lower MCS index, you have a much greater range (but less bitrate).If you want to, you can change this value using the RC channel switcher -"+
"this allows you to quickly select a lower MCS index during flight (e.g. if you want to fly further or encounter issues like your plane going out of the corridor of your antenna tracker.)"

    property string m_DESCRIPTION_STABILITY: "
Make the video more stable (less microfreezes) on the cost of less image quality."+
"Internally, this changes the encode keyframe interval and/ or FEC overhead in percent. DEFAULT is a good trade off regarding image quality and stability"+
"and works in most cases. Use CITY/POLLUTED on polluted channels,but it is always better to find a free channel."

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
                    text: qsTr("Show throttle warning")
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
                    checked: settings.wb_link_rate_control_widget_show_throttle_warning
                    onCheckedChanged: settings.wb_link_rate_control_widget_show_throttle_warning = checked
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
    widgetActionComponent:
        Column {
        width: m_widget_action_w-32
        SmallHeaderInfoRow{
            m_text: "Range vs Bitrate"
            m_info_text: m_DESCRIPTION_CHANNEL_WIDTH
        }
        /*TabBar{
                width: parent.width
                height: m_row_height
                id: channel_width_tab_bar
                currentIndex:  m_curr_channel_width==40 ? 1 : 0;
                onCurrentIndexChanged: {
                    //const chan_w= currentIndex==0 ? 20 : 40;
                    //set_channel_width_async(20)
                }
                TabButton{
                    text: "20Mhz"
                    onClicked: {
                        set_channel_width_async(20)
                    }
                }
                TabButton{
                    text: "40Mhz"
                    onClicked: {
                        set_channel_width_async(40)
                    }
                }
            }*/
        Row{
            width: parent.width
            height: m_row_height
            spacing: 20
            Button{
                text: "20Mhz"
                onClicked: {
                    set_channel_width_async(20)
                }
                highlighted: m_curr_channel_width==20
                //enabled: _ohdSystemAir.is_alive;
            }
            Button{
                text: "40Mhz"
                onClicked: {
                    set_channel_width_async(40)
                }
                highlighted:  m_curr_channel_width==40
                //enabled: _ohdSystemAir.is_alive;
            }
        }
        SmallHeaderInfoRow{
            m_text: "Range vs Bitrate"
            m_info_text: m_DESCRIPTION_MCS
        }
        Row{
            width: parent.width
            height: m_row_height

            ComboBox{
                width: parent.width
                height: m_row_height
                id: mcs_cb
                model: mcs_model
                textRole: "title"
                currentIndex: -1
                displayText: {
                    if(!_ohdSystemAir.is_alive)return "AIR NOT ALIVE";
                    return get_mcs_combobox_text(m_curr_mcs_index);
                    //return "MCS "+m_curr_mcs_index+" / "+get_rate_for_mcs(m_curr_mcs_index,m_curr_channel_width==40)+" MBit/s"
                }
                onActivated: {
                    console.log("onActivated:"+currentIndex);
                    if(currentIndex<0)return;
                    const mcs=model.get(currentIndex).value
                    set_air_only_mcs(mcs)
                }
                onDisplayTextChanged: {
                    for(var i = 0; i < model.count; ++i) {
                        if (model.get(i).value==m_curr_mcs_index){
                            currentIndex=i;
                        }
                    }
                }
                enabled: _ohdSystemAir.is_alive;
            }
        }
        SmallHeaderInfoRow{
            m_text: "Resiliency vs Bitrate"
            m_info_text:m_DESCRIPTION_STABILITY
        }
        Row{
            width: parent.width
            height: m_row_height
            ComboBox{
                width: parent.width
                height: m_row_height
                id: pollution_cb
                model: stability_model
                textRole: "title"
                currentIndex: -1
                displayText: {
                    if(!_ohdSystemAir.is_alive)return "AIR NOT ALIVE";
                    return get_fec_keyframe_combobox_text(m_curr_fec_perc,m_curr_keyframe_i)
                }
                onActivated: {
                    console.log("onActivated:"+currentIndex);
                    if(currentIndex<0)return;
                    const fec=model.get(currentIndex).value_fec
                    const key=model.get(currentIndex).value_keyframe
                    set_fec_percentage(fec)
                    set_keyframe_interval(key)
                }
                onDisplayTextChanged: {
                    for(var i = 0; i < model.count; ++i) {
                        if (model.get(i).value_fec==m_curr_fec_perc && model.get(i).value_keyframe==m_curr_keyframe_i){
                            currentIndex=i;
                        }
                    }
                }
                enabled: _ohdSystemAir.is_alive;
            }
        }
    }


    Item {
        id: widgetInner
        anchors.fill: parent
        scale: bw_current_scale

        Column {
            anchors.top: widgetInner.top
            width: parent.width

            Text {
                id: channelText
                y: 0
                width: parent.width
                color: settings.color_text
                text: get_text_channel()
                verticalAlignment: Text.AlignVCenter
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
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.wb_link_rate_control_widget_show_bitrate
            }
            Text {
                id: fec_keyfra
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: get_text_fec_keyframe()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.wb_link_rate_control_widget_show_fec_and_keyframe
            }
            Text{
                width: parent.width
                height: 14
                color: settings.color_warn
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
                visible: settings.wb_link_rate_control_widget_show_throttle_warning
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if(_ohdSystemAir.is_alive && _ohdSystemAir.curr_n_rate_adjustments>0){
                        return "THROTTLED";
                    }
                    return "";
                }
            }

        }
    }
}
