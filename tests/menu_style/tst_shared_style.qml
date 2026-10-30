import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup" as Menu
import "../../qml/ui/configpopup/qopenhd_settings" as Pages
import "../../qml/ui/configpopup/MenuTypography.js" as Typography
Item {
 width:900;height:650
 QtObject {id:settings_form;property bool darkMode:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff";property color errorColor:"red"}
 Menu.AdvancedActionButton {id:action;text:"Action";x:10;y:10}
 Menu.AdvancedDialogButton {id:dialogAction;text:"Confirm";x:140;y:10}
 Pages.MapActionButton {id:mapAction;text:"Map action";x:270;y:10}
 Menu.AdvancedTabButton {id:tab;text:"General";x:400;y:10}
 Pages.GeneralSettingsCard {id:generalCard;x:10;y:80;width:420;height:implicitHeight;title:"General heading";hint:"General description"}
 Pages.MapSettingsCard {id:mapCard;x:440;y:80;width:420;height:implicitHeight;title:"Map heading";subtitle:"Map description"}
 Menu.AdvancedTabBar {
  id:extrasTabs;x:10;y:350;width:800;spacing:6
  Menu.AdvancedTabButton {text:"AUDIO";iconText:"A"}
  Menu.AdvancedTabButton {text:"ADS-B";iconText:"B"}
  Menu.AdvancedTabButton {text:"RC / LOGS";iconText:"R"}
  Menu.AdvancedTabButton {text:"DATA LINK";iconText:"D"}
  Menu.AdvancedTabButton {text:"UART";iconText:"U"}
  Menu.AdvancedTabButton {text:"JOYSTICK";iconText:"J"}
  Menu.AdvancedTabButton {text:"FLEETCONTROL";iconText:"F"}
 }
 TestCase {
  name:"SharedMenuStyle";when:windowShown
  function textItem(item,text){if(item.text===text)return item;var children=item.children||[];for(var i=0;i<children.length;i++){var match=textItem(children[i],text);if(match)return match}return null}
  function test_common_controls(){
   var controls=[action,dialogAction,mapAction,tab]
   for(var i=0;i<controls.length;i++){
    compare(controls[i].height,Typography.controlHeight)
    compare(controls[i].font.pixelSize,Typography.body)
    compare(controls[i].font.family,Typography.family)
    compare(controls[i].topInset,0);compare(controls[i].bottomInset,0)
   }
  }
  function test_matching_text_roles(){
   compare(textItem(generalCard,"General heading").font.pixelSize,Typography.sectionTitle)
   compare(textItem(mapCard,"Map heading").font.pixelSize,Typography.sectionTitle)
   compare(textItem(generalCard,"General description"),null)
   compare(textItem(mapCard,"Map description"),null)
   compare(textItem(action,"Action").font.pixelSize,Typography.body)
  }
  function test_tabs_fit_at_full_and_reduced_width(){
   extrasTabs.width=1000;wait(20);compare(extrasTabs.compactTabs,false)
   extrasTabs.width=360;wait(20);compare(extrasTabs.compactTabs,true)
   var total=0
   for(var i=0;i<extrasTabs.count;i++){
    verify(extrasTabs.itemAt(i).iconOnly)
    total+=extrasTabs.itemAt(i).width
   }
   verify(total+(extrasTabs.count-1)*extrasTabs.spacing<=extrasTabs.width)
   extrasTabs.width=1000;wait(20);compare(extrasTabs.compactTabs,false)
  }
 }
}
