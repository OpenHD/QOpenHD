import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

import QtCharts 2.0

Rectangle{
    width: parent.width
    height: parent.height /2
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    //color: "#8cbfd7f3"
    color: "#ADD8E6"

    function open(){
        visible=true
    }

    function close(){
        visible=false;
    }

    function update(){
        pollution_chart.update_pollution_graph();
    }

    property string m_info_string: "Analyze channels for pollution by wifi access points."+
"NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended."+
"PLEASE DO NOT CHANGE SETTINGS WHILE ANALYZING."


    ChartView {
        title: "WiFi pollution estimate"
        width: parent.width
        height: parent.height
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        anchors.centerIn: parent
        id: pollution_chart

        function update_pollution_graph(){
            //const frequencies_list = _wbLinkSettingsHelper.get_pollution_qstringlist();
            //bar_axis_x.categories=frequencies_list;
            //const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies();
            const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies_filtered(1);
            var categories = _wbLinkSettingsHelper.pollution_frequencies_int_to_qstringlist(supported_frequencies);
            var values = _wbLinkSettingsHelper.pollution_frequencies_int_get_pollution(supported_frequencies);
            bar_axis_x.categories=categories;
            bar_set.values=values;
            /*const supported_frequencies=_wbLinkSettingsHelper.get_supported_frequencies();
            bar_axis_x.categories.clear();
            for(var i=0;i<supported_frequencies.length;i++){
                bar_axis_x.categories.append(""+supported_frequencies.at(i));
            }*/
        }

        BarSeries {
            id: hm_bar_series
            axisX: BarCategoryAxis {
                id: bar_axis_x
                categories: ["DUMMY0", "DUMMY1", "DUMMY3", "DUMMY4" ]
                //min: "0"
                //max: "500"
            }
            BarSet {
                id: bar_set
                label: "Pollution (pps)";
                values: [5,10,3,100]
                //values: [0,0,0,0]
                color: "red"
            }
        }
    }
    Button{
        text: "CLOSE"
        anchors.top: parent.top
        anchors.right: parent.right
        onClicked: {
            close()
        }
    }

    RowLayout{
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        Button{
            text: "START"
            onClicked: {
                var result=_wbLinkSettingsHelper.start_analyze_channels()
                if(result!==true){
                    _qopenhd.show_toast("Busy,please try again later",true);
                }else{
                    _qopenhd.show_toast("Analyze channels started, please wait");
                }
            }
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
        }
        ButtonIconInfo{
            onClicked: {
                _messageBoxInstance.set_text_and_show(m_info_string)
            }
        }
    }
}

