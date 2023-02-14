import QtQuick 2.12
import Qt.labs.settings 1.0



Settings {
    id: settings

    property double global_scale: 1.0
    property int font_dpi: 96

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

    property bool hide_watermark: true
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

    property string bar_behavior: "red"

    property double ground_power_opacity: 1

    property int log_level: 6

    property bool show_downlink_rssi: true
    property double downlink_rssi_opacity: 1
    //property bool downlink_rssi_show_lost_damaged: false
    //Const10
    property bool downlink_show_dbm_and_packets_per_card: false
    property bool downlink_show_current_bitrate: false
    property bool downlink_cards_right: false
    property double downlink_rssi_size: 1
    property bool downlink_rssi_declutter: false
    property double downlink_rssi_warn: 0
    property double downlink_rssi_caution: 0

    property bool show_uplink_rssi: true
    property double uplink_rssi_opacity: 1
    property double uplink_rssi_size: 1
    property bool uplink_rssi_declutter: false
    property double uplink_rssi_warn: 0
    property double uplink_rssi_caution: 0

    property bool show_rc_rssi: true
    property double rc_rssi_opacity: 1
    property double rc_rssi_size: 1
    property bool rc_rssi_declutter: false
    property double rc_rssi_warn: 0
    property double rc_rssi_caution: 0

    property bool show_bitrate: true
    property double bitrate_opacity: 1
    property double bitrate_size: 1
    property bool bitrate_declutter: false
    property double bitrate_warn: 0
    property double bitrate_caution: 0
    //
    property bool qrenderstats_show: true
    property double qrenderstats_opacity: 1
    property double qrenderstats_size: 1
    property bool qrenderstats_declutter: false
    property double qrenderstats_warn: 0
    property double qrenderstats_caution: 0


    property bool show_air_battery: true
    property double air_battery_opacity: 1
    property bool air_battery_show_voltage_current: false
    property bool air_battery_show_single_cell: false
    property double air_battery_size: 1

    property bool show_ground_battery: false
    property double ground_battery_opacity: 1
    property bool ground_battery_show_voltage_current: false
    property bool ground_battery_show_single_cell: false
    property bool ground_battery_show_fc_percent: false
    property double ground_battery_size: 1
    property int ground_battery_cells: 3

    property bool show_gps: true
    property double gps_opacity: 1
    property bool gps_show_all: false
    property double gps_size: 1
    property bool gps_declutter: false
    property double gps_warn: 3
    property double gps_caution: 2

    property bool show_home_distance: true
    property double home_distance_opacity: 1
    property double home_distance_size: 1
    property double home_saved_lat: 0.0
    property double home_saved_lon: 0.0

    property bool show_flight_timer: true
    property double flight_timer_opacity: 1
    property double flight_timer_size: 1

    property bool show_flight_mode: true
    property double flight_mode_opacity: 1
    property double flight_mode_size: 1

    property bool show_flight_distance: true
    property double flight_distance_opacity: 1
    property double flight_distance_size: 1

    property bool show_flight_mah: true
    property double mah_opacity: 1
    property double mah_size: 1

    property bool show_flight_mah_km: false
    property double mah_km_opacity: 1
    property double mah_km_size: 1

    property bool show_imu_temp: false
    property double imu_temp_opacity: 1
    property double imu_temp_size: 1
    property bool imu_temp_declutter: false
    property double imu_temp_warn: 75
    property double imu_temp_caution: 65

    property bool show_press_temp: true
    property double press_temp_opacity: 1
    property double press_temp_size: 1
    property bool press_temp_declutter: false
    property double press_temp_warn: 75
    property double press_temp_caution: 60

    property bool show_airspeed_temp: false
    property double airspeed_temp_opacity: 1
    property double airspeed_temp_size: 1
    property bool airspeed_temp_declutter: false
    property double airspeed_temp_warn: 0
    property double airspeed_temp_caution: 10

    property bool show_esc_temp: false
    property double esc_temp_opacity: 1
    property double esc_temp_size: 1
    property bool esc_temp_declutter: false
    property double esc_temp_warn: 75
    property double esc_temp_caution: 60

    property bool show_ground_status: true
    property double ground_status_opacity: 1
    property double ground_status_size: 1
    property bool ground_status_declutter: false
    property double ground_status_cpu_warn: 50
    property double ground_status_cpu_caution: 40
    property double ground_status_temp_warn: 60
    property double ground_status_temp_caution: 50

    property bool show_air_status: true
    property double air_status_opacity: 1
    property double air_status_size: 1
    property bool air_status_declutter: false
    property double air_status_cpu_warn: 70
    property double air_status_cpu_caution: 80
    property double air_status_temp_warn: 70
    property double air_status_temp_caution: 60

    property bool show_message_hud: true
    property double message_hud_opacity: 1
    property double message_hud_size: 1

    property bool show_horizon: true
    property bool horizon_invert_pitch: false
    property bool horizon_invert_roll: false
    property double horizon_size: 1
    property double horizon_width: 2
    property double horizon_opacity: 1
    property int horizon_ladder_spacing: 180
    property int horizon_range: 50
    property int horizon_step: 10
    property bool show_horizon_ladder: true
    property bool show_horizon_heading_ladder: true
    property bool show_horizon_home: true

    property bool heading_ladder_text: true //shared between heading and horizon

    property bool show_heading: true
    property double heading_opacity: 1
    property double heading_size: 1
    property double heading_width: 250
    property bool show_heading_ladder: true

    // false by default for now, since it has a big performance hit. (only noticeable on embedded devices like rpi -
    // but rpi is one of our main user(s) platforms
    property bool show_flight_path_vector: false
    property bool fpv_dynamic: true    
    property int fpv_sensitivity: 5
    property double fpv_opacity: 1
    property double fpv_size: 1.5
    property bool fpv_invert_pitch: false
    property bool fpv_invert_roll: false //currently not used
    property double fpv_vertical_limit: 60
    property double fpv_lateral_limit: 60


    property bool show_speed: true
    property bool speed_use_groundspeed: true
    property double speed_opacity: 1
    property double speed_size: 1
    property bool show_speed_ladder: true
    property int speed_range: 100
    property int speed_minimum: 0

    property bool show_speed_second: true
    property bool speed_second_use_groundspeed: false
    property double speed_second_opacity: 1
    property double speed_second_size: 1

    property bool show_altitude: true
    property bool altitude_rel_msl: false
    property double altitude_opacity: 1
    property double altitude_size: 1
    property bool show_altitude_ladder: true
    property int altitude_range: 100

    property bool show_altitude_second: true
    property bool altitude_second_msl_rel: true
    property double altitude_second_opacity: 1
    property double altitude_second_size: 1

    property bool show_arrow: true
    property bool arrow_invert: false
    property double arrow_opacity: 1
    property double arrow_size: 1

    property bool show_map: false
    property double map_opacity: 1
    property bool map_orientation: false
    property bool map_shape_circle: false
    property bool map_drone_track: true

    property int map_zoom: 18
    property double map_size: 1
    property bool show_throttle: true
    property double throttle_opacity: 1
    property double throttle_scale: 1

    property bool show_control: false
    property double control_opacity: 1
    property double control_size: 1

    property bool double_control: true
    property bool control_rev_pitch: false
    property bool control_rev_roll: false
    property bool control_rev_yaw: false
    property bool control_rev_throttle: false

    property bool show_gpio: false
    property int selected_map_provider: 0
    property int selected_map_variant: 0

    property bool show_vibration: false
    property double vibration_opacity: 1
    property double vibration_size: 1

    // Disabled by default, since it has a quite big impact on draw call performance on embedded devices
    // like rpi
    property bool show_vsi: false
    property double vsi_opacity: 1
    property int vsi_max: 20
    property double vsi_size: 1

    property bool show_wind: false
    property double wind_opacity: 1
    property bool wind_plane_copter: false //should default to plane
    property bool wind_arrow_circle: true
    //tumbler value had to be split into two values..
    property double wind_tumbler_decimal: 5
    property double wind_tumbler_tens: 13
    property double wind_max_quad_speed: wind_tumbler_tens+(wind_tumbler_decimal*.1)
    property double wind_size: 1

    property bool show_roll: true
    property bool roll_invert: false
    property bool roll_show_arc: true
    property bool roll_show_numbers: true
    property bool roll_sky_pointer: false
    property double roll_opacity: 1
    property double roll_size: 1

    property bool show_adsb: false
    property int adsb_distance_limit: 15000//meters. Bound box for api from map center (so x2)
    //property int adsb_sdr_distance: 20
    property bool adsb_api_sdr: false
    property bool adsb_api_openskynetwork: false
    property double adsb_opacity: 1
    property double adsb_size: 1
    property bool adsb_show_unknown_or_zero_alt: false

    property double vroverlay_opacity: 1
    property double vroverlay_size: 1
    property bool vroverlay_invert_pitch: false
    property bool vroverlay_invert_roll: false //currently not used
    property double vroverlay_vertical_fov: 90
    property double vroverlay_horizontal_fov: 120

    property bool show_blackbox: false
    property double blackbox_opacity: 1
    property double blackbox_size: 1

    property bool show_mission: true
    property double mission_opacity: 1
    property double mission_size: 1

    property bool show_record_widget: true
    property double recordTextSize: 14
    property bool show_minimal_record_widget: false
    property double record_widget_height: 48
    property double record_widget_width: 140


    property bool show_aoa: false
    property double aoa_opacity: 1
    property double aoa_size: 1
    property bool aoa_declutter: false
    property double aoa_warn: 10
    property double aoa_caution: 8
    property double aoa_max: 20

    property bool show_example_widget: false

    property int dev_qopenhd_n_cameras:1

    // N of battery cells (generic) of the vehicle, used for the show voltage per cell setting
    // Proper way would be to query / get that via mavlink, but this is more complicated than it seems at glance
    property int vehicle_battery_n_cells: 3
}
