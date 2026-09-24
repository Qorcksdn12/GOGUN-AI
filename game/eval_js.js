// Evaluate a policy (weights json) with the exact JS sim used by the HTML page: N full games from the very beginning.
const S = require('./sim.js'); const data = require('./gogun_data.json'); const fs = require('fs');
const w = JSON.parse(fs.readFileSync(process.argv[2])); const N = +process.argv[3] || 50; const seed0 = +process.argv[4] || 1;
const L = w.layers.map(l => ({ W: l.W.map(r => Float64Array.from(r)), b: Float64Array.from(l.b), n: l.b.length }));
const bufs = L.map(l => new Float64Array(l.n));
function logit(x) {
  let inp = x;
  for (let li = 0; li < L.length; li++) {
    const l = L[li], out = bufs[li]; out.set(l.b);
    for (let i = 0; i < inp.length; i++) { const v = inp[i]; if (v === 0) continue; const row = l.W[i]; for (let j = 0; j < l.n; j++) out[j] += v * row[j]; }
    if (li < L.length - 1) for (let j = 0; j < l.n; j++) out[j] = Math.tanh(out[j]);
    inp = out;
  }
  return inp[0];
}
const obs = new Float32Array(64); let clears = 0, deaths = []; const t0 = Date.now(); const acts = {};
for (let g = 0; g < N; g++) {
  const s = new S(data); s.order = process.env.ORDER || 'srg'; s.reset(seed0 + g * 7919, 0, 0, 0); s.itemsOn = true;
  let f = 0; const rec = [];
  while (!s.dead && !s.cleared && f < 12000) { s.features(obs); const a = logit(obs) > 0 ? 1 : 0; rec.push(a); s.step(a); f++; }
  if (s.cleared) clears++; else deaths.push({ seed: seed0 + g * 7919, frames: f, level: s.level, count: s.count, status: s.status, blocks: s.blocks.map(b => b.type + '@' + Math.round(b.x)).join(' ') });
  acts[seed0 + g * 7919] = { acts: rec, cleared: s.cleared, score: s.score, frames: f };
}
console.log(`games ${N}: cleared ${clears}  (${(100 * clears / N).toFixed(1)}%)   ${((Date.now() - t0) / 1000).toFixed(1)}s`);
for (const d of deaths.slice(0, 12)) console.log('  death', JSON.stringify(d));
if (process.argv[5]) fs.writeFileSync(process.argv[5], JSON.stringify(acts));
