"""Verify the production OSD/Application tab partition and keyboard navigation."""
from pathlib import Path
import argparse,os,shutil,subprocess,tempfile
parser=argparse.ArgumentParser();parser.add_argument('--qt-bin',required=True,type=Path);args=parser.parse_args()
root=Path(__file__).resolve().parents[1];menu=root/'qml/ui/configpopup'
with tempfile.TemporaryDirectory(prefix='qopenhd-menu-split-') as temp:
    folder=Path(temp);pages=folder/'qopenhd_settings';pages.mkdir()
    for name in ['AppSettingsPanel.qml','OsdSettingsPanel.qml','AppSettingsPageFrame.qml']:
        shutil.copy(menu/'qopenhd_settings'/name,pages/name)
    for name in ['AdvancedPageLoader.qml','AdvancedTabButton.qml','MenuTypography.js']:
        shutil.copy(menu/name,folder/name)
    for name in ['AppWidgetSettingsView','AppWidgetStyleSettingsView','AppGeneralSettingsView','AppVehicleSettingsView','AppVideoSettingsView','AppMapSettingsView','AppDevSettingsView']:
        (pages/(name+'.qml')).write_text('import QtQuick 2.12\nItem { objectName:"'+name+'";function gainFocus(){} }\n')
    mod=folder/'OpenHD';mod.mkdir();(mod/'qmldir').write_text('module OpenHD\nFixture 1.0 Fixture.qml\n');(mod/'Fixture.qml').write_text('import QtQuick 2.12\nQtObject {}')
    (folder/'tst_split.qml').write_text("""import QtQuick 2.12
import QtTest 1.2
import "qopenhd_settings" as Pages
Item {
 width:1000;height:650
 QtObject {id:settings_form;property bool darkMode:true;property bool showDeveloperSettings:false;property bool compactSidebar:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"white";property color secondaryText:"gray";property color accentColor:"#278cff";function side_bar_regain_focus(){} function frameworkActionButtons(){return []}}
 Pages.OsdSettingsPanel {id:osd;anchors.fill:parent}
 Pages.AppSettingsPanel {id:application;anchors.fill:parent;visible:false}
 TestCase {
  name:"OsdApplicationSplit";when:windowShown
  function test_partition(){
   compare(osd.availablePageIds.join(','),'0,1,5');compare(application.availablePageIds.join(','),'2,4')
   compare(findChild(osd,'settingsTab5').text,'MAP');compare(findChild(osd,'settingsTab2'),null)
   compare(findChild(application,'settingsTab2').text,'GENERAL');compare(findChild(application,'settingsTab0'),null)
   osd.currentPage=1;osd.moveTab(1,1);compare(osd.currentPage,5)
   application.currentPage=2;application.moveTab(2,1);compare(application.currentPage,4)
   settings_form.showDeveloperSettings=true;compare(application.availablePageIds.join(','),'2,4,6')
   application.currentPage=6;settings_form.showDeveloperSettings=false;compare(application.currentPage,2)
   compare(findChild(application,'settingsTab3'),null)
   application.currentPage=3;compare(application.currentPage,2)
   compare(osd.currentPage,5)
  }
 }
}
""")
    env=os.environ.copy();env.update(QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_QPA_PLATFORM='offscreen',QT_FORCE_STDERR_LOGGING='1',QML_DISABLE_DISK_CACHE='1',QML2_IMPORT_PATH=str(args.qt_bin.parent/'qml'),QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent/'plugins/platforms'))
    raise SystemExit(subprocess.run([str(args.qt_bin/'qmltestrunner.exe'),'-input',str(folder),'-import',str(folder)],env=env).returncode)
