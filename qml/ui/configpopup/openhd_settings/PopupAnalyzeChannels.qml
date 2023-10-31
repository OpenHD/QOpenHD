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
    id: main_background
    //width: parent.width-12
    //height: parent.height*2/3;
    width: parent.width
    height: parent.height
    anchors.centerIn: parent
    color: "#ADD8E6"
    border.color: "black"
    border.width: 3

    property bool m_normalize_data: false;
    property int m_chart_view_minimum_width: 1280-200;

    function open(){
        visible=true
    }

    function close(){
        visible=false;
    }

    function update(){
        pollution_chart.update_pollution_graph();
    }

    property string m_info_string: "Analyze channels for pollution by wifi access points.\n"+
"NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended !\n"+
"In short: Any frequency with red bars (small or big) should not be used, unless there are no options / other reasons to do so."

    GridLayout{
        id: top_elements
        //width: parent.width
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 5


        Text{ // TITLE
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.minimumHeight: 20
            text: "ANALYZE CHANNELS (POLLUTION)";
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
        }

        Button{
            Layout.row: 0
            Layout.column: 3
            Layout.alignment: Qt.AlignRight
            text: "CLOSE"
            onClicked: {
                if(_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==2){
                    _qopenhd.show_toast("STILL ANALYZING, PLEASE WAIT ...",);
                    return;
                }
                close()
            }
        }
        SimpleProgressBar{
            Layout.row: 1
            Layout.column: 0
            Layout.preferredWidth: 400
            Layout.minimumWidth: 100
            Layout.preferredHeight: 40
            impl_curr_progress_perc: _wbLinkSettingsHelper.analyze_progress_perc
            impl_show_progress_text: true
        }
        Button{
            Layout.row: 1
            Layout.column: 1
            Layout.alignment: Qt.AlignLeft
            text: "START"
            onClicked: {
                var result=_wbLinkSettingsHelper.start_analyze_channels()
                if(result!==true){
                    _qopenhd.show_toast("Busy,please try again later",true);
                }else{
                    _qopenhd.show_toast("STARTED, THIS MIGHT TAKE A WHILE !");
                }
            }
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
        }
        Text{
            Layout.row: 2
            Layout.column: 0
            Layout.preferredWidth: 200
            Layout.minimumWidth: 50
            text: {
                if(_wbLinkSettingsHelper.current_analyze_frequency<=0){
                    return "";
                }
                return "Analyzed "+_wbLinkSettingsHelper.current_analyze_frequency+" Mhz ...";
            }
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
        }

        Switch{
            Layout.row: 2
            Layout.column: 1
            text: "NORMALIZE"
            checked: m_normalize_data
            onCheckedChanged: {
                m_normalize_data=checked
                pollution_chart.update_pollution_graph();
            }
        }
        ButtonIconInfo{
            Layout.row: 2
            Layout.column: 2
            Layout.alignment: Qt.AlignLeft
            onClicked: {
                _messageBoxInstance.set_text_and_show(m_info_string)
            }
        }
        // Filler
        Item{
            Layout.fillWidth: true
        }
    }

    ScrollView{
        anchors.top: top_elements.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: pollution_chart.width
        ScrollBar.horizontal.interactive: true

        ChartView {
            id: pollution_chart
            title: "WiFi pollution estimate"
            width: main_background.width>m_chart_view_minimum_width ? main_background.width : m_chart_view_minimum_width;
            height: parent.height
            legend.alignment: Qt.AlignBottom
            antialiasing: true

            function update_pollution_graph(){
                //const frequencies_list = _wbLinkSettingsHelper.get_pollution_qstringlist();
                //bar_axis_x.categories=frequencies_list;
                //const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies();
                const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies_filtered(1);
                var categories = _wbLinkSettingsHelper.pollution_frequencies_int_to_qstringlist(supported_frequencies);
                var values = _wbLinkSettingsHelper.pollution_frequencies_int_get_pollution(supported_frequencies,m_normalize_data);
                bar_axis_x.categories=categories;
                bar_set.values=values;
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
    }


}

