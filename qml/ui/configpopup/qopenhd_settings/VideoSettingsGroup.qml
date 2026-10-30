import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
 id:root
 property string title:""
 property string subtitle:""
 property string icon:""
 property bool collapsible:false
 property bool expanded:true
 default property alias rows:rowColumn.data
 implicitHeight:frame.implicitHeight
 data:[
  MapSettingsCard {
   id:frame;width:root.width;height:implicitHeight;title:root.title;subtitle:root.subtitle;icon:root.icon
   Rectangle {
    // Lazy loading can begin at zero size. Break the width/implicit-height cycle.
    width:parent.width; height:rowColumn.implicitHeight
    Layout.fillWidth:true;Layout.preferredHeight:rowColumn.implicitHeight;implicitHeight:rowColumn.implicitHeight;visible:root.expanded
    color:"transparent";radius:Typography.controlRadius;border.color:settings_form.lineColor
    Column {id:rowColumn;width:parent.width;height:implicitHeight}
   }
  },
  ToolButton {
   objectName:root.objectName+"Collapse";visible:root.collapsible;x:root.width-width-12;y:14;width:Typography.controlHeight;height:Typography.controlHeight
   Accessible.name:root.expanded?qsTr("Collapse %1").arg(root.title):qsTr("Expand %1").arg(root.title)
   onClicked:root.expanded=!root.expanded
   background:Item {}
   contentItem:Text {text:root.expanded?"\uf077":"\uf078";font.family:"Font Awesome 5 Free";font.pixelSize:Typography.controlIcon;color:settings_form.secondaryText;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
  }
 ]
}
