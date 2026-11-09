import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../openhd_settings"
import ".."

FocusScope {
 id:root
 objectName:"generalSettingsPage"
 readonly property bool hybrid:settings.enable_hybrid
 readonly property int unitMode:hybrid?2:settings.enable_imperial?1:0
 readonly property var languages:[{text:qsTr("English (Default)"),locale:"en",flag:"../../../resources/flags/gb.svg"},{text:qsTr("Deutsch"),locale:"de",flag:"../../../resources/flags/de.svg"}]
 readonly property bool resetBlocked:(typeof _settingsBackup!=="undefined" && _settingsBackup.busy) || (typeof _qopenhd!=="undefined" && _qopenhd.debugMenuPreview===true) || (typeof _uiSimulator!=="undefined" && _uiSimulator.active) || (typeof _fcMavlinkSystem!=="undefined" && _fcMavlinkSystem.armed)
 readonly property var resetBackend:typeof _ohdAction!=="undefined"?_ohdAction:null
 property string resetTarget:""
 property string resetStatus:""
 function resetAvailable(target) {
  if(resetBlocked || (resetBackend && (resetBackend.settingsResetBusy || resetBackend.powerActionBusy)))return false
  if(target==="qopenhd")return typeof _qopenhd!=="undefined"
  return resetBackend && (target==="ground" ? typeof _ohdSystemGround!=="undefined" && _ohdSystemGround.is_alive : typeof _ohdSystemAir!=="undefined" && _ohdSystemAir.is_alive)
 }
 function openReset(target) {if(!resetAvailable(target))return;resetTarget=target;resetConfirm.open()}
 function confirmReset() {
  if(!resetAvailable(resetTarget)){resetStatus=qsTr("Reset unavailable.");return}
  if(resetTarget==="qopenhd") {
   if(_qopenhd.reset_settings())_restartqopenhdmessagebox.show_with_text(qsTr("All QOpenHD settings will reset when QOpenHD restarts."))
   else resetStatus=qsTr("Could not schedule QOpenHD settings reset.")
  } else {
   var result=resetBackend.request_settings_reset(resetTarget==="ground")
   resetStatus=result==="queued"?qsTr("Waiting for reset acknowledgement..."):qsTr("Reset unavailable: %1").arg(result)
  }
 }
 Connections {
  target:root.resetBackend
  function onSettingsResetFinished(ground,result) {
   var name=ground?qsTr("OpenHD Ground"):qsTr("OpenHD Air")
   root.resetStatus=result==="accepted"?qsTr("%1 accepted the reset and will reboot.").arg(name):result==="unsupported"?qsTr("Update OpenHD and SysUtils on %1 to support settings reset.").arg(name):(result==="unconfirmed" || result==="failed")?qsTr("No reset acknowledgement from %1. Check the unit before retrying.").arg(name):qsTr("%1 rejected the reset.").arg(name)
  }
 }
 AdvancedDialog {
  id:resetConfirm;objectName:"generalResetConfirm"
  parent:Overlay.overlay
  anchors.centerIn:parent
  width:Math.min(440,parent?parent.width-24:440)
  title:qsTr("Reset all settings?")
  contentItem:Text {
   text:root.resetTarget==="qopenhd"?qsTr("Reset all QOpenHD application and OSD settings on restart?"):qsTr("Reset all settings on %1 and reboot it? The link may disconnect.").arg(root.resetTarget==="ground"?qsTr("OpenHD Ground"):qsTr("OpenHD Air"))
   color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap
  }
  footer:Item {
   implicitHeight:Typography.controlHeight+32
   RowLayout {
    anchors.fill:parent;anchors.margins:16;spacing:10
    AdvancedActionButton {objectName:"generalResetCancel";Layout.fillWidth:true;text:qsTr("Cancel");onClicked:resetConfirm.reject()}
    AdvancedActionButton {objectName:"generalResetAccept";Layout.fillWidth:true;text:qsTr("Reset");destructive:true;enabled:root.resetAvailable(root.resetTarget);onClicked:{resetConfirm.close();root.confirmReset()}}
   }
  }
 }
 function gainFocus(){language.forceActiveFocus()}
 function setUnits(mode){settings.enable_hybrid=mode===2;settings.enable_imperial=mode===1}
 Flickable {
  id:scroll;objectName:"generalPageScroll";anchors.fill:parent;anchors.margins:10
  contentWidth:width;contentHeight:cards.height;clip:true;boundsBehavior:Flickable.StopAtBounds
  Column {
   id:cards;width:scroll.width;spacing:14
   GeneralSettingsCard {
    width:parent.width;height:implicitHeight;title:qsTr("Language");hint:qsTr("Select the application language.");icon:"\uf0ac";controlWidth:360
    headerControls:CompactLinkComboBox {
     id:language;objectName:"generalLanguage";anchors.fill:parent;topInset:0;bottomInset:0
     model:root.languages;textRole:"text";currentIndex:settings.locale==="de"?1:0;optionIcon:"\uf0ac"
     font.pixelSize:Typography.body;leftPadding:16;rightPadding:35
     contentItem:Item {
      Image {id:flag;width:28;height:19;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;source:root.languages[language.currentIndex>=0?language.currentIndex:0].flag;fillMode:Image.PreserveAspectFit}
      Text {anchors.left:flag.right;anchors.leftMargin:14;anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;text:language.currentText;font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.primaryText;elide:Text.ElideRight}
     }
     onActivated:{settings.locale=model[currentIndex].locale;_qopenhd.switchToLanguage(settings.locale);_restartqopenhdmessagebox.show_with_text(qsTr("Language change will apply after restart."))}
    }
   }
   GeneralSettingsCard {
    id:unitsCard;width:parent.width;height:implicitHeight;title:qsTr("Units");hint:qsTr("Choose the units used throughout the application.");icon:"\uf546";controlWidth:450
    headerControls:RowLayout {anchors.fill:parent;spacing:0
     MapActionButton {objectName:"generalMetric";Layout.fillWidth:true;Layout.fillHeight:true;text:qsTr("Metric");primary:root.unitMode===0;onClicked:root.setUnits(0)}
     MapActionButton {objectName:"generalImperial";Layout.fillWidth:true;Layout.fillHeight:true;text:qsTr("Imperial");primary:root.unitMode===1;onClicked:root.setUnits(1)}
     MapActionButton {objectName:"generalHybrid";Layout.fillWidth:true;Layout.fillHeight:true;text:qsTr("Hybrid");primary:root.unitMode===2;onClicked:root.setUnits(2)}
    }
    Rectangle {
     width:parent.width;height:width<700?218:132;radius:9;color:settings_form.darkMode?"#09273d":settings_form.panelBackground;border.color:settings_form.lineColor
     Rectangle {width:5;height:parent.height-2;x:1;y:1;radius:2;color:settings_form.accentColor}
     Column {x:28;y:22;width:parent.width<700?parent.width-50:parent.width-360;spacing:7
      Text {text:root.unitMode===0?qsTr("Metric Units"):root.unitMode===1?qsTr("Imperial Units"):qsTr("Hybrid Units");font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;color:settings_form.accentColor}

     }
     Column {
      x:parent.width<700?28:parent.width-310;y:parent.width<700?112:22;width:Math.min(280,parent.width-55);spacing:12
      Repeater {
       model:[{icon:"\uf546",label:qsTr("Distance"),value:root.unitMode===1?"0.7 mi":"1.2 km"},{icon:"\uf3fd",label:qsTr("Speed"),value:root.unitMode===1?"45 mph":"72 km/h"},{icon:"\uf6fc",label:qsTr("Altitude"),value:root.unitMode===0?"250 m":"820 ft"}]
       delegate:RowLayout {width:parent.width;spacing:14
        Text {text:modelData.icon;color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.rowIcon;Layout.preferredWidth:28}
        Text {Layout.fillWidth:true;text:modelData.label;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
        Text {objectName:"generalUnitExample"+index;Layout.preferredWidth:90;text:modelData.value;color:settings_form.accentColor;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
       }
      }
     }
    }
   }
   GeneralSettingsCard {
    width:parent.width;height:implicitHeight;title:qsTr("Show advanced settings");icon:"\uf1de";controlWidth:48
    hint:qsTr("Show additional OpenHD options and the Audio page in the left sidebar.")
    headerControls:WidgetToggle {
     objectName:"generalAdvancedSettings"
     anchors.fill:parent
     checked:settings.dev_show_advanced_button
     onToggled:{settings.dev_show_whitelisted_params=checked;settings.dev_show_advanced_button=checked}
    }
   }
   GeneralSettingsCard {
    width:parent.width;height:implicitHeight;title:qsTr("Reset all settings");icon:"\uf2ea";controlWidth:0
    Column {
     width:parent.width;spacing:4
     Repeater {
      model:[{key:"qopenhd",label:"QOpenHD"},{key:"air",label:"OpenHD Air"},{key:"ground",label:"OpenHD Ground"}]
      RowLayout {
       width:parent.width;height:Typography.rowHeight
       Text {Layout.fillWidth:true;text:modelData.label;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
       AdvancedActionButton {objectName:"generalReset_"+modelData.key;text:qsTr("Reset");destructive:true;enabled:root.resetAvailable(modelData.key);onClicked:root.openReset(modelData.key)}
      }
     }
     Text {objectName:"generalResetStatus";width:parent.width;visible:root.resetStatus.length>0;text:root.resetStatus;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap}
    }
   }
   GeneralSettingsCard {
    width:parent.width;height:implicitHeight;title:qsTr("Wi-Fi temperature alarm");icon:"\uf071";controlWidth:48
    hint:qsTr("Play a repeating warning tone when an Air or Ground radio is hot or overheating. Independent of speech and video audio. The visual warning is always enabled.")
    headerControls:WidgetToggle {objectName:"wifiTemperatureAlarmSound";anchors.fill:parent;checked:settings.wifi_temperature_alarm_sound;onToggled:settings.wifi_temperature_alarm_sound=checked}
   }
  }
 }
}
