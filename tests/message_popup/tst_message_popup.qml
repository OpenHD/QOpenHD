import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/elements" as Elements
Item {
 id: scene; width: 850; height: 480
 FontLoader {source:"../../qml/osdfonts/Archivo-Regular.ttf"}
 FontLoader {source:"../../qml/osdfonts/Archivo-Bold.ttf"}
 FontLoader {source:"../../qml/resources/Font Awesome 5 Free-Solid-900.otf"}
 QtObject {
  id: _messageBoxInstance
  property bool visible: false
  property int remaining_time_seconds: -1
  property string text: "Changing the camera restarts the air unit."
  function okay_button_clicked() { visible = false }
 }
 QtObject {
  id: _qopenhd
  property string error_message_text: ""
  function show_error_message(value) { error_message_text = value }
 }
 Elements.WorkaroundMessageBox { id: message }
 Elements.ErrorMessageBox { id: errorPopup }
 TestCase {
  name: "SharedMessages"; when: windowShown
  function test_compact_message_and_dismissal() {
   _messageBoxInstance.visible = true
   tryCompare(message, "opened", true)
   compare(String(message.background.color), "#041d2c")
   verify(message.height < 220)
   verify(message.width <= 420)
   compare(String(message.palette.windowText), "#edf4fa")
   message.accept()
   compare(_messageBoxInstance.visible, false)
  }
  function test_long_message_small_window() {
   scene.width = 350; scene.height = 300
   _messageBoxInstance.text = new Array(60).join("A longer status message. ")
   _messageBoxInstance.visible = true
   tryCompare(message, "opened", true)
   verify(message.width <= 318)
   verify(message.height <= 268)
   verify(message.x >= 0 && message.y >= 0)
   message.reject()
   compare(_messageBoxInstance.visible, false)
   scene.width = 850; scene.height = 480
  }
  function test_error_uses_same_dialog() {
   _qopenhd.error_message_text = "Unable to change this setting."
   tryCompare(errorPopup, "opened", true)
   compare(String(errorPopup.background.color), "#041d2c")
   verify(errorPopup.height < 220)
   errorPopup.accept()
   compare(_qopenhd.error_message_text, "")
  }
 }
}
