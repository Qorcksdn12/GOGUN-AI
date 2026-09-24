#!/usr/bin/env python3
"""GPU PPO trainer for gogun (고군분투).

* environments : the C simulator (sim.c), stepped by OpenMP threads (all CPU cores), with built-in auto-reset + curriculum
* networks     : actor / critic MLPs (obs -> H -> H -> 1, tanh) on the GPU with PyTorch  (or numpy for tests / CPU-only machines)
* algorithm    : PPO-clip, GAE, adaptive level curriculum, EMA of the actor.  Same maths as train.py (hand-written back-prop, no autograd).
* checkpoints  : .npz in the same format as train.py  ->  export_ck.py / eval_c.py / eval_battle.py / the web page all accept them.

examples
  python3 train_gpu.py --device cuda --minutes 10 --out ck_gpu                       # survival only (64 inputs)
  python3 train_gpu.py --device cuda --obs 2 --coin_w 0.001 --init ck_gpu.npz --minutes 10 --out ck_gpu_coin   # coin-aware (84 inputs)
  python3 train_gpu.py --backend numpy --envs 256 --iters 50                          # no GPU: same code on numpy (slow)
"""
import argparse, ctypes, json, os, sys, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))

# ============================================================================================ backends
class NumpyBackend:
    name = 'numpy'
    def __init__(self, device=None, seed=0): self.rng = np.random.default_rng(seed); self.device = 'cpu'
    def tensor(self, a): return np.ascontiguousarray(a, dtype=np.float32)
    def index(self, a): return np.asarray(a, dtype=np.int64)
    def to_np(self, t): return np.asarray(t)
    def zeros(self, *s): return np.zeros(s, np.float32)
    def zeros_like(self, t): return np.zeros_like(t)
    def rand(self, n): return self.rng.random(n, dtype=np.float32)
    def perm(self, n): return self.rng.permutation(n)
    def tanh(self, x): return np.tanh(x)
    def exp(self, x): return np.exp(x)
    def log(self, x): return np.log(x)
    def sqrt(self, x): return np.sqrt(x)
    def where(self, c, a, b): return np.where(c, a, b)
    def clip(self, x, lo, hi): return np.clip(x, lo, hi)
    def clamp_max(self, x, hi): return np.minimum(x, hi)
    def fl(self, b): return b.astype(np.float32)
    def item(self, t): return float(t)
    def copy(self, t): return t.copy()

class TorchBackend:
    name = 'torch'
    def __init__(self, device='auto', seed=0):
        import torch
        self.t = torch
        if device == 'auto': device = 'cuda' if torch.cuda.is_available() else 'cpu'
        self.device = device; torch.manual_seed(seed)
        if device.startswith('cuda'):
            torch.backends.cuda.matmul.allow_tf32 = True; torch.backends.cudnn.allow_tf32 = True
    def tensor(self, a): return self.t.from_numpy(np.ascontiguousarray(a, dtype=np.float32)).to(self.device, non_blocking=True)
    def index(self, a): return self.t.from_numpy(np.asarray(a, dtype=np.int64)).to(self.device)
    def to_np(self, t): return t.detach().cpu().numpy()
    def zeros(self, *s): return self.t.zeros(s, dtype=self.t.float32, device=self.device)
    def zeros_like(self, t): return self.t.zeros_like(t)
    def rand(self, n): return self.t.rand(n, device=self.device)
    def perm(self, n): return self.t.randperm(n, device=self.device)
    def tanh(self, x): return self.t.tanh(x)
    def exp(self, x): return self.t.exp(x)
    def log(self, x): return self.t.log(x)
    def sqrt(self, x): return self.t.sqrt(x)
    def where(self, c, a, b): return self.t.where(c, a, b)
    def clip(self, x, lo, hi): return self.t.clamp(x, lo, hi)
    def clamp_max(self, x, hi): return self.t.clamp(x, max=hi)
    def fl(self, b): return b.float()
    def item(self, t): return float(t.item())
    def copy(self, t): return t.clone()

