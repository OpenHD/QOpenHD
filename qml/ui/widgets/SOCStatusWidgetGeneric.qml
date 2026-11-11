import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0
import "../configpopup/status/SystemHealth.js" as SystemHealth

BaseWidget {
    id: airStatusWidget
    height: 24

    visible: settings.show_air_status && settings.show_widgets

    widgetPreviewContent: widgetInner
    widgetIdentifier: "air_status_widget"
    bw_verbose_name: qsTr("CPU LOAD AIR")

    property bool m_is_air: false

    // Functionality between air and air widget is really similar - this helps reducing code bloat a bit
    property int m_cpuload_perc:  m_is_air ? previewTelemetry("_ohdSystemAir", "curr_cpuload_perc", _ohdSystemAir.curr_cpuload_perc) : previewTelemetry("_ohdSystemGround", "curr_cpuload_perc", _ohdSystemGround.curr_cpuload_perc);
    readonly property var thresholdUnit: ({ohd_platform_type: m_is_air ? previewTelemetry("_ohdSystemAir", "ohd_platform_type", _ohdSystemAir.ohd_platform_type) : _ohdSystemGround.ohd_platform_type})
    readonly property string thresholdPrefix: SystemHealth.thresholdPrefix(thresholdUnit, !m_is_air)
    property int m_cpuload_perc_warn: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "cpu", "warn");
    property int m_cpuload_perc_caution: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "cpu", "caution")

    property int m_soc_temperature_deg: m_is_air ? previewTelemetry("_ohdSystemAir", "curr_soc_temp_degree", _ohdSystemAir.curr_soc_temp_degree) : previewTelemetry("_ohdSystemGround", "curr_soc_temp_degree", _ohdSystemGround.curr_soc_temp_degree)
    property int m_soc_temperature_deg_warn: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "temp", "warn")
    property int m_soc_temperature_deg_caution: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "temp", "caution")

    // These do not need warning level(s) and are hidden in the action popup
    property int m_curr_cpu_freq_mhz: m_is_air ?previewTelemetry("_ohdSystemAir", "curr_cpu_freq_mhz", _ohdSystemAir.curr_cpu_freq_mhz) : previewTelemetry("_ohdSystemGround", "curr_cpu_freq_mhz", _ohdSystemGround.curr_cpu_freq_mhz)
    property int m_curr_isp_freq_mhz: m_is_air ?previewTelemetry("_ohdSystemAir", "curr_isp_freq_mhz", _ohdSystemAir.curr_isp_freq_mhz) : previewTelemetry("_ohdSystemGround", "curr_isp_freq_mhz", _ohdSystemGround.curr_isp_freq_mhz)
    property int m_curr_h264_freq_mhz : m_is_air ?previewTelemetry("_ohdSystemAir", "curr_h264_freq_mhz", _ohdSystemAir.curr_h264_freq_mhz) : previewTelemetry("_ohdSystemGround", "curr_h264_freq_mhz", _ohdSystemGround.curr_h264_freq_mhz)
    property int m_curr_core_freq_mhz : m_is_air ?previewTelemetry("_ohdSystemAir", "curr_core_freq_mhz", _ohdSystemAir.curr_core_freq_mhz) : previewTelemetry("_ohdSystemGround", "curr_core_freq_mhz", _ohdSystemGround.curr_core_freq_mhz)
    property int m_curr_v3d_freq_mhz : m_is_air ?previewTelemetry("_ohdSystemAir", "curr_v3d_freq_mhz", _ohdSystemAir.curr_v3d_freq_mhz) : previewTelemetry("_ohdSystemGround", "curr_v3d_freq_mhz", _ohdSystemGround.curr_v3d_freq_mhz)
    property int m_ram_usage_perc  : m_is_air ?previewTelemetry("_ohdSystemAir", "ram_usage_perc", _ohdSystemAir.ram_usage_perc) : previewTelemetry("_ohdSystemGround", "ram_usage_perc", _ohdSystemGround.ram_usage_perc)
    property bool m_rpi_undervolt_error: m_is_air ?previewTelemetry("_ohdSystemAir", "rpi_undervolt_error", _ohdSystemAir.rpi_undervolt_error) : previewTelemetry("_ohdSystemGround", "rpi_undervolt_error", _ohdSystemGround.rpi_undervolt_error)

    // 0 - no warning
    // 1 - caution
    // 2 - warning
    function get_cpuload_warning_level(){
        if (SystemHealth.muted(!m_is_air, settings, "cpu")) return 0;
        if (m_cpuload_perc>= m_cpuload_perc_warn) {
            return 2;
        }
        if (m_cpuload_perc >= m_cpuload_perc_caution) {
            return 1;
        }
        return 0;
    }
    function get_temperature_warning_level(){
        if (SystemHealth.muted(!m_is_air, settings, "temp")) return 0;
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
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: m_is_air ? settings.air_status_declutter : settings.ground_status_declutter
                    onCheckedChanged: {
                        if(m_is_air){
                            settings.air_status_declutter = checked
                        }else{
                             settings.ground_status_declutter = checked
                        }
                    }
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
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: m_is_air ? settings.air_status_show_undervolt_icon : settings.ground_status_show_undervolt_icon
                    onCheckedChanged: {
                        if(m_is_air){
                             settings.air_status_show_undervolt_icon = checked
                        }else{
                            settings.ground_status_show_undervolt_icon = checked
                        }
                    }
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
                    text: m_cpuload_perc_caution
                    color: settings.color_caution
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: air_status_cpu_caution_Slider
                    orientation: Qt.Horizontal
                    value: m_cpuload_perc_caution
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onMoved: settings[thresholdPrefix + "cpu_caution"] = Math.round(value)
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
                    text: m_cpuload_perc_warn
                    color: settings.color_warn
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: air_status_cpu_warn_Slider
                    orientation: Qt.Horizontal
                    value: m_cpuload_perc_warn
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onMoved: settings[thresholdPrefix + "cpu_warn"] = Math.round(value)
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
                    text: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "temp", "caution")
                    color: settings.color_caution
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: air_status_temp_caution_Slider
                    orientation: Qt.Horizontal
                    value: m_soc_temperature_deg_caution
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onMoved: settings[thresholdPrefix + "temp_caution"] = Math.round(value)
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
                    text: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "temp", "warn")
                    color: settings.color_warn
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: air_status_temp_warn_Slider
                    orientation: Qt.Horizontal
                    value: SystemHealth.threshold(thresholdUnit, !m_is_air, settings, "temp", "warn")
                    from: 20
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onMoved: settings[thresholdPrefix + "temp_warn"] = Math.round(value)
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
                text: qsTr("CPU freq: %1 MHz").arg(m_curr_cpu_freq_mhz);
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("ISP freq: %1 MHz").arg(m_curr_isp_freq_mhz);
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("H264 freq: %1 MHz").arg(m_curr_h264_freq_mhz);
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("Core freq: %1 MHz").arg(m_curr_core_freq_mhz);
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("v3d freq: %1 MHz").arg(m_curr_v3d_freq_mhz)
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("RAM: %1%").arg(m_ram_usage_perc)
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: qsTr("RPI undervolt: %1").arg(m_rpi_undervolt_error ? qsTr("Y") : qsTr("N"))
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
            opacity: widgetGalleryPreview ? 1 : bw_current_opacity
            text: m_is_air ? "\uf2db" : "\uF2DA"
            anchors.right: cpuload_air.left
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
            opacity: widgetGalleryPreview ? 1 : bw_current_opacity
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
            visible: m_rpi_undervolt_error && !SystemHealth.muted(!m_is_air, settings, "undervolt") && (m_is_air ? settings.air_status_show_undervolt_icon : settings.ground_status_show_undervolt_icon)
        }

        Text {
            id: cpuload_air
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                var level=get_cpuload_warning_level();
                return warning_level_to_color(level)
            }
            opacity: widgetGalleryPreview ? 1 : bw_current_opacity
            text: Number(m_cpuload_perc).toLocaleString(Qt.locale(),
                                                            'f', 0) + "%"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: temp_air.left
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
            id: temp_air
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                var level=get_temperature_warning_level()
                return warning_level_to_color(level)
            }
            opacity: widgetGalleryPreview ? 1 : bw_current_opacity
            text: Number(m_soc_temperature_deg).toLocaleString(Qt.locale(),
                                                         'f', 0) + "°"
            anchors.verticalCenter: parent.verticalCenter
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
