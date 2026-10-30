import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../qopenhd_settings"
import "../openhd_settings"
import "../MenuTypography.js" as Typography
import "JoystickMapping.js" as Mapping

Flickable {
 id:root; objectName:"joystickSettingsPanel"
 clip:true;contentWidth:width;contentHeight:cards.height;boundsBehavior:Flickable.StopAtBounds
 readonly property var groundParams:typeof _ohdSystemGroundSettings!=="undefined"?_ohdSystemGroundSettings:null
 readonly property var airParams:typeof _ohdSystemAirSettingsModel!=="undefined"?_ohdSystemAirSettingsModel:null
 readonly property var inputs:typeof _joystickInputModel!=="undefined"?_joystickInputModel:null
 readonly property int revision:groundParams?groundParams.update_count:0
 readonly property int airRevision:airParams?airParams.update_count:0
 readonly property bool connected:{revision;return groundParams && (typeof _ohdSystemGround!=="undefined"?_ohdSystemGround.is_alive:groundParams.system_is_alive())}
 readonly property bool available:{revision;return connected&&groundParams.param_string_exists("RC_CHAN_MAP")}
 readonly property bool modern:{revision;return available&&groundParams.param_int_exists("JOY_MAP_V2")&&groundParams.get_cached_int("JOY_MAP_V2")>=1}
 readonly property bool monitorSupported:{revision;return modern&&groundParams.param_int_exists("JOY_MONITOR")}
 readonly property bool transmitting:{revision;return available&&groundParams.param_int_exists("ENABLE_JOY_RC")&&groundParams.get_cached_int("ENABLE_JOY_RC")!==0}
 readonly property bool armed:typeof _fcMavlinkSystem!=="undefined" && _fcMavlinkSystem.armed
 readonly property string savedMap:{revision;return available?groundParams.get_cached_string("RC_CHAN_MAP"):""}
 readonly property bool dirty:mapping.join(",")!==savedMap
 readonly property var freeBlocks:Mapping.freeBlocks(mapping)
 readonly property bool luaAvailable:{airRevision;return airParams&&airParams.system_is_alive()&&airParams.param_int_exists("RC_SET_BASE")&&airParams.param_int_exists("RC_OHD_CTRL")}
 readonly property int luaBase:{airRevision;return luaAvailable?airParams.get_cached_int("RC_SET_BASE"):0}
 property var mapping:[]
 property var values:[]
 property int learning:-1
 property var inputBaseline:[]
 property int learnTicks:0
 property bool monitoring:false
 property string message:""
 property string loadedMap:""
 onSavedMapChanged: Qt.callLater(syncMap)
 function syncMap() {
     if(loadedMap===""||mapping.join(",")===loadedMap){mapping=Mapping.parse(savedMap)}
     loadedMap=savedMap
     if(!available){stopMonitor();mapping=[];loadedMap=""}
 }
 Component.onCompleted:{mapping=Mapping.parse(savedMap);loadedMap=savedMap}
 onVisibleChanged:if(!visible)stopMonitor()
 Component.onDestruction:stopMonitor()
 function write(model,id,value,stringValue) {
     if(armed){message=qsTr("Disarm before changing RC settings.");return false}
     var error=stringValue?model.try_update_parameter_string(id,value):model.try_update_parameter_int(id,value)
     message=error
     return error===""
 }
 function stopMonitor() {
     learning=-1
     if(monitoring&&groundParams&&connected)groundParams.try_update_parameter_int("JOY_MONITOR",0)
     monitoring=false
 }
 function monitor() {
     if(monitoring){stopMonitor();return}
     if(write(groundParams,"JOY_MONITOR",1,false))monitoring=true
 }
 function learn(output) {
     if(!monitoring||!inputs||!inputs.is_alive){message=qsTr("Read inputs and connect a joystick to the Ground unit first.");return}
     inputBaseline=inputs.channelValues();learning=output;learnTicks=100
     message=qsTr("Move one stick or switch for CH %1.").arg(output+1)
 }
 function assign(output,input) {
     if(modern)mapping=Mapping.assign(mapping,output,input)
     else {var next=mapping.slice();next[output]=input;mapping=next}
     learning=-1
     message=""
 }
 function save() {
     if(!available||mapping.length!==18)return
     if(write(groundParams,"RC_CHAN_MAP",mapping.join(","),true)) {
         loadedMap=mapping.join(",");message=qsTr("Channel assignments saved.")
     }
 }
 Timer {
     interval:100;running:root.visible&&root.monitoring;repeat:true
     onTriggered:{
         root.values=root.inputs&&root.inputs.is_alive?root.inputs.channelValues():[]
         if(root.learning<0)return
         if(root.values.length!==18){root.learning=-1;root.message=qsTr("Joystick input lost.");return}
         var moved=Mapping.movedInput(root.inputBaseline,root.values)
         if(moved>=0){var output=root.learning;root.assign(output,moved+1);root.message=qsTr("%1 assigned to CH %2.").arg(Mapping.sourceName(moved+1)).arg(output+1)}
         else if(--root.learnTicks<=0){root.learning=-1;root.message=qsTr("No clear movement detected. Try again.")}
     }
 }
 Column {
     id:cards;width:root.width;spacing:12
     MapSettingsCard {
         width:parent.width;height:implicitHeight;title:qsTr("Joystick");icon:"\uf11b"
         subtitle:qsTr("Connect the joystick to the OpenHD Ground unit.")
         Column {
             Layout.fillWidth:true;Layout.minimumWidth:0
             width:parent.width;spacing:10
             RowLayout {
                 width:parent.width
                 Text {Layout.fillWidth:true;text:qsTr("Send RC to flight controller");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
                 WidgetToggle {objectName:"joystickTransmit";enabled:root.available&&!root.armed;checked:root.transmitting;onToggled:root.write(root.groundParams,"ENABLE_JOY_RC",checked?1:0,false)}
             }
             Text {width:parent.width;text:!root.available?qsTr("Connect a Ground unit with joystick support."):!root.modern?qsTr("Update OpenHD for input learning and unassigned channels."):qsTr("Choose an output channel, then assign an input or move its control. Save to apply.");wrapMode:Text.WordWrap;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
             Flow {
                 width:parent.width;spacing:8
                 AdvancedActionButton {objectName:"joystickMonitor";text:root.monitoring?qsTr("Stop reading"):qsTr("Read inputs");enabled:root.monitorSupported&&!root.armed;onClicked:root.monitor()}
                 AdvancedActionButton {text:qsTr("Clear unused inputs");enabled:root.modern&&root.monitoring&&root.values.length===18&&!root.armed;onClicked:{var next=root.mapping.slice();for(var i=0;i<18;i++){var input=next[i]-1;if(input>=0&&(root.values[input]<800||root.values[input]>2200))next[i]=0}root.mapping=next}}
                 AdvancedActionButton {objectName:"joystickSave";text:qsTr("Save assignments");enabled:root.available&&root.dirty&&root.mapping.length===18&&!root.armed;onClicked:root.save()}
                 AdvancedActionButton {text:qsTr("Revert");enabled:root.dirty;onClicked:{root.mapping=Mapping.parse(root.savedMap);root.loadedMap=root.savedMap;root.learning=-1;root.message=""}}
             }
             Text {width:parent.width;visible:text.length>0;text:root.message;wrapMode:Text.WordWrap;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
         }
     }
     GridLayout {
         width:parent.width;columns:width>=1050?3:width>=680?2:1;columnSpacing:10;rowSpacing:8
         Repeater {
             model:root.mapping.length
             Rectangle {
                 id:channelRow;objectName:"joystickChannel"+(index+1)
                 Layout.fillWidth:true;Layout.minimumWidth:0;implicitHeight:126
                 color:settings_form.panelBackground;border.color:root.learning===index?settings_form.accentColor:settings_form.lineColor;radius:8
                 readonly property int output:index
                 readonly property int input:root.mapping[index]||0
                 readonly property int pwm:input>0&&root.values.length===18?root.values[input-1]:-1
                 ColumnLayout {
                     anchors.fill:parent;anchors.margins:12;spacing:8
                     RowLayout {
                         Layout.fillWidth:true
                         Text {text:qsTr("CH %1").arg(index+1);color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
                         Text {Layout.fillWidth:true;text:root.luaBase>0&&index+1>=root.luaBase&&index+1<root.luaBase+4?qsTr("Lua"):"";color:settings_form.accentColor;font.family:Typography.family;font.pixelSize:Typography.helper}
                         Text {text:channelRow.pwm>=800&&channelRow.pwm<=2200?channelRow.pwm:"--";color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                     }
                     RowLayout {
                         Layout.fillWidth:true;spacing:8
                         CompactLinkComboBox {
                             objectName:"joystickSource"+(index+1);Layout.fillWidth:true;Layout.minimumWidth:0
                             property var sources:{var a=[];if(root.modern)a.push({text:qsTr("Unassigned"),value:0});for(var j=1;j<=18;j++)a.push({text:Mapping.sourceName(j),value:j});return a}
                             model:sources;textRole:"text";currentIndex:channelRow.input-(root.modern?0:1);enabled:!root.armed
                             onActivated:root.assign(channelRow.output,sources[currentIndex].value)
                         }
                         AdvancedActionButton {text:root.learning===index?qsTr("Move..."):qsTr("Assign");implicitWidth:Typography.controlMinWidth;enabled:root.monitoring&&root.inputs&&root.inputs.is_alive&&!root.armed;onClicked:root.learn(index)}
                     }
                     ProgressBar {Layout.fillWidth:true;from:1000;to:2000;value:channelRow.pwm>=800&&channelRow.pwm<=2200?channelRow.pwm:1000}
                 }
             }
         }
     }
     MapSettingsCard {
         width:parent.width;height:implicitHeight;title:qsTr("OpenHD Lua channels");icon:"\uf121"
         subtitle:qsTr("Four consecutive channels for the transmitter's OpenHD Lua tool.")
         Column {
             Layout.fillWidth:true;Layout.minimumWidth:0
             width:parent.width;spacing:10
             RowLayout {
                 width:parent.width
                 Text {Layout.fillWidth:true;text:qsTr("Enable Lua settings");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                 WidgetToggle {enabled:root.luaAvailable&&root.luaBase>0&&!root.armed;checked:{root.airRevision;return root.luaAvailable&&root.airParams.get_cached_int("RC_OHD_CTRL")!==0}
                     onToggled:root.write(root.airParams,"RC_OHD_CTRL",checked?1:0,false)}
             }
             RowLayout {
                 width:parent.width
                 Text {Layout.fillWidth:true;text:qsTr("First channel");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                 CompactLinkComboBox {
                     objectName:"joystickLuaBase";Layout.preferredWidth:180
                     model:{var a=[qsTr("Disabled")];for(var i=1;i<=15;i++)a.push("CH "+i+" - "+(i+3));return a}
                     currentIndex:root.luaBase;enabled:root.luaAvailable&&!root.armed
                     onActivated:root.write(root.airParams,"RC_SET_BASE",currentIndex,false)
                 }
             }
             AdvancedActionButton {
                 objectName:"joystickLuaFree";text:root.freeBlocks.length?qsTr("Use free CH %1 - %2").arg(root.freeBlocks[0]).arg(root.freeBlocks[0]+3):qsTr("No free four-channel block")
                 enabled:root.luaAvailable&&root.modern&&!root.dirty&&root.freeBlocks.length>0&&!root.armed
                 onClicked:root.write(root.airParams,"RC_SET_BASE",root.freeBlocks[0],false)
             }
             Text {width:parent.width;wrapMode:Text.WordWrap;text:qsTr("Free means unassigned in this joystick map. Match D2, D1, D0 and CLK in the transmitter's Lua tool; check its mixes separately.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
         }
     }
     MapSettingsCard {
         objectName:"joystickFcChannels";width:parent.width;height:implicitHeight
         title:qsTr("FC channels");icon:"\uf1de"
         Column {
             Layout.fillWidth:true;Layout.minimumWidth:0;width:parent.width;spacing:4
             Text {
                 width:parent.width;visible:typeof _rcchannelsmodelfc==="undefined" || !_rcchannelsmodelfc.is_alive
                 text:qsTr("Waiting for flight-controller channels.");wrapMode:Text.WordWrap
                 color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper
             }
             Repeater {
                 model:typeof _rcchannelsmodelfc!=="undefined"?_rcchannelsmodelfc:null
                 Rectangle {
                     objectName:"joystickFcChannel"+(index+1);width:parent.width;height:38;radius:6
                     color:index%2?settings_form.panelBackgroundRaised:"transparent"
                     RowLayout {
                         anchors.fill:parent;anchors.leftMargin:10;anchors.rightMargin:10;spacing:12
                         Text {text:qsTr("CH %1").arg(index+1);Layout.preferredWidth:52;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                         ProgressBar {Layout.fillWidth:true;from:1000;to:2000;value:model.curr_value>=800&&model.curr_value<=2200?model.curr_value:1000}
                         Text {text:model.curr_value>=800&&model.curr_value<=2200?model.curr_value:"--";Layout.preferredWidth:48;horizontalAlignment:Text.AlignRight;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                     }
                 }
             }
         }
     }
 }
}
