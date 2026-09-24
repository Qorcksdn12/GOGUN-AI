/* Web Worker entry: appended after sim.js and trainer.js inside the worker blob. */
let learner = null;
self.onmessage = function (e) {
  const m = e.data;
  try {
    let out = null, transfer = [];
    if (m.type === 'init') { learner = new GogunTrain.Learner(m.cfg, m.data); out = 'ok'; }
    else if (m.type === 'collect') out = learner.collect(m.P, m.levelW, m.opts);
    else if (m.type === 'grad') { out = learner.grad(m.P, m.first, m.mb, m.opts); transfer = [out.G.buffer]; }
    else if (m.type === 'eval') out = learner.evalGames(m.P, m.games, m.seed0, m.maxFrames);
    self.postMessage({ id: m.id, out: out }, transfer);
  } catch (err) { self.postMessage({ id: m.id, error: String(err && err.stack || err) }); }
};
