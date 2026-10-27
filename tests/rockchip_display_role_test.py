"""The full-image display marker never starts a ground UI on configured Air units."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import sys
sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('display', Path(__file__).resolve().parents[1] / 'deployment/rockchip/display-enabled.py')
display = importlib.util.module_from_spec(spec)
spec.loader.exec_module(display)


class DisplayRole(unittest.TestCase):
    def test_full_only_and_persisted_role_precedence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertFalse(display.enabled(root))
            marker = root / 'etc/qopenhd-rockchip/native-video-enabled'
            marker.parent.mkdir(parents=True)
            marker.touch()
            self.assertTrue(display.enabled(root))
            air = root / 'Config/openhd/air.txt'
            air.parent.mkdir(parents=True)
            air.touch()
            self.assertFalse(display.enabled(root))
            config = root / 'usr/local/share/OpenHD/SysUtils/config.json'
            config.parent.mkdir(parents=True)
            for role, expected in [('ground', True), ('air', False), ('record', False), ('unset', True)]:
                config.write_text(json.dumps({'run_mode': role}))
                self.assertEqual(display.enabled(root), expected)
            for invalid in ['{broken', '[]']:
                config.write_text(invalid)
                self.assertFalse(display.enabled(root))


if __name__ == '__main__':
    unittest.main()
