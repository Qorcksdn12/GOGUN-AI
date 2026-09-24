// long-episode differential test data: full games driven by a trained policy in the JS sim (the sim used by the HTML page)
const S = require('./sim.js'); const data = require('./gogun_data.json'); const fs = require('fs');
const w = JSON.parse(fs.readFileSync(process.argv[2])); const N = +process.argv[3] || 6; const seed0 = +process.argv[4] || 100;
const L = w.layers.map(l => ({ W: l.W.map(r => Float64Array.from(r)), b: Float64Array.from(l.b), n: l.b.length })); const bufs = L.map(l => new Float64Array(l.n));
function logit(x) { let inp = x; for (let li = 0; li < L.length; li++) { const l = L[li], out = bufs[li]; out.set(l.b); for (let i = 0; i < inp.length; i++) { const v = inp[i]; if (v === 0) continue; const row = l.W[i]; for (let j = 0; j < l.n; j++) out[j] += v * row[j]; } if (li < L.length - 1) for (let j = 0; j < l.n; j++) out[j] = Math.tanh(out[j]); inp = out; } return inp[0]; }
const obs = new Float32Array(64), eps = [];
for (let g = 0; g < N; g++) {
  const seed = seed0 + g * 7919, s = new S(data); s.reset(seed, 0, 0, 0);
  const acts = [], rows = [];
  while (!s.dead && !s.cleared && acts.length < 12000) {
    s.features(obs); const a = logit(obs) > 0 ? 1 : 0; acts.push(a); s.step(a); s.features(obs);
    let ck = 0; for (let i = 0; i < 64; i++) ck += obs[i] * (i + 1);
    rows.push([s.gy, s.dy, ['run', 'jump', 'shoot', 'rope', 'spin'].indexOf(s.status), s.way, s.level, s.count, s.score, s.dead ? 1 : 0, s.cleared ? 1 : 0, ck]);
  }
  eps.push({ seed, acts, rows });
}
fs.writeFileSync('difftrace_policy.json', JSON.stringify(eps));
console.log(eps.map(e => e.acts.length + (e.rows[e.rows.length - 1][8] ? 'C' : 'D')).join(' '));
