// generates random episodes with the JS reference sim and writes a trace for the C port to be compared against
const S = require('./sim.js'); const data = require('./gogun_data.json');
const fs = require('fs');
let seedState = 12345;
function rr() { seedState = (seedState * 1664525 + 1013904223) >>> 0; return seedState / 4294967296; }
const MAXC = [50, 100, 150, 200, 250, 300, 1000];
const eps = [];
const NEP = +process.argv[2] || 60;
for (let e = 0; e < NEP; e++) {
  const seed = 1000 + e * 7919, level = e % 6, count = Math.floor(rr() * MAXC[level]);
  const s = new S(data); s.reset(seed, level, count, 0);
  const sp = s.speed; const phase = Math.floor(rr() * sp); s.reset(seed, level, count, phase);
  const pPress = [0.08, 0.15, 0.3][e % 3]; const acts = []; const rows = [];
  let hold = 0, cur = 0;
  for (let t = 0; t < 900 && !s.dead && !s.cleared; t++) {
    if (hold <= 0) { cur = rr() < pPress ? 1 : 0; hold = 1 + Math.floor(rr() * (cur ? 6 : 14)); }
    hold--; acts.push(cur);
    s.step(cur);
    const f = s.features();
    rows.push([s.gy, s.dy, ['run', 'jump', 'shoot', 'rope', 'spin'].indexOf(s.status), s.way, s.level, s.count, s.score, s.dead ? 1 : 0, s.cleared ? 1 : 0, s.tx, s.ty, s.bodyRot, s.blocks.length].concat(Array.from(f)));
  }
  eps.push({ seed, level, count, phase, acts, rows });
}
fs.writeFileSync('difftrace.json', JSON.stringify(eps));
console.log('episodes', eps.length, 'total steps', eps.reduce((a, e) => a + e.rows.length, 0), 'dead', eps.filter(e => e.rows[e.rows.length - 1][7]).length);
