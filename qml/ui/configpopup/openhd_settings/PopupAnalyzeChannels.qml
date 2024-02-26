import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
 

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

import QtCharts 2.15

PopupBigGeneric{
    // Overwritten from parent
    m_title: "Scan for clean Channels"
    onCloseButtonClicked: {
        if (_ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode == 2) {
            _qopenhd.show_toast("STILL ANALYZING, PLEASE WAIT ...");
            return;
        }
        close()
    }
    // Actual implementation
    property bool m_normalize_data: false;
    property int m_chart_view_minimum_width: 1280;
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
        ListElement {title: "OHD [1-5]"; value: 0}
        ListElement {title: "All 2.4G"; value: 1}
        ListElement {title: "All 5.8G"; value: 2}
    }

    property string m_info_string: "Analyze channels for pollution by wifi access points.\n"+
                                   "NOTE: This only gives a hint at free channels, using a proper channel analyzer (e.g. on the phone) is recommended !\n"+
                                   "In short: Any frequency with red bars (small or big) should not be used, unless there are no options / other reasons to do so."

    ColumnLayout{
        id: main_layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: dirty_top_margin_for_implementation

        RowLayout{
            visible:true
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
                    var how_many_freq_bands=comboBoxWhichFrequencyToAnalyze.currentIndex
                    var result=_wbLinkSettingsHelper.start_analyze_channels(how_many_freq_bands)
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
                id: comboBoxWhichFrequencyToAnalyze
                model: model_filter
                textRole: "title"
                onCurrentIndexChanged: {
                    pollution_chart.update_pollution_graph();
                }
            }
            Switch{
                id:normalize_sw
                checked: m_normalize_data
                onCheckedChanged: {
                    m_normalize_data=checked
                    pollution_chart.update_pollution_graph();
                    if(m_normalize_data){
                        _qopenhd.show_toast("WARNING: THIS VIEW CAN BE DECEIVING !");
                    }
                }
            }
            Text{
                text: m_normalize_data ? "Relative" : "Absolute"
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
                clip: true
                //width: main_background.width>m_chart_view_minimum_width ? main_background.width : m_chart_view_minimum_width;
                width: {
                    const screen_width = main_background.width-10;
                    // 2.4G and OHD 1-5 should always fit into screen size
                    const filter=comboBoxWhichFrequencyToAnalyze.currentIndex;
                    if(filter==0 || filter==1){
                         return screen_width;
                    }
                    // All the 5.8G frequencies together do not!
                    return screen_width>m_chart_view_minimum_width ? screen_width : m_chart_view_minimum_width;
                }
                //width: m_chart_enlarged ? 1280 : main_background.width
                height: parent.height
                legend.alignment: Qt.AlignBottom
                antialiasing: true

                function update_pollution_graph(){
                    //const frequencies_list = _wbLinkSettingsHelper.get_pollution_qstringlist();
                    //bar_axis_x.categories=frequencies_list;
                    //const supported_frequencies = _wbLinkSettingsHelper.get_supported_frequencies();
                    const channels_to_analyze=comboBoxWhichFrequencyToAnalyze.currentIndex;
                    var frequencies_to_analyze=_frequencyHelper.get_frequencies(0);
                    if(channels_to_analyze==0){
                       frequencies_to_analyze=_frequencyHelper.get_frequencies(0);
                    }else if(channels_to_analyze==1){
                        frequencies_to_analyze=_frequencyHelper.get_frequencies(1);
                    }else{
                        frequencies_to_analyze=_frequencyHelper.get_frequencies(2);
                        frequencies_to_analyze=_frequencyHelper.filter_frequencies_40mhz_ht40plus_only(frequencies_to_analyze);
                    }
                    var categories = _pollutionHelper.pollution_frequencies_int_to_qstringlist(frequencies_to_analyze);
                    var values = _pollutionHelper.pollution_frequencies_int_get_pollution(frequencies_to_analyze,m_normalize_data);
                    bar_axis_x.categories=categories;
                    bar_set.values=values;
                    if(m_normalize_data){
                        element_x_axis.labelsVisible=false;
                        element_x_axis.min=0;
                        element_x_axis.max=100;
                    }else{
                        element_x_axis.labelsVisible=true;
                        element_x_axis.min=0;
                        element_x_axis.max=30;
                    }
                }
                BarSeries {
                    id: hm_bar_series
                    axisX: BarCategoryAxis {
                        id: bar_axis_x
                        categories: ["DUMMY0", "DUMMY1", "DUMMY3", "DUMMY4" ]
                        //min: "0"
                        //max: "500"
                    }
                    /*axisY: ValueAxis {
                        labelsVisible: false
                        gridVisible:false
                    }*/
                    axisY: CategoryAxis{
                        id: element_x_axis
                        min: 0
                        max: 30
                        labelsPosition: CategoryAxis.AxisLabelsPositionOnValue
                        CategoryRange {
                            label: "perfect"
                            endValue: 0

                        }
                        CategoryRange {
                            label: "good"
                            endValue: 10

                        }
                        CategoryRange {
                            label: "medium"
                            endValue: 20
                        }
                        CategoryRange {
                            label: "bad"
                            endValue: 30
                        }
                    }
                    BarSet {
                        id: bar_set
                        //label: m_normalize_data ? "Pollution estimate %" : "WiFiPollution estimate (pps)";
                        label: "WiFi pollution estimate"
                        values: [5,10,3,100]
                        //values: [0,0,0,0]
                        color: "red"
                    }
                    /*BarSet{
                        id: bar_set2
                        label: "GOOD"
                        color: "green"
                        values: [5,10,3,100]
                    }*/
                    labelsPosition: AbstractBarSeries.LabelsInsideEnd
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

