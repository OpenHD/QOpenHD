import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
import "../../qml/ui/configpopup/features/JoystickMapping.js" as Mapping
Item {
 id:scene;width:1200;height:800
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 ListModel {id:_rcchannelsmodelfc;property bool is_alive:true;ListElement {curr_value:1200} ListElement {curr_value:1800}}
 QtObject {id:_fcMavlinkSystem;property bool armed:false}
 QtObject {
     id:_ohdSystemGroundSettings
     property int update_count:0
     property bool connected:true
     property bool modern:true
     property string saved:"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"
     property int enabledValue:0
     property int monitorValue:0
     property string lastId:""
     property var lastValue:0
     property string error:""
     function system_is_alive(){return connected}
     function param_string_exists(id){return id==="RC_CHAN_MAP"}
     function get_cached_string(id){return saved}
     function param_int_exists(id){return id==="ENABLE_JOY_RC"||(modern&&(id==="JOY_MAP_V2"||id==="JOY_MONITOR"))}
     function get_cached_int(id){return id==="ENABLE_JOY_RC"?enabledValue:id==="JOY_MONITOR"?monitorValue:1}
     function try_update_parameter_int(id,value){lastId=id;lastValue=value;if(error)return error;if(id==="ENABLE_JOY_RC")enabledValue=value;else monitorValue=value;update_count++;return ""}
     function try_update_parameter_string(id,value){lastId=id;lastValue=value;if(error)return error;saved=value;update_count++;return ""}
 }
 QtObject {
     id:_ohdSystemAirSettingsModel
     property int update_count:0
     property int base:0
     property int enabledValue:0
     function system_is_alive(){return true}
     function param_int_exists(id){return true}
     function get_cached_int(id){return id==="RC_SET_BASE"?base:enabledValue}
     function try_update_parameter_int(id,value){if(id==="RC_SET_BASE")base=value;else enabledValue=value;update_count++;return ""}
 }
 QtObject {id:_joystickInputModel;property bool is_alive:true;property var values:[1500,1500,1000,1500,65535,65535,65535,65535,2000,65535,65535,65535,65535,65535,65535,65535,65535,65535];function channelValues(){return values.slice()}}
 Rectangle {anchors.fill:parent;color:"#091827"}
 Component {id:page;Pages.JoystickSettingsPanel {anchors.fill:parent}}
 Loader {id:loader;anchors.fill:parent;sourceComponent:page}
 TestCase {
     name:"JoystickSettings";when:windowShown
     function init(){loader.active=false;_fcMavlinkSystem.armed=false;_ohdSystemGroundSettings.connected=true;_ohdSystemGroundSettings.modern=true;_ohdSystemGroundSettings.enabledValue=0;_ohdSystemGroundSettings.error="";_ohdSystemGroundSettings.saved="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18";_ohdSystemGroundSettings.update_count++;_ohdSystemAirSettingsModel.base=0;_ohdSystemAirSettingsModel.update_count++;loader.active=true;tryCompare(loader,"status",Loader.Ready);wait(50)}
     function test_mapping_and_free_channels(){
         var m=Mapping.parse(_ohdSystemGroundSettings.saved);compare(m.length,18)
         m=Mapping.assign(m,3,3);compare(m[2],0);compare(m[3],3)
         m=Mapping.assign(m,6,5);compare(m[4],0);compare(m[6],5)
         for(var i=8;i<18;i++)m[i]=0
         compare(Mapping.freeBlocks(m)[0],9)
         compare(Mapping.parse("1,2,3").length,0)
         compare(Mapping.parse("1,,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18").length,0)
     }
     function test_all_input_output_pairs(){
         var identity=Mapping.parse(_ohdSystemGroundSettings.saved)
         for(var input=1;input<=18;input++)for(var output=0;output<18;output++){
             var m=Mapping.assign(identity,output,input)
             compare(m[output],input)
             for(var j=0;j<18;j++)if(j!==output)compare(m[j],j===input-1?0:identity[j])
             compare(Mapping.parse(m.join(",")).length,18)
         }
         for(var input=0;input<18;input++) {
             var base=[],moved=[];for(var j=0;j<18;j++){base.push(1500);moved.push(j===input?2000:1500)}
             compare(Mapping.movedInput(base,moved),input)
         }
         var empty=identity.slice();for(var i=0;i<18;i++)empty=Mapping.assign(empty,i,0)
         compare(Mapping.freeBlocks(empty).length,11)
         compare(Mapping.freeBlocks(identity).length,0)
         compare(Mapping.movedInput([1000,1000],[1500,1500]),-1)
         compare(Mapping.movedInput([1000,1000],[1500,1000]),0)
     }
     function test_live_learning_and_persistence(){
         var p=loader.item;p.monitor();compare(_ohdSystemGroundSettings.monitorValue,1);compare(_ohdSystemGroundSettings.enabledValue,0)
         p.learn(3);var v=_joystickInputModel.values.slice();v[2]=1800;_joystickInputModel.values=v
         tryCompare(p,"learning",-1);compare(p.mapping[3],3);compare(p.mapping[2],0);verify(p.dirty)
         p.save();compare(_ohdSystemGroundSettings.lastId,"RC_CHAN_MAP");compare(Mapping.parse(_ohdSystemGroundSettings.saved)[3],3);verify(!p.dirty)
         p.visible=false;compare(_ohdSystemGroundSettings.monitorValue,0);compare(_ohdSystemGroundSettings.enabledValue,0)
     }
     function test_selector_uses_output_not_choice_index(){
         var p=loader.item;var combo=findChild(p,"joystickSource4");combo.currentIndex=3;combo.activated(3)
         compare(p.mapping[3],3);compare(p.mapping[2],0)
     }
     function test_errors_and_access(){
         var p=loader.item;p.assign(3,3);_ohdSystemGroundSettings.error="Rejected";p.save();verify(p.dirty);compare(p.message,"Rejected")
         _fcMavlinkSystem.armed=true;verify(!findChild(p,"joystickSave").enabled);_ohdSystemGroundSettings.lastId="";p.monitor();compare(_ohdSystemGroundSettings.lastId,"")
         _fcMavlinkSystem.armed=false;_ohdSystemGroundSettings.connected=false;_ohdSystemGroundSettings.update_count++;verify(!p.available)
     }
     function test_legacy_and_lua_helper(){
         var p=loader.item;_ohdSystemGroundSettings.modern=false;_ohdSystemGroundSettings.update_count++;verify(!p.modern);p.assign(3,3);compare(p.mapping[2],3)
         _ohdSystemGroundSettings.modern=true;_ohdSystemGroundSettings.update_count++
         var m=p.mapping.slice();for(var i=8;i<18;i++)m[i]=0;p.mapping=m;p.save()
         var free=findChild(p,"joystickLuaFree");verify(free.enabled);free.clicked();compare(_ohdSystemAirSettingsModel.base,9)
         p.assign(8,1);verify(!free.enabled)
     }
     function test_fc_channels_preserved(){
         verify(findChild(loader.item,"joystickFcChannels")!==null)
         var row=findChild(loader.item,"joystickFcChannel2");verify(row!==null)
         _rcchannelsmodelfc.setProperty(1,"curr_value",1900)
         wait(30);verify(row.height>=38)
     }
     function test_layout(){
         for(var i=0;i<3;i++){
             scene.width=[1200,750,440][i];wait(100)
             var toggle=findChild(loader.item,"joystickTransmit");verify(toggle.width>=40,"toggle width="+toggle.width);verify(toggle.height>=24,"toggle height="+toggle.height);var point=toggle.mapToItem(scene,0,0);verify(point.x+toggle.width<=scene.width,"toggle x="+point.x+" width="+toggle.width+" screen="+scene.width);
             var row=findChild(loader.item,"joystickChannel1");verify(row.width>200);verify(row.height>=120)
             grabImage(scene).save("build/joystick-"+scene.width+".png")
         }
     }
 }
}
