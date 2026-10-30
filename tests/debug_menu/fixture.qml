import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
Item {
 id:scene;width:1200;height:720
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool showAdvancedSettings:true;property bool showDeveloperSettings:true;property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color goodColor:"green";property color errorColor:"red";function side_bar_regain_focus(){}}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_messageBoxInstance;function set_text_and_show(message){}}
 QtObject {id:_ohdSystemAir;property bool is_alive:true;property string ohd_platform_type_as_string:"RPI 4"}
 QtObject {id:_ohdSystemGround;property bool is_alive:true;property string ohd_platform_type_as_string:"ROCK 5A"}
 QtObject {id:_mavlinkTelemetry;property int pings:0;function ping_all_systems(){pings++}}
 ListModel {id:_mavlinkMessageStatsModel;property bool enabled:false;function setEnabled(value){enabled=value}function decodeMessageDetails(index){return {messageName:"HEARTBEAT",messageId:0,fieldCount:0,fields:[]}}}
 Component {
  id:paramModel
  QtObject {
   property int update_count:0;property bool ui_is_busy:false;property var values:({});property string lastId:"";property int writes:0
   function param_ids(){return Object.keys(values)}
   function param_int_exists(id){return typeof values[id]==="number"}
   function param_string_exists(id){return typeof values[id]==="string"}
   function get_cached_int(id){return values[id]}
   function get_cached_string(id){return values[id]}
   function get_ui_metadata(id){return {label:id,description:"Hardware value",readOnly:id.indexOf("CARD")>=0}}
   function int_param_has_enum_keys_values(id){return false}function string_param_has_enum(id){return false}function int_param_has_min_max(id){return false}
   function get_warning_before_safe(id){return ""}
   function try_set_param_int_async(id,value,confirm){lastId=id;values[id]=value;writes++;update_count++}
   function try_set_param_string_async(id,value,confirm){lastId=id;values[id]=value;writes++;update_count++}
   function try_refetch_all_parameters_async(log){update_count++}
   function ensure_parameters_available(){}
  }
 }
 property var _ohdSystemAirSettingsModel:paramModel.createObject(scene)
 property var _ohdSystemGroundSettings:paramModel.createObject(scene)
 Pages.MavlinkDebugPanel {id:page;anchors.fill:parent}
 TestCase {
  name:"DebugMenu";when:windowShown
  function init(){page.visible=true;settings_form.showDeveloperSettings=true;_qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=true;_ohdSystemGround.is_alive=true;_ohdSystemAirSettingsModel.values={AR1_S_SNR:15,DEV_TEST:0,FC_UART_BAUD:115200};_ohdSystemGroundSettings.values={WIFI_CARD0:2,WFB_LINK_EN:1,TRACK_UART_BAUD:9600};_ohdSystemAirSettingsModel.update_count++;_ohdSystemGroundSettings.update_count++;findChild(page,"debugTabs").currentIndex=0;wait(100)}
  function test_mavlink_retained_and_capture_stops(){
   var loader=findChild(page,"debugMavlinkPage");tryCompare(loader,"status",Loader.Ready)
   findChild(loader.item,"mavlinkCaptureButton").clicked();compare(_mavlinkMessageStatsModel.enabled,true)
   findChild(page,"debugTabs").currentIndex=1;wait(50);compare(_mavlinkMessageStatsModel.enabled,false)
   findChild(page,"debugTabs").currentIndex=0;findChild(loader.item,"mavlinkPingButton").clicked();verify(_mavlinkTelemetry.pings>0)
   findChild(loader.item,"mavlinkCaptureButton").clicked();page.visible=false;compare(_mavlinkMessageStatsModel.enabled,false)
  }
  function test_hardware_sources_and_ownership(){
   var tabs=findChild(page,"debugTabs");compare(tabs.count,3);tabs.currentIndex=1
   var air=findChild(page,"debugAirPage"),ground=findChild(page,"debugGroundPage")
   compare(air.parameterIds.join(","),"AR1_S_SNR,DEV_TEST");compare(ground.parameterIds.join(","),"WFB_LINK_EN,WIFI_CARD0")
   var row=findChild(air,"hardwareDiagnostic_DEV_TEST");verify(row!==null);row.commitChoice(1);compare(_ohdSystemAirSettingsModel.lastId,"DEV_TEST");compare(_ohdSystemGroundSettings.writes,0)
   tabs.currentIndex=2;var radio=findChild(ground,"hardwareDiagnostic_WFB_LINK_EN");radio.commitChoice(0);compare(_ohdSystemGroundSettings.lastId,"WFB_LINK_EN")
   verify(findChild(ground,"hardwareDiagnostic_WIFI_CARD0").locked)
   _ohdSystemAir.is_alive=false;verify(row.busy);var before=_ohdSystemAirSettingsModel.writes;row.commitChoice(0);compare(_ohdSystemAirSettingsModel.writes,before)
   verify(!radio.busy)
  }
  function test_developer_gate_and_live_update(){
   var air=findChild(page,"debugAirPage");settings_form.showDeveloperSettings=false;compare(air.parameterIds.length,0)
   settings_form.showDeveloperSettings=true;verify(air.parameterIds.length>0)
   _ohdSystemAirSettingsModel.values={};_ohdSystemAirSettingsModel.update_count++;compare(air.parameterIds.length,0)
  }
  function test_experimental_radio_settings_are_developer_only(){
   var air=findChild(page,"debugAirPage"),ground=findChild(page,"debugGroundPage")
   _ohdSystemAirSettingsModel.values={WB_ADAPT_CH:0,WB_FHSS:0,WB_FHSS_SLOT:25,FHSS_VIA_RC:0};_ohdSystemAirSettingsModel.update_count++
   _ohdSystemGroundSettings.values={WB_FHSS:0,WB_FHSS_SLOT:25};_ohdSystemGroundSettings.update_count++
   compare(air.parameterIds.join(","),"FHSS_VIA_RC,WB_ADAPT_CH,WB_FHSS,WB_FHSS_SLOT")
   compare(ground.parameterIds.join(","),"WB_FHSS,WB_FHSS_SLOT")
   settings_form.showDeveloperSettings=false
   compare(air.parameterIds.length,0);compare(ground.parameterIds.length,0)
  }
  function test_sbus_settings_are_developer_only(){
   var air=findChild(page,"debugAirPage")
   _ohdSystemAirSettingsModel.values={SBUS_EN:0,SBUS_DEV:"UART3",SBUS_HZ:50};_ohdSystemAirSettingsModel.update_count++
   compare(air.parameterIds.join(","),"SBUS_DEV,SBUS_EN,SBUS_HZ")
   settings_form.showDeveloperSettings=false;compare(air.parameterIds.length,0)
  }
  function test_air_ground_uart_link_is_developer_only(){
   var air=findChild(page,"debugAirPage"),ground=findChild(page,"debugGroundPage")
   var values={OHD_UART_EN:0,OHD_UART_TLM:"UART2",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
   _ohdSystemAirSettingsModel.values=values;_ohdSystemAirSettingsModel.update_count++
   _ohdSystemGroundSettings.values=values;_ohdSystemGroundSettings.update_count++
   compare(air.parameterIds.length,7);compare(ground.parameterIds.length,7)
   settings_form.showDeveloperSettings=false;settings_form.showAdvancedSettings=true
   compare(air.parameterIds.length,0);compare(ground.parameterIds.length,0)
  }
 }
}
