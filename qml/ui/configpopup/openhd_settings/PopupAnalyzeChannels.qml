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

import QtCharts 2.15

Rectangle{
    id: main_background
    width: parent.width - 20
    height: parent.height -20
    anchors.centerIn: parent
    color: "#333c4c"


    property bool m_normalize_data: false;
    property int m_chart_view_minimum_width: 1280;
    property int m_chart_view_minimum_width2: 1280;

    property bool m_chart_enlarged: false;

    function open(){
        visible=true
    }

    function close(){
        visible=false;
    }

    function update(){
        pollution_chart.update_pollution_graph();
    }

    ListModel{
        id: model_filter
        ListElement {title: "NO FILTER"; value: 0}
        ListElement {title: "2.4G ONLY"; value: 1}
        ListElement {title: "5.8G ONLY"; value: 2}
    }

    property string m_info_string: "Analyze channels for pollution by wifi access points.\n"+
                                   "NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended !\n"+
                                   "In short: Any frequency with red bars (small or big) should not be used, unless there are no options / other reasons to do so."

    ColumnLayout{
        id: main_layout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        BaseHeaderItem{
            m_text: "Scan for clean Channels"
        }

        Item {
            id:closeButtonWrapper
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.rightMargin: closeButton.width-main_layout.anchors.rightMargin
            Layout.topMargin: closeButtonWrapper.height-closeButton.height-1

            Button {
                id:closeButton
                text: "X"
                height:42
                width:42
                background: Rectangle {
                    Layout.fillHeight: parent
                    Layout.fillWidth: parent
                    color: closeButton.hovered ? "darkgrey" : "lightgrey"
                }
                onClicked: {
                    if (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode == 1) {
                        _qopenhd.show_toast("STILL ANALYZING, PLEASE WAIT ...");
                        return;
                    }
                    close()
                }
            }
        }

        RowLayout{
            visible:false
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            ButtonIconInfo{
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    _messageBoxInstance.set_text_and_show(m_info_string)
                }
            }
        }
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Button{
                id:startButton
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
            ComboBox {
                Layout.preferredWidth: 150
                Layout.minimumWidth: 50
                id: comboBoxFilter
                model: model_filter
                textRole: "title"
                onCurrentIndexChanged: {
                    pollution_chart.update_pollution_graph();
                }
            }
            Switch{
                id:normalize
                checked: m_normalize_data
                onCheckedChanged: {
                    m_normalize_data=checked
                    pollution_chart.update_pollution_graph();
                }
            }
            Text{
                text: "Normalize"
                color: "#fff"
                font.pixelSize: 18
                verticalAlignment: Qt.AlignVCenter
                Layout.leftMargin: -10
            }
        }
        SimpleProgressBar{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 400
            Layout.minimumWidth: 100
            Layout.preferredHeight: 40
            impl_curr_progress_perc: _wbLinkSettingsHelper.analyze_progress_perc
            impl_show_progress_text: true
        }
        Text{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 200
            Layout.minimumWidth: 100
            Layout.preferredHeight: 25
            color: "#fff"
            text: {
                if(_wbLinkSettingsHelper.current_analyze_frequency<=0){
                    return "";
                }
                return "Analyzed "+_wbLinkSettingsHelper.current_analyze_frequency+" Mhz ...";
            }
        }
        ScrollView{
            id: chart_scroll_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: pollution_chart.width
            ScrollBar.horizontal.interactive: true
            clip: true

            ChartView {
                id: pollution_chart
                //width: main_background.width>m_chart_view_minimum_width ? main_background.width : m_chart_view_minimum_width;
                width: {
                    const screen_width = main_background.width-10;
                    if(comboBoxFilter.currentIndex==0){
                        return screen_width>m_chart_view_minimum_width ? screen_width : m_chart_view_minimum_width;
                    }
                    if(comboBoxFilter.currentIndex==1){
                        return screen_width
                    }
                    return screen_width>m_chart_view_minimum_width2 ? screen_width : m_chart_view_minimum_width2;
                }
                //width: m_chart_enlarged ? 1280 : main_background.width
                height: parent.height
                legend.alignment: Qt.AlignBottom
                antialiasing: true

                function update_pollution_graph(){
                    //const frequencies_list = _wbLinkSettingsHelper.get_pollution_qstringlist();
                    //bar_axis_x.categories=frequencies_list;
                    //const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies();
                    const all_40Mhz_frequencies_unfiltered=_frequencyHelper.get_frequencies_all_40Mhz();
                    const all_40Mhz_frequencies = _frequencyHelper.filter_frequencies(all_40Mhz_frequencies_unfiltered,comboBoxFilter.currentIndex);
                    var categories = _pollutionHelper.pollution_frequencies_int_to_qstringlist(all_40Mhz_frequencies);
                    var values = _pollutionHelper.pollution_frequencies_int_get_pollution(all_40Mhz_frequencies,m_normalize_data);
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
        // Filler
        //Item{
        //    Layout.fillWidth: true
        //    Layout.fillHeight: true
        //}
    }




}

