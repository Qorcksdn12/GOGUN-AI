// continue-from-pretrained path (actor frozen while the random critic warms up), single thread, H=128
const T = require('./trainer.js'); const data = require('./gogun_data.json'); const fs = require('fs');
const pre = T.actorFromJSON(JSON.parse(fs.readFileSync(process.argv[2] || 'w_final.json'))); const H = pre.H, size = T.layoutOf(H).size;
const P = T.initParams(H, 4242); P.set(pre.P.subarray(0, size), 0);
const N = 32, TT = 128, MB = 2048, seconds = +process.argv[3] || 100, FREEZE = 3;
const L = new T.Learner({ H, envs: N, T: TT, seed: 9, ent: 0.003 }, data), opt = new T.Optimizer(H), ema = Float32Array.from(P.subarray(0, size));
const t0 = Date.now(); let it = 0, samples = 0; let levelW = [1/6,1/6,1/6,1/6,1/6,1/6];
while ((Date.now() - t0) / 1000 < seconds) {
  const freeze = it < FREEZE; const st = L.collect(P, levelW, { ent: 0.003 }); samples += st.samples;
  for (let e = 0; e < 4; e++) for (let m = 0; m < (N * TT) / MB + 1; m++) { const r = L.grad(P, m === 0, Math.min(MB, N * TT), { freezeActor: freeze, ent: 0.003 }); opt.step(P, r.G, 5e-5, freeze); for (let i = 0; i < size; i++) ema[i] = 0.995 * ema[i] + 0.005 * P[i]; if (m >= (N * TT) / MB) break; }
  it++; if (it % 3 === 0) console.log(`it ${it}${freeze ? ' (frozen)' : ''} samples ${(samples / 1e3).toFixed(0)}k  ep_len ${(st.lenSum / Math.max(1, st.episodes)).toFixed(0)}  dead ${st.deaths}/${st.episodes}  nan? ${P.some(Number.isNaN)}`);
}
const Pe = Float32Array.from(P); Pe.set(ema, 0);
const res = L.evalGames(Pe, 20, 8100, 9500); console.log('EVAL (ema) after continue:', res.filter(r => r[0]).length + '/20 cleared');
const res0 = L.evalGames(pre.P, 20, 8100, 9500); console.log('EVAL pretrained baseline :', res0.filter(r => r[0]).length + '/20 cleared');
