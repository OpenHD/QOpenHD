import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Rectangle {
 id:root
 property string title:""
 property string subtitle:""
 property string icon:""
 property string headerNote:""
 property bool compact: false
 readonly property int inset: compact ? 16 : 14
 readonly property int bodyOffset: compact ? 5 : 20
 readonly property real contentWidth:Math.max(0, width - 2 * inset)
 default property alias contents:body.data
 implicitHeight: header.height + body.implicitHeight + 12 + bodyOffset + (compact ? 12 : 14)
 radius:10;border.color:settings_form.lineColor
 gradient:Gradient {
  GradientStop {position:0;color:root.compact && settings_form.darkMode ? "#0b263c" : settings_form.panelBackgroundRaised}
  GradientStop {position:1;color:settings_form.darkMode?"#071e2d":settings_form.panelBackground}
 }
 RowLayout {
  id:header;x:root.inset;y:12;width:root.contentWidth;height:Math.max(root.compact ? 24 : 28,implicitHeight);spacing:10
  Text {text:root.icon;color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize:root.compact ? Typography.rowIcon : Typography.sectionIcon;visible:text.length>0}
  ColumnLayout {Layout.fillWidth:true;spacing:2
   Text {Layout.fillWidth:true;text:root.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;wrapMode:Text.WordWrap}
   Text {Layout.fillWidth:true;visible:root.compact && text.length>0;text:root.subtitle;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap}
  }
  Rectangle {
   visible: root.headerNote.length > 0
   implicitWidth: note.implicitWidth + (root.compact ? 16 : 0)
   implicitHeight: note.implicitHeight + (root.compact ? 6 : 0)
   radius: height / 2
   color: root.compact ? settings_form.panelBackgroundRaised : "transparent"
   Text {
    id: note
    anchors.centerIn: parent
    text: root.headerNote
    color: settings_form.secondaryText
    font.family: Typography.family
    font.pixelSize: Typography.helper
   }
  }
 }
 Rectangle {visible:!root.compact;x:1;y:header.y+header.height+10;width:parent.width-2;height:1;color:settings_form.lineColor}
 ColumnLayout {id:body;height:implicitHeight;x:root.inset;y:header.y+header.height+root.bodyOffset;width:root.contentWidth;spacing:root.compact ? 6 : 10}
}