def make_backend(name, device, seed):
    if name == 'numpy': return NumpyBackend(seed=seed)
    try: return TorchBackend(device, seed)
    except ImportError: sys.exit('PyTorch is not installed. Install it (https://pytorch.org) or run with --backend numpy.')

# ============================================================================================ networks (hand-written back-prop)
def ortho(rng, shape, gain):
    a = rng.standard_normal(shape); q, r = np.linalg.qr(a if shape[0] >= shape[1] else a.T)
    q = q * np.sign(np.diag(r)); q = q if shape[0] >= shape[1] else q.T
    return (gain * q).astype(np.float32)

def init_net(xp, sizes, rng, out_gain):
    P = []
    for i in range(len(sizes) - 1):
        g = out_gain if i == len(sizes) - 2 else np.sqrt(2)
        P += [xp.tensor(ortho(rng, (sizes[i], sizes[i + 1]), g)), xp.zeros(sizes[i + 1])]
    return P

def forward(xp, P, x, keep=False):
    W0, b0, W1, b1, W2, b2 = P
    h0 = xp.tanh(x @ W0 + b0); h1 = xp.tanh(h0 @ W1 + b1); out = h1 @ W2 + b2
    return (out, (x, h0, h1)) if keep else out

def backward(xp, P, cache, dout):
    W0, b0, W1, b1, W2, b2 = P; x, h0, h1 = cache
    gW2 = h1.T @ dout; gb2 = dout.sum(0)
    d1 = (dout @ W2.T) * (1 - h1 * h1); gW1 = h0.T @ d1; gb1 = d1.sum(0)
    d0 = (d1 @ W1.T) * (1 - h0 * h0); gW0 = x.T @ d0; gb0 = d0.sum(0)
    return [gW0, gb0, gW1, gb1, gW2, gb2]

class Adam:
    def __init__(self, xp, P, max_norm, b1=0.9, b2=0.999, eps=1e-5):
        self.xp = xp; self.m = [xp.zeros_like(p) for p in P]; self.v = [xp.zeros_like(p) for p in P]; self.t = 0; self.max_norm = max_norm; self.b1 = b1; self.b2 = b2; self.eps = eps
    def step(self, P, G, lr):
        xp = self.xp; gn = xp.sqrt(sum((g * g).sum() for g in G)); scale = xp.clamp_max(self.max_norm / (gn + 1e-6), 1.0)   # no host sync
        self.t += 1; c1 = 1 - self.b1 ** self.t; c2 = 1 - self.b2 ** self.t
        for p, g, m, v in zip(P, G, self.m, self.v):
            g = g * scale; m *= self.b1; m += (1 - self.b1) * g; v *= self.b2; v += (1 - self.b2) * g * g
            p -= lr * (m / c1) / (xp.sqrt(v / c2) + self.eps)

