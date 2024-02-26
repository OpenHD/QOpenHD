import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: airBatteryWidget
    width: 96
    height: 55

    visible: settings.show_air_battery

    widgetIdentifier: "air_battery_widget"
    bw_verbose_name: "AIR BATTERY (FC)"

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    function get_text_for_specific_battery(id){

        var voltage_v= id===0 ? _fcMavlinkSystem.battery_id0_voltage_volt : _fcMavlinkSystem.battery_id1_voltage_volt;
        var current_ampere= id===0 ? _fcMavlinkSystem.battery_id0_current_ampere : _fcMavlinkSystem.battery_id1_current_ampere;
        var consumed_mah = id===0 ? _fcMavlinkSystem.battery_id0_consumed_mah : _fcMavlinkSystem.battery_id1_consumed_mah;

        var ret="";
        //Number().toLocaleString(Qt.locale(),'f', 1) + "V"
        var voltage_str = Number(voltage_v).toLocaleString(Qt.locale(),'f', 1) + "V "
        ret+=voltage_str
        ret+=(Number(current_ampere).toLocaleString( Qt.locale(), 'f', 1) + "A ")
        ret+=(consumed_mah + "mAh")
        return ret;
    }

    function get_more_text_for_specific_battery(id){
        var type=id===0 ? _fcMavlinkSystem.battery_id0_type : _fcMavlinkSystem.battery_id1_type;
        var remaining=id===0 ? _fcMavlinkSystem.battery_id0_remaining_time_s : _fcMavlinkSystem.battery_id1_remaining_time_s;
        var remaining_s=" Remaining: ";
        if(remaining<=0){
            remaining_s+="N/A s";
        }else{
            remaining_s+=(remaining+"s");
        }
        return "Type: "+type+remaining_s
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            // This element has a couple of non-base-class settings for customization
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Show volts and amps")
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
                    checked: settings.air_battery_show_voltage_current
                    onCheckedChanged: settings.air_battery_show_voltage_current = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.air_battery_show_voltage_current
                Text {
                    text: qsTr("Single Cell ("+settings.vehicle_battery_n_cells+"S)")
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
                    checked: settings.air_battery_show_single_cell
                    onCheckedChanged: settings.air_battery_show_single_cell = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.air_battery_show_voltage_current
                Text {
                    text: qsTr("N cells: "+settings.vehicle_battery_n_cells)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                SpinBox {
                    width: 32*3
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    from: 1
                    to: 32
                    stepSize: 1
                    value: settings.vehicle_battery_n_cells
                    onValueChanged: {
                        settings.vehicle_battery_n_cells=value
                    }
                    editable: false
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Use batt id 0 only")
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
                    checked: settings.air_battery_use_batt_id_0_only
                    onCheckedChanged: settings.air_battery_use_batt_id_0_only = checked
                }
            }

        }
    }

    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            width: 200
            Item {
                width: parent.width
                height: 20
                Text {
                    text: qsTr("Batt1:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_text_for_specific_battery(0)
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 20
                Text {
                    text: get_more_text_for_specific_battery(0)
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left:parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 20
                Text {
                    text: qsTr("Batt2:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text:  get_text_for_specific_battery(1)
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 20
                Text {
                    text: get_more_text_for_specific_battery(1)
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left:parent.left
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: bw_current_opacity
        scale: bw_current_scale

        Text {
            id: airTag
            y: 0
            rotation: -90
            color: settings.color_text
            text: "air"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 2
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: battery_percent
            y: 0
            color: settings.color_text
            text:  qsTr("%L1%").arg( _fcMavlinkSystem.battery_percent)
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text {
            id: battery_amp_text
            visible: settings.air_battery_show_voltage_current
            text: Number(_fcMavlinkSystem.battery_current_ampere).toLocaleString(
                      Qt.locale(), 'f', 1) + "A"
            color: settings.color_text
            anchors.bottom: battery_percent.top
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text {
            id: battery_volt_text
            visible: settings.air_battery_show_voltage_current
            text: settings.air_battery_show_single_cell ? Number(
                                                              _fcMavlinkSystem.battery_voltage_single_cell).toLocaleString(
                                                              Qt.locale(),
                                                              'f', 1) + "V" :
                                                          Number(
                                                              _fcMavlinkSystem.battery_voltage_volt).toLocaleString(
                                                              Qt.locale(),
                                                              'f', 1) + "V"
            color: settings.color_text
            anchors.top: battery_percent.bottom
            anchors.left: batteryGauge.right
            anchors.leftMargin: 0
            clip: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text {
            id: batteryGauge
            y: 8
            width: 36
            height: 48
            color: {
                //TODO reintroduce the settings, but PLEASE FUCKING KEEP THE MV PATTERM
                var percent =  _fcMavlinkSystem.battery_percent
                // 20% warning, 15% critical
                return percent < 20 ? (percent < 15 ? "#ff0000" : "#fbfd15") : settings.color_shape
            }
            opacity: bw_current_opacity
            text: _fcMavlinkSystem.battery_percent_gauge
            anchors.left: parent.left
            anchors.leftMargin: 12
            fontSizeMode: Text.VerticalFit
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            elide: Text.ElideMiddle
            font.family: "Material Design Icons"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
