.pragma library

// One entry per existing widget visibility preference.
var categories = [
  {
    "id": "flight",
    "title": "Flight instruments",
    "icon": "\uf072",
    "color": "#59bfff"
  },
  {
    "id": "navigation",
    "title": "Navigation",
    "icon": "\uf124",
    "color": "#41df95"
  },
  {
    "id": "power",
    "title": "Power & battery",
    "icon": "\uf240",
    "color": "#45df81"
  },
  {
    "id": "link",
    "title": "Link & video",
    "icon": "\uf1eb",
    "color": "#40b5ff"
  },
  {
    "id": "sensors",
    "title": "Sensors",
    "icon": "\uf2c9",
    "color": "#ff6683"
  },
  {
    "id": "controls",
    "title": "Controls",
    "icon": "\uf11b",
    "color": "#c282f1"
  },
  {
    "id": "utilities",
    "title": "Utilities",
    "icon": "\uf0ad",
    "color": "#96bfff"
  },
  {
    "id": "developer",
    "title": "Developer",
    "icon": "\uf121",
    "color": "#cf83eb"
  }
]

var widgets = [
  {
    "key": "show_link_overview_widget",
    "title": "Link Overview",
    "description": "RSSI, temperature and link status",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_link_overview_widget_bottom",
    "title": "Bottom Link Bar",
    "description": "Bottom link sidebar",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_video_pipeline_debug_widget",
    "title": "Video Debug Widget",
    "description": "Video Debug Widget",
    "category": "developer",
    "developer": true
  },
  {
    "key": "show_artosyn_debug_widget",
    "title": "Artosyn Debug Widget",
    "description": "Artosyn Debug Widget",
    "category": "developer",
    "developer": true
  },
  {
    "key": "show_flight_mode",
    "title": "Flight Mode",
    "description": "Current flight mode",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_imu_temp",
    "title": "IMU temperature",
    "description": "IMU temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_press_temp",
    "title": "Pressure temperature",
    "description": "Pressure temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_press_temp2",
    "title": "Pressure temperature 2",
    "description": "Pressure temperature 2",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_press_temp3",
    "title": "Pressure temperature 3",
    "description": "Pressure temperature 3",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_airspeed_temp",
    "title": "Airspeed temperature",
    "description": "Airspeed temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_esc_temp",
    "title": "ESC temperature",
    "description": "ESC temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_battery_temp",
    "title": "Battery Temperature",
    "description": "Battery Temperature",
    "category": "power",
    "developer": false
  },
  {
    "key": "show_horizon",
    "title": "Horizon",
    "description": "Artificial horizon",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_performance_horizon",
    "title": "Perf. horizon",
    "description": "Performance attitude display",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_flight_path_vector",
    "title": "Flight Path Vector",
    "description": "Direction of travel",
    "category": "flight",
    "developer": false
  },
  {
    "key": "altitude_ladder_show",
    "title": "Altitude",
    "description": "Altitude ladder",
    "category": "flight",
    "developer": false
  },
  {
    "key": "speed_ladder_show",
    "title": "Speed",
    "description": "Speed ladder",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_heading",
    "title": "Heading",
    "description": "Heading indicator",
    "category": "flight",
    "developer": false
  },
  {
    "key": "bank_angle_indicator_widget_show",
    "title": "Bank Angle Indicator",
    "description": "Bank indicator",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_arrow",
    "title": "Home Arrow",
    "description": "Direction to home",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_control",
    "title": "Control Inputs",
    "description": "Flight controller inputs",
    "category": "controls",
    "developer": false
  },
  {
    "key": "show_vibration",
    "title": "Vibration",
    "description": "Vibration",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_vertical_speed_gauge_widget",
    "title": "Vertical Speed Gauge",
    "description": "Vertical Speed Gauge",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_aoa",
    "title": "Angle of Attack",
    "description": "Angle of Attack",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_distance_sensor_widget",
    "title": "distance sensor",
    "description": "distance sensor",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_time_widget",
    "title": "GPS time",
    "description": "Time received from GPS",
    "category": "utilities",
    "developer": false
  },
  {
    "key": "show_map",
    "title": "Map",
    "description": "Map overlay",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "adsb_enable",
    "title": "ADSB",
    "description": "Nearby aircraft",
    "category": "utilities",
    "developer": false
  },
  {
    "key": "show_message_hud",
    "title": "Log messages",
    "description": "Flight and system messages",
    "category": "utilities",
    "developer": false
  },
  {
    "key": "show_sidebar",
    "title": "Sidebar",
    "description": "On-screen sidebar",
    "category": "utilities",
    "developer": false
  },
  {
    "key": "qrenderstats_show",
    "title": "Qt render statistics",
    "description": "Qt render statistics",
    "category": "developer",
    "developer": true
  },
  {
    "key": "show_ip_camera_control_widget",
    "title": "IP Camera Control",
    "description": "Camera movement controls",
    "category": "controls",
    "developer": false
  },
  {
    "key": "show_gpio",
    "title": "GPIO",
    "description": "GPIO controls",
    "category": "controls",
    "developer": false
  },
  {
    "key": "show_txc_temp_air",
    "title": "TX Temperature",
    "description": "TX Temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_txc_temp_gnd",
    "title": "RX Temperature",
    "description": "RX Temperature",
    "category": "sensors",
    "developer": false
  },
  {
    "key": "show_retransmission_stats",
    "title": "Retransmission Stats",
    "description": "Retransmission counters",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_downlink_rssi",
    "title": "Downlink RSSI",
    "description": "Downlink RSSI",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_uplink_rssi",
    "title": "Uplink RSSI",
    "description": "Uplink RSSI",
    "category": "link",
    "developer": false
  },
  {
    "key": "wb_link_rate_control_widget_show",
    "title": "Live rate control",
    "description": "Link rate controls",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_bitrate",
    "title": "Video bitrate",
    "description": "Video bitrate and recording",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_rc_rssi",
    "title": "RC signal",
    "description": "External RC receiver signal",
    "category": "controls",
    "developer": false
  },
  {
    "key": "show_ground_status",
    "title": "Ground Status",
    "description": "Ground unit health",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_air_status",
    "title": "Air Status",
    "description": "Air unit health",
    "category": "link",
    "developer": false
  },
  {
    "key": "show_air_battery",
    "title": "Air Battery",
    "description": "Air Battery",
    "category": "power",
    "developer": false
  },
  {
    "key": "show_ground_battery",
    "title": "Ground Battery",
    "description": "Ground Battery",
    "category": "power",
    "developer": false
  },
  {
    "key": "show_flight_mah",
    "title": "Consumed charge",
    "description": "Battery charge consumed",
    "category": "power",
    "developer": false
  },
  {
    "key": "show_flight_mah_km",
    "title": "Efficiency",
    "description": "Charge used per kilometre",
    "category": "power",
    "developer": false
  },
  {
    "key": "show_flight_distance",
    "title": "Total Flight Distance",
    "description": "Total Flight Distance",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_wind",
    "title": "Wind",
    "description": "Wind",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_gps",
    "title": "GPS",
    "description": "GPS fix and satellites",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_home_distance",
    "title": "Home Distance",
    "description": "Distance from home",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_flight_time",
    "title": "Flight Timer",
    "description": "Flight Timer",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_speed_second",
    "title": "Second Speed",
    "description": "Second Speed",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_throttle",
    "title": "Throttle",
    "description": "Throttle",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_mission",
    "title": "Missions",
    "description": "Missions",
    "category": "navigation",
    "developer": false
  },
  {
    "key": "show_vertical_speed_simple_widget",
    "title": "Vertical Speed (minimal)",
    "description": "Vertical Speed (minimal)",
    "category": "flight",
    "developer": false
  },
  {
    "key": "show_altitude_second",
    "title": "Second Altitude",
    "description": "Second Altitude",
    "category": "flight",
    "developer": false
  }
]

// Keep the common flight instruments and navigation tools first.
var preferredOrder = ["show_horizon", "show_performance_horizon", "show_flight_mode", "altitude_ladder_show", "speed_ladder_show", "show_heading", "bank_angle_indicator_widget_show", "show_flight_path_vector", "show_vertical_speed_gauge_widget", "show_aoa", "show_throttle", "show_gps", "show_arrow", "show_home_distance", "show_map", "show_flight_distance", "show_flight_time", "show_wind", "show_mission"]
widgets.sort(function(a,b) {
    var ai=preferredOrder.indexOf(a.key),bi=preferredOrder.indexOf(b.key)
    return (ai<0?100:ai)-(bi<0?100:bi)
})
