#!/usr/bin/env python3
"""Extract the MP3 sounds (DefineSound) of the SWF and build sounds.json (base64 bank used by the HTML page).
usage: python3 extract_sounds.py 고군분투.swf out_dir [sounds.json]"""
import sys, os, struct, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from swfscene import Swf
sw = Swf(sys.argv[1]); out = sys.argv[2]; os.makedirs(out, exist_ok=True)
USED = ['snd_run', 'snd_ropeup', 'snd_shoot', 'snd_ropecatch', 'snd_spin', 'snd_silvercoin', 'snd_goldcoin', 'snd_coinbonus', 'snd_speedup', 'snd_best',
        'snd_gameover', 'snd_fadeinout', 'snd_gamebg', 'snd_allclear']       # the ones SetGame.as actually plays (+ the ending jingle)
bank = {}
for cid, (typ, t, d) in sorted(sw.defs.items()):
    if typ != 'sound': continue
    name = sw.exports.get(cid, f'sound{cid}'); flags = d[2]
    if flags >> 4 != 2: continue                                   # MP3 only (all 19 sounds of this game)
    rate = [5512, 11025, 22050, 44100][(flags >> 2) & 3]; nsamp = struct.unpack('<I', d[3:7])[0]; seek = struct.unpack('<h', d[7:9])[0]
    open(os.path.join(out, name + '.mp3'), 'wb').write(d[9:])
    if name in USED: bank[name[4:]] = {'mp3': base64.b64encode(d[9:]).decode(), 'rate': rate, 'samples': nsamp, 'seek': seek}
json.dump(bank, open(sys.argv[3] if len(sys.argv) > 3 else os.path.join(out, 'sounds.json'), 'w'), separators=(',', ':'))
print('sounds extracted:', len(bank), 'used /', 19, 'total; bank bytes:', sum(len(v['mp3']) for v in bank.values()))
