// v2 (coin-aware) observation: JS reference trace driven by the v1 policy, to be compared with the C port (set_obs_version(2))
const S = require('./sim.js'); const data = require('./gogun_data.json'); const fs = require('fs');
const w = JSON.parse(fs.readFileSync(process.argv[2])); const N = +process.argv[3] || 3, seed0 = +process.argv[4] || 300;
const L = w.layers.map(l => ({ W: l.W.map(r => Float64Array.from(r)), b: Float64Array.from(l.b), n: l.b.length })); const bufs = L.map(l => new Float64Array(l.n));
function logit(x) { let inp = x; for (let li = 0; li < L.length; li++) { const l = L[li], out = bufs[li]; out.set(l.b); for (let i = 0; i < inp.length; i++) { const v = inp[i]; if (v === 0) continue; const row = l.W[i]; for (let j = 0; j < l.n; j++) out[j] += v * row[j]; } if (li < L.length - 1) for (let j = 0; j < l.n; j++) out[j] = Math.tanh(out[j]); inp = out; } return inp[0]; }
const o1 = new Float32Array(64), o2 = new Float32Array(84), eps = [];
for (let g = 0; g < N; g++) {
  const seed = seed0 + g * 7919, s = new S(data), level = g % 3 === 0 ? 0 : (g % 3 === 1 ? 2 : 4);
  s.reset(seed, level, 0, g * 3); const acts = [], rows = [];
  while (!s.dead && !s.cleared && acts.length < 3000) {
    s.features(o1, 1); let a = logit(o1) > 0 ? 1 : 0; if (acts.length % 97 === 5) a = 1 - a;   // a few off-policy presses for variety
    acts.push(a); s.step(a); s.features(o2, 2);
    rows.push([s.score, Array.from(o2.subarray(64, 84), x => +x.toFixed(6))]);
  }
  eps.push({ seed, level, phase: g * 3, acts, rows });
}
fs.writeFileSync('difftrace_v2.json', JSON.stringify(eps));
console.log(eps.map(e => e.acts.length).join(' '), 'steps; final scores', eps.map(e => e.rows[e.rows.length - 1][0]).join(' '));
