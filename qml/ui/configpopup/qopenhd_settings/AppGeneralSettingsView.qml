import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../openhd_settings"

FocusScope {
 id:root
 objectName:"generalSettingsPage"
 readonly property bool hybrid:settings.enable_hybrid
 readonly property int unitMode:hybrid?2:settings.enable_imperial?1:0
 readonly property bool speechAvailable:typeof _qopenhd!=="undefined"&&_qopenhd.speechAvailable===true
 readonly property var languages:[{text:qsTr("English (Default)"),locale:"en",flag:"../../../resources/flags/gb.svg"},{text:qsTr("Deutsch"),locale:"de",flag:"../../../resources/flags/de.svg"}]
 readonly property var voiceNames:typeof _qopenhd!=="undefined"&&_qopenhd.speechVoices?_qopenhd.speechVoices:[]
 readonly property var voiceOptions:[qsTr("System Default")].concat(voiceNames)
 function gainFocus(){language.forceActiveFocus()}
 function setUnits(mode){settings.enable_hybrid=mode===2;settings.enable_imperial=mode===1}
 function updateSpeech(){if(speechAvailable)_qopenhd.configureSpeech(settings.speech_voice,settings.speech_rate,settings.speech_volume)}
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
      Text {width:parent.width;text:root.unitMode===0?qsTr("Distance in meters and kilometers, speed in km/h, altitude in meters."):root.unitMode===1?qsTr("Distance in feet and miles, speed in mph, altitude in feet."):qsTr("Distance in meters and kilometers, speed in km/h, altitude in feet.");font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.secondaryText;wrapMode:Text.WordWrap}
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
    width:parent.width;height:implicitHeight;title:qsTr("Text to Speech");hint:qsTr("Read important events and alerts aloud.");icon:"\uf028";controlWidth:48
    headerControls:WidgetToggle {objectName:"generalSpeechEnabled";anchors.fill:parent;checked:settings.enable_speech;enabled:root.speechAvailable;onToggled:settings.enable_speech=checked}
    Rectangle {
     width:parent.width;height:speechRows.height;radius:9;color:"transparent";border.color:settings_form.lineColor
     Column {
      id:speechRows;width:parent.width
      Repeater {
       model:3
       delegate:Item {
        width:parent.width;height:width<640?98:Typography.rowHeight
        Text {x:18;y:parent.width<640?15:(parent.height-height)/2;text:index===0?qsTr("Voice"):index===1?qsTr("Speech Rate"):qsTr("Volume");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
        Item {
         width:parent.width<640?parent.width-36:Math.min(450,parent.width*0.48);height:Typography.controlHeight;x:parent.width-width-18;y:parent.width<640?50:(parent.height-height)/2
         CompactLinkComboBox {
          objectName:"generalSpeechVoice";anchors.fill:parent;visible:index===0;topInset:0;bottomInset:0;optionIcon:"\uf550";font.pixelSize:Typography.body
          model:root.voiceOptions;currentIndex:Math.max(0,root.voiceNames.indexOf(settings.speech_voice)+1);enabled:root.speechAvailable&&settings.enable_speech
          onActivated:{settings.speech_voice=currentIndex===0?"":root.voiceNames[currentIndex-1];root.updateSpeech()}
         }
         MapValueSlider {objectName:"generalSpeechRate";anchors.fill:parent;visible:index===1;from:0.5;to:2;stepSize:0.05;value:settings.speech_rate;displayText:Math.round(value*100)+"%";enabled:root.speechAvailable&&settings.enable_speech;onMoved:{settings.speech_rate=value;root.updateSpeech()}}
         MapValueSlider {objectName:"generalSpeechVolume";anchors.fill:parent;visible:index===2;from:0;to:1;stepSize:0.01;value:settings.speech_volume;displayText:Math.round(value*100)+"%";enabled:root.speechAvailable&&settings.enable_speech;onMoved:{settings.speech_volume=value;root.updateSpeech()}}
        }
        Rectangle {visible:index>0;width:parent.width;y:0;height:1;color:settings_form.lineColor}
       }
      }
     }
    }
    Text {width:parent.width;visible:!root.speechAvailable;text:qsTr("No speech engine is available in this installation.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
   }
   GeneralSettingsCard {
    width:parent.width;height:implicitHeight;title:qsTr("Wi-Fi temperature alarm");icon:"\uf071";controlWidth:48
    hint:qsTr("Play a repeating warning tone when an Air or Ground radio is hot or overheating. Independent of speech and video audio. The visual warning is always enabled.")
    headerControls:WidgetToggle {objectName:"wifiTemperatureAlarmSound";anchors.fill:parent;checked:settings.wifi_temperature_alarm_sound;onToggled:settings.wifi_temperature_alarm_sound=checked}
   }
  }
 }
}
