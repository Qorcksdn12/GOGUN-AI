import struct, math
from swflib import *
from as2dec import decompile_code, parse_code

def read_matrix(d, p):
    br = BitReader(d, p)
    sx = sy = 1.0; r0 = r1 = 0.0
    if br.ub(1):
        n = br.ub(5); sx = br.sb(n) / 65536.0; sy = br.sb(n) / 65536.0
    if br.ub(1):
        n = br.ub(5); r0 = br.sb(n) / 65536.0; r1 = br.sb(n) / 65536.0
    n = br.ub(5); tx = br.sb(n) / 20.0; ty = br.sb(n) / 20.0
    br.align()
    return (sx, r0, r1, sy, tx, ty), br.p   # a b c d tx ty  (a=sx, b=r0, c=r1, d=sy)

def read_cxform(d, p, alpha):
    br = BitReader(d, p)
    has_add = br.ub(1); has_mult = br.ub(1); n = br.ub(4)
    mult = [256, 256, 256, 256]; add = [0, 0, 0, 0]
    k = 4 if alpha else 3
    if has_mult:
        for i in range(k): mult[i] = br.sb(n)
    if has_add:
        for i in range(k): add[i] = br.sb(n)
    br.align()
    return (mult, add), br.p

def parse_place2(d, v3=False):
    p = 0
    f = d[p]; p += 1
    if v3: f2 = d[p]; p += 1
    else: f2 = 0
    depth = struct.unpack('<H', d[p:p+2])[0]; p += 2
    o = dict(depth=depth, flags=f)
    if v3 and (f2 & 0x08 or (f2 & 0x10 and f & 0x02)): 
        s = d.index(b'\0', p); p = s + 1
    if f & 0x02: o['id'] = struct.unpack('<H', d[p:p+2])[0]; p += 2
    if f & 0x04: o['matrix'], p = read_matrix(d, p)
    if f & 0x08: o['cxform'], p = read_cxform(d, p, True)
    if f & 0x10: o['ratio'] = struct.unpack('<H', d[p:p+2])[0]; p += 2
    if f & 0x20:
        e = d.index(b'\0', p); o['name'] = d[p:e].decode('utf-8', 'replace'); p = e + 1
    if f & 0x40: o['clipdepth'] = struct.unpack('<H', d[p:p+2])[0]; p += 2
    if f & 0x80:
        # clip actions
        p += 2
        allf = struct.unpack('<I', d[p:p+4])[0]; p += 4
        acts = []
        while p < len(d):
            ef = struct.unpack('<I', d[p:p+4])[0]; p += 4
            if ef == 0: break
            sz = struct.unpack('<I', d[p:p+4])[0]; p += 4
            key = None
            if ef & (1 << 17):
                key = d[p]; p += 1; sz -= 1
            acts.append((ef, key, d[p:p+sz])); p += sz
        o['clipactions'] = acts
    return o

def parse_tags_to_frames(d_iter):
    frames = []; cur = dict(place=[], remove=[], labels=[], actions=[], sounds=[])
    for t, dd, pos in d_iter:
        if t == 1:
            frames.append(cur); cur = dict(place=[], remove=[], labels=[], actions=[], sounds=[])
        elif t in (26, 70): cur['place'].append(parse_place2(dd, t == 70))
        elif t == 4:
            cid = struct.unpack('<H', dd[:2])[0]; depth = struct.unpack('<H', dd[2:4])[0]
            m, p = read_matrix(dd, 4)
            cur['place'].append(dict(depth=depth, id=cid, matrix=m, flags=0x06))
        elif t == 5:
            cur['remove'].append(struct.unpack('<H', dd[2:4])[0])
        elif t == 28: cur['remove'].append(struct.unpack('<H', dd[:2])[0])
        elif t == 43: cur['labels'].append(dd[:-1].decode('utf-8', 'replace') if dd[-1] == 0 else dd.decode('utf-8','replace'))
        elif t == 12: cur['actions'].append(dd)
        elif t == 15:
            cur['sounds'].append(dd)
    return frames

