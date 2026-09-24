// DFS "oracle" planner (uses full knowledge of the deterministic sim). Used ONLY to (a) prove the game is clearable in the remake,
// (b) generate long, diverse traces for cross-checking the C port. The learned agent never uses it.
const S = require('./sim.js'); const data = require('./gogun_data.json');
function tSupportOf(s) {
  let cur = 198.0, ch = true;
  while (ch) { ch = false; for (const b of s.blocks) if ((b.type === 2 || b.type === 4) && b.x - 100 <= cur && b.x + 100 > cur) { cur = b.x + 100; ch = true; } }
  return (cur - 198.0) / Math.max(1, s.speed);
}
function key(t, s) { return t + '|' + s.status + s.frame + '|' + s.gy + '|' + s.dy + '|' + s.tx + '|' + s.ty + '|' + (s.click ? 1 : 0) + (s.pressed ? 1 : 0) + '|' + s.gHandler + s.gGravity + '|' + s.rHandler; }
function plan(s0) {
  for (const H of [40, 70, 110, 160, 230, 320]) {
    const seen = new Set();
    const dfs = (s, t, path) => {
      if (s.cleared) return path;
      if (t >= 4 && s.status === 'run' && tSupportOf(s) >= 6) return path;
      if (t >= H) return null;
      const k = key(t, s); if (seen.has(k)) return null; seen.add(k);
      for (const a of [0, 1]) { const c = s.clone(); c.step(a); if (c.dead) continue; const r = dfs(c, t + 1, path + a); if (r) return r; }
      return null;
    };
    const c0 = s0.clone(); c0.itemsOn = false;
    const r = dfs(c0, 0, ''); if (r) return r;
  }
  return null;
}
module.exports = { plan, tSupportOf };
if (require.main === module) {
  const seeds = process.argv.slice(2).map(Number); if (!seeds.length) seeds.push(1);
  for (const seed of seeds) {
    const s = new S(data); s.reset(seed, 0, 0, 0);
    let pl = '', pi = 0, frames = 0, plans = 0, t0 = Date.now();
    while (!s.dead && !s.cleared && frames < 12000) {
      if (pi >= pl.length) { const r = plan(s); plans++; if (!r) { break; } pl = r; pi = 0; if (!pl.length) pl = '0'; }
      s.step(+pl[pi++]); frames++;
    }
    console.log(`seed ${seed}: frames ${frames} level ${s.level} score ${s.score} dead ${s.dead} cleared ${s.cleared} plans ${plans} (${((Date.now() - t0) / 1000).toFixed(1)}s)`);
  }
}
