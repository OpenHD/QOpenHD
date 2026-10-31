import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0

// This is a base implementation for all HUD widgets -
// e.g. it exposes the dragging around, clicking once and clicking long action(s)
// for clicking once, set hasWidgetDetail to true and provide the widgetDetailComponent
// same for long press
// Action widget: Opened when the user (short) clicks on the widget
// Detail widget: Opened when the user long clicks on the widget
BaseWidgetForm {
    id: widgetBase
    visible:false
    Drag.active: dragging
    Drag.dragType: Drag.Internal

    // Used to uniquely identify persistent settings for this widget. Should only contain lowercase letters and "_" (aka no blank space, extra characters and more)
    property string widgetIdentifier
    readonly property bool widgetGalleryPreview: typeof hudOverlayGrid !== "undefined" && hudOverlayGrid.widgetGalleryPreviewActive === true
    // Example telemetry is confined to the hidden gallery drawing. The live
    // model and saved OSD preferences are never changed.
    function previewTelemetry(model, key, realValue) {
        if (!widgetGalleryPreview) return realValue
        var sample = model === "_fcMavlinkSystem" ? {
            is_alive:true,armed:false,flight_mode:"MANUAL",roll:0,pitch:0,hdg:85,
            home_heading:45,home_course:45,home_distance:1200,home_latitude:51.26,home_longitude:7.15,
            lat:51.27,lon:7.16,altitude_rel_m:120,altitude_msl_m:350,
            ground_speed_meter_per_second:15,air_speed_meter_per_second:16,speed:54,airspeed:58,
            vertical_speed_indicator_mps:1.5,aoa:5,vehicle_vx_angle:0,vehicle_vz_angle:0,
            throttle:58,rc_rssi_percentage:85,satellites_visible:14,gps_fix_type:3,gps_status_fix_type_str:"3D Fix",gps_hdop:0.8,gps_vdop:1.1,
            battery_voltage_volt:15.4,battery_voltage_single_cell:3.85,battery_percent:72,battery_percent_gauge:72,battery_current_ampere:4.2,
            battery_consumed_mah:850,battery_consumed_mah_per_km:125,battery_temperature:28,
            battery_id0_voltage_volt:15.4,battery_id0_current_ampere:4.2,battery_id0_consumed_mah:850,battery_id0_remaining_time_s:540,
            battery_id1_voltage_volt:15.4,battery_id1_current_ampere:0.4,battery_id1_consumed_mah:250,battery_id1_remaining_time_s:900,
            flight_time:"00:06:21",flight_distance_m:2400,sys_time_unix_as_str:"14:26:00",sys_time_unix_usec:1700000000000000,
            imu_temp_degree:42,esc_temp:38,preasure_sensor_temperature_degree:25,preasure_sensor2_temperature_degree:26,preasure_sensor3_temperature_degree:27,airspeed_sensor_temperature_degree:24,
            distance_sensor_distance_cm:250,vibration_x:4,vibration_y:3,vibration_z:5,wind_speed:3,mav_wind_speed:3,wind_direction:45,mav_wind_direction:45
        } : model === "_cameraStreamModelPrimary" || model === "_cameraStreamModelSecondary" ? {
            camera_status:1,camera_type:32,encoding_codec:"H.264",curr_set_and_measured_bitrate_mismatch:0,curr_delta_tx_dropped_frames:0,curr_received_bitrate_with_fec:"11.5 Mbit/s",air_recording_active:false,curr_set_video_format:"1920x1080@60",curr_video_measured_encoder_bitrate:"9.1 Mbit/s",curr_video_injected_bitrate:"11.5 Mbit/s",curr_recomended_video_bitrate_string:"9.1 Mbit/s",
            curr_fec_percentage:20,curr_keyframe_interval:5,curr_missing_packets_per_second:0,curr_retransmission_packets_per_second:2,curr_retransmission_requests_per_second:1,
            count_blocks_lost:0,count_blocks_recovered:12,count_fragments_recovered:24,total_n_tx_dropped_frames:0,
            curr_fec_block_length_min_max_avg:"8 / 12 / 10",curr_fec_decode_time_avg_min_max:"0.2 / 0.1 / 0.4 ms",curr_fec_encode_time_avg_min_max:"0.2 / 0.1 / 0.4 ms",curr_time_until_tx_min_max_avg:"1 / 3 / 2 ms",air_tx_packets_per_second_and_bits_per_second:"1200 pps / 11.5 Mbit/s"
        } : model.indexOf("_wifi_card_")===0 ? {
            alive:true,card_type_as_string:"RTL8812AU",devourer_quality_valid:true,devourer_link_health:95,rx_evm_db:-28,rx_snr_antenna1:32,rx_snr_antenna2:31,tx_power:100,tx_power_unit:"%"
        } : {
            is_alive:true,curr_cpuload_perc:24,curr_soc_temp_degree:46,ram_usage_perc:32,curr_cpu_freq_mhz:1500,curr_core_freq_mhz:500,curr_h264_freq_mhz:500,curr_isp_freq_mhz:500,curr_v3d_freq_mhz:500,
            current_rx_rssi:-48,current_rx_signal_quality:95,curr_rx_packet_loss_perc:1,curr_channel_mhz:5745,curr_channel_width_mhz:20,curr_mcs_index:2,curr_bitrate_kbits:11500,received_link_bitrate_bps:11500000,
            curr_rx_last_packet_status_good:true,radio_temperature_display_text:"42 C",radio_temperature_state:0,radio_temperature_state_text:"Normal",rpi_undervolt_error:false,dbm_too_low_warning:false,
            ina219_voltage_millivolt:15400,ina219_current_milliamps:450,curr_space_left_mb:8192,count_tx_dropped_packets:0,count_tx_inj_error_hint:0,curr_n_rate_adjustments:0,tx_is_currently_dropping_packets:false,wb_link_curr_foreign_pps:0,
            rx_packets_per_second_and_bits_per_second:"1200 pps / 11.5 Mbit/s",tx_packets_per_second_and_bits_per_second:"1200 pps / 11.5 Mbit/s",rx_tele_packets_per_second_and_bits_per_second:"25 pps / 18 kbit/s",tx_tele_packets_per_second_and_bits_per_second:"25 pps / 18 kbit/s"
        }
        return sample[key] !== undefined ? sample[key] : realValue
    }
    property int widgetPreviewRevision: 0
    function refreshWidgetPreviewBounds() { widgetPreviewRevision++ }
    // Visual extent used by the widget gallery; subclasses may draw beyond their root.
    property Item widgetPreviewContent: null
    property rect widgetPreviewRect: widgetPreviewContent ? previewBoundsForTree(widgetPreviewContent) : Qt.rect(Math.min(0,width*(1-bw_current_scale)/2)-4, Math.min(0,height*(1-bw_current_scale)/2)-4, width*Math.max(1,bw_current_scale)+8, height*Math.max(1,bw_current_scale)+8)
    function previewBoundsForTree(content) {
        var revision=widgetPreviewRevision
        var left=Infinity,top=Infinity,right=-Infinity,bottom=-Infinity
        function visit(item,depth) {
            if(!item || depth>12)return
            var w=item.width||0,h=item.height||0
            if(item.text!==undefined && item.clip!==true) {
                w=Math.max(w,item.implicitWidth||0)
                h=Math.max(h,item.implicitHeight||0)
            }
            if(w>0 && h>0) {
                var points=[item.mapToItem(widgetBase,0,0),item.mapToItem(widgetBase,w,0),item.mapToItem(widgetBase,0,h),item.mapToItem(widgetBase,w,h)]
                for(var n=0;n<points.length;n++) {
                    left=Math.min(left,points[n].x);top=Math.min(top,points[n].y)
                    right=Math.max(right,points[n].x);bottom=Math.max(bottom,points[n].y)
                }
            }
            if(item.clip)return
            var children=item.children||[]
            for(var i=0;i<children.length;i++)visit(children[i],depth+1)
        }
        visit(content,0)
        return right>left && bottom>top ? Qt.rect(left-4,top-4,right-left+8,bottom-top+8) : Qt.rect(0,0,width,height)
    }
    // Include transformed drawings outside the widget's placement rectangle.
    // This is capture metadata only; it never resizes or moves the live widget.
    function previewBoundsFor(item, area, includePlacement) {
        var revision=widgetPreviewRevision
        var r = area || Qt.rect(0,0,item.width,item.height)
        var points = [item.mapToItem(widgetBase,r.x,r.y), item.mapToItem(widgetBase,r.x+r.width,r.y),
                      item.mapToItem(widgetBase,r.x,r.y+r.height), item.mapToItem(widgetBase,r.x+r.width,r.y+r.height)]
        var include=includePlacement !== false
        var left=include?0:Infinity,top=include?0:Infinity,right=include?width:-Infinity,bottom=include?height:-Infinity
        for(var i=0;i<points.length;i++) {
            left=Math.min(left,points[i].x);top=Math.min(top,points[i].y)
            right=Math.max(right,points[i].x);bottom=Math.max(bottom,points[i].y)
        }
        return Qt.rect(left-3,top-3,right-left+6,bottom-top+6)
    }
    // Shown to the user as a more verbose description of what this widget does
    property string bw_verbose_name: qsTr("PLS FILL ME")

    // Show a "hand" icon to let the user know where to touch to drag the widget around.
    // Only used by "MAP" right now (to my knowledge)
    property bool useDragHandle: false
    // I think you can set this one to 2 for example if you want to align from the lower right corner
    property int defaultAlignment: 0
    property int defaultXOffset: 0
    property int defaultYOffset: 0
    property bool defaultHCenter: false
    property bool defaultVCenter: false

    property int detailPanelFontPixels: 13

    property bool dragging: false

    property bool isFullScreen: false

    property string alignmentIdentifier: "%1_align".arg(widgetIdentifier);
    property string xOffsetIdentifier: "%1_x_offset".arg(widgetIdentifier);
    property string yOffsetIdentifier: "%1_y_offset".arg(widgetIdentifier);
    property string hCenterIdentifier: "%1_h_center".arg(widgetIdentifier);
    property string vCenterIdentifier: "%1_v_center".arg(widgetIdentifier);
    property double oldOpacity: 100;

    // Feature persist scale begin --------------------------------------------------------------------------------------
    // Pretty much all widgets have a scale (previously often called size) setting
    // Properly resizing the widget elements itself is the responsibility of the upper implementation -
    // This base class implements the neccessary tools to resize, though. In short, we do
    // 1) Store the scale unique for this widget persistently
    // 2) expose its current value via a property variable
    // 3) have a simple util method to set the scale
    property string bw_scale_identifier: "%1_scale".arg(widgetIdentifier);
    // Default scale is 1, the value is persistent
    property double bw_current_scale : settings.value(bw_scale_identifier,1.0);
    // Updates the current base widget scale (unique per widgetIdentifier) and persist the value for later use
    function bw_set_current_scale(scale){
        if(scale <=0 || scale>=500){
            console.warn("perhaps invalid widget scale");
        }
        bw_current_scale=scale
        settings.setValue(bw_scale_identifier, bw_current_scale);
        settings.sync();
    }
    // Feature persist scale end   --------------------------------------------------------------------------------------

    // Feature persist background color begin --------------------------------------------------------------------------
    property string bw_background_color_identifier: "%1_bg_color".arg(widgetIdentifier);
    property string bw_current_background_color: settings.value(bw_background_color_identifier, "#000000");
    property bool bw_background_color_normalizing: false
    function bw_normalize_background_color(value){
        if (typeof value === "string") {
            if (value.length === 9 && value[0] === "#") {
                return "#" + value.substr(3);
            }
            return value;
        }
        if (value && typeof value === "object"
                && value.r !== undefined
                && value.g !== undefined
                && value.b !== undefined) {
            var r = Math.round(value.r * 255).toString(16);
            var g = Math.round(value.g * 255).toString(16);
            var b = Math.round(value.b * 255).toString(16);
            if (r.length < 2) r = "0" + r;
            if (g.length < 2) g = "0" + g;
            if (b.length < 2) b = "0" + b;
            return "#" + r + g + b;
        }
        return value;
    }
    onBw_current_background_colorChanged: {
        if (bw_background_color_normalizing) {
            return;
        }
        bw_background_color_normalizing = true;
        var normalized = bw_normalize_background_color(bw_current_background_color);
        if (normalized !== bw_current_background_color) {
            bw_current_background_color = normalized;
        }
        settings.setValue(bw_background_color_identifier, normalized);
        if (bw_background_color_identifier === "link_overview_widget_bg_color"
                && settings.link_overview_widget_bg_color !== normalized) {
            settings.link_overview_widget_bg_color = normalized;
        }
        settings.sync();
        bw_background_color_normalizing = false;
    }
    // Feature persist background color end   ----------------------------------------------------------------------------

    // Feature persist opacity begin ------------------------------------------------------------------------------------
    property string bw_opacity_identifier: "%1_opacity".arg(widgetIdentifier);
    // Default opacity is 1, the value is persistent
    property double bw_current_opacity : settings.value(bw_opacity_identifier,1.0);
    // Updates the current base widget scale (unique per widgetIdentifier) and persist the value for later use
    function bw_set_current_opacity(opacity){
        if(opacity <=0 || opacity>1){
            console.warn("perhaps invalid widget opacity");
        }
        bw_current_opacity=opacity
        settings.setValue(bw_opacity_identifier, bw_current_opacity);
        settings.sync();
    }
    // Feature persist opacity end --------------------------------------------------------------------------------------

    // Feature persist 'qquickpainteditem_font_scale' begin  ------------------------------------------------------------
    // only for qquick painted items (few)
    property string bw_qquickpainteditem_font_scale_identifier: "%1_qquickpainteditem_font_scale".arg(widgetIdentifier);
    property double bw_qquickpainteditem_font_scale: settings.value(bw_qquickpainteditem_font_scale_identifier,1.0);
    function bw_set_qquickpainteditem_font_scale(scale){
        bw_qquickpainteditem_font_scale=scale;
        settings.setValue(bw_qquickpainteditem_font_scale_identifier,bw_qquickpainteditem_font_scale);
        settings.sync();
    }
    // Feature persist 'qquickpainteditem_font_scale' end  --------------------------------------------------------------


    // Feature: Show grid when dragging
    property bool m_show_grid_when_dragging: false
    onDraggingChanged: {
        if(dragging && m_show_grid_when_dragging){
            hudOverlayGrid.m_show_horizontal_center_indicator=true;
            hudOverlayGrid.m_show_vertical_center_indicator=true
        }else{
            hudOverlayGrid.m_show_horizontal_center_indicator=false;
            hudOverlayGrid.m_show_vertical_center_indicator=false;
        }
    }



    // Added by Consti10 -
    // disable dragging for this widget (dragging is enabled by default)
    // Needed for the HUD log messages element, since it sits above the secondary video and disabling its "mouse area"
    // Was the easiest fix
    property bool disable_dragging: false
    property bool spanParentWidth: false
    // ---------------------------------------------------------------------
    // Custom keyboard KeyNavigation
    // DIRTY
    function dirty_open_action_popup(){
        widgetAction.open()
    }
    function dirty_close_action_popup(){
        widgetAction.close()
    }

    function dirty_open_close_action_popup(){
        if(widgetAction.opened){
            widgetAction.close()
        }else{
            widgetAction.open()
        }
    }


    // Can be called by the imp. to manually close the action popup
    function bw_manually_close_action_popup(){
        widgetAction.close()
    }

    // react to the user opening the (currently focused) widget
    Keys.onPressed: (event)=> {
        console.log("BaseWidget "+widgetIdentifier+" Key was pressed:"+event);
        if (event.key == Qt.Key_Return) {
            console.log("enter was pressed");
            event.accepted = true;
            dirty_open_action_popup()
        }else if(event.key == Qt.Key_Left){
            console.log("left was pressed")
            event.accepted=true;
            // TODO: Go to the next item
            event.accepted=true;
        }else if(event.key == Qt.Key_Right){
            console.log("right was pressed")
            event.accepted=true;
            // TODO: Go to the next item
        }
    }

    //layer.enabled: false

    /*Connections {
        target: link
        function onWidgetLocation(widgetName, alignment, xOffset, yOffset, hCenter, vCenter, full) {
            if (widgetIdentifier === widgetName) {
                setAlignment(alignment, xOffset, yOffset, hCenter, vCenter, false);
            }
        }
    }*/

    Component.onCompleted: {
        loadAlignment();
        saveAlignment();
        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
        settings.setValue(hCenterIdentifier, _hCenter)
        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
        settings.setValue(vCenterIdentifier, _vCenter)
        settings.sync();
    }

    SequentialAnimation {
        running: dragging

        onFinished: {
            if (dragging) {
                restart()
            }
        }
        alwaysRunToEnd: true

        animations: [
            RotationAnimator { target: dragHandle; from: 0; to: 2; duration: 200 * 0.4 },
            RotationAnimator { target: dragHandle; from: 2; to: 0; duration: 200 * 0.4 },
            RotationAnimator { target: dragHandle; from: 0; to: -2; duration: 200 * 0.4 },
            RotationAnimator { target: dragHandle; from: -2; to: 0; duration: 200 * 0.4 }
        ]
    }

    Timer {
        interval: 50;
        running: dragging;
        repeat: true
        onTriggered: {
            var point = calculateOffsets();
            var _xOffset = point.x;
            var _yOffset = point.y;

            var _hCenter = getHCenter();
            var _vCenter = getVCenter();
        }
    }

    function _onClicked(drag) {
        if (dragging) {
            drag.target = null
            widgetDetail.close()
            saveAlignment()
            loadAlignment()
            dragging = false
            globalDragLock = false
        } else if (hasWidgetPopup) {
            widgetPopup.open()
        } else if (hasWidgetAction) {
            if (widgetAction.visible) {
                widgetAction.close()
            }
            else if (widgetDetail.visible) {
                widgetDetail.close()
                dragging = false

                //widgetControls.close()

                saveAlignment()

                loadAlignment()
                globalDragLock = false
            }
            else {
                if (globalDragLock) {
                    return;
                }
                // A bit dirty - different action
                if(widgetIdentifier=="wb_link_rate_control_widget"){
                    sidebar.open_link_category();
                }else{
                    widgetAction.open()
                }
            }
        }
    }

    function _onPressAndHold(drag) {
        if (!dragging) {
            if (globalDragLock) {
                return;
            }
            globalDragLock = true
            dragging = true

            /*
                 * Unlock the element anchors so it can be dragged. They'll be enabled
                 * again when the widget is done being moved, if the selected alignment
                 * type requires them.
                 */
            resetAnchors()
            drag.target = widgetBase
            //widgetControls.open() ///-------------this is the arrow window
            //widgetDetail.open()

        } else {
            drag.target = null
            widgetDetail.close()
            saveAlignment()
            loadAlignment()
            dragging = false
            globalDragLock = false
        }
    }


    Text {
        id: dragHandle
        color: "white"
        text: "\uf256"
        font.family: "Font Awesome 5 Free"
        z: 2.0
        visible: useDragHandle && !isFullScreen
        enabled: useDragHandle && !isFullScreen
        width: 24
        height: 24
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        MouseArea {
            id: dragHandleMouseArea
            z: 3.0
            enabled: useDragHandle
            anchors.fill: parent
            onClicked: {
                _onClicked(drag)
            }
            onPressAndHold: {
                oldOpacity = dragHandle.opacity
                dragHandle.opacity = 100
                _onPressAndHold(drag)
            }
            onReleased: {
                dragHandle.opacity = oldOpacity
                _onClicked(drag)
            }
        }
    }


    MouseArea {
        id: dragArea

        enabled: ! disable_dragging;

        anchors.fill: parent

        onClicked: { _onClicked(drag) }

        onPressAndHold: { _onPressAndHold(drag) }

        onReleased: {
            if (dragging) widgetDetail.open();
        }

    }

    function calculateOffsets() {
        var _xOffset;
        var _yOffset;

        switch (alignmentType) {
        case 0:
            _xOffset = x;
            _yOffset = y;
            break;
        case 1:
            _xOffset = parent.width - (x + width);
            _yOffset = y;
            break;
        case 2:
            _xOffset = parent.width - (x + width);
            _yOffset = parent.height - (y + height);
            break;
        case 3:
            _xOffset = x;
            _yOffset = parent.height - (y + height);
            break;
        }
        if (_xOffset+width>parent.width) {
        _xOffset = parent.width-width}
        if (_xOffset<0){
        _xOffset = 0}
        if (_yOffset<0){
        _yOffset = 0}

        return Qt.point(_xOffset, _yOffset);
    }

    function saveAlignment() {
        var point = calculateOffsets();
        var _xOffset = point.x;
        var _yOffset = point.y;

        settings.setValue(alignmentIdentifier, alignmentType);
        settings.setValue(xOffsetIdentifier, _xOffset);
        settings.setValue(yOffsetIdentifier, _yOffset);
        settings.sync();

        var _hCenter = getHCenter();
        var _vCenter = getVCenter();

        //link.setWidgetLocation(widgetIdentifier, alignmentType, _xOffset, _yOffset, _hCenter, _vCenter)
    }

    /*
     * This is completely absurd and shouldn't be necessary, but here we are...
     *
     * For some reason, this returns strings on Linux and booleans on every other platform.
     */
    function getHCenter() {
        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter);
        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
            _hCenter = true;
        } else {
            _hCenter = false;
        }
        return _hCenter;
    }

    function getVCenter() {
        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter);
        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
            _vCenter = true;
        } else {
            _vCenter = false;
        }
        return _vCenter;
    }

    function loadAlignment() {
        alignmentType = settings.value(alignmentIdentifier, defaultAlignment);

        var _hCenter = getHCenter();
        var _vCenter = getVCenter();

        var xOffset = settings.value(xOffsetIdentifier, defaultXOffset);
        var yOffset = settings.value(yOffsetIdentifier, defaultYOffset);

        setAlignment(alignmentType, xOffset, yOffset, _hCenter, _vCenter, false);
    }

    function setAlignment(alignmentType, xOffset, yOffset, hCenter, vCenter, full) {
        /*
         * Anchors have to be cleared before any of them can be set again. This is documented
         * at https://doc.qt.io/qt-5/qtquick-positioning-anchors.html#changing-anchors
         */
        resetAnchors();
        isFullScreen = full;

        if (full) {
            anchors.top = parent.top;
            anchors.topMargin = yOffset;
            anchors.bottom = parent.bottom;
            anchors.bottomMargin = yOffset;
            anchors.left = parent.left;
            anchors.leftMargin = xOffset;
            anchors.right = parent.right;
            anchors.rightMargin = xOffset;
        } else if (alignmentType === 0) {
            if (vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.top = parent.top;
                anchors.topMargin = yOffset;
            }
            if (hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.left = parent.left;
                anchors.leftMargin = xOffset;
            }
        } else if (alignmentType === 1) {
            if (vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.top = parent.top;
                anchors.topMargin = yOffset;
            }
            if (hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.right = parent.right;
                anchors.rightMargin = xOffset;
            }
        } else if (alignmentType === 2) {
            if (vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.bottom = parent.bottom;
                anchors.bottomMargin = yOffset;
            }
            if (hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.right = parent.right;
                anchors.rightMargin = xOffset;
            }
        } else if (alignmentType === 3) {
            if (vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.bottom = parent.bottom;
                anchors.bottomMargin = yOffset;
            }
            if (hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.left = parent.left;
                anchors.leftMargin = xOffset;
            }
        }
        if (spanParentWidth && !full) {
            anchors.horizontalCenter = undefined;
            anchors.left = parent.left;
            anchors.right = parent.right;
            anchors.leftMargin = 0;
            anchors.rightMargin = 0;
        }
    }


    function moveUp() { widgetBase.y -= 1; }
    function moveRight() { widgetBase.x += 1; }
    function moveLeft() { widgetBase.x -= 1; }
    function moveDown() { widgetBase.y += 1; }


    function resetAnchors() {
        widgetBase.anchors.top = undefined;
        widgetBase.anchors.topMargin = 0;
        widgetBase.anchors.right = undefined;
        widgetBase.anchors.rightMargin = 0;
        widgetBase.anchors.left = undefined;
        widgetBase.anchors.leftMargin = 0;
        widgetBase.anchors.bottom = undefined;
        widgetBase.anchors.bottomMargin = 0;
        widgetBase.anchors.verticalCenter = undefined;
        widgetBase.anchors.horizontalCenter = undefined;
    }
}
