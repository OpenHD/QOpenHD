"""Check the bundled boot movie's B-frame timing and bounds without a decoder."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('boot_video', ROOT / 'tools/nxp-prepare-boot-video.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BootVideoTests(unittest.TestCase):
    def test_movie_preserves_composition_order_and_all_pictures(self):
        data = module.prepare(ROOT / 'qml/boot-video.mp4')
        self.assertEqual(data[:8], b'NXPBOOT1')
        count = struct.unpack_from('>I', data, 8)[0]
        self.assertEqual(count, 141)
        pos, timestamps, durations = 12, [], []
        for _ in range(count):
            size, pts, duration = struct.unpack_from('>IQI', data, pos)
            pos += 16
            self.assertTrue(data[pos:pos+size].startswith(b'\0\0\0\1'))
            self.assertLessEqual(pos+size, len(data))
            timestamps.append(pts)
            durations.append(duration)
            pos += size
        self.assertEqual(pos, len(data))
        self.assertEqual(min(timestamps), 0)
        self.assertNotEqual(timestamps, sorted(timestamps), 'B-frame PTS must not be replaced with decode timestamps')
        ordered = sorted(timestamps)
        self.assertTrue(all(41665 <= b-a <= 41668 for a, b in zip(ordered, ordered[1:])))
        self.assertAlmostEqual((max(timestamps)+durations[-1])/1e6, 141/24, places=4)

    def test_rejects_chunk_pointing_outside_the_movie(self):
        data = bytearray((ROOT / 'qml/boot-video.mp4').read_bytes())
        pos = data.index(b'stco')
        struct.pack_into('>I', data, pos+12, len(data)+1024)
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)/'invalid.mp4'
            path.write_bytes(data)
            with self.assertRaisesRegex(ValueError, 'outside file'):
                module.prepare(path)

    def test_rejects_truncated_box(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)/'invalid.mp4'
            path.write_bytes((ROOT / 'qml/boot-video.mp4').read_bytes()[:-10])
            with self.assertRaises(ValueError):
                module.prepare(path)


if __name__ == '__main__':
    unittest.main()
