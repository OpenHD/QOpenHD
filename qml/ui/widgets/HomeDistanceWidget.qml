import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: homeDistanceWidget
    width: 96
    height: 24

    visible: settings.show_home_distance

    widgetIdentifier: "home_distance_widget"
    bw_verbose_name: "HOME DISTANCE"

    defaultAlignment: 2
    defaultXOffset: 0
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    // Needs to be a bit bigger than default
    widgetActionWidth: 256
    widgetActionHeight: 164+30

    // Hides the stuff before decimal, aka returns
    // X.1234...
    function hide_before_decimals(number){
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
    function get_home_latitude(){
        var number=_fcMavlinkSystem.home_latitude
        //if(settings.gps_garble_lat_lon_first_decimals){
        //    return hide_before_decimals(number)
        //}
        if(settings.gps_hide_identity_using_offset){
            number +=settings.hide_identity_latitude_offset;
        }
        return Number(number).toLocaleString(Qt.locale(), 'f', 6)
    }
    function get_home_longitude(){
        var number=_fcMavlinkSystem.home_longitude
        //if(settings.gps_garble_lat_lon_first_decimals){
        //    return hide_before_decimals(number)
        //}
        if(settings.gps_hide_identity_using_offset){
            number +=settings.hide_identity_longitude_offset;
        }
        return Number(number).toLocaleString(Qt.locale(), 'f', 6)
    }

    //----------------------------- DETAIL BELOW ----------------------------------
    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
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
                height: 32
                Text {
                    text: qsTr("Home Lat:")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_home_latitude()
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Home Lon:")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_home_longitude()
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }

            /*Item {
                height: 32
                Text {
                    text: "Only For Ardupilot/PX4"
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                }
            }*/
            FlightModeSlider{
                flight_mode_text: "RTL"
            }
            FlightModeSlider{
                flight_mode_text: "QRTL"
            }

            RowLayout{
                width: parent.width
                height: 32
                Button{
                    height:32
                    id: requestHomeButton
                    text: "Request Home"
                    onClicked: {
                        _fcMavlinkAction.request_home_position_from_fc();
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: bw_current_scale
        opacity: bw_current_opacity

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            color: settings.color_shape
            text: "\uf015"
            anchors.right: home_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: home_distance_text
            width: 64
            height: 24
            color: settings.color_text
            text: {
                var distance = _fcMavlinkSystem.home_distance
                var unit = "m"
                var use_imperial = settings.value("enable_imperial", false)
                // QML settings can return strings for booleans on some platforms so we check
                if (use_imperial === true || use_imperial === 1
                        || use_imperial === "true") {
                    unit = "ft"
                    distance = distance * 3.28084
                }

                return distance.toLocaleString(Qt.locale(), "f", 1) + unit
            }
            elide: Text.ElideNone
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: settings.font_text
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
