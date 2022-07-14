import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: airStatusWidget
    width: 112
    height: 24

    visible: settings.show_air_status

    widgetIdentifier: "air_status_widget"

    defaultAlignment: 1
    defaultXOffset: 128
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: airstatusSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Column {
            id: airstatusSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: airstatusTitle
                    text: qsTr("AIR STATUS")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: airstatusTitleUL
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
                    id: air_status_opacity_Slider
                    orientation: Qt.Horizontal
                    height: parent.height
                    from: .1
                    value: settings.air_status_opacity
                    to: 1
                    stepSize: .1
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_opacity = air_status_opacity_Slider.value
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
                    id: air_status_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.air_status_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_size = air_status_size_Slider.value
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
                    checked: settings.air_status_declutter
                    onCheckedChanged: settings.air_status_declutter = checked
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
                    text: settings.air_status_cpu_warn
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
                    from: 50
                    value: settings.air_status_cpu_warn
                    to: 100
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_cpu_warn = Math.round(
                                    air_status_cpu_warn_Slider.value * 10) / 10.0
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
                    text: settings.air_status_cpu_caution
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
                    from: 20
                    value: settings.air_status_cpu_caution
                    to: 49
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_cpu_caution = Math.round(
                                    air_status_cpu_caution_Slider.value * 10) / 10.0
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
                    text: settings.air_status_temp_warn
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
                    from: 50
                    value: settings.air_status_temp_warn
                    to: 150
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_temp_warn = Math.round(
                                    air_status_temp_warn_Slider.value * 10) / 10.0
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
                    text: settings.air_status_temp_caution
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
                    from: 20
                    value: settings.air_status_temp_caution
                    to: 49
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.air_status_temp_caution = Math.round(
                                    air_status_temp_caution_Slider.value * 10) / 10.0
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: settings.air_status_size

        Text {
            id: chip_air
            y: 0
            width: 24
            height: 24
            color: {
                if (_ohdSystemAir.cpuload >= settings.air_status_cpu_warn
                        || _ohdSystemAir.temp_air >= settings.air_status_temp_warn) {
                    return settings.color_warn
                } else if (_ohdSystemAir.cpuload > settings.air_status_cpu_caution
                           || _ohdSystemAir.temp_air > settings.air_status_temp_caution) {
                    return settings.color_caution
                } else {
                    return settings.color_shape
                }
            }
            opacity: settings.air_status_opacity
            text: "\uf2db"
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

        Text {
            id: cpuload_air
            x: 0
            y: 0
            width: 36
            height: 24
            color: {
                if (_ohdSystemAir.cpuload >= settings.air_status_cpu_warn
                        || _ohdSystemAir.temp_air >= settings.air_status_temp_warn) {
                    widgetInner.visible = true
                    return settings.color_warn
                } else if (_ohdSystemAir.cpuload > settings.air_status_cpu_caution
                           || _ohdSystemAir.temp_air > settings.air_status_temp_caution) {
                    widgetInner.visible = true
                    return settings.color_caution
                } else if (settings.air_status_declutter == true
                           && OpenHD.armed == true) {
                    widgetInner.visible = false
                    return settings.color_text
                } else {
                    widgetInner.visible = true
                    return settings.color_text
                }
            }
            opacity: settings.air_status_opacity
            text: Number(_ohdSystemAir.cpuload).toLocaleString(Qt.locale(),
                                                            'f', 0) + "%"
            anchors.right: temp_air.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
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
            y: 4
            width: 36
            height: 24
            color: {
                if (_ohdSystemAir.cpuload >= settings.air_status_cpu_warn
                        || _ohdSystemAir.temp_air >= settings.air_status_temp_warn) {
                    widgetInner.visible = true
                    return settings.color_warn
                } else if (_ohdSystemAir.cpuload > settings.air_status_cpu_caution
                           || _ohdSystemAir.temp_air > settings.air_status_temp_caution) {
                    widgetInner.visible = true
                    return settings.color_caution
                } else if (settings.air_status_declutter == true
                           && OpenHD.armed == true) {
                    widgetInner.visible = false
                    return settings.color_text
                } else {
                    widgetInner.visible = true
                    return settings.color_text
                }
            }
            opacity: settings.air_status_opacity
            text: Number(_ohdSystemAir.temp_air).toLocaleString(Qt.locale(),
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
