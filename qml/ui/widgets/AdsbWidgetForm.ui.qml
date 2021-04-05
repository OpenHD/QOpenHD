import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Extras 1.4

import QtQml.Models 2.15
import QtPositioning 5.2
import QtLocation 5.12


import OpenHD 1.0



BaseWidget {
    id: adsbWidget
    width: 55
    height: 15

    z:4

    visible: settings.show_adsb

    widgetIdentifier: "adsb_widget"

    defaultAlignment: 1
    defaultXOffset: 93
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property double lastData: 0

    // Property status from adsbVehicleManager can be
    // 0 - not active ( if more than 60 seconds since last update )
    // 1 - active but more than 20 seconds since last update
    // 2 - active, less than 20 seconds since last update
    property bool adsbStatus: AdsbVehicleManager.status ? true : false
    property color adsbStatusColor: AdsbVehicleManager.status == 2 ? "green" : "red"


    widgetDetailComponent: ScrollView{

        contentHeight: adsbSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        Column {
            id: adsbSettingsColumn
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
                    id: adsb_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.adsb_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.adsb_opacity = adsb_opacity_Slider.value
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
                    id: adsb_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.adsb_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.adsb_size = adsb_size_Slider.value
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
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Source SDR")
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
                    checked: settings.adsb_api_sdr
                    onCheckedChanged: {
                        settings.adsb_api_sdr = checked;
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Source OpenSky")
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
                    checked: settings.adsb_api_openskynetwork
                    onCheckedChanged: {
                        settings.adsb_api_openskynetwork = checked;
                    }
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
                    id: adsb_distance_Slider
                    orientation: Qt.Horizontal
                    from: 7000
                    value: settings.adsb_distance_limit
                    to: 25000
                    stepSize: 1000
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.adsb_distance_limit = adsb_distance_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        visible: settings.show_adsb
        anchors.fill: parent
        scale: settings.adsb_size

        Text {
            id: adsb_text
            color: settings.color_shape
            opacity: settings.adsb_opacity
            text: "ADS-B"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        StatusIndicator {
            id: adsb_status
            width: 15
            height: 15
            anchors.left: adsb_text.right
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            color: adsbStatusColor
            active: adsbStatus
            visible: !settings.adsb_api_sdr
        }
    }
}
