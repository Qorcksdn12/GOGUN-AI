#!/usr/bin/env python3
"""Fast batch evaluation of a checkpoint in the C simulator: N full games from the start, deterministic policy (logit>0)."""
import sys, os, time
os.environ.setdefault('SIMLIB', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'libsim_check.so'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, train
def run(ck, N=200, seed=5, verbose=False):
    rng = np.random.default_rng(0); H = 128
    actor = train.MLP([train.OBS, H, H, 1], rng, 0.01); critic = train.MLP([train.OBS, H, H, 1], rng, 1.0)
    train.load_ckpt(ck, actor, critic)
    env = train.VecEnv(N, seed, p_full=1.0, full_steps=9500)
    first = np.ones(N, bool); res = []
    names = ['run', 'jump', 'shoot', 'rope', 'spin']
    for t in range(9600):
        pre = [(int(env.lib_get(i, 2)), env.lib_get(i, 0)) for i in range(N)] if verbose else None
        z = actor.forward(env.obs)[:, 0]; a = (z > 0).astype(np.int32)
        _, _, flag, term, info = env.step(a)
        for (i, f, lv, ln, ret, sc) in info:
            if first[i]:
                first[i] = False; res.append(('CLEAR' if f & 2 else ('dead' if f & 1 else 'timeout'), lv, ln, sc))
        if not first.any(): break
    clears = sum(1 for r in res if r[0] == 'CLEAR')
    return clears, N, res
if __name__ == '__main__':
    N = int(sys.argv[2]) if len(sys.argv) > 2 else 200; seed = int(sys.argv[3]) if len(sys.argv) > 3 else 5
    for ck in sys.argv[1].split(','):
        t = time.time(); c, n, res = run(ck, N, seed)
        fails = sorted([(r[2], r[1]) for r in res if r[0] != 'CLEAR'])
        print(f'{os.path.basename(ck):22s} clears {c}/{n} ({100*c/n:.1f}%)  fails(frame,level): {fails[:8]}  [{time.time()-t:.0f}s]', flush=True)
