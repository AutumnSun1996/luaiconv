"""generate charset map data used by `iconv.lua`"""
import argparse
from pathlib import Path
import struct


TGT_CHAR = b'\0'


def compress(data, tgtCharCode, fmt='!B'):
    compressed = []
    count = 0
    last = None
    overflow = struct.unpack_from(fmt, b'\xff\xff\xff\xff')[0] + 1
    assert overflow > 0

    for byte in data:
        if byte == tgtCharCode:
            count += 1
            # avoid overflow
            if count == overflow:
                compressed.append(tgtCharCode)
                compressed.extend(struct.pack(fmt, count - 1))
                count = 0
        else:
            if last == tgtCharCode and count:
                compressed.append(tgtCharCode)
                compressed.extend(struct.pack(fmt, count - 1))
                count = 0
            compressed.append(byte)
        last = byte

    if last == tgtCharCode and count:
        compressed.append(tgtCharCode)
        compressed.extend(struct.pack(fmt, count - 1))

    return bytes(compressed)


def build_bindata(charset: str):
    """create bin data to be used by 'iconv.lua'"""
    start = 0x7F + 1
    end = 0xFFFF

    bindata = []
    for i in range(0, end + 1):
        if i < start:
            # bindata.append(TGT_CHAR+TGT_CHAR)
            continue
        try:
            data = chr(i).encode(charset)
            if len(data) > 2:
                raise ValueError(
                    f'max byte size is 2, got {len(data)} for {chr(i)!r}({i:04x})'
                )
            if len(data) == 1:
                data = TGT_CHAR + data
                # raise ValueError(f'min byte size is 2, got {len(data)} for {chr(i)!r}({i:04x})')
            if data == TGT_CHAR + TGT_CHAR:
                raise ValueError(f'encoded to conflict value: {chr(i)!r}')
        except UnicodeEncodeError:
            data = TGT_CHAR + TGT_CHAR
        bindata.append(data)

    bindata = b''.join(bindata)
    bindata = bindata.rstrip(TGT_CHAR)
    print('size', len(bindata))
    bindata = compress(bindata, ord(TGT_CHAR))
    dst = Path(f'data/{charset}.bin')
    dst.parent.mkdir(exist_ok=True)
    dst.write_bytes(bindata)
    print('size', len(bindata))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('charset', nargs='?', default='gbk')
    args = p.parse_args()
    build_bindata(args.charset)


if __name__ == '__main__':
    main()
