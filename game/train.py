#!/usr/bin/env python3
"""PPO (numpy, hand-written backprop) for 고군분투.  Environment = C port of the reconstructed AS2 game logic (sim.c).
usage: python3 train.py [--iters N] [--hidden 128] [--out ckpt] [--init ckpt.npz]"""
import ctypes, numpy as np, time, json, os, sys, argparse

lib = ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), os.environ.get('SIMLIB', 'libsim.so')))
lib.set_obs_version.argtypes = [ctypes.c_int]; lib.set_reward.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float]
OBSV = int(os.environ.get('OBSV', '1'))     # 1: 64 inputs (survival only)   2: 84 inputs (adds the coin block)
ITEMS = int(os.environ.get('ITEMS', '0'))   # 1: simulate coins (needed for coin rewards / coin observations)
lib.set_obs_version(OBSV)
ENV_SIZE = lib.env_size(); OBS = lib.obs_dim()
lib.env_get.restype = ctypes.c_double; lib.env_get.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.vec_step.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
lib.vec_obs.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.vec_set_steps.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lib.vec_reset.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint32, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int]
MAXCOUNT = [50, 100, 150, 200, 250, 300]
SPEEDS = [15, 18, 21, 23, 25, 27]

class VecEnv:
    def __init__(self, n, seed=0, level_w=None, p_full=0.1, max_steps=1500, full_steps=9000, p_hard=0.0, hard_steps=600, p_trans=0.0):
        self.n = n; self.buf = ctypes.create_string_buffer(ENV_SIZE * n); self.ptr = ctypes.addressof(self.buf)
        self.rng = np.random.default_rng(seed)
        self.level_w = np.ones(6) / 6 if level_w is None else np.asarray(level_w)
        self.p_full = p_full; self.max_steps = max_steps; self.full_steps = full_steps
        self.obs = np.zeros((n, OBS), np.float32); self.rew = np.zeros(n, np.float32); self.flag = np.zeros(n, np.uint8)
        self.act = np.zeros(n, np.int32)
        import collections
        self.p_trans = p_trans; self.p_hard = p_hard; self.hard_steps = hard_steps; self.hard = []; self.ring = [collections.deque(maxlen=12) for _ in range(n)]; self.hard_used = 0
        self.ep_len = np.zeros(n, np.int64); self.ep_ret = np.zeros(n)
        for i in range(n): self.reset(i)
        lib.vec_obs(self.ptr, n, self.obs.ctypes.data)

    def reset(self, i):
        r = self.rng
        self.ring[i].clear()
        if self.p_hard > 0 and len(self.hard) >= 100 and r.random() < self.p_hard:
            snap = self.hard[int(r.integers(len(self.hard)))]
            ctypes.memmove(self.ptr + ENV_SIZE * int(i), snap, ENV_SIZE)
            lib.vec_set_steps(self.ptr, int(i), 0, self.hard_steps)
            self.ep_len[i] = 0; self.ep_ret[i] = 0; self.hard_used += 1
            return
        if r.random() < self.p_full:
            level, count, phase, ms = 0, 0, 0, self.full_steps
        elif r.random() < self.p_trans:
            level = int(r.integers(0, 5)); count = MAXCOUNT[level] - int(r.integers(1, 14)); phase = int(r.integers(0, SPEEDS[level])); ms = 450
        else:
            level = int(r.choice(6, p=self.level_w / self.level_w.sum())); count = int(r.integers(0, MAXCOUNT[level]))
            phase = int(r.integers(0, SPEEDS[level])); ms = self.max_steps
        lib.vec_reset(self.ptr, i, int(r.integers(1, 2**31)), level, count, phase, ms, ITEMS)
        self.ep_len[i] = 0; self.ep_ret[i] = 0

    def step(self, actions):
        self.act[:] = actions
        lib.vec_step(self.ptr, self.n, self.act.ctypes.data, self.obs.ctypes.data, self.rew.ctypes.data, self.flag.ctypes.data)
        self.ep_len += 1; self.ep_ret += self.rew
        done = self.flag != 0
        if self.p_hard > 0:
            raw = self.buf.raw
            for i in np.nonzero((self.ep_len % 30 == 0) & ~done)[0]:
                self.ring[i].append((int(self.ep_len[i]), raw[ENV_SIZE * i: ENV_SIZE * (i + 1)]))
            for i in np.nonzero((self.flag & 1) > 0)[0]:
                cand = [s for (l, s) in self.ring[i] if l <= self.ep_len[i] - 100]
                if cand:
                    self.hard.append(cand[-1] if len(cand) < 5 else cand[-3])
                    if len(self.hard) > 4000: self.hard.pop(0)
        info = []
        term_obs = None
        if done.any():
            term_obs = self.obs.copy()
            for i in np.nonzero(done)[0]:
                info.append((int(i), int(self.flag[i]), int(self.lib_get(i, 5)), int(self.ep_len[i]), float(self.ep_ret[i]), int(self.lib_get(i, 7))))
                self.reset(i)
            lib.vec_obs(self.ptr, self.n, self.obs.ctypes.data)
        return self.obs, self.rew.copy(), self.flag.copy(), term_obs, info

    def lib_get(self, i, what):
        return lib.env_get(self.ptr + ENV_SIZE * int(i), what)

