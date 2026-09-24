/* GogunTrain — PPO for the Gogun sim, written to run inside Web Workers (or plain Node for tests).
 * Two MLPs (actor / critic): 64 -> H -> H -> 1, tanh.  Parameters live in one flat Float32Array: [actor | critic].
 * Data-parallel design: every worker owns N_w environments; the coordinator averages the gradients of all workers. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('./sim.js'));
  else root.GogunTrain = factory(root.GogunSim);
})(typeof self !== 'undefined' ? self : this, function (GogunSim) {
  'use strict';
  const OBS = 64;   // default input size (observation v1); observation v2 (coin-aware) has 84
  const MAXCOUNT = [50, 100, 150, 200, 250, 300], SPEEDS = [15, 18, 21, 23, 25, 27];

  function layoutOf(H, nIn) {
    nIn = nIn || OBS; const o = { nIn: nIn }; let p = 0;
    o.W0 = p; p += nIn * H; o.b0 = p; p += H; o.W1 = p; p += H * H; o.b1 = p; p += H; o.W2 = p; p += H; o.b2 = p; p += 1; o.size = p;
    return o;
  }
  function mulberry(seed) {
    let a = seed >>> 0;
    return function () { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  }
  function randn(rng) { let u = 0, v = 0; while (u === 0) u = rng(); v = rng(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); }

  /** random initial parameters [actor | critic] (scaled Gaussian ~ orthogonal init used by the Python trainer) */
  function initParams(H, seed, nIn) {
    const o = layoutOf(H, nIn), rng = mulberry(seed), P = new Float32Array(2 * o.size);
    for (let net = 0; net < 2; net++) {
      const base = net * o.size, outGain = net === 0 ? 0.01 : 1.0;
      for (let i = 0; i < o.nIn * H; i++) P[base + o.W0 + i] = randn(rng) * Math.SQRT2 / Math.sqrt(o.nIn);
      for (let i = 0; i < H * H; i++) P[base + o.W1 + i] = randn(rng) * Math.SQRT2 / Math.sqrt(H);
      for (let i = 0; i < H; i++) P[base + o.W2 + i] = randn(rng) * outGain / Math.sqrt(H);
    }
    return P;
  }

  // ---- forward / backward for ONE sample (o = layout, off = offset of the net inside P) ---------------------------------
  function fwd(P, off, o, H, X, xo, h0, h1, ho) {
    const W0 = off + o.W0, b0 = off + o.b0, W1 = off + o.W1, b1 = off + o.b1, W2 = off + o.W2, b2 = off + o.b2;
    for (let j = 0; j < H; j++) h0[ho + j] = P[b0 + j];
    for (let k = 0; k < o.nIn; k++) { const x = X[xo + k]; if (x !== 0) { const w = W0 + k * H; for (let j = 0; j < H; j++) h0[ho + j] += x * P[w + j]; } }
    for (let j = 0; j < H; j++) h0[ho + j] = Math.tanh(h0[ho + j]);
    for (let j = 0; j < H; j++) h1[ho + j] = P[b1 + j];
    for (let k = 0; k < H; k++) { const x = h0[ho + k], w = W1 + k * H; for (let j = 0; j < H; j++) h1[ho + j] += x * P[w + j]; }
    for (let j = 0; j < H; j++) h1[ho + j] = Math.tanh(h1[ho + j]);
    let out = P[b2]; for (let j = 0; j < H; j++) out += h1[ho + j] * P[W2 + j];
    return out;
  }
  function bwd(P, off, o, H, X, xo, h0, h1, ho, dout, G, dh0, dh1) {
    const W0 = off + o.W0, b0 = off + o.b0, W1 = off + o.W1, b1 = off + o.b1, W2 = off + o.W2, b2 = off + o.b2;
    G[b2] += dout;
    for (let j = 0; j < H; j++) { const h = h1[ho + j]; G[W2 + j] += dout * h; const d = dout * P[W2 + j] * (1 - h * h); dh1[j] = d; G[b1 + j] += d; }
    for (let k = 0; k < H; k++) {
      const x = h0[ho + k], w = W1 + k * H; let s = 0;
      for (let j = 0; j < H; j++) { const d = dh1[j]; G[w + j] += x * d; s += P[w + j] * d; }
      const d0 = s * (1 - x * x); dh0[k] = d0; G[b0 + k] += d0;
    }
    for (let k = 0; k < o.nIn; k++) { const x = X[xo + k]; if (x !== 0) { const w = W0 + k * H; for (let j = 0; j < H; j++) G[w + j] += x * dh0[j]; } }
  }
  const sigmoid = z => 1 / (1 + Math.exp(-z));

  /** One data-parallel learner: owns environments, collects rollouts, computes minibatch gradients, plays evaluation games. */
  class Learner {
    constructor(cfg, data) {
      this.cfg = Object.assign({ H: 64, envs: 16, T: 128, gamma: 0.99, lam: 0.95, clip: 0.2, ent: 0.01, pFull: 0.1, pHard: 0.0, pTrans: 0.0, maxSteps: 1500, fullSteps: 9000, hardSteps: 600, seed: 1, obsVer: 1, coinW: 0 }, cfg);
      const c = this.cfg; this.H = c.H; this.nIn = c.obsVer === 2 ? 84 : 64; this.o = layoutOf(c.H, this.nIn); this.size = this.o.size;
      this.itemsOn = c.obsVer === 2 || c.coinW > 0;   // coins are only simulated when they matter (observation v2 or a coin reward)
      this.rng = mulberry(c.seed * 7919 + 13);
      this.data = data; this.N = c.envs; this.T = c.T;
      this.envs = []; this.epLen = new Int32Array(this.N); this.epMax = new Int32Array(this.N); this.ring = []; this.hard = [];
      for (let i = 0; i < this.N; i++) { const s = new GogunSim(data); s.itemsOn = this.itemsOn; this.envs.push(s); this.ring.push([]); }
      this.levelW = [1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6];
      const B = this.N * this.T;
      const nIn = this.nIn; this.obs = new Float32Array(B * nIn); this.act = new Float32Array(B); this.logp = new Float32Array(B);
      this.val = new Float32Array((this.T + 1) * this.N); this.rew = new Float32Array(B); this.term = new Float32Array(B); this.end = new Float32Array(B); this.boot = new Float32Array(B);
      this.adv = new Float32Array(B); this.ret = new Float32Array(B);
      this.h0 = new Float32Array(B > 4096 ? 4096 * this.H : B * this.H); this.h1 = new Float32Array(this.h0.length);
      this.dh0 = new Float32Array(this.H); this.dh1 = new Float32Array(this.H);
      this.tmpObs = new Float32Array(nIn); this.perm = new Int32Array(B); for (let i = 0; i < B; i++) this.perm[i] = i; this.cursor = B;
      this.mbH0 = new Float32Array(1); this.started = false;
      for (let i = 0; i < this.N; i++) this.resetEnv(i);
    }
    pickLevel() {
      const w = this.levelW; let s = 0; for (let i = 0; i < 6; i++) s += w[i];
      let r = this.rng() * s; for (let i = 0; i < 6; i++) { r -= w[i]; if (r <= 0) return i; } return 5;
    }
    resetEnv(i) {
      const c = this.cfg, r = this.rng; this.ring[i].length = 0;
      if (c.pHard > 0 && this.hard.length >= 60 && r() < c.pHard) {
        this.envs[i] = this.hard[Math.floor(r() * this.hard.length)].clone(); this.envs[i].itemsOn = this.itemsOn; this.epLen[i] = 0; this.epMax[i] = c.hardSteps; return;
      }
      let level, count, phase, ms;
      if (r() < c.pFull) { level = 0; count = 0; phase = 0; ms = c.fullSteps; }
      else if (r() < c.pTrans) { level = Math.floor(r() * 5); count = MAXCOUNT[level] - (1 + Math.floor(r() * 13)); phase = Math.floor(r() * SPEEDS[level]); ms = 450; }
      else { level = this.pickLevel(); count = Math.floor(r() * MAXCOUNT[level]); phase = Math.floor(r() * SPEEDS[level]); ms = c.maxSteps; }
      const e = this.envs[i]; e.itemsOn = this.itemsOn; e.reset(1 + Math.floor(r() * 2147483646), level, count, phase); this.epLen[i] = 0; this.epMax[i] = ms;
    }

    /** rollout with the given params [actor|critic]; returns statistics */
    collect(P, levelW, opts) {
      if (levelW) this.levelW = levelW;
      if (opts) Object.assign(this.cfg, opts);
      const N = this.N, T = this.T, H = this.H, o = this.o, c = this.cfg, cOff = this.size;
      const st = { samples: N * T, episodes: 0, deaths: 0, clears: 0, timeouts: 0, lenSum: 0, deathsByLevel: [0, 0, 0, 0, 0, 0], hardUsed: 0 };
      const h0 = this.h0, h1 = this.h1, tmp = this.tmpObs, nIn = this.nIn, ver = c.obsVer;
      for (let t = 0; t < T; t++) {
        for (let i = 0; i < N; i++) {
          const k = t * N + i, env = this.envs[i];
          env.features(this.obs.subarray(k * nIn, (k + 1) * nIn), ver);
          const z = fwd(P, 0, o, H, this.obs, k * nIn, h0, h1, 0), p = sigmoid(z), a = this.rng() < p ? 1 : 0;
          this.act[k] = a; this.logp[k] = Math.log((a ? p : 1 - p) + 1e-8);
          this.val[t * N + i] = fwd(P, cOff, o, H, this.obs, k * nIn, h0, h1, 0);
          const score0 = env.score; env.step(a); this.epLen[i]++;
          let r = env.dead ? 0 : 0.02, flag = 0;
          if (c.coinW) r += c.coinW * (env.score - score0);
          if (env.dead) flag = 1; else if (env.cleared) { flag = 2; r += 2; } else if (this.epMax[i] > 0 && this.epLen[i] >= this.epMax[i]) flag = 4;
          this.rew[k] = r; this.term[k] = (flag & 3) ? 1 : 0; this.end[k] = flag ? 1 : 0; this.boot[k] = 0;
          if (c.pHard > 0 && !flag && this.epLen[i] % 30 === 0) { const ring = this.ring[i]; ring.push([this.epLen[i], env.clone()]); if (ring.length > 12) ring.shift(); }
          if (flag) {
            if (flag & 4) { env.features(tmp, ver); this.boot[k] = fwd(P, cOff, o, H, tmp, 0, h0, h1, 0); }
            st.episodes++; st.lenSum += this.epLen[i];
            if (flag & 1) {
              st.deaths++; st.deathsByLevel[Math.min(env.level, 5)]++;
              if (c.pHard > 0) { const cand = this.ring[i].filter(x => x[0] <= this.epLen[i] - 100); if (cand.length) { this.hard.push((cand.length < 5 ? cand[cand.length - 1] : cand[cand.length - 3])[1]); if (this.hard.length > 500) this.hard.shift(); } }
            } else if (flag & 2) st.clears++; else st.timeouts++;
            this.resetEnv(i);
          }
        }
      }
      for (let i = 0; i < N; i++) { this.envs[i].features(tmp, ver); this.val[T * N + i] = fwd(P, cOff, o, H, tmp, 0, h0, h1, 0); }
      // GAE
      const gamma = c.gamma, lam = c.lam;
      for (let i = 0; i < N; i++) {
        let last = 0;
        for (let t = T - 1; t >= 0; t--) {
          const k = t * N + i, nonterm = 1 - this.term[k], nonend = 1 - this.end[k];
          const nv = this.end[k] > 0 ? this.boot[k] : this.val[(t + 1) * N + i];
          const delta = this.rew[k] + gamma * nv * nonterm - this.val[t * N + i];
          last = delta + gamma * lam * nonend * last; this.adv[k] = last; this.ret[k] = last + this.val[t * N + i];
        }
      }
      this.cursor = this.N * this.T;   // force reshuffle on the next grad() call
      return st;
    }

    /** gradient of the PPO loss on a random local minibatch of size mb, at parameters P.  Returns {G, ent, vloss, clipfrac} */
    grad(P, first, mb, opts) {
      const c = this.cfg; if (opts) Object.assign(c, opts);
      const B = this.N * this.T, H = this.H, o = this.o, cOff = this.size, G = new Float32Array(2 * this.size);
      if (first || this.cursor + mb > B) {   // reshuffle (Fisher-Yates)
        const p = this.perm; for (let i = B - 1; i > 0; i--) { const j = Math.floor(this.rng() * (i + 1)); const t = p[i]; p[i] = p[j]; p[j] = t; } this.cursor = 0;
      }
      mb = Math.min(mb, B); const idx = this.perm.subarray(this.cursor, this.cursor + mb); this.cursor += mb;
      let am = 0; for (let m = 0; m < mb; m++) am += this.adv[idx[m]]; am /= mb;
      let av = 0; for (let m = 0; m < mb; m++) { const d = this.adv[idx[m]] - am; av += d * d; } const asd = Math.sqrt(av / mb) + 1e-8;
      if (this.h0.length < H) this.h0 = new Float32Array(H), this.h1 = new Float32Array(H);
      const h0 = this.h0, h1 = this.h1, dh0 = this.dh0, dh1 = this.dh1, clip = c.clip, entC = c.ent, freeze = !!c.freezeActor;
      let ent = 0, vloss = 0, cf = 0;
      for (let m = 0; m < mb; m++) {
        const k = idx[m], xo = k * this.nIn, act = this.act[k];
        if (!freeze) {
          const z = fwd(P, 0, o, H, this.obs, xo, h0, h1, 0), p = sigmoid(z);
          const lp = Math.log((act > 0.5 ? p : 1 - p) + 1e-8), ratio = Math.exp(lp - this.logp[k]), A = (this.adv[k] - am) / asd;
          const clipped = Math.min(Math.max(ratio, 1 - clip), 1 + clip);
          const unclipped = (ratio * A <= clipped * A);
          let dz = unclipped ? (-(A * ratio) / mb) * (act - p) : 0;
          dz += (-entC) * (-(p * (1 - p)) * z) / mb;
          ent += -(p * Math.log(p + 1e-8) + (1 - p) * Math.log(1 - p + 1e-8)); if (!unclipped) cf++;
          bwd(P, 0, o, H, this.obs, xo, h0, h1, 0, dz, G, dh0, dh1);
        }
        const v = fwd(P, cOff, o, H, this.obs, xo, h0, h1, 0), dv = (v - this.ret[k]); vloss += dv * dv;
        bwd(P, cOff, o, H, this.obs, xo, h0, h1, 0, dv / mb, G, dh0, dh1);
      }
      return { G, ent: ent / mb, vloss: vloss / mb, clipfrac: cf / mb, n: mb };
    }

    /** deterministic full games from the start: returns per-game [cleared, frames, level] */
    evalGames(P, games, seed0, maxFrames) {
      const H = this.H, o = this.o, out = [], h0 = this.h0, h1 = this.h1, obs = this.tmpObs, ver = this.cfg.obsVer;
      const s = new GogunSim(this.data); s.itemsOn = this.itemsOn;
      for (let g = 0; g < games; g++) {
        s.reset(seed0 + g * 7919, 0, 0, 0); let f = 0;
        while (!s.dead && !s.cleared && f < maxFrames) { s.features(obs, ver); const z = fwd(P, 0, o, H, obs, 0, h0, h1, 0); s.step(z > 0 ? 1 : 0); f++; }
        out.push([s.cleared ? 1 : 0, f, s.level, s.score, s.way]);
      }
      return out;
    }
  }

  /** coordinator-side helpers: Adam with per-group gradient clipping, and EMA of the actor */
  class Optimizer {
    constructor(H, nIn) {
      this.o = layoutOf(H, nIn); this.size = this.o.size; const n = 2 * this.size;
      this.m = new Float32Array(n); this.v = new Float32Array(n); this.t = 0;
      this.b1 = 0.9; this.b2 = 0.999; this.eps = 1e-5; this.clipA = 0.5; this.clipC = 1.0;
    }
    step(P, G, lr, freezeActor) {
      const n = this.size; let gnA = 0, gnC = 0;
      for (let i = 0; i < n; i++) { gnA += G[i] * G[i]; gnC += G[n + i] * G[n + i]; }
      gnA = Math.sqrt(gnA); gnC = Math.sqrt(gnC);
      const sA = gnA > this.clipA ? this.clipA / (gnA + 1e-6) : 1, sC = gnC > this.clipC ? this.clipC / (gnC + 1e-6) : 1;
      this.t++; const c1 = 1 - Math.pow(this.b1, this.t), c2 = 1 - Math.pow(this.b2, this.t);
      for (let i = 0; i < 2 * n; i++) {
        if (freezeActor && i < n) continue;
        const g = G[i] * (i < n ? sA : sC);
        const m = this.m[i] = this.b1 * this.m[i] + (1 - this.b1) * g, v = this.v[i] = this.b2 * this.v[i] + (1 - this.b2) * g * g;
        P[i] -= lr * (m / c1) / (Math.sqrt(v / c2) + this.eps);
      }
      return { gnA, gnC };
    }
  }
  function actorToJSON(P, H, meta, nIn) {
    nIn = nIn || OBS; const o = layoutOf(H, nIn), rows = (base, r, c) => { const out = []; for (let i = 0; i < r; i++) out.push(Array.from(P.subarray(base + i * c, base + (i + 1) * c), x => +x.toFixed(6))); return out; };
    return { obs_dim: nIn, layers: [
      { W: rows(o.W0, nIn, H), b: Array.from(P.subarray(o.b0, o.b0 + H), x => +x.toFixed(6)) },
      { W: rows(o.W1, H, H), b: Array.from(P.subarray(o.b1, o.b1 + H), x => +x.toFixed(6)) },
      { W: rows(o.W2, H, 1), b: [+P[o.b2].toFixed(6)] }], meta: meta || {} };
  }
  function actorFromJSON(json) {
    const L = json.layers; if (!L || L.length !== 3) throw new Error('3-layer MLP expected');
    const H = L[0].b.length, nIn = L[0].W.length; if ((nIn !== 64 && nIn !== 84) || L[1].W.length !== H || L[2].W.length !== H || L[1].b.length !== H) throw new Error('shape mismatch: need 64 or 84 -> H -> H -> 1');
    const o = layoutOf(H, nIn), P = new Float32Array(2 * o.size);
    for (let i = 0; i < nIn; i++) P.set(L[0].W[i], o.W0 + i * H); P.set(L[0].b, o.b0);
    for (let i = 0; i < H; i++) P.set(L[1].W[i], o.W1 + i * H); P.set(L[1].b, o.b1);
    for (let i = 0; i < H; i++) P[o.W2 + i] = L[2].W[i][0]; P[o.b2] = L[2].b[0];
    return { H, P, nIn };
  }
  /** zero-pad the input layer of an actor (flat layout) from nFrom to nTo inputs: behaviour is unchanged until the new inputs are trained */
  function expandActor(P, H, nFrom, nTo) {
    const a = layoutOf(H, nFrom), b = layoutOf(H, nTo), out = new Float32Array(b.size);
    out.set(P.subarray(a.W0, a.W0 + nFrom * H), b.W0); out.set(P.subarray(a.b0, a.b0 + H), b.b0); out.set(P.subarray(a.W1, a.W1 + H * H), b.W1);
    out.set(P.subarray(a.b1, a.b1 + H), b.b1); out.set(P.subarray(a.W2, a.W2 + H), b.W2); out[b.b2] = P[a.b2]; return out;
  }
  return { OBS, layoutOf, initParams, Learner, Optimizer, actorToJSON, actorFromJSON, expandActor, fwd, bwd, mulberry };
});
