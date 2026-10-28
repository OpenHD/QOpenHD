import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/openhd_settings" as Cards
Item {
    id: scene; width: 850; height: 480
    property bool captureImages: false
    FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
    FontLoader { source: "../../qml/osdfonts/Archivo-Regular.ttf" }
    Component.onCompleted: Qt.application.font = Qt.font({family:"Archivo",pixelSize:13})
    QtObject { id: settings_form; property color panelBackgroundRaised:"#15283b";property color panelBackground:"#102235";property color lineColor:"#26394c";property color accentColor:"#278cff";property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb";property color errorColor:"#ff4e5d" }
    QtObject { id: _qopenhd; property bool debugMenuPreview:false }
    QtObject { id: _ohdSystemAir; property bool is_alive:true }
    QtObject {
        id: _ohdSystemAirSettingsModel
        property int update_count:0;property bool ui_is_busy:false;property bool has_params_fetched:true
        property int percent:70;property int dynamicEnabled:1;property int writes:0
        function param_int_exists(id) {return id==="VARIABLE_BITRATE" || id==="V_PRIMARY_PERC"}
        function get_cached_int(id) {return id==="V_PRIMARY_PERC" ? percent : dynamicEnabled}
        function try_set_param_int_async(id,value,confirm) {writes++;if(id==="V_PRIMARY_PERC") percent=value;else dynamicEnabled=value;update_count++}
    }
    property var fixture: ({id:1,total_bps:11000000,capacity_bps:13200000,categories:[{id:1,bps:7000000},{id:2,bps:3000000},{id:4,bps:200000}], allocation:{enabled:true,available:true,overcommitted:false,waiting:false,capacity_kbits:11000,priority_kbits:250,fixed_kbits:0,fixed_measured_kbits:0,safety_kbits:330,pool_kbits:10420,streams:[{id:0,active:true,controllable:true,percent:70,budget_kbits:7294},{id:1,active:true,controllable:true,percent:30,budget_kbits:3126}]}})
    Rectangle { anchors.fill:parent;color:"#091827" }
    Cards.LinkUsageMeter { id: meter; x:14;y:16;width:scene.width-28;usage:scene.fixture;allocationControls:true;onAllocationRequested:popup.open() }
    Cards.LinkAllocationPopup { id: popup; usage: scene.fixture }
    TestCase {
        name:"LinkAllocation";when:windowShown
        function visualChild(item,name) {
            if(item.objectName===name) return item
            if(item.children) for(var i=0;i<item.children.length;i++) {var found=visualChild(item.children[i],name);if(found)return found}
            return null
        }
        function test_allocation_ui() {
            var toggle=findChild(meter,"dynamicLinkBitrateSwitch")
            verify(toggle!==null);compare(toggle.checked,true)
            mouseClick(toggle);compare(_ohdSystemAirSettingsModel.dynamicEnabled,0)
            mouseClick(toggle);compare(_ohdSystemAirSettingsModel.dynamicEnabled,1)
            if(scene.captureImages) { wait(100);grabImage(meter).save("build/status-layout-full/link-usage-850x480.png") }
            var button=findChild(meter,"openLinkAllocationButton")
            mouseClick(button);tryCompare(popup,"visible",true);wait(150)
            popup.close()
            mouseClick(findChild(meter,"linkAllocationTrack"));tryCompare(popup,"visible",true);wait(100)
            compare(meter.fixedPercent+meter.dynamicPercent,100)
            verify(popup.width<scene.width);verify(popup.height<scene.height)
            compare(popup.dynamicCount(),2)
            var slider=visualChild(popup.contentItem,"allocationSlider0")
            verify(slider!==null);verify(slider.enabled)
            slider.forceActiveFocus();keyClick(Qt.Key_Right)
            compare(_ohdSystemAirSettingsModel.percent,71)
            compare(popup.draftPercent,71)
            if(scene.captureImages) grabImage(scene).save("build/status-layout-full/link-allocation-850x480.png")
            scene.width=420;scene.height=680;wait(100)
            verify(popup.width<scene.width);verify(popup.height<scene.height)
            if(scene.captureImages) grabImage(scene).save("build/status-layout-full/link-allocation-narrow.png")
            _qopenhd.debugMenuPreview=true;verify(!slider.enabled)
            _qopenhd.debugMenuPreview=false
            popup.close()
            scene.fixture={id:1,categories:[],allocation:{enabled:true,available:true,streams:[{id:0,active:true,controllable:true,percent:100,budget_kbits:7000},{id:1,active:true,controllable:false,percent:0,budget_kbits:0}]}}
            popup.open();wait(100);compare(popup.dynamicCount(),1)
            slider=visualChild(popup.contentItem,"allocationSlider0");verify(!slider.enabled);compare(slider.value,100)
            popup.close()
            scene.fixture={id:1,total_bps:25000000,capacity_bps:10000000,categories:[],allocation:{enabled:true,available:true,overcommitted:true,capacity_kbits:10000,priority_kbits:1000,safety_kbits:500,fixed_kbits:15000,pool_kbits:0,streams:[]}}
            compare(meter.fixedPercent,100);compare(meter.dynamicPercent,0)
            compare(meter.barDenominator,10000000)
            scene.fixture=null;popup.open();wait(100)
            compare(popup.allocation,null);compare(popup.streams.length,0)
            popup.close()
        }
    }
}
