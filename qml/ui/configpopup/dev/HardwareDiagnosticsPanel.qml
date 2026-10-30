import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../openhd_settings/AirSettingsLayout.js" as AirLayout
import "../MenuTypography.js" as Typography

Flickable {
 id:root;clip:true;contentWidth:width;contentHeight:body.implicitHeight;boundsBehavior:Flickable.StopAtBounds
 property var settingsModel
 property var systemModel
 readonly property int revision:settingsModel?settingsModel.update_count:0
 readonly property bool connected:systemModel&&systemModel.is_alive
 function ensureParameters(){if(visible&&connected&&settingsModel&&!settingsModel.ui_is_busy&&!_qopenhd.debugMenuPreview)settingsModel.ensure_parameters_available()}
 onVisibleChanged:if(visible)ensureParameters()
 onConnectedChanged:if(connected)ensureParameters()
 Component.onCompleted:ensureParameters()
 readonly property var parameterIds:{
     revision
     if(!settingsModel||settings_form.showDeveloperSettings!==true)return []
     var ids=settingsModel.param_ids().slice()
     // Some identifiers are hidden from the generic list but still available to dedicated controls.
     var known=AirLayout.knownAirIds.concat(AirLayout.developerParameters)
     for(var i=0;i<known.length;i++)if(ids.indexOf(known[i])<0&&(settingsModel.param_int_exists(known[i])||settingsModel.param_string_exists(known[i])))ids.push(known[i])
     return ids.filter(function(id){return AirLayout.isHardwareDiagnostic(id)}).sort()
 }
 ColumnLayout {
     id:body;width:root.width;spacing:10
     RowLayout {
         Layout.fillWidth:true
         Text {Layout.fillWidth:true;text:root.connected?(root.systemModel.ohd_platform_type_as_string||qsTr("Connected")):qsTr("Unit disconnected");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
         AdvancedActionButton {objectName:"refreshHardwareDiagnostics";text:qsTr("Refresh");iconText:"\uf2f1";enabled:root.connected&&root.settingsModel&&!root.settingsModel.ui_is_busy&&!_qopenhd.debugMenuPreview;onClicked:root.settingsModel.try_refetch_all_parameters_async(false)}
     }
     AdvancedCard {
         Layout.fillWidth:true;Layout.preferredHeight:rows.implicitHeight+24;contentMargin:12
         Column {
             id:rows;anchors.left:parent.left;anchors.right:parent.right;spacing:4
             Text {width:parent.width;visible:root.parameterIds.length===0;text:root.connected?qsTr("No hardware diagnostics reported by this firmware."):qsTr("Connect this unit to view its hardware diagnostics.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
             Repeater {
                 model:root.parameterIds
                 AirSettingRow {objectName:"hardwareDiagnostic_"+paramId;width:parent.width;settingsModel:root.settingsModel;connectionAlive:root.connected;paramId:modelData}
             }
         }
     }
 }
}
