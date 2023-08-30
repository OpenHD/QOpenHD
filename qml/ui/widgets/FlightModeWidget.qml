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

    // The commands are a bit different depending on if the user is using arducopter or arduplane / ardu-vtol.
    // QUITE ANNOYING FUCK !!!!
    property bool m_is_arducopter : _fcMavlinkSystem.is_arducopter
    property bool m_is_arduplane:_fcMavlinkSystem.is_arduplane
    property bool m_is_arduvtol: _fcMavlinkSystem.is_arduvtol

    function change_flight_mode(msg_id){
        _fcMavlinkAction.flight_mode_cmd_async(msg_id);
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
        clip: true
        contentHeight: flightModeCommandsColumn.height

        /*
        PLANE_MODE_MANUAL=0,
        PLANE_MODE_CIRCLE=1,
        PLANE_MODE_STABILIZE=2,
        PLANE_MODE_TRAINING=3,
        PLANE_MODE_ACRO=4,
        PLANE_MODE_FLY_BY_WIRE_A=5,
        PLANE_MODE_FLY_BY_WIRE_B=6,
        PLANE_MODE_CRUISE=7,
        PLANE_MODE_AUTOTUNE=8,
        PLANE_MODE_AUTO=10,
        PLANE_MODE_RTL=11,
        PLANE_MODE_LOITER=12,
        PLANE_MODE_TAKEOFF=13

VTOL
00017     17 : 'QSTABILIZE',
00018     18 : 'QHOVER',
00019     19 : 'QLOITER',
00020     20 : 'QLAND',
00021     21 : 'QRTL',

       COPTER_MODE_STABILIZE=0
       COPTER_MODE_ACRO=1
       COPTER_MODE_ALT_HOLD=2
       COPTER_MODE_AUTO=3
       COPTER_MODE_GUIDED=4
       COPTER_MODE_LOITER=5
       COPTER_MODE_RTL=6
       COPTER_MODE_CIRCLE=7
       COPTER_MODE_LAND=9
       COPTER_MODE_DRIFT=11
       COPTER_MODE_SPORT=13
       COPTER_MODE_FLIP=14
       COPTER_MODE_AUTOTUNE=15
       COPTER_MODE_POSHOLD=16
       COPTER_MODE_BRAKE=17
       COPTER_MODE_THROW=18
       COPTER_MODE_AVOID_ADSB=19
       COPTER_MODE_GUIDED_NOGPS=20
       COPTER_MODE_SMART_RTL=21
*/
        Column {
            id: flightModeCommandsColumn
            width: 200
            spacing: 2
            height: 600

            Text {
                height: 32
                text: {
                    return qsTr("Only For Ardupilot");
                }
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("RTL")
                msg_id: {
                    if (m_is_arducopter){
                        return 6;
                    }
                    if (m_is_arduplane || "VTOL"){
                        return 11;
                    }
                    return -1;
                }
                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("STABILIZE")
                msg_id: {
                    if (m_is_arducopter){
                        return 0;
                    }
                    if (m_is_arduplane || "VTOL"){
                        return 2;
                    }
                    return -1;
                }
                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("LOITER")
                msg_id: {
                    if (m_is_arducopter){
                        return 5;
                    }
                    if (m_is_arduplane || "VTOL"){
                        return 12;
                    }
                    return -1;
                }

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("CIRCLE")
                msg_id: {
                    if (m_is_arducopter){
                        return 7;
                    }
                    if (m_is_arduplane || m_is_arduvtol){
                        return 1;
                    }
                    return -1;
                }
                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("AUTO")
                msg_id: {
                    if (m_is_arducopter){
                        return 3;
                    }
                    if (m_is_arduplane || m_is_arduvtol){
                        return 10;
                    }
                }

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: _fcMavlinkSystem.supports_basic_commands

                text_off: qsTr("AUTOTUNE")
                msg_id: {
                    if (m_is_arducopter){
                        return 15;
                    }
                    if (m_is_arduplane ||  m_is_arduvtol){
                        return 8;
                    }
                }

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

  //-----------------------DIFFERNT from plane to copter to vtol

            ConfirmSlider {
                visible: {
                    if (m_is_arduplane ||  m_is_arduvtol){
                        return true;
                    } else {
                        return false;
                    }
                }
                text_off: qsTr("MANUAL")
                msg_id: 0

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: {
                    if (m_is_arduplane ||  m_is_arduvtol){
                        return true;
                    } else {
                        return false;
                    }
                }
                text_off: qsTr("FBWA")
                msg_id: 5

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: {
                    if (m_is_arduplane ||  m_is_arduvtol){
                        return true;
                    } else {
                        return false;
                    }
                }

                text_off: qsTr("FBWB")
                msg_id: 6

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arduvtol

                text_off: qsTr("QSTABILIZE")
                msg_id: 17

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arduvtol

                text_off: qsTr("QHOVER")
                msg_id: 18

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arduvtol

                text_off: qsTr("QLOITER")
                msg_id: 19

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arduvtol

                text_off: qsTr("QLAND")
                msg_id: 20

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arduvtol

                text_off: qsTr("QRTL")
                msg_id: 21

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }

            ConfirmSlider {
                visible: m_is_arducopter

                text_off: qsTr("ALT_HOLD")
                msg_id: 2

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }
            ConfirmSlider {
                visible: m_is_arducopter

                text_off: qsTr("POSHOLD")
                msg_id: 16

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
            }
            ConfirmSlider {
                visible: m_is_arducopter

                text_off: qsTr("ACRO")
                msg_id: 1

                onCheckedChanged: {
                    if (checked == true) {
                        change_flight_mode(msg_id);
                    }
                }
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
