import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: groundStatusWidget
    width: 112
    height: 24

    visible: settings.show_ground_status

    widgetIdentifier: "ground_status_widget"
    bw_verbose_name: "CPU LOAD GND"

    defaultAlignment: 1
    defaultXOffset: 128
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    // Functionality between air and ground widget is really similar - this helps reducing code bloat a bit
    property int m_cpuload_perc: _ohdSystemGround.curr_cpuload_perc
    property int m_cpuload_perc_warn: settings.ground_status_cpu_warn
    property int m_cpuload_perc_caution: settings.ground_status_cpu_caution

    property int m_soc_temperature_deg: _ohdSystemGround.curr_soc_temp_degree
    property int m_soc_temperature_deg_warn: settings.ground_status_temp_warn
    property int m_soc_temperature_deg_caution: settings.ground_status_temp_caution

    // These do not need warning level(s) and are hidden in the action popup
    property int m_curr_cpu_freq_mhz: _ohdSystemGround.curr_cpu_freq_mhz
    property int m_curr_isp_freq_mhz: _ohdSystemGround.curr_isp_freq_mhz
    property int m_curr_h264_freq_mhz : _ohdSystemGround.curr_h264_freq_mhz
    property int m_curr_core_freq_mhz : _ohdSystemGround.curr_core_freq_mhz
    property int m_curr_v3d_freq_mhz : _ohdSystemGround.curr_v3d_freq_mhz
    property int m_ram_usage_perc  : _ohdSystemGround.ram_usage_perc
    property bool m_rpi_undervolt_error: _ohdSystemGround.rpi_undervolt_error

    // 0 - no warning
    // 1 - caution
    // 2 - warning
    function get_cpuload_warning_level(){
        if (m_cpuload_perc>= m_cpuload_perc_warn) {
            return 2;
        }
        if (m_cpuload_perc > m_cpuload_perc_caution) {
            return 1;
        }
        return 0;
    }
    function get_temperature_warning_level(){
        if (m_soc_temperature_deg>= m_soc_temperature_deg_warn) {
            return 2;
        }
        if (m_soc_temperature_deg>= m_soc_temperature_deg_caution) {
            return 1;
        }
        return 0;
    }
    // The icon is colored if any of those warnings are set
    function get_highest_warning_level(){
        var w1=get_cpuload_warning_level();
        var w2=get_temperature_warning_level();
        return w1 >= w2 ? w1 : w2;
    }

    function warning_level_to_color(level){
        if(level===2)return settings.color_warn;
        if(level===1)return settings.color_caution;
        return settings.color_shape;
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
                    text: qsTr("Declutter Upon Arm")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                GgSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.ground_status_declutter
                    onCheckedChanged: settings.ground_status_declutter = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show undervolt icon")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                GgSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.ground_status_show_undervolt_icon
                    onCheckedChanged: settings.ground_status_show_undervolt_icon = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Caution CPU")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.ground_status_cpu_caution
                    color: settings.color_caution
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                GgSlider {
                    id: ground_status_cpu_caution_Slider
                    orientation: Qt.Horizontal
                    value: settings.ground_status_cpu_caution
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_cpu_caution = Math.round(
                                    ground_status_cpu_caution_Slider.value * 10) / 10.0
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Warn CPU")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.ground_status_cpu_warn
                    color: settings.color_warn
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                GgSlider {
                    id: ground_status_cpu_warn_Slider
                    orientation: Qt.Horizontal
                    value: settings.ground_status_cpu_warn
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_cpu_warn = Math.round(
                                    ground_status_cpu_warn_Slider.value * 10) / 10.0
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Caution Temp")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.ground_status_temp_caution
                    color: settings.color_caution
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                GgSlider {
                    id: ground_status_temp_caution_Slider
                    orientation: Qt.Horizontal
                    value: settings.ground_status_temp_caution
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_temp_caution = Math.round(
                                    ground_status_temp_caution_Slider.value * 10) / 10.0
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Warn Temp")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.ground_status_temp_warn
                    color: settings.color_warn
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                GgSlider {
                    id: ground_status_temp_warn_Slider
                    orientation: Qt.Horizontal
                    value: settings.ground_status_temp_warn
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_temp_warn = Math.round(
                                    ground_status_temp_warn_Slider.value * 10) / 10.0
                    }
                }
            }

        }
    }
    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200

            Text {
                //Layout.alignment: left
                text: "CPU freq: "+m_curr_cpu_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "ISP freq: "+m_curr_isp_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "H264 freq: "+m_curr_h264_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Core freq: "+m_curr_core_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "v3d freq: "+m_curr_v3d_freq_mhz+" Mhz"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "RAM: "+m_ram_usage_perc+" %"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "RPI undervolt: "+(m_rpi_undervolt_error ? "Y" : "N")
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: bw_current_scale

        Text {
            id: chip_icon
            y: 0
            width: 24
            height: 24
            color: {
                var level=get_highest_warning_level();
                return warning_level_to_color(level)
            }
            opacity: bw_current_opacity
            text: "\uF2DA"
            //text: "\uf2db"
            anchors.right: cpuload_gnd.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text{
            id: undervolt_error
            width: 24
            height: 24
            opacity: bw_current_opacity
            //text: "X"
            text: String.fromCodePoint(0xf0e7)+"!"
            anchors.right: chip_icon.left
            anchors.top: chip_icon.top
            anchors.rightMargin: 0
            anchors.topMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: "red"
            color: "yellow"
            //visible: true
            visible: m_rpi_undervolt_error && settings.ground_status_show_undervolt_icon
        }
        Text {
            id: cpuload_gnd
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                var level=get_cpuload_warning_level();
                return warning_level_to_color(level)
            }
            opacity: bw_current_opacity
            text: Number(m_cpuload_perc).toLocaleString(Qt.locale(),
                                                            'f', 0) + "%"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: temp_gnd.left
            anchors.rightMargin: 2
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.family: settings.font_text
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: temp_gnd
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                var level=get_temperature_warning_level()
                return warning_level_to_color(level)
            }
            opacity: bw_current_opacity
            text: Number(m_soc_temperature_deg).toLocaleString(Qt.locale(),
                                                         'f', 0) + "°"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.family: settings.font_text
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
