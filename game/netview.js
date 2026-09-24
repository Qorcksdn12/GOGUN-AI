/* Neural-network inspector: Net (flat-array MLP with captured activations) and NetView (graph / weights / inputs). */
(function (root, factory) { root.GogunNet = factory(root.GogunTrain); })(typeof self !== 'undefined' ? self : this, function (GT) {
  'use strict';
  const INK = [11, 11, 11], PAPER = [243, 243, 238], RED = [200, 52, 28];
  // ---- names of the 64 input features (order of GogunSim.features) -------------------------------------------------
  const NAMES = ['height', 'vy', 'st:run', 'st:jump', 'st:shoot', 'st:rope', 'st:spin', 'click', 'pressed', 'rope flying', 'rope hooked', 'tip dx', 'tip dy', 'body angle', 'speed', 'level',
    'ground left', 'next ground', 'gap length'];
  for (let a = 1; a <= 2; a++) NAMES.push('anchor' + a + ' dx', 'anchor' + a + ' frames', 'anchor' + a + ' seen');
  for (let b = 1; b <= 6; b++) NAMES.push('blk' + b + ' dx', 'blk' + b + ' gap', 'blk' + b + ' ground', 'blk' + b + ' anchor');
  NAMES.push('catch @+0f', 'catch @+1f', 'catch @+2f', 'catch @+3f', 'catch delay', 'flight lands', 'flight time', 'jump lands', 'jump time', 'spin lands', 'spin time', 'catch height', 'first catch', 'last catch', 'release time');
  for (let c = 1; c <= 6; c++) NAMES.push('coin' + c + ' dx', 'coin' + c + ' dy', 'coin' + c + ' gold');
  NAMES.push('coin value hold', 'coin value jump');   // observation v2 only (inputs 64..83)
  const GROUPS = [[0, 'STATE'], [9, 'ROPE'], [14, 'WORLD'], [16, 'GROUND'], [19, 'ANCHORS'], [25, 'BLOCKS'], [49, 'LOOKAHEAD'], [64, 'COINS']];

  class Net {
    constructor(H, actorP, label, nIn) {
      nIn = nIn || 64; this.H = H; this.nIn = nIn; this.o = GT.layoutOf(H, nIn); this.P = actorP; this.label = label || '';
      this.h0 = new Float32Array(H); this.h1 = new Float32Array(H); this.x = new Float32Array(nIn); this.z = 0;
    }
    logit(x) { this.x.set(x.length > this.nIn ? x.subarray(0, this.nIn) : x); this.z = GT.fwd(this.P, 0, this.o, this.H, this.x, 0, this.h0, this.h1, 0); return this.z; }
    get params() { return this.o.size; }
    static fromFull(H, P, label, nIn) { return new Net(H, P.slice(0, GT.layoutOf(H, nIn).size), label, nIn); }
  }
  const lerp = (a, b, t) => Math.round(a + (b - a) * t);
  function colorOf(v) {   // activation -> css color (positive: ink, negative: red)
    const t = Math.max(0, Math.min(1, Math.abs(v))), c = v >= 0 ? INK : RED;
    return 'rgb(' + lerp(PAPER[0], c[0], t) + ',' + lerp(PAPER[1], c[1], t) + ',' + lerp(PAPER[2], c[2], t) + ')';
  }

  class NetView {
    constructor(refs) { this.r = refs; this.mode = 'graph'; this.tipCells = []; this.lastNet = null; this.lastTick = 0; this._bindTip(); }
    setMode(m) { this.mode = m; this.r.graphWrap.style.display = m === 'graph' ? '' : 'none'; this.r.weightsWrap.style.display = m === 'weights' ? '' : 'none'; this.r.inputsWrap.style.display = m === 'inputs' ? '' : 'none'; this.built = null; }
    _size(cv, h) { const w = cv.parentElement.clientWidth || 300, dpr = Math.min(2, window.devicePixelRatio || 1); cv.style.height = h + 'px'; cv.style.width = w + 'px'; cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); return { w, h, dpr }; }
    _bindTip() {
      const cv = this.r.graph, tip = this.r.tip;
      const move = e => {
        const b = cv.getBoundingClientRect(), x = (e.touches ? e.touches[0].clientX : e.clientX) - b.left, y = (e.touches ? e.touches[0].clientY : e.clientY) - b.top;
        let best = null, bd = 1e9;
        for (const c of this.tipCells) { const d = Math.hypot(c.x - x, c.y - y); if (d < bd && d < c.s * 1.2) { bd = d; best = c; } }
        tip.textContent = best ? best.text : '칸에 마우스를 올리거나 터치하면 값이 보입니다';
      };
      cv.addEventListener('pointermove', move); cv.addEventListener('pointerdown', move);
    }
    draw(net, obs) {
      if (!net) return; this.lastNet = net;
      if (this.mode === 'graph') this.drawGraph(net, obs); else if (this.mode === 'inputs') this.updateInputs(net, obs);
      else if (this.mode === 'weights' && this.wKey !== net) this.drawWeights(net);
    }
    // ------------------------------------------------------------------ graph
    drawGraph(net, obs) {
      const cv = this.r.graph, W0 = cv.parentElement.clientWidth || 300; if (!W0) return;
      const horizontal = W0 >= 620, H = net.H, o = net.o, P = net.P;
      const hc = horizontal ? 8 : 16, hr = Math.ceil(H / hc);
      const nIn = net.nIn, dims = [{ n: nIn, c: 8, r: Math.ceil(nIn / 8) }, { n: H, c: hc, r: hr }, { n: H, c: hc, r: hr }, { n: 1, c: 1, r: 1 }];
      const pad = 16, titleH = 18, blocks = []; let cell, hCanvas;
      if (horizontal) {
        const maxRows = Math.max(dims[0].r, hr), gapMin = 46, cellW = (W0 - 2 * pad - 3 * gapMin) / (8 + hc + hc + 3), targetH = Math.min(460, Math.max(300, W0 * 0.5));
        cell = Math.min(cellW, (targetH - 2 * pad - titleH - 10) / maxRows, 26); hCanvas = Math.round(maxRows * cell + 2 * pad + titleH + 14);
        const totalW = (8 + hc + hc + 3) * cell, gap = (W0 - 2 * pad - totalW) / 3, areaTop = pad + titleH, areaH = maxRows * cell; let x = pad;
        for (let i = 0; i < 4; i++) {
          const d = dims[i], bw = i === 3 ? 3 * cell : d.c * cell, bh = i === 3 ? 3 * cell : d.r * cell;
          blocks.push({ x: x, y: areaTop + (areaH - bh) / 2, w: bw, h: bh, d: d, cell: i === 3 ? 3 * cell : cell }); x += bw + gap;
        }
      } else {
        cell = Math.min(17, (W0 - 2 * pad) / 16); const gapY = 40; let y = pad;
        for (let i = 0; i < 4; i++) {
          const d = dims[i], bw = i === 3 ? 3 * cell : d.c * cell, bh = i === 3 ? 3 * cell : d.r * cell;
          blocks.push({ x: (W0 - bw) / 2, y: y + titleH, w: bw, h: bh, d: d, cell: i === 3 ? 3 * cell : cell }); y += titleH + bh + gapY;
        }
        hCanvas = Math.round(y - gapY + pad);
      }
      const { w, h, dpr } = this._size(cv, hCanvas); const ctx = cv.getContext('2d'); ctx.setTransform(dpr, 0, 0, dpr, 0, 0); ctx.clearRect(0, 0, w, h);
      const centers = blocks.map(b => { const arr = []; const d = b.d; for (let i = 0; i < d.n; i++) { const cx = d.n === 1 ? b.x + b.w / 2 : b.x + (i % d.c) * b.cell + b.cell / 2, cy = d.n === 1 ? b.y + b.h / 2 : b.y + Math.floor(i / d.c) * b.cell + b.cell / 2; arr.push([cx, cy]); } return arr; });
      // activations
      const xin = new Float32Array(nIn); for (let i = 0; i < nIn; i++) xin[i] = Math.max(-1, Math.min(1, obs[i]));
      const a1 = net.h0, a2 = net.h1, out = net.z;
      // edges (strongest contributions only)
      const drawEdges = (from, to, act, Wbase, nIn, nOut, K, transposeOut) => {
        const cs = new Float32Array(nIn * nOut); let mx = 1e-9;
        for (let k = 0; k < nIn; k++) { const a = act[k]; if (a === 0) continue; for (let j = 0; j < nOut; j++) { const c = a * P[Wbase + (transposeOut ? k : k * nOut + j)]; cs[k * nOut + j] = c; const m = Math.abs(c); if (m > mx) mx = m; } }
        const mags = Float32Array.from(cs, Math.abs).sort(); const thr = mags[Math.max(0, mags.length - K)];
        ctx.lineWidth = 1;
        for (let idx = 0; idx < cs.length; idx++) {
          const c = cs[idx]; if (Math.abs(c) < thr || c === 0) continue; const k = (idx / nOut) | 0, j = idx % nOut, t = Math.abs(c) / mx;
          ctx.strokeStyle = c > 0 ? 'rgba(11,11,11,' + (0.12 + 0.6 * t).toFixed(3) + ')' : 'rgba(200,52,28,' + (0.12 + 0.6 * t).toFixed(3) + ')';
          ctx.beginPath(); ctx.moveTo(from[k][0], from[k][1]); ctx.lineTo(to[j][0], to[j][1]); ctx.stroke();
        }
      };
      drawEdges(centers[0], centers[1], xin, o.W0, nIn, H, 90, false);
      drawEdges(centers[1], centers[2], a1, o.W1, H, H, 120, false);
      { const cs = new Float32Array(H); let mx = 1e-9; for (let j = 0; j < H; j++) { cs[j] = a2[j] * P[o.W2 + j]; mx = Math.max(mx, Math.abs(cs[j])); }
        const mags = Float32Array.from(cs, Math.abs).sort(), thr = mags[Math.max(0, H - 40)];
        for (let j = 0; j < H; j++) { if (Math.abs(cs[j]) < thr) continue; const t = Math.abs(cs[j]) / mx; ctx.strokeStyle = cs[j] > 0 ? 'rgba(11,11,11,' + (0.15 + 0.6 * t).toFixed(3) + ')' : 'rgba(200,52,28,' + (0.15 + 0.6 * t).toFixed(3) + ')'; ctx.beginPath(); ctx.moveTo(centers[2][j][0], centers[2][j][1]); ctx.lineTo(centers[3][0][0], centers[3][0][1]); ctx.stroke(); } }
      // cells
      this.tipCells = []; const acts = [xin, a1, a2, [Math.tanh(out / 3)]], labels = ['INPUT  ' + nIn, 'HIDDEN 1  ' + H, 'HIDDEN 2  ' + H, 'OUTPUT  1'];
      ctx.font = '600 10px ui-monospace, Menlo, Consolas, monospace'; ctx.textBaseline = 'alphabetic';
      for (let bi = 0; bi < 4; bi++) {
        const b = blocks[bi], d = b.d, A = acts[bi];
        for (let i = 0; i < d.n; i++) {
          const [cx, cy] = centers[bi][i], s = b.cell; ctx.fillStyle = colorOf(A[i]); const g = bi === 3 ? 0 : 1;
          ctx.fillRect(cx - s / 2 + g / 2, cy - s / 2 + g / 2, s - g, s - g);
          if (bi < 3) this.tipCells.push({ x: cx, y: cy, s: s, text: bi === 0 ? 'input ' + i + '  ' + NAMES[i] + ' = ' + obs[i].toFixed(3) : 'hidden' + bi + '[' + i + '] = ' + A[i].toFixed(3) });
        }
        ctx.strokeStyle = '#0b0b0b'; ctx.lineWidth = 1.5; ctx.strokeRect(b.x, b.y, b.w, b.h);
        { const tw = ctx.measureText(labels[bi]).width; ctx.fillStyle = '#f3f3ee'; ctx.fillRect(b.x - 2, b.y - 16, tw + 6, 13); ctx.fillStyle = '#5b5b56'; ctx.fillText(labels[bi], b.x + 1, b.y - 6); }
      }
      const ob = blocks[3]; ctx.fillStyle = out >= 0 ? '#f3f3ee' : '#f3f3ee'; ctx.textAlign = 'center';
      ctx.font = '700 11px ui-monospace, Menlo, Consolas, monospace'; ctx.fillStyle = Math.abs(Math.tanh(out / 3)) > 0.5 ? '#f3f3ee' : '#0b0b0b';
      ctx.fillText(out >= 0 ? 'PRESS' : 'RELEASE', ob.x + ob.w / 2, ob.y + ob.h / 2 - 2); ctx.font = '500 10px ui-monospace, Menlo, Consolas, monospace'; ctx.fillText((out >= 0 ? '+' : '') + out.toFixed(2), ob.x + ob.w / 2, ob.y + ob.h / 2 + 11); ctx.textAlign = 'left';
      this.tipCells.push({ x: ob.x + ob.w / 2, y: ob.y + ob.h / 2, s: ob.cell, text: 'output logit = ' + out.toFixed(3) + '  (press when > 0)' });
    }
    // ------------------------------------------------------------------ weights
    drawWeights(net) {
      this.wKey = net; const H = net.H, o = net.o, P = net.P, host = this.r.weightsWrap; host.innerHTML = '';
      const mk = (title, rows, cols, get) => {
        const box = document.createElement('div'); box.className = 'wblock' + (rows === cols ? ' sq' : '');
        const t = document.createElement('div'); t.className = 'wtitle'; t.textContent = title; box.appendChild(t);
        const cv = document.createElement('canvas'); cv.width = cols; cv.height = rows; cv.className = 'wcanvas'; cv.style.aspectRatio = cols + ' / ' + Math.max(rows, 1);
        if (rows === 1) cv.style.height = '14px'; box.appendChild(cv);
        let mx = 1e-9; for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) mx = Math.max(mx, Math.abs(get(r, c)));
        const ctx = cv.getContext('2d'), img = ctx.createImageData(cols, rows);
        for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) { const v = get(r, c) / mx, t2 = Math.min(1, Math.abs(v)), col = v >= 0 ? INK : RED, k = (r * cols + c) * 4; img.data[k] = lerp(PAPER[0], col[0], t2); img.data[k + 1] = lerp(PAPER[1], col[1], t2); img.data[k + 2] = lerp(PAPER[2], col[2], t2); img.data[k + 3] = 255; }
        ctx.putImageData(img, 0, 0);
        const s = document.createElement('div'); s.className = 'wnote'; s.textContent = 'max |w| = ' + mx.toFixed(3); box.appendChild(s); host.appendChild(box);
      };
      mk('W0   input(' + net.nIn + ') x hidden1(' + H + ')', net.nIn, H, (r, c) => P[o.W0 + r * H + c]);
      mk('W1   hidden1(' + H + ') x hidden2(' + H + ')', H, H, (r, c) => P[o.W1 + r * H + c]);
      mk('W2   hidden2(' + H + ') x output(1)', 1, H, (r, c) => P[o.W2 + c]);
    }
    // ------------------------------------------------------------------ inputs list
    buildInputs(nIn) {
      const host = this.r.inputsWrap; host.innerHTML = ''; this.rowsEl = []; this.builtN = nIn;
      let gi = 0;
      for (let i = 0; i < nIn; i++) {
        if (gi < GROUPS.length && GROUPS[gi][0] === i) { const g = document.createElement('div'); g.className = 'ghead'; g.textContent = GROUPS[gi][1]; host.appendChild(g); gi++; }
        const row = document.createElement('div'); row.className = 'irow';
        row.innerHTML = '<span class="in">' + String(i).padStart(2, '0') + '</span><span class="nm">' + NAMES[i] + '</span><span class="bar"><i></i></span><span class="vl">0.00</span><span class="imp"><i></i></span>';
        host.appendChild(row); this.rowsEl.push({ bar: row.querySelector('.bar i'), vl: row.querySelector('.vl'), imp: row.querySelector('.imp i') });
      }
      this.built = true; this.impFor = null;
    }
    updateInputs(net, obs) {
      if (!this.built || this.builtN !== net.nIn) this.buildInputs(net.nIn);
      const now = performance.now(); if (now - this.lastTick < 90) return; this.lastTick = now;
      if (this.impFor !== net) {   // importance = sum |W0 row| (how strongly the network reads this input)
        const H = net.H, o = net.o, P = net.P, nIn = net.nIn, imp = new Float32Array(nIn); let mx = 1e-9;
        for (let k = 0; k < nIn; k++) { let s = 0; for (let j = 0; j < H; j++) s += Math.abs(P[o.W0 + k * H + j]); imp[k] = s; mx = Math.max(mx, s); }
        for (let k = 0; k < nIn; k++) this.rowsEl[k].imp.style.width = (100 * imp[k] / mx).toFixed(0) + '%';
        this.impFor = net;
      }
      for (let k = 0; k < net.nIn; k++) {
        const v = obs[k], t = Math.max(-1, Math.min(1, v)), r = this.rowsEl[k];
        r.bar.style.left = t >= 0 ? '50%' : (50 + t * 50) + '%'; r.bar.style.width = Math.abs(t) * 50 + '%'; r.bar.className = t >= 0 ? 'pos' : 'neg'; r.vl.textContent = v.toFixed(2);
      }
    }
  }
  return { Net, NetView, NAMES, colorOf };
});
