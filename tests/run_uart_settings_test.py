from pathlib import Path
import argparse,os,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--qt-bin',type=Path,required=True);args=p.parse_args()
menu=ROOT/'qml/ui/configpopup'
paths=[menu/'features/UartSettingsPanel.qml',menu/'MenuTypography.js',menu/'AdvancedActionButton.qml',menu/'AdvancedDialog.qml',menu/'AdvancedDialogButton.qml',menu/'openhd_settings/CompactLinkComboBox.qml',ROOT/'qml/ui/elements/DarkComboBox.qml']
paths += [menu/'openhd_settings'/name for name in ['AirSettingRow.qml','AirSettingsLayout.js','InlineMavlinkParamControl.qml']]
paths += [menu/'qopenhd_settings/MapSettingsCard.qml']
with tempfile.TemporaryDirectory(prefix='qopenhd-uart-') as temp:
    folder=Path(temp);pages=folder/'pages';pages.mkdir()
    for path in paths:
        text=path.read_text(encoding='utf-8').replace('../MenuTypography.js','MenuTypography.js').replace('../configpopup/MenuTypography.js','MenuTypography.js')
        for dep in ['import ".."','import "../qopenhd_settings"','import "../openhd_settings"','import "../../elements"']:text=text.replace(dep,'')
        (pages/path.name).write_text(text,encoding='utf-8')
    text=(ROOT/'tests/uart/fixture.qml').read_text(encoding='utf-8').replace('"../../qml/ui/configpopup/features"','"pages"').replace('../../qml/',(ROOT/'qml').as_uri()+'/')
    (folder/'tst_joystick.qml').write_text(text,encoding='utf-8')
    env=os.environ.copy();env['PATH']=str(args.qt_bin)+os.pathsep+env.get('PATH','')
    env.update(QT_SCALE_FACTOR='1',QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent/'plugins/platforms'),QML2_IMPORT_PATH=str(args.qt_bin.parent/'qml'))
    log=ROOT/'build'/('uart-settings-'+args.qt_bin.parent.name+'.txt')
    result=subprocess.run([str(args.qt_bin/'qmltestrunner.exe'),'-input',str(folder),'-o',str(log)+',txt'],cwd=ROOT,env=env,timeout=60)
    print(log.read_text(encoding='utf-8') if log.exists() else 'No Qt output')
    raise SystemExit(result.returncode)
