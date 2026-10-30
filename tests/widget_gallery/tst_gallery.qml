import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
import "../../qml/ui/configpopup/qopenhd_settings/WidgetCatalog.js" as Catalog
Item {
    id:scene;width:1600;height:900
    FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
    FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
    QtObject {id:settings_form;property bool darkMode:true;property bool showDeveloperSettings:false;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property int closes:0;function close_all(){closes++}}
    QtObject {id:hudOverlayGrid;property bool widgetGalleryPreviewActive:false;readonly property var widgetPreviewTargets: ({show_horizon:actualSource})}
    Rectangle {id:actualSource;visible:false;width:120;height:60;color:"#fa2222";Text {anchors.centerIn:parent;text:"REAL SOURCE";color:"white"}}
    QtObject {id:settings;
        property bool show_widgets: false
        property bool show_link_overview_widget: false
        property bool show_link_overview_widget_bottom: false
        property bool show_video_pipeline_debug_widget: false
        property bool show_artosyn_debug_widget: false
        property bool show_flight_mode: false
        property bool show_imu_temp: false
        property bool show_press_temp: false
        property bool show_press_temp2: false
        property bool show_press_temp3: false
        property bool show_airspeed_temp: false
        property bool show_esc_temp: false
        property bool show_battery_temp: false
        property bool show_horizon: false
        property bool show_performance_horizon: false
        property bool show_flight_path_vector: false
        property bool altitude_ladder_show: false
        property bool speed_ladder_show: false
        property bool show_heading: false
        property bool bank_angle_indicator_widget_show: false
        property bool show_arrow: false
        property bool show_control: false
        property bool show_vibration: false
        property bool show_vertical_speed_gauge_widget: false
        property bool show_aoa: false
        property bool show_distance_sensor_widget: false
        property bool show_time_widget: false
        property bool show_map: false
        property bool adsb_enable: false
        property bool show_message_hud: false
        property bool show_sidebar: false
        property bool qrenderstats_show: false
        property bool show_ip_camera_control_widget: false
        property bool show_gpio: false
        property bool show_txc_temp_air: false
        property bool show_txc_temp_gnd: false
        property bool show_retransmission_stats: false
        property bool show_downlink_rssi: false
        property bool show_uplink_rssi: false
        property bool wb_link_rate_control_widget_show: false
        property bool show_bitrate: false
        property bool show_rc_rssi: false
        property bool show_ground_status: false
        property bool show_air_status: false
        property bool show_air_battery: false
        property bool show_ground_battery: false
        property bool show_flight_mah: false
        property bool show_flight_mah_km: false
        property bool show_flight_distance: false
        property bool show_wind: false
        property bool show_gps: false
        property bool show_home_distance: false
        property bool show_flight_time: false
        property bool show_speed_second: false
        property bool show_throttle: false
        property bool show_mission: false
        property bool show_vertical_speed_simple_widget: false
        property bool show_altitude_second: false
    }
    Rectangle {anchors.fill:parent;color:settings_form.pageBackground}
    Pages.AppWidgetSettingsView {id:gallery;anchors.fill:parent}
    TestCase {
        name:"WidgetGallery";when:windowShown
        function visual(item,name){if(item.objectName===name)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var found=visual(children[i],name);if(found)return found}return null}
        function init(){
            scene.Window.window.width=1600;scene.Window.window.height=900;scene.width=1600;scene.height=900
            gallery.category="flight"
            settings_form.showDeveloperSettings=false
            Catalog.widgets.forEach(function(w){settings[w.key]=false});gallery.revision++
        }
        function test_inventory_and_developer_gate(){
            compare(Catalog.widgets.length,57)
            compare(gallery.category,"flight")
            compare(gallery.sections.length,1)
            compare(visual(gallery,"widgetCategory_all"),null)
            compare(gallery.categories.length,7)
            var keys={};Catalog.widgets.forEach(function(w){verify(!keys[w.key],"Duplicate "+w.key);keys[w.key]=true;compare(typeof settings[w.key],"boolean")})
            compare(gallery.availableWidgets.length,54)
            compare(gallery.matches("developer").length,0)
            settings_form.showDeveloperSettings=true
            compare(gallery.availableWidgets.length,57)
            compare(gallery.matches("developer").length,3)
        }
        function test_category_and_write(){
            gallery.category="navigation"
            compare(gallery.sections.length,1)
            compare(gallery.matches("navigation").length,8)
            wait(80)
            var toggle=visual(gallery,"widgetToggle_show_gps")
            verify(toggle!==null);compare(toggle.checked,false)
            mouseClick(toggle)
            compare(settings.show_gps,true)
            compare(settings.show_map,false)
            compare(visual(gallery,"widgetSearch"),null)
            compare(visual(gallery,"widgetFilter_0"),null)
        }
        function test_master_and_presets(){
            var master=visual(gallery,"widgetMasterSwitch")
            mouseClick(master);compare(settings.show_widgets,true)
            gallery.applyPreset(1)
            compare(settings.show_horizon,true);compare(settings.show_map,false);compare(settings.qrenderstats_show,false)
            gallery.applyPreset(2);compare(settings.show_map,true)
            gallery.applyPreset(3);compare(settings.show_gpio,true);compare(settings.show_video_pipeline_debug_widget,false)
            gallery.changeWidget(Catalog.widgets[0],false);compare(gallery.presetIndex,0)
        }
        function test_actual_source_is_not_mutated(){
            gallery.category="flight"
            wait(80)
            var card=visual(gallery,"widgetCard_show_horizon")
            var texture=visual(card,"actualWidgetTexture")
            verify(texture!==null)
            compare(texture.sourceItem,actualSource)
            compare(actualSource.visible,false)
            compare(settings.show_horizon,false)
            compare(texture.live,false)
            compare(texture.hideSource,false)
            compare(texture.sourceRect.width,120)
        }
        function test_responsive_and_capture(){
            gallery.applyPreset(2)
            wait(150)
            grabImage(scene).save("build/widget-gallery-wide.png")
            scene.Window.window.width=800;scene.Window.window.height=600;scene.width=800;scene.height=600
            wait(150);compare(gallery.wide,false)
            var rail=visual(gallery,"widgetCategoryRail")
            compare(rail.visible,true);compare(rail.width,60)
            compare(visual(gallery,"widgetCategoryLabel_navigation").visible,false)
            mouseClick(visual(gallery,"widgetCategory_navigation"));compare(gallery.category,"navigation")
            compare(gallery.sections.length,1)
            mouseClick(visual(gallery,"widgetCategory_flight"));wait(150)
            var scroll=visual(gallery,"widgetGalleryScroll");verify(scroll.width<=800);verify(scroll.height>250)
            grabImage(scene).save("build/widget-gallery-compact.png")
            scene.Window.window.width=420;scene.Window.window.height=620;scene.width=420;scene.height=620
            wait(150);verify(scroll.width<=420);verify(scroll.height>200)
            grabImage(scene).save("build/widget-gallery-narrow.png")
        }
    }
}
