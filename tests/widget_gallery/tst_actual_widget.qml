import QtQuick 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/widgets" as HUD
import "../../qml/ui/configpopup/qopenhd_settings" as Gallery
Item {
    id:scene;width:600;height:400
    property bool globalDragLock:false
    property int detailPanelFontPixels:13
    QtObject {
        id:settings
        property bool show_flight_mode:false
        property bool show_widgets:false
        property bool flight_mode_show_disarmed:true
        property bool bank_angle_indicator_widget_show:false
        property bool bank_angle_indicator_widget_show_arc:true
        property bool bank_angle_indicator_widget_show_numbers:true
        property bool bank_angle_indicator_widget_roll_invert:false
        property bool bank_angle_indicator_widget_sky_pointer:false
        property int smoothing:0
        property color color_text:"#ffffff"
        property color color_shape:"#ffffff"
        property color color_glow:"#000000"
        property string font_text:"Arial"
        property string link_overview_widget_bg_color:"#000000"
        property int writes:0
        function value(key,fallback){return fallback}
        function setValue(key,val){writes++}
        function sync(){}
    }
    QtObject {id:_fcMavlinkSystem;property string flight_mode:"MANUAL";property bool armed:false;property bool is_alive:true;property real roll:0}
    QtObject {id:_fcMavlinkAction;property string ardupilot_mav_type:"quad";function has_mapping(mode){return false}}
    QtObject {id:_qopenhd;function show_toast(message){}}
    QtObject {id:hudOverlayGrid;readonly property var widgetPreviewTargets:({show_flight_mode:actual,bank_angle_indicator_widget_show:bank});property bool m_show_horizontal_center_indicator:false;property bool m_show_vertical_center_indicator:false}
    Rectangle {anchors.fill:parent;color:"#102235"}
    Item { width:600;height:400;visible:false;HUD.FlightModeWidget {id:actual} HUD.RollWidget {id:bank} }
    Gallery.WidgetPreview {id:preview;x:0;y:0;width:160;height:100;widgetKey:"show_flight_mode"}
    TestCase {
        name:"ActualWidgetPreview";when:windowShown
        function test_bank_bounds_include_outside_drawing(){
            preview.widgetKey="bank_angle_indicator_widget_show"
            wait(180)
            var texture=findChild(preview,"actualWidgetTexture")
            compare(texture.sourceItem,bank)
            verify(texture.sourceRect.width>bank.width)
            verify(texture.sourceRect.height>bank.height)
            verify(texture.textureSize.width>=texture.sourceRect.width)
            compare(bank.visible,false)
            preview.refresh();wait(120)
            var image=grabImage(preview),lit=0
            for(var y=5;y<image.height-5;y++)for(var x=5;x<image.width-5;x++){
                var pixel=image.pixel(x,y)
                if(pixel.r>0.6&&pixel.g>0.6&&pixel.b>0.6)lit++
            }
            verify(lit>20,"The complete bank indicator must render in the preview")
            image.save("build/widget-preview-actual-bank.png")
            preview.widgetKey="show_flight_mode"
        }
        function test_existing_widget_rendering(){
            wait(250)
            compare(actual.visible,false)
            compare(settings.show_flight_mode,false)
            var writes=settings.writes
            var texture=findChild(preview,"actualWidgetTexture")
            compare(texture.sourceItem,actual)
            compare(texture.sourceRect.height,96)
            preview.refresh();wait(120)
            compare(settings.writes,writes)
            var image=grabImage(preview),lit=0
            for(var y=5;y<image.height-5;y++)for(var x=5;x<image.width-5;x++){
                var pixel=image.pixel(x,y)
                if(pixel.r>0.6&&pixel.g>0.6&&pixel.b>0.6)lit++
            }
            image.save("build/widget-preview-actual-flight-mode.png")
            verify(lit>20,"The actual widget text must appear in the miniature")
        }
    }
}
