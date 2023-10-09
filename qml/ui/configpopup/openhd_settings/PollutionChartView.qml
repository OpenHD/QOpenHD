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

ChartView {
    title: "WiFi pollution estimate"
    width: parent.width
    height: rowHeight * 3
    legend.alignment: Qt.AlignBottom
    antialiasing: true


    function update(){
        update_pollution_graph();
    }

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
