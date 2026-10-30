import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/backup" as Pages
Item {
 id:scene;width:1000;height:750
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property color errorColor:"#ff4e5d";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 QtObject {id:_qopenhd;function quit_qopenhd(){}}
 QtObject {id:settings;property int syncs:0;function sync(){syncs++}}
 QtObject {
     id:_fleetControlLte
     property bool authenticated:false
     property bool online:true
     property bool busy:false
     property string accountName:"Test account"
     property string statusText:"Online"
     property var settingsBackups:[]
     signal settingsBackupReady(var document)
     function refreshSettingsBackups(){}
     function saveSettingsBackup(name,document){}
     function loadSettingsBackup(id){}
 }
 QtObject {
     id:_settingsBackup
     property bool busy:false
     property int progress:0
     property string message:""
     property bool restartRequired:false
     property bool storageScanning:false
     property string lastExport:""
     property string lastImport:""
     property var selected:[]
     signal storageLocationsChanged()
     function sections(){return [{id:"qopenhd",title:"QOpenHD / OSD",ready:true},{id:"air",title:"Air",ready:true},{id:"ground",title:"Ground",ready:false}]}
     function locations(){return [{label:"Video storage",path:"/Video",writable:true},{label:"USB",path:"/media/usb",writable:true},{label:"SD (read-only)",path:"/media/sd",writable:false}]}
     function refreshLocations(){}
     function initialDirectory(){return "/Video"}
     function parentDirectory(path){return "/"}
     function joinPath(directory,name){return name.indexOf("/")>=0?"":directory+"/"+name}
     function exists(path){return path.indexOf("saved.ohdsettings")>=0}
     function browse(path){return {path:path,writable:path!=="/media/sd",entries:[{name:"Backups",path:path+"/Backups",directory:true},{name:"saved.ohdsettings",path:path+"/saved.ohdsettings",directory:false}]}}
     function exportBackup(path,overwrite){lastExport=path;message="Saved";return true}
     function inspectBackup(path){return {sections:[{id:"qopenhd",title:"QOpenHD / OSD",ready:true,selected:true},{id:"air",title:"Air",ready:true,selected:true},{id:"ground",title:"Ground",ready:false,selected:false}]}}
     function restoreBackup(path,parts){lastImport=path;selected=parts;message="Restoring";busy=true;progress=30;return true}
 }
 Rectangle {anchors.fill:parent;color:"#091827"}
 Pages.BackupRestorePopup {id:dialog}
 TestCase {
     name:"SettingsBackupPopup";when:windowShown
     function visualFind(item,name){
         if(item.objectName===name)return item
         if(item.children)for(var i=0;i<item.children.length;i++){var found=visualFind(item.children[i],name);if(found)return found}
         return null
     }
     function control(name){
         var found=findChild(dialog,name)||visualFind(dialog.contentItem,name)
         if(found)return found
         var picker=findChild(dialog,"settingsFilePicker")
         return picker?visualFind(picker.contentItem,name):null
     }
     function init(){_fleetControlLte.authenticated=false;_fleetControlLte.online=true;_settingsBackup.busy=false;_settingsBackup.message="";_settingsBackup.lastExport="";_settingsBackup.lastImport="";_settingsBackup.selected=[];dialog.open();tryCompare(dialog,"visible",true);wait(180)}
     function cleanup(){_settingsBackup.busy=false;var picker=control("settingsFilePicker");picker.close();dialog.close();wait(180)}
     function test_export_to_video_and_usb(){
         mouseClick(control("backupExport"));var picker=control("settingsFilePicker");tryCompare(picker,"opened",true);wait(100)
         compare(picker.directory,"/Video");picker.go("/media/usb");picker.filename="custom.ohdsettings";wait(100)
         grabImage(scene).save("build/backup-picker-export.png");mouseClick(control("backupChooseFile"));tryCompare(_settingsBackup,"lastExport","/media/usb/custom.ohdsettings");verify(settings.syncs>0)
     }
     function test_read_only_storage_hidden(){
         mouseClick(control("backupExport"));var picker=control("settingsFilePicker");verify(picker.volumes.every(function(v){return v.writable}));compare(picker.volumes.length,2);picker.go("/media/sd");wait(40)
         verify(!control("backupChooseFile").enabled);compare(_settingsBackup.lastExport,"")
     }
     function test_import_review_and_disabled_unit(){
         mouseClick(control("backupImport"));var picker=control("settingsFilePicker");picker.filename="saved.ohdsettings";picker.choose();tryCompare(dialog,"reviewing",true);wait(250)
         verify(dialog.reviewing);verify(!control("restoreSection_ground").enabled)
         compare(dialog.selectedSections.join(","),"qopenhd,air")
         wait(180);grabImage(scene).save("build/backup-restore-review.png");mouseClick(control("confirmSettingsRestore"));compare(_settingsBackup.lastImport,"/Video/saved.ohdsettings");compare(_settingsBackup.selected.join(","),"qopenhd,air");verify(!control("confirmSettingsRestore").enabled)
     }
     function test_cloud_requires_account_and_online_connection(){
         var save=control("saveFleetControlBackup");verify(!save.visible)
         _fleetControlLte.authenticated=true;wait(40);verify(save.visible);verify(save.enabled)
         _fleetControlLte.online=false;verify(!save.enabled)
         _fleetControlLte.authenticated=false;verify(!save.visible)
     }
     function test_file_picker_keeps_a_usable_file_list(){
         var sizes=[[1200,700],[760,480],[540,340],[440,600]]
         for(var i=0;i<sizes.length;i++){
             scene.width=sizes[i][0];scene.height=sizes[i][1];_settingsBackup.storageScanning=true
             control("backupExport").clicked();var picker=control("settingsFilePicker");tryCompare(picker,"visible",true);wait(180)
             verify(/^OpenHD-settings-\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.ohdsettings$/.test(picker.filename))
             var list=control("backupFileList");verify(list.height>=118,"File viewport too small: "+list.height)
             verify(picker.width<=scene.width);verify(picker.height<=scene.height)
             grabImage(scene).save("build/backup-picker-"+scene.width+"x"+scene.height+".png")
             picker.close();wait(180)
         }
         _settingsBackup.storageScanning=false;scene.width=1000;scene.height=750
     }
     function test_responsive_popup(){
         var sizes=[[1000,750],[640,480],[440,600]]
         for(var i=0;i<sizes.length;i++){
             scene.width=sizes[i][0];scene.height=sizes[i][1];wait(80)
             verify(dialog.width<=scene.width);verify(dialog.height<=scene.height)
             grabImage(scene).save("build/backup-popup-"+scene.width+".png")
         }
     }
 }
}
