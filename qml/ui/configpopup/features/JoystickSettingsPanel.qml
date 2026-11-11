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
 readonly property bool transmitting:{revision;return connected&&groundParams.param_int_exists("ENABLE_JOY_RC")&&groundParams.get_cached_int("ENABLE_JOY_RC")!==0}
 readonly property bool transmitAvailable:{revision;return connected&&groundParams.param_int_exists("ENABLE_JOY_RC")}
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
 readonly property bool monitoring:transmitting&&inputs&&inputs.is_alive
 property bool monitorRequested:false
 onMonitoringChanged:if(!monitoring){values=[];learning=-1}
 property string message:""
 property string loadedMap:""
 onSavedMapChanged: Qt.callLater(syncMap)
 function syncMap() {
     if(loadedMap===""||mapping.join(",")===loadedMap){mapping=Mapping.parse(savedMap)}
     loadedMap=savedMap
     if(!available){stopMonitor();mapping=[];loadedMap=""}
 }
 Component.onCompleted:{mapping=Mapping.parse(savedMap);loadedMap=savedMap;syncMonitor()}
 onVisibleChanged:syncMonitor()
 onTransmittingChanged:Qt.callLater(syncMonitor)
 onMonitorSupportedChanged:Qt.callLater(syncMonitor)
 Component.onDestruction:stopMonitor()
 function write(model,id,value,stringValue) {
     if(armed){message=qsTr("Disarm before changing RC settings.");return false}
     var error=stringValue?model.try_update_parameter_string(id,value):model.try_update_parameter_int(id,value)
     message=error
     return error===""
 }
 function stopMonitor() {
     learning=-1
     var release=monitorRequested&&groundParams&&connected
     monitorRequested=false
     values=[]
     if(release)groundParams.try_update_parameter_int("JOY_MONITOR",0)
 }
 function syncMonitor() {
     if(!visible||!transmitting){stopMonitor();return}
     // Compatibility with firmware where raw input reporting still needs this request.
     if(monitorSupported&&!monitorRequested){monitorRequested=true;if(groundParams.try_update_parameter_int("JOY_MONITOR",1)!=="")monitorRequested=false}
 }
 function learn(output) {
     if(!monitoring||!inputs||!inputs.is_alive){message=qsTr("Enable joystick RC and connect a joystick first.");return}
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
     ChannelOverview {
         objectName: "joystickChannelOverview"
         width: parent.width
         controller: root
     }
     MapSettingsCard {
         objectName: "joystickControls"
         visible: settings_form.showAdvancedSettings
         width:parent.width;height:implicitHeight;title:qsTr("Joystick");icon:"\uf11b"
         subtitle:qsTr("Connect the joystick to the OpenHD Ground unit.")
         Column {
             Layout.fillWidth:true;Layout.minimumWidth:0
             width:parent.width;spacing:10
             RowLayout {
                 width:parent.width
                 Text {Layout.fillWidth:true;text:qsTr("Send RC to flight controller");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
                 WidgetToggle {objectName:"joystickTransmit";enabled:root.transmitAvailable&&!root.armed;checked:root.transmitting;onToggled:{root.write(root.groundParams,"ENABLE_JOY_RC",checked?1:0,false);checked=Qt.binding(function(){return root.transmitting})}}
             }

             Flow {
                 width:parent.width;spacing:8
                 AdvancedActionButton {text:qsTr("Clear unused inputs");enabled:root.modern&&root.monitoring&&root.values.length===18&&!root.armed;onClicked:{var next=root.mapping.slice();for(var i=0;i<18;i++){var input=next[i]-1;if(input>=0&&(root.values[input]<800||root.values[input]>2200))next[i]=0}root.mapping=next}}
                 AdvancedActionButton {objectName:"joystickSave";text:qsTr("Save assignments");enabled:root.available&&root.dirty&&root.mapping.length===18&&!root.armed;onClicked:root.save()}
                 AdvancedActionButton {text:qsTr("Revert");enabled:root.dirty;onClicked:{root.mapping=Mapping.parse(root.savedMap);root.loadedMap=root.savedMap;root.learning=-1;root.message=""}}
             }
             Text {width:parent.width;visible:text.length>0;text:root.message;wrapMode:Text.WordWrap;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
         }
     }
     MapSettingsCard {
         objectName: "joystickLuaControls"
         visible: settings_form.showAdvancedSettings
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

         }
     }
 }
}
