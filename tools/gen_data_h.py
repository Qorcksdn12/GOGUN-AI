#!/usr/bin/env python3
"""gogun_data.json -> data.h (static tables for sim.c)"""
import json, sys
d = json.load(open(sys.argv[1])); outp = sys.argv[2]
maps = [d['maps'][f'level{i}'] for i in range(7)]; items = d['items']
maxmap = max(len(m) for ms in maps for m in ms); maxblk = max(len(b) for e in items for b in e[1:]); maxkey = max(len(e[0]) for e in items)
def row(vals, width):
    vals = list(vals) + [0] * (width - len(vals)); return '{' + ','.join(str(v) for v in vals) + '}'
out = ['/* generated from gogun_data.json (MapData / ItemData of the original SWF) */', f'#define MAXMAPLEN {maxmap}', f'#define MAXCOINS {maxblk}', f'#define NITEMS {len(items)}']
out.append('static const int NMAPS[7] = {' + ','.join(str(len(ms)) for ms in maps) + '};')
out.append('static const int MAPLEN[7][5] = {' + ','.join(row([len(m) for m in ms], 5) for ms in maps) + '};')
out.append(f'static const int MAPDATA[7][5][{maxmap}] = {{')
for ms in maps: out.append('  {' + ','.join(row(ms[k], maxmap) if k < len(ms) else row([], maxmap) for k in range(5)) + '},')
out.append('};')
out.append('static const int ITEMKEYLEN[NITEMS] = {' + ','.join(str(len(e[0])) for e in items) + '};')
out.append(f'static const int ITEMKEY[NITEMS][{maxkey}] = {{')
for e in items: out.append('  ' + row(e[0], maxkey) + ',')
out.append('};')
out.append(f'static const int ITEMBCOUNT[NITEMS][{maxkey}] = {{')
for e in items: out.append('  ' + row([len(b) for b in e[1:]], maxkey) + ',')
out.append('};')
out.append(f'static const short ITEMSLOT[NITEMS][{maxkey}][{maxblk}] = {{')
for e in items: out.append('  {' + ','.join(row(e[1 + k], maxblk) if k < len(e) - 1 else row([], maxblk) for k in range(maxkey)) + '},')
out.append('};')
open(outp, 'w').write('\n'.join(out) + '\n'); print('wrote', outp)
