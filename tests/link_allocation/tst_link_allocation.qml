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
    QtObject {
        id: _airCameraSettingsModel
        property int update_count: 0; property bool has_params_fetched: true; property bool ui_is_busy: false
        property int bitrate: 8; property int writes: 0
        function param_int_exists(id) { return id === "BITRATE_MBITS" }
        function get_cached_int(id) { return bitrate }
        function get_ui_metadata(id) { return {control:"slider",minimum:2,maximum:18,readOnly:false} }
        function try_set_param_int_async(id,value,confirm) { if(id === "BITRATE_MBITS"){bitrate=value;writes++;update_count++} }
    }
    QtObject {
        id: _airCameraSettingsModel2
        property int update_count: 0; property bool has_params_fetched: true; property bool ui_is_busy: false
        property int bitrate: 4; property int writes: 0
        function param_int_exists(id) { return id === "BITRATE_MBITS" }
        function get_cached_int(id) { return bitrate }
        function get_ui_metadata(id) { return {control:"slider",minimum:2,maximum:18,readOnly:false} }
        function try_set_param_int_async(id,value,confirm) { if(id === "BITRATE_MBITS"){bitrate=value;writes++;update_count++} }
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
            compare(findChild(meter,"openLinkAllocationButton"),null)
            mouseClick(findChild(meter,"linkAllocationTrack"));tryCompare(popup,"visible",true);wait(100)
            compare(meter.fixedPercent+meter.dynamicPercent,100)
            verify(popup.width<scene.width);verify(popup.height<scene.height)
            compare(popup.dynamicCount(),2)
            compare(meter.compactUsage(6600000),"50%")
            compare(meter.compactUsage(1),"<0.1%")
            compare(visualChild(meter,"linkUsagePercent1").text,"Cam 1 53%")
            var overviewSegments=visualChild(meter,"linkUsageSegments")
            compare(overviewSegments.denominator,13200000)
            compare(overviewSegments.segments[0].value,7000000)
            compare(popup.trafficRows.length,7)
            compare(popup.datalinkBps(),-1)
            compare(popup.trafficRows[2].name,"Telemetry")
            verify(!visualChild(popup.contentItem,"allocationTrafficRow6").visible)
            compare(popup.categoryBps(5),-1)
            compare(visualChild(popup.contentItem,"allocationTrafficTotal3").text,"Not reported")
            var slider=visualChild(popup.contentItem,"allocationSlider0")
            verify(slider!==null);verify(slider.enabled)
            slider.forceActiveFocus();keyClick(Qt.Key_Right)
            compare(_ohdSystemAirSettingsModel.percent,71)
            compare(popup.draftPercent,71)
            var secondSlider=visualChild(popup.contentItem,"allocationSlider1")
            verify(secondSlider.enabled);compare(secondSlider.value,29)
            secondSlider.forceActiveFocus();keyClick(Qt.Key_Right)
            compare(_ohdSystemAirSettingsModel.percent,70)
            compare(slider.value+secondSlider.value,100)
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
            scene.fixture={id:1,total_bps:25000000,capacity_bps:10000000,categories:[{id:1,bps:25000000}],allocation:{enabled:true,available:true,overcommitted:true,capacity_kbits:10000,priority_kbits:1000,safety_kbits:500,fixed_kbits:15000,pool_kbits:0,streams:[]}}
            compare(meter.fixedPercent,100);compare(meter.dynamicPercent,0)
            compare(meter.barDenominator,10000000)
            popup.open();wait(100)
            var fill=visualChild(popup.contentItem,"allocationTrafficFill0")
            verify(fill!==null);compare(fill.width,fill.parent.width)
            compare(popup.rateBps(popup.categoryBps(1)),"25.0 Mbit/s")
            popup.close()
            _ohdSystemAirSettingsModel.dynamicEnabled=0
            _ohdSystemAirSettingsModel.update_count++
            scene.fixture={id:1,categories:[{id:1,bps:8000000},{id:2,bps:4000000}],allocation:{enabled:false,available:false,streams:[{id:0,active:true,controllable:true},{id:1,active:true,controllable:true}]}}
            popup.open();wait(100)
            var firstEditor=visualChild(popup.contentItem,"allocationBitrate0")
            var secondEditor=visualChild(popup.contentItem,"allocationBitrate1")
            verify(firstEditor!==null);verify(secondEditor!==null)
            firstEditor.focusControl.forceActiveFocus();keyClick(Qt.Key_Right);keyClick(Qt.Key_Return)
            compare(_airCameraSettingsModel.bitrate,9);compare(_airCameraSettingsModel2.bitrate,4)
            secondEditor.focusControl.forceActiveFocus();keyClick(Qt.Key_Right);keyClick(Qt.Key_Return)
            compare(_airCameraSettingsModel2.bitrate,5)
            _qopenhd.debugMenuPreview=true
            firstEditor.commitInt(10);compare(_airCameraSettingsModel.bitrate,9)
            _qopenhd.debugMenuPreview=false
            popup.close()
            var ethernet={id:2,total_bps:2500000,capacity_bps:1000000000,categories:[{id:1,bps:2500000},{id:2,bps:0},{id:3,bps:0},{id:4,bps:0},{id:5,bps:0},{id:6,bps:0}]}
            popup.linkUsages=[ethernet,scene.fixture]
            popup.open();wait(100)
            var wifiSection=visualChild(popup.contentItem,"linkAllocationSection1")
            var ethernetSection=visualChild(popup.contentItem,"linkAllocationSection2")
            verify(wifiSection!==null);verify(ethernetSection!==null)
            verify(ethernetSection.y>wifiSection.y)
            compare(ethernetSection.categoryBps(1),2500000)
            compare(ethernetSection.capacityBps,1000000000)
            compare(visualChild(ethernetSection,"allocationTrafficTotal0").text,"2.5 Mbit/s")
            var scroll=visualChild(popup.contentItem,"linkAllocationScroll")
            verify(scroll.contentHeight>scroll.height)
            scroll.contentY=scroll.contentHeight-scroll.height
            verify(ethernetSection.mapToItem(scroll,0,ethernetSection.height).y<=scroll.height+1)
            var originalRow=visualChild(wifiSection,"allocationTrafficRow0")
            popup.linkUsages=[JSON.parse(JSON.stringify(scene.fixture)),ethernet]
            wait(20)
            compare(visualChild(popup.contentItem,"linkAllocationSection1"),wifiSection)
            compare(visualChild(wifiSection,"allocationTrafficRow0"),originalRow)
            popup.close();popup.linkUsages=[]
            scene.fixture=null;popup.open();wait(100)
            compare(popup.allocation,null);compare(popup.streams.length,0)
            verify(!popup.connected)
            compare(visualChild(popup.contentItem,"allocationTrafficTotal0").text,"Not reported")
            popup.close()
        }
    }
}
