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

    defaultAlignment: 1
    defaultXOffset: 128
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    widgetDetailComponent: ScrollView {

        contentHeight: groundstatusSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: groundstatusSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: groundstatusSettingsTitle
                    text: qsTr("GROUND STATUS")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: groundstatusSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    id: opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: ground_status_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.ground_status_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_opacity = ground_status_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: ground_status_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.ground_status_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.ground_status_size = ground_status_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Horizontal Center")
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
                    checked: {
                        // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier,
                                                      defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1
                                || _hCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier,
                                                        checked)
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Vertical Center")
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
                    checked: {
                        // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier,
                                                      defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1
                                || _vCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier,
                                                        checked)
                }
            }
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
                    checked: settings.ground_status_declutter
                    onCheckedChanged: settings.ground_status_declutter = checked
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
                Slider {
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
                Slider {
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
                Slider {
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
                Slider {
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
                text: "CPU freq: "+_ohdSystemGround.curr_cpu_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "ISP freq: "+_ohdSystemGround.curr_isp_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "H264 freq: "+_ohdSystemGround.curr_h264_freq_mhz
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                //Layout.alignment: left
                text: "Core freq: "+_ohdSystemGround.curr_core_freq_mhz
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
        scale: settings.ground_status_size

        Text {
            id: chip_gnd
            y: 0
            width: 24
            height: 24
            color: {

                if (_ohdSystemGround.curr_cpuload_perc>= settings.ground_status_cpu_warn
                        || _ohdSystemGround.curr_soc_temp_degree>= settings.ground_status_temp_warn) {
                    return settings.color_warn
                } else if (_ohdSystemGround.curr_cpuload_perc > settings.ground_status_cpu_caution
                           || _ohdSystemGround.curr_soc_temp_degree> settings.ground_status_temp_caution) {
                    return settings.color_caution
                } else {
                    return settings.color_shape
                }
            }
            opacity: settings.ground_status_opacity
            text: "\uF2DA"
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

        Text {
            id: cpuload_gnd
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                if (_ohdSystemGround.curr_cpuload_perc>= settings.ground_status_cpu_warn
                        || _ohdSystemGround.curr_soc_temp_degree>= settings.ground_status_temp_warn) {
                    widgetInner.visible = true
                    return settings.color_warn
                } else if (_ohdSystemGround.curr_cpuload_perc> settings.ground_status_cpu_caution
                           || _ohdSystemGround.curr_soc_temp_degree> settings.ground_status_temp_caution) {
                    widgetInner.visible = true
                    return settings.color_caution
                } else if (settings.ground_status_declutter == true
                           && OpenHD.armed == true) {
                    widgetInner.visible = false
                    return settings.color_text
                } else {
                    widgetInner.visible = true
                    return settings.color_text
                }
            }
            opacity: settings.ground_status_opacity
            text: Number(_ohdSystemGround.curr_cpuload_perc).toLocaleString(Qt.locale(),
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
                if (_ohdSystemGround.curr_cpuload_perc>= settings.ground_status_cpu_warn
                        || _ohdSystemGround.curr_soc_temp_degree >= settings.ground_status_temp_warn) {
                    widgetInner.visible = true
                    return settings.color_warn
                } else if (_ohdSystemGround.curr_cpuload_perc> settings.ground_status_cpu_caution
                           || _ohdSystemGround.curr_soc_temp_degree > settings.ground_status_temp_caution) {
                    widgetInner.visible = true
                    return settings.color_caution
                } else if (settings.ground_status_declutter == true
                           && OpenHD.armed == true) {
                    widgetInner.visible = false
                    return settings.color_text
                } else {
                    widgetInner.visible = true
                    return settings.color_text
                }
            }
            opacity: settings.ground_status_opacity
            text: Number(_ohdSystemGround.curr_soc_temp_degree).toLocaleString(Qt.locale(),
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
