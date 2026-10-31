"""Run production power handlers and CmdSender with GUI-thread MAVLink replies.

Only the radio transport and unrelated OHDAction methods are replaced. The QML
buttons/handlers are read from the production dialog, without its status-card
dependencies. No reboot command is executed.
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def block(text, marker):
    start = text.index(marker)
    opening = text.index('{', start)
    depth, end = 1, opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qt-bin', required=True, type=Path)
    parser.add_argument('--make', default='mingw32-make' if os.name == 'nt' else 'make')
    args = parser.parse_args()
    source = (ROOT / 'app/telemetry/action/ohdaction.cpp').read_text(encoding='utf-8')
    methods = '\n'.join(block(source, marker) for marker in (
        'bool OHDAction::send_command_reboot_air(',
        'bool OHDAction::send_command_reboot_gnd(',
        'QString OHDAction::request_power_action('))
    qml = (ROOT / 'qml/ui/configpopup/status/PowerActionDialoque.qml').read_text(encoding='utf-8')
    sections = [block(qml, marker) for marker in (
        'enum PowerAction', 'function open_dialoque(',
        'function finish_power_action(', 'Connections {')]
    properties = re.findall(r'^    property (?:bool|int) .*$', qml, re.M)
    sections.append(block(qml, 'readonly property string actionLabel:'))
    for name in ('powerActionCancel', 'powerActionConfirm'):
        start = qml.rfind('AdvancedDialogButton {', 0, qml.index('objectName: "' + name + '"'))
        button = block(qml[start:], 'AdvancedDialogButton {').replace('AdvancedDialogButton {', 'Button {', 1)
        # Styling is checked by power_dialog; retain production click/enabled logic.
        button = button.replace('                destructive: true', '')
        sections.append(button)
    fixture = '''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
Item {
    id: powerDialog; width: 400; height: 240
    Component.onCompleted: visible = false
    function open() { visible = true }
    function reject() { visible = false }
PROPERTIES
SECTIONS
}
'''.replace('PROPERTIES', '\n'.join(properties)).replace('SECTIONS', '\n'.join(sections))
    env = dict(os.environ, PATH=str(args.qt_bin) + os.pathsep + os.environ.get('PATH', ''),
               QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    # Windows build helpers can briefly retain their working-directory handle.
    with tempfile.TemporaryDirectory(prefix='qopenhd-power-', ignore_cleanup_errors=True) as temporary:
        folder = Path(temporary)
        (folder / 'PowerActionDialoque.qml').write_text(fixture, encoding='utf-8')
        sender = (ROOT / 'app/telemetry/action/impl/cmdsender.cpp').read_text(encoding='utf-8')
        sender = sender.replace('#include "util/uisimulator.h"', '').replace('../../tutil/qopenhdmavlinkhelper.hpp', 'telemetry/tutil/qopenhdmavlinkhelper.hpp').replace('../../MavlinkTelemetry.h', 'telemetry/MavlinkTelemetry.h')
        (folder / 'cmdsender_for_test.cpp').write_text(sender, encoding='utf-8')
        template = (ROOT / 'tests/power_action_test.cpp.in').read_text(encoding='utf-8')
        (folder / 'power_action_test.cpp').write_text(template.replace('@POWER_ACTION_METHODS@', methods), encoding='utf-8')
        (folder / 'power_action_test.pro').write_text(
            'QT = core gui qml quick\nCONFIG += console c++17\nCONFIG -= app_bundle\n'
            'TARGET = power_action_test\nSOURCES += power_action_test.cpp\n'
            f'INCLUDEPATH += "{ROOT.as_posix()}/app" "{ROOT.as_posix()}/app/telemetry" "{ROOT.as_posix()}/app/telemetry/action/impl"\n',
            encoding='utf-8')
        for command in ([str(args.qt_bin / 'qmake'), 'power_action_test.pro'], [args.make, '-j4']):
            result = subprocess.run(command, cwd=folder, env=env, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
            if result.returncode:
                print(result.stdout)
                return result.returncode
        executable = folder / ('release/power_action_test.exe' if os.name == 'nt' else 'power_action_test')
        return subprocess.run([str(executable), str(folder / 'PowerActionDialoque.qml')],
                              cwd=folder, env=env, timeout=30).returncode


if __name__ == '__main__':
    raise SystemExit(main())
