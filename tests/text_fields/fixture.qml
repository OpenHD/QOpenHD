import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
Item {
 id:scene;width:1200;height:650
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property bool darkMode:true;property bool showAdvancedSettings:false;property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true}
 QtObject {id:_messageBoxInstance;function set_text_and_show(message){}}
 QtObject {id:_ohdSystemAirSettingsModel;property int update_count:0;function param_int_exists(id){return false}function get_cached_int(id){return 0}}
 QtObject {id:params;property int update_count:0;property bool has_params_fetched:true;function get_cached_string(id){return id==="IP_CAM_ADDRESS"?"192.168.1.12":"rtspsrc location=rtsp://{IP}:554/stream=0 protocols=tcp latency=0 ! rtp{CODEC}depay"}function try_set_param_string_async(id,value,confirm){}}
 Rectangle {anchors.fill:parent;color:"#091827"}
 Pages.CameraConnectionPanel {id:panel;anchors.fill:parent;settingsModel:params}
 TestCase {
  name:"TextFieldAlignment";when:windowShown
  function test_rtsp_fields_are_centered_and_padded(){
   wait(100)
   var names=["addressField","portField","pathField"];for(var i=0;i<names.length;i++){var name=names[i];
    var field=findChild(panel,"rtsp_"+name);verify(field!==null)
    compare(field.verticalAlignment,TextInput.AlignVCenter);verify(field.leftPadding>=12);verify(field.rightPadding>=12)
    verify(Math.abs(field.topPadding-field.bottomPadding)<=1)
   }
   grabImage(scene).save("build/rtsp-text-fields-aligned.png")
  }
 }
}
