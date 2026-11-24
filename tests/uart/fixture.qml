import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
Item {
 id:scene;width:1200;height:850
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool compactSidebar:false;property color pageBackground:"#091827";function side_bar_regain_focus(){}property bool showAdvancedSettings:false;property bool showDeveloperSettings:false;property color errorColor:"#ff4e5d";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
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
         function string_param_has_enum(id){return id === "TRACKER_UART_OUT"}
         function string_param_get_enum_keys(id){return ["/dev/ttyUSB0","/dev/ttyUSB1"]}
         function string_param_get_enum_values(id){return string_param_get_enum_keys(id)}
         function ensure_parameters_available(){}
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
 Component {id:page;Pages.PortsSettingsPanel {anchors.fill:parent}}
 Loader {id:loader;anchors.fill:parent;sourceComponent:page}
 Rectangle {anchors.fill:parent;color:"#091827";z:-1}
 TestCase {
     name:"PortsSettings";when:windowShown
     function row(group,id){return findChild(loader.item,"portSetting_"+group+"_"+id)}
     function init(){
         loader.active=false;settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false;_qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=true;_ohdSystemGround.is_alive=true
         _ohdSystemAirSettingsModel.values={FC_UART_CONN:"/dev/ttyS1",FC_UART_BAUD:921600,FC_UART_FLWCTL:0,SBUS_EN:0,SBUS_DEV:"/dev/ttyS2",SBUS_HZ:50,GPIO_2:0,GPIO_26:0,OHD_UART_EN:0,OHD_UART_TLM:"/dev/ttyUSB0",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
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
     function test_roles_write_to_the_selected_unit(){
         row("fc","FC_UART_BAUD").commitChoice(115200)
         compare(_ohdSystemAirSettingsModel.lastId,"FC_UART_BAUD")
         row("airLink","OHD_UART_EN").commitToggle(true)
         row("groundLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,1)
         compare(_ohdSystemGroundSettings.values.OHD_UART_EN,1)
         row("gpio","GPIO_26").commitChoice(2)
         compare(_ohdSystemAirSettingsModel.lastId,"GPIO_26")
         compare(_ohdSystemAirSettingsModel.values.GPIO_26,2)
     }
     function test_advertised_port_choices_use_validation(){
         _ohdSystemGroundSettings.values.OHD_UART_EN=1
         _ohdSystemGroundSettings.update_count++
         var tracker=row("tracker","TRACKER_UART_OUT")
         var editor=findChild(tracker,"portChoiceEditor")
         compare(tracker.choices.map(function(entry){return entry.value}),
                 ["","DEFAULT","/dev/ttyUSB0","/dev/ttyUSB1",null])
         editor.activated(2)
         compare(_ohdSystemGroundSettings.writes,0)
         compare(editor.currentIndex,0)
         verify(loader.item.validationError.length>0)
         editor.activated(3)
         compare(_ohdSystemGroundSettings.lastValue,"/dev/ttyUSB1")
         compare(editor.currentIndex,3)
     }
     function test_air_conflicts_and_missing_port(){
         row("sbus","SBUS_DEV").commitChoice("/dev//ttyS1")
         row("sbus","SBUS_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.SBUS_EN,0)
         row("airLink","OHD_UART_TLM").commitChoice("")
         row("airLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,0)
         row("airLink","OHD_UART_TLM").commitChoice("DEFAULT")
         row("fc","FC_UART_CONN").commitChoice("DEFAULT")
         row("airLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,1)
     }
     function test_only_reported_pins_are_editable(){
         delete _ohdSystemAirSettingsModel.values.GPIO_26
         _ohdSystemAirSettingsModel.update_count++
         compare(row("gpio","GPIO_26"),null)
         verify(row("gpio","GPIO_2") !== null)
     }
     function test_preview(){
         _qopenhd.debugMenuPreview=true;row("tracker","TRACKER_UART_OUT").commitChoice("DEFAULT");compare(_ohdSystemGroundSettings.writes,0)
     }
     function test_layout(){
         for(var i=0;i<3;i++){
             scene.width=[1200,760,440][i];wait(50)
             var r=row("tracker","TRACK_UART_BAUD");verify(r.width>200)
             compare(r.stacked, r.width < 300)
         }
     }

 }
}
