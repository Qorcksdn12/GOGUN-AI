// evaluates a weights JSON with the exact float32 forward pass used by the HTML page (GogunTrain.fwd)
const T = require('./trainer.js'); const data = require('./gogun_data.json'); const fs = require('fs');
const pre = T.actorFromJSON(JSON.parse(fs.readFileSync(process.argv[2]))); const games = +process.argv[3] || 100, seed0 = +process.argv[4] || 91000;
const L = new T.Learner({ H: pre.H, envs: 1, T: 1, seed: 3 }, data); const P = new Float32Array(2 * T.layoutOf(pre.H).size); P.set(pre.P.subarray(0, T.layoutOf(pre.H).size), 0);
const t0 = Date.now(); const res = L.evalGames(P, games, seed0, 9500), c = res.filter(r => r[0]).length;
console.log(`float32 page path: ${c}/${games} full games cleared (${(100 * c / games).toFixed(1)}%), mean frames ${(res.reduce((a, r) => a + r[1], 0) / games).toFixed(0)}  [${((Date.now() - t0) / 1000).toFixed(0)}s]`);
console.log('failures (frames, level):', JSON.stringify(res.filter(r => !r[0]).map(r => [r[1], r[2]])));
