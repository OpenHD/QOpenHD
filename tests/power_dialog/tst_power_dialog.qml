import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import QtQuick.Window 2.12
import "../../qml/ui/configpopup/status" as Status
Item {
 id: scene; width: 800; height: 600
 FontLoader { source: "../../qml/osdfonts/Archivo-Regular.ttf" }
 FontLoader { source: "../../qml/osdfonts/Archivo-Bold.ttf" }
 FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
 QtObject { id: _ohdAction; property bool powerActionBusy: false
 signal powerActionFinished(bool ground, bool reboot, string result)
 function request_power_action(ground,reboot) { return "queued" }
 }
 QtObject { id: _fcMavlinkAction; function send_command_reboot(reboot) { return true } }
 QtObject { id: _qopenhd; function show_toast(message) {} }
 QtObject { id: settings_panel; function close_all() {} }
 Status.PowerActionDialoque { id: dialog }
 TestCase {
 name: "PowerDialog"; when: windowShown
 function test_content_fits_data() { return [{tag:"normal",w:800,h:600},{tag:"compact",w:430,h:350}] }
 function test_content_fits(data) {
 scene.Window.window.width=data.w;scene.Window.window.height=data.h
 scene.width=data.w;scene.height=data.h
 wait(30)
 dialog.open_dialoque(0,true);tryCompare(dialog,"opened",true)
 var warning=findChild(dialog,"powerActionWarning")
 var cancel=findChild(dialog,"powerActionCancel")
 var confirm=findChild(dialog,"powerActionConfirm")
 verify(dialog.width<=scene.width-32)
 verify(dialog.height<260,"Confirmation must size to its content")
 verify(warning.paintedWidth<=warning.width+1,"Warning must wrap within dialog")
 verify(warning.height>=warning.contentHeight)
 compare(cancel.width,confirm.width)
 compare(confirm.text,"Reboot Ground")
 verify(confirm.width>=confirm.contentItem.implicitWidth)
 mouseClick(cancel);tryCompare(dialog,"visible",false)
 }
 function test_request_pending_and_acknowledged() {
 dialog.open_dialoque(1,true);tryCompare(dialog,"opened",true)
 var confirm=findChild(dialog,"powerActionConfirm")
 compare(confirm.text,"Reboot Air")
 mouseClick(confirm)
 compare(dialog.powerRequestPending,true)
 compare(confirm.enabled,false)
 _ohdAction.powerActionFinished(true,true,"accepted")
 compare(dialog.powerRequestPending,true)
 _ohdAction.powerActionFinished(false,true,"accepted")
 compare(dialog.powerRequestPending,false)
 tryCompare(dialog,"visible",false)
 }
 }
}