# ============================================================================================ simulator (C, OpenMP)
class SimVec:
    def __init__(self, n, obs_ver, items, coin_w, alive, clear_bonus, threads, lib_path=None):
        if threads > 0: os.environ['OMP_NUM_THREADS'] = str(threads)
        cand = [lib_path] if lib_path else [os.path.join(HERE, 'libsim_omp.so'), os.path.join(HERE, 'libsim.so')]
        path = next((p for p in cand if p and os.path.exists(p)), None)
        if path is None: sys.exit('libsim not found: run ./build.sh first')
        path = os.path.abspath(path); L = self.lib = ctypes.CDLL(path); self.path = path; self.omp = path.endswith('_omp.so')
        L.env_size.restype = ctypes.c_int; L.obs_dim.restype = ctypes.c_int; L.env_get.restype = ctypes.c_double; L.env_get.argtypes = [ctypes.c_void_p, ctypes.c_int]
        L.set_obs_version.argtypes = [ctypes.c_int]; L.set_reward.argtypes = [ctypes.c_float] * 3
        L.set_curriculum.argtypes = [ctypes.c_void_p, ctypes.c_float, ctypes.c_int, ctypes.c_int, ctypes.c_float, ctypes.c_int]
        L.vec_init_auto.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint32]
        L.vec_obs.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        L.vec_step.argtypes = [ctypes.c_void_p] * 1 + [ctypes.c_int] + [ctypes.c_void_p] * 4
        L.vec_step_auto.argtypes = [ctypes.c_void_p, ctypes.c_int] + [ctypes.c_void_p] * 7
        L.vec_reset.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint32, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        L.set_obs_version(obs_ver); L.set_reward(alive, coin_w, clear_bonus)
        self.n = n; self.od = L.obs_dim(); self.esz = L.env_size(); self.items = items
        self.buf = ctypes.create_string_buffer(self.esz * n); self.ptr = ctypes.addressof(self.buf)
        self.obs = np.zeros((n, self.od), np.float32); self.tobs = np.zeros((n, self.od), np.float32)
        self.rew = np.zeros(n, np.float32); self.flag = np.zeros(n, np.uint8); self.act = np.zeros(n, np.int32)
        self.elevel = np.zeros(n, np.int32); self.elen = np.zeros(n, np.int32)
    def curriculum(self, level_w, p_full, max_steps, full_steps, p_trans):
        self.lw = np.asarray(level_w, np.float32); self.lib.set_curriculum(self.lw.ctypes.data, p_full, max_steps, full_steps, p_trans, self.items)
    def init_auto(self, salt): self.lib.vec_init_auto(self.ptr, self.n, salt & 0xffffffff); self.lib.vec_obs(self.ptr, self.n, self.obs.ctypes.data)
    def step_auto(self, act):
        self.act[:] = act
        self.lib.vec_step_auto(self.ptr, self.n, self.act.ctypes.data, self.obs.ctypes.data, self.rew.ctypes.data, self.flag.ctypes.data, self.tobs.ctypes.data, self.elevel.ctypes.data, self.elen.ctypes.data)
    def reset_full_games(self, seed, max_steps=9500):
        rng = np.random.default_rng(seed)
        for i in range(self.n): self.lib.vec_reset(self.ptr, i, int(rng.integers(1, 2**31)), 0, 0, 0, max_steps, self.items)
        self.lib.vec_obs(self.ptr, self.n, self.obs.ctypes.data)
    def step_plain(self, act):
        self.act[:] = act; self.lib.vec_step(self.ptr, self.n, self.act.ctypes.data, self.obs.ctypes.data, self.rew.ctypes.data, self.flag.ctypes.data)
    def get(self, i, what): return self.lib.env_get(self.ptr + self.esz * int(i), what)

# ============================================================================================ checkpoint I/O (train.py compatible)
def save_ckpt(path, xp, actor, critic, meta):
    d = {}
    for pre, P in (('a', actor), ('c', critic)):
        for i in range(3): d[f'{pre}_W{i}'] = xp.to_np(P[2 * i]); d[f'{pre}_b{i}'] = xp.to_np(P[2 * i + 1])
    d['meta'] = np.array(json.dumps(meta)); np.savez(path, **d)

def load_ckpt(path, xp, actor, critic):
    z = np.load(path)
    def fit(w, like):   # a 64-input checkpoint can seed an 84-input net (new input rows start at zero)
        like = xp.to_np(like)
        if w.shape[0] < like.shape[0]: w = np.vstack([w, np.zeros((like.shape[0] - w.shape[0], w.shape[1]), w.dtype)])
        return xp.tensor(w)
    for pre, P in (('a', actor), ('c', critic)):
        for i in range(3):
            if f'{pre}_W{i}' in z: P[2 * i] = fit(z[f'{pre}_W{i}'], P[2 * i]); P[2 * i + 1] = xp.tensor(z[f'{pre}_b{i}'])
    return json.loads(str(z['meta'])) if 'meta' in z else {}

def export_json(path, xp, actor, obs_dim, meta):
    obj = {'obs_dim': obs_dim, 'layers': [{'W': xp.to_np(actor[2 * i]).round(6).tolist(), 'b': xp.to_np(actor[2 * i + 1]).round(6).tolist()} for i in range(3)], 'meta': meta}
    json.dump(obj, open(path, 'w'))

