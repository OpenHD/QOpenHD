"""Exercise the actual settings header button with software rendering."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--qt-bin', type=Path, required=True)
parser.add_argument('--output-dir', type=Path, required=True)
parser.add_argument('--platform', default='offscreen')
args = parser.parse_args()
output = args.output_dir.resolve()
output.mkdir(parents=True, exist_ok=True)
menu = ROOT / 'qml/ui/configpopup'
source = (menu / 'ConfigPopup.qml').read_text(encoding='utf-8')
start = source.rfind('Column {', 0, source.index('id: brand'))
opening = source.index('{', start)
depth, end = 1, opening + 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
brand = source[start:end]
fixture = '''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
Item {
    id: settings_form
    width: 320; height: 180
    FontLoader { id: regularFont; source: "Archivo-Regular.ttf" }
    FontLoader { id: boldFont; source: "Archivo-Bold.ttf" }
    property bool compactSidebar: true
    property bool darkMode: true
    property int closed: 0
    function close_all() { ++closed }
    Rectangle {
        id: rail
        width: settings_form.compactSidebar ? 72 : 180
        height: parent.height
        color: settings_form.darkMode ? "#0b1b2b" : "#ffffff"
        BRAND
    }
    TestCase {
        name: "SettingsBackButton"; when: windowShown
        function button() { return findChild(settings_form,"settingsBackButton") }
        function init() { tryCompare(regularFont,"status",FontLoader.Ready);tryCompare(boldFont,"status",FontLoader.Ready);compactSidebar=true;darkMode=true;closed=0;wait(20) }
        function test_compact_touch_area() {
            var b=button()
            compare(b.width,64);compare(b.height,76)
            compare(b.text,"")
            var logo=findChild(b,"settingsBackLogo")
            verify(logo !== null);tryCompare(logo,"status",Image.Ready)
            verify(logo.width >= 52)
            verify(b.x>=0 && b.x+b.width<=rail.width)
            mouseClick(b,2,2);compare(closed,1)
            mouseClick(b,b.width-2,2);compare(closed,2)
            mouseClick(b,2,b.height-2);compare(closed,3)
            mouseClick(b,b.width-2,b.height-2);compare(closed,4)
        }
        function test_keyboard() {
            button().forceActiveFocus()
            keyClick(Qt.Key_Space);compare(closed,1)
        }
        function test_expanded() {
            compactSidebar=false;wait(20)
            compare(button().width,156);compare(button().height,76)
            mouseClick(button());compare(closed,1)
        }
        function test_render_both_themes() {
            mouseMove(settings_form,300,160)
            button().focus=false
            wait(40)
            var dark=grabImage(button())
            verify(dark.width>0)
            dark.save(OUTPUT + "/back-dark.png")
            darkMode=false;wait(40)
            var light=grabImage(button())
            verify(light.width>0)
            light.save(OUTPUT + "/back-light.png")
        }
    }
}
'''.replace('BRAND', brand).replace('OUTPUT', json.dumps(output.as_posix()))
with tempfile.TemporaryDirectory(prefix='qopenhd-back-button-') as temp:
    folder = Path(temp)
    for name in ('SettingsBackButton.qml', 'settings-logo-dark.png', 'settings-logo-light.png', 'MenuTypography.js'):
        shutil.copy2(menu / name, folder / name)
    for name in ('Archivo-Regular.ttf', 'Archivo-Bold.ttf'):
        shutil.copy2(ROOT / 'qml/osdfonts' / name, folder / name)
    (folder / 'tst_back.qml').write_text(fixture, encoding='utf-8')
    env = dict(os.environ, QT_QPA_PLATFORM=args.platform,
               QT_QUICK_BACKEND='software', QT_QUICK_CONTROLS_STYLE='Basic',
               QT_FORCE_STDERR_LOGGING='1', QT_SCALE_FACTOR='1', QT_SCREEN_SCALE_FACTORS='1')
    env['PATH'] = str(args.qt_bin) + os.pathsep + env.get('PATH', '')
    runner = args.qt_bin / ('qmltestrunner.exe' if os.name == 'nt' else 'qmltestrunner')
    raise SystemExit(subprocess.run([str(runner), '-input', str(folder)], env=env, timeout=40).returncode)
