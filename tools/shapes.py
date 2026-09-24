import struct
from swflib import BitReader, read_rect
from swfscene import read_matrix

def rd_color(d, p, alpha):
    if alpha: return [d[p], d[p+1], d[p+2], d[p+3] / 255.0], p + 4
    return [d[p], d[p+1], d[p+2], 1.0], p + 3

def rd_fills(d, p, ver):
    n = d[p]; p += 1
    if n == 0xFF and ver >= 2: n = struct.unpack('<H', d[p:p+2])[0]; p += 2
    out = []
    for _ in range(n):
        t = d[p]; p += 1
        if t == 0x00:
            c, p = rd_color(d, p, ver >= 3); out.append({'t': 'solid', 'c': c})
        elif t in (0x10, 0x12, 0x13):
            m, p = read_matrix(d, p)
            ng = d[p] & 0x0F; p += 1
            g = []
            for _ in range(ng):
                ratio = d[p]; p += 1
                c, p = rd_color(d, p, ver >= 3); g.append([ratio, c])
            fp = 0.0
            if t == 0x13: fp = struct.unpack('<h', d[p:p+2])[0] / 256.0; p += 2
            out.append({'t': 'lin' if t == 0x10 else 'rad', 'm': [m[0]/20, m[1]/20, m[2]/20, m[3]/20, m[4], m[5]], 'g': g, 'fp': fp})
        elif t in (0x40, 0x41, 0x42, 0x43):
            bid = struct.unpack('<H', d[p:p+2])[0]; p += 2
            m, p = read_matrix(d, p)
            out.append({'t': 'bmp', 'id': bid, 'm': [m[0]/20, m[1]/20, m[2]/20, m[3]/20, m[4], m[5]], 'rep': t in (0x40, 0x42), 'smooth': t in (0x40, 0x41)})
        else:
            raise Exception('fill type %x' % t)
    return out, p

def rd_lines(d, p, ver):
    n = d[p]; p += 1
    if n == 0xFF and ver >= 2: n = struct.unpack('<H', d[p:p+2])[0]; p += 2
    out = []
    for _ in range(n):
        w = struct.unpack('<H', d[p:p+2])[0] / 20.0; p += 2
        if ver == 4:
            f1 = d[p]; f2 = d[p+1]; p += 2
            join = (f1 >> 4) & 3
            if join == 2: p += 2
            has_fill = (f1 >> 3) & 1
            if has_fill:
                fl, p = rd_fills(d[p:] if False else d, p, ver) if False else (None, p)
                raise Exception('linestyle2 fill unsupported')
            c, p = rd_color(d, p, True)
        else:
            c, p = rd_color(d, p, ver >= 3)
        out.append({'w': w, 'c': c})
    return out, p

def fmt(v): 
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'

def parse_shape(d, tagtype):
    ver = {2: 1, 22: 2, 32: 3, 83: 4}[tagtype]
    p = 2
    bounds, p = read_rect(d, p)
    if ver == 4:
        _, p = read_rect(d, p); p += 1
    fills, p = rd_fills(d, p, ver)
    lines, p = rd_lines(d, p, ver)
    br = BitReader(d, p)
    nfb = br.ub(4); nlb = br.ub(4)
    x = y = 0; f0 = f1 = ln = 0
    foff = 0; loff = 0
    edges = []   # (kind, x0,y0, cx,cy, x1,y1, fill0, fill1, line)
    while True:
        if br.ub(1) == 0:
            flags = br.ub(5)
            if flags == 0: break
            if flags & 1:
                nb = br.ub(5); x = br.sb(nb); y = br.sb(nb)
            if flags & 2: v = br.ub(nfb); f0 = v + foff if v else 0
            if flags & 4: v = br.ub(nfb); f1 = v + foff if v else 0
            if flags & 8: v = br.ub(nlb); ln = v + loff if v else 0
            if flags & 16:
                br.align()
                foff = len(fills); loff = len(lines)
                nf, np_ = rd_fills(d, br.p, ver); fills += nf
                nl, np_ = rd_lines(d, np_, ver); lines += nl
                br.p = np_; br.bit = 0
                nfb = br.ub(4); nlb = br.ub(4)
                f0 = f1 = ln = 0
        else:
            if br.ub(1):
                nb = br.ub(4) + 2
                if br.ub(1): dx = br.sb(nb); dy = br.sb(nb)
                elif br.ub(1): dx = 0; dy = br.sb(nb)
                else: dx = br.sb(nb); dy = 0
                edges.append(('L', x, y, None, None, x + dx, y + dy, f0, f1, ln)); x += dx; y += dy
            else:
                nb = br.ub(4) + 2
                cx = br.sb(nb); cy = br.sb(nb); ax = br.sb(nb); ay = br.sb(nb)
                edges.append(('Q', x, y, x + cx, y + cy, x + cx + ax, y + cy + ay, f0, f1, ln)); x += cx + ax; y += cy + ay
    # ---- group edges by fill (fill1 forward, fill0 reversed) and chain into closed contours
    per_fill = {}
    for e in edges:
        k, x0, y0, cx, cy, x1, y1, a, b, l = e
        if b: per_fill.setdefault(b, []).append((k, x0, y0, cx, cy, x1, y1))
        if a: per_fill.setdefault(a, []).append((k, x1, y1, cx, cy, x0, y0))
    paths = []
    for fi in sorted(per_fill):
        segs = per_fill[fi]
        by_start = {}
        for i, s in enumerate(segs): by_start.setdefault((s[1], s[2]), []).append(i)
        used = [False] * len(segs); parts = []
        for i in range(len(segs)):
            if used[i]: continue
            used[i] = True; s = segs[i]; start = (s[1], s[2])
            cmd = ['M' + fmt(s[1] / 20) + ' ' + fmt(s[2] / 20)]
            def emit(s):
                if s[0] == 'L': cmd.append('L' + fmt(s[5] / 20) + ' ' + fmt(s[6] / 20))
                else: cmd.append('Q' + fmt(s[3] / 20) + ' ' + fmt(s[4] / 20) + ' ' + fmt(s[5] / 20) + ' ' + fmt(s[6] / 20))
            emit(s); cur = (s[5], s[6])
            while cur != start:
                cand = [j for j in by_start.get(cur, []) if not used[j]]
                if not cand: break
                j = cand[0]; used[j] = True; emit(segs[j]); cur = (segs[j][5], segs[j][6])
            cmd.append('Z'); parts.append(''.join(cmd))
        paths.append({'f': fi - 1, 'd': ''.join(parts)})
    # ---- strokes
    strokes = {}
    prev = None
    for e in edges:
        k, x0, y0, cx, cy, x1, y1, a, b, l = e
        if not l: prev = None; continue
        cmds = strokes.setdefault(l, [])
        if prev != (l, x0, y0): cmds.append('M' + fmt(x0 / 20) + ' ' + fmt(y0 / 20))
        if k == 'L': cmds.append('L' + fmt(x1 / 20) + ' ' + fmt(y1 / 20))
        else: cmds.append('Q' + fmt(cx / 20) + ' ' + fmt(cy / 20) + ' ' + fmt(x1 / 20) + ' ' + fmt(y1 / 20))
        prev = (l, x1, y1)
    return {'b': [bounds[0]/20, bounds[2]/20, bounds[1]/20, bounds[3]/20], 'fills': fills, 'lines': lines, 'paths': paths, 'strokes': [{'l': l - 1, 'd': ''.join(c)} for l, c in sorted(strokes.items())]}
