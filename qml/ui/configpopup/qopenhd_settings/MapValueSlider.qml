import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
Item {
 id:control
 property alias from:slider.from
 property alias to:slider.to
 property alias stepSize:slider.stepSize
 property alias value:slider.value
 property string displayText:Math.round(value).toString()
 signal moved()
 implicitHeight:Typography.controlHeight
 RowLayout {
  anchors.fill:parent;spacing:12
  Slider {
   id:slider;Layout.fillWidth:true;Layout.minimumWidth:30;implicitHeight:Typography.controlHeight
   onMoved:control.moved()
   background:Rectangle {
    x:slider.leftPadding;y:slider.topPadding+(slider.availableHeight-height)/2
    width:slider.availableWidth;height:6;radius:3;color:settings_form.lineColor
    Rectangle {width:slider.visualPosition*parent.width;height:parent.height;radius:3;color:settings_form.accentColor}
   }
   handle:Rectangle {
    x:slider.leftPadding+slider.visualPosition*(slider.availableWidth-width)
    y:slider.topPadding+(slider.availableHeight-height)/2
    width:18;height:18;radius:9;color:"#f4f8fc";border.color:slider.activeFocus?settings_form.accentColor:"#b7cbd9"
   }
  }
  Rectangle {
   Layout.preferredWidth:62;Layout.preferredHeight:Typography.controlHeight;radius:6
   color:settings_form.pageBackground;border.color:settings_form.lineColor
   Text {anchors.centerIn:parent;text:control.displayText;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
  }
 }
}
