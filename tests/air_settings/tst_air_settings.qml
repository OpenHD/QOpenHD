import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/openhd_settings" as Air
import "../../qml/ui/configpopup/openhd_settings/AirSettingsLayout.js" as AirLayout
Item {
 id: scene; width: 1000; height: 740
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form
 property bool darkMode:true;property bool showAdvancedSettings:true;property bool showDeveloperSettings:false
 property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb"
 property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b"
 property color lineColor:"#26394c";property color accentColor:"#278cff";property color goodColor:"#35dc72"
 }
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true}
 QtObject {id:_messageBoxInstance;function set_text_and_show(text){}}
 QtObject {id:_airCameraSettingsModel2}
 QtObject {
 id:_ohdSystemAirSettingsModel
 property int update_count:0;property bool ui_is_busy:false;property bool has_params_fetched:true
 property var values:({FC_UART_CONN:"UART1",FC_UART_BAUD:921600,FC_UART_FLWCTL:0,FC_SYS_ID:1,FC_BATT_N_CELLS:3,FC_FW_INFO:"INAV",FC_FW_EVID:'{"evidence":"Firmware reply"}',OHD_UART_EN:1,OHD_UART_TLM:"UART2",OHD_UART_BAUD:115200,OHD_UART_FLW:0,SBUS_EN:0,SBUS_DEV:"UART3",SBUS_HZ:50,GPIO_2:0,GPIO_26:0,LOG_OPENHD:1,LOG_MAVLINK:0,WB_V_FEC_PERC:20,AUDIO_ENABLE:1,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1,ADSB_ENABLE:1,SIYI_ACTIVE:0,TOPOTEK_ACTIVE:0,CAM_CTRL_ACTIVE:0,CONFIG_BOOT_AIR:1,DEV_HIGH_RETR:0,WB_MAX_D_BZ:20,WB_DEV_LOGS:0})
 property int writes:0
 function param_ids(){return Object.keys(values).filter(function(id){return ["FC_FW_INFO","FC_FW_EVID","LOG_OPENHD","LOG_MAVLINK","DEV_HIGH_RETR","WB_MAX_D_BZ","WB_DEV_LOGS"].indexOf(id)<0}).reverse()}
 function param_int_exists(id){return typeof values[id] === "number"}
 function param_string_exists(id){return typeof values[id] === "string"}
 function get_cached_int(id){return values[id]}
 function get_cached_string(id){return values[id]}
 function get_ui_metadata(id){return {cameraOnly:["GX_GAIN","ISO","AWB_MODE_LC","ISP_GAIN"].indexOf(id)>=0,control: id.indexOf("_EN")>=0 || id.indexOf("LOG_")===0 ? "toggle" : "number",readOnly:id==="FC_FW_INFO" || id==="FC_FW_EVID",description:"",label:id}}
 function int_param_has_enum_keys_values(id){return false}
 function string_param_has_enum(id){return false}
 function int_param_has_min_max(id){return false}
 function get_warning_before_safe(id){return ""}
 function ensure_parameters_available(){}
 function try_set_param_int_async(id,value,log){values[id]=value;writes++;update_count++}
 function try_set_param_string_async(id,value,log){values[id]=value;writes++;update_count++}
 }
 QtObject {id:_ohdSystemGround;property bool is_alive:true}
 QtObject {
 id:_ohdSystemGroundSettings
 property int update_count:0;property bool ui_is_busy:false;property bool has_params_fetched:true
 property var values:({FC_UART_CONN:"UART1",FC_UART_BAUD:921600,FC_UART_FLWCTL:0,FC_SYS_ID:1,FC_BATT_N_CELLS:3,FC_FW_INFO:"INAV",FC_FW_EVID:'{"evidence":"Firmware reply"}',OHD_UART_EN:1,OHD_UART_TLM:"UART2",OHD_UART_BAUD:115200,OHD_UART_FLW:0,SBUS_EN:0,SBUS_DEV:"UART3",SBUS_HZ:50,GPIO_2:0,GPIO_26:0,LOG_OPENHD:1,LOG_MAVLINK:0,WB_V_FEC_PERC:20,AUDIO_ENABLE:1,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1,ADSB_ENABLE:1,SIYI_ACTIVE:0,TOPOTEK_ACTIVE:0,CAM_CTRL_ACTIVE:0,CONFIG_BOOT_AIR:1,DEV_HIGH_RETR:0,WB_MAX_D_BZ:20,WB_DEV_LOGS:0})
 property int writes:0
 function param_ids(){return Object.keys(values).filter(function(id){return ["FC_FW_INFO","FC_FW_EVID","LOG_OPENHD","LOG_MAVLINK","DEV_HIGH_RETR","WB_MAX_D_BZ","WB_DEV_LOGS"].indexOf(id)<0}).reverse()}
 function param_int_exists(id){return typeof values[id] === "number"}
 function param_string_exists(id){return typeof values[id] === "string"}
 function get_cached_int(id){return values[id]}
 function get_cached_string(id){return values[id]}
 function get_ui_metadata(id){return {cameraOnly:["GX_GAIN","ISO","AWB_MODE_LC","ISP_GAIN"].indexOf(id)>=0,control: id.indexOf("_EN")>=0 || id.indexOf("LOG_")===0 ? "toggle" : "number",readOnly:id==="FC_FW_INFO" || id==="FC_FW_EVID",description:"",label:id}}
 function int_param_has_enum_keys_values(id){return false}
 function string_param_has_enum(id){return false}
 function int_param_has_min_max(id){return false}
 function get_warning_before_safe(id){return ""}
 function ensure_parameters_available(){}
 function try_set_param_int_async(id,value,log){values[id]=value;writes++;update_count++}
 function try_set_param_string_async(id,value,log){values[id]=value;writes++;update_count++}
 }
 Air.AirSettingsPanel {id:groundPanel;anchors.fill:parent;groundMode:true;visible:false;activeCategory:"system"}

 Rectangle {anchors.fill:parent;color:"#091827"}
 Air.AirSettingsPanel {id:panel;anchors.fill:parent;anchors.margins:16}
 TestCase {
  function test_radio_internal_settings_developer_only(){
   var ids=["WFB_LINK_EN","WIFI_CARD0","WIFI_CARD1","WIFI_CARD2","WIFI_CARD3","WIFI_CARD12","WB_ADAPT_CH","WB_FHSS","WB_FHSS_SLOT","FHSS_VIA_RC"]
   for(var i=0;i<ids.length;i++){
    verify(!AirLayout.visibleInMode(ids[i],false,false))
    verify(!AirLayout.visibleInMode(ids[i],true,false))
    verify(AirLayout.visibleInMode(ids[i],true,true))
   }
  }
  function test_all_ar1_developer_only(){
   var ids=["AR1_S_SNR","AR1_S_MCS","AR1_CONFIG","AR1_CHANNEL"]
   for(var i=0;i<ids.length;i++){
    verify(!AirLayout.visibleInMode(ids[i],false,false))
    verify(!AirLayout.visibleInMode(ids[i],true,false))
    verify(AirLayout.visibleInMode(ids[i],true,true))
   }
  }

 name:"AirSettings";when:windowShown
 function test_artosyn_self_diagnostics_require_developer_mode(){
 var original=_ohdSystemAirSettingsModel.values
 var advanced=settings_form.showAdvancedSettings
 var developer=settings_form.showDeveloperSettings
 var suffixes=["SNR","LDPT","LDPN","GNA","GNB","MCS","CHN","PWR","LNI","LNF","1TX","TFK","LSN","LGA","LGB","HSN","HGA","HGB"]
 var diagnostics={}
 for(var i=0;i<suffixes.length;i++) diagnostics["AR1_S_"+suffixes[i]]=1
 _ohdSystemAirSettingsModel.values=diagnostics;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true;settings_form.showDeveloperSettings=false
 compare(panel.parameterIds.length,0);compare(panel.categories.length,0)
 settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=true
 compare(panel.parameterIds.length,0)
 compare(panel.categories.length,0)
 compare(panel.idsForSection("developerControls").length,0)
 // Developer mode must not manufacture diagnostics when firmware supplies none.
 _ohdSystemAirSettingsModel.values={};_ohdSystemAirSettingsModel.update_count++
 compare(panel.parameterIds.length,0);compare(panel.categories.length,0)
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=advanced;settings_form.showDeveloperSettings=developer
 }
 function test_categories_and_live_controls(){
 compare(panel.activeCategory,"fc")
 compare(panel.idsForSection("fcSerial").join(","),"FC_UART_CONN,FC_UART_BAUD,FC_UART_FLWCTL")
 verify(findChild(panel,"airSection_battery")!==null)
 verify(findChild(panel,"airSection_fcInfo")!==null)
 mouseClick(findChild(panel,"airCategory_peripherals"));compare(panel.activeCategory,"peripherals")
 var port=findChild(panel,"airSetting_FC_UART_CONN");verify(port!==null)
 var baud=findChild(panel,"airSetting_FC_UART_BAUD");baud.commitChoice(115200)
 compare(_ohdSystemAirSettingsModel.values.FC_UART_BAUD,115200)
 var flow=findChild(panel,"airSetting_FC_UART_FLWCTL");flow.commitToggle(true)
 compare(_ohdSystemAirSettingsModel.values.FC_UART_FLWCTL,1)
 compare(findChild(panel,"airSetting_SBUS_EN"),null)
 _qopenhd.debugMenuPreview=true
 var writes=_ohdSystemAirSettingsModel.writes
 flow.commitToggle(false);compare(_ohdSystemAirSettingsModel.writes,writes)
 _qopenhd.debugMenuPreview=false
 panel.activeCategory="expert";settings_form.showAdvancedSettings=false
 compare(panel.activeCategory,"fc");verify(panel.categories.every(function(c) { return panel.categoryCount(c.id) > 0 }))
 settings_form.showAdvancedSettings=true
 }
 function test_empty_categories_and_live_fallback(){
 var original=_ohdSystemAirSettingsModel.values
 var advanced=settings_form.showAdvancedSettings
 var developer=settings_form.showDeveloperSettings
 settings_form.showAdvancedSettings=true
 settings_form.showDeveloperSettings=false
 _ohdSystemAirSettingsModel.values={FC_BATT_N_CELLS:3,FC_UART_BAUD:115200}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.categories.map(function(c){return c.id}).join(","),"fc,peripherals")
 panel.activeCategory="peripherals"
 _ohdSystemAirSettingsModel.values={FC_BATT_N_CELLS:3}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.activeCategory,"fc")
 compare(findChild(panel,"airCategory_peripherals"),null)
 _ohdSystemAirSettingsModel.values={}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.categories.length,0)
 compare(panel.activeCategory,"")
 panel.gainFocus()
 _ohdSystemAirSettingsModel.values={FC_UART_BAUD:115200}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.activeCategory,"peripherals")
 settings_form.showAdvancedSettings=advanced
 settings_form.showDeveloperSettings=developer
 _ohdSystemAirSettingsModel.values=original
 _ohdSystemAirSettingsModel.update_count++
 }
 function test_compact_navigation_keeps_settings_space(){
 scene.width=760;scene.height=400;wait(50)
 compare(findChild(panel,"airCategoryStrip").height,44)
 verify(findChild(panel,"airSettingsBody").height >= panel.height - 60)
 scene.width=480;scene.height=320;wait(50)
 compare(findChild(panel,"airCategoryStrip").height,44)
 verify(findChild(panel,"airSettingsBody").height >= panel.height - 60)
 scene.width=1000;scene.height=740
 }
 function test_first_batch_review_and_developer_tier(){
 settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false
 panel.activeCategory="fc"
 var decisions=AirLayout.reviewDecisions, ids=Object.keys(decisions)
 compare(ids.length,24)
 for(var i=0;i<ids.length;i++) compare(panel.parameterIds.indexOf(ids[i])>=0,decisions[ids[i]]==="KEEP" && AirLayout.belongsInAir(ids[i]),ids[i])
 compare(panel.idsForSection("fcInfo").join(","),"FC_FW_INFO")
 var info=findChild(panel,"airSetting_FC_FW_INFO");verify(info.locked);compare(info.displayValue,"INAV");compare(findChild(panel,"airSetting_FC_FW_EVID"),null)
 settings_form.showAdvancedSettings=true
 for(var j=0;j<ids.length;j++) compare(panel.parameterIds.indexOf(ids[j])>=0,AirLayout.belongsInAir(ids[j]),ids[j])
 compare(panel.parameterIds.indexOf("AUDIO_ENABLE"),-1)
 compare(panel.parameterIds.indexOf("ADSB_ENABLE"),-1)
 compare(panel.parameterIds.indexOf("DEV_HIGH_RETR"),-1)
 verify(panel.categories.filter(function(c){return c.id==="developer"}).length===0)
 settings_form.showDeveloperSettings=true
 compare(panel.parameterIds.indexOf("DEV_HIGH_RETR"),-1)
 compare(panel.categories.filter(function(c){return c.id==="developer"}).length,0)
 panel.activeCategory="developer";settings_form.showDeveloperSettings=false
 compare(panel.activeCategory,"fc")
 }
 function test_dedicated_settings_never_duplicate_in_air(){
 var original=_ohdSystemAirSettingsModel.values
 var all=Object.assign({},original)
 var owned=Object.keys(AirLayout.dedicatedPages).concat(["WB_UDP_ENABLE","WB_UDP_FEC","AUDIO_GAIN","ADSB_ENABLE"])
 for(var i=0;i<owned.length;i++) all[owned[i]]=1
 _ohdSystemAirSettingsModel.values=all;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true;settings_form.showDeveloperSettings=true
 _qopenhd.debugMenuPreview=true
 for(var j=0;j<owned.length;j++) compare(panel.parameterIds.indexOf(owned[j]),-1,owned[j])
 compare(panel.idsForSection("video").length,0)
 compare(panel.idsForSection("links").length,0)
 settings_form.showAdvancedSettings=false
 for(var r=0;r<owned.length;r++) compare(panel.parameterIds.indexOf(owned[r]),-1,owned[r])
 settings_form.showAdvancedSettings=true
 // Each setting has a single home within Air as well.
 var seen={}
 for(var k=0;k<AirLayout.sections.length;k++) {
 var section=AirLayout.sections[k]
 compare(section.categories.length,1,section.id)
 for(var n=0;n<section.ids.length;n++) {verify(!seen[section.ids[n]],section.ids[n]);seen[section.ids[n]]=true}
 }
 _qopenhd.debugMenuPreview=false;settings_form.showDeveloperSettings=false
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 }
 function test_link_cards_collapse_and_developer_gate(){
 var original=_ohdSystemAirSettingsModel.values
 _ohdSystemAirSettingsModel.values={BW_VIA_RC:0,MCS_VIA_RC:0,RC_UPDATE_HZ:50,WB_PASSIVE_MODE:0,WB_RED_TX:0,WB_E_STBC:0,WB_E_LDPC:0,AR_ADDR:"127.0.0.1",AR_PORT:9000}
 _ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true;settings_form.showDeveloperSettings=false
 panel.activeCategory="expert";wait(40)
 compare(panel.sectionsForCategory("expert").map(function(s){return s.id}).join(","),"rcRadio,radio,artosyn")
 compare(panel.parameterIds.indexOf("RC_UPDATE_HZ"),-1)
 verify(AirLayout.isHardwareDiagnostic("RC_UPDATE_HZ"))
 verify(!AirLayout.visibleInMode("RC_UPDATE_HZ",true,false))
 verify(AirLayout.visibleInMode("RC_UPDATE_HZ",true,true))
 var rc=findChild(panel,"airSection_rcRadio"),radio=findChild(panel,"airSection_radio"),artosyn=findChild(panel,"airSection_artosyn")
 verify(rc!==null);verify(radio!==null);verify(artosyn!==null)
 verify(radio.x>rc.x);verify(artosyn.y>radio.y);compare(artosyn.x,rc.x)
 compare(findChild(panel,"airSetting_AR_ADDR"),null)
 findChild(panel,"airSectionToggle_artosyn").clicked();wait(20)
 verify(findChild(panel,"airSetting_AR_ADDR")!==null)
 compare(findChild(panel,"airSetting_WB_E_STBC"),null)
 findChild(panel,"airRfCodingToggle_radio").clicked();wait(20)
 verify(findChild(panel,"airSetting_WB_E_STBC")!==null)
 scene.width=480;wait(40);verify(radio.y>rc.y);verify(artosyn.y>radio.y)
 scene.width=1000
 _ohdSystemAirSettingsModel.values={BW_VIA_RC:0,WB_RED_TX:0};_ohdSystemAirSettingsModel.update_count++;wait(20)
 compare(findChild(panel,"airSection_artosyn"),null)
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 panel.activeCategory="fc"
 }
 function test_ground_shared_layout_dedup_and_correct_target(){
 _ohdSystemGroundSettings.values={WIFI_MODE:1,WIFI_HS_SSID:"OpenHD-Ground",WIFI_CL_SSID:"Home",SYS_RUN_MODE:"ground",SYS_DISP_FORCE:0,SYS_DISP_MODE:"1920x1080@60",ETH_LINK_EN:1,ETHERNET:0,FC_UART_CONN:"UART1",ENABLE_JOY_RC:1,RC_UPDATE_HZ:50,AR1_S_SNR:12,WB_FREQUENCY:5745,TX_POWER_I:10,GX_GAIN:1,LOG_OPENHD:0,TRACKER_UART_OUT:"UART2",HOTSPOT_CARD:0,CONFIG_BOOT_AIR:0,SYS_PLATFORM:4}
 _ohdSystemGroundSettings.update_count++
 groundPanel.visible=true;settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false
 groundPanel.activeCategory="system";wait(40)
 verify(findChild(groundPanel,"airSection_wifi")!==null)
 verify(findChild(groundPanel,"airSetting_WIFI_HS_SSID")!==null)
 compare(groundPanel.parameterIds.slice().sort().join(","),"SYS_RUN_MODE,WIFI_CL_SSID,WIFI_HS_SSID,WIFI_MODE")
 var before=_ohdSystemAirSettingsModel.writes
 findChild(groundPanel,"wifiMode2").clicked();wait(30)
 compare(_ohdSystemGroundSettings.values.WIFI_MODE,2)
 compare(_ohdSystemAirSettingsModel.writes,before)
 compare(findChild(groundPanel,"airSetting_WIFI_HS_SSID"),null)
 var client=findChild(groundPanel,"airSetting_WIFI_CL_SSID");verify(client!==null)
 _ohdSystemAir.is_alive=false;verify(!client.busy)
 _ohdSystemGround.is_alive=false;verify(client.busy)
 var writes=_ohdSystemGroundSettings.writes;client.commitChoice("blocked");compare(_ohdSystemGroundSettings.writes,writes)
 _ohdSystemAir.is_alive=true;_ohdSystemGround.is_alive=true
 settings_form.showAdvancedSettings=true;wait(30)
 verify(findChild(groundPanel,"airSection_display")!==null)
 groundPanel.activeCategory="ethernet";wait(30)
 var ethernet=findChild(groundPanel,"airSetting_ETH_LINK_EN");verify(ethernet!==null);verify(ethernet.toggle)
 ethernet.commitToggle(false);compare(_ohdSystemGroundSettings.values.ETH_LINK_EN,0)
 settings_form.showAdvancedSettings=false;wait(30);compare(groundPanel.activeCategory,"system")
 scene.width=480;wait(30)
 var mode=findChild(groundPanel,"wifiMode2"),point=mode.mapToItem(scene,0,0);verify(point.x+mode.width<=scene.width)
 scene.width=1000;groundPanel.visible=false;settings_form.showAdvancedSettings=true
 }
 function test_link_ownership_and_removed_settings(){
 var ids=["WB_FREQUENCY","WB_CHANNEL_W","WB_MCS_INDEX","ESP_ANALYSE","TX_PWR_LVL","WB_PIT_MODE","VARIABLE_BITRATE","V_PRIMARY_PERC","HOTSPOT_CARD","QP_MIN","QP_MAX"]
 for(var i=0;i<ids.length;i++)verify(!AirLayout.belongsInAir(ids[i],true),ids[i])
 compare(AirLayout.categories.filter(function(c){return c.id==="expert"})[0].title,"Link")
 var retransmission=["WB_ENABLE_RETRA","WB_RTX_VIDEO","WB_RTX_TELEM","WB_RTX_RC","WB_RTX_V_MAXMS","WB_RTX_T_MAXMS","WB_RTX_R_MAXMS","WB_RTX_REQ_REP"]
 for(var j=0;j<retransmission.length;j++){
 verify(!AirLayout.visibleInMode(retransmission[j],true,false))
 verify(AirLayout.isHardwareDiagnostic(retransmission[j]))
 verify(AirLayout.visibleInMode(retransmission[j],true,true))
 }
 }
 function test_uart_fc_normal_and_link_developer_only(){
 var advanced=settings_form.showAdvancedSettings
 settings_form.showAdvancedSettings=false;panel.activeCategory="peripherals";wait(30)
 compare(panel.sectionsForCategory("peripherals").map(function(s){return s.id}).join(","),"fcSerial,gpio")
 compare(panel.sectionsForCategory("peripherals")[0].title,"Flight-controller MAVLink")
 compare(findChild(panel,"airSetting_OHD_UART_EN"),null)
 settings_form.showAdvancedSettings=true;wait(30)
 compare(panel.sectionsForCategory("peripherals").map(function(s){return s.id}).join(","),"fcSerial,gpio")
 compare(findChild(panel,"airSection_telemetry"),null)
 settings_form.showDeveloperSettings=true
 compare(panel.idsForSection("telemetry").length,0)
 settings_form.showDeveloperSettings=false
 compare(panel.validateUart("FC_UART_CONN","UART2").length>0,true)
 compare(panel.validateUart("OHD_UART_TLM","UART1").length>0,true)
 compare(panel.validateUart("OHD_UART_EN",0),"")
 settings_form.showAdvancedSettings=advanced
 }
 function test_narrow_and_offline(){
 scene.width=480;panel.activeCategory="peripherals";wait(50)
 verify(panel.width<480)
 _ohdSystemAir.is_alive=false
 var flow=findChild(panel,"airSetting_FC_UART_FLWCTL");verify(flow.busy)
 var writes=_ohdSystemAirSettingsModel.writes;flow.commitToggle(false)
 compare(_ohdSystemAirSettingsModel.writes,writes)
 _ohdSystemAir.is_alive=true;scene.width=1000
 }
 function test_camera_parameters_never_appear_under_system(){
 var original=_ohdSystemAirSettingsModel.values
 _ohdSystemAirSettingsModel.values={GX_GAIN:0,ISO:100,AWB_MODE_LC:0,ISP_GAIN:100};_ohdSystemAirSettingsModel.update_count++
 compare(panel.parameterIds.length,0)
 settings_form.showAdvancedSettings=true;settings_form.showDeveloperSettings=true
 compare(panel.parameterIds.length,0)
 settings_form.showDeveloperSettings=false
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 }
 function test_air_hides_ground_display_and_platform_fields(){
 var original=_ohdSystemAirSettingsModel.values
 _ohdSystemAirSettingsModel.values={SYS_DISP_FORCE:1,SYS_DISP_MODE:"1920x1080@60",SYS_PLATFORM:11,BOARD_TYPE:11};_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true;settings_form.showDeveloperSettings=true
 compare(panel.parameterIds.length,0)
 settings_form.showDeveloperSettings=false
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 }
 function test_ethernet_advanced_category_and_no_joystick_duplicate(){
 var original=_ohdSystemAirSettingsModel.values
 _ohdSystemAirSettingsModel.values={ETH_LINK_EN:1,ETHERNET:0,ETH_HOTSPOT_E:0,ETH_PASSIVE_F:1,ENABLE_JOY_RC:1};_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false
 compare(panel.categories.length,0)
 settings_form.showAdvancedSettings=true
 compare(panel.categories.map(function(c){return c.id}).join(","),"ethernet")
 compare(panel.idsForSection("ethernet").join(","),"ETH_LINK_EN,ETHERNET,ETH_HOTSPOT_E,ETH_PASSIVE_F")
 compare(panel.parameterIds.indexOf("ENABLE_JOY_RC"),-1)
 compare(panel.idsForSection("additional").length,0)
 panel.activeCategory="ethernet";wait(30)
 var ethernet=findChild(panel,"airSetting_ETH_LINK_EN")
 verify(ethernet!==null);verify(ethernet.toggle)
 ethernet.commitToggle(false);compare(_ohdSystemAirSettingsModel.values.ETH_LINK_EN,0)
 ethernet.commitToggle(true);compare(_ohdSystemAirSettingsModel.values.ETH_LINK_EN,1)
 settings_form.showAdvancedSettings=false;compare(panel.categories.length,0)
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true
 }
 function test_wifi_single_card_switches_fields_without_overwriting_other_mode(){
 var original=_ohdSystemAirSettingsModel.values
 _ohdSystemAirSettingsModel.values={WIFI_MODE:1,WIFI_HOTSPOT_E:0,WIFI_HS_IFACE:"wlan0",WIFI_HS_SSID:"OpenHD-Air",WIFI_HS_PW:"hotspot-secret",WIFI_CL_IFACE:"wlan1",WIFI_CL_SSID:"Workshop",WIFI_CL_PW:"client-secret",WIFI_IFACES:"wlan0",CONFIG_BOOT_AIR:1,SYS_RUN_MODE:1};_ohdSystemAirSettingsModel.update_count++
 panel.activeCategory="system";wait(50)
 compare(findChild(panel,"airCategory_uart"),null)
 compare(findChild(panel,"airSection_role"),null)
 compare(panel.parameterIds.indexOf("CONFIG_BOOT_AIR"),-1)
 verify(findChild(panel,"airSection_wifi")!==null)
 compare(findChild(panel,"airSection_hotspot"),null);compare(findChild(panel,"airSection_wifiClient"),null)
 verify(findChild(panel,"airSetting_WIFI_HS_SSID")!==null);compare(findChild(panel,"airSetting_WIFI_CL_SSID"),null)
 findChild(panel,"wifiMode2").clicked();wait(40)
 compare(_ohdSystemAirSettingsModel.values.WIFI_MODE,2)
 compare(findChild(panel,"airSetting_WIFI_HS_SSID"),null);verify(findChild(panel,"airSetting_WIFI_CL_SSID")!==null)
 compare(_ohdSystemAirSettingsModel.values.WIFI_HS_SSID,"OpenHD-Air")
 findChild(panel,"airSetting_WIFI_CL_SSID").commitChoice("New network")
 compare(_ohdSystemAirSettingsModel.values.WIFI_CL_SSID,"New network")
 findChild(panel,"wifiMode1").clicked();wait(40)
 compare(findChild(panel,"airSetting_WIFI_HS_SSID").value,"OpenHD-Air")
 findChild(panel,"wifiMode0").clicked();wait(40)
 compare(findChild(panel,"airSetting_WIFI_HS_SSID"),null);compare(findChild(panel,"airSetting_WIFI_CL_SSID"),null)
 verify(findChild(panel,"airSetting_WIFI_IFACES")!==null)
 scene.width=480;wait(40)
 var button=findChild(panel,"wifiMode2"),point=button.mapToItem(scene,0,0)
 verify(point.x+button.width<=scene.width)
 scene.width=1000
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 }
 }
}
