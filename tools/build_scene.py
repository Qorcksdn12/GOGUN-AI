#!/usr/bin/env python3
"""Extract everything the gameplay scene needs from 고군분투.swf into scene.json:
vector/bitmap shapes (as SVG-path JSON), sprite timelines, WebP bitmaps.  (pure python, no external tools)"""
import sys, json, os, io, base64, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from swfscene import *
from shapes import parse_shape
from PIL import Image
sw = Swf(sys.argv[1] if len(sys.argv) > 1 else 'game.swf')
BUTTONS = (210, 211, 212)
roots = [445, 490, 539, 332, 317, 338, 264, 244, 250, 72, 129, 182, 213, 220, 335, 340, 343, 206, 196, 193, 190]
def button_up(cid):
    typ, t, d = sw.defs[cid]; p = 3
    p += 2
    recs = []
    while d[p] != 0:
        fl = d[p]; p += 1
        ch = struct.unpack('<H', d[p:p+2])[0]; dep = struct.unpack('<H', d[p+2:p+4])[0]; p += 4
        m, p = read_matrix(d, p); cx, p = read_cxform(d, p, True)
        if fl & 0x20: p += 1
        recs.append((fl, ch, dep, m))
    return [r for r in recs if r[0] & 1]
reach = set()
def visit(cid):
    if cid in reach or cid not in sw.defs: return
    reach.add(cid)
    if sw.defs[cid][0] == 'sprite':
        for f in sw.sprites[cid]:
            for pl in f['place']:
                if 'id' in pl: visit(pl['id'])
for r in roots: visit(r)
for b in BUTTONS:
    for (fl, ch, dep, m) in button_up(b): visit(ch)
ACT = {'stop();': 'stop', 'this.removeMovieClip();': 'remove', 'this._parent._parent.removeMovieClip();': 'remove2', 'gotoFrame(1);': 'goto1',
       'this._parent.gotoAndStop(1);': 'pstop1', 'this._parent.gotoAndStop(frame);': 'pgoto', 'hit_box._visible = false;': 'hidehit'}
shapes = {}; bitmaps = set()
for cid in sorted(reach):
    typ, t, d = sw.defs[cid]
    if typ != 'shape' or t in (46, 84): continue
    s = parse_shape(d, t); shapes[cid] = s
    for f in s['fills']:
        if f['t'] == 'bmp' and f['id'] != 0xFFFF: bitmaps.add(f['id'])
sprites = {}
for cid in sorted(c for c in reach if sw.defs[c][0] == 'sprite'):
    frames = []
    for f in sw.sprites[cid]:
        fr = {}
        if f['labels']: fr['l'] = f['labels']
        if f['remove']: fr['r'] = f['remove']
        acts = [ACT.get(decompile_code(a).strip(), 'unknown') for a in f['actions']]
        if acts: fr['a'] = acts
        ps = []
        for pl in f['place']:
            o = {'d': pl['depth']}
            if pl['flags'] & 2: o['id'] = pl['id']
            if 'matrix' in pl: o['m'] = [round(v, 5) for v in pl['matrix']]
            if 'name' in pl: o['n'] = pl['name']
            if 'cxform' in pl: o['cx'] = pl['cxform']
            ps.append(o)
        if ps: fr['p'] = ps
        frames.append(fr)
    sprites[cid] = frames
for b in BUTTONS:
    sprites[b] = [{'p': [{'d': dep, 'id': ch, 'm': [round(v, 5) for v in m]} for (fl, ch, dep, m) in button_up(b)]}]
os.makedirs('bmp', exist_ok=True)
imgs = {}
for b in sorted(bitmaps):
    im = Image.open(f'bmp/{b}.png').convert('RGBA'); bio = io.BytesIO()
    im.save(bio, 'WEBP', quality=90, lossless=(im.width * im.height <= 4000), method=6)
    imgs[b] = 'data:image/webp;base64,' + base64.b64encode(bio.getvalue()).decode()
scene = {'shapes': shapes, 'sprites': sprites, 'bitmaps': imgs, 'exports': {v: k for k, v in sw.exports.items() if not v.startswith('__Packages')}}
json.dump(scene, open('scene.json', 'w'), separators=(',', ':'))
print('shapes', len(shapes), 'sprites', len(sprites), 'bitmaps', len(imgs), 'bytes', os.path.getsize('scene.json'))