# ---------------------------------------------------------------- networks
def ortho(rng, shape, gain):
    a = rng.standard_normal(shape); q, r = np.linalg.qr(a if shape[0] >= shape[1] else a.T)
    q = q * np.sign(np.diag(r)); q = q if shape[0] >= shape[1] else q.T
    return (gain * q).astype(np.float32)

class MLP:
    def __init__(self, sizes, rng, out_gain):
        self.W = []; self.b = []
        for i in range(len(sizes) - 1):
            g = out_gain if i == len(sizes) - 2 else np.sqrt(2)
            self.W.append(ortho(rng, (sizes[i], sizes[i + 1]), g)); self.b.append(np.zeros(sizes[i + 1], np.float32))
        self.m = [np.zeros_like(p) for p in self.params()]; self.v = [np.zeros_like(p) for p in self.params()]; self.t = 0
    def params(self): return self.W + self.b
    def forward(self, x, cache=False):
        hs = [x]
        for i in range(len(self.W) - 1):
            x = np.tanh(x @ self.W[i] + self.b[i]); hs.append(x)
        out = x @ self.W[-1] + self.b[-1]
        return (out, hs) if cache else out
    def backward(self, hs, dout):
        gW = [None] * len(self.W); gb = [None] * len(self.W)
        d = dout
        for i in range(len(self.W) - 1, -1, -1):
            gW[i] = hs[i].T @ d; gb[i] = d.sum(0)
            if i > 0: d = (d @ self.W[i].T) * (1 - hs[i] ** 2)
        return gW + gb
    def adam(self, grads, lr, max_norm=0.5, b1=0.9, b2=0.999, eps=1e-5):
        gn = np.sqrt(sum(float((g ** 2).sum()) for g in grads))
        if gn > max_norm: grads = [g * (max_norm / (gn + 1e-6)) for g in grads]
        self.t += 1
        for p, g, m, v in zip(self.params(), grads, self.m, self.v):
            m *= b1; m += (1 - b1) * g; v *= b2; v += (1 - b2) * g * g
            p -= lr * (m / (1 - b1 ** self.t)) / (np.sqrt(v / (1 - b2 ** self.t)) + eps)
        return gn

def sigmoid(z): return 1.0 / (1.0 + np.exp(-z))

def save_ckpt(path, actor, critic, meta):
    d = {f'a_W{i}': w for i, w in enumerate(actor.W)}; d.update({f'a_b{i}': b for i, b in enumerate(actor.b)})
    d.update({f'c_W{i}': w for i, w in enumerate(critic.W)}); d.update({f'c_b{i}': b for i, b in enumerate(critic.b)})
    d['meta'] = np.array(json.dumps(meta)); np.savez(path, **d)

def load_ckpt(path, actor, critic):
    z = np.load(path)
    def fit(w, like):   # a 64-input checkpoint can seed an 84-input net: the new input rows start at zero (behaviour unchanged at the start)
        if w.shape[0] < like.shape[0]: w = np.vstack([w, np.zeros((like.shape[0] - w.shape[0], w.shape[1]), w.dtype)])
        return w
    for i in range(len(actor.W)): actor.W[i][:] = fit(z[f'a_W{i}'], actor.W[i]); actor.b[i][:] = z[f'a_b{i}']
    for i in range(len(critic.W)): critic.W[i][:] = fit(z[f'c_W{i}'], critic.W[i]); critic.b[i][:] = z[f'c_b{i}']
    return json.loads(str(z['meta']))

def export_json(path, actor, meta):
    obj = {'obs_dim': OBS, 'layers': [{'W': w.round(6).tolist(), 'b': b.round(6).tolist()} for w, b in zip(actor.W, actor.b)], 'meta': meta}
    json.dump(obj, open(path, 'w'))

