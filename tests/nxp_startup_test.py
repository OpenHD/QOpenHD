"""Exercise launcher environment/readiness with PAM's competing runtime dir."""
from pathlib import Path
import os
import shutil
import socket
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]

class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='nxp-start-')
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name)
        self.private = self.work / 'service-runtime'
        self.pam = self.work / 'pam-runtime'
        self.private.mkdir()
        self.pam.mkdir()
        self.env = dict(os.environ, XDG_RUNTIME_DIR=str(self.pam),
                        RUNTIME_DIRECTORY=str(self.private))
        self.env.pop('NXP_RUNTIME_DIR', None)
        self.env.pop('NXP_DEBUG_SERVER', None)

    def install(self, script, executable):
        launcher = self.work / script
        shutil.copyfile(ROOT / 'tools' / script, launcher)
        fake = self.work / executable
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$XDG_RUNTIME_DIR"\n')
        fake.chmod(0o755)
        return launcher

    def test_compositor_uses_service_directory_after_pam_override(self):
        launcher = self.install('nxp-run-weston.sh', 'weston')
        result = subprocess.run(['sh', str(launcher), 'headless'], env=self.env,
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout.strip(), str(self.private))

    def test_qt_waits_for_socket_in_explicit_shared_directory(self):
        launcher = self.install('nxp-run-qopenhd.sh', 'QOpenHD')
        env = dict(self.env, NXP_RUNTIME_DIR=str(self.private),
                   WAYLAND_DISPLAY='wayland-qopenhd', QT_QPA_PLATFORM='wayland')
        with subprocess.Popen(['sh', str(launcher)], env=env, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
            time.sleep(0.2)
            self.assertIsNone(process.poll(), 'Qt started before its compositor socket existed')
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(str(self.private / 'wayland-qopenhd'))
                server.listen(1)
                stdout, stderr = process.communicate(timeout=3)
            self.assertEqual(process.returncode, 0, stderr)
            self.assertEqual(stdout.strip(), str(self.private))

if __name__ == '__main__':
    unittest.main()
