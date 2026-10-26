"""Check install archive ownership, including the root directory entry."""
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class BundleTests(unittest.TestCase):
    def test_deployment_archive_is_owned_by_root(self):
        with tempfile.TemporaryDirectory(prefix='nxp-bundle-') as temporary:
            work = Path(temporary)
            deploy = work / 'deploy'
            runtime = deploy / 'usr/local/share/qopenhd-nxp'
            runtime.mkdir(parents=True)
            (runtime / 'test-file').write_bytes(b'unchanged contents')
            (runtime / 'test-link').symlink_to('test-file')
            output = work / 'runtime.tar.gz'
            subprocess.run(['bash', str(ROOT / 'tools/nxp-pack-deploy.sh'),
                            str(deploy), str(output)], check=True)
            with tarfile.open(output) as archive:
                entries = archive.getmembers()
                self.assertTrue(any(item.name == '.' for item in entries))
                for item in entries:
                    self.assertEqual((item.uid, item.gid), (0, 0), item.name)
                self.assertEqual(archive.extractfile('./usr/local/share/qopenhd-nxp/test-file').read(),
                                 b'unchanged contents')
                self.assertEqual(archive.getmember('./usr/local/share/qopenhd-nxp/test-link').linkname,
                                 'test-file')

if __name__ == '__main__':
    unittest.main()