class Swf:
    def __init__(self, path):
        s = load(path); self.s = s; self.body = s['body']
        self.defs = {}   # id -> (type, data)
        self.exports = {}
        self.sprites = {}
        self.main_frames = None
        tags = list(iter_tags(self.body, s['tagstart']))
        self.tags = tags
        for t, d, pos in tags:
            if t in (2, 22, 32, 83, 46, 84):
                cid = struct.unpack('<H', d[:2])[0]; self.defs[cid] = ('shape', t, d)
            elif t in (6, 20, 21, 35, 36, 90):
                cid = struct.unpack('<H', d[:2])[0]; self.defs[cid] = ('bitmap', t, d)
            elif t == 14:
                cid = struct.unpack('<H', d[:2])[0]; self.defs[cid] = ('sound', t, d)
            elif t in (11, 33, 37, 10, 48, 75, 34, 7):
                cid = struct.unpack('<H', d[:2])[0]; self.defs[cid] = ('other', t, d)
            elif t == 39:
                cid = struct.unpack('<H', d[:2])[0]
                nf = struct.unpack('<H', d[2:4])[0]
                self.sprites[cid] = parse_tags_to_frames(iter_tags(d, 4))
                self.defs[cid] = ('sprite', t, None)
            elif t == 56:
                n = struct.unpack('<H', d[:2])[0]; p = 2
                for _ in range(n):
                    cid = struct.unpack('<H', d[p:p+2])[0]; p += 2
                    e = d.index(b'\0', p); self.exports[cid] = d[p:e].decode('utf-8','replace'); p = e + 1
        self.main_frames = parse_tags_to_frames(iter(tags[:]) if False else [(t, d, pos) for t, d, pos in tags])
        self.byname = {v: k for k, v in self.exports.items()}

    def shape_bounds(self, cid):
        typ, t, d = self.defs[cid]
        r, p = read_rect(d, 2)
        xmin, xmax, ymin, ymax = r
        return (xmin / 20.0, ymin / 20.0, xmax / 20.0, ymax / 20.0)

    def display_list(self, cid, frame):
        """state after applying frames 0..frame (0-based) for sprite cid"""
        fr = self.sprites[cid] if cid is not None else self.main_frames
        dl = {}
        for k in range(min(frame + 1, len(fr))):
            f = fr[k]
            for dp in f['remove']: dl.pop(dp, None)
            for pl in f['place']:
                dep = pl['depth']
                if pl['flags'] & 0x02:   # has character -> new (or replace)
                    ent = dict(id=pl['id'], matrix=pl.get('matrix', (1, 0, 0, 1, 0, 0)), name=pl.get('name'), cx=pl.get('cxform'), ratio=pl.get('ratio'), clip=pl.get('clipactions'), clipdepth=pl.get('clipdepth'))
                    dl[dep] = ent
                else:
                    ent = dl.get(dep)
                    if ent is None: continue
                    ent = dict(ent)
                    if 'matrix' in pl: ent['matrix'] = pl['matrix']
                    if 'name' in pl: ent['name'] = pl['name']
                    if 'cxform' in pl: ent['cx'] = pl['cxform']
                    if 'ratio' in pl: ent['ratio'] = pl['ratio']
                    dl[dep] = ent
        return dl

def mat_apply(m, x, y):
    a, b, c, d, tx, ty = m
    return (a * x + c * y + tx, b * x + d * y + ty)

def mat_mul(m1, m2):  # m1 applied after m2 : result = m1 * m2
    a1, b1, c1, d1, tx1, ty1 = m1; a2, b2, c2, d2, tx2, ty2 = m2
    return (a1*a2 + c1*b2, b1*a2 + d1*b2, a1*c2 + c1*d2, b1*c2 + d1*d2, a1*tx2 + c1*ty2 + tx1, b1*tx2 + d1*ty2 + ty1)
