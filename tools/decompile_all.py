#!/usr/bin/env python3
"""Decompile every DoInitAction block (= the AS2 classes: SetGame, MapData, ItemData, CoinItem, ...) of the SWF into readable pseudo-AS2.
usage: python3 decompile_all.py 고군분투.swf out_dir"""
import sys, os, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from swflib import load, iter_tags
from as2dec import decompile_code
swf, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
s = load(swf); body = s['body']
exports = {}
for t, d, pos in iter_tags(body, s['tagstart']):
    if t == 56:
        n = struct.unpack('<H', d[:2])[0]; p = 2
        for _ in range(n):
            cid = struct.unpack('<H', d[p:p+2])[0]; p += 2
            e = d.index(b'\0', p); exports[cid] = d[p:e].decode('utf-8', 'replace'); p = e + 1
for t, d, pos in iter_tags(body, s['tagstart']):
    if t == 59:
        sid = struct.unpack('<H', d[:2])[0]
        name = exports.get(sid, f'sprite{sid}').replace('__Packages.', '')
        open(os.path.join(out, name + '.as'), 'w', encoding='utf-8').write(decompile_code(d[2:]))
print('decompiled classes ->', out)
