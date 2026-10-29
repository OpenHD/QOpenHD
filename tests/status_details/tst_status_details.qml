import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup" as Menu
Item {
 FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
 FontLoader { source: "../../qml/osdfonts/Archivo-Regular.ttf" }
 FontLoader { source: "../../qml/osdfonts/Archivo-Bold.ttf" }

 Component.onCompleted: Qt.application.font = Qt.font({family: "Segoe UI", pixelSize: 13})
 property bool captureImages: false
 id: scene; width: 1543; height: 565
 property var _cameraStreamModelPrimary: testCamera
 QtObject {
  id: testCamera
  property int camera_status: 1
  property int camera_type: 124
  property int encoding_codec: 1
  function camera_codec_to_string(value) { return "H.265" }
  property string curr_set_video_format: "1920x1080@60"
  property int curr_received_bitrate_with_fec_bps: 12300000
  property int curr_video_measured_encoder_bitrate_bps: 6600000
  property int curr_video_injected_bitrate_bps: 7920000
  function camera_type_to_string(value) { return "ORQA REKINDLE" }
 }
 property var _audioControl: testAudio
 QtObject { id: testAudio; property bool playing: true; property int playbackVolume: 70; function setPlaybackEnabled(enabled) { playing = enabled } }
 property var _ohdSystemAir: air
 property var _ohdSystemGround: air
 property var _ohdSystemGroundSettings: params
 property var _ohdSystemAirSettingsModel: params
 property var _airCameraSettingsModel: params
 property var _fcMavlinkSystem: fc
 property var _wifi_card_air: wifi
 property var _wifi_card_gnd0: wifi
 property var _wifi_card_gnd1: wifi
 property var _wifi_card_gnd2: wifi
 property var _wifi_card_gnd3: wifi
 property var _qopenhd: ({version_string: "3.0.0-evo", debugMenuPreview: false, launchedFromQtCreator: true})
 QtObject {
  id: settings
  property int air_status_temp_warn: 85
  property int air_status_temp_caution: 75
  property int ground_status_temp_warn: 85
  property int ground_status_temp_caution: 75
  property int air_status_cpu_warn: 95
  property int air_status_cpu_caution: 85
  property int ground_status_cpu_warn: 95
  property int ground_status_cpu_caution: 85
  property int air_unit_battery_type: -1
  property int air_unit_battery_cells: 0
  property int air_unit_battery_capacity_mah: 0
  property int air_unit_battery_low: 0
  property int air_unit_battery_mid: 0
  property int air_unit_battery_full: 0
  property int ground_battery_type: 1
  property int ground_battery_cells: 4
  property int ground_battery_capacity_mah: 5200
  property int ground_battery_low: 27
  property int ground_battery_mid: 34
  property int ground_battery_full: 42
  property bool dev_enable_live_audio_playback: true
  property color color_caution: "#ffbd60"
 }
 QtObject {
  id: params
  property int update_count: 0
  property bool has_params_fetched: true
  property int encryption: 0
  property string writtenParam: ""
  property int writtenValue: -1
  function try_set_param_int_async(id,value,confirm) { writtenParam=id; writtenValue=value }
  function param_int_exists(id) { return true }
  function get_cached_int(id) { return encryption }
  function system_is_alive() { return true }
  function param_string_exists(id) { return false }
 }
 QtObject {
  id: air
  property bool is_alive: true
  property string openhd_version: "3.0.0-rc1"
  property string ohd_platform_type_as_string: "Radxa Zero 3W"
  property int ohd_platform_type: 0
  property bool artosyn_link_detected: false
  property int primary_link_type: 0
  property int current_rx_signal_quality: 92
  property double received_link_bitrate_bps: 13200000
  property bool artosyn_debug_stats_available: false
  property string last_ping_result_openhd: "28 ms"
  property int wifi_hotspot_state: 0
  property int curr_soc_temp_degree: 48
  property int curr_cpuload_perc: 38
  property int onboard_uptime_ms: 10000
  property bool rpi_undervolt_error: false
  property int air_reported_fc_sys_id: 1
  property int onboard_ram_usage_mib: 31
  property var ground_details: ({hotspot_clients: 2, hotspot_ip: "192.168.3.1", system_used_bytes: 1073741824, system_total_bytes: 4294967296, logs_used_bytes: 2147483648, logs_total_bytes: 8589934592})
  property int onboard_ram_total_mib: 3994 * 1024
  property int curr_space_left_mb: 42000
  property int wifi_hotspot_frequency: 5745
  property int external_devices_count: -1
  property int ina219_voltage_millivolt: 15800
  property int battery_percent: 62
  property var link_usage: [{id: 1, total_bps: 13200000}]
 }
 QtObject { id: wifi; property bool alive: true; property bool card_type_supported: true; property string card_type_as_string: "Devourer RTL822C" }
 QtObject {
  id: fc
  property bool is_alive: true
  property bool telemetry_active: true
  property var craft_diagnostics: ({heartbeatAge: 0.2, statusAge: 0.1, present: 3, enabled: 3, healthy: 3})
  property var firmware_identity: ({name: "ArduPilot", ver: 67438336})
  property string mav_type_str: "Quadcopter"
  property double battery_voltage_volt: 15.8
  property int battery_percent: 62
  property int satellites_visible: 12
  property string gps_status_fix_type_str: "3D"
  property bool armed: false
  property string flight_mode: "ALT_HOLD"
 }

 QtObject { id: hudOverlayGrid; function regain_focus() {} }
 Menu.ConfigPopup { id: menu; anchors.fill: parent }
 TestCase {
  name: "FullStatusLayout"; when: windowShown
  function visualChild(item,name) {
   if(item.objectName===name) return item
   if(item.children) for(var i=0;i<item.children.length;i++) { var found=visualChild(item.children[i],name);if(found) return found }
   return null
  }
  function test_ground_details_popup() {
   scene.width=850;scene.height=480
   tryVerify(function() { return menu.statusPanel !== null })
   var receiveHeader=findChild(menu,"statusOverviewHeader")
   verify(receiveHeader !== null)
   compare(receiveHeader.receivedLinkBps,13200000)
   air.received_link_bitrate_bps=0
   compare(receiveHeader.receivedLinkBps,0)
   air.received_link_bitrate_bps=-1
   compare(receiveHeader.receivedLinkBps,-1)
   air.received_link_bitrate_bps=13200000
   var cards=findChild(menu,"statusOverviewCards")
   mouseClick(cards.actionButtons()[0])
   tryVerify(function() { return findChild(menu,"groundStationDetailsPopup") !== null })
   var popup=findChild(menu,"groundStationDetailsPopup")
   tryCompare(popup,"visible",true)
   wait(150)
   verify(popup.width<scene.width);verify(popup.height<scene.height)
   if(scene.captureImages) grabImage(scene).save("build/status-layout-full/ground-details-850x480.png")
   mouseClick(visualChild(popup.contentItem,"groundHotspotMode1"))
   compare(params.writtenParam,"WIFI_HOTSPOT_E");compare(params.writtenValue,1)
   var chemistry=findChild(menu,"groundBatteryChemistry")
   compare(chemistry.count,3)
   compare(popup.ramTotal,3994)
   compare(popup.details.hotspot_clients,2)
   compare(popup.storageText("logs"),"2.0 / 8.0 GiB (25 %)")
   for (var size of [[850,480],[640,360],[1440,900]]) {
    scene.width=size[0];scene.height=size[1];wait(80)
    chemistry.popup.open();wait(80)
    var dropdown=chemistry.popup
    verify(dropdown.x>=0 && dropdown.y>=0)
    verify(dropdown.x+dropdown.width*dropdown.scale<=scene.width)
    verify(dropdown.y+dropdown.height*dropdown.scale<=scene.height)
    verify(dropdown.height>=150, "All three chemistry rows should fit")
    dropdown.close()
   }
   scene.width=850;scene.height=480;wait(80)
   chemistry.forceActiveFocus();keyClick(Qt.Key_Home);keyClick(Qt.Key_Return)
   compare(settings.ground_battery_type,0)
   compare(settings.ground_battery_low,33);compare(settings.ground_battery_full,42)
   var capacity=findChild(menu,"groundBatteryCapacity")
   capacity.popup.open();wait(80)
   capacity.popup.contentItem.currentIndex=capacity.capacities.indexOf(6000)
   keyClick(Qt.Key_Return)
   compare(settings.ground_battery_capacity_mah,6000)
   var cells=findChild(menu,"groundBatteryCells")
   compare(cells.count,7)
   compare(cells.optionDetails[3].description,"17.5-21.0 V - discharge to full")
   compare(cells.optionDetails[0].description,"7.0-8.4 V - discharge to full")
   compare(cells.optionDetails[6].description,"28.0-33.6 V - discharge to full")
   popup.chemistryChanged(1)
   compare(cells.optionDetails[0].description,"5.0-8.4 V - discharge to full")
   compare(cells.optionDetails[6].description,"20.0-33.6 V - discharge to full")
   popup.chemistryChanged(0)
   compare(cells.model[0],"2S");compare(cells.model[6],"8S")
   cells.popup.open();wait(80)
   cells.popup.contentItem.currentIndex=3
   keyClick(Qt.Key_Return)
   compare(settings.ground_battery_cells,5)
   compare(findChild(menu,"groundHotspotChannel").enabled,false)
   scene._qopenhd={version_string:"3.0.0-evo",debugMenuPreview:true,launchedFromQtCreator:true}
   compare(visualChild(popup.contentItem,"groundHotspotMode1").enabled,false)
   compare(findChild(menu,"groundBatteryCapacity").enabled,false)
   compare(visualChild(popup.contentItem,"groundDetailsReboot").enabled,false)
   scene._qopenhd={version_string:"3.0.0-evo",debugMenuPreview:false,launchedFromQtCreator:true}
   scene.width=1440;scene.height=900;wait(100)
   if(scene.captureImages) grabImage(scene).save("build/status-layout-full/ground-details-1440x900.png")
   mouseClick(findChild(menu,"groundDetailsClose"))
   tryCompare(popup,"visible",false)
   mouseClick(cards.actionButtons()[1])
   tryVerify(function() { return findChild(menu,"airUnitDetailsPopup") !== null })
   var airPopup=findChild(menu,"airUnitDetailsPopup")
   tryCompare(airPopup,"visible",true)
   if(scene.captureImages) grabImage(visualChild(airPopup.contentItem,"airCamerasPanel")).save("build/status-layout-full/air-camera-cards.png")
   compare(airPopup.systemType,1)
   compare(airPopup.width,popup.width)
   compare(airPopup.height,popup.height)
   compare(airPopup.uiScale,popup.uiScale)
   verify(visualChild(airPopup.contentItem,"airCamerasPanel").visible)
   compare(visualChild(airPopup.contentItem,"airCamera0Value0").text,"ORQA REKINDLE")
   compare(visualChild(airPopup.contentItem,"airCamera0Status").text,"Streaming")
   compare(visualChild(airPopup.contentItem,"airCamera0Value3").text,"6.6 Mbit/s")
   compare(visualChild(airPopup.contentItem,"airCamera0Value1").text,"1920 x 1080 @ 60 FPS")
   compare(visualChild(airPopup.contentItem,"airCamera0Value2").text,"H.265")
   compare(visualChild(airPopup.contentItem,"airCamera1Value0").text,"Not reported")
   compare(visualChild(airPopup.contentItem,"airCamerasPanel").height,236)
   verify(!findChild(airPopup,"groundBatteryChemistry").visible)
   compare(airPopup.unit,scene._ohdSystemAir)
   compare(airPopup.params,scene._ohdSystemAirSettingsModel)
   compare(airPopup.ramTotal,3994)
   compare(airPopup.details.hotspot_clients,2)
   airPopup.close()
  }
  function test_resize_and_alignment() {
   tryVerify(function() { return menu.statusPanel !== null })
   var cards=findChild(menu,"statusOverviewCards")
   verify(cards !== null)
   var sound=findChild(menu,"statusSoundButton")
   verify(sound!==null)
   mouseClick(sound)
   var popup=findChild(menu,"statusVolumePopup")
   tryCompare(popup,"visible",true)
   wait(150)
   var mute=findChild(menu,"statusMuteButton")
   mouseClick(mute);compare(scene._audioControl.playbackVolume,0)
   mouseClick(mute);compare(scene._audioControl.playbackVolume,70)
   var slider=findChild(menu,"statusVolumeSlider")
   slider.forceActiveFocus();keyClick(Qt.Key_Left)
   compare(scene._audioControl.playbackVolume,69)
   var playback=findChild(menu,"statusPlaybackSwitch")
   mouseClick(playback);compare(scene._audioControl.playing,false)
   mouseClick(playback);compare(scene._audioControl.playing,true)
   popup.close()
   var sizes=[[1440,900],[1920,1080],[1024,600],[850,480],[540,900]]
   for (var n=0;n<sizes.length;n++) {
    scene.width=sizes[n][0];scene.height=sizes[n][1];wait(150)
    if(scene.width===850) compare(cards.columns,3)
    verify(sound.visible)
    var soundPosition=sound.mapToItem(scene,0,0)
    verify(soundPosition.x>=0 && soundPosition.x+sound.width*0.45<scene.width)
    verify(Math.abs(cards.y - Math.max(0, Math.round((cards.availableHeight-cards.implicitHeight)/2))) < 1,"Cards are not vertically centered")
    var buttons=cards.actionButtons()
    verify(soundPosition.y + sound.height * 0.45 < buttons[0].parent.parent.mapToItem(scene,0,0).y)
    for(var i=0;i<buttons.length;i++) {
     var button=buttons[i], card=button.parent.parent
     var rect=card.mapToItem(scene,0,0)
     verify(rect.y >= 60,"Toolbar overlaps card at " + sizes[n])
     verify(rect.x + card.width <= scene.width + 1,"Horizontal overflow at " + sizes[n] + " card " + i + " x " + rect.x + " width " + card.width + " grid " + cards.width)
     verify(Math.abs(card.height-card.implicitHeight)<1,"Height does not follow scale")
     verify(card.cardScale > 0 && card.cardScale <= card.width/490+0.01 || card.cardScale===0.55)
     var body=button.parent.children[2].item
     var rows=[]
     for(var j=0;j<body.children.length;j++) if(body.children[j].m_left_text!==undefined) rows.push(body.children[j])
     compare(rows.length,6)
     compare(rows[3].m_left_text,"System health")
     compare(rows[4].m_left_text,"Battery")
     for(j=1;j<rows.length;j++) {
      var previous=findChild(rows[j-1],"statusRowValue"),current=findChild(rows[j],"statusRowValue")
      var a=previous.mapToItem(scene,previous.width,0),b=current.mapToItem(scene,current.width,0)
      verify(Math.abs(a.x-b.x)<1,"Values do not share a right edge")
     }
     if(cards.columns===3) {
      compare(card.height,buttons[0].parent.parent.height)
      verify(rect.y+card.height <=scene.height,"Footer outside viewport")
     }
    }
    if(scene.captureImages) grabImage(scene).save("build/status-layout-full/status-"+scene.width+"x"+scene.height+".png")
   }
  }
 }
}
