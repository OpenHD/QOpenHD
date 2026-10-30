import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
Item {
 id:scene;width:1200;height:850
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool showAdvancedSettings:false;property bool showDeveloperSettings:false;property color errorColor:"#ff4e5d";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true}
 QtObject {id:_ohdSystemGround;property bool is_alive:true}
 QtObject {id:_messageBoxInstance;function set_text_and_show(message){}}
 Component {
     id:paramModel
     QtObject {
         property int update_count:0
         property bool ui_is_busy:false
         property var values:({})
         property int writes:0
         property string lastId:""
         property var lastValue:""
         function param_int_exists(id){return typeof values[id]==="number"}
         function param_string_exists(id){return typeof values[id]==="string"}
         function get_cached_int(id){return values[id]}
         function get_cached_string(id){return values[id]}
         function get_ui_metadata(id){return {label:id,description:"",readOnly:false}}
         function string_param_has_enum(id){return false}
         function int_param_has_enum_keys_values(id){return id.indexOf("BAUD")>=0}
         function int_param_get_enum_keys(id){return ["9600","115200","921600"]}
         function int_param_get_enum_values(id){return [9600,115200,921600]}
         function int_param_has_min_max(id){return false}
         function get_warning_before_safe(id){return ""}
         function try_set_param_int_async(id,value,log){values[id]=value;lastId=id;lastValue=value;writes++;update_count++}
         function try_set_param_string_async(id,value,log){values[id]=value;lastId=id;lastValue=value;writes++;update_count++}
     }
 }
 property var _ohdSystemAirSettingsModel:paramModel.createObject(scene)
 property var _ohdSystemGroundSettings:paramModel.createObject(scene)
 Component {id:page;Pages.UartSettingsPanel {anchors.fill:parent}}
 Loader {id:loader;anchors.fill:parent;sourceComponent:page}
 Rectangle {anchors.fill:parent;color:"#091827";z:-1}
 TestCase {
     name:"UartSettings";when:windowShown
     function row(group,id){return findChild(loader.item,"uartSetting_"+group+"_"+id)}
     function init(){
         loader.active=false;settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false;_qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=true;_ohdSystemGround.is_alive=true
         _ohdSystemAirSettingsModel.values={FC_UART_CONN:"/dev/ttyS1",FC_UART_BAUD:921600,FC_UART_FLWCTL:0,OHD_UART_EN:0,OHD_UART_TLM:"/dev/ttyUSB0",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
         _ohdSystemGroundSettings.values={TRACKER_UART_OUT:"",TRACK_UART_BAUD:9600,TRACK_UART_FLOW:0,OHD_UART_EN:0,OHD_UART_TLM:"/dev/ttyUSB0",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
         _ohdSystemAirSettingsModel.writes=0;_ohdSystemGroundSettings.writes=0
         _ohdSystemAirSettingsModel.update_count++;_ohdSystemGroundSettings.update_count++
         loader.active=true;tryCompare(loader,"status",Loader.Ready);wait(50)
     }
     function test_tracker_routes_to_ground(){
         row("tracker","TRACKER_UART_OUT").commitChoice("/dev/ttyUSB1")
         compare(_ohdSystemGroundSettings.lastId,"TRACKER_UART_OUT");compare(_ohdSystemAirSettingsModel.writes,0)
         row("tracker","TRACK_UART_FLOW").commitToggle(true);compare(_ohdSystemGroundSettings.lastValue,1)
     }
     function test_ground_independent_of_air(){
         _ohdSystemAir.is_alive=false;verify(!row("tracker","TRACK_UART_BAUD").busy)
         row("tracker","TRACK_UART_BAUD").commitChoice(115200);compare(_ohdSystemGroundSettings.lastValue,115200)
         _ohdSystemGround.is_alive=false;row("tracker","TRACK_UART_BAUD").commitChoice(9600);compare(_ohdSystemGroundSettings.writes,1)
     }
     function test_link_only_lives_in_debug(){
         for(var mode=0;mode<3;mode++){
             settings_form.showAdvancedSettings=mode>0;settings_form.showDeveloperSettings=mode===2
             compare(findChild(loader.item,"uartSection_airLink"),null)
             compare(findChild(loader.item,"uartSection_groundLink"),null)
         }
     }
     function test_port_conflicts(){
         _ohdSystemGroundSettings.values.OHD_UART_EN=1;_ohdSystemGroundSettings.update_count++
         row("tracker","TRACKER_UART_OUT").commitChoice("/dev/ttyUSB0")
         compare(_ohdSystemGroundSettings.writes,0);verify(loader.item.validationError.length>0)
     }
     function test_preview(){
         _qopenhd.debugMenuPreview=true;row("tracker","TRACKER_UART_OUT").commitChoice("DEFAULT");compare(_ohdSystemGroundSettings.writes,0)
     }
     function test_layout(){
         for(var i=0;i<3;i++){
             scene.width=[1200,760,440][i];wait(50)
             var r=row("tracker","TRACK_UART_BAUD");verify(r.width>200)
         }
     }

 }
}
