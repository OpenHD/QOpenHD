"""Verify Video through the compiled Application shell and real lazy page loader.

Example: py -3.12 tests/run_video_compiled_layout_test.py --qt-bin C:/Qt/5.15.19/mingw81_32/bin --make-bin C:/Qt/Tools/mingw810_32/bin
"""
from pathlib import Path
import argparse,os,subprocess,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--qt-bin',type=Path,required=True);parser.add_argument('--make-bin',type=Path,required=True);args=parser.parse_args()
folder=ROOT/'build'/('video-compiled-layout-'+args.qt_bin.parent.name);folder.mkdir(exist_ok=True)
menu=ROOT/'qml/ui/configpopup'
files=[menu/'MenuTypography.js',menu/'AdvancedActionButton.qml',menu/'AdvancedTabButton.qml',menu/'AdvancedPageLoader.qml',ROOT/'qml/ui/elements/DarkComboBox.qml',menu/'openhd_settings/CompactLinkComboBox.qml']
files += [menu/'qopenhd_settings'/n for n in ['AppVideoSettingsView.qml','AppSettingsPanel.qml','AppSettingsPageFrame.qml','VideoSettingsRow.qml','VideoSettingsGroup.qml','VideoNumberControl.qml','MapSettingRow.qml','MapSettingsCard.qml','MapValueSlider.qml','WidgetToggle.qml']]
resource=ET.Element('RCC');group=ET.SubElement(resource,'qresource',prefix='/')
for path in files:ET.SubElement(group,'file',alias=path.relative_to(ROOT/'qml').as_posix()).text=path.as_posix()
for name in ['AppGeneralSettingsView','AppDevSettingsView','AppVehicleSettingsView','AppMapSettingsView','AppWidgetSettingsView','AppWidgetStyleSettingsView']:
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
  context->setContextProperty("QOPENHD_IS_MOBILE",false);
  context->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_AVCODEC",true);
  context->setContextProperty("QOPENHD_ENABLE_GSTREAMER_QMLGLSINK",false);
  context->setContextProperty("QOPENHD_ENABLE_NXP_VIDEO",false);
  context->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_ANDROID",false);
  context->setContextProperty("QOPENHD_AUDIO_PLAYBACK_AVAILABLE",true);
 }
};
QUICK_TEST_MAIN_WITH_SETUP(video_layout,Setup)
#include "main.moc"
''',encoding='utf-8')
(folder/'test.pro').write_text('QT += quick qmltest quickcontrols2\nCONFIG += console c++17 qtquickcompiler\nTARGET = video_layout_test\nSOURCES += main.cpp\nRESOURCES += fixture.qrc\n',encoding='utf-8')
fixture=(ROOT/'tests/video_settings/fixture_video.qml').read_text(encoding='utf-8').replace('"../../qml/ui/configpopup/qopenhd_settings"','"qrc:/ui/configpopup/qopenhd_settings"').replace('../../qml/',(ROOT/'qml').as_uri()+'/')
fixture=fixture.replace('id:settings_form;','id:settings_form;property bool compactSidebar:true;function side_bar_regain_focus(){} function frameworkActionButtons(){return []} ')
fixture=fixture.replace('Pages.AppVideoSettingsView {anchors.fill:parent}','Pages.AppSettingsPanel {anchors.fill:parent;currentPage:4}')
fixture=fixture.replace('find(page,"videoSettingsScroll").contentY=0','tryVerify(function(){return find(page,"videoSettingsScroll")!==null});find(page,"videoSettingsScroll").contentY=0')
start=fixture.index('  function test_normal_layout_geometry(){');end=fixture.index('  function test_responsive_capture(){',start)
case=fixture[start:end].replace('test_normal_layout_geometry','test_application_video_layout')
case=case.replace('scene.width=sizes[i][0];wait(100)','scene.width=sizes[i][0];tryVerify(function(){var group=find(page,"videoDisplayGroup");return group!==null && group.width>150});wait(100)')
case=case.replace('   for(var i=0;i<sizes.length;i++){','   for(var mode=0;mode<3;mode++){\n   settings_form.showAdvancedSettings=mode===1;settings_form.showDeveloperSettings=mode===2\n   for(var i=0;i<sizes.length;i++){')
case=case.replace('"Zero-width display row at "+sizes[i][0]+": "+names[j]', '"Invalid display row: mode="+mode+" width="+row.width+" screen="+sizes[i][0]+" card="+display.width+" grid="+row.parent.width+" columns="+row.parent.columns+": "+names[j]')
case=case.replace('    for(var j=0;j<names.length;j++){','    if(mode>=1)names=names.concat(["videoRotationRow","videoFullscreenRow","videoTransparentSettingsRow"])\n    if(mode===2)names=names.concat(["videoTransparentBackgroundRow","videoSwapIntervalRow","videoFontDpiRow"])\n    for(var j=0;j<names.length;j++){')
case=case.replace('    grabImage(scene).save("build/video-normal-"+sizes[i][0]+".png")','    if(mode===0)grabImage(scene).save("build/video-compiled-normal-"+sizes[i][0]+".png")')
case=case[:-4]+'   }\n'+case[-4:]
fixture=fixture[:fixture.index('  function test_normal_and_two_streams(){')]+case+' }\n}\n'
(folder/'tst_compiled.qml').write_text(fixture,encoding='utf-8')
env=os.environ.copy();env['PATH']=str(args.qt_bin)+os.pathsep+str(args.make_bin)+os.pathsep+env.get('PATH','')
env.update(QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent/'plugins/platforms'),QML2_IMPORT_PATH=str(args.qt_bin.parent/'qml'),QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_SCALE_FACTOR='1',QT_FORCE_STDERR_LOGGING='1')
for command in [[str(args.qt_bin/'qmake.exe'),'test.pro'],[str(args.make_bin/'mingw32-make.exe'),'-j4']]:
    with (folder/'build.log').open('w',encoding='utf-8') as log:
        result=subprocess.run(command,cwd=folder,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    if result.returncode:print((folder/'build.log').read_text(encoding='utf-8'));raise SystemExit(result.returncode)
log=folder/'result.txt'
result=subprocess.run([str(folder/'release/video_layout_test.exe'),'-input',str(folder),'-o',str(log)+',txt'],cwd=ROOT,env=env,timeout=60)
print(log.read_text(encoding='utf-8') if log.exists() else 'No Qt results produced')
raise SystemExit(result.returncode)
