import "../MenuTypography.js" as Typography
import QtQuick 2.12

Item {
 id:root
 property alias label:setting.label
 property alias hint:setting.hint
 property alias controlWidth:setting.controlWidth
 property alias minimumControlWidth:setting.minimumControlWidth
 property string icon:""
 default property alias editor:setting.control
 implicitHeight:setting.implicitHeight+12
 Text {x:12;y:(root.height-height)/2;visible:root.icon.length>0;text:root.icon;color:settings_form.secondaryText;font.family:"Font Awesome 5 Free";font.pixelSize:Typography.rowIcon}
 MapSettingRow {id:setting;x:root.icon.length?46:14;y:6;width:Math.max(0,root.width-x-14);height:implicitHeight}
 Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:settings_form.lineColor}
}
