import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
 id:root;objectName:"debugMenu"
 pageIcon:"\uf188";pageTitle:qsTr("DEBUG")
 pageSubtitle:qsTr("MAVLink messages and unit hardware diagnostics")
 initialFocusItem:debugTabs
 onBackRequested:settings_form.side_bar_regain_focus()
 ColumnLayout {
     anchors.fill:parent;spacing:10
     AdvancedTabBar {
         id:debugTabs;objectName:"debugTabs";Layout.fillWidth:true;spacing:6
         AdvancedTabButton {objectName:"debugMavlinkTab";text:qsTr("MAVLINK");iconText:"\uf1e6"}
         AdvancedTabButton {objectName:"debugAirTab";text:qsTr("AIR");iconText:"\uf1d8"}
         AdvancedTabButton {objectName:"debugGroundTab";text:qsTr("GROUND");iconText:"\uf519"}
     }
     StackLayout {
         Layout.fillWidth:true;Layout.fillHeight:true;currentIndex:debugTabs.currentIndex
         AdvancedPageLoader {objectName:"debugMavlinkPage";selected:root.visible&&debugTabs.currentIndex===0;source:"MavlinkMessagesView.qml"}
         HardwareDiagnosticsPanel {objectName:"debugAirPage";settingsModel:_ohdSystemAirSettingsModel;systemModel:_ohdSystemAir}
         HardwareDiagnosticsPanel {objectName:"debugGroundPage";settingsModel:_ohdSystemGroundSettings;systemModel:_ohdSystemGround}
     }
 }
}
