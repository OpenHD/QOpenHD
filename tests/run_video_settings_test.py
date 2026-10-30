"""Run production Video QML with deterministic compile-time capabilities."""
from pathlib import Path
import argparse,os,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--qt-bin',type=Path,required=True);args=parser.parse_args()
flags={'QOPENHD_IS_MOBILE':'mobile','QOPENHD_ENABLE_VIDEO_VIA_AVCODEC':'avcodec','QOPENHD_ENABLE_GSTREAMER_QMLGLSINK':'gstreamer','QOPENHD_ENABLE_NXP_VIDEO':'nativeVideo','QOPENHD_ENABLE_VIDEO_VIA_ANDROID':'androidVideo','QOPENHD_AUDIO_PLAYBACK_AVAILABLE':'audio'}
menu=ROOT/'qml/ui/configpopup'
with tempfile.TemporaryDirectory(prefix='qopenhd-video-settings-') as temp:
    folder=Path(temp);pages=folder/'pages';pages.mkdir()
    files=[menu/'MenuTypography.js',menu/'AdvancedActionButton.qml',ROOT/'qml/ui/elements/DarkComboBox.qml',menu/'openhd_settings/CompactLinkComboBox.qml']
    files += [menu/'qopenhd_settings'/name for name in ['AppVideoSettingsView.qml','VideoSettingsRow.qml','VideoSettingsGroup.qml','VideoNumberControl.qml','MapSettingRow.qml','MapSettingsCard.qml','MapValueSlider.qml','WidgetToggle.qml']]
    for path in files:
        content=path.read_text(encoding='utf-8')
        content=content.replace('../MenuTypography.js','MenuTypography.js').replace('../configpopup/MenuTypography.js','MenuTypography.js')
        for dep in ['import "../openhd_settings"','import "../../elements"','import ".."']:content=content.replace(dep,'')
        if path.name=='AppVideoSettingsView.qml':
            for flag,key in flags.items():content=content.replace(flag,'testCapabilities.'+key)
        (pages/path.name).write_text(content,encoding='utf-8')
    fixture=(ROOT/'tests/video_settings/fixture_video.qml').read_text(encoding='utf-8').replace('"../../qml/ui/configpopup/qopenhd_settings"','"pages"').replace('../../qml/',(ROOT/'qml').as_uri()+'/')
    (folder/'tst_video.qml').write_text(fixture,encoding='utf-8')
    env=os.environ.copy();env.update(QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_FORCE_STDERR_LOGGING='1',QT_SCALE_FACTOR='1')
    env['PATH']=str(args.qt_bin)+os.pathsep+env.get('PATH','')
    log=ROOT/'build'/('video-settings-'+args.qt_bin.parent.name+'.txt')
    result=subprocess.run([str(args.qt_bin/'qmltestrunner.exe'),'-input',str(folder),'-o',str(log)+',txt'],cwd=ROOT,env=env,timeout=60)
    print(log.read_text(encoding='utf-8') if log.exists() else 'No test log produced')
    raise SystemExit(result.returncode)