# ---------------------------------------------------------------- evaluation
def evaluate(actor, n=32, mode='full', seed=999, deterministic=True, steps=1500, level=None):
    """mode=full: full game from start (level 0).  mode=level: start at `level` with random count."""
    if mode == 'full': env = VecEnv(n, seed, p_full=1.0, full_steps=9500)
    else:
        w = np.zeros(6); w[level] = 1; env = VecEnv(n, seed, level_w=w, p_full=0.0, max_steps=steps)
    rng = np.random.default_rng(seed + 1)
    res = {'cleared': 0, 'dead': 0, 'timeout': 0, 'done': 0, 'frames': []}
    finished = np.zeros(n, bool); counted = 0
    pending = n
    # only count the first episode of each env
    first = np.ones(n, bool)
    for t in range(10000):
        z = actor.forward(env.obs)[:, 0]
        a = (z > 0).astype(np.int32) if deterministic else (rng.random(n) < sigmoid(z)).astype(np.int32)
        _, _, flag, _, info = env.step(a)
        for (i, f, lv, ln, ret, sc) in info:
            if first[i]:
                first[i] = False; res['done'] += 1
                if f & 2: res['cleared'] += 1
                elif f & 1: res['dead'] += 1
                else: res['timeout'] += 1
                res['frames'].append(ln)
        if not first.any(): break
    return res

