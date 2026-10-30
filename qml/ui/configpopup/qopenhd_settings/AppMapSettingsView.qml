import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"

FocusScope {
 id:root
 objectName:"mapSettingsPage"
 readonly property var mapTarget:hudOverlayGrid.mapSettingsTarget
 readonly property var builder:typeof _offlineMapBuilder!=="undefined"?_offlineMapBuilder:null
 readonly property var tiles:typeof _offlineMapTiles!=="undefined"?_offlineMapTiles:null
 readonly property var sourceMap:mapTarget?mapTarget.map:null
 readonly property bool wide:width>=1100
 readonly property real leftWidth:wide?Math.floor((pageScroll.width-12)*0.56):pageScroll.width
 readonly property real rightWidth:wide?pageScroll.width-leftWidth-12:pageScroll.width
 readonly property bool busy:builder && (builder.busy || builder.searching)
 property url areaSelectionSource:"../../widgets/map/OfflineMapSelection.qml"
 property bool selecting:false
 property string selectionMode:"circle"
 property var pendingRegion:null
 property int detailLevel:1
 readonly property int estimatedTiles:builder&&selectionCanvas.item&&selectionCanvas.item.selectionValid?builder.tileCount(selectionCanvas.item.south,selectionCanvas.item.west,selectionCanvas.item.north,selectionCanvas.item.east,13+detailLevel):0
 readonly property string previewRevision:[settings.map_zoom,settings.map_orientation,settings.map_drone_track,settings.map_show_mission_waypoints,settings.map_round,settings.map_size,settings.selected_map_provider,settings.selected_map_variant,settings.adsb_enable,settings.adsb_source,settings.adsb_radius,mapTarget?mapTarget.followDrone:false].join("|")
 Material.theme:settings_form.darkMode?Material.Dark:Material.Light
 Material.accent:settings_form.accentColor
 Material.foreground:settings_form.primaryText
 function gainFocus(){showMapControl.forceActiveFocus()}
 function updateViewport(){
  if(mapTarget && typeof mapTarget.settingsPreviewSize!=="undefined")mapTarget.settingsPreviewSize=visible&&!selecting?Qt.size(mapFrame.width,mapFrame.height):Qt.size(0,0)
 }
 function refreshPreview(){if(visible&&!selecting)capture.restart()}
 function setZoom(value){
  settings.map_zoom=Math.max(1,Math.min(30,Math.round(value)))
  if(sourceMap)sourceMap.zoomLevel=Math.max(sourceMap.minimumZoomLevel,Math.min(sourceMap.maximumZoomLevel,settings.map_zoom))
  refreshPreview()
 }
 function beginSelection(){
  if(!builder || busy)return
  selecting=true
  updateViewport()
  if(!selectionCanvas.active){
   if(settings.map_api_key.trim())builder.setMapboxKey(settings.map_api_key.trim())
   selectionCanvas.setSource(root.areaSelectionSource,{
    initialLatitude:applicationWindow.referenceLatitude,initialLongitude:applicationWindow.referenceLongitude,
    tileCacheDirectory:builder.mapCacheDirectory(settings.map_api_key.trim()?"preview_mapbox":"preview"),
    tileHost:settings.map_api_key.trim()?builder.mapboxBaseUrl:tiles.osmBaseUrl,
    usingMapbox:settings.map_api_key.trim().length>0})
   selectionCanvas.active=true
  }else applySelectionMode()
 }
 function applySelectionMode(){
  if(!selectionCanvas.item)return
  selectionCanvas.item.radiusMode=selectionMode==="circle"
  selectionCanvas.item.drawing=selectionMode==="rectangle"
  if(pendingRegion){selectionCanvas.item.fitRegion(pendingRegion);pendingRegion=null}
  else if(selectionMode==="circle")selectionCanvas.item.selectCenterRadius()
 }
 function chooseMode(mode){selectionMode=mode;beginSelection()}
 function searchLocation(){if(builder&&region.text.trim()&&!busy){beginSelection();builder.search(region.text.trim())}}
 function finishSelection(){selecting=false;selectionCanvas.active=false;updateViewport();refreshPreview()}
 function createMap(){
  if(!builder||busy||estimatedTiles<=0||!selectionCanvas.item)return
  var area=selectionCanvas.item
  builder.generate(region.text.trim(),area.south,area.west,area.north,area.east,13+detailLevel)
 }
 onPreviewRevisionChanged:Qt.callLater(refreshPreview)
 onSourceMapChanged:Qt.callLater(refreshPreview)
 onVisibleChanged:{updateViewport();if(visible)refreshPreview();else {capture.stop();selectionCanvas.active=false;selecting=false}}
 Component.onCompleted:{updateViewport();refreshPreview()}
 Component.onDestruction:if(mapTarget&&typeof mapTarget.settingsPreviewSize!=="undefined")mapTarget.settingsPreviewSize=Qt.size(0,0)
 Timer {id:capture;interval:450;repeat:false;onTriggered:if(root.visible&&root.sourceMap&&!root.selecting)mapTexture.scheduleUpdate()}
 Connections {target:root.sourceMap;ignoreUnknownSignals:true;function onMapReadyChanged(){root.refreshPreview()} function onErrorChanged(){root.refreshPreview()}}
 Connections {
  target:root.builder;ignoreUnknownSignals:true
  function onGenerated(filePath){
   if(root.tiles)root.tiles.reload()
   if(settings.selected_map_provider===2&&root.mapTarget)root.mapTarget.configure()
   else settings.selected_map_provider=2
   root.finishSelection()
  }
 }
 Flickable {
  id:pageScroll;objectName:"mapPageScroll";anchors.fill:parent;anchors.margins:10
  clip:true;contentWidth:width;contentHeight:panels.height;boundsBehavior:Flickable.StopAtBounds
  Item {
   id:panels;width:pageScroll.width
   height:root.wide?Math.max(leftPanels.height,rightPanels.height):leftPanels.height+rightPanels.height+12
   Column {
    id:leftPanels;width:root.leftWidth;spacing:12
    MapSettingsCard {
     id:displayCard;width:parent.width;height:implicitHeight;title:qsTr("Map Display");subtitle:qsTr("Configure the map on your flight screen");icon:"\uf279"
     Grid {
      Layout.fillWidth:true;columns:width>=560?2:1;spacing:12
      MapSettingRow {
       id:showMapRow;width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Show map");hint:qsTr("Display the map on the OSD");controlWidth:48
       WidgetToggle {id:showMapControl;objectName:"mapShow";anchors.fill:parent;checked:settings.show_map;onToggled:settings.show_map=checked}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Small map opacity");hint:qsTr("Opacity when minimised")
       MapValueSlider {anchors.fill:parent;from:0.1;to:1;stepSize:0.1;value:settings.map_opacity_minimized;displayText:Math.round(value*100)+"%";onMoved:settings.map_opacity_minimized=value}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Follow aircraft");hint:qsTr("Keep the aircraft centred");controlWidth:48
       WidgetToggle {objectName:"mapFollow";anchors.fill:parent;checked:root.mapTarget&&root.mapTarget.followDrone;enabled:!!root.mapTarget;onToggled:root.mapTarget.followDrone=checked}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Expanded map opacity");hint:qsTr("Opacity when expanded")
       MapValueSlider {anchors.fill:parent;from:0.1;to:1;stepSize:0.1;value:settings.map_opacity_maximized;displayText:Math.round(value*100)+"%";onMoved:settings.map_opacity_maximized=value}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Zoom level");hint:qsTr("Default map zoom")
       MapValueSlider {anchors.fill:parent;objectName:"mapZoom";from:1;to:30;stepSize:1;value:settings.map_zoom;displayText:Math.round(value).toString();onMoved:root.setZoom(value)}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Lock to drone direction");hint:qsTr("Rotate with the drone heading");controlWidth:48
       WidgetToggle {objectName:"mapDirection";anchors.fill:parent;checked:settings.map_orientation;onToggled:settings.map_orientation=checked}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Small map shape");hint:qsTr("Shape of the minimised map");controlWidth:shapeChoices.implicitWidth;minimumControlWidth:shapeChoices.implicitWidth
       RowLayout {id:shapeChoices;anchors.fill:parent;spacing:6
        MapActionButton {objectName:"mapShapeRound";Layout.fillWidth:true;text:qsTr("Round");primary:settings.map_round;onClicked:settings.map_round=true}
        MapActionButton {objectName:"mapShapeRectangle";Layout.fillWidth:true;text:qsTr("Rounded rectangle");primary:!settings.map_round;onClicked:settings.map_round=false}
       }
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Show drone track");hint:qsTr("Draw the aircraft's path");controlWidth:48
       WidgetToggle {objectName:"mapTrack";anchors.fill:parent;checked:settings.map_drone_track;onToggled:settings.map_drone_track=checked}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Small map size");hint:qsTr("Width of the minimised map")
       MapValueSlider {anchors.fill:parent;objectName:"mapSize";from:0.25;to:8;stepSize:0.05;value:settings.map_size;displayText:root.mapTarget?Math.round(root.mapTarget.compactWidth)+" px":"--";onMoved:settings.map_size=value}
      }
      MapSettingRow {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight
       label:qsTr("Show mission waypoints");hint:qsTr("Display the mission on the map");controlWidth:48
       WidgetToggle {objectName:"mapWaypoints";anchors.fill:parent;checked:settings.map_show_mission_waypoints;onToggled:settings.map_show_mission_waypoints=checked}
      }
     }
    }
    MapSettingsCard {
     width:parent.width;height:implicitHeight;title:qsTr("Map Source & Style");subtitle:qsTr("Map provider, imagery and credentials");icon:"\uf03e"
     Grid {
      Layout.fillWidth:true;columns:width>=650?3:1;spacing:10
      Column {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;spacing:6
       Text {text:qsTr("Map Provider");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
       Text {text:qsTr("Select map data source");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
       CompactLinkComboBox {topInset:0;bottomInset:0;font.pixelSize:Typography.body;objectName:"mapProvider";optionIcon:"\uf279";width:parent.width;height:Typography.controlHeight;model:root.mapTarget?root.mapTarget.pluginModel:[];textRole:"description";currentIndex:settings.selected_map_provider;onActivated:settings.selected_map_provider=currentIndex}
      }
      Column {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;spacing:6
       Text {text:qsTr("Map Style");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
       Text {text:qsTr("Visual style for the map");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
       CompactLinkComboBox {topInset:0;bottomInset:0;font.pixelSize:Typography.body;
        id:mapStyle;objectName:"mapStyle";width:parent.width;height:Typography.controlHeight;textRole:"description"
        model:root.mapTarget&&root.mapTarget.activeProviderName==="mapboxgl"?root.mapTarget.supportedMapTypes:[{description:settings.selected_map_provider===2?qsTr("Offline"):settings.selected_map_provider===1?qsTr("Streets"):qsTr("Standard (default)")}]
        enabled:root.mapTarget&&root.mapTarget.activeProviderName==="mapboxgl"&&count>0
        currentIndex:enabled?root.mapTarget.activeMapTypeIndex:0;onActivated:settings.selected_map_variant=currentIndex
       }
      }
      Column {
       width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;spacing:6
       Text {text:qsTr("Mapbox API key");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
       Text {text:qsTr("Required for Mapbox maps");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
       TextField {objectName:"mapApiKey";width:parent.width;height:Typography.controlHeight;leftPadding:12;rightPadding:12;topPadding:0;bottomPadding:0;verticalAlignment:TextInput.AlignVCenter;text:settings.map_api_key;placeholderText:"pk.xxxxx";echoMode:TextInput.Password;selectByMouse:true;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;onEditingFinished:settings.map_api_key=text.trim();background:Rectangle {radius:7;color:settings_form.pageBackground;border.color:settings_form.lineColor}}
      }
     }
     Flow {Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:10
      Text {width:Math.max(160,parent.width-160);text:qsTr("Mapbox requires a public access token from account.mapbox.com. OpenStreetMap and OpenHD Offline need no key.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
      MapActionButton {objectName:"reloadMap";text:qsTr("Reload map");iconText:"\uf2f1";enabled:!!root.mapTarget;onClicked:{root.mapTarget.configure();root.refreshPreview()}}
     }
    }
    MapSettingsCard {
     width:parent.width;height:implicitHeight;title:qsTr("ADS-B");subtitle:qsTr("Nearby aircraft from ADS-B data");icon:"\uf072"
     Grid {Layout.fillWidth:true;columns:width>=760?3:1;spacing:14
      MapSettingRow {width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight;label:qsTr("Enable ADS-B");hint:qsTr("Show air traffic on map");controlWidth:48
       WidgetToggle {objectName:"mapAdsbEnabled";anchors.fill:parent;checked:settings.adsb_enable;onToggled:settings.adsb_enable=checked}
      }
      MapSettingRow {width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight;label:qsTr("ADS-B source");hint:qsTr("Data source for air traffic");controlWidth:180
       RowLayout {anchors.fill:parent;spacing:0;enabled:settings.adsb_enable
        MapActionButton {objectName:"mapAdsbInternet";Layout.fillWidth:true;implicitWidth:105;text:qsTr("Internet feed");primary:settings.adsb_source===0;onClicked:settings.adsb_source=0}
        MapActionButton {objectName:"mapAdsbSdr";Layout.fillWidth:true;implicitWidth:55;text:qsTr("SDR");primary:settings.adsb_source===1;onClicked:settings.adsb_source=1}
       }
      }
      MapSettingRow {width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:implicitHeight;label:qsTr("ADS-B radius");hint:qsTr("Aircraft within this range");controlWidth:160
       MapValueSlider {anchors.fill:parent;objectName:"mapAdsbRadius";from:5000;to:100000;stepSize:1000;value:settings.adsb_radius;displayText:Math.round(value/1000)+" km";enabled:settings.adsb_enable;onMoved:settings.adsb_radius=value}
      }
     }
    }
    Rectangle {
     visible:settings_form.showDeveloperSettings===true;width:parent.width;height:70;radius:9;color:settings_form.panelBackground;border.color:settings_form.lineColor
     RowLayout {anchors.fill:parent;anchors.margins:12;spacing:12
      Text {text:"\uf0ad";font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon;color:settings_form.secondaryText}
      ColumnLayout {Layout.fillWidth:true;spacing:2
       Text {text:qsTr("Developer / Demo");font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true;color:settings_form.primaryText}
       Text {Layout.fillWidth:true;text:qsTr("Tools for map development");font.family:Typography.family;font.pixelSize:Typography.helper;color:settings_form.secondaryText;wrapMode:Text.WordWrap}
      }
      MapActionButton {objectName:"toggleMapDemo";text:root.mapTarget&&root.mapTarget.demoFlight?qsTr("Stop demo"):qsTr("Debug: circling plane");iconText:"\uf2f1";enabled:!!root.mapTarget;onClicked:{root.mapTarget.demoFlight=!root.mapTarget.demoFlight;if(root.mapTarget.demoFlight){settings.show_map=true;root.mapTarget.followDrone=true}root.refreshPreview()}}
     }
    }
   }
   Column {
    id:rightPanels;width:root.rightWidth;x:root.wide?leftPanels.width+12:0;y:root.wide?0:leftPanels.height+12;spacing:12
    MapSettingsCard {
     width:parent.width;height:implicitHeight;title:root.selecting?qsTr("Choose offline map area"):qsTr("Live Map Preview");subtitle:root.selecting?qsTr("Choose a centre or draw a rectangle on the map"):qsTr("Your map with the current settings");icon:"\uf06e"
     Rectangle {
      id:mapFrame;objectName:"mapPreviewFrame";Layout.fillWidth:true;Layout.preferredHeight:root.wide?Math.max(220,displayCard.height-94):(root.rightWidth-28)*0.53;Layout.minimumHeight:220
      color:"#0b1923";radius:7;clip:true
      onWidthChanged:Qt.callLater(root.updateViewport)
      onHeightChanged:Qt.callLater(root.updateViewport)
      ShaderEffectSource {id:mapTexture;objectName:"actualMapPreview";anchors.fill:parent;sourceItem:root.visible&&!root.selecting?root.sourceMap:null;sourceRect:root.sourceMap?Qt.rect(0,0,root.sourceMap.width,root.sourceMap.height):Qt.rect(0,0,1,1);textureSize:Qt.size(Math.max(1,width*2),Math.max(1,height*2));live:false;hideSource:false;smooth:true}
      Loader {id:selectionCanvas;objectName:"offlineAreaCanvas";anchors.fill:parent;active:false;visible:root.selecting;onLoaded:root.applySelectionMode()}
      Text {
       anchors.centerIn:parent;width:parent.width-80
       visible:!root.selecting&&(!root.sourceMap || (root.mapTarget&&(root.mapTarget.apiKeyMissing||root.mapTarget.mapFailure.length>0)))
       text:root.mapTarget&&root.mapTarget.apiKeyMissing?qsTr("Add a Mapbox key to load this map"):root.mapTarget&&root.mapTarget.mapFailure?root.mapTarget.mapFailure:qsTr("Waiting for map data")
       color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap
      }
      Text {anchors.centerIn:parent;width:parent.width-40;visible:root.selecting&&selectionCanvas.status===Loader.Error;text:qsTr("Map preview unavailable. Check Qt Location and Positioning support.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap;horizontalAlignment:Text.AlignHCenter}
      Rectangle {
       anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:8;width:copyrightText.implicitWidth+12;height:22;radius:4;color:"#d9071b2a";visible:!root.selecting
       Text {id:copyrightText;objectName:"mapMenuAttribution";anchors.centerIn:parent;text:'<a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>';linkColor:"#e4f1fa";font.family:Typography.family;font.pixelSize:Typography.helper;onLinkActivated:Qt.openUrlExternally(link)}
      }
      MapActionButton {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:8;text:root.selecting?qsTr("Close selection"):"";iconText:root.selecting?"\uf00d":"\uf2f1";implicitWidth:root.selecting?130:36;implicitHeight: Typography.controlHeight;enabled:!root.busy;onClicked:root.selecting?root.finishSelection():root.refreshPreview()}
      Column {anchors.left:parent.left;anchors.top:parent.top;anchors.margins:8;spacing:5;visible:!root.selecting
       MapActionButton {implicitWidth:36;implicitHeight: Typography.controlHeight;text:"+";enabled:!!root.sourceMap;onClicked:root.setZoom(settings.map_zoom+1)}
       MapActionButton {implicitWidth:36;implicitHeight: Typography.controlHeight;text:"-";enabled:!!root.sourceMap;onClicked:root.setZoom(settings.map_zoom-1)}
      }
      Rectangle {
       anchors.right:parent.right;anchors.top:parent.top;anchors.margins:8;width:Math.min(parent.width-75,providerInfo.implicitWidth+18);height:providerInfo.implicitHeight+14;radius:6;color:"#df071b2a";visible:!root.selecting
       Text {id:providerInfo;anchors.centerIn:parent;text:qsTr("Provider: %1").arg(settings.selected_map_provider===2?"OpenHD Offline":settings.selected_map_provider===1?"Mapbox":"OpenStreetMap")+"\n"+qsTr("Style: %1").arg(mapStyle.currentText);color:"white";font.family:Typography.family;font.pixelSize:Typography.helper}
      }
     }

    }
    MapSettingsCard {
     width:parent.width;height:implicitHeight;title:qsTr("Offline Maps");subtitle:qsTr("Maps for areas without an internet connection");icon:"\uf019"
     headerNote:width>650?qsTr("%1 packages installed").arg(root.tiles?root.tiles.packageCount:0):""
     Text {text:qsTr("Installed maps");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
     Flow {Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:10
      CompactLinkComboBox {topInset:0;bottomInset:0;font.pixelSize:Typography.body;id:offlinePackages;objectName:"offlinePackages";optionIcon:"\uf279";width:parent.width>600?Math.max(180,parent.width-355):parent.width;height:Typography.controlHeight;model:root.tiles?root.tiles.packages:[];textRole:"name";enabled:count>0}
      MapActionButton {objectName:"jumpToOfflineMap";text:qsTr("Jump to map");iconText:"\uf35d";enabled:offlinePackages.currentIndex>=0&&!!root.mapTarget;onClicked:{root.mapTarget.jumpToOfflineMap(root.tiles.packages[offlinePackages.currentIndex]);root.refreshPreview()}}
      MapActionButton {objectName:"prepareOfflineMap";text:qsTr("Create offline map");iconText:"\uf019";primary:true;enabled:!!root.builder&&!root.busy;onClicked:root.beginSelection()}
     }
     Rectangle {
      Layout.fillWidth:true;implicitHeight:creationBody.implicitHeight+28;radius:9;color:"transparent";border.color:settings_form.lineColor
      Column {
       id:creationBody;x:14;y:14;width:parent.width-28;spacing:12
       RowLayout {width:parent.width;spacing:12
        Text {text:"\uf279";font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon;color:settings_form.accentColor}
        ColumnLayout {Layout.fillWidth:true;spacing:2
         Text {text:qsTr("Create Offline Map");font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;color:settings_form.primaryText}
         Text {text:qsTr("Choose a map region for offline use");font.family:Typography.family;font.pixelSize:Typography.helper;color:settings_form.secondaryText}
        }
       }
       RowLayout {width:parent.width;spacing:8
        TextField {id:region;objectName:"offlineRegionSearch";Layout.fillWidth:true;Layout.minimumWidth:0;implicitHeight:Typography.controlHeight;leftPadding:12;rightPadding:12;topPadding:0;bottomPadding:0;verticalAlignment:TextInput.AlignVCenter;placeholderText:qsTr("Search for a location (city, region...)");selectByMouse:true;enabled:!!root.builder&&!root.busy;onAccepted:root.searchLocation();color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;background:Rectangle {radius:7;color:settings_form.pageBackground;border.color:settings_form.lineColor}}
        MapActionButton {text:qsTr("Find");implicitWidth:60;enabled:region.text.trim().length>0&&!root.busy;onClicked:root.searchLocation()}
       }
       CompactLinkComboBox {topInset:0;bottomInset:0;font.pixelSize:Typography.body;
        objectName:"offlineRegionResults";width:parent.width;height:Typography.controlHeight;visible:count>0;model:root.builder?root.builder.searchResults:[];textRole:"name";enabled:!root.busy
        onActivated:{root.pendingRegion=model[currentIndex];root.beginSelection()}
        onModelChanged:{currentIndex=-1;if(model&&model.length===1){currentIndex=0;root.pendingRegion=model[0];Qt.callLater(root.beginSelection)}}
       }
       Grid {
        width:parent.width;columns:width>590?3:1;spacing:12
        ColumnLayout {height:implicitHeight;width:parent.columns===3?parent.width*0.34:parent.width;spacing:7
         Text {text:qsTr("Selection mode");font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.secondaryText}
         RowLayout {width:parent.width;spacing:0
          MapActionButton {objectName:"offlineRectangle";Layout.fillWidth:true;implicitWidth:90;text:qsTr("Rectangle");primary:root.selectionMode==="rectangle";enabled:!!root.builder&&!root.busy;onClicked:root.chooseMode("rectangle")}
          MapActionButton {objectName:"offlineCircle";Layout.fillWidth:true;implicitWidth:78;text:qsTr("Circle");primary:root.selectionMode==="circle";enabled:!!root.builder&&!root.busy;onClicked:root.chooseMode("circle")}
         }
        }
        ColumnLayout {height:implicitHeight;width:parent.columns===3?parent.width*0.27:parent.width;spacing:7
         Text {text:qsTr("Detail level");font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.secondaryText}
         CompactLinkComboBox {topInset:0;bottomInset:0;font.pixelSize:Typography.body;objectName:"offlineDetail";Layout.fillWidth:true;Layout.preferredHeight:Typography.controlHeight;model:[qsTr("Overview"),qsTr("Standard"),qsTr("High detail"),qsTr("Maximum detail")];currentIndex:root.detailLevel;enabled:!root.busy;onActivated:root.detailLevel=currentIndex}
        }
        ColumnLayout {height:implicitHeight;width:parent.columns===3?parent.width*0.39-24:parent.width;spacing:7
         Text {text:qsTr("Map size");font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.secondaryText}
         Text {objectName:"offlineEstimate";Layout.fillWidth:true;text:root.estimatedTiles<0?qsTr("Area too large"):root.estimatedTiles>0?qsTr("%1 tiles").arg(root.estimatedTiles):qsTr("Select an area");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
         MapActionButton {objectName:"createOfflineMap";text:qsTr("Create map");iconText:"\uf019";primary:true;enabled:root.selecting&&root.estimatedTiles>0&&!root.busy;onClicked:root.createMap()}
        }
       }
       Text {width:parent.width;text:root.selectionMode==="circle"?qsTr("Circle: 50 km radius. File size depends on map detail."):qsTr("Draw a rectangle in the preview. File size depends on map detail.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
       Text {width:parent.width;text:root.builder?root.builder.status:qsTr("Offline map builder unavailable");visible:text.length>0;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
       ProgressBar {width:parent.width;visible:root.busy;value:root.builder?root.builder.progress:0;indeterminate:root.builder&&(root.builder.searching||root.builder.progress===0)}
       MapActionButton {text:qsTr("Cancel");visible:root.busy;onClicked:root.builder.cancel()}
      }
     }
    }
   }
  }
 }
}
