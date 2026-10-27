"""Check the real native .deb payload and its runtime-only dependencies."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NativePackages(unittest.TestCase):
    def test_native_dependencies_exclude_media_frameworks_and_build_tools(self):
        dependencies = (ROOT / 'ci/rockchip-runtime-dependencies.txt').read_text().splitlines()
        for dependency in dependencies:
            self.assertNotIn('-dev', dependency)
            self.assertNotIn('qmake', dependency)
            self.assertNotIn('gstreamer', dependency)
            self.assertNotIn('libav', dependency)
        self.assertIn('weston', dependencies)
        self.assertIn('qtwayland5', dependencies)

    def test_built_native_packages(self):
        packages = list(Path(os.environ.get('QOPENHD_PACKAGE_DIR', ROOT)).glob('qopenhd-native-*.deb'))
        if os.environ.get('CROSS_TARGET', '').startswith('rock-'):
            self.assertEqual(len(packages), 2, 'Both native Rockchip family packages must be produced')
        for package in packages:
            with self.subTest(package=package.name), tempfile.TemporaryDirectory() as fixture:
                members = subprocess.check_output(['ar', 't', str(package)], text=True).splitlines()
                self.assertIn('control.tar.xz', members)
                self.assertIn('data.tar.xz', members)
                subprocess.run(['dpkg-deb', '-x', str(package), fixture], check=True)
                base = Path(fixture) / 'usr/local/share/qopenhd-rockchip'
                for filename in ['QOpenHD', 'openhd-boot-splash', 'boot-logo.png', 'mali/egl-platform-compat.so',
                                 'run-qopenhd.sh', 'run-compositor.sh', 'display-enabled.py',
                                 'deployment/qopenhd.service', 'deployment/openhd-rockchip-boot-splash.service']:
                    self.assertGreater((base / filename).stat().st_size, 0, filename)
                self.assertEqual((base / 'native-video.version').read_text().strip(), '1')
                # Package install alone must not activate the compositor on Lite.
                self.assertFalse((Path(fixture) / 'etc/qopenhd-rockchip/native-video-enabled').exists())
                self.assertEqual((Path(fixture) / 'usr/local/bin/QOpenHD').resolve(), base / 'QOpenHD')
                dependencies = subprocess.check_output(['dpkg-deb', '-f', str(package), 'Depends'], text=True)
                for forbidden in ['-dev', 'qmake', 'gstreamer', 'libavcodec', 'libavformat']:
                    self.assertNotIn(forbidden, dependencies)
                dynamic = subprocess.check_output(['readelf', '-d', str(base / 'QOpenHD')], text=True)
                for forbidden in ['libavcodec', 'libavformat', 'libgstreamer', 'libimxvpuapi', 'libimxdmabuffer']:
                    self.assertNotIn(forbidden, dynamic)
                self.assertIn('librockchip_mpp.so', dynamic)
                if 'distribution=bullseye' in (base / 'build-info.txt').read_text():
                    self.assertTrue((base / 'kiosk-shell-black.so').is_file())
                    self.assertIn('weston (<< 10)', dependencies)
                    self.assertTrue((base / 'licenses/weston-kiosk/COPYING').is_file())
                for filename in ['QOpenHD', 'openhd-boot-splash', 'mali/egl-platform-compat.so']:
                    header = subprocess.check_output(['readelf', '-h', str(base / filename)], text=True)
                    self.assertRegex(header, r'Machine:\s+AArch64')


if __name__ == '__main__':
    unittest.main()
