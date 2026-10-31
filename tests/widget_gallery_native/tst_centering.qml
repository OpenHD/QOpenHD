import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/widgets" as HUD
import "../../qml/ui/elements" as Elements
import "../../qml/ui/configpopup/qopenhd_settings" as Gallery
Item {
 id:scene;width:900;height:420
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 property bool globalDragLock:false
 property int detailPanelFontPixels:13
 Elements.AppSettings {id:settings;show_widgets:false;show_horizon:false;show_flight_path_vector:false;smoothing:0;font_text:"Arial";color_shape:"white";color_text:"white";color_glow:"black"}
 QtObject {id:_fcMavlinkSystem;property string flight_mode:"MANUAL";property bool armed:false;property bool is_alive:true;property real roll:0;property real pitch:0;property real hdg:10;property real home_heading:25;property real altitude_rel_m:250;property real altitude_msl_m:300;property real air_speed_meter_per_second:12;property real ground_speed_meter_per_second:10;property real vehicle_vx_angle:0;property real vehicle_vz_angle:0;property real vertical_speed_indicator_mps:1;property real aoa:5}
 QtObject {id:_fcMavlinkAction;property string ardupilot_mav_type:"quad";function has_mapping(mode){return false}}
 QtObject {id:sidebar;property bool m_is_active:false}
 QtObject {id:hudOverlayGrid;property bool widgetGalleryPreviewActive:true;property bool m_show_horizontal_center_indicator:false;property bool m_show_vertical_center_indicator:false;readonly property var widgetPreviewTargets:({horizon:horizon,performance:performance,flight:flight,altitude:altitude,speed:speed,heading:heading,bank:bank,fpv:fpv,vertical:vertical,aoa:aoa})}
 Item {width:900;height:420;visible:false
  HUD.HorizonWidget {id:horizon}
  HUD.PerformanceHorizonWidget2 {id:performance}
  HUD.FlightModeWidget {id:flight}
  HUD.AltitudeWidget {id:altitude}
  HUD.SpeedWidget {id:speed}
  HUD.HeadingWidget {id:heading}
  HUD.RollWidget {id:bank}
  HUD.FpvWidget {id:fpv}
  HUD.VerticalSpeedGaugeWidget {id:vertical}
  HUD.AoaWidget {id:aoa}
 }
 Grid {columns:5;spacing:12
  Repeater {id:tiles;model:["horizon","performance","flight","altitude","speed","heading","bank","fpv","vertical","aoa"]
   Gallery.WidgetPreview {width:152;height:152;widgetKey:modelData}
  }
 }
 TestCase {
  name:"NativeWidgetCentering";when:windowShown
  function test_sample_values_are_gallery_only(){
   hudOverlayGrid.widgetGalleryPreviewActive=true
   compare(horizon.previewTelemetry("_fcMavlinkSystem","altitude_rel_m",0),120)
   compare(horizon.previewTelemetry("_fcMavlinkSystem","aoa",0),5)
   compare(horizon.previewTelemetry("_cameraStreamModelPrimary","camera_status",0),1)
   compare(horizon.previewTelemetry("_fcMavlinkSystem","unknown",99),99)
   compare(_fcMavlinkSystem.altitude_rel_m,250)
   hudOverlayGrid.widgetGalleryPreviewActive=false
   compare(horizon.previewTelemetry("_fcMavlinkSystem","altitude_rel_m",250),250)
   compare(horizon.previewTelemetry("_cameraStreamModelPrimary","camera_status",0),0)
   hudOverlayGrid.widgetGalleryPreviewActive=true
  }
  function test_real_drawings_centered_and_visible(){
   wait(500)
   for(var i=0;i<tiles.count;i++){
    var tile=tiles.itemAt(i)
    tile.snapshot="";tile.refresh()
    tryVerify(function(){return tile.snapshot.length>0},5000,tile.widgetKey+" must render even when disabled")
    tryCompare(findChild(tile,"centeredWidgetImage"),"status",1,5000)
    wait(250)
    var image=grabImage(tile)
    image.save("build/widget-preview-"+tile.widgetKey+".png")
    var left=image.width,top=image.height,right=-1,bottom=-1,lit=0
    for(var y=5;y<image.height-5;y++)for(var x=5;x<image.width-5;x++){
     var p=image.pixel(x,y)
     if(p.r>0.2&&p.g>0.2&&p.b>0.2){left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);lit++}
    }
    verify(lit>10,tile.widgetKey+" visible pixels")
    verify(Math.abs((left+right)/2-(image.width-1)/2)<=3,tile.widgetKey+" centered horizontally "+left+":"+right)
    verify(Math.abs((top+bottom)/2-(image.height-1)/2)<=3,tile.widgetKey+" centered vertically "+top+":"+bottom)
    image.save("build/widget-preview-"+tile.widgetKey+".png")
   }
   compare(settings.show_widgets,false);compare(settings.show_horizon,false);compare(settings.show_flight_path_vector,false)
   grabImage(scene).save("build/widget-preview-native-grid.png")
  }
 }
}
