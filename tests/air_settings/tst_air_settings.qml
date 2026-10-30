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
 function get_ui_metadata(id){return {control: id.indexOf("_EN")>=0 || id.indexOf("LOG_")===0 ? "toggle" : "number",readOnly:id==="FC_FW_INFO" || id==="FC_FW_EVID",description:"",label:id}}
 function int_param_has_enum_keys_values(id){return false}
 function string_param_has_enum(id){return false}
 function int_param_has_min_max(id){return false}
 function get_warning_before_safe(id){return ""}
 function ensure_parameters_available(){}
 function try_set_param_int_async(id,value,log){values[id]=value;writes++;update_count++}
 function try_set_param_string_async(id,value,log){values[id]=value;writes++;update_count++}
 }
 Rectangle {anchors.fill:parent;color:"#091827"}
 Air.AirSettingsPanel {id:panel;anchors.fill:parent;anchors.margins:16}
 TestCase {
  function test_radio_internal_settings_developer_only(){
   var ids=["WFB_LINK_EN","WIFI_CARD0","WIFI_CARD1","WIFI_CARD2","WIFI_CARD3","WIFI_CARD12"]
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
 compare(panel.parameterIds.length,suffixes.length)
 compare(panel.categories.length,1);compare(panel.categories[0].id,"developer")
 compare(panel.idsForSection("developerControls").length,suffixes.length)
 // Developer mode must not manufacture diagnostics when firmware supplies none.
 _ohdSystemAirSettingsModel.values={};_ohdSystemAirSettingsModel.update_count++
 compare(panel.parameterIds.length,0);compare(panel.categories.length,0)
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=advanced;settings_form.showDeveloperSettings=developer
 }
 function test_categories_and_live_controls(){
 compare(panel.activeCategory,"fc")
 compare(panel.idsForSection("fcSerial").length,0)
 verify(findChild(panel,"airSection_battery")!==null)
 verify(findChild(panel,"airSection_fcInfo")!==null)
 compare(findChild(panel,"airSetting_FC_UART_CONN"),null)
 mouseClick(findChild(panel,"airCategory_uart"));compare(panel.activeCategory,"uart")
 var sbus=findChild(panel,"airSetting_SBUS_EN")
 verify(sbus!==null);compare(sbus.value,0)
 wait(50)
 var toggle=findChild(sbus,"airToggle_SBUS_EN")
 mouseClick(toggle,toggle.width-19,toggle.height/2);compare(_ohdSystemAirSettingsModel.values.SBUS_EN,1)
 compare(findChild(panel,"airSetting_SBUS_EN"),sbus)
 _qopenhd.debugMenuPreview=true
 var writes=_ohdSystemAirSettingsModel.writes
 sbus.commitToggle(false);compare(_ohdSystemAirSettingsModel.writes,writes)
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
 _ohdSystemAirSettingsModel.values={FC_BATT_N_CELLS:3,SBUS_EN:0}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.categories.map(function(c){return c.id}).join(","),"fc,uart")
 panel.activeCategory="uart"
 _ohdSystemAirSettingsModel.values={FC_BATT_N_CELLS:3}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.activeCategory,"fc")
 compare(findChild(panel,"airCategory_uart"),null)
 _ohdSystemAirSettingsModel.values={}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.categories.length,0)
 compare(panel.activeCategory,"")
 panel.gainFocus()
 _ohdSystemAirSettingsModel.values={SBUS_EN:0}
 _ohdSystemAirSettingsModel.update_count++
 compare(panel.activeCategory,"uart")
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
 compare(panel.idsForSection("fcInfo").join(","),"FC_FW_INFO,FC_FW_EVID")
 var info=findChild(panel,"airSetting_FC_FW_EVID");verify(info.locked);compare(info.displayValue,"Firmware reply")
 settings_form.showAdvancedSettings=true
 for(var j=0;j<ids.length;j++) compare(panel.parameterIds.indexOf(ids[j])>=0,AirLayout.belongsInAir(ids[j]),ids[j])
 compare(panel.parameterIds.indexOf("AUDIO_ENABLE"),-1)
 compare(panel.parameterIds.indexOf("ADSB_ENABLE"),-1)
 compare(panel.parameterIds.indexOf("DEV_HIGH_RETR"),-1)
 verify(panel.categories.filter(function(c){return c.id==="developer"}).length===0)
 settings_form.showDeveloperSettings=true
 verify(panel.parameterIds.indexOf("DEV_HIGH_RETR")>=0)
 verify(panel.categories.filter(function(c){return c.id==="developer"}).length===1)
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
 for(var j=0;j<owned.length;j++) compare(panel.parameterIds.indexOf(owned[j])>=0,AirLayout.isLinkRecoveryParameter(owned[j]),owned[j])
 compare(panel.idsForSection("video").length,0)
 verify(panel.idsForSection("links").length>0)
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
 function test_local_link_override_uses_air_model(){
 var original=_ohdSystemAirSettingsModel.values
 var local=Object.assign({},original,{WB_FREQUENCY:5745,WB_CHANNEL_W:20,WB_MCS_INDEX:2})
 _ohdSystemAirSettingsModel.values=local;_ohdSystemAirSettingsModel.update_count++
 settings_form.showAdvancedSettings=true;_qopenhd.debugMenuPreview=false
 panel.activeCategory="expert";wait(30)
 var frequency=findChild(panel,"airSetting_WB_FREQUENCY")
 verify(frequency!==null);compare(frequency.settingsModel,_ohdSystemAirSettingsModel)
 var writes=_ohdSystemAirSettingsModel.writes
 frequency.commitChoice(5805)
 compare(_ohdSystemAirSettingsModel.writes,writes+1)
 compare(_ohdSystemAirSettingsModel.values.WB_FREQUENCY,5805)
 compare(_ohdSystemAirSettingsModel.values.WB_CHANNEL_W,20)
 compare(_ohdSystemAirSettingsModel.values.WB_MCS_INDEX,2)
 _ohdSystemAirSettingsModel.values=original;_ohdSystemAirSettingsModel.update_count++
 panel.activeCategory="fc"
 }
 function test_narrow_and_offline(){
 scene.width=480;panel.activeCategory="uart";wait(50)
 verify(panel.width<480)
 _ohdSystemAir.is_alive=false
 var sbus=findChild(panel,"airSetting_SBUS_EN");verify(sbus.busy)
 var writes=_ohdSystemAirSettingsModel.writes;sbus.commitToggle(false)
 compare(_ohdSystemAirSettingsModel.writes,writes)
 _ohdSystemAir.is_alive=true;scene.width=1000
 }
 }
}
