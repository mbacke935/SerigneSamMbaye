"""Generate assets/icons/icon_app.png — 512x512 green background + gold circle.
No third-party deps: uses only struct + zlib from the stdlib.
"""
import os
import struct
import zlib

W = H = 512
# Colors
BG = (15, 61, 46)      # #0F3D2E
GOLD = (200, 162, 74)  # #C8A24A
WHITE = (255, 255, 255)

def make_pixel_row(y):
    row = bytearray()
    cx, cy, r = W // 2, H // 2, 200
    ring = 16
    for x in range(W):
        dx, dy = x - cx, y - cy
        dist2 = dx * dx + dy * dy
        if r - ring <= (dist2 ** 0.5) <= r:
            c = GOLD
        elif dist2 < (r - ring) ** 2:
            # Simple headphones icon in center
            hx, hy = cx, cy - 20
            ear_r = 55
            ear_w = 22
            # arc top: y < hy, dist from (hx,hy) in [ear_r-ear_w..ear_r]
            ax, ay = x - hx, y - hy
            ad = (ax * ax + ay * ay) ** 0.5
            if ay <= 0 and ear_r - ear_w <= ad <= ear_r:
                c = WHITE
            # left ear cup: circle around (hx-ear_r, hy)
            elif ((x-(hx-ear_r))**2 + (y-(hy+5))**2) < (ear_w+4)**2:
                c = WHITE
            # right ear cup
            elif ((x-(hx+ear_r))**2 + (y-(hy+5))**2) < (ear_w+4)**2:
                c = WHITE
            else:
                c = BG
        else:
            c = BG
        row += bytes(c)
    return bytes(row)


def png_chunk(tag, data):
    c = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', c)


def write_png(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    raw = b''
    for y in range(H):
        raw += b'\x00' + make_pixel_row(y)
    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(png_chunk(b'IHDR', ihdr))
        f.write(png_chunk(b'IDAT', compressed))
        f.write(png_chunk(b'IEND', b''))
    print(f'Written: {path} ({W}x{H} PNG)')


if __name__ == '__main__':
    write_png('frontend/assets/icons/icon_app.png')
