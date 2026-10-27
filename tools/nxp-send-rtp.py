"""Send Annex B fixtures as low-delay H264/H265 RTP, without media frameworks."""
import argparse
import re
import socket
import struct
import time
import secrets
from pathlib import Path

def access_units(data, hevc):
    nals = [n for n in re.split(b"\x00\x00\x00?\x01", data) if n]
    units, current = [], []
    picture = False
    for nal in nals:
        kind = (nal[0] >> 1) & 63 if hevc else nal[0] & 31
        vcl = kind < 32 if hevc else kind in (1, 5)
        # first_slice_segment_in_pic_flag / first_mb_in_slice == 0. Keep all
        # slices of each picture together, including real clips without AUD NALs.
        first = vcl and (len(nal) > 2 and bool(nal[2] & 128) if hevc else len(nal) > 1 and bool(nal[1] & 128))
        config = kind in (32, 33, 34) if hevc else kind in (7, 8)
        if current and (kind == (35 if hevc else 9) or (picture and (first or config))):
            units.append(current)
            current = []
            picture = False
        current.append(nal)
        picture |= vcl
    if current:
        units.append(current)

    return units


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("file", type=Path)
    p.add_argument("host")
    p.add_argument("--port", type=int, default=5600)
    p.add_argument("--fps", type=int, default=120)
    p.add_argument("--loops", type=int, default=5)
    p.add_argument("--start-delay", type=float, default=0)
    p.add_argument("--drop-every", type=int, default=0, help="drop one RTP fragment every N pictures")
    p.add_argument("--openhd-stream", type=int, choices=(0, 1),
                   help="wrap RTP for OpenHD Ethernet ingress (use --port 5910)")
    args = p.parse_args()
    hevc = args.file.suffix == ".h265"
    units = access_units(args.file.read_bytes(), hevc)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sequence = 0
    source = secrets.randbits(32)
    time.sleep(args.start_delay)
    started = start = time.monotonic()
    pictures = 0
    for _ in range(args.loops):
        for unit in units:
            payloads = []
            for nal in unit:
                if len(nal) <= 1100:
                    payloads.append(nal)
                    continue
                header_size = 2 if hevc else 1
                body = nal[header_size:]
                chunks = [body[i:i+1097] for i in range(0, len(body), 1097)]
                for i, chunk in enumerate(chunks):
                    flags = (128 if i == 0 else 0) | (64 if i == len(chunks)-1 else 0)
                    if hevc:
                        header = bytes([(nal[0] & 0x81) | (49 << 1), nal[1], flags | ((nal[0] >> 1) & 63)])
                    else:
                        header = bytes([(nal[0] & 0xe0) | 28, flags | (nal[0] & 31)])
                    payloads.append(header + chunk)
            timestamp = (pictures * 90000 // args.fps) & 0xffffffff
            for i, payload in enumerate(payloads):
                header = struct.pack("!BBHII", 0x80, 96 | (128 if i == len(payloads)-1 else 0), sequence, timestamp, source)
                sequence = (sequence + 1) & 0xffff
                if not (args.drop_every and pictures % args.drop_every == args.drop_every-1 and i == len(payloads)//2):
                    packet = header + payload
                    if args.openhd_stream is not None:
                        packet = b'OHDV\x01' + bytes([args.openhd_stream]) + packet
                    sock.sendto(packet, (args.host, args.port))
            pictures += 1
            deadline = start + pictures / args.fps
            now = time.monotonic()
            # A delayed test sender must not burst several stale pictures at once
            # and turn scheduler jitter into artificial receiver queue overruns.
            if now > deadline + 1 / args.fps:
                start = now - (pictures - 1) / args.fps
                deadline = now + 1 / args.fps
            time.sleep(max(0, deadline - now))
    print(f"Sent {pictures} access units in {time.monotonic()-started:.3f}s")


if __name__ == "__main__":
    main()
