import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Rectangle {
 id:root
 property string title:""
 property string subtitle:""
 property string icon:""
 property string headerNote:""
 default property alias contents:body.data
 implicitHeight:header.height+body.implicitHeight+46
 radius:10;border.color:settings_form.lineColor
 gradient:Gradient {
  GradientStop {position:0;color:settings_form.panelBackgroundRaised}
  GradientStop {position:1;color:settings_form.darkMode?"#071e2d":settings_form.panelBackground}
 }
 RowLayout {
  id:header;x:14;y:12;width:parent.width-28;height:root.subtitle.length?48:28;spacing:10
  Text {text:root.icon;color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.sectionIcon;visible:text.length>0}
  ColumnLayout {Layout.fillWidth:true;spacing:2
   Text {Layout.fillWidth:true;text:root.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;wrapMode:Text.WordWrap}
   Text {Layout.fillWidth:true;text:root.subtitle;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap;visible:text.length>0}
  }
  Text {text:root.headerNote;visible:text.length>0;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
 }
 Rectangle {x:1;y:header.y+header.height+10;width:parent.width-2;height:1;color:settings_form.lineColor}
 ColumnLayout {id:body;height:implicitHeight;x:14;y:header.y+header.height+20;width:parent.width-28;spacing:10}
}
