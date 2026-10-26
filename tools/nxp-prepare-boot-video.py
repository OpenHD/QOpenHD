"""Package the bundled AVC MP4 for Hantro without any media framework.

This is a build-time reader for one non-fragmented avc1 track. Preserve decode
order and composition timestamps (the Pi boot movie contains B-frames).
"""
import argparse
import struct
from pathlib import Path


def prepare(source):
    data = source.read_bytes()
    if len(data) > 16 * 1024 * 1024:
        raise ValueError('boot movie exceeds 16 MiB')

    def u32(pos):
        return struct.unpack_from('>I', data, pos)[0]

    def boxes(start, end):
        while start < end:
            if start + 8 > end:
                raise ValueError('truncated MP4 box')
            size, kind = u32(start), data[start + 4:start + 8]
            header = 8
            if size == 1:
                size = struct.unpack_from('>Q', data, start + 8)[0]
                header = 16
            if size == 0:
                size = end - start
            if size < header or start + size > end:
                raise ValueError('invalid MP4 box size')
            yield kind, start + header, start + size
            start += size

    def child(parent, kind):
        return next((s, e) for k, s, e in boxes(*parent) if k == kind)

    def entries(box, stride):
        start, end = box
        count = u32(start + 4)
        if count > 10000 or start + 8 + count * stride != end:
            raise ValueError('invalid sample table')
        return start + 8, count

    moov = child((0, len(data)), b'moov')
    tracks = []
    for kind, start, end in boxes(*moov):
        if kind != b'trak':
            continue
        mdia = child((start, end), b'mdia')
        hdlr = child(mdia, b'hdlr')
        if data[hdlr[0] + 8:hdlr[0] + 12] == b'vide':
            tracks.append(mdia)
    if len(tracks) != 1:
        raise ValueError('expected exactly one video track')
    mdia = tracks[0]
    mdhd = child(mdia, b'mdhd')
    timescale = u32(mdhd[0] + (20 if data[mdhd[0]] else 12))
    if not timescale:
        raise ValueError('zero video timescale')
    stbl = child(child(mdia, b'minf'), b'stbl')
    stsd = child(stbl, b'stsd')
    if u32(stsd[0] + 4) != 1:
        raise ValueError('expected one sample description')
    kind, start, end = next(boxes(stsd[0] + 8, stsd[1]))
    if kind != b'avc1':
        raise ValueError('boot video must be AVC avc1')
    avcc, avcc_end = child((start + 78, end), b'avcC')
    length_size = (data[avcc + 4] & 3) + 1
    cursor, parameters = avcc + 6, []
    for count in [data[avcc + 5] & 31, None]:
        if count is None:
            count, cursor = data[cursor], cursor + 1
        for _ in range(count):
            size = struct.unpack_from('>H', data, cursor)[0]
            cursor += 2
            if not size or cursor + size > avcc_end:
                raise ValueError('invalid AVC parameter set')
            parameters.append(data[cursor:cursor + size])
            cursor += size
    stsz, stsz_end = child(stbl, b'stsz')
    fixed, count = u32(stsz + 4), u32(stsz + 8)
    if not 1 <= count <= 10000 or stsz + 12 + (0 if fixed else 4 * count) != stsz_end:
        raise ValueError('invalid sample sizes')
    sizes = [fixed] * count if fixed else [u32(stsz + 12 + i * 4) for i in range(count)]
    start, n = entries(child(stbl, b'stts'), 8)
    durations = []
    for i in range(n):
        samples, delta = struct.unpack_from('>II', data, start + i * 8)
        if not delta or samples > count - len(durations):
            raise ValueError('invalid sample durations')
        durations.extend([delta] * samples)
    if len(durations) != count or sum(durations) / timescale > 30:
        raise ValueError('invalid boot video duration')
    offsets = [0] * count
    ctts = next(((s, e) for k, s, e in boxes(*stbl) if k == b'ctts'), None)
    if ctts:
        start, n = entries(ctts, 8)
        offsets = []
        fmt = '>Ii' if data[ctts[0]] == 1 else '>II'
        for i in range(n):
            samples, offset = struct.unpack_from(fmt, data, start + i * 8)
            if samples > count - len(offsets):
                raise ValueError('invalid composition offsets')
            offsets.extend([offset] * samples)
        if len(offsets) != count:
            raise ValueError('missing composition offsets')
    start, n = entries(child(stbl, b'stsc'), 12)
    runs = [struct.unpack_from('>III', data, start + i * 12) for i in range(n)]
    if not runs or runs[0][0] != 1 or any(not num or description != 1 for _, num, description in runs):
        raise ValueError('invalid chunk map')
    chunk_box = next((k, s, e) for k, s, e in boxes(*stbl) if k in (b'stco', b'co64'))
    step = 4 if chunk_box[0] == b'stco' else 8
    start, n = entries(chunk_box[1:], step)
    chunks = [int.from_bytes(data[start + i * step:start + (i + 1) * step], 'big') for i in range(n)]
    samples, sample, run, dts = [], 0, 0, 0
    for chunk_number, pos in enumerate(chunks, 1):
        while run + 1 < len(runs) and runs[run + 1][0] <= chunk_number:
            run += 1
        for _ in range(runs[run][1]):
            if sample >= count:
                raise ValueError('too many chunk samples')
            end = pos + sizes[sample]
            if end > len(data):
                raise ValueError('sample outside file')
            nals = []
            while pos < end:
                if pos + length_size > end:
                    raise ValueError('truncated NAL length')
                size = int.from_bytes(data[pos:pos + length_size], 'big')
                pos += length_size
                if not size or pos + size > end:
                    raise ValueError('invalid NAL size')
                nals.append(data[pos:pos + size])
                pos += size
            if any(n[0] & 31 == 5 for n in nals):
                nals = parameters + nals
            elif sample == 0:
                raise ValueError('initial sample is not an IDR')
            au = b''.join(b'\0\0\0\1' + n for n in nals)
            samples.append((dts + offsets[sample], durations[sample], au))
            dts += durations[sample]
            sample += 1
    if sample != count:
        raise ValueError('missing samples')
    origin = min(pts for pts, _, _ in samples)
    result = bytearray(b'NXPBOOT1' + struct.pack('>I', count))
    for pts, duration, au in samples:
        result.extend(struct.pack('>IQI', len(au), (pts - origin) * 1000000 // timescale,
                                  duration * 1000000 // timescale))
        result.extend(au)
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output_dir', type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / 'boot-video.bin').write_bytes(prepare(args.source))
    (args.output_dir / 'boot-video.qrc').write_text(
        '<RCC><qresource prefix="/nxp"><file>boot-video.bin</file></qresource></RCC>\n')


if __name__ == '__main__':
    main()