# ---------------------------------------------------------------- PPO
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--iters', type=int, default=200); ap.add_argument('--hidden', type=int, default=128)
    ap.add_argument('--envs', type=int, default=128); ap.add_argument('--T', type=int, default=128)
    ap.add_argument('--epochs', type=int, default=4); ap.add_argument('--mb', type=int, default=4096)
    ap.add_argument('--lr', type=float, default=3e-4); ap.add_argument('--ent', type=float, default=0.01)
    ap.add_argument('--gamma', type=float, default=0.99); ap.add_argument('--lam', type=float, default=0.95)
    ap.add_argument('--out', default='ckpt'); ap.add_argument('--init', default=None); ap.add_argument('--seed', type=int, default=0)
    ap.add_argument('--eval_every', type=int, default=25); ap.add_argument('--max_steps', type=int, default=1500)
    ap.add_argument('--lr_decay', type=int, default=1); ap.add_argument('--p_hard', type=float, default=0.0); ap.add_argument('--p_trans', type=float, default=0.0); ap.add_argument('--ema', type=float, default=0.995); ap.add_argument('--eval_n', type=int, default=300)
    ap.add_argument('--coin_w', type=float, default=0.0, help='reward per coin point (needs ITEMS=1; use OBSV=2 so the agent can see coins)')
    ap.add_argument('--alive', type=float, default=0.02)
    a = ap.parse_args()
    lib.set_reward(a.alive, a.coin_w, 2.0)
    rng = np.random.default_rng(a.seed)
    H = a.hidden
    actor = MLP([OBS, H, H, 1], rng, 0.01); critic = MLP([OBS, H, H, 1], rng, 1.0)
    meta = {'hidden': H, 'iters_done': 0, 'steps': 0}
    if a.init: meta = load_ckpt(a.init, actor, critic)
    level_w = np.ones(6) / 6
    env = VecEnv(a.envs, a.seed + 1, level_w, max_steps=a.max_steps, p_hard=a.p_hard, p_trans=a.p_trans)
    import copy
    actor_ema = copy.deepcopy(actor)
    N, T = a.envs, a.T
    obs_b = np.zeros((T, N, OBS), np.float32); act_b = np.zeros((T, N), np.float32); logp_b = np.zeros((T, N), np.float32)
    val_b = np.zeros((T + 1, N), np.float32); rew_b = np.zeros((T, N), np.float32); term_b = np.zeros((T, N), np.float32); end_b = np.zeros((T, N), np.float32)
    boot_b = np.zeros((T, N), np.float32)
    death_ema = np.ones(6) * 1.0; step_ema = np.ones(6) * 1000.0
    t_start = time.time(); recent = []
    for it in range(meta['iters_done'], meta['iters_done'] + a.iters):
        lr = a.lr * (max(0.1, 1 - (it - meta['iters_done']) / a.iters) if a.lr_decay else 1.0)
        # ---- rollout
        for t in range(T):
            o = env.obs.copy(); obs_b[t] = o
            z = actor.forward(o)[:, 0]; p = sigmoid(z)
            act = (rng.random(N) < p).astype(np.float32)
            logp_b[t] = np.where(act > 0.5, np.log(p + 1e-8), np.log(1 - p + 1e-8)); act_b[t] = act
            val_b[t] = critic.forward(o)[:, 0]
            _, rew, flag, term_obs, info = env.step(act.astype(np.int32))
            rew_b[t] = rew
            dead = (flag & 1) > 0; clr = (flag & 2) > 0; tmo = (flag & 4) > 0
            term_b[t] = (dead | clr); end_b[t] = (flag != 0)
            boot_b[t] = 0
            if tmo.any():
                vt = critic.forward(term_obs[tmo])[:, 0]; boot_b[t][tmo] = vt
            for (i, f, lv, ln, ret, sc) in info:
                recent.append((f, ln, ret, lv))
                if f & 1: death_ema[min(lv, 5)] += 1
        val_b[T] = critic.forward(env.obs)[:, 0]
        # ---- GAE
        adv = np.zeros((T, N), np.float32); last = np.zeros(N, np.float32)
        for t in range(T - 1, -1, -1):
            nonterm = 1.0 - term_b[t]; nonend = 1.0 - end_b[t]
            nv = np.where(end_b[t] > 0, boot_b[t], val_b[t + 1])
            delta = rew_b[t] + a.gamma * nv * nonterm - val_b[t]
            last = delta + a.gamma * a.lam * nonend * last
            adv[t] = last
        ret = adv + val_b[:T]
        # ---- update
        B = T * N
        X = obs_b.reshape(B, OBS); A = act_b.reshape(B); LP = logp_b.reshape(B); ADV = adv.reshape(B); RET = ret.reshape(B)
        stats = {}
        for ep in range(a.epochs):
            perm = rng.permutation(B)
            for s in range(0, B, a.mb):
                idx = perm[s:s + a.mb]; x = X[idx]; act = A[idx]; adv_m = ADV[idx]; adv_m = (adv_m - adv_m.mean()) / (adv_m.std() + 1e-8)
                z, hs = actor.forward(x, True); z = z[:, 0]; p = sigmoid(z)
                logp = np.where(act > 0.5, np.log(p + 1e-8), np.log(1 - p + 1e-8))
                ratio = np.exp(logp - LP[idx])
                unclipped = (ratio * adv_m <= np.clip(ratio, 1 - 0.2, 1 + 0.2) * adv_m)
                g_logp = -(adv_m * ratio) * unclipped / len(idx)          # dL/dlogp
                dz = g_logp * (act - p)
                ent = -(p * np.log(p + 1e-8) + (1 - p) * np.log(1 - p + 1e-8))
                dz += (-a.ent) * (-(p * (1 - p)) * z) / len(idx)          # -ent_coef * dH/dz
                ga = actor.backward(hs, dz[:, None].astype(np.float32))
                actor.adam(ga, lr)
                for pe, p in zip(actor_ema.params(), actor.params()): pe *= a.ema; pe += (1 - a.ema) * p
                v, hv = critic.forward(x, True); v = v[:, 0]
                dv = (v - RET[idx]) / len(idx)
                gc = critic.backward(hv, dv[:, None].astype(np.float32))
                critic.adam(gc, lr, max_norm=1.0)
                stats = {'ent': float(ent.mean()), 'vloss': float(((v - RET[idx]) ** 2).mean()), 'clipfrac': float((~unclipped).mean())}
        # adaptive curriculum: sample harder levels more often
        for l in range(6): step_ema[l] = step_ema[l] * 0.98 + 1.0
        rate = death_ema / (death_ema.sum() + 1e-9); env.level_w = 0.3 / 6 + 0.7 * rate
        death_ema *= 0.97
        meta['iters_done'] = it + 1; meta['steps'] = meta.get('steps', 0) + B
        if (it + 1) % 5 == 0:
            r = recent[-400:]
            dead = np.mean([1 if (x[0] & 1) else 0 for x in r]) if r else 0
            print(f"it {it+1} steps {meta['steps']/1e6:.2f}M t {time.time()-t_start:.0f}s ep_len {np.mean([x[1] for x in r]) if r else 0:.0f} dead% {dead*100:.0f} ent {stats['ent']:.3f} vloss {stats['vloss']:.4f} clip {stats['clipfrac']:.3f} lvw {np.round(env.level_w,2).tolist()} hard {len(env.hard)}/{env.hard_used}", flush=True)
        if (it + 1) % a.eval_every == 0:
            save_ckpt(a.out + '.npz', actor, critic, meta)
            save_ckpt(f'{a.out}_it{it+1}.npz', actor, critic, meta)
            save_ckpt(f'{a.out}_ema_it{it+1}.npz', actor_ema, critic, meta)
            out = []
            for name, net in (('raw', actor), ('ema', actor_ema)):
                f = evaluate(net, a.eval_n, 'full', 1000 + it, True)
                fails = sorted(x for x, _ in zip(f['frames'], range(10**9)) if x < 9000)[:5]
                out.append(f"{name}: cleared {f['cleared']}/{f['done']}")
            print(f"  EVAL det full-game ({a.eval_n} games)  " + ' | '.join(out), flush=True)
    save_ckpt(a.out + '.npz', actor, critic, meta); export_json(a.out + '.json', actor, meta)
    print('saved', a.out)

if __name__ == '__main__':
    main()
