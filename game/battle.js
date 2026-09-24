/* BATTLE tab: two lanes play the SAME seed (identical maps and coin layouts) at the same time; the score is distance + coins.
 *   distance points = floor(scrolled pixels / 3),   coin points = the game's own score (silver 5, gold 50 - 5 x level, bonus 100 + 20 x level). */
(function (root, factory) { root.GogunBattle = factory(); })(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  const DIST_DIV = 3;
  function create(api) {
    const $ = api.$, fmt = api.fmt, DATA = api.DATA, SCENE = api.SCENE;
    const st = { state: 'ready', limit: 1800, speed: 1, seed: 1, frames: 0, humanQueue: [], humanHeld: false, seedCounter: (Date.now() & 0x7fffffff) >>> 0, record: {}, history: [] };
    try { st.record = JSON.parse(localStorage.getItem('gogun_battle_record') || '{}') || {}; } catch (e) { st.record = {}; }
    const lanes = [0, 1].map(i => {
      const cv = $('b-cv' + (i + 1)), sim = new GogunSim(DATA), view = new GogunRender.GameView(SCENE, api.images, sim);
      return { i, cv, ctx: cv.getContext('2d'), sim, view, net: null, key: '', human: false, obs: new Float32Array(84), logit: 0, ended: false, timeUp: false, endingSeen: false };
    });
    const dist = L => Math.floor(L.sim.way / DIST_DIV), coin = L => L.sim.score, total = L => dist(L) + coin(L);
    function label(key) { return key === 'human' ? 'YOU' : api.labelOf(key); }
    function fillSelects() {
      const opts = k => '<option value="' + k + '">' + api.optionLabel(k, st.record) + '</option>';
      const keys = api.modelKeys();
      const cur1 = $('b-p1').value || 'human', cur2 = $('b-p2').value || 't5';
      $('b-p1').innerHTML = '<option value="human">HUMAN (you)</option>' + keys.map(opts).join('');
      $('b-p2').innerHTML = keys.map(opts).join('');
      $('b-p1').value = [...$('b-p1').options].some(o => o.value === cur1) ? cur1 : 'human';
      $('b-p2').value = [...$('b-p2').options].some(o => o.value === cur2) ? cur2 : 't5';
    }
    function newMatch() {
      st.seedCounter = (st.seedCounter * 1664525 + 1013904223) >>> 0; st.seed = st.seedCounter || 1; st.frames = 0; st.humanQueue.length = 0; st.humanHeld = false;
      const keys = [$('b-p1').value, $('b-p2').value]; st.limit = +$('b-len').value;
      lanes.forEach((L, i) => {
        L.key = keys[i]; L.human = keys[i] === 'human'; L.net = L.human ? api.getNet('pre') : api.getNet(keys[i]);   // a human lane still shows what the pretrained net would do (advisory)
        L.sim.reset(st.seed, 0, 0, 0); L.view.reset(); L.ended = false; L.timeUp = false; L.endingSeen = false; L.logit = 0;
        $('b-n' + (i + 1)).textContent = (L.human ? 'YOU' : label(keys[i]));
      });
      $('b-banner').textContent = 'ready. press START.'; $('b-banner').className = 'banner';
      api.audioReset(lanes[0]); st.state = 'ready'; $('b-start').textContent = 'START'; updateHud();
    }
    function start() { if (st.state === 'done') newMatch(); st.state = 'running'; $('b-start').textContent = 'RESTART'; $('b-banner').textContent = 'running ...'; api.audioReset(lanes[0]); }
    function finish() {
      st.state = 'done'; const a = total(lanes[0]), b = total(lanes[1]);
      let msg, cls; const n1 = $('b-n1').textContent, n2 = $('b-n2').textContent;
      if (a === b) { msg = 'DRAW  ' + fmt(a) + ' : ' + fmt(b); cls = 'banner'; } else if (a > b) { msg = n1 + ' WINS  ' + fmt(a) + ' : ' + fmt(b); cls = 'banner win'; } else { msg = n2 + ' WINS  ' + fmt(b) + ' : ' + fmt(a); cls = 'banner lose'; }
      $('b-banner').textContent = msg; $('b-banner').className = cls; $('b-start').textContent = 'REMATCH';
      const h = st.history; h.unshift({ p1: n1, p2: n2, a, b, t: st.frames }); if (h.length > 8) h.pop();
      $('b-log').textContent = h.map(x => (x.p1 + ' ' + fmt(x.a)).padEnd(22) + ' vs  ' + (x.p2 + ' ' + fmt(x.b)).padEnd(22) + (x.a === x.b ? 'draw' : (x.a > x.b ? 'left' : 'right'))).join('\n');
      if (lanes[0].human && !lanes[1].human) {   // record of the human against each tier
        const k = lanes[1].key, r = st.record[k] || (st.record[k] = { w: 0, l: 0, d: 0 }); if (a > b) r.w++; else if (a < b) r.l++; else r.d++;
        try { localStorage.setItem('gogun_battle_record', JSON.stringify(st.record)); } catch (e) { } fillSelects();
      }
    }
    function stepLane(L) {
      if (L.ended) return;
      let a;
      if (L.human) a = st.humanQueue.length ? st.humanQueue.shift() : (st.humanHeld ? 1 : 0);
      else { L.sim.features(L.obs, L.net.nIn === 84 ? 2 : 1); L.logit = L.net.logit(L.obs); a = L.logit > 0 ? 1 : 0; }
      L.sim.step(a); L.view.update();
      if (L.i === 0) api.audioEvents(L);
      if (L.sim.dead || L.sim.cleared) L.ended = true;
      else if (st.limit && L.sim.frameNo >= st.limit) { L.ended = true; L.timeUp = true; }
    }
    function tick(n) {
      if (st.state !== 'running') return;
      for (let s = 0; s < n && st.state === 'running'; s++) {
        st.frames++; lanes.forEach(stepLane);
        for (const L of lanes) if (L.ended && (L.sim.dead || L.sim.cleared)) L.view.update();   // let the game-over / ending animation play
        if (lanes[0].ended && lanes[1].ended) finish();
      }
    }
    function updateHud() {
      lanes.forEach((L, i) => {
        const k = i + 1, s = L.sim;
        $('b-d' + k).textContent = fmt(dist(L)); $('b-c' + k).textContent = fmt(coin(L)); $('b-t' + k).textContent = fmt(total(L));
        $('b-s' + k).textContent = s.cleared ? 'CLEARED' : (s.dead ? 'DEAD' : (L.timeUp ? 'TIME UP' : (st.state === 'ready' ? 'READY' : 'RUNNING'))) + '  |  level ' + (Math.min(s.level, 5) + 1) + '  |  frame ' + fmt(s.frameNo);
      });
      const el = st.frames / 30, lim = st.limit / 30; $('b-time').textContent = el.toFixed(1) + ' s' + (st.limit ? ' / ' + lim.toFixed(0) + ' s' : ' (full run)');
      $('b-bar').style.width = (st.limit ? Math.min(100, 100 * st.frames / st.limit) : Math.min(100, 100 * Math.max(...lanes.map(L => (L.sim.way / 160000)))) ) + '%';
    }
    function resize(L) {
      const dpr = Math.min(2, window.devicePixelRatio || 1), w = Math.min(1000, Math.max(480, Math.round(L.cv.parentElement.clientWidth * dpr)));
      if (L.cv.width !== w) { L.cv.width = w; L.cv.height = Math.round(w * 0.75); }
    }
    function draw() {
      for (const L of lanes) { resize(L); L.ctx.setTransform(L.cv.width / 640, 0, 0, L.cv.height / 480, 0, 0); L.view.draw(L.ctx); L.ctx.setTransform(1, 0, 0, 1, 0, 0); }
      updateHud();
    }
    // ---- wiring -------------------------------------------------------------------------------------------------
    $('b-start').onclick = () => { if (st.state === 'running') newMatch(); else start(); };
    $('b-p1').onchange = newMatch; $('b-p2').onchange = newMatch; $('b-len').onchange = newMatch;
    $('b-speed').querySelectorAll('button').forEach(b => b.onclick = () => { st.speed = +b.dataset.bspeed; $('b-speed').querySelectorAll('button').forEach(x => x.classList.toggle('on', x === b)); });
    const down = () => { st.humanHeld = true; st.humanQueue.push(1); }, up = () => { st.humanHeld = false; st.humanQueue.push(0); };
    lanes[0].cv.addEventListener('pointerdown', e => { if (lanes[0].human && st.state === 'running') { e.preventDefault(); down(); } });
    window.addEventListener('pointerup', () => { if (lanes[0].human && st.state === 'running') up(); });
    window.addEventListener('keydown', e => { if (api.tab() === 'battle' && e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'SELECT') { e.preventDefault(); if (lanes[0].human && st.state === 'running' && !e.repeat) down(); } });
    window.addEventListener('keyup', e => { if (api.tab() === 'battle' && e.code === 'Space' && lanes[0].human && st.state === 'running') up(); });
    fillSelects(); newMatch();
    return { st, lanes, tick, draw, newMatch, start, fillSelects, total, dist, coin, get speed() { return st.speed; }, get running() { return st.state === 'running'; } };
  }
  return { create, DIST_DIV };
});
