// finite-difference check of the analytic PPO gradient (tiny net, one learner, one minibatch)
const S = require('./sim.js'); const T = require('./trainer.js'); const data = require('./gogun_data.json');
const H = 6, cfg = { H, envs: 4, T: 8, seed: 3, ent: 0.02 };
const L = new T.Learner(cfg, data); const P = T.initParams(H, 5);
for (let i = 0; i < P.length; i++) P[i] += (Math.random() - 0.5) * 0.4;   // make actor non-trivial
L.collect(P, null, {});
// fixed minibatch = all 32 samples, so the loss is a deterministic function of P
function loss(P2) {
  const cfg2 = L.cfg; const B = L.N * L.T, o = L.o; let pl = 0, vl = 0, en = 0;
  const h0 = new Float32Array(H), h1 = new Float32Array(H);
  let am = 0; for (let k = 0; k < B; k++) am += L.adv[k]; am /= B; let av = 0; for (let k = 0; k < B; k++) av += (L.adv[k] - am) ** 2; const asd = Math.sqrt(av / B) + 1e-8;
  for (let k = 0; k < B; k++) {
    const z = T.fwd(P2, 0, o, H, L.obs, k * 64, h0, h1, 0), p = 1 / (1 + Math.exp(-z)), a = L.act[k];
    const lp = Math.log((a > 0.5 ? p : 1 - p) + 1e-8), ratio = Math.exp(lp - L.logp[k]), A = (L.adv[k] - am) / asd;
    pl += -Math.min(ratio * A, Math.min(Math.max(ratio, 0.8), 1.2) * A);
    en += -(p * Math.log(p + 1e-8) + (1 - p) * Math.log(1 - p + 1e-8));
    const v = T.fwd(P2, L.size, o, H, L.obs, k * 64, h0, h1, 0); vl += 0.5 * (v - L.ret[k]) ** 2;
  }
  return pl / B - cfg2.ent * en / B + vl / B;
}
const r = L.grad(P, true, L.N * L.T, {}); const G = r.G;
let maxRel = 0, worst = -1; const P64 = Float64Array.from(P);
const eps = 1e-3;
for (let trial = 0; trial < 60; trial++) {
  const i = Math.floor(Math.random() * P.length);
  const Pp = Float32Array.from(P), Pm = Float32Array.from(P); Pp[i] += eps; Pm[i] -= eps;
  const num = (loss(Pp) - loss(Pm)) / (2 * eps), ana = G[i];
  const rel = Math.abs(num - ana) / Math.max(1e-4, Math.abs(num) + Math.abs(ana));
  if (rel > maxRel) { maxRel = rel; worst = i; }
}
console.log('max relative gradient error over 60 random params:', maxRel.toExponential(2), '(param', worst, ')');
