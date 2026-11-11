import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
import "../../qml/ui/configpopup/features/JoystickMapping.js" as Mapping
import "../../qml/ui/configpopup/features/RcRanges.js" as Ranges
Item {
 id:scene;width:1200;height:800
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool compactSidebar:true;property color pageBackground:"#091827";property int backCalls:0;function side_bar_regain_focus(){backCalls++} property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 ListModel {id:_rcchannelsmodelfc;property bool is_alive:true;function channelValues(){var a=[];for(var i=0;i<18;i++)a.push(i<count?get(i).curr_value:1500);return a} ListElement {curr_value:1200} ListElement {curr_value:1800} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500} ListElement {curr_value:1500}}
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
     property bool connected:true
     property bool radioSupported:true
     property bool rangesSupported:true
     property var profiles: ({RC_BW_RANGES:"1500:20,2100:40",RC_MCS_RANGES:"1300:0,1700:2,2100:3"})
     property string error:""
     property string rejectId:""
     property var assignments: ({BW_VIA_RC:3,MCS_VIA_RC:8,TXMODE_VIA_RC:0,FHSS_VIA_RC:0})
     property var writes: []
     property int base:0
     property int enabledValue:0
     function system_is_alive(){return connected}
     function param_int_exists(id){return assignments[id]!==undefined?radioSupported:true}
     function param_string_exists(id){return rangesSupported && profiles[id]!==undefined}
     function get_cached_string(id){return profiles[id] || ""}
     function try_update_parameter_string(id,value){if(error)return error;if(id===rejectId)return "Rejected";var log=writes.slice();log.push({id:id,value:value});writes=log;var next=Object.assign({},profiles);next[id]=value;profiles=next;update_count++;return ""}
     function get_cached_int(id){return assignments[id]!==undefined?assignments[id]:id==="RC_SET_BASE"?base:enabledValue}
     function try_update_parameter_int(id,value){if(error)return error;if(id===rejectId)return "Rejected";var log=writes.slice();log.push({id:id,value:value});writes=log;if(assignments[id]!==undefined){var next=Object.assign({},assignments);next[id]=value;assignments=next}else if(id==="RC_SET_BASE")base=value;else enabledValue=value;update_count++;return ""}
 }
 QtObject {id:_joystickInputModel;property bool is_alive:true;property var values:[1500,1500,1000,1500,65535,65535,65535,65535,2000,65535,65535,65535,65535,65535,65535,65535,65535,65535];function channelValues(){return values.slice()}}
 Rectangle {anchors.fill:parent;color:"#091827"}
 Component {id:standalonePage;Pages.JoystickPage {width:1200;height:800}}
 Component {id:page;Pages.JoystickSettingsPanel {anchors.fill:parent}}
 Loader {id:loader;anchors.fill:parent;sourceComponent:page}
 TestCase {
     name:"JoystickSettings";when:windowShown
     function init(){_ohdSystemGroundSettings.lastId="";loader.active=false;_fcMavlinkSystem.armed=false;_ohdSystemGroundSettings.connected=true;_ohdSystemGroundSettings.modern=true;_ohdSystemGroundSettings.enabledValue=0;_ohdSystemGroundSettings.error="";_ohdSystemGroundSettings.saved="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18";_ohdSystemGroundSettings.update_count++;_rcchannelsmodelfc.is_alive=true;_rcchannelsmodelfc.setProperty(2,"curr_value",1500);_ohdSystemAirSettingsModel.connected=true;_ohdSystemAirSettingsModel.radioSupported=true;_ohdSystemAirSettingsModel.rangesSupported=true;_ohdSystemAirSettingsModel.profiles={RC_BW_RANGES:"1500:20,2100:40",RC_MCS_RANGES:"1300:0,1700:2,2100:3"};_ohdSystemAirSettingsModel.error="";_ohdSystemAirSettingsModel.rejectId="";_ohdSystemAirSettingsModel.assignments={BW_VIA_RC:3,MCS_VIA_RC:8,TXMODE_VIA_RC:0,FHSS_VIA_RC:0};_ohdSystemAirSettingsModel.writes=[];_ohdSystemAirSettingsModel.base=0;_ohdSystemAirSettingsModel.update_count++;loader.active=true;tryCompare(loader,"status",Loader.Ready);wait(50)}
     function test_standalone_page_focus_and_back(){
         var page = standalonePage.createObject(scene)
         verify(page !== null)
         verify(findChild(page, "joystickSettingsPanel") !== null)
         page.gainFocus()
         verify(findChild(page, "joystickSettingsPanel").activeFocus)
         var previous = settings_form.backCalls
         keyClick(Qt.Key_Escape)
         compare(settings_form.backCalls, previous + 1)
         page.destroy()
     }
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
         var p=loader.item;_ohdSystemGroundSettings.enabledValue=1;_ohdSystemGroundSettings.update_count++;wait(30);compare(_ohdSystemGroundSettings.monitorValue,1);compare(_ohdSystemGroundSettings.enabledValue,1)
         p.learn(3);var v=_joystickInputModel.values.slice();v[2]=1800;_joystickInputModel.values=v
         tryCompare(p,"learning",-1);compare(p.mapping[3],3);compare(p.mapping[2],0);verify(p.dirty)
         p.save();compare(_ohdSystemGroundSettings.lastId,"RC_CHAN_MAP");compare(Mapping.parse(_ohdSystemGroundSettings.saved)[3],3);verify(!p.dirty)
         p.visible=false;compare(_ohdSystemGroundSettings.monitorValue,0);compare(_ohdSystemGroundSettings.enabledValue,1)
     }
     function test_automatic_reading(){
         var p=loader.item;compare(findChild(p,"joystickMonitor"),null);verify(!p.monitoring)
         _ohdSystemGroundSettings.enabledValue=1;_ohdSystemGroundSettings.update_count++
         verify(p.monitoring);tryCompare(_ohdSystemGroundSettings,"monitorValue",1)
         tryCompare(p,"values",_joystickInputModel.values)
         _joystickInputModel.is_alive=false;verify(!p.monitoring)
         _joystickInputModel.is_alive=true;verify(p.monitoring)
         _ohdSystemGroundSettings.enabledValue=0;_ohdSystemGroundSettings.update_count++
         verify(!p.monitoring);tryCompare(p,"values",[]);tryCompare(_ohdSystemGroundSettings,"monitorValue",0)
     }
     function openEditor(channel){
         findChild(loader.item,"joystickChannel"+channel).clicked()
         var editor=findChild(loader.item,"channelEditor")
         tryCompare(editor,"opened",true)
         return editor
     }
     function chooseFunction(editor, index) {
         var picker=findChild(editor.contentItem,"channelFunctionPicker")
         for(var i=0;i<picker.model.length;i++) {
             if(picker.model[i].actionIndex!==index)continue
             picker.currentIndex=i;picker.activated(i)
             compare(editor.selectedAction,index)
             return
         }
         fail("Function missing from picker: "+index)
     }
     function test_channel_functions_apply_and_cancel(){
         var editor=openEditor(6)
         chooseFunction(editor,0)
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,3)
         editor.close();tryCompare(editor,"opened",false)
         editor=openEditor(6)
         compare(editor.selected[0],false)
         chooseFunction(editor,0);editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,6)
         compare(_ohdSystemAirSettingsModel.writes.length,1)
         tryCompare(editor,"opened",false)
         editor=openEditor(6);chooseFunction(editor,-1);editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,0)
         compare(_ohdSystemAirSettingsModel.assignments.MCS_VIA_RC,8)
     }
     function test_channel_functions_rejected_stale_and_armed(){
         var editor=openEditor(6)
         chooseFunction(editor,0)
         _fcMavlinkSystem.armed=true;editor.apply()
         compare(_ohdSystemAirSettingsModel.writes.length,0);verify(editor.opened)
         _fcMavlinkSystem.armed=false;_ohdSystemAirSettingsModel.error="Rejected";editor.apply()
         compare(editor.error,"Rejected");verify(editor.opened)
         _ohdSystemAirSettingsModel.error="";_ohdSystemAirSettingsModel.try_update_parameter_int("BW_VIA_RC",9)
         editor.apply();verify(editor.error.indexOf("changed")>=0)
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,9)
     }
     function test_channel_ranges_follow_fc_pwm(){
         var editor=openEditor(3), segment=findChild(editor.contentItem,"channelRange0_0")
         verify(segment.activeRange)
         _rcchannelsmodelfc.setProperty(2,"curr_value",1800)
         tryCompare(segment,"activeRange",false)
         verify(findChild(editor.contentItem,"channelRange0_1").activeRange)
         _rcchannelsmodelfc.is_alive=false
         tryCompare(findChild(editor.contentItem,"channelRange0_1"),"activeRange",false)
         _rcchannelsmodelfc.is_alive=true
     }
     function setAreaValue(editor, action, area, value) {
         findChild(editor.contentItem,"channelRangeEditor"+action).selectedArea=area
         var combo=findChild(editor.contentItem,"rangeValue"+action)
         for(var i=0;i<combo.model.length;i++) if(combo.model[i].value===value) {
             combo.currentIndex=i;combo.activated(i);return
         }
         fail("Missing range value")
     }
     function test_editable_bandwidth_areas_apply_and_cancel(){
         var editor=openEditor(3)
         compare(Ranges.encode(editor.ranges[0]),"1500:20,2100:40")
         findChild(editor.contentItem,"rangeAdd0").clicked()
         compare(editor.ranges[0].length,3)
         setAreaValue(editor,0,0,10);setAreaValue(editor,0,1,20)
         var rangeEditor=findChild(editor.contentItem,"channelRangeEditor0")
         rangeEditor.selectedArea=0
         var boundary=findChild(editor.contentItem,"rangeBoundary0")
         boundary.value=1300;boundary.valueModified()
         rangeEditor.selectedArea=1;boundary.value=1700;boundary.valueModified()
         compare(Ranges.encode(editor.ranges[0]),"1300:10,1700:20,2100:40")
         compare(_ohdSystemAirSettingsModel.profiles.RC_BW_RANGES,"1500:20,2100:40")
         editor.close();tryCompare(editor,"opened",false)
         editor=openEditor(3)
         compare(editor.ranges[0].length,2)
         editor.editRanges(0,Ranges.parse("1300:10,1700:20,2100:40"));editor.apply()
         compare(_ohdSystemAirSettingsModel.profiles.RC_BW_RANGES,"1300:10,1700:20,2100:40")
         editor=openEditor(3)
         compare(editor.ranges[0].length,3)
         findChild(editor.contentItem,"rangeReset0").clicked();editor.apply()
         compare(_ohdSystemAirSettingsModel.profiles.RC_BW_RANGES,"1500:20,2100:40")
     }
     function test_custom_mcs_values_and_five_areas(){
         var editor=openEditor(8)
         compare(Ranges.encode(editor.ranges[1]),"1300:0,1700:2,2100:3")
         setAreaValue(editor,1,0,1);setAreaValue(editor,1,1,3);setAreaValue(editor,1,2,4)
         editor.apply()
         compare(_ohdSystemAirSettingsModel.profiles.RC_MCS_RANGES,"1300:1,1700:3,2100:4")
         editor=openEditor(8)
         var add=findChild(editor.contentItem,"rangeAdd1")
         add.clicked();add.clicked()
         compare(editor.ranges[1].length,5);verify(!add.enabled)
         for(var i=0;i<5;i++)setAreaValue(editor,1,i,i)
         var expected=Ranges.encode(editor.ranges[1]);editor.apply()
         compare(_ohdSystemAirSettingsModel.profiles.RC_MCS_RANGES,expected)
         editor=openEditor(8)
         for(var j=0;j<4;j++)findChild(editor.contentItem,"rangeRemove1").clicked()
         compare(editor.ranges[1].length,1);compare(editor.ranges[1][0].upper,2100)
         verify(!findChild(editor.contentItem,"rangeRemove1").enabled)
         editor.apply()
         verify(_ohdSystemAirSettingsModel.profiles.RC_MCS_RANGES.indexOf("2100:")===0)
     }
     function test_custom_ranges_rejected_stale_and_disconnected(){
         var editor=openEditor(6);chooseFunction(editor,0)
         editor.editRanges(0,Ranges.parse("1300:10,1700:20,2100:40"))
         _ohdSystemAirSettingsModel.error="Rejected";editor.apply()
         compare(editor.error,"Rejected");compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,3)
         compare(_ohdSystemAirSettingsModel.profiles.RC_BW_RANGES,"1500:20,2100:40")
         _ohdSystemAirSettingsModel.error="";_ohdSystemAirSettingsModel.connected=false;_ohdSystemAirSettingsModel.update_count++
         editor.apply();compare(_ohdSystemAirSettingsModel.writes.length,0)
         editor.close();tryCompare(editor,"opened",false)
         _ohdSystemAirSettingsModel.connected=true;_ohdSystemAirSettingsModel.update_count++
         editor=openEditor(3)
         _ohdSystemAirSettingsModel.try_update_parameter_string("RC_BW_RANGES","1300:10,1700:20,2100:40")
         editor.apply();verify(editor.error.indexOf("changed")>=0)
     }
     function test_custom_ranges_partial_save_can_retry(){
         var editor=openEditor(6);chooseFunction(editor,0)
         editor.editRanges(0,Ranges.parse("1300:10,1700:20,2100:40"))
         _ohdSystemAirSettingsModel.rejectId="BW_VIA_RC";editor.apply()
         verify(editor.opened);verify(editor.savedChanges);compare(editor.error,"Rejected")
         compare(_ohdSystemAirSettingsModel.profiles.RC_BW_RANGES,"1300:10,1700:20,2100:40")
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,3)
         _ohdSystemAirSettingsModel.rejectId="";editor.apply()
         tryCompare(editor,"opened",false)
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,6)
         compare(_ohdSystemAirSettingsModel.writes.length,2)
     }
     function test_custom_ranges_live_preview_and_armed_guard(){
         var editor=openEditor(3)
         editor.editRanges(0,Ranges.parse("1300:40,1700:10,2100:20"))
         _rcchannelsmodelfc.setProperty(2,"curr_value",1300)
         tryCompare(findChild(editor.contentItem,"channelRange0_0"),"activeRange",true)
         verify(!findChild(editor.contentItem,"channelRange0_1").activeRange)
         _rcchannelsmodelfc.setProperty(2,"curr_value",1301)
         tryCompare(findChild(editor.contentItem,"channelRange0_1"),"activeRange",true)
         verify(!findChild(editor.contentItem,"channelRange0_0").activeRange)
         _fcMavlinkSystem.armed=true
         editor.editRanges(0,Ranges.parse("1500:20,2100:40"))
         compare(editor.ranges[0].length,3)
         editor.apply();compare(_ohdSystemAirSettingsModel.writes.length,0)
         verify(!findChild(editor.contentItem,"channelRangeEditor0").editable)
     }
     function test_old_firmware_ranges_remain_read_only(){
         _ohdSystemAirSettingsModel.rangesSupported=false;_ohdSystemAirSettingsModel.update_count++
         var editor=openEditor(3), rangeEditor=findChild(editor.contentItem,"channelRangeEditor0")
         verify(!rangeEditor.editable)
         compare(Ranges.encode(editor.ranges[0]),"1300:10,1700:20,2100:40")
         editor.editRanges(0,Ranges.parse("1500:20,2100:40"))
         compare(editor.ranges[0].length,3)
         editor.apply();compare(_ohdSystemAirSettingsModel.writes.length,0)
     }
     function test_range_boundaries_and_validation(){
         var ranges=Ranges.parse("1300:0,1700:2,2100:3")
         compare(Ranges.setBoundary(ranges,0,2000)[0].upper,1699)
         compare(Ranges.setBoundary(ranges,1,1000)[1].upper,1301)
         compare(Ranges.setBoundary(ranges,2,1800)[2].upper,2100)
         compare(Ranges.remove(ranges,2)[1].upper,2100)
         verify(Ranges.valid(ranges,[0,1,2,3,4]))
         verify(!Ranges.valid([{upper:1700,value:0},{upper:1300,value:2},{upper:2100,value:3}],[0,1,2,3,4]))
         verify(!Ranges.valid([{upper:2100,value:5}],[0,1,2,3,4]))
         compare(Ranges.parse("1500:20,2100:40,").length,0)
         compare(Ranges.parse("2100:20x").length,0)
         var editor=openEditor(3)
         editor.editRanges(0,[{upper:2100,value:80}]);editor.apply()
         verify(editor.opened);verify(editor.error.indexOf("Invalid")>=0)
         compare(_ohdSystemAirSettingsModel.writes.length,0)
     }
     function test_channel_functions_disconnect(){
         var editor=openEditor(6)
         chooseFunction(editor,0)
         _ohdSystemAirSettingsModel.connected=false;_ohdSystemAirSettingsModel.update_count++
         editor.apply();verify(editor.opened);compare(_ohdSystemAirSettingsModel.writes.length,0)
         verify(!findChild(editor.contentItem,"channelFunctionPicker").enabled)
     }
     function test_channel_popup_layout(){
         scene.width=1200;scene.height=800
         var editor=openEditor(3)
         wait(100);grabImage(scene).save("build/joystick-popup-1200.png")
         scene.width=440;wait(100)
         verify(editor.width<=scene.width);grabImage(scene).save("build/joystick-popup-440.png")
         var apply=findChild(editor.contentItem,"channelApply")
         var scroll=findChild(editor.contentItem,"channelEditorScroll")
         verify(scroll.height>0)
         verify(apply.mapToItem(scene,0,0).y>editor.y+editor.height-100)
         chooseFunction(editor,1)
         scene.height=480;wait(100)
         verify(editor.height<=scene.height)
         verify(scroll.contentHeight>scroll.height)
         var point=apply.mapToItem(scene,0,0)
         verify(point.y+apply.height<=scene.height)
         verify(point.y>scene.height-100)
         scroll.contentY=scroll.contentHeight-scroll.height
         wait(100);grabImage(scene).save("build/joystick-popup-short.png")
         scene.height=800
         editor.close();scene.width=1200
     }
     function test_errors_and_access(){
         var p=loader.item;p.assign(3,3);_ohdSystemGroundSettings.error="Rejected";p.save();verify(p.dirty);compare(p.message,"Rejected")
         _fcMavlinkSystem.armed=true;verify(!findChild(p,"joystickSave").enabled);_ohdSystemGroundSettings.lastId="";p.save();compare(_ohdSystemGroundSettings.lastId,"")
         _fcMavlinkSystem.armed=false;_ohdSystemGroundSettings.connected=false;_ohdSystemGroundSettings.update_count++;verify(!p.available)
     }
     function test_transmit_uses_enable_joy_rc_and_tracks_rejections(){
         var p=loader.item,toggle=findChild(p,"joystickTransmit")
         _ohdSystemGroundSettings.enabledValue=1;_ohdSystemGroundSettings.update_count++
         verify(p.transmitting);verify(toggle.checked)
         toggle.checked=false;toggle.toggled()
         compare(_ohdSystemGroundSettings.enabledValue,0)
         _ohdSystemGroundSettings.error="Rejected"
         toggle.checked=true;toggle.toggled()
         compare(_ohdSystemGroundSettings.enabledValue,0);compare(toggle.checked,false)
         _ohdSystemGroundSettings.error="";_ohdSystemGroundSettings.enabledValue=1;_ohdSystemGroundSettings.update_count++
         compare(toggle.checked,true)
     }
     function test_legacy_and_lua_helper(){
         var p=loader.item;_ohdSystemGroundSettings.modern=false;_ohdSystemGroundSettings.update_count++;verify(!p.modern);p.assign(3,3);compare(p.mapping[2],3)
         _ohdSystemGroundSettings.modern=true;_ohdSystemGroundSettings.update_count++
         var m=p.mapping.slice();for(var i=8;i<18;i++)m[i]=0;p.mapping=m;p.save()
         var free=findChild(p,"joystickLuaFree");verify(free.enabled);free.clicked();compare(_ohdSystemAirSettingsModel.base,9)
         p.assign(8,1);verify(!free.enabled)
     }
     function test_overview_replaces_old_live_view(){
         compare(findChild(loader.item,"joystickFcChannels"),null)
         var overview=findChild(loader.item,"joystickChannelOverview")
         verify(findChild(loader.item,"joystickControls").y>overview.y+overview.height)
         _rcchannelsmodelfc.setProperty(1,"curr_value",1900)
         tryCompare(findChild(loader.item,"joystickChannel2"),"value",1900)
     }
     function test_single_dropdown_replaces_function(){
         var editor=openEditor(6)
         chooseFunction(editor,0);chooseFunction(editor,1)
         verify(!editor.selected[0]);verify(editor.selected[1])
         editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,3)
         compare(_ohdSystemAirSettingsModel.assignments.MCS_VIA_RC,6)
         editor=openEditor(6)
         chooseFunction(editor,0);editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,6)
         compare(_ohdSystemAirSettingsModel.assignments.MCS_VIA_RC,0)
         var writes=_ohdSystemAirSettingsModel.writes
         compare(writes[writes.length-2].id,"MCS_VIA_RC")
         compare(writes[writes.length-2].value,0)
         editor=openEditor(6);chooseFunction(editor,-1);editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,0)
     }
     function test_channel_popup_only_reads_fc_channel(){
         var before=loader.item.mapping.join(","), editor=openEditor(4)
         compare(findChild(editor.contentItem,"channelInput"),null)
         compare(findChild(editor.contentItem,"channelDetectInput"),null)
         chooseFunction(editor,2);editor.apply()
         compare(_ohdSystemAirSettingsModel.assignments.TXMODE_VIA_RC,4)
         compare(loader.item.mapping.join(","),before)
         compare(_ohdSystemGroundSettings.lastId,"")
     }
     function test_replacing_function_partial_save_can_retry(){
         var editor=openEditor(3)
         chooseFunction(editor,1)
         _ohdSystemAirSettingsModel.rejectId="MCS_VIA_RC";editor.apply()
         verify(editor.opened);verify(editor.savedChanges);compare(editor.error,"Rejected")
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,0)
         compare(_ohdSystemAirSettingsModel.assignments.MCS_VIA_RC,8)
         _ohdSystemAirSettingsModel.rejectId="";editor.apply()
         tryCompare(editor,"opened",false)
         compare(_ohdSystemAirSettingsModel.assignments.BW_VIA_RC,0)
         compare(_ohdSystemAirSettingsModel.assignments.MCS_VIA_RC,3)
     }
     function test_layout(){
         for(var i=0;i<3;i++){
             scene.width=[1200,750,440][i];wait(100)
             var toggle=findChild(loader.item,"joystickTransmit");verify(toggle.width>=40,"toggle width="+toggle.width);verify(toggle.height>=24,"toggle height="+toggle.height);var point=toggle.mapToItem(scene,0,0);verify(point.x+toggle.width<=scene.width,"toggle x="+point.x+" width="+toggle.width+" screen="+scene.width);
             var row=findChild(loader.item,"joystickChannel1");verify(row.width>200);verify(row.height>=64)
             grabImage(scene).save("build/joystick-"+scene.width+".png")
         }
     }
 }
}
