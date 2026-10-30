import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
Item {
 id:scene;width:1600;height:900
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb";property color accentColor:"#278cff"}
 QtObject {id:settings;property string locale:"en";property bool enable_imperial:false;property bool enable_hybrid:false;property bool enable_speech:true;property string speech_voice:"";property real speech_rate:1;property real speech_volume:1;property bool wifi_temperature_alarm_sound:true}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false;property int resets:0;function reset_settings(){resets++;return true} property bool speechAvailable:true;property var speechVoices:["Voice One","Voice Two"];property string selectedLanguage:"";property string selectedVoice:"";property real rate:1;property real volume:1;function switchToLanguage(locale){selectedLanguage=locale} function configureSpeech(voice,r,v){selectedVoice=voice;rate=r;volume=v}}
 QtObject {id:_restartqopenhdmessagebox;property string message:"";function show_with_text(text){message=text}}
 QtObject {id:_uiSimulator;property bool active:false}
 QtObject {id:_fcMavlinkSystem;property bool armed:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true}
 QtObject {id:_ohdSystemGround;property bool is_alive:true}
 QtObject {id:_ohdAction;property bool settingsResetBusy:false;property bool powerActionBusy:false;property int resets:0;property bool lastGround:false;signal settingsResetFinished(bool ground,string result);function request_settings_reset(ground){resets++;lastGround=ground;return "queued"}}
 Rectangle {anchors.fill:parent;color:settings_form.pageBackground}
 Pages.AppGeneralSettingsView {id:page;anchors.fill:parent}
 TestCase {
  name:"GeneralSettings";when:windowShown
  function visual(item,name){if(item.objectName===name&&item.visible)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var child=visual(children[i],name);if(child)return child}return null}
  function init(){scene.Window.window.width=1600;scene.Window.window.height=900;scene.width=1600;scene.height=900;settings.enable_imperial=false;settings.enable_hybrid=false;settings.enable_speech=true;_qopenhd.speechAvailable=true;visual(page,"generalPageScroll").contentY=0;wait(80)}
  function test_reset_controls_confirm_and_target(){
   var air=findChild(page,"generalReset_air"),ground=findChild(page,"generalReset_ground"),local=findChild(page,"generalReset_qopenhd")
   verify(air!==null);verify(ground!==null);verify(local!==null)
   var before=_ohdAction.resets
   page.openReset("air");wait(20);findChild(page,"generalResetCancel").clicked();compare(_ohdAction.resets,before)
   page.openReset("air");wait(20);findChild(page,"generalResetAccept").clicked();compare(_ohdAction.resets,before+1);compare(_ohdAction.lastGround,false)
   page.openReset("ground");wait(20);findChild(page,"generalResetAccept").clicked();compare(_ohdAction.lastGround,true)
   _ohdAction.settingsResetFinished(true,"unsupported");verify(page.resetStatus.indexOf("Update OpenHD")>=0)
   _ohdSystemAir.is_alive=false;verify(!air.enabled);verify(ground.enabled)
   _ohdSystemAir.is_alive=true
   _fcMavlinkSystem.armed=true;verify(!air.enabled);verify(!ground.enabled);verify(!local.enabled)
   _fcMavlinkSystem.armed=false
   _uiSimulator.active=true;verify(!local.enabled);verify(!air.enabled);_uiSimulator.active=false
   _qopenhd.debugMenuPreview=true;verify(!local.enabled);_qopenhd.debugMenuPreview=false
   var count=_qopenhd.resets;page.openReset("qopenhd");wait(20);findChild(page,"generalResetAccept").clicked();compare(_qopenhd.resets,count+1)
   verify(_restartqopenhdmessagebox.message.indexOf("restart")>=0)
  }
  function test_units_are_functional(){
   mouseClick(visual(page,"generalImperial"));compare(settings.enable_imperial,true);compare(settings.enable_hybrid,false);compare(visual(page,"generalUnitExample2").text,"820 ft")
   mouseClick(visual(page,"generalHybrid"));compare(settings.enable_imperial,false);compare(settings.enable_hybrid,true);compare(visual(page,"generalUnitExample0").text,"1.2 km");compare(visual(page,"generalUnitExample2").text,"820 ft")
   mouseClick(visual(page,"generalMetric"));compare(settings.enable_imperial,false);compare(settings.enable_hybrid,false);compare(visual(page,"generalUnitExample2").text,"250 m")
  }
  function test_language(){var language=visual(page,"generalLanguage");language.currentIndex=1;language.activated(1);compare(settings.locale,"de");compare(_qopenhd.selectedLanguage,"de");verify(_restartqopenhdmessagebox.message.length>0);language.currentIndex=0;language.activated(0)}
  function test_speech_controls(){
   var voice=visual(page,"generalSpeechVoice");voice.currentIndex=2;voice.activated(2);compare(settings.speech_voice,"Voice Two");compare(_qopenhd.selectedVoice,"Voice Two")
   var rate=visual(page,"generalSpeechRate");rate.value=1.25;rate.moved();compare(settings.speech_rate,1.25);compare(_qopenhd.rate,1.25)
   var volume=visual(page,"generalSpeechVolume");volume.value=0.6;volume.moved();compare(settings.speech_volume,0.6);compare(_qopenhd.volume,0.6)
   mouseClick(visual(page,"generalSpeechEnabled"));compare(settings.enable_speech,false);compare(voice.enabled,false)
   _qopenhd.speechAvailable=false;compare(visual(page,"generalSpeechEnabled").enabled,false)
  }
  function test_responsive_capture(){
   settings.speech_voice="";settings.speech_rate=1;settings.speech_volume=1
   wait(100);grabImage(scene).save("build/general-settings-wide.png")
   var widths=[800,420]
   for(var i=0;i<widths.length;i++){
    scene.Window.window.width=widths[i];scene.Window.window.height=650;scene.width=widths[i];scene.height=650;wait(100)
    var language=visual(page,"generalLanguage"),button=visual(page,"generalHybrid")
    verify(language.width<=page.width);verify(button.x+button.width<=button.parent.width+1)
    grabImage(scene).save("build/general-settings-"+widths[i]+".png")
   }
  }
 }
}
