/* Coordinator (main thread) for in-browser PPO: spawns Web Workers, averages their gradients, runs Adam + EMA. */
(function (root, factory) { root.GogunTrainCtl = factory(root.GogunTrain); })(typeof self !== 'undefined' ? self : this, function (GT) {
  'use strict';
  class Pool {
    constructor(workerSrc) { this.src = workerSrc; this.workers = []; this.nextId = 1; this.pending = new Map(); this.url = null; }
    spawn(n) {
      this.dispose();
      this.url = URL.createObjectURL(new Blob([this.src], { type: 'text/javascript' }));
      for (let i = 0; i < n; i++) {
        const w = new Worker(this.url);
        w.onmessage = e => { const p = this.pending.get(e.data.id); if (!p) return; this.pending.delete(e.data.id); if (e.data.error) p.rej(new Error(e.data.error)); else p.res(e.data.out); };
        w.onerror = e => { for (const [, p] of this.pending) p.rej(new Error(e.message || 'worker error')); this.pending.clear(); };
        this.workers.push(w);
      }
    }
    call(i, msg) { const id = this.nextId++; msg.id = id; return new Promise((res, rej) => { this.pending.set(id, { res, rej }); this.workers[i].postMessage(msg); }); }
    all(msgFn) { return Promise.all(this.workers.map((w, i) => this.call(i, msgFn(i)))); }
    dispose() { for (const w of this.workers) w.terminate(); this.workers = []; this.pending.clear(); if (this.url) { URL.revokeObjectURL(this.url); this.url = null; } }
  }

  class Controller {
    constructor(workerSrc, data, hooks) { this.src = workerSrc; this.data = data; this.h = hooks || {}; this.pool = null; this.running = false; this.evalPool = null; this.evalH = 0; this.stopped = Promise.resolve(); }
    get iter() { return this.it || 0; }
    /** cfg: {H, workers, envsTotal, T, epochs, mbTotal, lr, ent, ema, gamma, lam, pHard, decay, freezeIters, initFull (Float32Array [actor|critic]) | null} */
    async start(cfg) {
      await this.stop();
      const c = this.cfg = Object.assign({ H: 64, workers: 2, envsTotal: 64, T: 128, epochs: 4, mbTotal: 2048, lr: 3e-4, ent: 0.01, ema: 0.995, gamma: 0.99, lam: 0.95, pHard: 0.0, decay: 600, freezeIters: 0, initFull: null, obsVer: 1, coinW: 0 }, cfg);
      const nIn = c.obsVer === 2 ? 84 : 64; this.nIn = nIn;
      const W = c.workers, perW = Math.max(4, Math.round(c.envsTotal / W));
      this.pool = new Pool(this.src); this.pool.spawn(W);
      this.envsPerWorker = perW; this.size = GT.layoutOf(c.H, nIn).size;
      await this.pool.all(i => ({ type: 'init', data: this.data, cfg: { H: c.H, envs: perW, T: c.T, gamma: c.gamma, lam: c.lam, ent: c.ent, pHard: 0, obsVer: c.obsVer, coinW: c.coinW, seed: 1000 + i * 17 + (Date.now() & 255) } }));
      this.P = c.initFull ? Float32Array.from(c.initFull) : GT.initParams(c.H, (Date.now() & 0xffffff) + 1, nIn);
      this.opt = new GT.Optimizer(c.H, nIn); this.ema = Float32Array.from(this.P.subarray(0, this.size));
      this.it = 0; this.samples = 0; this.t0 = performance.now(); this.levelW = [1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6]; this.deathEma = [1, 1, 1, 1, 1, 1]; this.recent = [];
      this.running = true; this.error = null;
      this.stopped = this._loop();
    }
    async stop() { this.running = false; try { await this.stopped; } catch (e) { } if (this.pool) { this.pool.dispose(); this.pool = null; } }
    emaActor() { return this.ema; }
    async _loop() {
      const c = this.cfg, W = this.pool.workers.length, B = this.envsPerWorker * c.T, mbW = Math.max(32, Math.floor(c.mbTotal / W)), rounds = Math.max(1, Math.round(B / mbW));
      try {
        while (this.running) {
          const tIter = performance.now(), freeze = this.it < c.freezeIters;
          const cs = await this.pool.all(() => ({ type: 'collect', P: this.P, levelW: this.levelW, opts: { ent: c.ent, pHard: this.it >= 30 ? c.pHard : 0 } }));
          if (!this.running) break;
          let ep = 0, len = 0, dead = 0, clr = 0, samples = 0; const dbl = [0, 0, 0, 0, 0, 0];
          for (const r of cs) { ep += r.episodes; len += r.lenSum; dead += r.deaths; clr += r.clears; samples += r.samples; for (let l = 0; l < 6; l++) dbl[l] += r.deathsByLevel[l]; }
          const lr = c.lr * Math.max(0.1, 1 - this.it / c.decay); let ent = 0, vloss = 0, clip = 0, nStep = 0;
          for (let e = 0; e < c.epochs && this.running; e++) for (let r = 0; r < rounds && this.running; r++) {
            const gs = await this.pool.all(() => ({ type: 'grad', P: this.P, first: r === 0, mb: mbW, opts: { freezeActor: freeze, ent: c.ent } }));
            if (!this.running) break;
            const G = gs[0].G; ent += gs[0].ent; vloss += gs[0].vloss; clip += gs[0].clipfrac; nStep++;
            for (let k = 1; k < W; k++) { const g = gs[k].G; for (let i = 0; i < G.length; i++) G[i] += g[i]; ent += gs[k].ent; vloss += gs[k].vloss; clip += gs[k].clipfrac; }
            const inv = 1 / W; for (let i = 0; i < G.length; i++) G[i] *= inv;
            this.opt.step(this.P, G, lr, freeze);
            const a = c.ema, n = this.size; for (let i = 0; i < n; i++) this.ema[i] = a * this.ema[i] + (1 - a) * this.P[i];
          }
          if (!this.running) break;
          for (let l = 0; l < 6; l++) this.deathEma[l] += dbl[l];
          const ds = this.deathEma.reduce((a, b) => a + b, 0); this.levelW = this.deathEma.map(x => 0.3 / 6 + 0.7 * x / ds); for (let l = 0; l < 6; l++) this.deathEma[l] *= 0.97;
          this.it++; this.samples += samples; this.recent.push([ep, len, dead, clr]); if (this.recent.length > 8) this.recent.shift();
          const rp = this.recent.reduce((a, r) => [a[0] + r[0], a[1] + r[1], a[2] + r[2], a[3] + r[3]], [0, 0, 0, 0]);
          const dt = (performance.now() - tIter) / 1000, el = (performance.now() - this.t0) / 1000;
          if (this.h.onIter) this.h.onIter({ it: this.it, samples: this.samples, sps: samples / dt, epLen: rp[1] / Math.max(1, rp[0]), deathPct: 100 * rp[2] / Math.max(1, rp[0]), clearPct: 100 * rp[3] / Math.max(1, rp[0]), ent: ent / Math.max(1, nStep * W), vloss: vloss / Math.max(1, nStep * W), clipfrac: clip / Math.max(1, nStep * W), lr: lr, elapsed: el, levelW: this.levelW, frozen: freeze });
        }
      } catch (err) { this.error = err; this.running = false; if (this.h.onError) this.h.onError(err); }
    }
    /** deterministic full games with an actor (Float32Array, layout of H). Uses a dedicated small pool. */
    async evaluate(H, actorP, games, nWorkers, nIn) {
      nIn = nIn || 64; const ver = nIn === 84 ? 2 : 1;
      const W = Math.max(1, Math.min(nWorkers || 2, games)), key = H + ':' + ver;
      if (!this.evalPool || this.evalPool.workers.length !== W || this.evalH !== key) {
        if (this.evalPool) this.evalPool.dispose();
        this.evalPool = new Pool(this.src); this.evalPool.spawn(W); this.evalH = key;
        await this.evalPool.all(i => ({ type: 'init', data: this.data, cfg: { H: H, envs: 1, T: 1, obsVer: ver, seed: 5 + i } }));
      }
      const size = GT.layoutOf(H, nIn).size, P = new Float32Array(2 * size); P.set(actorP.subarray(0, size), 0);
      const per = Math.ceil(games / W), seed0 = 700001 + (Date.now() % 1000) * 13;
      const outs = await this.evalPool.all(i => ({ type: 'eval', P: P, games: Math.min(per, games - i * per), seed0: seed0 + i * per * 7919, maxFrames: 9500 }));
      const flat = [].concat(...outs), n = Math.max(1, flat.length);
      return { games: flat.length, cleared: flat.filter(r => r[0]).length, meanFrames: flat.reduce((a, r) => a + r[1], 0) / n, deathLevels: flat.filter(r => !r[0]).map(r => r[2]),
        meanCoin: flat.reduce((a, r) => a + (r[3] || 0), 0) / n, meanDist: flat.reduce((a, r) => a + (r[4] || 0), 0) / n / 3 };
    }
    disposeAll() { this.running = false; if (this.pool) this.pool.dispose(); if (this.evalPool) this.evalPool.dispose(); }
  }
  return { Controller };
});
