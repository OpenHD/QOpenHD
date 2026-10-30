import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
Item {
 id:scene;width:1600;height:1000
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool showDeveloperSettings:false;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff"}
 QtObject {id:applicationWindow;property real referenceLatitude:50.1;property real referenceLongitude:7.1}
 QtObject {
  id:settings
  property bool show_map:false;property bool map_round:true;property bool map_orientation:false
  property bool map_drone_track:true;property bool map_show_mission_waypoints:true
  property real map_size:1;property real map_opacity_minimized:1;property real map_opacity_maximized:1
  property int map_zoom:18;property int selected_map_provider:0;property int selected_map_variant:0
  property string map_api_key:"";property bool adsb_enable:false;property int adsb_source:0;property real adsb_radius:50000
 }
 ListModel {id:plugins;ListElement {description:"OpenStreetMap"} ListElement {description:"Mapbox (API key)"} ListElement {description:"OpenHD Offline"}}
 QtObject {
  id:mapTarget;property Item map:mapCanvas;property bool followDrone:true;property bool demoFlight:false
  property size settingsPreviewSize:Qt.size(0,0)
  readonly property real compactWidth:Math.max(184,200*settings.map_size)*(settings.map_round?0.7:1)
  readonly property string activeProviderName:settings.selected_map_provider===1?"mapboxgl":settings.selected_map_provider===2?"openhd_offline":"osm"
  property bool apiKeyMissing:false;property string mapFailure:"";property var pluginModel:plugins
  property var supportedMapTypes:[{description:"Streets"},{description:"Satellite"}];property int activeMapTypeIndex:0
  property int reloads:0;property int jumps:0
  function configure(){reloads++} function jumpToOfflineMap(pkg){jumps++}
 }
 Rectangle {
  id:mapCanvas;visible:false;color:"#325847"
  width:mapTarget.settingsPreviewSize.width>0?mapTarget.settingsPreviewSize.width:200
  height:mapTarget.settingsPreviewSize.height>0?mapTarget.settingsPreviewSize.height:200
  property bool mapReady:true;property int error:0;property real minimumZoomLevel:1;property real maximumZoomLevel:20;property real zoomLevel:18
  Text {anchors.centerIn:parent;text:"Map render fixture";color:"white"}
 }
 QtObject {id:hudOverlayGrid;property var mapSettingsTarget:mapTarget}
 QtObject {id:_offlineMapTiles;property int packageCount:1;property var packages:[{name:"Local area",minZoom:0,maxZoom:14}];property string osmBaseUrl:"http://fixture.invalid/";property int reloads:0;function reload(){reloads++}}
 QtObject {
  id:_offlineMapBuilder;property bool busy:false;property bool searching:false;property string status:"";property real progress:0
  property var searchResults:[];property string mapboxBaseUrl:"http://fixture.invalid/mapbox/"
  property int searches:0;property int generations:0;property int lastZoom:0
  signal generated(string filePath)
  function mapCacheDirectory(source){return "fixture-cache"} function setMapboxKey(key){}
  function search(query){searches++;searchResults=[{name:"Chosen area",south:50,north:51,west:7,east:8}]}
  function tileCount(s,w,n,e,z){return 1234}
  function generate(name,s,w,n,e,z){generations++;lastZoom=z}
  function cancel(){busy=false;searching=false}
 }
 Rectangle {anchors.fill:parent;color:settings_form.pageBackground}
 Pages.AppMapSettingsView {id:page;anchors.fill:parent;areaSelectionSource:Qt.resolvedUrl("SelectionFixture.qml")}
 TestCase {
  name:"MapSettings";when:windowShown
  function visual(item,name){if(item.objectName===name)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var found=visual(children[i],name);if(found)return found}return null}
  function init(){scene.Window.window.width=1600;scene.Window.window.height=1000;scene.width=1600;scene.height=1000;page.visible=true;page.finishSelection();settings.map_round=true;settings_form.showDeveloperSettings=false;visual(page,"mapPageScroll").contentY=0;wait(100)}
  function test_round_default_and_real_controls(){
   compare(settings.map_round,true);compare(settings.show_map,false)
   mouseClick(visual(page,"mapShapeRectangle"));compare(settings.map_round,false)
   mouseClick(visual(page,"mapShapeRound"));compare(settings.map_round,true)
   mouseClick(visual(page,"mapShow"));compare(settings.show_map,true)
   var zoom=visual(page,"mapZoom");zoom.value=12;zoom.moved();compare(settings.map_zoom,12);compare(mapCanvas.zoomLevel,12)
   mouseClick(visual(page,"mapAdsbEnabled"));compare(settings.adsb_enable,true)
   mouseClick(visual(page,"mapAdsbSdr"));compare(settings.adsb_source,1)
  }
  function test_preview_borrows_and_restores_viewport(){
   wait(100)
   var frame=visual(page,"mapPreviewFrame"),texture=visual(page,"actualMapPreview")
   compare(texture.sourceItem,mapCanvas);compare(texture.live,false);compare(texture.hideSource,false)
   compare(mapTarget.settingsPreviewSize.width,frame.width)
   page.visible=false;compare(mapTarget.settingsPreviewSize.width,0);page.visible=true
   compare(visual(page,"toggleMapDemo").visible,false)
   settings_form.showDeveloperSettings=true;compare(visual(page,"toggleMapDemo").visible,true)
  }
  function test_input_alignment_and_shape_bounds(){
   var key=visual(page,"mapApiKey")
   compare(key.verticalAlignment,TextInput.AlignVCenter);verify(key.leftPadding>=12);verify(key.rightPadding>=12)
   var widths=[1600,1280,1100,800,420]
   for(var i=0;i<widths.length;i++){
    scene.Window.window.width=widths[i];scene.width=widths[i];wait(60)
    var round=visual(page,"mapShapeRound"),rectangle=visual(page,"mapShapeRectangle")
    verify(round.x>=0);verify(rectangle.x+rectangle.width<=rectangle.parent.width+1)
    verify(round.x+round.width<=rectangle.x)
    var label=visual(rectangle,"actionButtonLabel")
    verify(label.contentWidth<=label.width+1,"Shape text exceeds its button at width "+widths[i])
   }
  }
  function test_offline_controls_use_builder(){
   page.beginSelection();tryCompare(visual(page,"offlineAreaCanvas"),"status",Loader.Ready)
   compare(page.selectionMode,"circle");compare(page.estimatedTiles,1234)
   page.detailLevel=2;page.createMap();compare(_offlineMapBuilder.generations,1);compare(_offlineMapBuilder.lastZoom,15)
   _offlineMapBuilder.generated("fixture.gldmap");compare(settings.selected_map_provider,2);compare(page.selecting,false);compare(_offlineMapTiles.reloads,1)
   page.chooseMode("rectangle");tryCompare(visual(page,"offlineAreaCanvas"),"status",Loader.Ready);compare(visual(page,"offlineAreaCanvas").item.drawing,true)
   page.finishSelection()
  }
  function test_region_search_selects_real_result(){
   visual(page,"offlineRegionSearch").text="Chosen area"
   page.searchLocation();compare(_offlineMapBuilder.searches,1)
   tryVerify(function(){return page.selecting && page.pendingRegion===null})
   compare(visual(page,"offlineAreaCanvas").item.south,50)
   compare(page.estimatedTiles,1234)
  }
  function test_responsive_capture(){
   page.selectionMode="circle";page.detailLevel=1;_offlineMapBuilder.searchResults=[];visual(page,"offlineRegionSearch").text="";settings.selected_map_provider=0
   wait(250);grabImage(scene).save("build/map-settings-wide.png")
   scene.Window.window.width=800;scene.Window.window.height=650;scene.width=800;scene.height=650
   wait(200);compare(page.wide,false);verify(visual(page,"mapPageScroll").contentHeight>650)
   grabImage(scene).save("build/map-settings-compact.png")
   scene.Window.window.width=420;scene.Window.window.height=650;scene.width=420;scene.height=650
   wait(200);verify(visual(page,"mapPageScroll").width<=420)
   grabImage(scene).save("build/map-settings-narrow.png")
  }
 }
}
