import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: gpsWidget
    implicitWidth: widgetInner.implicitWidth
    implicitHeight: widgetInner.implicitHeight
    width: implicitWidth
    height: implicitHeight

    visible: settings.show_gps && settings.show_widgets

    widgetIdentifier: "gps_widget"
    bw_verbose_name: qsTr("GPS WIDGET")

    defaultAlignment: 2
    defaultXOffset: 171
    defaultYOffset: 160
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    // Hides the stuff before decimal, aka returns
    // X.1234...
    function hide_before_decimals(number){
        /*var truncated = number|0;
        var decimals=number-truncated
        const decimals_as_str=Number(decimals).toLocaleString(Qt.locale(), 'f', 6)
        return "X."+decimals_as_str.slice(2)*/
        var text=Number(number).toLocaleString(Qt.locale(), 'f', 6)
        const myArray = text.split(".");
        let before_decimal = myArray[0];
        var hidden=""
        for (let i = 0; i < before_decimal.length; i++) {
            hidden=hidden+"-"
        }
        hidden+="."
        let after_decimal = myArray[1];
        //return before_decimal+"."+after_decimal
        return hidden+after_decimal
    }

    // garbles the first decimals if wanted
    function get_latitude(){
        var number=_fcMavlinkSystem.lat
        //if(settings.gps_garble_lat_lon_first_decimals){
        //    return hide_before_decimals(number)
        //}
        if(settings.gps_hide_identity_using_offset){
            number +=settings.hide_identity_latitude_offset;
        }
        return Number(number).toLocaleString(Qt.locale(), 'f', 6)
    }
    function get_longitude(){
        var number=_fcMavlinkSystem.lon
        //if(settings.gps_garble_lat_lon_first_decimals){
        //    return hide_before_decimals(number)
        //}
        if(settings.gps_hide_identity_using_offset){
            number +=settings.hide_identity_longitude_offset;
        }
        return Number(number).toLocaleString(Qt.locale(), 'f', 6)
    }

    function gps_stats_visible() {
        if (_fcMavlinkSystem.gps_hdop >= settings.gps_warn) {
            return true;
        }
        if (_fcMavlinkSystem.gps_hdop > settings.gps_caution) {
            return true;
        }
        if (settings.gps_declutter == true && _fcMavlinkSystem.armed == true) {
            return false;
        }
        return true;
    }

    function gps_stats_color() {
        if (_fcMavlinkSystem.gps_hdop >= settings.gps_warn) {
            return settings.color_warn;
        }
        if (_fcMavlinkSystem.gps_hdop > settings.gps_caution) {
            return settings.color_caution;
        }
        return settings.color_text;
    }


    //----------------------------- DETAIL BELOW ----------------------------------
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
                    text: qsTr("Lat/Lon only")
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
                    checked: settings.gps_show_all
                    onCheckedChanged: settings.gps_show_all = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Hide identity")
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
                    checked: settings.gps_hide_identity_using_offset
                    onCheckedChanged: {
                        if(settings.gps_hide_identity_using_offset != checked && checked){
                            if(settings.hide_identity_latitude_offset==0.0 || settings.hide_identity_longitude_offset==0.0){
                                _messageBoxInstance.set_text_and_show(qsTr("Your identity is only hidden if you set custom offset values for lat,lon. Go to QOpenHD/General and set custom values."),10);
                            }
                        }
                        settings.gps_hide_identity_using_offset = checked
                    }
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
                    checked: settings.gps_declutter
                    onCheckedChanged: settings.gps_declutter = checked
                }
            }
            Item {
                id: gps_warn_label
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Warn HDOP")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.gps_warn
                    color: settings.color_warn
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: gps_warn_label.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: gps_warn_Slider
                    orientation: Qt.Horizontal
                    from: 3
                    value: settings.gps_warn
                    to: 6
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.gps_warn = Math.round(
                                    gps_warn_Slider.value * 10) / 10.0
                    }
                }
            }
            Item {
                id: gps_caution_label
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Caution HDOP")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: settings.gps_caution
                    color: settings.color_caution
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: gps_caution_label.right
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: gps_caution_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.gps_caution
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.gps_caution = Math.round(
                                    gps_caution_Slider.value * 10) / 10.0
                    }
                }
            }
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            width: 200
            Item {
                width: parent.width
                height: 20
                Text {
                    text: qsTr("Lat:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_latitude()
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
                    text: qsTr("Lon:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_longitude()
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
                    text: qsTr("GPS Count:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: qsTr(""+_fcMavlinkSystem.satellites_visible)
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
                    text: qsTr("GPS Lock:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: qsTr(""+_fcMavlinkSystem.gps_status_fix_type_str)
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
                    text: qsTr("HDOP:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(_fcMavlinkSystem.gps_hdop).toLocaleString(Qt.locale(), 'f', 1)
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
                    text: qsTr("VDOP:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Number(_fcMavlinkSystem.gps_vdop).toLocaleString(Qt.locale(), 'f', 1)
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: bw_current_scale
        visible: settings.gps_show_all || gps_stats_visible()

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 2

            Row {
                id: latRow
                spacing: 6
                height: 16
                visible: settings.gps_show_all
                Text {
                    id: lat_onscreen
                    text: get_latitude()
                    color: settings.color_text
                    opacity: bw_current_opacity
                    font.bold: true
                    font.family: settings.font_text
                    height: parent.height
                    width: 120
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                id: lonRow
                spacing: 6
                height: 16
                visible: settings.gps_show_all
                Text {
                    id: lon_onscreen
                    text: get_longitude()
                    color: settings.color_text
                    opacity: bw_current_opacity
                    font.bold: true
                    font.family: settings.font_text
                    height: parent.height
                    width: 120
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }

            Row {
                id: statsRow
                spacing: 6
                height: 24
                visible: !settings.gps_show_all && gps_stats_visible()
                Text {
                    id: satellite_icon
                    width: 24
                    height: 24
                    color: settings.color_shape
                    opacity: bw_current_opacity
                    text: "\uf0ac"
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
                Text {
                    id: satellites_visible
                    width: 24
                    height: 24
                    color: gps_stats_color()
                    opacity: bw_current_opacity
                    text: _fcMavlinkSystem.satellites_visible
                    elide: Text.ElideNone
                    clip: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 16
                    font.family: settings.font_text
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
                Text {
                    id: gps_hdop
                    width: 48
                    height: 24
                    color: gps_stats_color()
                    opacity: bw_current_opacity
                    text: qsTr("%L1").arg(_fcMavlinkSystem.gps_hdop)
                    verticalAlignment: Text.AlignTop
                    font.pixelSize: 10
                    font.family: settings.font_text
                    horizontalAlignment: Text.AlignLeft
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
        }

        implicitWidth: contentColumn.implicitWidth
        implicitHeight: contentColumn.implicitHeight
    }
}
