"""Picture grouping regression for actual AUD-less, multi-slice movie input."""
import importlib.util
from pathlib import Path
import unittest
import sys
sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('sender', Path(__file__).resolve().parents[1] / 'tools/nxp-send-rtp.py')
sender = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sender)


class PictureGroupingTests(unittest.TestCase):
    def test_h264_without_aud_keeps_slices_together(self):
        nals = [b'\x67sps', b'\x68pps', b'\x65\x80first', b'\x65\x40second',
                b'\x41\x80next', b'\x41\x40slice', b'\x67sps', b'\x68pps', b'\x65\x80idr']
        data = b''.join((b'\0\0\1' if i % 2 else b'\0\0\0\1') + n for i, n in enumerate(nals))
        self.assertEqual(sender.access_units(data, False), [nals[:4], nals[4:6], nals[6:]])

    def test_hevc_without_aud_keeps_slices_together(self):
        nals = [b'\x40\x01vps', b'\x42\x01sps', b'\x44\x01pps',
                b'\x26\x01\x80idr', b'\x26\x01\x00slice', b'\x02\x01\x80next']
        data = b''.join(b'\0\0\0\1' + n for n in nals)
        self.assertEqual(sender.access_units(data, True), [nals[:5], nals[5:]])

    def test_existing_aud_fixtures(self):
        nals = [b'\x09aud', b'\x65\x80idr', b'\x65\x40slice', b'\x09aud', b'\x41\x80next']
        self.assertEqual(sender.access_units(b''.join(b'\0\0\1' + n for n in nals), False), [nals[:3], nals[3:]])


if __name__ == '__main__':
    unittest.main()
