import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

// Generic since we use the same widget for primary and secondary camera (allbei with different values, of course)
BaseWidget {
    id: bitrateWidget
    width: 112
    height: 48

    property bool m_is_for_primary_camera: true

    widgetIdentifier: m_is_for_primary_camera ? "bitrate_widget" : "bitrate_widget2"
    bw_verbose_name: m_is_for_primary_camera ? "VIDEO BITRATE CAM1" : "VIDEO BITRATE CAM2"

    defaultAlignment: 1
    defaultXOffset: 224
    defaultYOffset: m_is_for_primary_camera ? 0 : 50
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    hasWidgetAction: true
    widgetActionHeight: 400

    property var m_camera_stream_model: m_is_for_primary_camera ? _cameraStreamModelPrimary : _cameraStreamModelSecondary

    // param - so therefore might not be always synchronized
    property string m_curr_video_format:  m_is_for_primary_camera ? _cameraStreamModelPrimary.curr_set_video_format : _cameraStreamModelSecondary.curr_set_video_format


    function bitrate_color(curr_set_and_measured_bitrate_mismatch){
        if(curr_set_and_measured_bitrate_mismatch===1){
            return "yellow" // too low
        }else if(curr_set_and_measured_bitrate_mismatch==2){
            return "red" // too high
        }
        return settings.color_text // all ok
    }

    function set_camera_resolution(resolution_str){
        if(m_is_for_primary_camera){
           _wbLinkSettingsHelper.set_param_video_resolution_framerate_async(true,resolution_str)
        }else{
            _wbLinkSettingsHelper.set_param_video_resolution_framerate_async(false,resolution_str)
        }
    }
    function get_drop_str_tx_rx(){
        //return _cameraStreamModelPrimary.total_n_tx_dropped_frames+":"+_cameraStreamModelPrimary.count_blocks_lost;
        //return m_camera_stream_model.curr_delta_tx_dropped_frames+":"+m_camera_stream_model.total_n_tx_dropped_frames
        return m_camera_stream_model.total_n_tx_dropped_frames+":"+m_camera_stream_model.count_blocks_lost;
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
                    text: m_camera_stream_model.curr_set_video_format_and_codec
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
                    text: m_camera_stream_model.curr_recomended_video_bitrate_string
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
                    text: m_camera_stream_model.curr_video_measured_encoder_bitrate
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
                    text: m_camera_stream_model.curr_video_injected_bitrate
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
                    text: qsTr("TX Dropped/RX lost:")
                    color: "white"
                    font.bold: true
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: get_drop_str_tx_rx()
                    color: "white";
                    font.bold: true;
                    height: parent.height
                    font.pixelSize: detailPanelFontPixels;
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item{
                width: parent.width
                height: 150
                //color: "green"
                GridLayout{
                    width: parent.width
                    height: parent.height
                    rows: 3
                    columns: 2 //
                    // 1 dummy sw
                    // 2 mmal
                    // 3 veye
                    // 4 libcamera
                    enabled: (m_camera_stream_model.camera_type==1 || m_camera_stream_model.camera_type==2 || m_camera_stream_model.camera_type==4)
                    Button{
                        text: "480p60(16:9)"
                        onClicked: set_camera_resolution("848x480@60")
                        highlighted: m_curr_video_format=="848x480@60"
                    }
                    Button{
                        text: "480p60(4:3)"
                        onClicked: set_camera_resolution("640x480@60")
                        highlighted: m_curr_video_format=="640x480@60"
                    }
                    Button{
                        text: "720p49(16:9)"
                        onClicked: set_camera_resolution("1280x720@49")
                        highlighted: m_curr_video_format=="1280x720@49"
                    }
                    Button{
                        text: "720p60(4:3)"
                        onClicked: set_camera_resolution("960x720@60")
                        highlighted: m_curr_video_format=="960x720@60"
                    }
                    Button{
                        text: "1080p30(16:9)"
                        onClicked: set_camera_resolution("1920x1080@30")
                        highlighted: m_curr_video_format=="1920x1080@30"
                    }
                    Button{
                        text: "1080p30(4:3)"
                        onClicked: set_camera_resolution("1440x1080@30")
                        highlighted: m_curr_video_format=="1440x1080@30"
                    }
                }
            }
            /*Item{
                id: placeholder
                width:parent.width
                height: 10
            }*/
            Item {
                width: parent.width
                height: 32
                visible: !m_is_for_primary_camera
                Button{
                    text: "Switch primary & secondary"
                    onClicked: settings.qopenhd_switch_primary_secondary = !settings.qopenhd_switch_primary_secondary
                    highlighted: settings.qopenhd_switch_primary_secondary == true
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
            color: bitrate_color(m_camera_stream_model.curr_set_and_measured_bitrate_mismatch)
            text: m_camera_stream_model.curr_received_bitrate_with_fec
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
