// single-thread run of the browser trainer core in Node: speed + learning sanity check
const T = require('./trainer.js'); const data = require('./gogun_data.json');
const H = +process.argv[2] || 64, seconds = +process.argv[3] || 90, N = +process.argv[4] || 64, TT = 128, MB = 2048, EPOCHS = 4;
const cfg = { H, envs: N, T: TT, seed: 1, ent: 0.01, pFull: 0.1 };
const L = new T.Learner(cfg, data); let P = T.initParams(H, 11); const opt = new T.Optimizer(H); const ema = Float32Array.from(P.subarray(0, opt.size));
const t0 = Date.now(); let it = 0, samples = 0; const recent = []; let levelW = [1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6, 1 / 6]; const deathEma = [1, 1, 1, 1, 1, 1];
while ((Date.now() - t0) / 1000 < seconds) {
  const st = L.collect(P, levelW, {}); samples += st.samples;
  for (let e = 0; e < EPOCHS; e++) for (let m = 0; m < (N * TT) / MB; m++) {
    const r = L.grad(P, m === 0, MB, {}); const lr = 3e-4; opt.step(P, r.G, lr, false);
    for (let i = 0; i < opt.size; i++) ema[i] = 0.995 * ema[i] + 0.005 * P[i];
  }
  for (let l = 0; l < 6; l++) deathEma[l] += st.deathsByLevel[l]; const s = deathEma.reduce((a, b) => a + b, 0); levelW = deathEma.map(x => 0.3 / 6 + 0.7 * x / s); for (let l = 0; l < 6; l++) deathEma[l] *= 0.97;
  it++; recent.push([st.episodes, st.lenSum, st.deaths]); if (recent.length > 10) recent.shift();
  if (it % 10 === 0) { const ep = recent.reduce((a, r) => a + r[0], 0), ln = recent.reduce((a, r) => a + r[1], 0), d = recent.reduce((a, r) => a + r[2], 0); console.log(`it ${it} samples ${(samples / 1e6).toFixed(2)}M ${((Date.now() - t0) / 1000).toFixed(0)}s  ${(samples / ((Date.now() - t0) / 1000) / 1000).toFixed(1)}k samples/s  ep_len ${(ln / Math.max(1, ep)).toFixed(0)} dead% ${(100 * d / Math.max(1, ep)).toFixed(0)}`); }
}
const Pe = Float32Array.from(P); Pe.set(ema, 0);
const t1 = Date.now(); const NG = +process.argv[5] || 20; const res = L.evalGames(Pe, NG, 555, 9500); const clears = res.filter(r => r[0]).length;
console.log(`EVAL (ema actor) ${clears}/${NG} full games cleared, mean frames ${(res.reduce((a, r) => a + r[1], 0) / NG).toFixed(0)}  [${((Date.now() - t1) / 1000).toFixed(1)}s]`);
