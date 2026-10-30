import QtQuick 2.12
import QtTest 1.2
import "../../qml/ui/widgets" as HUD
Item {
    id:scene;width:640;height:400
    property bool globalDragLock:false
    QtObject {
        id:settings;property bool enable_hybrid:false;property int smoothing:33
        property bool show_widgets:false
        property bool show_link_overview_widget:false
        property bool show_link_overview_widget_bottom:false
        property string color_text:"white"
        property string color_shape:"white"
        property string color_glow:"black"
        property string font_text:"Sans Serif"
        property string link_overview_widget_bg_color:"#000000"
        property real link_overview_widget_scale:1
        property real link_overview_widget_opacity:1
        property string osd_bottom_bar_font:""
        property string osd_bottom_bar_background_color:""
        property string osd_bottom_bar_text_color:""
        property bool enable_imperial:false
        property bool speed_ladder_show_unit:true
        property bool speed_ladder_use_kmh:false
        property bool wind_plane_copter:false
        property string wind_unit:"m/s"
        function value(key,fallback){return key.indexOf("_x_offset")>=0?80:fallback}
        function setValue(key,value){}
        function sync(){}
    }
    QtObject {
        id:_fcMavlinkSystem
        property bool is_alive:true
        property bool armed:false
        property string flight_mode:"MANUAL"
        property string flight_time:"00:01"
        property real air_speed_meter_per_second:10
        property real altitude_rel_m:20
        property real battery_consumed_mah:100
        property real battery_current_ampere:1
        property real battery_percent:80
        property real battery_voltage_volt:15
        property real ground_speed_meter_per_second:9
        property real home_distance:100
        property real mav_wind_direction:0
        property real mav_wind_speed:0
        property real satellites_visible:12
        property real wind_direction:0
        property real wind_speed:0
    }
    QtObject {id:_ohdSystemGround;property real current_rx_signal_quality:90;property real ina219_current_milliamps:1;property real ina219_voltage_millivolt:12000}
    QtObject {id:_fcMavlinkAction;property string ardupilot_mav_type:"quad";function has_mapping(mode){return false}}
    QtObject {id:_qopenhd;function show_toast(text){}}
    QtObject {id:hudOverlayGrid;property bool m_show_horizontal_center_indicator:false;property bool m_show_vertical_center_indicator:false}
    HUD.LinkOverviewWidgetBottom {id:bar}
    TestCase {
        name:"BottomBarStyle";when:windowShown
        function test_full_width_at_all_scales(){
            wait(250) // The production BaseWidget animates its initial width.
            var visual=findChild(bar,"bottomBarVisual")
            for(var i=0;i<3;i++){
                settings.link_overview_widget_scale=[0.6,1,1.5][i]
                wait(30)
                var left=visual.mapToItem(scene,0,0),right=visual.mapToItem(scene,visual.width,0)
                verify(Math.abs(left.x)<0.1,"Left edge must touch the screen: "+left.x)
                verify(Math.abs(right.x-scene.width)<0.1,"Right edge must touch the screen: "+right.x)
            }
        }
        function test_font_and_colours_change_real_widget(){
            settings.osd_bottom_bar_font="Archivo"
            settings.osd_bottom_bar_background_color="#223344"
            settings.osd_bottom_bar_text_color="#fedcba"
            compare(bar.linkFont,"Archivo");compare(bar.linkMonoFont,"Archivo")
            verify(Qt.colorEqual(findChild(bar,"bottomBarBackground").fillColor,"#223344"))
            var text=findChild(bar,"bottomBarFlightModeText")
            compare(text.font.family,"Archivo");verify(Qt.colorEqual(text.color,"#fedcba"))
        }
    }
}