# ============================================================================================ evaluation
def evaluate(xp, env_eval, actor, games, seed):
    env = env_eval; env.reset_full_games(seed); done = np.zeros(env.n, bool); res = {'cleared': 0, 'dead': 0, 'frames': [], 'way': [], 'score': []}
    for t in range(1, 9501):
        z = forward(xp, actor, xp.tensor(env.obs))[:, 0]; env.step_plain((xp.to_np(z) > 0).astype(np.int32))
        for i in np.nonzero((env.flag != 0) & ~done)[0]:
            done[i] = True; res['cleared'] += int(env.flag[i] & 2 > 0); res['dead'] += int(env.flag[i] & 1 > 0); res['frames'].append(t)
            res['way'].append(env.get(i, 3)); res['score'].append(env.get(i, 7))
        if done.all(): break
    return res

# ============================================================================================ main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--backend', default='torch', choices=['torch', 'numpy']); ap.add_argument('--device', default='auto', help='cuda | cuda:1 | cpu | auto (torch backend)')
    ap.add_argument('--envs', type=int, default=8192); ap.add_argument('--T', type=int, default=128); ap.add_argument('--epochs', type=int, default=4); ap.add_argument('--mb', type=int, default=32768)
    ap.add_argument('--hidden', type=int, default=128); ap.add_argument('--lr', type=float, default=3e-4); ap.add_argument('--ent', type=float, default=0.01)
    ap.add_argument('--gamma', type=float, default=0.99); ap.add_argument('--lam', type=float, default=0.95); ap.add_argument('--clip', type=float, default=0.2); ap.add_argument('--ema', type=float, default=0.995)
    ap.add_argument('--obs', type=int, default=1, choices=[1, 2], help='1: 64 inputs (survival)  2: 84 inputs (adds coin observations)')
    ap.add_argument('--coin_w', type=float, default=0.0, help='reward per coin point (use with --obs 2)'); ap.add_argument('--alive', type=float, default=0.02); ap.add_argument('--clear_bonus', type=float, default=2.0)
    ap.add_argument('--p_full', type=float, default=0.1); ap.add_argument('--p_trans', type=float, default=0.0); ap.add_argument('--max_steps', type=int, default=1500)
    ap.add_argument('--iters', type=int, default=1000000); ap.add_argument('--minutes', type=float, default=0.0, help='stop after this many minutes (0 = use --iters)')
    ap.add_argument('--init', default=None); ap.add_argument('--out', default='ck_gpu'); ap.add_argument('--seed', type=int, default=0)
    ap.add_argument('--eval_every', type=int, default=50); ap.add_argument('--eval_games', type=int, default=200); ap.add_argument('--threads', type=int, default=0, help='OpenMP threads (0 = all cores)')
    ap.add_argument('--lr_decay', type=int, default=1, help='linearly decay lr to 10 percent over --iters/--minutes'); ap.add_argument('--lib', default=None)
    a = ap.parse_args()
    xp = make_backend(a.backend, a.device, a.seed); rng = np.random.default_rng(a.seed)
    items = 1 if (a.obs == 2 or a.coin_w != 0) else 0
    env = SimVec(a.envs, a.obs, items, a.coin_w, a.alive, a.clear_bonus, a.threads, a.lib)
    OBS, N, T, H = env.od, a.envs, a.T, a.hidden; B = N * T; mb = min(a.mb, B)
    actor = init_net(xp, [OBS, H, H, 1], rng, 0.01); critic = init_net(xp, [OBS, H, H, 1], rng, 1.0); meta = {'hidden': H, 'iters_done': 0, 'steps': 0, 'obs_dim': OBS, 'coin_w': a.coin_w}
    if a.init: meta.update(load_ckpt(a.init, xp, actor, critic)); meta['obs_dim'] = OBS; meta['coin_w'] = a.coin_w
    ema = [xp.copy(p) for p in actor]; opt_a = Adam(xp, actor, 0.5); opt_c = Adam(xp, critic, 1.0)
    env_eval = SimVec(min(a.eval_games, 1024), a.obs, items, a.coin_w, a.alive, a.clear_bonus, a.threads, a.lib)
    level_w = np.ones(6, np.float32) / 6; death_ema = np.ones(6)
    env.curriculum(level_w, a.p_full, a.max_steps, 9000, a.p_trans); env.init_auto(a.seed * 7919 + 1)
    print(f'backend {xp.name} on {xp.device} | sim {os.path.basename(env.path)} ({"OpenMP" if env.omp else "single thread"}) | obs {OBS} | envs {N} x T {T} = {B} samples/iter | minibatch {mb} | hidden {H} | coin_w {a.coin_w}', flush=True)
    obs_b = xp.zeros(T, N, OBS); act_b = xp.zeros(T, N); lp_b = xp.zeros(T, N); val_b = xp.zeros(T + 1, N); rew_b = xp.zeros(T, N); term_b = xp.zeros(T, N); end_b = xp.zeros(T, N); boot_b = xp.zeros(T, N)
    t0 = time.time(); it0 = meta['iters_done']; it = it0; ep_hist = []; total_iters = a.iters
    while it < it0 + total_iters:
        el = time.time() - t0
        if a.minutes > 0 and el > a.minutes * 60: break
        frac = (el / (a.minutes * 60)) if a.minutes > 0 else ((it - it0) / max(1, total_iters))
        lr = a.lr * (max(0.1, 1 - frac) if a.lr_decay else 1.0)
        tr = time.time(); dead_c = np.zeros(6); n_ep = 0; len_sum = 0; n_dead = 0; n_clear = 0; coin_ret = 0.0
        # ---------------------------------------------------------------- rollout
        for t in range(T):
            x = xp.tensor(env.obs); obs_b[t] = x
            z = forward(xp, actor, x)[:, 0]; p = 1 / (1 + xp.exp(-z)); act = xp.fl(xp.rand(N) < p)
            lp_b[t] = xp.log(xp.where(act > 0.5, p, 1 - p) + 1e-8); act_b[t] = act; val_b[t] = forward(xp, critic, x)[:, 0]
            env.step_auto(xp.to_np(act).astype(np.int32))
            fl = env.flag; rew_b[t] = xp.tensor(env.rew); term_b[t] = xp.tensor((fl & 3) > 0); end_b[t] = xp.tensor(fl > 0)
            if fl.any():
                ends = np.nonzero(fl)[0]; n_ep += len(ends); len_sum += int(env.elen[ends].sum()); n_dead += int((fl[ends] & 1 > 0).sum()); n_clear += int((fl[ends] & 2 > 0).sum())
                dl = env.elevel[ends][(fl[ends] & 1) > 0]; dead_c += np.bincount(np.minimum(dl, 5), minlength=6)
                to = np.nonzero(fl & 4)[0]
                if len(to):
                    idx = xp.index(to); boot_b[t][idx] = forward(xp, critic, xp.tensor(env.tobs[to]))[:, 0]
        val_b[T] = forward(xp, critic, xp.tensor(env.obs))[:, 0]
        # ---------------------------------------------------------------- GAE
        adv = xp.zeros(T, N); last = xp.zeros(N)
        for t in range(T - 1, -1, -1):
            nv = xp.where(end_b[t] > 0, boot_b[t], val_b[t + 1])
            delta = rew_b[t] + a.gamma * nv * (1 - term_b[t]) - val_b[t]
            last = delta + a.gamma * a.lam * (1 - end_b[t]) * last; adv[t] = last
        ret = (adv + val_b[:T]).reshape(B); X = obs_b.reshape(B, OBS); A = act_b.reshape(B); LP = lp_b.reshape(B); ADV = adv.reshape(B)
        t_roll = time.time() - tr; tu = time.time()
        # ---------------------------------------------------------------- PPO update
        st_ent = st_v = 0.0
        for ep in range(a.epochs):
            perm = xp.perm(B)
            for s in range(0, B - mb + 1, mb):
                idx = perm[s:s + mb]; x = X[idx]; act = A[idx]; adv_m = ADV[idx]; n = float(mb)
                adv_m = (adv_m - adv_m.mean()) / (xp.sqrt(((adv_m - adv_m.mean()) ** 2).mean()) + 1e-8)
                z, cache = forward(xp, actor, x, True); z = z[:, 0]; p = 1 / (1 + xp.exp(-z))
                logp = xp.log(xp.where(act > 0.5, p, 1 - p) + 1e-8); ratio = xp.exp(logp - LP[idx])
                unclipped = xp.fl(ratio * adv_m <= xp.clip(ratio, 1 - a.clip, 1 + a.clip) * adv_m)
                dz = -(adv_m * ratio) * unclipped / n * (act - p) + (-a.ent) * (-(p * (1 - p)) * z) / n
                ga = backward(xp, actor, cache, dz[:, None]); opt_a.step(actor, ga, lr)
                for pe, pa in zip(ema, actor): pe *= a.ema; pe += (1 - a.ema) * pa
                v, cache_c = forward(xp, critic, x, True); v = v[:, 0]; dv = (v - ret[idx]) / n
                gc = backward(xp, critic, cache_c, dv[:, None]); opt_c.step(critic, gc, lr)
        st_ent = xp.item((-(p * xp.log(p + 1e-8) + (1 - p) * xp.log(1 - p + 1e-8))).mean()); st_v = xp.item(((v - ret[idx]) ** 2).mean())
        t_upd = time.time() - tu
        # ---------------------------------------------------------------- curriculum + bookkeeping
        death_ema += dead_c; rate = death_ema / (death_ema.sum() + 1e-9); level_w = (0.3 / 6 + 0.7 * rate).astype(np.float32); death_ema *= 0.97
        env.curriculum(level_w, a.p_full, a.max_steps, 9000, a.p_trans)
        it += 1; meta['iters_done'] = it; meta['steps'] = meta.get('steps', 0) + B; ep_hist.append((n_ep, len_sum, n_dead, n_clear)); ep_hist = ep_hist[-10:]
        if it % 5 == 0 or it == it0 + 1:
            e, l, d, c = (sum(h[i] for h in ep_hist) for i in range(4)); dt = time.time() - t0
            print(f'it {it} | {meta["steps"]/1e6:.1f}M frames | {(it - it0) * B / dt / 1e3:.0f}k frames/s (rollout {t_roll:.2f}s update {t_upd:.2f}s) | ep_len {l / max(1, e):.0f} dead {100 * d / max(1, e):.0f}% clear {100 * c / max(1, e):.0f}% | ent {st_ent:.3f} vloss {st_v:.4f} | {dt / 60:.1f} min', flush=True)
        if it % a.eval_every == 0:
            save_ckpt(a.out + '.npz', xp, actor, critic, meta); save_ckpt(a.out + '_ema.npz', xp, ema, critic, meta); save_ckpt(f'{a.out}_ema_it{it}.npz', xp, ema, critic, meta)
            r = evaluate(xp, env_eval, ema, a.eval_games, 1000 + it); g = max(1, len(r['frames']))
            print(f'  EVAL (ema actor, {g} full games): cleared {r["cleared"]}/{g} ({100 * r["cleared"] / g:.1f}%) | mean frames {np.mean(r["frames"]):.0f} | mean coin score {np.mean(r["score"]):.0f} | mean distance {np.mean(r["way"]) / 3:.0f}', flush=True)
    save_ckpt(a.out + '.npz', xp, actor, critic, meta); save_ckpt(a.out + '_ema.npz', xp, ema, critic, meta); export_json(a.out + '.json', xp, ema, OBS, meta)
    print('saved', a.out + '.npz', a.out + '_ema.npz', a.out + '.json (EMA actor, web-page format)')

if __name__ == '__main__':
    main()
