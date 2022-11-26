import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: aoaWidget
    width: 50
    height: 100
    defaultAlignment: 1
    defaultXOffset: 60
    defaultVCenter: true

    visible: settings.show_aoa

    widgetIdentifier: "aoa_widget"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: aoaSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: aoaSettingsColumn
            Item {
                width: parent.width
                height: 42
                Text {
                    id: aoaSettingsTitle
                    text: qsTr("Angle of Attack")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: aoaSettingsTitleUL
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
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: aoa_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.aoa_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.aoa_opacity = aoa_opacity_Slider.value
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
                    id: aoa_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.aoa_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.aoa_size = aoa_size_Slider.value
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
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: aoa_max_Slider
                    orientation: Qt.Horizontal
                    from: 15
                    value: settings.aoa_max
                    to: 40
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.aoa_max = aoa_max_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.aoa_opacity

        //-----------------------ladder start---------------
        Item {
            id: aoaGauge

            anchors.left: parent.left
            anchors.rightMargin: 0 //tweak ladder left or right

            visible: settings.show_aoa

            transform: Scale {
                origin.x: 25
                origin.y: 60
                xScale: settings.aoa_size
                yScale: settings.aoa_size
            }

            AoaGauge {
                id: aoaGaugeC
                //anchors.centerIn: parent
                anchors.top: parent.bottom

                width: 50
                height: 100
                clip: false
                color: settings.color_shape
                glow: settings.color_glow

                aoaRange: settings.aoa_max
                Behavior on aoa {NumberAnimation { duration: settings.smoothing }}
                aoa: _fcMavlinkSystem.aoa
                fontFamily: settings.font_text
            }
        }

        //-----------------------ladder end---------------
        Text {
            visible:false // used for testing
            anchors.fill: parent
            id: aoa_text
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: settings.aoa_size
                yScale: settings.aoa_size
            }
            text: Number(_fcMavlinkSystem.aoa).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
