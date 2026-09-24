#!/usr/bin/env python3
"""Benchmark checkpoints with the battle metric (distance + coin score) on full games from the start.
usage: python3 eval_battle.py ckpt1.npz [ckpt2.npz ...] [--games 200] [--seed 4242] [--json out.json]"""
import ctypes, os, sys, json, argparse, numpy as np
lib = ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), os.environ.get('SIMLIB', 'libsim.so')))
lib.env_size.restype = ctypes.c_int; lib.obs_dim.restype = ctypes.c_int; lib.env_get.restype = ctypes.c_double; lib.env_get.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.vec_step.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
lib.vec_obs.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.vec_reset.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint32, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lib.set_obs_version.argtypes = [ctypes.c_int]
ENV = lib.env_size()
DIST_DIV = 3.0      # distance points = way / 3   (a full run is about 53k distance points, comparable to about 50k coin points)

def load_actor(path):
    z = np.load(path); return [z[f'a_W{i}'].astype(np.float32) for i in range(3)], [z[f'a_b{i}'].astype(np.float32) for i in range(3)]
def logits(Ws, bs, x):
    h = np.tanh(x @ Ws[0] + bs[0]); h = np.tanh(h @ Ws[1] + bs[1]); return (h @ Ws[2] + bs[2])[:, 0]

def play(Ws, bs, games=100, seed=4242, level=0, max_frames=9500, checkpoints=(1800,)):
    lib.set_obs_version(2 if Ws[0].shape[0] == 84 else 1); od = lib.obs_dim(); assert od == Ws[0].shape[0], (od, Ws[0].shape)
    buf = ctypes.create_string_buffer(ENV * games); ptr = ctypes.addressof(buf); rng = np.random.default_rng(seed)
    for i in range(games): lib.vec_reset(ptr, i, int(rng.integers(1, 2**31)), level, 0, 0, 0, 1)
    obs = np.zeros((games, od), np.float32); rew = np.zeros(games, np.float32); flag = np.zeros(games, np.uint8); act = np.zeros(games, np.int32)
    lib.vec_obs(ptr, games, obs.ctypes.data)
    done = np.zeros(games, bool); res = {k: np.zeros(games) for k in ('cleared', 'frames', 'way', 'score')}; snap = {c: np.zeros((games, 2)) for c in checkpoints}
    for t in range(1, max_frames + 1):
        act[:] = (logits(Ws, bs, obs) > 0)
        lib.vec_step(ptr, games, act.ctypes.data, obs.ctypes.data, rew.ctypes.data, flag.ctypes.data)
        for i in np.nonzero((flag != 0) & ~done)[0]:
            done[i] = True; res['cleared'][i] = 1 if (flag[i] & 2) else 0; res['frames'][i] = t
            e = ptr + ENV * int(i); res['way'][i] = lib.env_get(e, 3); res['score'][i] = lib.env_get(e, 7)
        for c in checkpoints:
            if t == c:
                for i in range(games):
                    if not done[i]: e = ptr + ENV * i; snap[c][i] = (lib.env_get(e, 3), lib.env_get(e, 7))
                    else: snap[c][i] = (res['way'][i], res['score'][i])
        if done.all(): break
    for i in np.nonzero(~done)[0]:
        e = ptr + ENV * int(i); res['frames'][i] = max_frames; res['way'][i] = lib.env_get(e, 3); res['score'][i] = lib.env_get(e, 7)
    return res, snap

def summarize(res, snap):
    dist = res['way'] / DIST_DIV; tot = dist + res['score']
    out = {'clear_rate': float(res['cleared'].mean()), 'mean_frames': float(res['frames'].mean()), 'mean_dist': float(dist.mean()), 'mean_coin': float(res['score'].mean()), 'mean_total': float(tot.mean()), 'std_total': float(tot.std())}
    for c, a in snap.items(): out[f'total@{c}'] = float((a[:, 0] / DIST_DIV + a[:, 1]).mean()); out[f'coin@{c}'] = float(a[:, 1].mean())
    return out

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('ckpts', nargs='+'); ap.add_argument('--games', type=int, default=200); ap.add_argument('--seed', type=int, default=4242); ap.add_argument('--json', default=None)
    a = ap.parse_args(); allr = {}
    for p in a.ckpts:
        Ws, bs = load_actor(p); res, snap = play(Ws, bs, a.games, a.seed); s = summarize(res, snap); allr[p] = s
        print(f"{os.path.basename(p):28s} clear {s['clear_rate']*100:5.1f}%  frames {s['mean_frames']:6.0f}  dist {s['mean_dist']:8.0f}  coin {s['mean_coin']:8.0f}  total {s['mean_total']:8.0f} (+-{s['std_total']:.0f})  total@60s {s['total@1800']:7.0f}")
    if a.json: json.dump(allr, open(a.json, 'w'), indent=1)
