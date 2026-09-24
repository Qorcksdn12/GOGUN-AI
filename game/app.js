/* gogun // ai — UI glue: game loop, model selection, network inspector, in-browser PPO training */
(function () {
  'use strict';
  const $ = id => document.getElementById(id);
  const GT = window.GogunTrain, GN = window.GogunNet;
  const DATA = JSON.parse($('data-json').textContent), SCENE = JSON.parse($('scene-json').textContent), WEIGHTS = JSON.parse($('weights-json').textContent);
  const WORKER_SRC = $('src-sim').textContent + '\n' + $('src-trainer').textContent + '\n' + $('src-worker').textContent;
  const fmt = n => Math.round(n).toLocaleString('en-US');
  const AUDIO_BANK = JSON.parse($('audio-json').textContent), LADDER = JSON.parse($('ladder-json').textContent);
  const audio = new GogunAudio.AudioEngine(AUDIO_BANK);
  function b64ToF32(b64) { const bin = atob(b64), u8 = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i); return new Float32Array(u8.buffer); }

  // ---- models -----------------------------------------------------------------------------------------------------
  const pre = GT.actorFromJSON(WEIGHTS);
  const models = { pre: GN.Net.fromFull(pre.H, pre.P, 'PRETRAINED', pre.nIn), live: null, imp: null };
  for (const t of LADDER) { const m = new GN.Net(t.H, b64ToF32(t.w), 'TIER ' + t.tier, t.nIn); m.tier = t; models['t' + t.tier] = m; }
  const KEYS = ['pre', 't1', 't2', 't3', 't4', 't5', 't6', 't7', 't8', 't9', 't10', 'live', 'imp'];
  const S = { tab: 'play', mode: 'ai', speed: 1, paused: false, auto: true, startLevel: 0, sel: 'pre', sound: true };
  const active = () => models[S.sel] || models.pre;
  function modelLabel(k) {
    const m = models[k]; if (!m) return '';
    const kind = m.nIn === 84 ? 'coin-aware' : 'survival';
    if (k === 'pre') return 'PRETRAINED  |  ' + m.H + ' hidden  |  ' + kind;
    if (m.tier) return 'TIER ' + m.tier.tier + '  |  ' + kind + '  |  avg ' + fmt(m.tier.stats.total) + ' pts';
    if (k === 'live') return 'BROWSER  |  ' + m.H + ' hidden  |  ' + kind + '  |  iter ' + (m.iter || 0);
    return 'IMPORTED  |  ' + m.H + ' hidden  |  ' + kind;
  }
  function shortLabel(k) { return k === 'pre' ? 'PRETRAINED' : (models[k] && models[k].tier ? 'TIER ' + models[k].tier.tier : (k === 'live' ? 'LIVE' : 'IMPORTED')); }
  function modelKeys() { return KEYS.filter(k => models[k]); }
  function optionLabel(k, record) { const r = record && record[k]; return modelLabel(k) + (r ? '  [W' + r.w + ' L' + r.l + ' D' + r.d + ']' : ''); }
  function syncModelSelects() {
    for (const id of ['model-sel-play', 'model-sel-net']) {
      const el = $(id); el.innerHTML = '';
      for (const k of modelKeys()) { const o = document.createElement('option'); o.value = k; o.textContent = modelLabel(k); el.appendChild(o); }
      el.value = S.sel;
    }
    $('r-model-p').textContent = modelLabel(S.sel);
    const m = active(); $('n-arch').textContent = m.nIn + ' - ' + m.H + ' - ' + m.H + ' - 1  (tanh)  |  ' + fmt(m.params) + ' weights';
    $('net-sub').textContent = m.nIn + '-' + m.H + '-' + m.H + '-1 | ' + fmt(m.params) + ' PARAMS';
    if (battle) battle.fillSelects();
  }

  // ---- sim / view -----------------------------------------------------------------------------------------------
  const sim = new GogunSim(DATA);
  const cv = $('cv'), ctx = cv.getContext('2d'), miniNet = $('mini-net').getContext('2d'), miniTrain = $('mini-train').getContext('2d');
  for (const id of ['mini-net', 'mini-train']) { $(id).width = 320; $(id).height = 240; }
  let view = null, seedCounter = (Date.now() & 0x7fffffff) >>> 0;
  const stats = { games: 0, clears: 0, deaths: 0, bestFrames: 0, bestScore: 0 };
  let endHold = 0, lastLogit = 0, humanQueue = [], humanHeld = false;
  const obs = new Float32Array(84);
  let battle = null, audioOn = false, endingPlayed = false;

  function resizeMain() {
    const st = cv.parentElement, dpr = Math.min(2, window.devicePixelRatio || 1), w = Math.min(1000, Math.max(640, Math.round(st.clientWidth * dpr)));
    if (cv.width !== w) { cv.width = w; cv.height = Math.round(w * 0.75); }
  }
  function resetStats() { stats.games = stats.clears = stats.deaths = stats.bestFrames = stats.bestScore = 0; }
  function newGame() {
    seedCounter = (seedCounter * 1664525 + 1013904223) >>> 0;
    sim.reset(seedCounter, S.startLevel, 0, 0); if (view) view.reset(); endHold = 0; endingPlayed = false; if (audioOn) audio.resync(sim);
  }
  function stepOnce() {
    const net = active();
    sim.features(obs, net.nIn === 84 ? 2 : 1); lastLogit = net.logit(obs);
    let a;
    if (S.mode === 'ai') a = lastLogit > 0 ? 1 : 0; else a = humanQueue.length ? humanQueue.shift() : (humanHeld ? 1 : 0);
    sim.step(a); view.update();
    if (audioOn) { audio.onEvents(sim.events); if (view.ending && !endingPlayed) { endingPlayed = true; audio.ending(); } }
    if ((sim.dead || sim.cleared) && !endHold) {
      endHold = 1; stats.games++; if (sim.cleared) stats.clears++; else stats.deaths++;
      stats.bestFrames = Math.max(stats.bestFrames, sim.frameNo); stats.bestScore = Math.max(stats.bestScore, sim.score);
    } else if (endHold) { endHold++; if (S.auto && endHold > (sim.cleared ? 200 : 75)) newGame(); }
  }

  // ---- main loop --------------------------------------------------------------------------------------------------
  let last = performance.now(), acc = 0, bacc = 0, frameNo = 0;
  function speedNow() { return S.tab === 'battle' && battle ? battle.speed : S.speed; }
  function wantAudio() { return S.sound && audio.unlocked && audio.ready && !S.paused && speedNow() <= 4 && (S.tab === 'play' || (S.tab === 'battle' && battle && battle.running)); }
  function audioSync(force) { const want = wantAudio(); if (force || want !== audioOn) { audioOn = want; if (want) audio.resync(S.tab === 'battle' && battle ? battle.lanes[0].sim : sim); else audio.stopAll(); } }
  function loop(now) {
    const dt = Math.min(250, now - last); last = now; frameNo++;
    if (S.tab === 'battle' && battle) {
      bacc += dt / (1000 / 30) * battle.speed; let n = Math.floor(bacc); bacc -= n; if (n > 120) n = 120; audioSync(false); battle.tick(n); battle.draw();
    } else if (S.tab !== 'info') {
      if (!S.paused) { acc += dt / (1000 / 30) * S.speed; let n = Math.floor(acc); acc -= n; if (n > 240) n = 240; audioSync(false); for (let i = 0; i < n; i++) stepOnce(); }
      resizeMain(); ctx.setTransform(cv.width / 640, 0, 0, cv.height / 480, 0, 0); view.draw(ctx); ctx.setTransform(1, 0, 0, 1, 0, 0);
      if (S.tab === 'net') { miniNet.drawImage(cv, 0, 0, 320, 240); if ((frameNo & 3) === 0) netview.draw(active(), obs); }
      if (S.tab === 'train') { miniTrain.drawImage(cv, 0, 0, 320, 240); }
      if ((frameNo & 3) === 0) updatePanel();
    } else audioSync(false);
    requestAnimationFrame(loop);
  }
  const STATE = { run: 'RUN', jump: 'JUMP', shoot: 'ROPE SHOT', rope: 'ROPE SWING', spin: 'SPIN JUMP' };
  function updatePanel() {
    if (S.tab !== 'play' && S.tab !== 'net') return;
    const lv = Math.min(sim.level, 5) + 1, p = 1 / (1 + Math.exp(-lastLogit)), press = lastLogit >= 0;
    if (S.tab === 'net') { $('n-out-t').textContent = press ? 'PRESS' : 'RELEASE'; $('n-out-p').textContent = 'logit ' + (lastLogit >= 0 ? '+' : '') + lastLogit.toFixed(2) + '  p=' + p.toFixed(2) + '  | ' + (STATE[sim.status] || '') + ' | level ' + lv; return; }
    $('play-sub').textContent = (S.mode === 'ai' ? 'AI PLAYER' : 'HUMAN PLAYER') + ' / GAME ' + (stats.games + 1);
    $('r-state-t').textContent = sim.cleared ? 'CLEARED' : (sim.dead ? 'DEAD' : (STATE[sim.status] || '-'));
    $('r-state-p').textContent = 'level ' + lv + ' / 6 | speed ' + sim.speed + ' px/frame | score ' + fmt(sim.score);
    $('r-state-m').textContent = 'frame ' + fmt(sim.frameNo) + ' | ' + (sim.frameNo / 30).toFixed(1) + ' s';
    $('r-ai-p').textContent = (S.mode === 'ai' ? '' : 'advisory only (human is playing)  ') + (press ? 'PRESS' : 'RELEASE') + '   p=' + p.toFixed(2) + '   logit ' + (lastLogit >= 0 ? '+' : '') + lastLogit.toFixed(2);
    $('bar-ai').style.width = (S.mode === 'ai' ? p * 100 : (sim.pressed ? 100 : 0)) + '%';
    const tot = [50, 100, 150, 200, 250, 300]; let done = 0; for (let i = 0; i < Math.min(sim.level, 6); i++) done += tot[i]; if (sim.level < 6) done += sim.count;
    const pct = Math.min(100, done / 1050 * 100); $('bar-prog').style.width = pct + '%'; $('r-prog-p').textContent = pct.toFixed(1) + ' % of 1,050 blocks';
    $('r-res-p').textContent = stats.clears + ' cleared / ' + stats.deaths + ' dead  (' + stats.games + ' games)';
    $('r-res-m').textContent = 'longest ' + fmt(stats.bestFrames) + ' frames | best score ' + fmt(stats.bestScore);
  }

  // ---- tabs / play controls ---------------------------------------------------------------------------------------
  function setTab(t) {
    S.tab = t; document.querySelectorAll('.tab').forEach(b => b.classList.toggle('on', b.dataset.tab === t)); document.querySelectorAll('.panel').forEach(p => p.classList.toggle('on', p.id === 'p-' + t));
    if (t === 'net') { netview.built = null; netview.wKey = null; netview.setMode(netview.mode); }
    if (t === 'train') drawChart(); if (t === 'battle' && battle) battle.fillSelects(); audioSync(true); updatePanel();
  }
  document.querySelectorAll('.tab').forEach(b => b.onclick = () => setTab(b.dataset.tab));
  function setMode(m) {
    S.mode = m; $('m-ai').classList.toggle('on', m === 'ai'); $('m-me').classList.toggle('on', m === 'me');
    $('r-hint').textContent = m === 'ai' ? '신경망이 매 프레임 마우스를 누를지(1) 뗄지(0) 정합니다.' : '게임을 클릭/터치(스페이스바): 점프, 공중에서 다시 클릭: 밧줄, 스윙 중 누르고 있으면 끌어올림.'; newGame();
  }
  $('m-ai').onclick = () => setMode('ai'); $('m-me').onclick = () => setMode('me');
  $('speedseg').querySelectorAll('button').forEach(b => b.onclick = () => { S.speed = +b.dataset.speed; $('speedseg').querySelectorAll('button').forEach(x => x.classList.toggle('on', x === b)); audioSync(true); });
  $('pause').onclick = () => { S.paused = !S.paused; $('pause').textContent = S.paused ? 'RESUME' : 'PAUSE'; audioSync(true); };
  $('restart').onclick = () => newGame();
  $('auto').onclick = () => { S.auto = !S.auto; $('auto').classList.toggle('on', S.auto); $('auto').textContent = 'AUTO RESTART: ' + (S.auto ? 'ON' : 'OFF'); };
  $('lvl').onchange = e => { S.startLevel = +e.target.value; newGame(); };
  $('snd').onclick = () => { S.sound = !S.sound; $('snd').classList.toggle('on', S.sound); $('snd').textContent = 'SOUND: ' + (S.sound ? 'ON' : 'OFF'); audio.enabled = S.sound; audio.unlock(); audioSync(true); };
  $('vol').oninput = e => audio.setVolume(+e.target.value / 100); audio.setVolume(0.6);
  const unlockAudio = () => { if (!audio.unlocked) { audio.onReady = () => audioSync(true); audio.unlock(); } };   // browsers only allow audio after a user gesture
  ['pointerdown', 'keydown', 'touchend'].forEach(ev => window.addEventListener(ev, unlockAudio, { passive: true }));
  const down = () => { humanHeld = true; humanQueue.push(1); }, up = () => { humanHeld = false; humanQueue.push(0); };
  cv.addEventListener('pointerdown', e => { if (S.mode === 'me') { e.preventDefault(); down(); } });
  window.addEventListener('pointerup', () => { if (S.mode === 'me') up(); });
  window.addEventListener('keydown', e => { if (e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'SELECT') { e.preventDefault(); if (S.mode === 'me' && !e.repeat) down(); } });
  window.addEventListener('keyup', e => { if (e.code === 'Space' && S.mode === 'me') up(); });
  for (const id of ['model-sel-play', 'model-sel-net']) $(id).onchange = e => { S.sel = e.target.value; netview.impFor = null; netview.wKey = null; syncModelSelects(); resetStats(); newGame(); };

  // ---- network view ------------------------------------------------------------------------------------------------
  const netview = new GN.NetView({ graph: $('net-graph'), tip: $('net-tip'), graphWrap: $('net-graph-wrap'), weightsWrap: $('net-weights-wrap'), inputsWrap: $('net-inputs-wrap') });
  $('viewseg').querySelectorAll('button').forEach(b => b.onclick = () => { $('viewseg').querySelectorAll('button').forEach(x => x.classList.toggle('on', x === b)); netview.setMode(b.dataset.view); netview.wKey = null; netview.draw(active(), obs); });
  window.addEventListener('resize', () => { if (S.tab === 'net') netview.draw(active(), obs); if (S.tab === 'train') drawChart(); });

  // ---- training ----------------------------------------------------------------------------------------------------
  const hist = { it: [], len: [], dead: [], evals: [] }; let trainRunning = false, logLines = [], autoEvalBusy = false;
  const hw = Math.max(1, navigator.hardwareConcurrency || 4), wSel = $('s-workers');
  for (let w = 1; w <= Math.min(12, hw); w++) { const o = document.createElement('option'); o.value = w; o.textContent = w; wSel.appendChild(o); }
  wSel.value = Math.max(1, Math.min(6, hw - 1));
  const workersOK = typeof Worker !== 'undefined' && typeof Blob !== 'undefined' && !!(window.URL && URL.createObjectURL);
  const ctl = workersOK ? new GogunTrainCtl.Controller(WORKER_SRC, DATA, { onIter: onTrainIter, onError: onTrainError }) : null;
  function log(line) { logLines.push(line); if (logLines.length > 400) logLines.shift(); const el = $('log'); el.textContent = logLines.join('\n'); el.scrollTop = el.scrollHeight; }
  function setTrainState(running) {
    trainRunning = running; $('dot').classList.toggle('busy', running); $('t-stop').disabled = !running; $('t-scratch').disabled = running; $('t-cont').disabled = running;
    $('train-sub').textContent = 'PPO IN BROWSER | ' + (running ? 'RUNNING' : 'IDLE') + (running && ctl && ctl.pool && ctl.cfg ? ' | ' + ctl.pool.workers.length + ' WORKERS / ' + ctl.cfg.H + ' HIDDEN' : '');
  }
  function onTrainIter(st) {
    hist.it.push(st.it); hist.len.push(st.epLen); hist.dead.push(st.deathPct);
    $('m-iter').textContent = fmt(st.it) + (st.frozen ? ' (actor frozen)' : ''); $('m-steps').textContent = fmt(st.samples); $('m-sps').textContent = fmt(st.sps) + ' /s';
    $('m-len').textContent = fmt(st.epLen) + ' f'; $('m-dead').textContent = st.deathPct.toFixed(0) + ' %'; $('m-ent').textContent = st.ent.toFixed(3);
    $('m-time').textContent = Math.floor(st.elapsed / 60) + ':' + String(Math.floor(st.elapsed % 60)).padStart(2, '0');
    const H = ctl.cfg.H;
    if (!models.live || models.live.H !== H || models.live.nIn !== ctl.nIn) { models.live = new GN.Net(H, Float32Array.from(ctl.emaActor()), 'LIVE', ctl.nIn); models.live.iter = st.it; syncModelSelects(); }
    else { models.live.P.set(ctl.emaActor()); models.live.iter = st.it; if ((st.it % 10) === 0) syncModelSelects(); }
    if (st.it % 10 === 0 || st.it === 1) log('it ' + String(st.it).padStart(4) + ' | ' + (st.samples / 1e6).toFixed(2) + 'M frames | ' + fmt(st.sps) + '/s | ep ' + fmt(st.epLen) + ' f | dead ' + st.deathPct.toFixed(0) + '% | ent ' + st.ent.toFixed(2) + ' | vloss ' + st.vloss.toFixed(4) + ' | lr ' + st.lr.toExponential(1));
    if (st.it % 25 === 0 && !autoEvalBusy && models.live) {   // cheap periodic evaluation (10 full games) for the learning curve
      autoEvalBusy = true; const net = models.live, it0 = st.it;
      ctl.evaluate(net.H, Float32Array.from(net.P), 10, 2, net.nIn).then(r => {
        const pct = 100 * r.cleared / r.games; hist.evals.push({ it: it0, pct: pct }); $('m-eval').textContent = r.cleared + ' / ' + r.games + ' (auto, iter ' + it0 + ')';
        log('auto eval @' + it0 + ': ' + r.cleared + '/' + r.games + ' full games cleared' + (net.nIn === 84 ? ' | coin ' + fmt(r.meanCoin) + ' | dist ' + fmt(r.meanDist) + ' | total ' + fmt(r.meanCoin + r.meanDist) : '')); if (S.tab === 'train') drawChart();
      }).catch(() => { }).then(() => { autoEvalBusy = false; });
    }
    if (S.tab === 'train' && (st.it % 2) === 0) drawChart();
  }
  function onTrainError(err) { setTrainState(false); log('ERROR: ' + (err && err.message || err)); }
  async function startTraining(cont) {
    try { await startTrainingInner(cont); } catch (e) { onTrainError(e); }
  }
  async function startTrainingInner(cont) {
    if (!ctl) { log('Web Workers are not available in this browser.'); return; }
    let H = cont ? pre.H : +$('s-hidden').value;
    const obsVer = +$('s-obs').value, nIn = obsVer === 2 ? 84 : 64, coinW = obsVer === 2 ? +$('s-coin').value : 0;
    const cfg = { H: H, workers: +wSel.value, envsTotal: +$('s-envs').value, lr: +$('s-lr').value, ent: +$('s-ent').value, pHard: +$('s-hard').value, ema: 0.995, obsVer: obsVer, coinW: coinW };
    if (cont) {
      const init = GT.initParams(H, 4242, nIn), size = GT.layoutOf(H, nIn).size;
      init.set(nIn === pre.nIn ? models.pre.P.subarray(0, size) : GT.expandActor(models.pre.P, H, pre.nIn, nIn), 0);
      cfg.initFull = init; cfg.freezeIters = 20; cfg.lr = Math.min(cfg.lr, 5e-5); cfg.ent = Math.min(cfg.ent, 0.003); $('s-hidden').value = String(H);
    }
    hist.it.length = hist.len.length = hist.dead.length = 0; hist.evals.length = 0; models.live = null; logLines = [];
    log((cont ? 'continue from pretrained (actor frozen for 20 iterations while the critic warms up)' : 'start from scratch') + ' | inputs ' + nIn + (coinW ? ' | coin reward ' + coinW + ' / point' : '') + ' | hidden ' + H + ' | workers ' + cfg.workers + ' | envs ' + cfg.envsTotal + ' | lr ' + cfg.lr + ' | ent ' + cfg.ent);
    setTrainState(true);
    try { await ctl.start(cfg); setTrainState(true); } catch (e) { onTrainError(e); return; }
    S.sel = 'live'; models.live = new GN.Net(H, Float32Array.from(ctl.emaActor()), 'LIVE', nIn); models.live.iter = 0; syncModelSelects(); resetStats(); newGame();
  }
  $('t-scratch').onclick = () => startTraining(false); $('t-cont').onclick = () => startTraining(true);
  $('t-stop').onclick = async () => { if (!ctl) return; $('t-stop').disabled = true; await ctl.stop(); setTrainState(false); log('stopped at iteration ' + ctl.iter + '. the live model stays selectable.'); };
  $('t-eval').onclick = async () => {
    if (!ctl) return; const net = active(), btn = $('t-eval'); btn.disabled = true; $('m-eval').textContent = 'running...';
    try {
      const r = await ctl.evaluate(net.H, net.P, 30, Math.min(4, Math.max(1, +wSel.value)), net.nIn);
      const pct = 100 * r.cleared / r.games; $('m-eval').textContent = r.cleared + ' / ' + r.games + ' (' + pct.toFixed(0) + '%)';
      log('eval (' + modelLabel(S.sel) + '): ' + r.cleared + '/' + r.games + ' full games cleared, mean ' + fmt(r.meanFrames) + ' frames | dist ' + fmt(r.meanDist) + ' + coin ' + fmt(r.meanCoin) + ' = ' + fmt(r.meanDist + r.meanCoin)); if (trainRunning || ctl.iter) hist.evals.push({ it: ctl.iter, pct: pct }); drawChart();
    } catch (e) { $('m-eval').textContent = 'error'; log('ERROR: ' + (e && e.message || e)); }
    btn.disabled = false;
  };
  $('t-export').onclick = () => {
    const m = active(), json = GT.actorToJSON(m.P, m.H, { source: 'gogun browser export', model: S.sel, iterations: m.iter || null }, m.nIn);
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(json)], { type: 'application/json' })); a.download = 'gogun_actor_h' + m.H + (m.nIn === 84 ? '_coin' : '') + '.json'; document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
  };
  // ---- model import: shared by the TRAIN/PLAY buttons and by dragging a .json file onto the page --------------------
  function importModelFile(file) {
    if (!file) return;
    const rd = new FileReader();
    rd.onload = () => {
      try {
        const r = GT.actorFromJSON(JSON.parse(rd.result));
        models.imp = GN.Net.fromFull(r.H, r.P, 'IMPORTED', r.nIn); S.sel = 'imp'; syncModelSelects(); resetStats(); newGame();
        log('imported ' + file.name + ' (inputs ' + r.nIn + ', hidden ' + r.H + ')');
      } catch (err) { log('IMPORT FAILED (' + file.name + '): ' + err.message); }
    };
    rd.onerror = () => log('IMPORT FAILED: could not read ' + file.name);
    rd.readAsText(file);
  }
  $('t-import').onclick = () => $('t-file').click();
  $('play-import').onclick = () => $('t-file').click();
  $('t-file').onchange = e => { importModelFile(e.target.files[0]); e.target.value = ''; };
  if (!workersOK) { for (const id of ['t-scratch', 't-cont', 't-eval']) $(id).disabled = true; $('train-sub').textContent = 'PPO IN BROWSER | WEB WORKERS UNAVAILABLE'; }

  // ---- drag & drop a model json anywhere on the page ---------------------------------------------------------------
  const dz = $('dropzone'); let dragDepth = 0;
  const hasFiles = e => !!(e.dataTransfer && Array.from(e.dataTransfer.types || []).indexOf('Files') !== -1);
  window.addEventListener('dragenter', e => { if (!hasFiles(e)) return; e.preventDefault(); dragDepth++; dz.classList.add('on'); });
  window.addEventListener('dragover', e => { if (hasFiles(e)) e.preventDefault(); });
  window.addEventListener('dragleave', e => { if (!hasFiles(e)) return; dragDepth = Math.max(0, dragDepth - 1); if (!dragDepth) dz.classList.remove('on'); });
  window.addEventListener('drop', e => {
    if (!hasFiles(e)) return; e.preventDefault(); dragDepth = 0; dz.classList.remove('on');
    const files = Array.from(e.dataTransfer.files || []); const f = files.find(x => /\.json$/i.test(x.name)) || files[0];
    if (f) importModelFile(f); else log('IMPORT FAILED: no file found in drop');
  });
  window.addEventListener('drop', e => e.preventDefault());   // belt-and-suspenders: never let a stray drop navigate the page away

  function drawChart() {
    const c = $('chart'); if (!c.clientWidth) return; const dpr = Math.min(2, window.devicePixelRatio || 1), w = c.clientWidth, h = c.clientHeight;
    if (c.width !== Math.round(w * dpr)) { c.width = Math.round(w * dpr); c.height = Math.round(h * dpr); }
    const g = c.getContext('2d'); g.setTransform(dpr, 0, 0, dpr, 0, 0); g.clearRect(0, 0, w, h);
    const L = 34, R = 34, T = 18, B = 18, pw = w - L - R, ph = h - T - B, n = hist.it.length, xmax = Math.max(20, n ? hist.it[n - 1] : 20);
    g.font = '500 10px ui-monospace, Menlo, Consolas, monospace'; g.fillStyle = '#8b8b85'; g.strokeStyle = '#dcdcd4'; g.lineWidth = 1;
    for (let i = 0; i <= 4; i++) { const y = T + ph * i / 4; g.beginPath(); g.moveTo(L, y); g.lineTo(L + pw, y); g.stroke(); g.textAlign = 'right'; g.fillText(String(1500 - 375 * i), L - 4, y + 3); g.textAlign = 'left'; g.fillText(String(100 - 25 * i), L + pw + 4, y + 3); }
    g.strokeStyle = '#0b0b0b'; g.lineWidth = 2; g.strokeRect(L, T, pw, ph);
    g.textAlign = 'left'; g.fillStyle = '#0b0b0b'; g.fillText('EPISODE FRAMES', L, 11); g.fillStyle = '#c8341c'; g.fillText('DEATHS %', L + 110, 11); g.fillStyle = '#0b0b0b'; g.fillText('EVAL CLEAR %', L + 180, 11); g.textAlign = 'right'; g.fillStyle = '#8b8b85'; g.fillText('iter ' + xmax, L + pw, h - 4);
    const X = i => L + pw * i / xmax;
    const line = (arr, ymax, color, lw) => { if (!arr.length) return; g.strokeStyle = color; g.lineWidth = lw; g.beginPath(); for (let i = 0; i < arr.length; i++) { const x = X(hist.it[i]), y = T + ph * (1 - Math.min(1, arr[i] / ymax)); if (i) g.lineTo(x, y); else g.moveTo(x, y); } g.stroke(); };
    line(hist.dead, 100, '#c8341c', 1.5); line(hist.len, 1500, '#0b0b0b', 2);
    for (const e of hist.evals) { const x = X(e.it), y = T + ph * (1 - e.pct / 100); g.fillStyle = '#0b0b0b'; g.fillRect(x - 4, y - 4, 8, 8); g.fillStyle = '#f3f3ee'; g.fillRect(x - 2, y - 2, 4, 4); }
  }

  // ---- clock ------------------------------------------------------------------------------------------------------
  function tick() { $('clock').textContent = new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true }); }
  tick(); setInterval(tick, 1000);

  window.__gogun = { sim, stats, S, models, hist, audio, get battle() { return battle; },  get view() { return view; }, get ctl() { return ctl; }, netview, newGame, stepOnce, setMode, setSpeed: v => { S.speed = v; }, draw: () => { resizeMain(); ctx.setTransform(cv.width / 640, 0, 0, cv.height / 480, 0, 0); view.draw(ctx); ctx.setTransform(1, 0, 0, 1, 0, 0); }, setPaused: v => { S.paused = v; }, setStartLevel: l => { S.startLevel = l; }, setTab, startTraining, syncModelSelects };
  syncModelSelects(); $('r-hint').textContent = '신경망이 매 프레임 마우스를 누를지(1) 뗄지(0) 정합니다.';
  GogunRender.loadImages(SCENE).then(images => {
    view = new GogunRender.GameView(SCENE, images, sim);
    battle = GogunBattle.create({ $, fmt, DATA, SCENE, images, getNet: k => models[k] || models.pre, modelKeys, optionLabel, labelOf: shortLabel, tab: () => S.tab,
      audioEvents: L => { if (audioOn && S.tab === 'battle') { audio.onEvents(L.sim.events); if (L.view.ending && !L.endingSeen) { L.endingSeen = true; audio.ending(); } } },
      audioReset: L => { if (audioOn || (S.tab === 'battle' && audio.unlocked)) audioSync(true); } });
    newGame(); view.update(); $('loading').style.display = 'none';
    requestAnimationFrame(t => { last = t; loop(t); }); window.__gogunReady = true;
  });
})();
