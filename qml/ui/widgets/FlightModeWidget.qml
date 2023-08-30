import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: flightModeWidget
    width: 212
    height: 48

    visible: settings.show_flight_mode

    widgetIdentifier: "flight_mode_widget"
    bw_verbose_name: "FLIGHT MODE"

    defaultAlignment: 3
    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true //--TURN TO TRUE TO SEE THE FLIGHT MODE ACTIONS

    // Needs to be a lot bigger than default:
    widgetActionHeight: 164+ 450

    function close_action_popup(){
        flightModeWidget.bw_manually_close_action_popup()
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            show_vertical_lock: true
            show_horizontal_lock: true

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show disarmed")
                    horizontalAlignment: Text.AlignRight
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
                    checked: settings.flight_mode_show_disarmed
                    onCheckedChanged: settings.flight_mode_show_disarmed = checked
                }
            }
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        clip: true
        contentHeight: flightModeCommandsColumn.height

        Column {
            id: flightModeCommandsColumn
            width: 200
            height: 900
            spacing: 2

            Text {
                text: qsTr("Only For Ardupilot");
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            FlightModeSlider{
                flight_mode_text: "RTL"
            }
            FlightModeSlider{
                flight_mode_text: "STABILIZE"
            }
            FlightModeSlider{
                flight_mode_text: "LOITER"
            }
            FlightModeSlider{
                flight_mode_text: "CIRCLE"
            }
            FlightModeSlider{
                flight_mode_text: "AUTO"
            }
            FlightModeSlider{
                flight_mode_text: "AUTOTUNE"
            }
            FlightModeSlider{
                flight_mode_text: "MANUAL"
            }
            FlightModeSlider{
                flight_mode_text: "FBWA"
            }
            FlightModeSlider{
                flight_mode_text: "FBWB"
            }
            FlightModeSlider{
                flight_mode_text: "QSTABILIZE"
            }
            FlightModeSlider{
                flight_mode_text: "QHOVER"
            }
            FlightModeSlider{
                flight_mode_text: "QLOITER"
            }
            FlightModeSlider{
                flight_mode_text: "QLAND"
            }
            FlightModeSlider{
                flight_mode_text: "QRTL"
            }
            FlightModeSlider{
                flight_mode_text: "ALT_HOLD"
            }
            FlightModeSlider{
                flight_mode_text: "POSHOLD"
            }
            FlightModeSlider{
                flight_mode_text: "ACRO"
            }
            FlightModeSlider{
                flight_mode_text: "GUIDED"
            }
            FlightModeSlider{
                flight_mode_text: "LAND"
            }
            FlightModeSlider{
                flight_mode_text: "SMART_RTL"
            }
            FlightModeSlider{
                flight_mode_text: "ZIGZAG"
            }
            FlightModeSlider{
                flight_mode_text: "AUTO_RTL"
            }
            FlightModeSlider{
                flight_mode_text: "CRUISE"
            }
            FlightModeSlider{
                flight_mode_text: "TAKEOFF"
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        scale: bw_current_scale

        Text {
            id: flight_mode_icon
            width: 24
            height: 48
            color: _fcMavlinkSystem.armed ? "red" : settings.color_shape
            opacity: bw_current_opacity
            text: "\uf072"
            anchors.right: flight_mode_text.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 20
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text {
            id: flight_mode_text
            height: 48
            color: settings.color_text
            opacity: bw_current_opacity
            text: _fcMavlinkSystem.flight_mode
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 24
            font.family: settings.font_text
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Text{
            id: disarmed_text
            height: 48
            width: parent.width
            color: settings.color_text
            opacity: bw_current_opacity
            text: "DISARMED"
            anchors.bottom: parent.top
            anchors.left: parent.left
            bottomPadding: 5
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 24
            font.family: settings.font_text
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
            visible: settings.flight_mode_show_disarmed && (!_fcMavlinkSystem.armed && _fcMavlinkSystem.is_alive)
        }
    }
}
