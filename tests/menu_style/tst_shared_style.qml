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
   compare(textItem(generalCard,"General description").font.pixelSize,Typography.helper)
   compare(textItem(mapCard,"Map description").font.pixelSize,Typography.helper)
   compare(textItem(action,"Action").font.pixelSize,Typography.body)
  }
 }
}
