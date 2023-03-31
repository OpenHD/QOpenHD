import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {

    id: missionWidget
    width: 96
    height: 25

    visible: settings.show_mission

    widgetIdentifier: "mission_widget"
    bw_verbose_name: "MISSIONS"

    defaultAlignment: 2
    defaultXOffset: 50
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    // Needs to be a bit bigger than default:
    widgetActionHeight: 164+ 100

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
                height: 32
                Text {
                    text: "Only For Ardupilot/PX4"
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                }
            }

            ConfirmSliderEnableDisable {
                id: confirmSliderEnableUpdates
                visible: _fcMavlinkSystem.supports_basic_commands
                text_off: qsTr("Enable updates")
                text_on: qsTr("Disable updates");

                onCheckedChanged: {
                    if(error_last){
                        error_last=false;
                        return;
                    }
                    var res=false
                    if (checked == true) {
                        res=_fcMavlinkSystem.enable_disable_mission_updates(true);
                        if(res===false){
                            error_last=true;
                            checked = !checked;
                        }
                    }else{
                        res=_fcMavlinkSystem.enable_disable_mission_updates(false);
                        if(res===false){
                            error_last=true;
                            checked = !checked;
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 20
                Text {
                    text: qsTr("Waypoints curr/total:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: qsTr(_fcMavlinkSystem.mission_waypoints_current+"/"+_fcMavlinkSystem.mission_waypoints_current_total)
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
                    text: qsTr("Type:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: qsTr(_fcMavlinkSystem.mission_current_type)
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
        opacity: bw_current_opacity
        scale: bw_current_scale

        Item {
            anchors.fill: parent
            anchors.centerIn: parent

            Text {
                id: mission_description
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: qsTr(
                          "Mission") + ": " + qsTr(_fcMavlinkSystem.mission_waypoints_current+"/"+_fcMavlinkSystem.mission_waypoints_current_total)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
