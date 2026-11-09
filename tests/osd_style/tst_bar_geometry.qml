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
        property string color_warn:"red"
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
        property bool gps_hide_identity_using_offset:false
        property bool gps_position_popup_open:false
        property string savedGpsPosition:""
        property real hide_identity_latitude_offset:0
        property real hide_identity_longitude_offset:0
        function value(key,fallback){return key.indexOf("_x_offset")>=0?80:fallback}
        function setValue(key,value){if(key==="gps_callout_last_position")savedGpsPosition=value}
        function sync(){}
    }
    QtObject {
        id:_fcMavlinkSystem
        property bool is_alive:true
        property bool armed:false
        property int gps_fix_type:3
        property real lat:51.25
        property real lon:7.125
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
    QtObject {id:_fcMavlinkAction;property string ardupilot_mav_type:"quad";property int armCalls:0;function has_mapping(mode){return false}function arm_fc_async(arm){if(arm)armCalls++}}
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
        function test_settings_hold_opens_slot_editor_without_fc(){
            settings.show_widgets=true
            settings.show_link_overview_widget=true
            settings.show_link_overview_widget_bottom=true
            _fcMavlinkSystem.is_alive=false
            wait(250)
            compare(findChild(bar,"bottomBarSettingsButton"),null)
            var surface=findChild(bar,"bottomBarSettingsHold")
            mousePress(surface,12,surface.height/2);wait(950);mouseRelease(surface,12,surface.height/2)
            tryCompare(bar.widgetDetail,"visible",true)
            var loader=findChild(bar,"bottomBarSettingsLoader")
            tryCompare(loader,"status",Loader.Ready)
            var gps=findChild(loader,"bottomBarSlot1")
            var altitude=findChild(loader,"bottomBarSlot2")
            verify(gps!==null && altitude!==null)
            gps.currentIndex=bar.slot_index_for_value("gps_speed");gps.activated(gps.currentIndex)
            altitude.currentIndex=bar.slot_index_for_value("altitude");altitude.activated(altitude.currentIndex)
            compare(bar.slot1Selection,"gps_speed");compare(bar.slot2Selection,"altitude")
            verify(bar.widgetDetail.height<=scene.height-24)
            verify(!bar.dragging)
            bar.widgetDetail.close()
            settings.show_widgets=false
            settings.show_link_overview_widget=false
            settings.show_link_overview_widget_bottom=false
            _fcMavlinkSystem.is_alive=true
        }
        function test_satellites_fixed_and_gps_popup(){
            settings.show_widgets=true;settings.show_link_overview_widget=true;settings.show_link_overview_widget_bottom=true
            settings.link_overview_widget_scale=1
            bar.hide_na=true
            _fcMavlinkSystem.is_alive=false
            wait(250)
            var satellites=findChild(bar,"bottomBarSatellites"),touch=findChild(bar,"bottomBarGpsTouch")
            verify(satellites.visible)
            compare(findChild(bar,"bottomBarSatelliteCount").text,"N/A")
            var visual=findChild(bar,"bottomBarVisual"),slots=findChild(bar,"bottomBarRightSlots")
            verify(satellites.x+satellites.width<=visual.width)
            verify(satellites.x>visual.width*0.75)
            verify(slots.x+slots.width<=satellites.x)
            bar.slot7Selection="satellites";bar.normalize_slot_selections();compare(bar.slot7Selection,"none")
            for(var i=0;i<bar.slotOptions.length;i++)verify(bar.slotOptions[i].value!=="satellites")
            _fcMavlinkSystem.is_alive=true;_fcMavlinkSystem.gps_fix_type=3
            mouseClick(touch)
            var popup=findChild(bar,"bottomBarGpsPopup")
            tryCompare(popup,"visible",true)
            verify(popup.width<=300);verify(popup.height<=48)
            var icon=findChild(bar,"bottomBarSatelliteIcon")
            var tip=popup.mapToItem(visual,popup.tipX,popup.height)
            var iconCentre=icon.mapToItem(visual,icon.width/2,0)
            verify(Math.abs(tip.x-iconCentre.x)<1,"Callout pointer must align with the satellite icon")
            var latitude=findChild(popup,"gpsPopupLatitude"),longitude=findChild(popup,"gpsPopupLongitude")
            verify(Qt.colorEqual(latitude.color, findChild(bar,"bottomBarSatelliteCount").color))
            verify(Qt.colorEqual(longitude.color, latitude.color))
            compare(latitude.text,"51.250000\u00b0 N")
            compare(longitude.text,"7.125000\u00b0 E")
            wait(50)
            verify(latitude.contentWidth<=latitude.width,"Full latitude must fit beside a shorter longitude")
            _fcMavlinkSystem.lon=-179.123456;wait(50)
            verify(longitude.contentWidth<=longitude.width+1,"Full longitude must fit the compact callout")
            _fcMavlinkSystem.lon=7.125
            settings.gps_hide_identity_using_offset=true
            settings.hide_identity_latitude_offset=1
            settings.hide_identity_longitude_offset=-2
            compare(latitude.text,"52.250000\u00b0 N")
            compare(longitude.text,"5.125000\u00b0 E")
            _fcMavlinkSystem.lat=-51.25;_fcMavlinkSystem.lon=-7.125
            settings.gps_hide_identity_using_offset=false
            compare(latitude.text,"51.250000\u00b0 S");compare(longitude.text,"7.125000\u00b0 W")
            _fcMavlinkSystem.lat=51.25;_fcMavlinkSystem.lon=7.125
            tryCompare(bar,"lastGpsPosition",Qt.point(51.25,7.125))
            _fcMavlinkSystem.gps_fix_type=0
            _fcMavlinkSystem.lat=0;_fcMavlinkSystem.lon=0
            compare(latitude.text,"Last 51.250000\u00b0 N");compare(longitude.text,"7.125000\u00b0 E")
            verify(Qt.colorEqual(latitude.color,"red"));verify(Qt.colorEqual(longitude.color,"red"))
            tryCompare(settings,"savedGpsPosition","51.25,7.125")
            settings.gps_hide_identity_using_offset=true
            compare(latitude.text,"Last 52.250000\u00b0 N");compare(longitude.text,"5.125000\u00b0 E")
            settings.gps_hide_identity_using_offset=false
            bar.gpsPreviewRequested=true
            compare(latitude.text,"50.110924\u00b0 N");compare(longitude.text,"8.682127\u00b0 E")
            verify(Qt.colorEqual(latitude.color,"red"));verify(Qt.colorEqual(longitude.color,"red"))
            compare(findChild(bar,"bottomBarSatelliteCount").text,"12")
            compare(_fcMavlinkSystem.gps_fix_type,0)
            compare(settings.savedGpsPosition,"51.25,7.125")
            bar.gpsPreviewRequested=false
            popup.close();wait(100)
            compare(settings.gps_position_popup_open,false)
            mouseClick(touch);compare(settings.gps_position_popup_open,true)
            mousePress(touch);wait(950);mouseRelease(touch)
            tryCompare(bar.widgetDetail,"visible",true);compare(settings.gps_position_popup_open,true)
            var loader=findChild(bar,"bottomBarSettingsLoader")
            tryCompare(loader,"status",Loader.Ready)
            var scramble=findChild(loader,"bottomBarGpsScramble")
            verify(scramble!==null)
            scramble.checked=true
            scramble.toggled()
            compare(settings.gps_hide_identity_using_offset,true)
            compare(latitude.text,"Last 52.250000\u00b0 N")
            bar.widgetDetail.close()
            mouseClick(touch);compare(settings.gps_position_popup_open,false)
            _fcMavlinkSystem.gps_fix_type=3
            _fcMavlinkSystem.lat=51.25;_fcMavlinkSystem.lon=7.125
            settings.gps_hide_identity_using_offset=false
            settings.show_widgets=false;settings.show_link_overview_widget=false;settings.show_link_overview_widget_bottom=false
        }
        function test_hold_regions_preserve_centre_arming(){
            settings.show_widgets=true
            settings.show_link_overview_widget=true
            settings.show_link_overview_widget_bottom=true
            _fcMavlinkSystem.is_alive=true;_fcMavlinkSystem.armed=false
            _fcMavlinkAction.armCalls=0
            var surface=findChild(bar,"bottomBarSettingsHold")
            for(var i=0;i<3;i++){
                settings.link_overview_widget_scale=[0.6,1,1.5][i];wait(250)
                // Press through the full surface: the centre's own area must receive it.
                mousePress(surface,surface.width/2,12);wait(950);mouseRelease(surface,surface.width/2,12)
                compare(_fcMavlinkAction.armCalls,i+1)
                compare(bar.widgetDetail.visible,false)
                var x=i%2===0 ? 12 : surface.width-12
                mousePress(surface,x,surface.height/2);wait(950);mouseRelease(surface,x,surface.height/2)
                tryCompare(bar.widgetDetail,"visible",true)
                compare(_fcMavlinkAction.armCalls,i+1)
                verify(!bar.dragging)
                bar.widgetDetail.close();wait(100)
            }
            settings.show_widgets=false
            settings.show_link_overview_widget=false
            settings.show_link_overview_widget_bottom=false
        }
    }
}
