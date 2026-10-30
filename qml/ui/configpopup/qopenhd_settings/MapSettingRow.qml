import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Item {
 id:root
 property string label:""
 property string hint:""
 property real controlWidth:210
 property real minimumControlWidth:0
 readonly property bool stacked:minimumControlWidth>width*0.52
 default property alias control:slot.data
 implicitHeight:stacked?caption.implicitHeight+58:Math.max(Typography.rowHeight,caption.implicitHeight+8)
 Column {
  id:caption;x:0;y:root.stacked?0:(root.height-height)/2
  width:root.stacked?root.width:Math.max(0,slot.x-8);spacing:3
  Text {width:parent.width;text:root.label;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true;wrapMode:Text.WordWrap}

 }
 Item {
  id:slot;width:root.stacked?root.width:Math.min(root.controlWidth,root.width*0.52)
  x:root.stacked?0:root.width-width;y:root.stacked?caption.height+8:(root.height-height)/2;height:Typography.controlHeight
 }
}
