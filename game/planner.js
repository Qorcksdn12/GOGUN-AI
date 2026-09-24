// exhaustive DFS planner used only to study feasibility of a fixed map (not part of the learned agent)
const S = require('./sim.js'); const data = require('./gogun_data.json');
function shift(s, d) { for (const b of s.blocks) b.x -= d; s.nextway += d; s.way += d; }
function key(t, s) { return t + '|' + s.status + s.frame + '|' + s.gy + '|' + s.dy + '|' + s.tx + '|' + s.ty + '|' + (s.click ? 1 : 0) + (s.pressed ? 1 : 0) + '|' + s.gHandler + s.gGravity + '|' + s.rHandler; }
function solve(level, mapq, phase, maxT) {
  const s0 = new S(data); s0.itemsOn = false; s0.reset(7, level);
  s0.map = mapq.concat([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]); shift(s0, phase);
  const seen = new Set(); let nodes = 0;
  const hazardAhead = s => s.blocks.some(b => b.type !== 2 && b.x > 60) || s.map.some(t => t !== 2);
  function dfs(s, t, path) {
    if (t > maxT) return null;
    if (!hazardAhead(s) && s.status === 'run' && !s.dead) return path;
    const k = key(t, s);
    if (seen.has(k)) return null; seen.add(k); nodes++;
    for (const a of [0, 1]) {
      const c = s.clone(); c.step(a);
      if (c.dead) continue;
      const r = dfs(c, t + 1, path + a);
      if (r) return r;
    }
    return null;
  }
  const r = dfs(s0, 0, '');
  return { plan: r, nodes };
}
module.exports = { solve, shift };
if (require.main === module) {
  const cases = [
    [2, [2, 2, 1, 1, 2, 2]], [2, [2, 2, 1, 3, 1, 2, 2]], [3, [2, 2, 1, 1, 3, 1, 1, 2, 2, 2]],
    [4, [2, 1, 3, 1, 3, 1, 3, 1, 2, 2]], [5, [1, 3, 1, 3, 1, 3, 1, 3, 1, 3]], [5, [2, 2, 2, 2, 1, 1, 1, 2, 2, 2]],
  ];
  for (const [level, m] of cases) {
    const sp = new S(data).reset(1, level).speed; const res = [];
    for (let ph = 0; ph < sp; ph += Math.max(1, Math.floor(sp / 9))) {
      const t0 = Date.now(); const r = solve(level, m, ph, 260);
      res.push(`ph${ph}:${r.plan ? 'OK' : 'NO'}(${r.nodes})`);
    }
    console.log(`level ${level} speed ${sp} map ${m.join('')}\n   ${res.join(' ')}`);
  }
}
