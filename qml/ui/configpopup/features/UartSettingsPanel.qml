import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../qopenhd_settings"
import "../openhd_settings"
import "../MenuTypography.js" as Typography

Flickable {
 id:root;objectName:"uartSettingsPanel"
 clip:true;contentWidth:width;contentHeight:cards.y+cards.implicitHeight;boundsBehavior:Flickable.StopAtBounds
 property string validationError:""
 readonly property bool advanced:settings_form.showAdvancedSettings || settings_form.showDeveloperSettings
 readonly property var sections:[
     {id:"fc",title:qsTr("Flight controller"),note:qsTr("Air"),description:qsTr("Serial connection from the Air unit to the flight controller."),icon:"\uf2db",side:"air",rows:[
         {id:"FC_UART_CONN",label:qsTr("Port"),hint:qsTr("UART connected to the flight controller.")},
         {id:"FC_UART_BAUD",label:qsTr("Baud rate"),hint:qsTr("Match the flight-controller serial speed.")},
         {id:"FC_UART_FLWCTL",label:qsTr("Flow control"),hint:qsTr("Enable only when RTS and CTS are wired.")}]},
     {id:"tracker",title:qsTr("Tracker output"),note:qsTr("Ground"),description:qsTr("Send flight-controller MAVLink telemetry to a tracker or radio."),icon:"\uf124",side:"ground",rows:[
         {id:"TRACKER_UART_OUT",label:qsTr("Port"),hint:qsTr("Choose Disabled to stop tracker output.")},
         {id:"TRACK_UART_BAUD",label:qsTr("Baud rate"),hint:qsTr("Match the tracker or radio serial speed.")},
         {id:"TRACK_UART_FLOW",label:qsTr("Flow control"),hint:qsTr("Enable only when RTS and CTS are wired.")}]},
     {id:"airLink",title:qsTr("Serial telemetry link"),note:qsTr("Air"),description:qsTr("mLRS / ELRS Backpack via a MAVLink UART bridge; no video."),icon:"\uf0c1",side:"air",rows:linkRows},
     {id:"groundLink",title:qsTr("Serial telemetry link"),note:qsTr("Ground"),description:qsTr("Configure the matching Ground end of the serial radio link."),icon:"\uf0c1",side:"ground",rows:linkRows}]
 readonly property var linkRows:[
     {id:"OHD_UART_EN",label:qsTr("Enable serial link"),hint:qsTr("Use the module's MAVLink serial mode.")},
     {id:"OHD_UART_TLM",label:qsTr("Port"),hint:qsTr("UART connected to this unit's radio or bridge.")},
     {id:"OHD_UART_BAUD",label:qsTr("Baud rate"),hint:qsTr("Match the attached module's serial speed.")},
     {id:"OHD_UART_FLW",label:qsTr("Flow control"),hint:qsTr("Enable only when RTS and CTS are wired.")},
     {id:"UART_PRI_RC",label:qsTr("RC priority"),hint:qsTr("Scheduling priority for RC commands."),advanced:true},
     {id:"UART_PRI_OHD",label:qsTr("OpenHD priority"),hint:qsTr("Scheduling priority for OpenHD settings and status."),advanced:true},
     {id:"UART_PRI_FC",label:qsTr("FC telemetry priority"),hint:qsTr("Scheduling priority for flight-controller telemetry."),advanced:true}]
 function modelFor(side){return side==="air"?_ohdSystemAirSettingsModel:_ohdSystemGroundSettings}
 function alive(side){return side==="air"?_ohdSystemAir.is_alive:_ohdSystemGround.is_alive}
 function rowsFor(section) {
     var model=modelFor(section.side)
     return section.rows.filter(function(row){return (!row.advanced||root.advanced)&&(model.param_int_exists(row.id)||model.param_string_exists(row.id))})
 }
 function validatePort(side, id, value) {
     validationError=""
     if(["FC_UART_CONN","TRACKER_UART_OUT","OHD_UART_TLM","OHD_UART_EN"].indexOf(id)<0)return ""
     var model=modelFor(side)
     function port(key){return key===id?String(value).trim():model.param_string_exists(key)?model.get_cached_string(key):""}
     var enabled=id==="OHD_UART_EN"?Number(value)!==0:model.param_int_exists("OHD_UART_EN")&&model.get_cached_int("OHD_UART_EN")!==0
     if(id==="OHD_UART_EN" && enabled && !port("OHD_UART_TLM"))
         return qsTr("Choose a UART port before enabling the serial telemetry link.")
     var used=side==="air"?[{name:qsTr("flight controller"),port:port("FC_UART_CONN")}]:[{name:qsTr("tracker"),port:port("TRACKER_UART_OUT")}]
     if(enabled)used.push({name:qsTr("serial telemetry link"),port:port("OHD_UART_TLM")})
     if(used.length===2 && used[0].port && used[0].port!=="DEFAULT" && used[0].port===used[1].port)
         return qsTr("%1: %2 is already assigned. Use a separate UART for the %3 and %4.").arg(side==="air"?qsTr("Air"):qsTr("Ground")).arg(used[0].port).arg(used[0].name).arg(used[1].name)
     return ""
 }
 Text {
     id:errorText;width:root.width;visible:root.validationError.length>0;text:root.validationError
     color:settings_form.errorColor;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap
 }
 GridLayout {
     y:errorText.visible?errorText.height+10:0
     id:cards;width:root.width;columns:width>=900?2:1;columnSpacing:12;rowSpacing:12
     Repeater {
         model:root.sections
         MapSettingsCard {
             id:card;objectName:"uartSection_"+section.id
             readonly property var section:modelData
             readonly property var params:root.modelFor(section.side)
             readonly property int revision:params.update_count
             readonly property var rows:{revision;return root.rowsFor(section)}
             Layout.fillWidth:true;Layout.minimumWidth:0;Layout.alignment:Qt.AlignTop
             title:section.title;subtitle:section.description;headerNote:section.note;icon:section.icon
             Column {
                 Layout.fillWidth:true;Layout.minimumWidth:0;width:parent.width;spacing:2
                 Text {
                     width:parent.width;visible:!root.alive(card.section.side)||card.rows.length===0
                     text:!root.alive(card.section.side)?qsTr("Connect the %1 unit to configure this connection.").arg(card.section.note):qsTr("This firmware does not report these UART settings.")
                     wrapMode:Text.WordWrap;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper
                 }
                 Repeater {
                     model:card.rows
                     AirSettingRow {
                         objectName:"uartSetting_"+card.section.id+"_"+paramId
                         width:parent.width;settingsModel:card.params;connectionAlive:root.alive(card.section.side)
                         paramId:modelData.id;labelOverride:modelData.label;descriptionOverride:modelData.hint
                         validateChange:function(id,value){return root.validatePort(card.section.side,id,value)}
                         onValidationFailed:function(reason){root.validationError=reason}
                     }
                 }
             }
         }
     }
 }
}
