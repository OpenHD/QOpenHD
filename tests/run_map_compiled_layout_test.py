"""Verify Map through the compiled Application shell and real lazy page loader.

Example: py tests/run_map_compiled_layout_test.py --qt-bin C:/Qt/5.15.19/mingw81_32/bin --make-bin C:/Qt/Tools/mingw810_32/bin
"""
from pathlib import Path
import argparse,os,subprocess,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--qt-bin',type=Path,required=True);parser.add_argument('--make-bin',type=Path,required=True);parser.add_argument('--platform',default='windows' if os.name=='nt' else 'offscreen');args=parser.parse_args()
folder=ROOT/'build'/('map-compiled-layout-'+args.qt_bin.parent.name);folder.mkdir(parents=True,exist_ok=True)
menu=ROOT/'qml/ui/configpopup'
files=[menu/'SettingsBackButton.qml',menu/'settings-logo-dark.png',menu/'settings-logo-light.png',menu/'MenuTypography.js',menu/'AdvancedActionButton.qml',menu/'AdvancedTabButton.qml',menu/'AdvancedPageLoader.qml',ROOT/'qml/ui/elements/DarkComboBox.qml',menu/'openhd_settings/CompactLinkComboBox.qml']
files += [menu/'qopenhd_settings'/n for n in ['AppMapSettingsView.qml','AppSettingsPanel.qml','AppSettingsPageFrame.qml','MapSettingRow.qml','MapSettingsCard.qml','MapActionButton.qml','MapValueSlider.qml','WidgetToggle.qml']]
resource=ET.Element('RCC');group=ET.SubElement(resource,'qresource',prefix='/')
for path in files:ET.SubElement(group,'file',alias=path.relative_to(ROOT/'qml').as_posix()).text=path.as_posix()
for name in ['AppGeneralSettingsView','AppDevSettingsView','AppVehicleSettingsView','AppVideoSettingsView','AppWidgetSettingsView','AppWidgetStyleSettingsView']:
    path=folder/(name+'.qml');path.write_text('import QtQuick 2.12\nItem {function gainFocus(){}}\n',encoding='utf-8')
    ET.SubElement(group,'file',alias='ui/configpopup/qopenhd_settings/'+path.name).text=path.as_posix()
for name,text in [('qmldir','module OpenHD\nDummy 1.0 Dummy.qml\n'),('Dummy.qml','import QtQuick 2.12\nQtObject {}\n')]:
    path=folder/name;path.write_text(text,encoding='utf-8');ET.SubElement(group,'file',alias='OpenHD/'+name).text=path.as_posix()
