import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtTest 1.2
import "../../qml/ui/configpopup/features" as Pages
Item {
 id:scene;width:1200;height:850
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property real width:scene.width;property real height:scene.height;property bool darkMode:true;property bool compactSidebar:false;property color pageBackground:"#091827";function side_bar_regain_focus(){}property bool showAdvancedSettings:false;property bool showDeveloperSettings:false;property color errorColor:"#ff4e5d";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c"}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true; property int ohd_platform_type:-1}
 QtObject {id:_ohdSystemGround;property bool is_alive:true; property int ohd_platform_type:-1}
 QtObject {id:_messageBoxInstance;function set_text_and_show(message){}}
 Component {
     id:paramModel
     QtObject {
         property int update_count:0
         property bool ui_is_busy:false
         property var values:({})
         property var detectedPorts: []
         property bool hasSerialScan: true
         property var headerRoutes: ({})
         property string boardModel: ""
         property int writes:0
         property string lastId:""
         property var lastValue:""
         function param_int_exists(id){return typeof values[id]==="number"}
         function param_string_exists(id){return typeof values[id]==="string"}
         function get_cached_int(id){return values[id]}
         function get_cached_string(id){return values[id]}
         function get_ui_metadata(id){
             return {label:id, description:"", readOnly:false, serialPortScan:hasSerialScan,
                     keys:detectedPorts, values:detectedPorts, serialHeaderRoutes:headerRoutes, serialBoardModel:boardModel}
         }
         function string_param_has_enum(id){return false}
         function ensure_parameters_available(){}
         function int_param_has_enum_keys_values(id){
             return id.indexOf("BAUD")>=0 || id.indexOf("GPIO_")===0 || id.indexOf("UART_PRI_")===0
         }
         function int_param_get_enum_keys(id){
             return id.indexOf("GPIO_")===0 ? ["Untouched","High","Low"] : int_param_get_enum_values(id).map(String)
         }
         function int_param_get_enum_values(id){
             if (id.indexOf("GPIO_")===0) return [0,1,2]
             if (id.indexOf("UART_PRI_")===0) return [0,1,2,3,4,5,6,7,8,9,10]
             return [9600,115200,921600]
         }
         function int_param_has_min_max(id){return id.indexOf("UART_PRI_")===0}
         function int_param_get_min_value(id){return 0}
         function int_param_get_max_value(id){return 10}
         function get_warning_before_safe(id){return ""}
         function try_set_param_int_async(id,value,log){values[id]=value;lastId=id;lastValue=value;writes++;update_count++}
         function try_set_param_string_async(id,value,log){values[id]=value;lastId=id;lastValue=value;writes++;update_count++}
     }
 }
 property var _ohdSystemAirSettingsModel:paramModel.createObject(scene)
 property var _ohdSystemGroundSettings:paramModel.createObject(scene)
 Component {id:page;Pages.PortsSettingsPanel {anchors.fill:parent}}
 Loader {id:loader;anchors.fill:parent;sourceComponent:page}
 Rectangle {anchors.fill:parent;color:"#091827";z:-1}
 TestCase {
     name:"PortsSettings";when:windowShown
     function row(group,id){return findChild(loader.item,"portSetting_"+group+"_"+id)}
     function section(name){return findChild(loader.item,"portsSection_"+name)}
     function selectUnit(index){
         var tabs=findChild(loader.item,"portsUnitTabs")
         mouseClick(tabs.itemAt(index))
         compare(tabs.currentIndex,index)
     }
     function init(){
         loader.active=false;scene.width=1200;scene.height=850;settings_form.showAdvancedSettings=false;settings_form.showDeveloperSettings=false;_qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=true;_ohdSystemGround.is_alive=true
         _ohdSystemAirSettingsModel.values={FC_UART_CONN:"/dev/ttyS1",FC_UART_BAUD:921600,FC_UART_FLWCTL:0,SBUS_EN:0,SBUS_DEV:"/dev/ttyS2",SBUS_HZ:50,GPIO_2:0,GPIO_26:0,OHD_UART_EN:0,OHD_UART_TLM:"/dev/ttyUSB0",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
         _ohdSystemGroundSettings.values={TRACKER_UART_OUT:"",TRACK_UART_BAUD:9600,TRACK_UART_FLOW:0,OHD_UART_EN:0,OHD_UART_TLM:"/dev/ttyUSB0",OHD_UART_BAUD:115200,OHD_UART_FLW:0,UART_PRI_RC:3,UART_PRI_OHD:2,UART_PRI_FC:1}
         _ohdSystemAir.ohd_platform_type=-1
         _ohdSystemGround.ohd_platform_type=-1
         _ohdSystemAirSettingsModel.boardModel=""
         _ohdSystemGroundSettings.boardModel=""
         _ohdSystemAirSettingsModel.headerRoutes={}
         _ohdSystemGroundSettings.headerRoutes={}
         _ohdSystemAirSettingsModel.hasSerialScan=true
         _ohdSystemGroundSettings.hasSerialScan=true
         _ohdSystemAirSettingsModel.detectedPorts=["/dev/ttyS1","/dev/ttyS2","/dev/ttyUSB0"]
         _ohdSystemGroundSettings.detectedPorts=["/dev/ttyUSB0","/dev/ttyUSB1"]
         _ohdSystemAirSettingsModel.writes=0;_ohdSystemGroundSettings.writes=0
         _ohdSystemAirSettingsModel.update_count++;_ohdSystemGroundSettings.update_count++
         loader.active=true;tryCompare(loader,"status",Loader.Ready);wait(50)
     }
     function test_tracker_routes_to_ground(){
         selectUnit(1)
         row("tracker","TRACKER_UART_OUT").commitChoice("/dev/ttyUSB1")
         compare(_ohdSystemGroundSettings.lastId,"TRACKER_UART_OUT");compare(_ohdSystemAirSettingsModel.writes,0)
         row("tracker","TRACK_UART_FLOW").commitToggle(true);compare(_ohdSystemGroundSettings.lastValue,1)
     }
     function test_ground_independent_of_air(){
         selectUnit(1)
         _ohdSystemAir.is_alive=false;verify(!row("tracker","TRACK_UART_BAUD").busy)
         row("tracker","TRACK_UART_BAUD").commitChoice(115200);compare(_ohdSystemGroundSettings.lastValue,115200)
         _ohdSystemGround.is_alive=false;row("tracker","TRACK_UART_BAUD").commitChoice(9600);compare(_ohdSystemGroundSettings.writes,1)
     }
     function test_roles_write_to_the_selected_unit(){
         settings_form.showAdvancedSettings=true
         row("fc","FC_UART_BAUD").commitChoice(115200)
         compare(_ohdSystemAirSettingsModel.lastId,"FC_UART_BAUD")
         row("airLink","OHD_UART_EN").commitToggle(true)
         compare(row("groundLink","OHD_UART_EN"),null)
         selectUnit(1)
         compare(row("airLink","OHD_UART_EN"),null)
         row("groundLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,1)
         compare(_ohdSystemGroundSettings.values.OHD_UART_EN,1)
         selectUnit(0)
         row("gpio","GPIO_26").commitChoice(2)
         compare(_ohdSystemAirSettingsModel.lastId,"GPIO_26")
         compare(_ohdSystemAirSettingsModel.values.GPIO_26,2)
     }
     function test_unit_tabs_keyboard(){
         var tabs=findChild(loader.item,"portsUnitTabs")
         loader.item.gainFocus()
         verify(tabs.itemAt(0).activeFocus)
         keyClick(Qt.Key_Right)
         compare(tabs.currentIndex,1)
         verify(tabs.itemAt(1).activeFocus)
         keyClick(Qt.Key_Left)
         compare(tabs.currentIndex,0)
     }
     function test_advertised_port_choices_use_validation(){
         selectUnit(1)
         _ohdSystemGroundSettings.values.OHD_UART_EN=1
         _ohdSystemGroundSettings.update_count++
         var tracker=row("tracker","TRACKER_UART_OUT")
         var editor=findChild(tracker,"portChoiceEditor")
         compare(tracker.choices.map(function(entry){return entry.value}),
                 ["","/dev/ttyUSB0","/dev/ttyUSB1"])
         editor.activated(1)
         compare(_ohdSystemGroundSettings.writes,0)
         compare(editor.currentIndex,0)
         verify(loader.item.validationError.length>0)
         editor.activated(2)
         compare(_ohdSystemGroundSettings.lastValue,"/dev/ttyUSB1")
         compare(editor.currentIndex,2)
     }
     function test_compact_dropdown_keyboard(){
         selectUnit(1)
         var tracker=row("tracker","TRACKER_UART_OUT")
         var editor=findChild(tracker,"portChoiceEditor")
         verify(editor.compact)
         editor.forceActiveFocus()
         keyClick(Qt.Key_Return)
         tryCompare(editor.popup,"opened",true)
         keyClick(Qt.Key_Down)
         keyClick(Qt.Key_Return)
         tryCompare(editor.popup,"opened",false)
         compare(_ohdSystemGroundSettings.lastValue,"/dev/ttyUSB0")
         compare(findChild(tracker,"portChoiceEditor"),editor)
     }
     function test_scan_is_per_unit_and_updates_without_replacing_the_row(){
         var fc=row("fc","FC_UART_CONN")
         compare(fc.choices.map(function(entry){return entry.value}),
                 ["","/dev/ttyS1","/dev/ttyS2","/dev/ttyUSB0"])
         var editor=findChild(fc,"portChoiceEditor")
         _ohdSystemAirSettingsModel.detectedPorts=["/dev/ttyACM0"]
         _ohdSystemAirSettingsModel.update_count++
         compare(fc.choices.map(function(entry){return entry.value}),["","/dev/ttyACM0"])
         compare(editor.currentIndex,-1)
         compare(editor.displayText,"Saved port (/dev/ttyS1)")
         fc.commitChoice("/dev/ttyS1")
         fc.commitChoice("DEFAULT")
         compare(_ohdSystemAirSettingsModel.writes,0)
         fc.commitChoice("/dev/ttyACM0")
         compare(_ohdSystemAirSettingsModel.lastValue,"/dev/ttyACM0")

         selectUnit(1)
         compare(row("tracker","TRACKER_UART_OUT").choices.map(function(entry){return entry.value}),
                 ["","/dev/ttyUSB0","/dev/ttyUSB1"])
     }
     function test_missing_inventory_does_not_offer_legacy_choices(){
         selectUnit(1)
         var tracker=row("tracker","TRACKER_UART_OUT")
         var editor=findChild(tracker,"portChoiceEditor")
         _ohdSystemGroundSettings.hasSerialScan=false
         _ohdSystemGroundSettings.update_count++
         compare(tracker.choices.length,1)
         compare(editor.displayText,"UART list unavailable")
         verify(!editor.enabled)

         _ohdSystemGroundSettings.hasSerialScan=true
         _ohdSystemGroundSettings.detectedPorts=[]
         _ohdSystemGroundSettings.update_count++
         compare(tracker.choices.length,1)
         compare(editor.displayText,"No UARTs detected")
         verify(!editor.enabled)
     }
     function test_air_conflicts_and_missing_port(){
         settings_form.showAdvancedSettings=true
         row("sbus","SBUS_DEV").commitChoice("/dev/ttyS1")
         row("sbus","SBUS_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.SBUS_EN,0)
         row("airLink","OHD_UART_TLM").commitChoice("")
         row("airLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,0)
         row("airLink","OHD_UART_TLM").commitChoice("/dev/ttyUSB0")
         row("airLink","OHD_UART_EN").commitToggle(true)
         compare(_ohdSystemAirSettingsModel.values.OHD_UART_EN,1)
     }
     function test_priorities_use_bounded_steppers(){
         settings_form.showAdvancedSettings=true
         var priority=row("airLink","UART_PRI_RC")
         var editor=findChild(priority,"portNumberEditor")
         verify(editor !== null)
         compare(editor.from,0)
         compare(editor.to,10)
         compare(editor.topPadding,editor.bottomPadding)
     }
     function test_only_reported_pins_are_editable(){
         delete _ohdSystemAirSettingsModel.values.GPIO_26
         _ohdSystemAirSettingsModel.update_count++
         compare(row("gpio","GPIO_26"),null)
         verify(row("gpio","GPIO_2") !== null)
     }
     function test_preview(){
         selectUnit(1)
         _qopenhd.debugMenuPreview=true;row("tracker","TRACKER_UART_OUT").commitChoice("/dev/ttyUSB1");compare(_ohdSystemGroundSettings.writes,0)
     }
     function test_units_only_show_their_own_cards(){
         verify(section("fc") !== null)
         verify(section("gpio") !== null)
         compare(section("tracker"),null)
         compare(section("link"),null)
         compare(section("sbus"),null)

         settings_form.showDeveloperSettings=true
         compare(section("link"),null)
         compare(section("sbus"),null)
         selectUnit(1)
         verify(section("tracker") !== null)
         compare(section("fc"),null)
         compare(section("gpio"),null)
         compare(section("link"),null)
         compare(section("sbus"),null)

         settings_form.showDeveloperSettings=false
         settings_form.showAdvancedSettings=true
         verify(row("groundLink","OHD_UART_TLM") !== null)
         compare(section("sbus"),null)
         selectUnit(0)
         verify(row("airLink","OHD_UART_TLM") !== null)
         verify(section("sbus") !== null)
         compare(section("tracker"),null)

         settings_form.showAdvancedSettings=false
         compare(section("link"),null)
         compare(section("sbus"),null)
         verify(section("fc") !== null)
         verify(section("gpio") !== null)
     }
     function test_board_pinout_follows_unit_settings(){
         _ohdSystemAir.ohd_platform_type=20
         _ohdSystemAirSettingsModel.headerRoutes={"/dev/ttyS4":{rx:16,tx:18}}
         _ohdSystemAirSettingsModel.values.FC_UART_CONN="/dev/ttyS4"
         _ohdSystemAirSettingsModel.update_count++
         var board=findChild(loader.item,"portsBoardPinout")
         verify(board !== null)
         compare(board.pinNames.length,40)
         compare(board.highlights[16].signal,"RX")
         compare(board.highlights[18].signal,"TX")
         compare(board.highlights[8],undefined)
         var pin=findChild(board,"portsHeaderPin16")
         mouseClick(pin)
         compare(board.inspectedPin,16)

         _ohdSystemAirSettingsModel.values.FC_UART_CONN="/dev/ttyUSB0"
         _ohdSystemAirSettingsModel.update_count++
         compare(board.highlights[16],undefined)
         _ohdSystemGround.ohd_platform_type=20
         selectUnit(1)
         compare(Object.keys(board.highlights).length,0)
         compare(board.inspectedPin,0)
         _ohdSystemGroundSettings.headerRoutes={"/dev/ttyS4":{rx:16,tx:18}}
         _ohdSystemGroundSettings.values.TRACKER_UART_OUT="/dev/ttyS4"
         _ohdSystemGroundSettings.update_count++
         compare(board.highlights[16],undefined)
         compare(board.highlights[18].label,"Tracker")
         _ohdSystemGround.is_alive=false
         compare(Object.keys(board.highlights).length,0)
     }
     function test_board_and_chart_share_pin_rows(){
         var platforms=[20,11,13,21,22,31,32,34,35]
         for (var i=0; i<platforms.length; ++i) {
             _ohdSystemAir.ohd_platform_type=platforms[i]
             var board=findChild(loader.item,"portsBoardPinout")
             var art=findChild(board,"portsBoardArt")
             wait(50)
             verify(board.sideBySide)
             for (var number=1; number<=board.pinNames.length; ++number) {
                 var pin=findChild(board,"portsHeaderPin"+number)
                 var chartY=pin.mapToItem(board, pin.width / 2, pin.height / 2).y
                 var boardY=art.mapToItem(board, 0, art.pinCenterY(number)).y
                 verify(Math.abs(chartY-boardY) <= 1, "Pin " + number + " at " + chartY + " vs " + boardY)
                 var labels=["pinPad","pinNumber","pinDescription"]
                 for (var k=0; k<labels.length; ++k) {
                     var label=findChild(pin, labels[k])
                     var labelY=label.mapToItem(board,0,label.height/2).y
                     verify(Math.abs(labelY-chartY) <= 1, "Pin " + number + " " + labels[k] + " differs from row center")
                 }
                 compare(pin.odd,number % 2 === 1)
             }
         }
     }
     function test_board_art_matches_selected_unit(){
         _ohdSystemAir.ohd_platform_type=20
         _ohdSystemGround.ohd_platform_type=13
         var board=findChild(loader.item,"portsBoardPinout")
         compare(board.platform,20)
         selectUnit(1)
         compare(board.platform,13)
         verify(board.title.indexOf("Pi 5") >= 0)
         _ohdSystemGround.ohd_platform_type=11
         compare(board.platform,11)
         verify(board.title.indexOf("Pi 4") >= 0)
         _ohdSystemGround.ohd_platform_type=12
         verify(board.schematic)
         compare(board.pinNames.length,0)
         verify(board.title.indexOf("Compute Module 4") >= 0)

         _ohdSystemGround.ohd_platform_type=13
         _ohdSystemGroundSettings.boardModel="Raspberry Pi Compute Module 5 Rev 1.0"
         _ohdSystemGroundSettings.update_count++
         verify(board.schematic)
         verify(board.title.indexOf("Compute Module 5") >= 0)

         _ohdSystemGround.ohd_platform_type=-1
         tryVerify(function(){return findChild(loader.item,"portsBoardPinout") === null})
     }
     function test_each_platform_has_a_named_view(){
         var platformIds=[0,1,10,11,12,13,20,21,22,23,24,25,26,27,28,29,30,31,32,34,35,36,38,40,46,47,51,52,61,255]
         var named=[]
         for (var i=0; i<platformIds.length; ++i) {
             _ohdSystemAir.ohd_platform_type=platformIds[i]
             var board=findChild(loader.item,"portsBoardPinout")
             verify(board !== null)
             verify(board.title.length > 0)
             var art=findChild(board,"portsBoardArt")
             tryCompare(art,"imageReady",true)
             compare(board.pinNames.length, art.geometry.header ? art.geometry.header.rows * art.geometry.header.columns : 0)
             if (i > 0 && i < platformIds.length - 1 && platformIds[i] !== 26) {
                 verify(named.indexOf(board.title) < 0)
                 named.push(board.title)
             }
         }
     }
     function test_reported_board_models_and_connector_sizes(){
         _ohdSystemAir.ohd_platform_type=10
         _ohdSystemAirSettingsModel.boardModel="Raspberry Pi Zero 2 W Rev 1.0"
         _ohdSystemAirSettingsModel.update_count++
         var board=findChild(loader.item,"portsBoardPinout")
         compare(board.pinNames[7],"GPIO 14")
         verify(board.title.indexOf("Zero 2 W") >= 0)
         _ohdSystemAir.ohd_platform_type=31
         compare(board.pinNames.length,30)
         compare(board.auxPins.length,15)
         compare(board.auxPins[3],"GND")
         _ohdSystemAir.ohd_platform_type=35
         _ohdSystemAirSettingsModel.headerRoutes={"/dev/ttyS1":{rx:16,tx:18}}
         _ohdSystemAirSettingsModel.update_count++
         compare(board.highlights[16].label,"FC telemetry")
         compare(board.highlights[18].signal,"TX")
         compare(board.pinNames[25],"GPIO4_D1")
     }
     function test_raspberry_pin_functions_are_not_live_assignments(){
         _ohdSystemAir.ohd_platform_type=11
         var board=findChild(loader.item,"portsBoardPinout")
         compare(board.functionForPin(8),"UART TX")
         compare(board.functionForPin(10),"UART RX")
         compare(board.functionForPin(23),"SPI SCLK")
         compare(board.highlights[8],undefined)
         compare(board.highlights[10],undefined)
         _ohdSystemAir.ohd_platform_type=32
         compare(board.functionForPin(16),"UART4 TX")
         compare(board.functionForPin(18),"UART4 RX")
     }
     function test_original_proportions_and_pin_locations(){
         var cases=[
             [11,"",56,85], [20,"",30,65], [21,"",56,85], [22,"",75,100], [29,"",56,85],
             [31,"",51,51], [32,"",30,65], [34,"Radxa ROCK 3B",75,100],
             [10,"Raspberry Pi Zero 2 W Rev 1.0",30,65], [27,"Luckfox Lyra Plus",21,72]
         ]
         for (var i=0; i<cases.length; ++i) {
             var entry=cases[i]
             _ohdSystemAir.ohd_platform_type=entry[0]
             _ohdSystemAirSettingsModel.boardModel=entry[1]
             _ohdSystemAirSettingsModel.update_count++
             var board=findChild(loader.item,"portsBoardPinout")
             var art=findChild(board,"portsBoardArt")
             tryCompare(art,"imageReady",true)
             verify(art.pcbBounds.width > 0 && art.pcbBounds.height > 0)
             verify(Math.abs(art.pcbBounds.width / art.pcbBounds.height - entry[2] / entry[3]) < 0.0001)
             var last=art.pointForPin(board.pinNames.length,false)
             verify(last.x > art.pcbBounds.x && last.x < art.pcbBounds.x + art.pcbBounds.width)
             verify(last.y > art.pcbBounds.y && last.y < art.pcbBounds.y + art.pcbBounds.height)
         }
     }
     function test_low_resolution_pin_navigation(){
         scene.width=630
         scene.height=380
         _ohdSystemAir.ohd_platform_type=20
         _ohdSystemAirSettingsModel.values.FC_UART_CONN="/dev/ttyS4"
         _ohdSystemAirSettingsModel.headerRoutes={"/dev/ttyS4":{rx:16,tx:18}}
         _ohdSystemAirSettingsModel.update_count++
         var board=findChild(loader.item,"portsBoardPinout")
         var art=findChild(board,"portsBoardArt")
         var scroll=findChild(loader.item,"portsScrollView")
         tryCompare(art,"imageReady",true)
         var pins=findChild(board,"portsPinList")
         verify(board.compactView)
         verify(pins.visible && pins.interactive)
         verify(board.height < scroll.height)
         verify(art.artWidth <= art.width && art.artHeight <= art.height)
         verify(findChild(art,"portsBoardMarker16").visible)
         verify(findChild(art,"portsBoardMarker18").visible)
         verify(!findChild(art,"portsBoardMarker8").visible)
         tryVerify(function(){return pins.contentY > 0})
         var rx=findChild(board,"portsHeaderPin16")
         var tx=findChild(board,"portsHeaderPin18")
         var rxY=rx.mapToItem(pins,0,rx.height/2).y
         var txY=tx.mapToItem(pins,0,tx.height/2).y
         verify(rxY >= rx.height/2 && txY + tx.height/2 <= pins.height)

         var pin=art.pointForPin(16,false)
         compare(art.hitPin(pin.x,pin.y,art.geometry.header),16)
         mouseClick(art,Math.round(pin.x),Math.round(pin.y))
         compare(board.inspectedPin,16)
         tx.forceActiveFocus()
         keyClick(Qt.Key_Space)
         compare(board.inspectedPin,18)

         var last=findChild(board,"portsHeaderPin40")
         last.forceActiveFocus()
         tryVerify(function(){return last.mapToItem(pins,0,last.height).y <= pins.height + 1})
         keyClick(Qt.Key_Space)
         compare(board.inspectedPin,40)
         verify(findChild(art,"portsBoardMarker40").visible)
     }
     function test_stacked_pinout_keeps_active_rows_visible(){
         scene.width=336
         scene.height=340
         _ohdSystemAir.ohd_platform_type=20
         _ohdSystemAirSettingsModel.values.FC_UART_CONN="/dev/ttyS4"
         _ohdSystemAirSettingsModel.headerRoutes={"/dev/ttyS4":{rx:16,tx:18}}
         _ohdSystemAirSettingsModel.update_count++
         var board=findChild(loader.item,"portsBoardPinout")
         var art=findChild(board,"portsBoardArt")
         var pins=findChild(board,"portsPinList")
         var viewport=findChild(loader.item,"portsScrollView")
         tryCompare(art,"imageReady",true)
         verify(board.compactView && !board.compactBesideArt)
         tryVerify(function(){return pins.contentY > 0})
         var rx=findChild(board,"portsHeaderPin16")
         var tx=findChild(board,"portsHeaderPin18")
         tryVerify(function(){
             return rx.mapToItem(viewport,0,0).y >= 0 && tx.mapToItem(viewport,0,tx.height).y <= viewport.height
         })
     }
     function test_gpio_highlights_use_physical_pins(){
         _ohdSystemAir.ohd_platform_type=11
         _ohdSystemAirSettingsModel.values.GPIO_2=1
         _ohdSystemAirSettingsModel.values.GPIO_26=2
         _ohdSystemAirSettingsModel.update_count++
         var board=findChild(loader.item,"portsBoardPinout")
         compare(board.highlights[3].signal,"High")
         compare(board.highlights[37].signal,"Low")
         _ohdSystemAirSettingsModel.values.GPIO_26=0
         _ohdSystemAirSettingsModel.update_count++
         compare(board.highlights[37],undefined)
     }
     function test_layout(){
         settings_form.showAdvancedSettings=true
         var tabs=findChild(loader.item,"portsUnitTabs")
         var fc=section("fc")
         var gpio=section("gpio")
         var link=section("link")
         var r=row("fc","FC_UART_BAUD")

         for(var i=0;i<3;i++){
             scene.width=[1100,760,330][i];wait(50)
             compare(tabs.itemAt(0).width,tabs.itemAt(1).width)
             if (i === 0) {
                 compare(fc.y,gpio.y)
                 compare(fc.width,gpio.width)
                 verify(Math.abs(link.width - fc.width - gpio.width - 12) < 1)
             } else if(i === 2) {
                 verify(gpio.y > fc.y)
                 compare(link.width,fc.width)
             }

             var label=findChild(r,"portRowLabel")
             var editor=findChild(r,"portRowEditor")
             compare(editor.height,32)
             if (r.stacked) {
                 compare(editor.x,0)
                 verify(editor.y > label.y + label.height)
             } else {
                 verify(Math.abs(editor.y + editor.height / 2 - label.y - label.height / 2) < 1)
                 var portEditor=findChild(row("fc","FC_UART_CONN"),"portRowEditor")
                 compare(editor.x,portEditor.x)
                 compare(editor.width,portEditor.width)
             }
         }
         scene.width=1200
     }

 }
}
