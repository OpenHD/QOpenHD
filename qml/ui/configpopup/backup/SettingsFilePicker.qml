import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography

AdvancedDialog {
 id:picker;objectName:"settingsFilePicker"
 property var backend
 property bool saving:false
 property var volumes:[]
 property var entries:[]
 property string directory:""
 property string filename:""
 property string error:""
 property bool writable:false
 property string pendingChoice:""
 onClosed:{var result=pendingChoice;pendingChoice="";if(result.length)chosen(result)}
 signal chosen(string path)
 parent:Overlay.overlay
 width:Math.min(660,parent?parent.width-24:660)
 height:Math.min(480,parent?parent.height-24:480)
 x:parent?(parent.width-width)/2:0;y:parent?(parent.height-height)/2:0
 title:saving?qsTr("Export settings"):qsTr("Import settings")
 standardButtons:Dialog.NoButton
 function go(path){
     var result=backend.browse(path)
     if(result.error){error=result.error;return}
     directory=result.path;entries=result.entries;writable=result.writable;error="";pathField.text=directory
 }
 function openForSave(save){
     pendingChoice="";saving=save;backend.refreshLocations();volumes=backend.locations().filter(function(v){return v.writable});filename=save?"OpenHD-settings-"+Qt.formatDateTime(new Date(),"yyyy-MM-dd_HH-mm-ss")+".ohdsettings":""
     go(backend.initialDirectory());open()
 }
 function choose(){
     var name=filename.trim()
     if(saving&&name.indexOf(".")<0)name+=".ohdsettings"
     var path=backend.joinPath(directory,name)
     if(!path){error=qsTr("Enter a filename without folder separators.");return}
     if(!saving&&!backend.exists(path)){error=qsTr("Choose an existing settings file.");return}
     if(saving&&!writable){return}
     pendingChoice=path;close()
 }
 Connections {target:picker.backend;function onStorageLocationsChanged(){picker.volumes=picker.backend.locations().filter(function(v){return v.writable})}}
 contentItem:Flickable {
     id:pickerScroll;clip:true;contentWidth:width;contentHeight:pickerBody.height;boundsBehavior:Flickable.StopAtBounds
     Item {
     id:pickerBody;width:pickerScroll.width;height:Math.max(pickerScroll.height,350)
     ColumnLayout {
     anchors.fill:parent;spacing:8
     RowLayout {
         Layout.fillWidth:true
         AdvancedActionButton {
             implicitWidth:Typography.controlHeight;Layout.preferredWidth:Typography.controlHeight
             onClicked:picker.go(backend.parentDirectory(picker.directory));Accessible.name:qsTr("Parent folder")
             contentItem:Text {text:"\uf062";font.family:"Font Awesome 5 Free";font.pixelSize:Typography.controlIcon;color:settings_form.primaryText;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
         }
         TextField { rightPadding: 12; topPadding: 6; bottomPadding: 6;id:pathField;objectName:"backupFolderPath";Layout.fillWidth:true;text:picker.directory;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;leftPadding:12;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true;onEditingFinished:picker.go(text);background:Rectangle {radius:8;color:settings_form.panelBackground;border.color:settings_form.lineColor}}
     }
     Text {visible:picker.backend&&picker.backend.storageScanning;text:qsTr("Looking for mounted storage...");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
     CompactLinkComboBox {
         visible:picker.width<600;Layout.fillWidth:true
         model:picker.volumes;textRole:"label"
         onActivated:picker.go(picker.volumes[currentIndex].path)
     }
     RowLayout {
         objectName:"backupStorageArea";Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:130;spacing:10
         ListView {
             visible:picker.width>=600;Layout.preferredWidth:140;Layout.fillHeight:true;clip:true;spacing:4
             model:picker.volumes
             delegate:AdvancedActionButton {
                 width:ListView.view.width;text:modelData.label
                 onClicked:picker.go(modelData.path)
             }
         }
         Rectangle {
             Layout.fillWidth:true;Layout.fillHeight:true;radius:8;color:settings_form.panelBackground;border.color:settings_form.lineColor
             ListView {
                 id:files;objectName:"backupFileList";anchors.fill:parent;anchors.margins:6;clip:true;model:picker.entries;spacing:2
                 delegate:ItemDelegate {
                     width:files.width;height:Math.max(Typography.controlHeight,nameLabel.implicitHeight+18)
                     onClicked:if(modelData.directory)picker.go(modelData.path);else picker.filename=modelData.name
                     background:Rectangle {radius:6;color:parent.hovered||picker.filename===modelData.name?settings_form.panelBackgroundRaised:"transparent"}
                     contentItem:RowLayout {
                         spacing:10
                         Text {text:modelData.directory?"\uf07b":"\uf15b";color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.rowIcon}
                         Text {id:nameLabel;Layout.fillWidth:true;text:modelData.name;color:settings_form.primaryText;wrapMode:Text.WrapAnywhere;font.family:Typography.family;font.pixelSize:Typography.body}
                     }
                 }
                 Text {anchors.centerIn:parent;visible:files.count===0;text:qsTr("Folder is empty");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
             }
         }
     }
     Text {Layout.fillWidth:true;visible:text.length>0;text:picker.error;wrapMode:Text.WordWrap;color:settings_form.errorColor;font.family:Typography.family;font.pixelSize:Typography.helper}
     RowLayout {
         Layout.fillWidth:true
         Text {text:qsTr("Filename");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
         TextField { rightPadding: 12; topPadding: 6; bottomPadding: 6;objectName:"backupFilename";Layout.fillWidth:true;text:picker.filename;onTextEdited:picker.filename=text;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;leftPadding:12;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true;onAccepted:picker.choose();background:Rectangle {radius:8;color:settings_form.panelBackground;border.color:settings_form.lineColor}}
     }
     RowLayout {
         Layout.fillWidth:true
         Item {Layout.fillWidth:true}
         AdvancedActionButton {text:qsTr("Cancel");onClicked:picker.close()}
         AdvancedActionButton {objectName:"backupChooseFile";text:picker.saving?qsTr("Save here"):qsTr("Open");enabled:picker.filename.trim().length>0&&(!picker.saving||picker.writable);onClicked:picker.choose()}
     }
     }
     }
 }
}
