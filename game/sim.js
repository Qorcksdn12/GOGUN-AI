/* 고군분투 (Gogun Bun-tu) — faithful logic remake of the original AS2 game (SetGame / MapData / CoinItem / ItemData).
 * Written against the decompiled ActionScript of "고군분투.swf".  Works in Node and in the browser (UMD).
 * Frame order per tick (Flash AS2 display-list order): mouse events -> stage.onEnterFrame -> rope.onEnterFrame -> gogoon.onEnterFrame
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.GogunSim = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // ---- constants taken from the original code -------------------------------------------------
  const BLOCK_W = 150, GROUND = 365, GX = 200;
  const GRAVITY = 3.5, DYJUMP = 30, ROPESPEED = 40;
  const SPEED0 = 15;
  const MAXCOUNT = [50, 100, 150, 200, 250, 300, 1000];
  const DEG = 57.295779513;
  // ---- geometry taken from the SWF display lists ----------------------------------------------
  const GROUND_RECT = { x0: -100, x1: 100, y0: 353.3, y1: 403.3 };          // block.ground_pos  (block origin = (x, 520))
  const ROPE_RECT = { x0: -110, x1: 100, y0: 85, y1: 135 };                 // block.rope_pos
  const HIT = { dx: 0, dy: 0.05, r: 2 };                                     // gogoon.hit_mc  (4x4 box)
  const ROPEPOS = { x: 12.5, y: -54.4 };                                     // gogoon.ropepos in frame "shoot"
  const BODY_ROPE = { x: 14.3, y: -55.95 };                                  // gogoon.body in frame "rope"
  const ITEMPOS = {                                                          // gogoon.body.item_pos : body origin + item_pos origin, half box 25x30
    run:   { bx: -55.75, by: -98.15, ix: 36.5, iy: 63.45 },
    jump:  { bx: -10, by: -40.5, ix: -9.5, iy: 6.45 },
    shoot: { bx: -10, by: -40.5, ix: -9.5, iy: 6.45 },
    spin:  { bx: -2.95, by: -42.55, ix: -5.5, iy: 2.45 },
    rope:  { bx: 14.3, by: -55.95, ix: -24, iy: 30.5 },
  };
  const ITEM_HALF = { w: 25, h: 30 };
  const COIN_GOLD = { x0: -20.35, x1: 20.4, y0: -19.85, y1: 20.9 };         // id_item frame 1 bounds
  const COIN_SILVER = { x0: -19.8, x1: 21.1, y0: -20.35, y1: 19.85 };       // id_item frame 2 bounds
  const STATUS_IDX = { run: 0, jump: 1, shoot: 2, rope: 3, spin: 4 };
  const TYPE_GAP = 1, TYPE_GROUND = 2, TYPE_ANCHOR = 3, TYPE_FINISH = 4;

  function norm180(a) { a = ((a + 180) % 360 + 360) % 360 - 180; return a; }

  class Sim {
    constructor(data) {
      this.maps = [data.maps.level0, data.maps.level1, data.maps.level2, data.maps.level3, data.maps.level4, data.maps.level5, data.maps.level6];
      this.items = data.items;
      this.itemKey = data.items.map(e => e[0].join(','));
      this.events = [];               // cosmetic events (sounds / effects) for the HTML front-end
      this.itemsOn = true;            // coins can be switched off for planners / fast tests
      this.reset(1);
    }

    clone() {
      const c = Object.create(Sim.prototype);
      for (const k in this) {
        const v = this[k];
        if (k === 'blocks') c.blocks = v.map(b => ({ x: b.x, type: b.type }));
        else if (k === 'boxes') c.boxes = v.map(b => ({ x: b.x, y: b.y, coins: b.coins.map(o => o), all: b.all }));
        else if (Array.isArray(v) && k !== 'maps' && k !== 'items' && k !== 'itemKey') c[k] = v.slice();
        else c[k] = v;
      }
      return c;
    }

    // ---- RNG (mulberry32, identical in sim.c) ---------------------------------------------------
    rand32() {
      this.rs = (this.rs + 0x6D2B79F5) >>> 0;
      let t = this.rs;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return (t ^ (t >>> 14)) >>> 0;
    }
    random(n) { return this.rand32() % n; }
    irand32() {   // independent stream for coin-layout picks (keeps the map sequence identical whether coins are simulated or not)
      this.irs = (this.irs + 0x6D2B79F5) >>> 0;
      let t = this.irs;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return (t ^ (t >>> 14)) >>> 0;
    }

    // ---- SetGame.initialize / initMap -----------------------------------------------------------
    reset(seed, level, count, phase) {
      this.rs = seed >>> 0; this.irs = (seed ^ 0x9E3779B9) >>> 0;
      level = level | 0;
      this.level = level; this.count = 0;
      this.speed = SPEED0; for (let l = 1; l <= level; l++) this.speed += (l < 3 ? 3 : 2);
      this.addspeed = 1;
      this.way = 0; this.nextway = 0;
      this.blocks = []; this.map = [];
      this.boxes = []; this.itemwait = []; this.parr = new Array(9).fill(-1); this.pitem = 0;
      this.score = 0; this.dead = false; this.cleared = false; this.finishing = false; this.frameNo = 0;
      this.gy = GROUND; this.dy = 0; this.status = 'run'; this.frame = 'run'; this.click = false; this.pressed = false;
      this.gHandler = null; this.gGravity = GRAVITY; this.rHandler = null; this.tx = 0; this.ty = 0; this.bodyRot = 0;
      this.gx = GX; this.stickVisible = false; this.stickFrame = 1; this.blocksCreated = 0;
      this.events.length = 0;
      for (let i = 0; i < 6; i++) this.createBlock(TYPE_GROUND, i * BLOCK_W);
      this.count = (count | 0) || 0;
      this.gRun();
      phase = phase | 0;
      if (phase) { for (const b of this.blocks) b.x -= phase; this.nextway += phase; this.way += phase; }
      return this;
    }

    // ---- input ---------------------------------------------------------------------------------
    onMouseDown() {
      this.click = true;
      if (this.status === 'run') this.gJump();
      else if (this.status === 'jump') this.gShoot();
    }
    onMouseUp() { this.click = false; }

    // ---- gogoon state machine -------------------------------------------------------------------
    gRun() { this.status = 'run'; this.click = false; this.frame = 'run'; this.gHandler = 'run'; this.events.push('run'); }
    gRunFrame() { if (!this.groundCheck()) this.gameOver(); }
    gJump() {
      this.status = 'jump'; this.frame = 'jump'; this.dy = DYJUMP * this.addspeed;
      this.gHandler = 'jump'; this.gGravity = GRAVITY; this.events.push('jump');
    }
    gJumpFrame(g) {
      if (this.dy > -20) this.dy = this.dy - g * Math.pow(this.addspeed, 2);
      this.gy = this.gy - this.dy;
      if (this.dy < 0) {
        if (this.status !== 'shoot') this.status = 'jump';
        if (!(this.gy < GROUND) && this.groundCheck()) {
          this.gy = GROUND; this.stickVisible = false; this.rHandler = null; this.gHandler = null;
          this.gRun(); this.events.push('land');
        }
        if (this.gy > 470) this.gameOver();
      }
    }
    gShoot() {
      this.status = 'shoot'; this.frame = 'shoot'; this.events.push('shoot');
      this.tx = this.gx + ROPEPOS.x; this.ty = this.gy + ROPEPOS.y;
      this.stickVisible = true; this.stickFrame = 1; this.rHandler = 'shoot';
    }
    gShootFrame() {
      if (this.ty > 0) {
        this.ty = this.ty - (ROPESPEED - 5);
        this.tx = this.tx + (ROPESPEED + 5);
        if (this.checkRope()) this.gRope();
      } else {
        this.stickVisible = false; this.rHandler = null; this.status = 'jump';
      }
    }
    checkRope() {
      for (let i = 0; i < this.blocks.length; i++) {
        const b = this.blocks[i];
        if (b.type !== TYPE_ANCHOR) continue;
        if (this.tx >= b.x + ROPE_RECT.x0 && this.tx <= b.x + ROPE_RECT.x1 && this.ty >= ROPE_RECT.y0 && this.ty <= ROPE_RECT.y1) return true;
      }
      return false;
    }
    gRope() {
      this.gHandler = null; this.frame = 'rope'; this.status = 'rope'; this.events.push('ropecatch');
      this.dy = 15 * this.addspeed;
      if (this.ty < 125) this.tx = this.tx - (125 - this.ty - 5);
      this.ty = 125; this.bodyRot = 45; this.stickFrame = 2; this.rHandler = 'rope';
    }
    gRopeFrame() {
      if (!(this.gy > 550)) {
        this.tx = this.tx - this.speed * this.addspeed;
        const bx = this.gx + BODY_ROPE.x, by = this.gy + BODY_ROPE.y;
        this.bodyRot = norm180(Math.atan2(this.ty - by, this.tx - bx) * DEG + 70);
        if (this.click) {
          if (this.dy > -30) this.dy = this.dy - GRAVITY * Math.pow(this.addspeed, 2);
          if (this.gy < this.ty + 50) this.gSpin();
        } else {
          if (this.dy < 30) this.dy = this.dy + GRAVITY * Math.pow(this.addspeed, 2);
        }
        this.gy = this.gy + this.dy;
        if (this.bodyRot < -70) this.gSpin();
        if (this.tx < 70) this.gSpin();
      } else this.gameOver();
    }
    gSpin() {
      this.rHandler = null; this.stickVisible = false; this.status = 'spin'; this.frame = 'spin';
      this.events.push('spin');
      this.dy = DYJUMP + 15 * this.addspeed;
      this.gHandler = 'jump'; this.gGravity = GRAVITY * 1.5;
    }

    // ---- collision helpers (bounding-box hitTest, inclusive) -------------------------------------
    groundCheck() {
      const hx0 = this.gx - HIT.r, hx1 = this.gx + HIT.r, hy0 = this.gy + HIT.dy - HIT.r, hy1 = this.gy + HIT.dy + HIT.r;
      for (let i = 0; i < this.blocks.length; i++) {
        const b = this.blocks[i];
        if (b.type !== TYPE_GROUND && b.type !== TYPE_FINISH) continue;
        if (hx0 <= b.x + GROUND_RECT.x1 && hx1 >= b.x + GROUND_RECT.x0 && hy0 <= GROUND_RECT.y1 && hy1 >= GROUND_RECT.y0) return true;
      }
      return false;
    }
    itemRectAt(frame, gy, rot) {
      if (frame === 'die') return null;
      const g = ITEMPOS[frame];
      let cx, cy, hw = ITEM_HALF.w, hh = ITEM_HALF.h;
      if (frame === 'rope') {
        const th = rot / DEG, c = Math.cos(th), s = Math.sin(th);
        cx = this.gx + g.bx + (c * g.ix - s * g.iy);
        cy = gy + g.by + (s * g.ix + c * g.iy);
        const w = Math.abs(c) * ITEM_HALF.w + Math.abs(s) * ITEM_HALF.h, h = Math.abs(s) * ITEM_HALF.w + Math.abs(c) * ITEM_HALF.h;
        hw = w; hh = h;
      } else { cx = this.gx + g.bx + g.ix; cy = gy + g.by + g.iy; }
      return { x0: cx - hw, x1: cx + hw, y0: cy - hh, y1: cy + hh };
    }
    itemRect() { return this.itemRectAt(this.frame, this.gy, this.bodyRot); }

    // ---- world -----------------------------------------------------------------------------------
    createBlock(type, x) {
      if (type === TYPE_FINISH) this.goFinish();
      this.blocks.push({ x: x, type: type });
      this.blocksCreated++;
      this.count = this.count + 1;
      if (this.count >= MAXCOUNT[this.level]) this.levelUp();
    }
    levelUp() {
      this.level = this.level + 1;
      if (this.level <= 5) {
        this.count = 0;
        this.speed = this.speed + (this.level < 3 ? 3 : 2);
        this.events.push('speedup');
      } else {
        this.count = 0;
        this.map.push(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2);
      }
    }
    goFinish() { this.speed = 0; this.finishing = true; this.cleared = true; this.events.push('finish'); }
    getMap(level) {
      const lv = level + 1; let p = 0;
      if (lv === 1) p = 75; else if (lv === 2) p = 50; else if (lv === 3) p = 40; else if (lv === 4) p = 10; else if (lv === 5) p = 30;
      if (this.random(100) < p) { const L = this.maps[0]; return L[this.random(L.length)]; }
      const L = this.maps[lv]; return L[this.random(L.length)];
    }
    getItem(map) {
      const key = map.join(','); const idx = [];
      for (let i = 0; i < this.itemKey.length; i++) if (this.itemKey[i] === key) idx.push(i);
      if (!idx.length) return [];
      const e = this.items[idx[this.irand32() % idx.length]];
      return e.slice(1);
    }
    addItem(map) {
      if (this.itemwait.length <= 0) {
        const it = this.getItem(map);
        for (let i = 0; i < it.length; i++) this.itemwait.push(it[i]);
        this.pitem = this.pitem < 8 ? this.pitem + 1 : 0;
        let n = 0; for (let i = 0; i < it.length; i++) for (let j = 0; j < it[i].length; j++) if (it[i][j] < 100) n++;
        this.parr[this.pitem] = n <= 0 ? -1 : n;
      }
    }
    createItem(x, y) {
      const arr = this.itemwait.length ? this.itemwait.shift() : null;
      if (arr && arr.length > 0) {
        const box = { x: x, y: y, coins: [], all: [] };
        for (let i = 0; i < arr.length; i++) {
          let s = arr[i], gold = true;
          if (s >= 100) { gold = false; s -= 100; }
          const c = { ox: -58.5 + (s % 4) * 37.5, oy: -480 + Math.floor(s / 4) * 37, gold: gold, pitem: this.pitem, eaten: false, eatenAt: -1 };
          box.coins.push(c); box.all.push(c);
        }
        this.boxes.push(box);
      }
    }
    deleteItem(x) { for (let i = 0; i < this.boxes.length; i++) if (this.boxes[i].x < x) { this.boxes.splice(i, 1); i--; } }
    deleteBlock() { this.blocks.shift(); }
    addPoint(type) {
      if (type === 1) { this.score += 5; this.events.push('silver'); }
      else if (type === 2) { this.score += Math.trunc(50 - this.level * 5 + 0.1); this.events.push('gold'); }
      else if (type === 3) { this.score += Math.trunc(100 + this.level * 20 + 0.1); }
    }
    eatItem() {
      const r = this.itemRect(); if (!r) return;
      for (let i = 0; i < this.boxes.length; i++) {
        const box = this.boxes[i];
        for (let j = 0; j < box.coins.length; j++) {
          const c = box.coins[j], cr = c.gold ? COIN_GOLD : COIN_SILVER;
          const cx = box.x + c.ox, cy = box.y + c.oy;
          if (r.x0 <= cx + cr.x1 && r.x1 >= cx + cr.x0 && r.y0 <= cy + cr.y1 && r.y1 >= cy + cr.y0) {
            if (c.gold) this.parr[c.pitem] -= 1;
            this.addPoint(c.gold ? 2 : 1);
            this.onBonus();
            c.eaten = true; c.eatenAt = this.frameNo;
            box.coins.splice(j, 1); j--;
          }
        }
      }
    }
    onBonus() {
      for (let i = 0; i < this.parr.length; i++) if (this.parr[i] === 0) { this.addPoint(3); this.events.push('bonus'); this.parr[i] = -1; }
    }
    gameOver() {
      if (this.finishing) return;   // after the finish block appears the original swaps to the ending scene before the hero can fall
      this.dead = true; this.frame = 'die'; this.gHandler = null; this.rHandler = null; this.stickVisible = false;
      this.events.push('gameover');
    }

    // ---- SetGame.onEnterFrame ---------------------------------------------------------------------
    stageFrame() {
      const sp = this.speed * this.addspeed;
      this.way += sp; this.nextway += sp;
      for (let i = 0; i < this.blocks.length; i++) this.blocks[i].x -= sp;
      for (let i = 0; i < this.boxes.length; i++) this.boxes[i].x -= sp;
      const nx = BLOCK_W * 5 - (this.nextway - BLOCK_W);
      if (BLOCK_W <= this.nextway) {
        if (this.map.length <= 0) {
          const m = this.getMap(this.level);
          for (let i = 0; i < m.length; i++) this.map.push(m[i]);
          if (this.itemsOn) this.addItem(this.map);
        }
        const t = this.map.shift();
        this.createBlock(t, nx);
        if (this.itemsOn) this.createItem(nx, 520);
        this.deleteItem(-BLOCK_W);
        this.deleteBlock();
        this.nextway = this.nextway - BLOCK_W;
      }
      if (this.itemsOn) this.eatItem();
    }
    finishFrame() { this.gx += 30; }



    // ---- look-ahead helpers ----
    groundAt(gy, shift) {
      const hx0 = 198, hx1 = 202, hy0 = gy + 0.05 - 2, hy1 = gy + 0.05 + 2;
      for (const b of this.blocks) {
        if (b.type !== 2 && b.type !== 4) continue;
        const bx = b.x - shift;
        if (hx0 <= bx + 100 && hx1 >= bx - 100 && hy0 <= 403.3 && hy1 >= 353.3) return true;
      }
      return false;
    }
    flightSim(gy, dy, g, sp) {
      for (let f = 1; f <= 60; f++) {
        if (dy > -20) dy = dy - g;
        gy = gy - dy;
        if (dy < 0) { if (!(gy < GROUND) && this.groundAt(gy, sp * f)) return f; if (gy > 470) return -1; }
      }
      return -1;
    }
    catchPredict(j, sp) {   // returns {k, gy} or null
      if (this.gHandler !== 'jump' || this.status === 'shoot') return null;
      let gy = this.gy, dy = this.dy; const g = this.gGravity;
      for (let f = 1; f <= j; f++) {
        if (dy > -20) dy = dy - g;
        gy = gy - dy;
        if (dy < 0) { if (!(gy < GROUND) && this.groundAt(gy, sp * f)) return null; if (gy > 470) return null; }
      }
      if (this.status === 'spin' && !(dy < 0)) return null;
      let ty = gy + ROPEPOS.y, tx = ROPEPOS.x + GX;
      for (let k = 1; k <= 16; k++) {
        if (!(ty > 0)) break;
        ty = ty - 35; tx = tx + 45;
        const shift = sp * (j + k);
        for (const b of this.blocks) {
          if (b.type !== 3) continue;
          const bx = b.x - shift;
          if (tx >= bx - 110 && tx <= bx + 100 && ty >= 85 && ty <= 135) return { k: k, gy: gy };
        }
        if (dy > -20) dy = dy - g;
        gy = gy - dy;
        if (dy < 0) { if (!(gy < GROUND) && this.groundAt(gy, sp * (j + k))) return null; if (gy > 470) return null; }
      }
      return null;
    }

    // ---- coin look-ahead (observation v2) -------------------------------------------------------------
    coinHold(label, gy, rot, sp, F, cands) {
      const n = cands.length; if (!n) return 0; const r = this.itemRectAt(label, gy, rot); if (!r) return 0;
      const taken = new Uint8Array(n); let v = 0;
      for (let f = 1; f <= F; f++) {
        const s = sp * f;
        for (let i = 0; i < n; i++) {
          if (taken[i]) continue; const c = cands[i], cr = c.gold ? COIN_GOLD : COIN_SILVER, cx = c.cx - s;
          if (r.x0 <= cx + cr.x1 && r.x1 >= cx + cr.x0 && r.y0 <= c.cy + cr.y1 && r.y1 >= c.cy + cr.y0) { taken[i] = 1; v += c.val; }
        }
      }
      return v;
    }
    coinFlight(label, gy, dy, g, sp, cands) {
      const n = cands.length; if (!n) return 0; const taken = new Uint8Array(n); let v = 0;
      for (let f = 1; f <= 60; f++) {
        const r = this.itemRectAt(label, gy, 0), s = sp * f;
        if (r) for (let i = 0; i < n; i++) {
          if (taken[i]) continue; const c = cands[i], cr = c.gold ? COIN_GOLD : COIN_SILVER, cx = c.cx - s;
          if (r.x0 <= cx + cr.x1 && r.x1 >= cx + cr.x0 && r.y0 <= c.cy + cr.y1 && r.y1 >= c.cy + cr.y0) { taken[i] = 1; v += c.val; }
        }
        if (dy > -20) dy = dy - g;
        gy = gy - dy;
        if (dy < 0) { if (!(gy < GROUND) && this.groundAt(gy, s)) break; if (gy > 470) break; }
      }
      return v;
    }
    coinFeatures(o, k, sp) {   // 20 extra inputs: 6 nearest coins (dx, dy, gold) + coin value on the way if we hold height / if we jump
      const cl = (v, lo, hi) => v < lo ? lo : (v > hi ? hi : v);
      const lab = this.frame === 'die' ? 'run' : this.frame;
      const r0 = this.itemRectAt(lab, this.gy, this.bodyRot), icx = (r0.x0 + r0.x1) / 2, icy = (r0.y0 + r0.y1) / 2;
      const gv = Math.trunc(50 - this.level * 5 + 0.1), cands = [];
      for (let i = 0; i < this.boxes.length; i++) {
        const box = this.boxes[i];
        for (let j = 0; j < box.coins.length; j++) { const c = box.coins[j], cx = box.x + c.ox; if (cx >= icx - 60 && cx <= icx + 720) cands.push({ cx: cx, cy: box.y + c.oy, gold: c.gold, val: c.gold ? gv : 5 }); }
      }
      cands.sort((a, b) => (a.cx - b.cx) || (a.cy - b.cy));
      for (let i = 0; i < 6; i++) {
        if (i < cands.length) { o[k++] = cl((cands[i].cx - icx) / 300, -1, 2.5); o[k++] = cl((cands[i].cy - icy) / 200, -2, 2); o[k++] = cands[i].gold ? 1 : 0; }
        else { o[k++] = 2.5; o[k++] = 0; o[k++] = 0; }
      }
      const hold = this.coinHold(lab, this.gy, this.bodyRot, sp, 24, cands);
      let fv = 0;
      if (this.gHandler === 'jump') fv = this.coinFlight(lab, this.gy, this.dy, this.gGravity, sp, cands);
      else if (this.gHandler === 'run') fv = this.coinFlight('jump', GROUND, DYJUMP * this.addspeed, GRAVITY, sp, cands);
      o[k++] = cl(hold / 100, 0, 3); o[k++] = cl(fv / 100, 0, 3);
      return k;
    }

    // ---- observation vector for the neural policy (64 floats, or 84 with the coin block when ver = 2; must match env_obs() in sim.c) --------
    features(o, ver) {
      ver = ver || this.obsVer || 1; o = o || new Float32Array(ver === 2 ? 84 : 64);
      let sp = this.speed * this.addspeed; if (sp < 1) sp = 1;
      let k = 0;
      o[k++] = (this.gy - GROUND) / 150;
      o[k++] = this.dy / 30;
      const st = STATUS_IDX[this.status];
      for (let s = 0; s < 5; s++) o[k++] = st === s ? 1 : 0;
      o[k++] = this.click ? 1 : 0; o[k++] = this.pressed ? 1 : 0;
      o[k++] = this.rHandler === 'shoot' ? 1 : 0; o[k++] = this.rHandler === 'rope' ? 1 : 0;
      const ra = this.rHandler !== null;
      o[k++] = ra ? (this.tx - GX) / 300 : 0;
      o[k++] = ra ? (this.ty - this.gy) / 300 : 0;
      o[k++] = this.rHandler === 'rope' ? this.bodyRot / 90 : 0;
      o[k++] = sp / 27; o[k++] = this.level / 6;
      const B = this.blocks, nb = B.length;
      let cur = 198.0, ch = true;
      while (ch) { ch = false; for (let i = 0; i < nb; i++) if ((B[i].type === 2 || B[i].type === 4) && B[i].x - 100 <= cur && B[i].x + 100 > cur) { cur = B[i].x + 100; ch = true; } }
      const tSupport = (cur - 198.0) / sp;
      let nextStart = 900.0;
      for (let i = 0; i < nb; i++) if ((B[i].type === 2 || B[i].type === 4) && B[i].x - 100 > cur && B[i].x - 100 < nextStart) nextStart = B[i].x - 100;
      const tNext = (nextStart - 202.0) / sp;
      const cl = (v, lo, hi) => v < lo ? lo : (v > hi ? hi : v);
      o[k++] = cl(tSupport / 20, -1, 2); o[k++] = cl(tNext / 30, -1, 3); o[k++] = cl((nextStart - cur) / 450, -1, 2);
      let na = 0;
      for (let i = 0; i < nb && na < 2; i++) if (B[i].type === 3 && B[i].x + 100 >= 150) {
        const rx = B[i].x - 5 - 212.5;
        o[k++] = rx / 300; o[k++] = cl(rx / (sp * 20), -3, 3); o[k++] = 1; na++;
      }
      while (na < 2) { o[k++] = 0; o[k++] = 0; o[k++] = 0; na++; }
      for (let i = 0; i < 6; i++) {
        if (i < nb) { o[k++] = (B[i].x - GX) / 300; o[k++] = B[i].type === 1 ? 1 : 0; o[k++] = (B[i].type === 2 || B[i].type === 4) ? 1 : 0; o[k++] = B[i].type === 3 ? 1 : 0; }
        else { o[k++] = 2.5; o[k++] = 0; o[k++] = 0; o[k++] = 0; }
      }
      let kc = 0, jfirst = -1, jlast = -1, gyc0 = 0;
      for (let j = 0; j < 12; j++) {
        const r = this.catchPredict(j, sp);
        if (j < 4) o[k++] = r ? 1 : 0;
        if (j === 0) { kc = r ? r.k : 0; gyc0 = r ? r.gy : 0; }
        if (r) { if (jfirst < 0) jfirst = j; jlast = j; }
      }
      o[k++] = kc / 12;
      const inFlight = this.gHandler === 'jump';
      const fl = inFlight ? this.flightSim(this.gy, this.dy, this.gGravity, sp) : 0;
      o[k++] = (inFlight && fl > 0) ? 1 : 0; o[k++] = fl > 0 ? fl / 30 : 0;
      const jl = this.flightSim(GROUND, DYJUMP * this.addspeed, GRAVITY, sp);
      o[k++] = jl > 0 ? 1 : 0; o[k++] = jl > 0 ? jl / 30 : 0;
      const roping = this.rHandler === 'rope';
      const sl = roping ? this.flightSim(this.gy, DYJUMP + 15 * this.addspeed, GRAVITY * 1.5, sp) : 0;
      o[k++] = (roping && sl > 0) ? 1 : 0; o[k++] = sl > 0 ? sl / 40 : 0;
      o[k++] = kc ? (gyc0 - GROUND) / 150 : 0;
      o[k++] = (jfirst + 1) / 12; o[k++] = (jlast + 1) / 12;
      o[k++] = roping ? cl((this.tx - 70) / sp / 20, -1, 2) : 0;
      if (ver === 2) this.coinFeatures(o, k, sp);
      return o;
    }

    // ---- one 30 fps tick ---------------------------------------------------------------------------
    step(pressed) {
      pressed = !!pressed;
      this.events.length = 0;
      if (!this.dead) {
        if (pressed && !this.pressed) this.onMouseDown();
        else if (!pressed && this.pressed) this.onMouseUp();
      }
      this.pressed = pressed;
      this.frameNo++;
      if (this.dead) return;
      const ord = this.order || 'srg';
      for (let i = 0; i < 3; i++) {
        const ch = ord[i];
        if (ch === 's') { if (this.finishing && this.stagePhase === 'finish') this.finishFrame(); else this.stageFrame(); }
        else if (ch === 'r') { if (this.rHandler === 'shoot') this.gShootFrame(); else if (this.rHandler === 'rope') this.gRopeFrame(); }
        else if (ch === 'g') { if (this.gHandler === 'run') this.gRunFrame(); else if (this.gHandler === 'jump') this.gJumpFrame(this.gGravity); }
        if (this.dead) break;
      }
      if (this.finishing && !this.stagePhase) this.stagePhase = 'finish';
    }
  }

  Sim.const = { BLOCK_W, GROUND, GX, GRAVITY, MAXCOUNT, GROUND_RECT, ROPE_RECT, HIT, ITEMPOS, COIN_GOLD, COIN_SILVER, DEG };
  return Sim;
});
