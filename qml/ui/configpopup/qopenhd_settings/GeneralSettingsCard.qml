import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Rectangle {
 id:root
 property string title:""
 property string hint:""
 property string icon:""
 property real controlWidth:340
 readonly property bool stacked:width<760 && controlWidth>100
 property alias headerControls:controls.data
 default property alias contents:body.data
 implicitHeight:headerHeight+(body.children.length?body.implicitHeight+20:0)
 readonly property real headerHeight:stacked?110:Typography.sectionHeaderHeight
 radius:12;border.color:settings_form.lineColor
 gradient:Gradient {
  GradientStop {position:0;color:settings_form.panelBackgroundRaised}
  GradientStop {position:1;color:settings_form.darkMode?"#061d2b":settings_form.panelBackground}
 }
 Text {x:22;y:root.stacked?22:(root.headerHeight-height)/2;text:root.icon;color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon}
 Column {
  x:82;y:root.stacked?20:(root.headerHeight-height)/2
  width:root.stacked?root.width-106:Math.max(0,controls.x-x-20);spacing:6
  Text {width:parent.width;text:root.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;wrapMode:Text.WordWrap}

 }
 Item {id:controls;width:root.stacked?root.width-40:Math.min(root.controlWidth,root.width*0.43);height:Typography.controlHeight;x:root.width-width-20;y:root.stacked?root.headerHeight-height-14:(root.headerHeight-height)/2}
 Column {id:body;x:20;y:root.headerHeight;width:root.width-40;spacing:12}
}
