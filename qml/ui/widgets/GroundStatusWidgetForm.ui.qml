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

    widgetDetailComponent: ScrollView{

        contentHeight: groundstatusSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: groundstatusSettingsColumn
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
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
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
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
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
            color: settings.color_shape
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
            color: OpenHD.cpuload_gnd >= 70 ? (OpenHD.cpuload_gnd >= 80 ? "#ff0000" : "#fbfd15") : settings.color_text
            opacity: settings.ground_status_opacity
            text: Number(OpenHD.cpuload_gnd).toLocaleString(Qt.locale(), 'f', 0) + "%";
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
            color: OpenHD.temp_gnd >= 65 ? (OpenHD.temp_gnd >= 75 ? "#ff0000" : "#fbfd15") : settings.color_text
            opacity: settings.ground_status_opacity
            text: Number(OpenHD.temp_gnd).toLocaleString(Qt.locale(), 'f', 0) + "°";
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
