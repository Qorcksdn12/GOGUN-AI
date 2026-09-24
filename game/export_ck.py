#!/usr/bin/env python3
"""Export the ACTOR of a training checkpoint (.npz from train.py / train_gpu.py) to the JSON format of the web page (TRAIN > IMPORT).
Shapes (obs dim 64 or 84, hidden size) are read from the file.   usage: python3 export_ck.py ck_ema.npz weights.json [name]"""
import sys, json, numpy as np
ck, out = sys.argv[1], sys.argv[2]; name = sys.argv[3] if len(sys.argv) > 3 else ''
z = np.load(ck); layers = [{'W': z[f'a_W{i}'].round(6).tolist(), 'b': z[f'a_b{i}'].round(6).tolist()} for i in range(3)]
meta = json.loads(str(z['meta'])) if 'meta' in z else {}
if name: meta['name'] = name
obj = {'obs_dim': int(z['a_W0'].shape[0]), 'layers': layers, 'meta': meta}
json.dump(obj, open(out, 'w')); print('exported', ck, '->', out, '| obs', obj['obs_dim'], 'hidden', z['a_W0'].shape[1], {k: meta[k] for k in ('iters_done', 'steps', 'coin_w', 'name') if k in meta})
