#!/usr/bin/env python3
"""Extract every bitmap character of the SWF (DefineBits/JPEG2/JPEG3/Lossless/Lossless2) to PNG.  usage: extract_bitmaps.py game.swf out_dir"""
import sys, os, io, struct, zlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
from swfscene import Swf
sw = Swf(sys.argv[1]); out = sys.argv[2]; os.makedirs(out, exist_ok=True)
tables = None
for t, d, pos in sw.tags:
    if t == 8: tables = d
def jpeg_fix(b): return b[4:] if b[:4] == b'\xff\xd9\xff\xd8' else b
n = 0
for cid, (typ, t, d) in sorted(sw.defs.items()):
    if typ != 'bitmap': continue
    if t == 6:
        tbs = tables[:-2] if tables[-2:] == b'\xff\xd9' else tables; data = d[2:]
        img = Image.open(io.BytesIO(tbs + (data[2:] if data[:2] == b'\xff\xd8' else data))).convert('RGBA')
    elif t == 21: img = Image.open(io.BytesIO(jpeg_fix(d[2:]))).convert('RGBA')
    elif t == 35:
        off = struct.unpack('<I', d[2:6])[0]
        img = Image.open(io.BytesIO(jpeg_fix(d[6:6 + off]))).convert('RGBA')
        alpha = zlib.decompress(d[6 + off:])
        if len(alpha) == img.width * img.height: img.putalpha(Image.frombytes('L', img.size, alpha))
    elif t in (20, 36):
        fmt = d[2]; w, h = struct.unpack('<HH', d[3:7]); p = 7
        if fmt == 3: nc = d[p] + 1; p += 1
        raw = zlib.decompress(d[p:])
        if fmt == 3:
            cs = 4 if t == 36 else 3
            pal = [raw[i * cs:(i + 1) * cs] for i in range(nc)]; stride = (w + 3) & ~3; px = raw[nc * cs:]; buf = bytearray()
            for y in range(h):
                for v in px[y * stride:y * stride + w]:
                    c = pal[v] if v < nc else b'\0\0\0\0'; buf += bytes(c) if cs == 4 else bytes(c) + b'\xff'
            img = Image.frombytes('RGBA', (w, h), bytes(buf))
        elif fmt == 5:
            arr = np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 4)
            A = arr[:, :, 0].astype(np.float32); R = arr[:, :, 1].astype(np.float32); G = arr[:, :, 2].astype(np.float32); B = arr[:, :, 3].astype(np.float32)
            if t == 36:
                with np.errstate(divide='ignore', invalid='ignore'): f = np.where(A > 0, 255.0 / A, 0)
                R = np.clip(R * f, 0, 255); G = np.clip(G * f, 0, 255); B = np.clip(B * f, 0, 255)
            img = Image.fromarray(np.stack([R, G, B, A], axis=2).astype(np.uint8), 'RGBA')
        elif fmt == 4:
            arr = np.frombuffer(raw, dtype=np.uint8); stride = (w * 2 + 3) & ~3; o = np.zeros((h, w, 4), np.uint8)
            for y in range(h):
                row = arr[y * stride:y * stride + w * 2].reshape(w, 2); v = (row[:, 0].astype(np.uint16) << 8) | row[:, 1]
                o[y, :, 0] = ((v >> 10) & 31) * 255 // 31; o[y, :, 1] = ((v >> 5) & 31) * 255 // 31; o[y, :, 2] = (v & 31) * 255 // 31; o[y, :, 3] = 255
            img = Image.fromarray(o, 'RGBA')
        else: continue
    else: continue
    img.save(os.path.join(out, f'{cid}.png')); n += 1
print('bitmaps extracted:', n)
