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
    width: 75
    height: 25

    z: 4

    visible: settings.show_adsb

    widgetIdentifier: "adsb_widget"
    bw_verbose_name: "ADSB (REQUIRES INTERNET)"


    defaultAlignment: 1
    // Placed below the SOC air / ground statistics by default
    defaultXOffset: 128
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: false

    property double lastData: 0

    // Property status from adsbVehicleManager can be
    // 0 - not active ( if more than 60 seconds since last update )
    // 1 - active but more than 20 seconds since last update
    // 2 - active, less than 20 seconds since last update
    property bool adsbStatus: AdsbVehicleManager.status ? true : false
    property color adsbStatusColor: AdsbVehicleManager.status == 2 ? "green" : "red"

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
                        settings.adsb_api_sdr = checked
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
                        settings.adsb_api_openskynetwork = checked
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Max")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    id: adsb_distance_text
                    text: settings.adsb_distance_limit/1000+"Km"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: adsb_distance_Slider
                    orientation: Qt.Horizontal
                    from: 5000
                    value: settings.adsb_distance_limit
                    to: {
                        if (LimitADSBMax){
                            return 20000; //this is to limit pi... 200km for testing
                        }
                        else{
                            return 50000;
                        }
                    }

                    stepSize: 1000
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: adsb_distance_text.left
                    width: parent.width - 96

                    onValueChanged: {
                        settings.adsb_distance_limit = adsb_distance_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Uknown/Zero Alt Traffic")
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
                    checked: settings.adsb_show_unknown_or_zero_alt
                    onCheckedChanged: {
                        settings.adsb_show_unknown_or_zero_alt = checked
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
