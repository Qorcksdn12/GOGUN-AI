/* Minimal SWF-timeline runtime + renderer (canvas 2D) for the assets extracted from 고군분투.swf.
 * shapes  : SVG-path fills (bitmap / solid / gradient) ; sprites : frame lists with depth-based display lists. */
(function (root, factory) { if (typeof module === 'object' && module.exports) module.exports = factory(); else root.GogunRender = factory(); })(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  const IDENT = [1, 0, 0, 1, 0, 0];

  class Runtime {
    constructor(scene, images) { this.scene = scene; this.images = images; this.pathCache = new Map(); }
    paths(id) {
      let p = this.pathCache.get(id);
      if (!p) { p = this.scene.shapes[id].paths.map(o => new Path2D(o.d)); this.pathCache.set(id, p); }
      return p;
    }
  }

  class Node {
    constructor(rt, id, parent) {
      this.rt = rt; this.id = id; this.parent = parent || null;
      this.isShape = !!rt.scene.shapes[id];
      this.children = new Map(); this.frame = 0; this.playing = true; this.visible = true; this.removed = false; this.rot = null; this.alpha = 1;
      this.def = this.isShape ? null : rt.scene.sprites[id];
      if (this.def) this.gotoFrame(0);
    }
    named(n) { for (const ch of this.children.values()) if (ch.n === n) return ch; return null; }
    labelFrame(l) { for (let i = 0; i < this.def.length; i++) if (this.def[i].l && this.def[i].l.indexOf(l) >= 0) return i; return 0; }
    goto(label) { this.gotoFrame(typeof label === 'string' ? this.labelFrame(label) : label); this.playing = false; }
    gotoFrame(k) {
      const def = this.def; k = Math.max(0, Math.min(def.length - 1, k));
      const dl = new Map();
      for (let i = 0; i <= k; i++) {
        const f = def[i];
        if (f.r) for (const d of f.r) dl.delete(d);
        if (f.p) for (const p of f.p) {
          if (p.id !== undefined) dl.set(p.d, { id: p.id, m: p.m || IDENT, n: p.n || null, cx: p.cx || null });
          else { const e = dl.get(p.d); if (e) { const ne = Object.assign({}, e); if (p.m) ne.m = p.m; if (p.n) ne.n = p.n; if (p.cx) ne.cx = p.cx; dl.set(p.d, ne); } }
        }
      }
      for (const [d, ch] of this.children) if (!dl.has(d) || dl.get(d).id !== ch.node.id) this.children.delete(d);
      for (const [d, e] of dl) {
        let ch = this.children.get(d);
        if (!ch) { ch = { node: new Node(this.rt, e.id, this), m: e.m, n: e.n, cx: e.cx }; this.children.set(d, ch); }
        else { ch.m = e.m; ch.n = e.n; ch.cx = e.cx; }
      }
      this.frame = k; this.runActions();
    }
    runActions() {
      const a = this.def[this.frame].a; if (!a) return;
      for (const x of a) {
        if (x === 'stop') this.playing = false;
        else if (x === 'remove') this.removed = true;
        else if (x === 'remove2') { if (this.parent && this.parent.parent) this.parent.parent.removed = true; }
        else if (x === 'goto1') this.gotoFrame(0);
        else if (x === 'pstop1') { if (this.parent) { this.parent.gotoFrame(0); this.parent.playing = false; } }
        else if (x === 'pgoto') { if (this.parent && this.parent.target !== undefined) this.parent.gotoFrame(this.parent.target); }
        else if (x === 'hidehit') { const h = this.named('hit_box'); if (h) h.node.visible = false; }
      }
    }
    tick() {
      if (!this.def) return;
      if (this.playing && this.def.length > 1) {
        const nf = this.frame + 1;
        if (nf >= this.def.length) this.gotoFrame(0); else this.advance(nf);
      }
      for (const [d, ch] of this.children) { ch.node.tick(); }
      for (const [d, ch] of this.children) if (ch.node.removed) this.children.delete(d);
    }
    advance(k) {
      const f = this.def[k];
      if (f.r) for (const d of f.r) this.children.delete(d);
      if (f.p) for (const p of f.p) {
        if (p.id !== undefined) this.children.set(p.d, { node: new Node(this.rt, p.id, this), m: p.m || IDENT, n: p.n || null, cx: p.cx || null });
        else { const ch = this.children.get(p.d); if (ch) { if (p.m) ch.m = p.m; if (p.n) ch.n = p.n; if (p.cx) ch.cx = p.cx; } }
      }
      this.frame = k; this.runActions();
    }
    draw(ctx, alpha) {
      if (!this.visible || this.removed) return;
      alpha *= this.alpha;
      if (this.isShape) return this.drawShape(ctx, alpha);
      const keys = Array.from(this.children.keys()).sort((a, b) => a - b);
      for (const d of keys) {
        const ch = this.children.get(d), n = ch.node;
        if (!n.visible || n.removed) continue;
        let m = ch.m;
        if (n.rot !== null) { const sx = Math.hypot(m[0], m[1]), sy = Math.hypot(m[2], m[3]), r = n.rot * Math.PI / 180; m = [Math.cos(r) * sx, Math.sin(r) * sx, -Math.sin(r) * sy, Math.cos(r) * sy, m[4], m[5]]; }
        if (n.pos) m = [m[0], m[1], m[2], m[3], n.pos[0], n.pos[1]];
        let a = alpha; if (ch.cx) a *= ch.cx[0][3] / 256;
        ctx.save(); ctx.transform(m[0], m[1], m[2], m[3], m[4], m[5]); n.draw(ctx, a); ctx.restore();
      }
    }
    drawShape(ctx, alpha) {
      const sh = this.rt.scene.shapes[this.id], ps = this.rt.paths(this.id);
      for (let i = 0; i < ps.length; i++) {
        const f = sh.fills[sh.paths[i].f]; if (!f) continue;
        const path = ps[i];
        if (f.t === 'solid') { ctx.globalAlpha = alpha * f.c[3]; ctx.fillStyle = 'rgb(' + f.c[0] + ',' + f.c[1] + ',' + f.c[2] + ')'; ctx.fill(path); }
        else if (f.t === 'bmp') {
          const img = this.rt.images[f.id]; if (!img) continue;
          ctx.save(); ctx.globalAlpha = alpha; ctx.clip(path);
          ctx.transform(f.m[0], f.m[1], f.m[2], f.m[3], f.m[4], f.m[5]); ctx.imageSmoothingEnabled = f.smooth;
          if (f.rep) { ctx.fillStyle = ctx.createPattern(img, 'repeat'); ctx.fillRect(-4000, -4000, 8000, 8000); } else ctx.drawImage(img, 0, 0);
          ctx.restore();
        } else if (f.t === 'lin' || f.t === 'rad') {
          ctx.save(); ctx.globalAlpha = alpha; ctx.clip(path); ctx.transform(f.m[0], f.m[1], f.m[2], f.m[3], f.m[4], f.m[5]);
          const g = f.t === 'lin' ? ctx.createLinearGradient(-16384, 0, 16384, 0) : ctx.createRadialGradient(f.fp * 16384, 0, 0, 0, 0, 16384);
          for (const [r, c] of f.g) g.addColorStop(r / 255, 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + c[3] + ')');
          ctx.fillStyle = g; ctx.fillRect(-20000, -20000, 40000, 40000); ctx.restore();
        }
      }
      ctx.globalAlpha = 1;
    }
  }

  function loadImages(scene) {
    const out = {}; const jobs = [];
    for (const id in scene.bitmaps) {
      const im = new Image(); im.src = scene.bitmaps[id]; out[id] = im;
      jobs.push(im.decode ? im.decode().catch(() => {}) : new Promise(r => { im.onload = r; }));
    }
    return Promise.all(jobs).then(() => out);
  }

  /* ---- the game scene ------------------------------------------------------------------------------------ */
  class GameView {
    constructor(scene, images, sim) {
      this.rt = new Runtime(scene, images); this.sim = sim; this.E = scene.exports;
      const R = this.rt;
      this.bg = new Node(R, 445);
      this.cat = new Node(R, 490); this.cat.pos = null;
      this.cloud = new Node(R, 539); this.cloudX = 0;
      this.hero = new Node(R, this.E.id_gogoon); this.stick = new Node(R, this.E.id_stick);
      this.score = new Node(R, this.E.id_score); this.run = new Node(R, this.E.id_running);
      this.fx = []; this.blockNodes = new Map(); this.coinNodes = new Map();
      this.trail = []; this.best = 0; this.tickNo = 0; this.deadFrames = 0; this.clearFrames = 0; this.popup = null; this.ending = null; this.fade = 0;
      this.heroFrame = ''; this.bonusFlash = 0;
      this.setFace('sleep'); this.faceTimer = 0;
    }
    setFace(l) { const h = this.cat.named('head_mc'); if (h) h.node.goto(l); }
    setDigits(node, prefix, n, len, left) {
      const s = String(n);
      for (let i = 0; i < len; i++) {
        const c = node.named(prefix + i); if (!c) continue;
        let d;
        if (left) { c.node.visible = i < s.length; d = i < s.length ? +s[i] : 0; }
        else { const k = i - (len - s.length); d = k >= 0 ? +s[k] : 0; c.node.visible = true; }
        c.node.gotoFrame(d > 0 ? d - 1 : 9); c.node.playing = false;
      }
    }
    reset() {
      this.fx = []; this.blockNodes.clear(); this.coinNodes.clear(); this.trail = []; this.deadFrames = 0; this.clearFrames = 0; this.popup = null; this.ending = null;
      this.hero = new Node(this.rt, this.E.id_gogoon); this.heroFrame = ''; this.cloudX = 0; this.stick = new Node(this.rt, this.E.id_stick); this.setFace('sleep'); this.faceTimer = 0;
    }
    /* advance the visual state by one game frame (called once per sim.step) */
    update() {
      const s = this.sim, R = this.rt; this.tickNo++;
      for (const ev of s.events) {
        if (ev === 'bonus') { this.fx.push({ n: new Node(R, this.E.id_bonus_effect), x: 191, y: 237 }); this.setFace('eyes'); this.faceTimer = 150; }
        else if (ev === 'speedup') { this.fx.push({ n: new Node(R, this.E.id_speedup_effect), x: 88, y: 363 }); this.setFace('suprise'); this.faceTimer = 150; }
        else if (ev === 'gameover') { this.setFace('smile'); }
      }
      if (this.faceTimer > 0 && --this.faceTimer === 0 && !s.dead) this.setFace('sleep');
      // hero pose
      const lab = s.frame;
      if (lab !== this.heroFrame) { this.hero.goto(lab); this.heroFrame = lab; }
      const hm = this.hero.named('hit_mc'); if (hm) hm.node.visible = false;   // like the original: gogoon.hit_mc._visible = false
      const body = this.hero.named('body'); if (body) body.node.rot = (lab === 'rope') ? s.bodyRot : null;
      // trail (afterimages, like the original shadowEffect)
      this.trail.push([s.gx, s.gy]); if (this.trail.length > 3) this.trail.shift();
      this.hero.tick(); this.stick.tick(); this.cat.tick();
      for (const f of this.fx) f.n.tick(); this.fx = this.fx.filter(f => !f.n.removed);
      // clouds
      this.cloudX -= s.speed * s.addspeed / 4; if (this.cloudX < -832) this.cloudX += 832;
      // stick
      const st = this.stick;
      if (s.stickVisible && !s.dead) {
        st.visible = true; st.goto(s.rHandler === 'rope' ? 1 : 0);
      } else st.visible = false;
      // housekeeping: drop nodes of blocks/coins that no longer exist
      if (this.tickNo % 300 === 0) {
        const liveB = new Set(s.blocks); for (const k of this.blockNodes.keys()) if (!liveB.has(k)) this.blockNodes.delete(k);
        const liveC = new Set(); for (const box of s.boxes) for (const c of box.all) liveC.add(c); for (const k of this.coinNodes.keys()) if (!liveC.has(k)) this.coinNodes.delete(k);
      }
      // blocks: tick nodes
      for (const b of s.blocks) { let n = this.blockNodes.get(b); if (!n) { n = new Node(R, this.E.id_block); n.goto(b.type - 1); this.blockNodes.set(b, n); } n.tick(); }
      if (s.dead) { for (const b of s.blocks) { const n = this.blockNodes.get(b); const body = n && n.named('body'); if (body && body.node.frame !== 1) body.node.goto(1); } this.deadFrames++; if (this.deadFrames === 12) this.popup = new Node(R, this.E.id_gameover); }
      if (this.popup) this.popup.tick();
      // coins
      for (const box of s.boxes) for (const c of box.all) {
        let n = this.coinNodes.get(c);
        if (!n) { n = new Node(R, this.E.id_item); n.goto(c.gold ? 0 : 1); this.coinNodes.set(c, n); }
        if (c.eaten && !n.eatenStarted) { n.eatenStarted = true; const cc = n.named('coin'); if (cc) cc.node.goto(1); }
        if (n.eatenStarted) n.tick();
      }
      if ((this.tickNo & 127) === 0) {
        const liveB = new Set(s.blocks); for (const k of Array.from(this.blockNodes.keys())) if (!liveB.has(k)) this.blockNodes.delete(k);
        const liveC = new Set(); for (const box of s.boxes) for (const c of box.all) liveC.add(c);
        for (const k of Array.from(this.coinNodes.keys())) if (!liveC.has(k)) this.coinNodes.delete(k);
      }
      // score & progress
      this.setDigits(this.score, 'score', s.score, 6, true);
      this.best = Math.max(this.best, s.score); this.setDigits(this.cat, 'score', this.best, 7, false);
      const face = this.run.named('face_mc'); if (face) { face.node.pos = [s.count / [50, 100, 150, 200, 250, 300, 1000][Math.min(s.level, 6)] * 90 + 90 * Math.min(s.level, 6), 0]; }
      // ending sequence
      if (s.cleared) { this.clearFrames++; if (this.clearFrames >= 16 && !this.ending) { this.ending = new Node(R, this.E['@_4_gogun_ending']); } if (this.ending) this.ending.tick(); }
    }
    draw(ctx) {
      const s = this.sim;
      ctx.clearRect(0, 0, 640, 480);
      ctx.save(); ctx.beginPath(); ctx.rect(0, 0, 640, 480); ctx.clip();
      this.bg.draw(ctx, 1);
      ctx.save(); ctx.translate(106, 119); this.cat.draw(ctx, 1); ctx.restore();   // catstone_mc at (106,119)
      this.cloud.pos = null;
      ctx.save(); ctx.translate(this.cloudX, 318.1); this.cloud.draw(ctx, 1); ctx.restore();
      // blocks
      for (const b of s.blocks) { const n = this.blockNodes.get(b); if (!n) continue; ctx.save(); ctx.translate(b.x, 520); n.draw(ctx, 1); ctx.restore(); }
      // rope line
      if (s.rHandler && !s.dead) {
        const ox = s.gx + 12.5, oy = s.gy - 54.4;
        ctx.strokeStyle = 'rgb(150,186,180)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(s.tx, s.ty); ctx.stroke();
        const st = this.stick;
        ctx.save(); ctx.translate(s.tx, s.ty);
        const rot = s.rHandler === 'rope' ? -80 : Math.atan2(s.ty - oy, s.tx - ox) * 180 / Math.PI;
        ctx.rotate(rot * Math.PI / 180); st.draw(ctx, 1); ctx.restore();
      }
      // coins
      for (const box of s.boxes) for (const c of box.all) {
        const n = this.coinNodes.get(c); if (!n || n.removed) continue;
        ctx.save(); ctx.translate(box.x + c.ox, 520 + c.oy); n.draw(ctx, 1); ctx.restore();
      }
      // hero + afterimages
      const t = this.trail;
      if (!s.dead && s.frame !== 'die') {
        if (t.length > 2) { ctx.save(); ctx.translate(t[0][0], t[0][1]); this.hero.draw(ctx, 0.2); ctx.restore(); }
        if (t.length > 1) { ctx.save(); ctx.translate(t[1][0], t[1][1]); this.hero.draw(ctx, 0.5); ctx.restore(); }
      }
      ctx.save(); ctx.translate(s.gx, s.gy); this.hero.draw(ctx, 1); ctx.restore();
      // effects
      for (const f of this.fx) { ctx.save(); ctx.translate(f.x, f.y); f.n.draw(ctx, 1); ctx.restore(); }
      // UI
      ctx.save(); ctx.translate(11, 8); this.score.draw(ctx, 1); ctx.restore();
      ctx.save(); ctx.translate(50, 463); this.run.draw(ctx, 1); ctx.restore();
      if (this.popup) { ctx.save(); ctx.translate(230, 50); this.popup.draw(ctx, 1); ctx.restore(); }
      if (this.ending) { const a = Math.min(1, (this.clearFrames - 16) / 12); ctx.save(); ctx.translate(320, 240.4); this.ending.draw(ctx, a); ctx.restore(); }
      ctx.restore();
    }
  }
  return { Runtime, Node, GameView, loadImages };
});
