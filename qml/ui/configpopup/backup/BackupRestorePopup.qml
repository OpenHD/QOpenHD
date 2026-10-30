import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../MenuTypography.js" as Typography

AdvancedDialog {
 id:dialog;objectName:"settingsBackupPopup"
 readonly property var backend:typeof _settingsBackup!=="undefined"?_settingsBackup:null
 readonly property var fleet:typeof _fleetControlLte!=="undefined"?_fleetControlLte:null
 readonly property bool cloudAvailable:fleet&&fleet.authenticated
 property var importSections:[]
 property var selectedSections:[]
 property string selectedFile:""
 property bool reviewing:false
 property bool exporting:false
 parent:Overlay.overlay
 width:Math.min(580,parent?parent.width-28:580)
 height:Math.min(reviewing?190+importSections.length*48:232+(cloudAvailable?120:0)+(backend&&backend.restartRequired?46:0),parent?parent.height-28:600)
 x:parent?(parent.width-width)/2:0;y:parent?(parent.height-height)/2:0
 closePolicy:backend&&backend.busy?Popup.NoAutoClose:Popup.CloseOnEscape
 standardButtons:Dialog.NoButton
 onAboutToShow:{reviewing=false;if(backend)backend.refreshLocations();if(cloudAvailable)fleet.refreshSettingsBackups()}
 header:Item {
     implicitHeight:64
     RowLayout {
         x:20;y:18;width:parent.width-40;height:34;spacing:14
         Text {text:"\uf0c7";color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon}
         Text {Layout.fillWidth:true;text:qsTr("Backup & Restore");color:settings_form.primaryText;font.bold:true;font.family:Typography.family;font.pixelSize:Typography.dialogTitle}
         ToolButton {
             objectName:"backupCloseButton";Layout.preferredWidth:Typography.controlHeight;Layout.preferredHeight:Typography.controlHeight;padding:0
             enabled:!backend||!backend.busy;Accessible.name:qsTr("Close");onClicked:dialog.close()
             background:Rectangle {radius:Typography.controlRadius;color:parent.hovered||parent.activeFocus?settings_form.panelBackgroundRaised:"transparent"}
             contentItem:Text {text:"\uf00d";color:settings_form.primaryText;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.rowIcon;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
         }
     }
 }
 function reviewFile(path){
     selectedFile=path
     var review=backend.inspectBackup(path)
     if(review.error)return
     importSections=review.sections;selectedSections=review.sections.filter(function(s){return s.selected}).map(function(s){return s.id});reviewing=true
 }
 Connections {
     target:dialog.fleet
     function onSettingsBackupReady(document){var path=dialog.backend.cacheCloudBackup(document);if(path.length){cloudList.close();dialog.reviewFile(path)}}
 }
 function updateScrollHeight(){backupScroll.contentHeight=body.implicitHeight}
 contentItem:Flickable {
     id:backupScroll
     contentWidth:width;clip:true;boundsBehavior:Flickable.StopAtBounds
     onWidthChanged:Qt.callLater(dialog.updateScrollHeight)
     Component.onCompleted:Qt.callLater(dialog.updateScrollHeight)
     ColumnLayout {
         id:body;width:backupScroll.width;height:implicitHeight;spacing:12
         onImplicitHeightChanged:Qt.callLater(dialog.updateScrollHeight)
         RowLayout {
             visible:!dialog.reviewing;Layout.fillWidth:true;spacing:12
             Repeater {
                 model:[{label:qsTr("Export"),icon:"\uf019",save:true},{label:qsTr("Import"),icon:"\uf093",save:false}]
                 AbstractButton {
                     objectName:modelData.save?"backupExport":"backupImport"
                     Layout.fillWidth:true;Layout.minimumWidth:0;Layout.preferredWidth:1;implicitHeight:116
                     enabled:dialog.backend!==null&&!dialog.backend.busy
                     onClicked:{dialog.exporting=modelData.save;if(typeof settings!=="undefined"&&typeof settings.sync==="function")settings.sync();filePicker.openForSave(modelData.save)}
                     background:Rectangle {radius:10;color:parent.hovered?settings_form.panelBackgroundRaised:settings_form.panelBackground;border.color:parent.activeFocus?settings_form.accentColor:settings_form.lineColor}
                     contentItem:Item {
                         Column {
                         anchors.centerIn:parent;width:parent.width;spacing:12
                         Text {anchors.horizontalCenter:parent.horizontalCenter;text:modelData.icon;color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon}
                         Text {anchors.horizontalCenter:parent.horizontalCenter;text:modelData.label;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle}
                     }
                     }
                 }
             }
         }
         ColumnLayout {
             Layout.fillWidth:true;visible:dialog.cloudAvailable&&!dialog.reviewing;spacing:8
             Text {text:qsTr("FleetControl - %1").arg(dialog.fleet?dialog.fleet.accountName:"");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
             RowLayout {
                 Layout.fillWidth:true
                 AdvancedActionButton {objectName:"saveFleetControlBackup";text:qsTr("Save to FleetControl");enabled:dialog.cloudAvailable&&dialog.fleet.online&&!dialog.fleet.busy&&!dialog.backend.busy;onClicked:cloudSave.open()}
                 AdvancedActionButton {objectName:"loadFleetControlBackups";text:qsTr("Account backups");enabled:dialog.cloudAvailable&&!dialog.fleet.busy;onClicked:{dialog.fleet.refreshSettingsBackups();cloudList.open()}}
             }
             Text {Layout.fillWidth:true;text:dialog.fleet?dialog.fleet.statusText:"";color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
         }
         ColumnLayout {
             visible:dialog.reviewing;Layout.fillWidth:true;spacing:8
             Text {Layout.fillWidth:true;text:qsTr("Choose what to restore");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
             Repeater {model:dialog.importSections
                 CheckBox {
                     objectName:"restoreSection_"+modelData.id
                     text:modelData.title+(modelData.ready?"":(modelData.reason?" - "+modelData.reason:qsTr(" - connect and load settings first")))
                     enabled:modelData.ready&&!dialog.backend.busy;checked:modelData.selected
                     font.family:Typography.family;font.pixelSize:Typography.body
                     onToggled:{var selected=dialog.selectedSections.slice();var at=selected.indexOf(modelData.id);if(checked&&at<0)selected.push(modelData.id);else if(!checked&&at>=0)selected.splice(at,1);dialog.selectedSections=selected}
                     contentItem:Text {text:parent.text;color:settings_form.primaryText;leftPadding:parent.indicator.width+parent.spacing;verticalAlignment:Text.AlignVCenter;wrapMode:Text.WordWrap;font.family:Typography.family;font.pixelSize:Typography.body}
                 }
             }
             RowLayout {
                 Layout.fillWidth:true
                 AdvancedActionButton {text:qsTr("Back");enabled:!dialog.backend.busy;onClicked:dialog.reviewing=false}
                 Item {Layout.fillWidth:true}
                 AdvancedActionButton {objectName:"confirmSettingsRestore";text:qsTr("Restore selected settings");enabled:!dialog.backend.busy&&dialog.selectedSections.length>0;onClicked:dialog.backend.restoreBackup(dialog.selectedFile,dialog.selectedSections)}
             }
         }
         ProgressBar {Layout.fillWidth:true;visible:dialog.backend&&dialog.backend.busy;from:0;to:100;value:dialog.backend?dialog.backend.progress:0}
         Text {Layout.fillWidth:true;visible:text.length>0;text:dialog.backend?dialog.backend.message:qsTr("Backup service unavailable.");wrapMode:Text.WordWrap;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
         AdvancedActionButton {visible:dialog.backend&&dialog.backend.restartRequired;enabled:!dialog.backend.busy;text:qsTr("Close QOpenHD");onClicked:_qopenhd.quit_qopenhd()}
     }
 }
 SettingsFilePicker {
     id:filePicker;backend:dialog.backend
     onChosen:function(path){
         dialog.selectedFile=path
         if(dialog.exporting){if(dialog.backend.exists(path))overwrite.open();else dialog.backend.exportBackup(path,false)}
         else {
             dialog.reviewFile(path)
         }
     }
 }
 AdvancedDialog {
     id:cloudSave;objectName:"cloudBackupNameDialog";parent:Overlay.overlay;title:qsTr("Save to FleetControl")
     width:Math.min(440,parent?parent.width-28:440);x:parent?(parent.width-width)/2:0;y:parent?(parent.height-height)/2:0
     standardButtons:Dialog.Save|Dialog.Cancel
     contentItem:TextField { verticalAlignment: TextInput.AlignVCenter; leftPadding: 12; rightPadding: 12; topPadding: 6; bottomPadding: 6;id:cloudName;text:"OpenHD-"+Qt.formatDateTime(new Date(),"yyyy-MM-dd_HH-mm-ss");placeholderText:qsTr("Backup name");maximumLength:100;selectByMouse:true}
     onAccepted:{if(typeof settings!=="undefined"&&typeof settings.sync==="function")settings.sync();var document=dialog.backend.exportDocument();if(Object.keys(document).length)dialog.fleet.saveSettingsBackup(cloudName.text,document)}
 }
 AdvancedDialog {
     id:cloudList;parent:Overlay.overlay;title:qsTr("FleetControl account backups")
     width:Math.min(580,parent?parent.width-28:580);height:Math.min(430,parent?parent.height-28:430)
     x:parent?(parent.width-width)/2:0;y:parent?(parent.height-height)/2:0
     contentItem:ListView {
         clip:true;spacing:8;model:dialog.fleet?dialog.fleet.settingsBackups:[]
         delegate:AdvancedActionButton {width:ListView.view.width;text:modelData.name+" / "+String(modelData.createdAt).substring(0,10);enabled:!dialog.fleet.busy;onClicked:dialog.fleet.loadSettingsBackup(modelData.id)}
         Text {anchors.centerIn:parent;visible:parent.count===0;text:qsTr("No saved backups");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
     }
 }
 AdvancedDialog {
     id:overwrite;title:qsTr("Overwrite settings file?");parent:Overlay.overlay
     width:Math.min(420,parent?parent.width-28:420);x:parent?(parent.width-width)/2:0;y:parent?(parent.height-height)/2:0
     standardButtons:Dialog.Yes|Dialog.No
     onAccepted:dialog.backend.exportBackup(dialog.selectedFile,true)
 }
}
