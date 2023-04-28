import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: bitrateWidget
    width: 112
    height: 48

    visible: settings.show_bitrate

    widgetIdentifier: "bitrate_widget"
    bw_verbose_name: "VIDEO BITRATE CAM1"

    defaultAlignment: 1
    defaultXOffset: 224
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true

    function bitrate_color(curr_set_and_measured_bitrate_mismatch){
        if(curr_set_and_measured_bitrate_mismatch===1){
            return "yellow" // too low
        }else if(curr_set_and_measured_bitrate_mismatch==2){
            return "red" // too high
        }
        return settings.color_text // all ok
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

    widgetActionComponent: ScrollView{

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            width:200
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Set(Enc):")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: _cameraStreamModelPrimary.curr_set_video_codec
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Set(Enc):")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: _cameraStreamModelPrimary.curr_recomended_video_bitrate_string
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Measured(Enc):")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: _cameraStreamModelPrimary.curr_video_measured_encoder_bitrate
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Injected(+FEC):")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: _cameraStreamModelPrimary.curr_video_injected_bitrate
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
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

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 48
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: -2
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 32
            color: bitrate_color(_cameraStreamModelPrimary.curr_set_and_measured_bitrate_mismatch)
            text: _cameraStreamModelPrimary.curr_video0_received_bitrate_with_fec
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            font.family: settings.font_text
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
