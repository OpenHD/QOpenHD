import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/dev" as Dev
Item {
 id:scene;width:900;height:720
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings_form;property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color primaryText:"white";property color secondaryText:"#aebdcb";property color lineColor:"#26394c";property color accentColor:"#278cff"}
 QtObject {
 id:_uiSimulator
 property bool active:false
 property var profile:({ground:21,air:11,camera1:32,camera2:3,radio:17,link:1,secondLink:0,state:1,fc:true,groundRadios:1,airRadios:1,accessMode:0})
 property string lastAction:"Simulation ready"
 property int starts:0
 function platforms(){return [{label:"ROCK 5A",value:21},{label:"RPI 4",value:11}]}
 function cameras(platform){return [{label:"Not connected",value:-1},{label:"IMX708",value:32},{label:"IP camera",value:3}]}
 function radios(){return [{label:"RTL8812AU",value:17}]}
 function start(config){profile=config;active=true;starts++;return true}
 function stop(){active=false}
 }
 Dev.SimulationPopup{id:popup}
 TestCase {
 name:"SimulationPopup";when:windowShown
 function visual(item,name) {
  if(item.objectName===name)return item
  var children=item.children||[]
  for(var i=0;i<children.length;i++){var result=visual(children[i],name);if(result)return result}
  return null
 }
 function test_configure_and_start(){
 popup.open();tryCompare(popup,"opened",true)
 compare(visual(popup.contentItem,"simulationChoice_ground").currentText,"ROCK 5A")
 compare(visual(popup.contentItem,"simulationChoice_camera1").currentText,"IMX708")
 compare(visual(popup.contentItem,"simulationChoice_camera2").currentText,"IP camera")
 compare(visual(popup.contentItem,"simulationChoice_accessMode").currentText,"Normal")
 popup.setChoice("accessMode",2)
 popup.setChoice("ground",11);popup.setChoice("camera2",-1)
 mouseClick(visual(popup.footer,"simulationStart"));compare(_uiSimulator.starts,1)
 compare(_uiSimulator.profile.accessMode,2)
 compare(_uiSimulator.profile.ground,11);compare(_uiSimulator.profile.camera2,-1)
 tryCompare(popup,"visible",false)
 }
 function test_compact_fits(){
 scene.Window.window.width=500;scene.Window.window.height=480
 popup.open();tryCompare(popup,"opened",true)
 verify(popup.height<=480,"Popup must scroll within a small window")
 verify(popup.width<=476)
 verify(visual(popup.contentItem,"simulationChoice_ground").width>100)
 popup.close()
 }
 }
}
