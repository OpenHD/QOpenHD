import QtQuick 2.12
import Qt.labs.settings 1.0


Settings {
    id: settings

    property double global_scale: 1.0

    property string locale: "en"

    property int main_video_port: 5600
    property int pip_video_port: 5601
    property int lte_video_port: 8000
    property int battery_cells: 3

    property int mavlink_sysid: default_mavlink_sysid()

    property bool show_pip_video: false
    property double pip_video_opacity: 1

    property bool enable_software_video_decoder: false
    property bool enable_rtp: true
    property bool enable_lte_video: false
    property bool hide_watermark: false

    property bool enable_speech: true
    property bool enable_imperial: false
    property bool enable_rc: false

    property string color_shape: "white"
    property string color_text: "white"
    property string color_glow: "black"
    property string font_text: "Sans Serif"

    property string bar_behavior: "red"

    property double ground_power_opacity: 1

    property int log_level: 3

    property bool show_downlink_rssi: true
    property double downlink_rssi_opacity: 1
    property bool downlink_rssi_show_lost_damaged: false
    property bool downlink_cards_right: false
    property double downlink_rssi_size: 1

    property bool show_uplink_rssi: true
    property double uplink_rssi_opacity: 1
    property double uplink_rssi_size: 1

    property bool show_rc_rssi: false
    property double rc_rssi_opacity: 1
    property double rc_rssi_size: 1

    property bool show_bitrate: true
    property double bitrate_opacity: 1
    property bool bitrate_show_skip_fail_count: false
    property double bitrate_size: 1

    property bool show_air_battery: true
    property double air_battery_opacity: 1
    property bool air_battery_show_voltage_current: false
    property bool air_battery_show_single_cell: false
    property double air_battery_size: 1

    property bool show_gps: true
    property double gps_opacity: 1
    property bool gps_show_all: false
    property double gps_size: 1

    property bool show_home_distance: true
    property double home_distance_opacity: 1
    property double home_distance_size: 1

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
    property bool flight_mah_use_telemetry: true
    property double mah_opacity: 1
    property double mah_size: 1

    property bool show_fc_temp: true
    property double fc_temp_opacity: 1
    property double fc_temp_size: 1

    property bool show_ground_status: true
    property double ground_status_opacity: 1
    property double ground_status_size: 1

    property bool show_air_status: true
    property double air_status_opacity: 1
    property double air_status_size: 1

    property bool show_message_hud: true
    property double message_hud_opacity: 1
    property double message_hud_size: 1

    property bool show_horizon: true
    property bool horizon_invert_pitch: false
    property bool horizon_invert_roll: false
    property int horizon_size: 1
    property double horizon_opacity: 1
    property int horizon_ladder_spacing: 10
    property bool show_horizon_ladder: true
    property bool show_horizon_heading_ladder: true
    property bool show_horizon_home: true

    property bool heading_inav: false //shared between heading and horizon
    property bool heading_ladder_text: true //shared between heading and horizon

    property bool show_heading: true
    property double heading_opacity: 1
    property double heading_size: 1
    property double heading_width: 250
    property bool show_heading_ladder: true

    property bool show_fpv: true
    property bool fpv_dynamic: true
    property int fpv_sensitivity: 5
    property double fpv_opacity: 1
    property double fpv_size: 1

    property bool show_speed: true
    property bool speed_use_groundspeed: true
    property double speed_opacity: 1
    property double speed_size: 1
    property bool show_speed_ladder: true
    property int speed_range: 100
    property int speed_minimum: 0

    property bool show_speed_second: true
    property bool speed_second_use_groundspeed: true
    property double speed_second_opacity: 1
    property double speed_second_size: 1

    property bool show_altitude: true
    property bool altitude_rel_msl: false
    property double altitude_opacity: 1
    property double altitude_size: 1
    property bool show_altitude_ladder: true
    property int altitude_range: 100

    property bool show_altitude_second: true
    property bool altitude_second_msl_rel: false
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
    property bool map_drone_track: false

    property int map_zoom: 18

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

    property bool show_vsi: true
    property double vsi_opacity: 1
    property int vsi_max: 20
    property double vsi_size: 1

    property bool show_wind: false
    property double wind_opacity: 1
    property bool wind_plane_copter: true
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
    //property int adsb_marker_limit: 19
    property double adsb_opacity: 1
    property double adsb_size: 1

    property bool show_blackbox: false
    property double blackbox_opacity: 1
    property double blackbox_size: 1

    property bool show_example_widget: false

    property bool stereo_enable: false

    property int stereo_mode: 0
}