ET.ElementTree(resource).write(folder/'fixture.qrc',encoding='unicode')
(folder/'main.cpp').write_text('''#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>
class Setup:public QObject {
 Q_OBJECT
public slots:
 void qmlEngineAvailable(QQmlEngine *engine){
  engine->addImportPath("qrc:/");
  auto context=engine->rootContext();
  context->setContextProperty("QOPENHD_IS_MOBILE",true);
  context->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_AVCODEC",true);
  context->setContextProperty("QOPENHD_ENABLE_GSTREAMER_QMLGLSINK",false);
  context->setContextProperty("QOPENHD_ENABLE_NXP_VIDEO",false);
  context->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_ANDROID",false);
  context->setContextProperty("QOPENHD_AUDIO_PLAYBACK_AVAILABLE",true);
 }
};
QUICK_TEST_MAIN_WITH_SETUP(map_layout,Setup)
#include "main.moc"
''',encoding='utf-8')
(folder/'test.pro').write_text('QT += quick qmltest quickcontrols2\nCONFIG += console c++17 qtquickcompiler\nTARGET = map_layout_test\nSOURCES += main.cpp\nRESOURCES += fixture.qrc\n',encoding='utf-8')
fixture=(ROOT/'tests/map_settings/tst_map_settings.qml').read_text(encoding='utf-8').replace('"../../qml/ui/configpopup/qopenhd_settings"','"qrc:/ui/configpopup/qopenhd_settings"').replace('../../qml/',(ROOT/'qml').as_uri()+'/')
fixture=fixture.replace('id:scene;width:1600;height:1000','id:scene;width:1600;height:1000;property bool layoutReady:false')
fixture=fixture.replace('id:settings_form;','id:settings_form;property bool compactSidebar:true;function side_bar_regain_focus(){} function frameworkActionButtons(){return []} ')
fixture=fixture[:fixture.index(' TestCase {')]
fixture=fixture.replace(' Pages.AppMapSettingsView {id:page;anchors.fill:parent;areaSelectionSource:Qt.resolvedUrl("SelectionFixture.qml")}',' Pages.AppSettingsPanel {id:shell;width:scene.layoutReady?scene.width:0;height:scene.height;osdMenu:true;currentPage:5}\n property var page:null')
fixture=fixture.replace('import QtTest 1.2','import QtTest 1.2\nimport "qrc:/ui/configpopup" as Menu')
fixture += r''' Menu.SettingsBackButton {id:packagedBack;width:64;height:76;visible:false}
 TestCase {
  name:"CompiledMapLayout";when:windowShown
  function initTestCase(){tryVerify(function(){return findChild(shell,"mapSettingsPage")!==null});page=findChild(shell,"mapSettingsPage");scene.layoutReady=true;tryVerify(function(){return page.width>150})}
  function test_packaged_logo(){var image=findChild(packagedBack,"settingsBackLogo");tryCompare(image,"status",Image.Ready);compare(packagedBack.text,"");verify(image.width>=52)}
  function test_adsb_geometry(){
   var sizes=[420,800,1100,1600]
   for(var i=0;i<sizes.length;i++){
    scene.Window.window.width=sizes[i];scene.width=sizes[i];wait(150)
    var card=findChild(page,"mapAdsbCard")
    var names=["mapAdsbEnabledRow","mapAdsbSourceRow","mapAdsbRadiusRow"]
    for(var j=0;j<names.length;j++){
     var row=findChild(page,names[j])
     verify(row.width>150,"Collapsed row "+names[j]+" at "+sizes[i]+": "+row.width)
     verify(row.height>=56,"Collapsed height: "+names[j])
     var pos=row.mapToItem(card,0,0)
     verify(pos.y>=40 && pos.y+row.height<=card.height,"Row outside card: "+names[j]+" y="+pos.y+" h="+row.height+" card="+card.height)
     if(j>0){var prev=findChild(page,names[j-1]);var old=prev.mapToItem(card,0,0);verify(Math.abs(pos.y-old.y)<1 ? pos.x>=old.x+prev.width : pos.y>=old.y+prev.height,"Rows overlap")}
    }
    var controls=["mapAdsbEnabled","mapAdsbInternet","mapAdsbSdr","mapAdsbRadius"]
    for(var k=0;k<controls.length;k++){
     var editor=findChild(page,controls[k]);var point=editor.mapToItem(card,0,0)
     verify(editor.width>20,"Collapsed editor: "+controls[k])
     verify(point.x>=0 && point.y>=40 && point.x+editor.width<=card.width+1 && point.y+editor.height<=card.height+1,"Editor outside ADS-B card: "+controls[k])
    }
    var scroll=findChild(page,"mapPageScroll")
    scroll.contentY=Math.max(0,card.mapToItem(page,0,0).y+scroll.contentY-20);wait(100)
    grabImage(scene).save("build/map-compiled-"+sizes[i]+".png")
   }
  }
 }
}
'''
(folder/'tst_compiled.qml').write_text(fixture,encoding='utf-8')
env=os.environ.copy();env['PATH']=str(args.qt_bin)+os.pathsep+str(args.make_bin)+os.pathsep+env.get('PATH','')
env.update(QT_QPA_PLATFORM=args.platform, QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent/'plugins/platforms'),QML2_IMPORT_PATH=str(args.qt_bin.parent/'qml'),QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_SCALE_FACTOR='1',QT_FORCE_STDERR_LOGGING='1')
for command in [[str(args.qt_bin/'qmake.exe'),'test.pro'],[str(args.make_bin/'mingw32-make.exe'),'-j4']]:
    with (folder/'build.log').open('w',encoding='utf-8') as log:
        result=subprocess.run(command,cwd=folder,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    if result.returncode:print((folder/'build.log').read_text(encoding='utf-8'));raise SystemExit(result.returncode)
log=folder/'result.txt'
result=subprocess.run([str(folder/'release/map_layout_test.exe'),'-input',str(folder),'-o',str(log)+',txt'],cwd=ROOT,env=env,timeout=60)
print(log.read_text(encoding='utf-8') if log.exists() else 'No Qt results produced')
raise SystemExit(result.returncode)
