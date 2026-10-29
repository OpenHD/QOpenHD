import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/video" as Video
Item {
 id:scene;width:850;height:480
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {id:settings;property int secondary_video_minimized_width:320;property int secondary_video_minimized_height:240;property int secondary_video_maximize_factor_perc:200}
 Video.SecondaryVideoSettingsPopup {id:popup}
 TestCase {name:"SecondaryVideoSettings";when:windowShown
 function visualChild(item,name){if(item.objectName===name)return item;var nodes=item.children||[];for(var i=0;i<nodes.length;i++){var result=visualChild(nodes[i],name);if(result)return result}return null}
 function test_popup(){
 popup.open();tryCompare(popup,"opened",true)
 compare(String(popup.background.color),"#041d2c")
 verify(popup.width<scene.width);verify(popup.height<scene.height)
 var editor=visualChild(popup.contentItem,"secondaryVideoSetting0")
 compare(editor.value,320);editor.forceActiveFocus();keyClick(Qt.Key_Up)
 compare(settings.secondary_video_minimized_width,321)
 settings.secondary_video_minimized_height=280
 compare(visualChild(popup.contentItem,"secondaryVideoSetting1").value,280)
 var factor=visualChild(popup.contentItem,"secondaryVideoSetting2");factor.forceActiveFocus();keyClick(Qt.Key_Up)
 compare(settings.secondary_video_maximize_factor_perc,201)
 scene.width=350;scene.height=300;wait(50)
 verify(popup.x>=0 && popup.y>=0);verify(popup.width<=scene.width-24);verify(popup.height<=scene.height-24)
 popup.close()
 }
 }
}
