import QtQuick 2.12
import Qt.labs.settings 1.0



Settings {
    id: settings

    property double global_scale: 1.0
    // Set a custom font dpi instead of QT high dpi auto scaling.
    // Requires restart to be applied
    property int screen_custom_font_dpi: 0

    // Dirty, rotate everything even though that can create issues
    property int general_screen_rotation: 0

    property string locale: "en"

    property int dev_stream0_udp_rtp_input_port: 5600
    property string dev_stream0_udp_rtp_input_ip_address: "127.0.0.1"

    // Sys id QOpenHD uses itself
    property int qopenhd_mavlink_sysid: 255

    //WARNING: THIS ALLOWS THE USER TO MAKE BREAKING CHANGES
    property bool dev_show_whitelisted_params: false
    property bool dev_show_advanced_button: false
    property bool dev_allow_freq_change_when_armed: false
    // WARNING END
    //WARNING: THIS makes the RC panel visible
    property bool app_show_RC: false


    property bool app_background_transparent: true
    // devices that use drm/kms (e.g. rpi) are always fullscreen anyways
    // aka this setting only has an effect when running QOpenHD on a PC, and there also
    // pretty much only during development
    property bool app_explicit_window_fullscreen: false

    property bool enable_software_video_decoder: false
    // enably a test video source instead of decoding actual video data, if supported by the platform
    // 0 = disabled
    // 1 = raw video
    // 2 = raw vide encode and then decode
    property int dev_test_video_mode:0 // 0 is disabled
    // Video codec of the primary video stream (main window).
    property int selectedVideoCodecPrimary:0 //0==h264,1==h265,2==MJPEG, other (error) default to h264
    property int selectedVideoCodecSecondary:0

    property bool dev_jetson: false
    // When this one is set to true, we read a file (where you can then write your custom rx gstreamer pipeline
    // that ends with qmlglsink )
    property bool dev_enable_custom_pipeline: false
    // only for ffmpeg
    property int dev_limit_fps_on_test_file: -1
    property bool dev_draw_alternating_rgb_dummy_frames: false;
    // r.n only works on h264 / h265 and on select video stream(s)
    // does not work on mjpeg, but as far as I can see, mjpeg doesn't suffer from the "one frame buffering" issue in avcodec
    property bool dev_use_low_latency_parser_when_possible: true;
    property bool dev_feed_incomplete_frames_to_decoder:false;

    // dirty, perhaps temporary
    property bool dev_rpi_use_external_omx_decode_service: true;
    property bool dev_always_use_generic_external_decode_service: false

    property bool enable_speech: true
    property bool enable_imperial: false
    property bool enable_rc: false

    property string color_shape: "white"
    property string color_text: "white"
    property string color_glow: "black"
    property string color_warn: "red"
    property string color_caution: "yellow"
    property string font_text: "Sans Serif"

    // animation smoothing value, in ms
    // Note that low fps like on embedded devices also adds some latency - because of that, default to 100ms here
    property int smoothing: 100

    property int log_level: 6

    property bool show_downlink_rssi: true
    //Const10
    property bool downlink_show_dbm_and_packets_per_card: false
    property bool downlink_show_current_bitrate: false
    property bool downlink_cards_right: false
    property bool downlink_rssi_declutter: false
    property double downlink_rssi_warn: 0
    property double downlink_rssi_caution: 0
    // r.n one of the most important statistics about link quality
    property int downlink_packet_loss_perc_caution : 10
    property int downlink_packet_loss_perc_warn : 20

    property bool show_uplink_rssi: true
    property bool uplink_rssi_declutter: false
    property double uplink_rssi_warn: 0
    property double uplink_rssi_caution: 0

    property bool show_rc_rssi: true
    property bool rc_rssi_declutter: false
    property double rc_rssi_warn: 0
    property double rc_rssi_caution: 0

    property bool show_bitrate: true
    property bool bitrate_declutter: false
    property double bitrate_warn: 0
    property double bitrate_caution: 0
    //
    property bool qrenderstats_show: false
    property bool qrenderstats_declutter: false
    property double qrenderstats_warn: 0
    property double qrenderstats_caution: 0


    property bool show_air_battery: true
    property bool air_battery_show_voltage_current: false
    property bool air_battery_show_single_cell: false

    property bool show_ground_battery: false
    property bool ground_battery_show_voltage_current: false
    property bool ground_battery_show_single_cell: false
    property bool ground_battery_show_fc_percent: false
    property int ground_battery_cells: 3

    property bool show_gps: true
    property bool gps_show_all: false
    property bool gps_declutter: false
    property double gps_warn: 3
    property double gps_caution: 2

    property bool show_home_distance: true
    property double home_saved_lat: 0.0
    property double home_saved_lon: 0.0

    property bool show_flight_time: true

    property bool show_flight_mode: true

    property bool show_flight_distance: true

    property bool show_flight_mah: true

    property bool show_flight_mah_km: true

    property bool show_imu_temp: false
    property bool imu_temp_declutter: false
    property double imu_temp_warn: 75
    property double imu_temp_caution: 65

    property bool show_press_temp: true
    property bool press_temp_declutter: false
    property double press_temp_warn: 75
    property double press_temp_caution: 60

    property bool show_airspeed_temp: false
    property bool airspeed_temp_declutter: false
    property double airspeed_temp_warn: 0
    property double airspeed_temp_caution: 10

    property bool show_esc_temp: false
    property bool esc_temp_declutter: false
    property double esc_temp_warn: 75
    property double esc_temp_caution: 60

    property bool show_ground_status: true
    property bool ground_status_declutter: false
    property double ground_status_cpu_caution: 50
    property double ground_status_cpu_warn: 70
    property double ground_status_temp_caution: 60
    property double ground_status_temp_warn: 70

    property bool show_air_status: true
    property bool air_status_declutter: false
    property double air_status_cpu_caution: 50
    property double air_status_cpu_warn: 70
    property double air_status_temp_caution: 60
    property double air_status_temp_warn: 70

    property bool show_message_hud: true

    property bool show_horizon: true
    property bool horizon_invert_pitch: false
    property bool horizon_invert_roll: false
    property double horizon_width: 2
    property int horizon_ladder_spacing: 180
    property int horizon_range: 50
    property int horizon_step: 10
    property bool show_horizon_ladder: true
    property bool show_horizon_heading_ladder: true
    property bool show_horizon_home: true
    property bool horizon_show_center_indicator: true
    property double horizon_clip_area_scale: 1.0

    property bool heading_ladder_text: true //shared between heading and horizon

    property bool show_heading: true
    property bool show_heading_ladder: true

    // experimental
    property bool show_performance_horizon: false
    // experimental end

    // false by default for now, since it has a big performance hit. (only noticeable on embedded devices like rpi -
    // but rpi is one of our main user(s) platforms
    property bool show_flight_path_vector: false
    property bool fpv_dynamic: true    
    property int fpv_sensitivity: 5
    property bool fpv_invert_pitch: false
    property bool fpv_invert_roll: false //currently not used
    property double fpv_vertical_limit: 60
    property double fpv_lateral_limit: 60


    property bool show_speed: true
    property bool speed_use_groundspeed: true
    property bool show_speed_ladder: true
    property int speed_range: 100
    property int speed_minimum: 0

    property bool show_speed_second: true
    property bool speed_second_use_groundspeed: false

    property bool show_altitude: true
    property bool altitude_rel_msl: false
    property bool show_altitude_ladder: true
    property int altitude_range: 100

    property bool show_altitude_second: true
    property bool altitude_second_msl_rel: true

    property bool show_arrow: true
    property bool arrow_invert: false

    property bool show_map: false
    property double map_opacity_minimized: 1
    property double map_opacity_maximized: 1
    property bool map_orientation: false
    property bool map_drone_track: true
    property bool map_show_mission_waypoints: true

    property int map_zoom: 18
    property double map_size: 1
    property bool show_throttle: true

    property bool show_control: false
    property bool double_control: true
    property bool control_rev_pitch: false
    property bool control_rev_roll: false
    property bool control_rev_yaw: false
    property bool control_rev_throttle: false

    property bool show_gpio: false
    property int selected_map_provider: 0
    property int selected_map_variant: 0

    property bool show_vibration: false

    // Disabled by default, since it has a quite big impact on draw call performance on embedded devices
    // like rpi
    property bool show_vsi: false
    property int vsi_max: 20

    property bool show_wind: false
    property bool wind_plane_copter: false //should default to plane
    property bool wind_arrow_circle: true
    //tumbler value had to be split into two values..
    property double wind_tumbler_decimal: 5
    property double wind_tumbler_tens: 13
    property double wind_max_quad_speed: wind_tumbler_tens+(wind_tumbler_decimal*.1)

    property bool show_roll: true
    property bool roll_invert: false
    property bool roll_show_arc: true
    property bool roll_show_numbers: true
    property bool roll_sky_pointer: false

    property bool show_adsb: false
    property int adsb_distance_limit: 15000//meters. Bound box for api from map center (so x2)
    //property int adsb_sdr_distance: 20
    property bool adsb_api_sdr: false
    property bool adsb_api_openskynetwork: false
    property bool adsb_show_unknown_or_zero_alt: false

    property bool show_mission: false

    property bool show_record_widget: true
    property double recordTextSize: 14
    property bool show_minimal_record_widget: true
    property double record_widget_height: 48
    property double record_widget_width: 140

    // The user can controll the width and height the secondary video has when in minimized state
    // (By that he also controlls the ratio).
    // And he can specify a factor by which the secondary video is maximized when clicked
    property int secondary_video_minimized_width : 320
    property int secondary_video_minimized_height : 240
    property int secondary_video_maximize_factor_perc : 200

    property bool show_aoa: false
    property bool aoa_declutter: false
    property double aoa_warn: 10
    property double aoa_caution: 8
    property double aoa_max: 20

    property bool show_example_widget: false

    property int dev_qopenhd_n_cameras:1

    // N of battery cells (generic) of the vehicle, used for the show voltage per cell setting
    // Proper way would be to query / get that via mavlink, but this is more complicated than it seems at glance
    property int vehicle_battery_n_cells: 3

    // Show FC mavlink messages in the HUD
    property bool show_fc_messages_in_hud: true

    // only works on select platforms (on rpi, we are automatically already full screen)
    property bool dev_force_show_full_screen: false

    // experimental
    property bool dev_enable_live_audio_playback: false
    // might / might not work
    property bool dev_set_swap_interval_zero: false

    // Discard actual video ratio and fit primary video to whatever ratio the screen is at (might distort video)
    property bool primary_video_scale_to_fit: false

    // HUD WB link rate control element settings
    property bool wb_link_rate_control_widget_show: true

    // really really dirty, i want to get rid of it as soon as possible
    property bool dirty_enable_inav_hacks: false

    property int custom_cursor_type: 0
    property int custom_cursor_scale: 1 // arbitrary scale values - higher == bigger,

    // experimental - mavlink via TCP
    property bool dev_mavlink_via_tcp: false
    property string dev_mavlink_tcp_ip: "0.0.0.0"
}
