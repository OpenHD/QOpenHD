"""Exercise production startup focus scopes and HUD/sidebar key handlers in Qt 5.

python tests/run_keyboard_navigation_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
The small fixture omits telemetry/video but reads the handlers and startup Loader
declarations directly from QML, so a focus regression changes runtime behavior.
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
    opening = text.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]


def loader(path, name, source):
    text = (ROOT / "qml" / path).read_text(encoding="utf-8")
    start = text.rfind("Loader {", 0, text.index("id: " + name))
    declaration = block(text[start:], "Loader")
    return re.sub(r'source: "[^"]+"', 'source: "' + source + '"', declaration)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", required=True, type=Path)
    args = parser.parse_args()
    hud = (ROOT / "qml/ui/HUDOverlayGrid.qml").read_text(encoding="utf-8")
    sidebar = (ROOT / "qml/ui/sidebar/SideBarMain.qml").read_text(encoding="utf-8")
    button = (ROOT / "qml/ui/sidebar/SidebarStackButton.qml").read_text(encoding="utf-8")
    fixture = '''import QtQuick 2.12
Item {
    id: hudOverlayGrid; focus: true
    property alias sidebar: sidebar
    property alias m_stack_index: sidebar.m_stack_index
    QtObject { id: actual_hud_elements; property bool visible: true }
    %s
    %s
    Item {
        id: sidebar
        property bool m_extra_is_visible: false
        property bool m_is_active: false
        property int m_stack_index: -1
        QtObject { id: stack_manager; property bool visible: false }
        QtObject { id: choiceSelector; function discard_and_close() {} }
        %s
        %s
        function handover_joystick_control_to_button(index) { button.forceActiveFocus() }
        Item { id: button; objectName: "sidebarButton"
            property string override_tag: "test"
            %s
        }
    }
    Component.onCompleted: regain_focus()
}
''' % (block(hud, "function regain_focus()"), block(hud, "Keys.onPressed:"),
       block(sidebar, "function open_and_take_control("), block(sidebar, "function close()"),
       block(button, "Keys.onPressed:"))
    desktop = loader("main.qml", "flightUi", "Hud.qml")
    pi_inner = loader("PiFlightContent.qml", "flightUi", "Hud.qml")
    pi_outer = loader("PiStartupWindow.qml", "flightContent", "PiFlight.qml")
    test = '''import QtQuick 2.12
import QtTest 1.2
Item {
    id: applicationWindow; width: 850; height: 480
    property bool bootSplashEnabled: false
    property bool firstFrameShown: true
    %s
    Item { id: otherFocus }
    TestCase {
        name: "KeyboardNavigation"; when: windowShown
        function test_startup_and_sidebar_roundtrip() {
            %s
            tryCompare(flightUi, "status", Loader.Ready)
            var hud = flightUi.item
            %s
            tryCompare(hud, "activeFocus", true)
            keyClick(Qt.Key_Down)
            compare(hud.sidebar.m_extra_is_visible, true)
            compare(hud.sidebar.m_stack_index, 0)
            keyClick(Qt.Key_Down)
            compare(hud.sidebar.m_stack_index, 1)
            keyClick(Qt.Key_Up)
            keyClick(Qt.Key_Up)
            compare(hud.sidebar.m_extra_is_visible, false)
            tryCompare(hud, "activeFocus", true)
            keyClick(Qt.Key_Right)
            compare(hud.sidebar.m_extra_is_visible, true)
            hud.sidebar.close()
            hud.enabled = false
            otherFocus.forceActiveFocus()
            compare(otherFocus.activeFocus, true)
            hud.regain_focus()
            compare(hud.enabled, true)
            tryCompare(hud, "activeFocus", true)
            keyClick(Qt.Key_Down)
            compare(hud.sidebar.m_extra_is_visible, true)
        }
    }
}
'''
    env = os.environ.copy()
    env["PATH"] = str(args.qt_bin) + os.pathsep + env["PATH"]
    env.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               QT_FORCE_STDERR_LOGGING="1",
               QML2_IMPORT_PATH=str(args.qt_bin.parent / "qml"),
               QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent / "plugins/platforms"))
    with tempfile.TemporaryDirectory(prefix="qopenhd-keyboard-") as temp:
        folder = Path(temp)
        (folder / "Hud.qml").write_text(fixture, encoding="utf-8")
        (folder / "PiFlight.qml").write_text(
            'import QtQuick 2.12\nItem { ' + pi_inner + ' }', encoding="utf-8")
        cases = [
            ("desktop", desktop, "", ""),
            ("desktop_async", desktop, "applicationWindow.firstFrameShown = true", ""),
            ("pi", pi_outer.replace("id: flightContent", "id: flightUi"),
             "flightUi.active = true", "hud = hud.children[0].item"),
        ]
        for name, declaration, setup, unwrap in cases:
            path = folder / ("tst_" + name + ".qml")
            scene = test % (declaration, setup, unwrap)
            if name == "desktop_async":
                scene = scene.replace("bootSplashEnabled: false", "bootSplashEnabled: true")
                scene = scene.replace("firstFrameShown: true", "firstFrameShown: false")
            path.write_text(scene, encoding="utf-8")
        return subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder)],
                              env=env, timeout=60).returncode


if __name__ == "__main__":
    raise SystemExit(main())
