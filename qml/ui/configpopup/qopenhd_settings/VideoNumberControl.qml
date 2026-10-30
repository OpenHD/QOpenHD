import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

Item {
 id:root
 property int value:0
 property int from:0
 property int to:100
 property int stepSize:1
 signal modified(int value)
 implicitHeight:Typography.controlHeight
 function commit(candidate){
  if(!root.enabled || !isFinite(candidate))return
  var bounded=Math.max(from,Math.min(to,Math.round(candidate)))
  if(bounded!==value)modified(bounded)
  input.text=String(value)
 }
 onValueChanged:input.text=String(value)
 RowLayout {
  anchors.fill:parent;spacing:6
  AdvancedActionButton {objectName:root.objectName+"Decrease";Layout.preferredWidth:Typography.controlHeight;Layout.preferredHeight:Typography.controlHeight;implicitWidth:Typography.controlHeight;text:"-";enabled:root.value>root.from;onClicked:root.commit(root.value-root.stepSize)}
  TextField {
   id:input;objectName:root.objectName+"Input";Layout.fillWidth:true;Layout.minimumWidth:40;Layout.preferredHeight:Typography.controlHeight
   text:String(root.value);font.family:Typography.family;font.pixelSize:Typography.body;color:settings_form.primaryText
   horizontalAlignment:TextInput.AlignHCenter;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true
   leftPadding:6;rightPadding:6;topPadding:0;bottomPadding:0
   validator:IntValidator {bottom:root.from;top:root.to}
   onEditingFinished:{if(acceptableInput)root.commit(Number(text));else text=String(root.value)}
   background:Rectangle {radius:Typography.controlRadius;color:settings_form.pageBackground;border.color:input.activeFocus?settings_form.accentColor:settings_form.lineColor}
  }
  AdvancedActionButton {objectName:root.objectName+"Increase";Layout.preferredWidth:Typography.controlHeight;Layout.preferredHeight:Typography.controlHeight;implicitWidth:Typography.controlHeight;text:"+";enabled:root.value<root.to;onClicked:root.commit(root.value+root.stepSize)}
 }
}
