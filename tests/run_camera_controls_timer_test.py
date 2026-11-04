"""Exercise production camera sliders and compact flight-time formatting in Qt Quick."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--qt-bin', type=Path, required=True)
args = parser.parse_args()
menu = ROOT / 'qml/ui/configpopup'
widget = (ROOT / 'qml/ui/widgets/LinkOverviewWidgetBottom.qml').read_text(encoding='utf-8')
functions = widget[widget.index('    function pad2('):widget.index('    function format_home_distance(')]
fixture = (ROOT / 'tests/camera_controls/tst_controls.qml.in').read_text(encoding='utf-8').replace('FLIGHT_FUNCTIONS', functions)
with tempfile.TemporaryDirectory(prefix='qopenhd-camera-controls-') as temp:
    folder = Path(temp)
    files = [menu / 'MenuTypography.js', menu / 'AdvancedActionButton.qml',
             ROOT / 'qml/ui/elements/DarkComboBox.qml']
    files += [menu / 'openhd_settings' / name for name in
              ('CameraSettingRow.qml', 'InlineMavlinkParamControl.qml', 'CompactLinkComboBox.qml')]
    for path in files:
        content = path.read_text(encoding='utf-8')
        content = content.replace('../MenuTypography.js', 'MenuTypography.js').replace('../configpopup/MenuTypography.js', 'MenuTypography.js')
        for dep in ('import ".."', 'import "../../elements"'):
            content = content.replace(dep, '')
        (folder / path.name).write_text(content, encoding='utf-8')
    (folder / 'tst_controls.qml').write_text(fixture, encoding='utf-8')
    env = dict(os.environ, QT_QUICK_BACKEND='software', QT_QUICK_CONTROLS_STYLE='Basic',
               QT_FORCE_STDERR_LOGGING='1', QT_SCALE_FACTOR='1')
    env['PATH'] = str(args.qt_bin) + os.pathsep + env.get('PATH', '')
    raise SystemExit(subprocess.run([str(args.qt_bin / 'qmltestrunner.exe'), '-input', str(folder)], env=env, timeout=60).returncode)
