#!/usr/bin/env python3
"""Build the 10-tier opponent ladder for the BATTLE mode.
Every candidate checkpoint (.npz from train.py / train_gpu.py) plays full games with the battle metric (distance/3 + coins);
ten of them are chosen so that the average total rises about evenly (geometric spacing) from a weak model to the best one.
usage: python3 make_ladder.py --cands 'sn64_ema_it*.npz' ck_f_ema_it3000.npz gc_0005_ema.npz --games 60 --out ladder.json"""
import sys, os, json, glob, argparse, base64, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import eval_battle as eb
NAMES = ['ROOKIE', 'STUDENT', 'RUNNER', 'CLIMBER', 'NINJA', 'SHINOBI', 'MASTER', 'SENSEI', 'LEGEND', 'GOGUN']
def flat_actor(Ws, bs): return np.concatenate([Ws[0].ravel(), bs[0], Ws[1].ravel(), bs[1], Ws[2].ravel(), bs[2]]).astype(np.float32)
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--cands', nargs='+', required=True); ap.add_argument('--games', type=int, default=60); ap.add_argument('--seed', type=int, default=777)
    ap.add_argument('--out', default='ladder.json'); ap.add_argument('--cache', default='ladder_eval_cache.json'); ap.add_argument('--min_total', type=float, default=300.0)
    a = ap.parse_args(); paths = []
    for c in a.cands: paths += sorted(glob.glob(c)) or [c]
    cache = json.load(open(a.cache)) if os.path.exists(a.cache) else {}; rows = []
    for p in paths:
        key = f'{os.path.basename(p)}|{a.games}|{a.seed}'
        if key not in cache:
            Ws, bs = eb.load_actor(p); res, snap = eb.play(Ws, bs, a.games, a.seed); cache[key] = eb.summarize(res, snap); json.dump(cache, open(a.cache, 'w'))
        s = cache[key]; rows.append((s['mean_total'], p, s)); print(f"{os.path.basename(p):30s} clear {s['clear_rate']*100:5.1f}%  dist {s['mean_dist']:8.0f}  coin {s['mean_coin']:8.0f}  total {s['mean_total']:8.0f}  total@60s {s['total@1800']:7.0f}", flush=True)
    rows.sort(key=lambda r: r[0]); usable = [r for r in rows if r[0] >= a.min_total]
    if len(usable) < 10: sys.exit(f'only {len(usable)} usable candidates (need 10)')
    lo, hi = usable[0][0], usable[-1][0]; targets = np.exp(np.linspace(np.log(lo), np.log(hi), 10)); chosen = []; pool = list(usable)
    for t in targets[:-1]:
        best = min(pool, key=lambda r: abs(np.log(r[0]) - np.log(t))); pool.remove(best); chosen.append(best)
    chosen.append(usable[-1]); chosen.sort(key=lambda r: r[0])
    ladder = []
    for i, (tot, p, s) in enumerate(chosen, 1):
        Ws, bs = eb.load_actor(p); w = flat_actor(Ws, bs)
        ladder.append({'tier': i, 'name': NAMES[i - 1], 'H': int(Ws[0].shape[1]), 'nIn': int(Ws[0].shape[0]), 'w': base64.b64encode(w.tobytes()).decode(), 'src': os.path.basename(p),
                       'stats': {'clear': round(s['clear_rate'], 3), 'dist': round(s['mean_dist']), 'coin': round(s['mean_coin']), 'total': round(s['mean_total']), 'sprint60': round(s['total@1800']), 'games': a.games}})
    json.dump(ladder, open(a.out, 'w'), separators=(',', ':'))
    print('\nladder ->', a.out)
    for t in ladder: print(f"  TIER {t['tier']:2d} {t['name']:8s} {t['src']:30s} H{t['H']:3d} in{t['nIn']}  clear {t['stats']['clear']*100:5.1f}%  total {t['stats']['total']:7d}  (dist {t['stats']['dist']}, coin {t['stats']['coin']})  60s {t['stats']['sprint60']}")
if __name__ == '__main__': main()
