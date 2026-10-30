import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
Item {
 id:scene;width:1500;height:1000
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:testCapabilities;property bool mobile:false;property bool avcodec:true;property bool gstreamer:false;property bool nativeVideo:false;property bool androidVideo:false;property bool audio:true}
 QtObject {id:settings_form;property bool showDeveloperSettings:false;property bool showAdvancedSettings:false;property bool darkMode:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color errorColor:"red"}
 QtObject {id:_qopenhd;property string platform:"windows";function is_linux(){return platform==="linux"||platform==="rpi"||platform==="rock"||platform==="nxp"} function is_android(){return platform==="android"} function is_platform_rpi(){return platform==="rpi"} function is_platform_rock(){return platform==="rock"}}
 QtObject {id:_restartqopenhdmessagebox;property int requests:0;function show(){requests++}}
 QtObject {id:_audioControl;property bool playing:false;property int changes:0;function setPlaybackEnabled(enabled){playing=enabled;changes++}}
 QtObject {id:_mouseHelper;property bool hidden:false;property int cursor:0;property int size:1;function set_hide_cursor_inactive_enable(enabled){hidden=enabled} function set_active_cursor_type_and_scale(type,scale){cursor=type;size=scale}}
 QtObject {
  id:settings
  property bool secondary_camera_available:false
  property bool primary_video_scale_to_fit:false
  property bool qopenhd_switch_primary_secondary:false
  property bool dev_enable_live_audio_playback:false
  property int qopenhd_primary_video_codec:0
  property int qopenhd_secondary_video_codec:0
  property bool qopenhd_primary_video_force_sw:false
  property bool qopenhd_secondary_video_force_sw:false
  property int qopenhd_primary_video_rtp_input_port:5600
  property int qopenhd_secondary_video_rtp_input_port:5601
  property int dev_secondary_video_input_mode:0
  property bool dev_disable_primary_video:false
  property int dev_test_video_mode:0
  property int dev_limit_fps_on_test_file:-1
  property bool dev_use_low_latency_parser_when_possible:true
  property bool dev_rpi_use_external_omx_decode_service:true
  property bool dev_always_use_generic_external_decode_service:false
  property bool enable_kms_renderer:false
  property real global_scale:1.0
  property bool enable_cursor_auto_hide:false
  property int custom_cursor_type:0
  property int custom_cursor_scale:1
  property int general_screen_rotation:0
  property bool dev_force_show_full_screen:false
  property bool screen_settings_openhd_parameters_transparent:false
  property bool app_background_transparent:true
  property bool dev_set_swap_interval_zero:false
  property int screen_custom_font_dpi:0
 }
 Rectangle {anchors.fill:parent;color:settings_form.pageBackground}
 readonly property var page:pageLoader.item
 readonly property var defaults:({secondary_camera_available:false,primary_video_scale_to_fit:false,qopenhd_switch_primary_secondary:false,dev_enable_live_audio_playback:false,qopenhd_primary_video_codec:0,qopenhd_secondary_video_codec:0,qopenhd_primary_video_force_sw:false,qopenhd_secondary_video_force_sw:false,qopenhd_primary_video_rtp_input_port:5600,qopenhd_secondary_video_rtp_input_port:5601,dev_secondary_video_input_mode:0,dev_disable_primary_video:false,dev_test_video_mode:0,dev_limit_fps_on_test_file:-1,dev_use_low_latency_parser_when_possible:true,dev_rpi_use_external_omx_decode_service:true,dev_always_use_generic_external_decode_service:false,enable_kms_renderer:false,global_scale:1.0,enable_cursor_auto_hide:false,custom_cursor_type:0,custom_cursor_scale:1,general_screen_rotation:0,dev_force_show_full_screen:false,screen_settings_openhd_parameters_transparent:false,app_background_transparent:true,dev_set_swap_interval_zero:false,screen_custom_font_dpi:0})
 Component {id:pageComponent;Pages.AppVideoSettingsView {anchors.fill:parent}}
 Loader {id:pageLoader;anchors.fill:parent;sourceComponent:pageComponent}
 TestCase {
  name:"VideoSettings";when:windowShown
  function find(item,name){if(item.objectName===name)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var result=find(children[i],name);if(result)return result}return null}
  function isShown(name){var item=find(page,name);return item!==null&&item.visible}
  function toggle(name,enabled){var item=find(page,name);verify(item!==null,name);item.checked=enabled;item.toggled()}
  function choice(name,index){var item=find(page,name);verify(item!==null,name);item.currentIndex=index;item.activated(index)}
  function init(){
   pageLoader.active=false
   Object.keys(scene.defaults).forEach(function(key){settings[key]=scene.defaults[key]})
   scene.Window.window.width=1500;scene.Window.window.height=1000;scene.width=1500;scene.height=1000
   settings_form.showDeveloperSettings=false;settings_form.showAdvancedSettings=false;_qopenhd.platform="windows"
   testCapabilities.mobile=false;testCapabilities.avcodec=true;testCapabilities.gstreamer=false;testCapabilities.nativeVideo=false;testCapabilities.androidVideo=false;testCapabilities.audio=true
   settings.secondary_camera_available=false;settings.dev_always_use_generic_external_decode_service=false;settings.dev_rpi_use_external_omx_decode_service=true;settings.dev_test_video_mode=0
   pageLoader.active=true;tryCompare(pageLoader,"status",Loader.Ready);find(page,"videoSettingsScroll").contentY=0;wait(100)
  }
  function test_normal_and_two_streams(){
   verify(isShown("videoFit"));verify(!isShown("videoAudio"));verify(!isShown("videoSwap"));verify(!isShown("videoDecoderGroup"));verify(!isShown("videoNetworkGroup"));verify(!isShown("videoRotation"));verify(!isShown("videoTransparentBackground"))
   settings.secondary_camera_available=true;verify(isShown("videoSwap"));toggle("videoSwap",true);compare(settings.qopenhd_switch_primary_secondary,true)
   settings.secondary_camera_available=false;verify(!isShown("videoSwap"));compare(settings.qopenhd_switch_primary_secondary,true)
   toggle("videoFit",true);compare(settings.primary_video_scale_to_fit,true)
   verify(!isShown("videoAudio"));verify(!isShown("videoPlaybackGroup"))
   compare(settings.dev_enable_live_audio_playback,false)
  }
  function test_advanced_and_collapse_preserves_access(){
   settings_form.showAdvancedSettings=true;wait(50);verify(isShown("videoDecoderGroup"));verify(isShown("videoRotation"));verify(isShown("videoFullscreen"));verify(!isShown("videoSecondaryCodec"));verify(!isShown("videoPrimaryPort"))
   choice("videoPrimaryCodec",1);compare(settings.qopenhd_primary_video_codec,1)
   toggle("videoSoftware",true);compare(settings.qopenhd_primary_video_force_sw,true);compare(settings.qopenhd_secondary_video_force_sw,true)
   settings.secondary_camera_available=true;verify(isShown("videoSecondaryCodec"));choice("videoSecondaryCodec",1);compare(settings.qopenhd_secondary_video_codec,1)
   settings.secondary_camera_available=false
   var group=find(page,"videoDecoderGroup");group.expanded=false;group.expanded=true
   verify(!isShown("videoSecondaryCodec"));verify(!isShown("videoPrimaryPort"));compare(settings.qopenhd_secondary_video_codec,1)
   settings_form.showAdvancedSettings=false;verify(!isShown("videoDecoderGroup"));verify(!isShown("videoRotation"));compare(settings.qopenhd_primary_video_codec,1)
  }
  function test_developer_platform_guards_and_numbers(){
   settings_form.showDeveloperSettings=true;wait(50)
   verify(isShown("videoPrimaryPort"));verify(isShown("videoParser"));verify(!isShown("videoSecondaryPort"));verify(!isShown("videoAndroidInput"));verify(!isShown("videoRpiDecode"));verify(!isShown("videoExternalDecode"));verify(!isShown("videoKms"));verify(!isShown("videoTestFps"))
   var port=find(page,"videoPrimaryPort");compare(port.from,1);compare(port.to,6900);port.commit(5700);compare(settings.qopenhd_primary_video_rtp_input_port,5700);port.commit(9999);compare(settings.qopenhd_primary_video_rtp_input_port,6900)
   find(page,"videoPrimaryPortDecrease").clicked();compare(settings.qopenhd_primary_video_rtp_input_port,6899)
   var input=find(page,"videoPrimaryPortInput");input.text="6200";input.editingFinished();compare(settings.qopenhd_primary_video_rtp_input_port,6200)
   input.text="invalid";input.editingFinished();compare(settings.qopenhd_primary_video_rtp_input_port,6200);compare(input.text,"6200")
   choice("videoTestMode",1);verify(isShown("videoTestFps"));var fps=find(page,"videoTestFps");fps.commit(60);compare(settings.dev_limit_fps_on_test_file,60);fps.commit(-2);compare(settings.dev_limit_fps_on_test_file,-1)
   _qopenhd.platform="rpi";verify(isShown("videoRpiDecode"));verify(isShown("videoExternalDecode"));verify(!isShown("videoSoftware"));verify(!isShown("videoFit"));verify(!isShown("videoParser"));verify(!isShown("videoKms"))
   toggle("videoRpiDecode",false);verify(isShown("videoSoftware"));verify(isShown("videoKms"));toggle("videoKms",true);compare(settings.enable_kms_renderer,true)
   _qopenhd.platform="android";testCapabilities.avcodec=false;testCapabilities.androidVideo=true;testCapabilities.mobile=true;settings.secondary_camera_available=true
   verify(isShown("videoAndroidInput"));verify(isShown("videoDisablePrimary"));verify(!isShown("videoParser"));verify(!isShown("videoCursorStyle"));verify(!isShown("videoFullscreen"));verify(!isShown("videoSwapInterval"));verify(!isShown("videoTestMode"))
   choice("videoAndroidInput",2);compare(settings.dev_secondary_video_input_mode,2);toggle("videoDisablePrimary",true);compare(settings.dev_disable_primary_video,true)
  }
  function test_native_and_no_backend(){
   settings_form.showDeveloperSettings=true;testCapabilities.avcodec=false;testCapabilities.nativeVideo=true;_qopenhd.platform="nxp";wait(50)
   verify(isShown("videoFit"));verify(isShown("videoPrimaryCodec"));verify(!isShown("videoSoftware"));verify(!isShown("videoParser"));verify(!isShown("videoRpiDecode"));verify(!isShown("videoKms"));verify(!isShown("videoDiagnosticsGroup"));verify(!isShown("videoPlatformGroup"));verify(!isShown("videoTransparentBackground"))
   testCapabilities.nativeVideo=false;testCapabilities.audio=false
   verify(!isShown("videoPlaybackGroup"));verify(!isShown("videoDecoderGroup"));verify(!isShown("videoNetworkGroup"));verify(isShown("videoDisplayGroup"))
  }
  function test_display_settings_and_existing_values(){
   settings.custom_cursor_type=7;settings.custom_cursor_scale=6;wait(30)
   compare(find(page,"videoCursorStyle").currentText,"White hand");compare(find(page,"videoCursorSize").currentText,"Small (16 px)");compare(settings.custom_cursor_type,7);compare(settings.custom_cursor_scale,6)
   choice("videoCursorStyle",2);compare(settings.custom_cursor_type,2);compare(_mouseHelper.cursor,2)
   choice("videoCursorSize",2);compare(settings.custom_cursor_scale,2);compare(_mouseHelper.size,2)
   toggle("videoAutoHide",true);compare(settings.enable_cursor_auto_hide,true);compare(_mouseHelper.hidden,true)
   var scale=find(page,"videoAppScale"),before=_restartqopenhdmessagebox.requests;scale.value=1.2;scale.moved();compare(settings.global_scale,1.2);compare(_restartqopenhdmessagebox.requests,before+1)
   settings_form.showAdvancedSettings=true;choice("videoRotation",2);compare(settings.general_screen_rotation,180);toggle("videoFullscreen",true);compare(settings.dev_force_show_full_screen,true);toggle("videoTransparentSettings",true);compare(settings.screen_settings_openhd_parameters_transparent,true)
   settings_form.showDeveloperSettings=true;choice("videoFontDpi",4);compare(settings.screen_custom_font_dpi,100);toggle("videoTransparentBackground",false);compare(settings.app_background_transparent,false);toggle("videoSwapInterval",true);compare(settings.dev_set_swap_interval_zero,true)
  }
  function test_no_writes_when_recreating_or_changing_access(){
   pageLoader.active=false
   settings.qopenhd_primary_video_codec=2;settings.qopenhd_primary_video_rtp_input_port=5800;settings.dev_secondary_video_input_mode=2;settings.dev_limit_fps_on_test_file=125
   settings_form.showDeveloperSettings=true;pageLoader.active=true;tryCompare(pageLoader,"status",Loader.Ready);wait(50);compare(find(page,"videoPrimaryCodec").currentText,"MJPEG")
   settings_form.showDeveloperSettings=false;settings_form.showAdvancedSettings=true;scene.width=800;wait(50);scene.width=1500;wait(50)
   compare(settings.qopenhd_primary_video_codec,2);compare(settings.qopenhd_primary_video_rtp_input_port,5800);compare(settings.dev_secondary_video_input_mode,2);compare(settings.dev_limit_fps_on_test_file,125)
  }
  function test_normal_layout_geometry(){
   var sizes=[[1568,704],[1176,528],[1500,1000],[850,650],[420,650]]
   for(var i=0;i<sizes.length;i++){
    scene.Window.window.width=sizes[i][0];scene.Window.window.height=sizes[i][1];scene.width=sizes[i][0];scene.height=sizes[i][1]
    pageLoader.active=false;scene.width=0;pageLoader.active=true;tryCompare(pageLoader,"status",Loader.Ready);scene.width=sizes[i][0];wait(100)
    var display=find(page,"videoDisplayGroup")
    var names=["videoFitRow","videoAppScaleRow","videoAutoHideRow","videoCursorStyleRow","videoCursorSizeRow"],bounds=[]
    for(var j=0;j<names.length;j++){
     var row=find(page,names[j]);verify(row.visible)
     var point=row.mapToItem(display,0,0)
     verify(row.width>150,"Zero-width display row at "+sizes[i][0]+": "+names[j])
     verify(point.y+row.height<=display.height+1,"Row exceeds display card: "+names[j]+" y="+point.y+" height="+row.height+" card="+display.height)
     for(var k=0;k<bounds.length;k++){
      var b=bounds[k]
      verify(point.x+row.width<=b.x+1||point.x>=b.x+b.w-1||point.y+row.height<=b.y+1||point.y>=b.y+b.h-1,"Display rows overlap: "+names[j])
     }
     bounds.push({x:point.x,y:point.y,w:row.width,h:row.height})
    }
    grabImage(scene).save("build/video-normal-"+sizes[i][0]+".png")
   }
  }
  function test_responsive_capture(){
   settings_form.showDeveloperSettings=true;settings.secondary_camera_available=true;_qopenhd.platform="linux";settings.dev_rpi_use_external_omx_decode_service=false;settings.qopenhd_primary_video_codec=0;settings.qopenhd_secondary_video_codec=0
   wait(150);grabImage(scene).save("build/video-settings-wide.png")
   var scroll=find(page,"videoSettingsScroll");scroll.contentY=Math.max(0,scroll.contentHeight-scroll.height);wait(100);grabImage(scene).save("build/video-settings-display.png");scroll.contentY=0
   for(var width of [850,420]){
    scene.Window.window.width=width;scene.Window.window.height=650;scene.width=width;scene.height=650;wait(100)
    compare(page.twoColumns,false);verify(find(page,"videoSettingsScroll").contentHeight>650)
    grabImage(scene).save("build/video-settings-"+width+".png")
   }
  }
 }
}
