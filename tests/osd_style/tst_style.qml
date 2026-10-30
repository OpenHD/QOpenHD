import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
Item {
    id:scene;width:1600;height:900
    FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
    FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
    FontLoader {source:"../../qml/osdfonts/Quicksand-Regular.ttf"}
    FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
    QtObject {id:settings_form;property bool darkMode:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb";property color accentColor:"#278cff"}
    QtObject {
        id:settings
        property int smoothing:33
        property string color_shape:"white"
        property string color_text:"white"
        property string color_glow:"black"
        property string color_warn:"red"
        property string color_caution:"yellow"
        property string font_text:"Sans Serif"
        property real osd_opacity:1.0
        property string link_overview_widget_bg_color:"#000000"
        property string osd_top_bar_background_color:""
        property string osd_top_bar_text_color:""
        property string osd_top_bar_font:""
        property string osd_bottom_bar_background_color:""
        property string osd_bottom_bar_text_color:""
        property string osd_bottom_bar_font:""
    }
    QtObject {id:hudOverlayGrid;readonly property Item osdStylePreviewItem:actualOsd}
    Item {
        id:actualOsd;width:1280;height:720;visible:false;opacity:settings.osd_opacity
        Text {x:20;y:20;text:"12.4 V";font.family:settings.font_text;font.pixelSize:30;color:settings.color_text;style:Text.Outline;styleColor:settings.color_glow}
        Text {anchors.centerIn:parent;text:"+";font.pixelSize:70;color:settings.color_shape}
        Text {anchors.right:parent.right;anchors.rightMargin:20;y:20;text:"78";font.family:settings.font_text;font.pixelSize:30;color:settings.color_text;style:Text.Outline;styleColor:settings.color_glow}
    }
    Rectangle {anchors.fill:parent;color:settings_form.pageBackground}
    Pages.AppWidgetStyleSettingsView {id:page;anchors.fill:parent}
    SignalSpy {id:refreshSpy;signalName:"triggered"}
    TestCase {
        name:"OsdStyle";when:windowShown
        function visual(item,name){if(item.objectName===name)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var found=visual(children[i],name);if(found)return found}return null}
        function init(){
            scene.Window.window.width=1600;scene.Window.window.height=900;scene.width=1600;scene.height=900
            page.visible=true;page.resetDefaults()
        }
        function test_presets_persist_without_save(){
            compare(visual(page,"styleApply"),null);compare(visual(page,"styleRevert"),null)
            mouseClick(visual(page,"stylePreset_1"))
            compare(settings.font_text,"Quicksand");verify(Qt.colorEqual(settings.color_shape,"#14ff00"))
            page.usePreset(2);page.setStyle("color_text","#abcdef")
            page.visible=false;verify(Qt.colorEqual(settings.color_text,"#abcdef"))
            page.visible=true;verify(Qt.colorEqual(settings.color_text,"#abcdef"))
        }
        function test_colours_font_opacity_and_live_source(){
            var colour=visual(page,"styleColour_color_text")
            colour.colorSelected("#23abed");compare(settings.color_text,"#23abed")
            var font=visual(page,"styleFont");font.currentIndex=font.model.indexOf("Archivo");font.activated(font.currentIndex)
            compare(settings.font_text,"Archivo")
            var alpha=visual(page,"styleOsdOpacity");alpha.value=0.45;alpha.moved();compare(settings.osd_opacity,0.45)
            var glow=visual(page,"styleGlowOpacity");glow.value=0.6;glow.moved();verify(Math.abs(page.glowColor.a-0.6)<0.01)
            var texture=visual(page,"styleOsdTexture");compare(texture.sourceItem,actualOsd);compare(texture.live,false);compare(texture.hideSource,false);compare(texture.opacity,0.45)
            compare(actualOsd.visible,false)
            page.visible=false;compare(settings.osd_opacity,0.45);page.visible=true
            page.resetDefaults();compare(settings.osd_opacity,1);compare(settings.font_text,"Sans Serif")
        }
        function test_bar_style_controls_and_preview_fill(){
            visual(page,"styleBarBackground_top").colorSelected("#223344")
            visual(page,"styleBarText_bottom").colorSelected("#abcdef")
            compare(settings.osd_top_bar_background_color,"#223344")
            compare(settings.osd_bottom_bar_text_color,"#abcdef")
            var font=visual(page,"styleBarFont_bottom");font.currentIndex=font.model.indexOf("Archivo");font.activated(font.currentIndex)
            compare(settings.osd_bottom_bar_font,"Archivo")
            page.setStyle("osd_bottom_bar_font","Quicksand");page.visible=false;page.visible=true
            compare(settings.osd_bottom_bar_font,"Quicksand")
            var frame=visual(page,"liveOsdStylePreview"),texture=visual(page,"styleOsdTexture")
            compare(texture.width,frame.width);compare(texture.height,frame.height)
            verify(Math.abs(texture.width/texture.height-actualOsd.width/actualOsd.height)<0.01)
            compare(visual(page,"stylePreviewBackground").scale,1.06)
        }
        function test_smoothing_persists_without_save(){
            var slider=visual(page,"styleAnimationSmoothing")
            slider.value=500;slider.moved();page.visible=false
            compare(settings.smoothing,500);page.visible=true;compare(settings.smoothing,500)
            page.resetDefaults();compare(settings.smoothing,33)
        }
        function test_snapshot_refreshes_only_after_changes(){
            refreshSpy.target=findChild(page,"stylePreviewRefresh");verify(refreshSpy.target!==null)
            wait(180);refreshSpy.clear()
            page.usePreset(1)
            tryCompare(refreshSpy,"count",1,2000)
            refreshSpy.clear();wait(180);compare(refreshSpy.count,0)
            page.visible=false;wait(100);refreshSpy.clear()
            settings.color_text="#123456";wait(150);compare(refreshSpy.count,0)
            page.visible=true;tryCompare(refreshSpy,"count",1,2000)
        }
        function test_responsive_capture(){
            wait(200)
            grabImage(scene).save("build/osd-style-wide.png")
            var scroll=visual(page,"stylePageScroll")
            scene.Window.window.width=800;scene.Window.window.height=650;scene.width=800;scene.height=650
            wait(200);compare(page.wide,false);verify(scroll.height>400);verify(scroll.contentHeight>scroll.height)
            grabImage(scene).save("build/osd-style-compact.png")
            scene.Window.window.width=420;scene.Window.window.height=650;scene.width=420;scene.height=650
            wait(200);verify(scroll.width<=420);verify(scroll.height>300)
            grabImage(scene).save("build/osd-style-narrow.png")
        }
    }
}
