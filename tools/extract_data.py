#!/usr/bin/env python3
"""Pull the level maps (MapData.setMap) and coin layouts (ItemData.setItem1..5) out of the decompiled classes -> gogun_data.json"""
import re, json, sys, os
dec, out = sys.argv[1], sys.argv[2]
mt = open(os.path.join(dec, 'MapData.as'), encoding='utf-8').read(); it = open(os.path.join(dec, 'ItemData.as'), encoding='utf-8').read()
maps = {}
for m in re.finditer(r'this\.(level\d)\.push\((\[.*?\])\);', mt): maps.setdefault(m.group(1), []).append(json.loads(m.group(2)))
items = [json.loads(m.group(1)) for m in re.finditer(r'this\.item\.push\((\[.*\])\);', it)]
json.dump({'maps': maps, 'items': items}, open(out, 'w'))
print('maps', {k: len(v) for k, v in maps.items()}, 'items', len(items))
