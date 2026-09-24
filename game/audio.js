/* WebAudio player for the sounds extracted from the SWF (MP3, base64 bank).  Event mapping follows SetGame.as (JhSound.play / stop). */
(function (root, factory) { root.GogunAudio = factory(); })(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  const GAIN = { gamebg: 0.32, run: 0.45, spin: 0.5 };   // everything else 0.9
  class AudioEngine {
    constructor(bank) {
      this.bank = bank; this.ctx = null; this.master = null; this.buf = {}; this.ready = false; this.enabled = true; this.vol = 0.6;
      this.active = {}; this.log = []; this.onReady = null; this.unlocked = false;
    }
    unlock() {   // must be called from a user gesture (browser autoplay policy)
      if (!this.ctx) {
        const G = typeof window !== 'undefined' ? window : self, AC = G.AudioContext || G.webkitAudioContext; if (!AC) return false;
        this.ctx = new AC(); this.master = this.ctx.createGain(); this.master.gain.value = this.vol; this.master.connect(this.ctx.destination); this._decode();
      }
      if (this.ctx.state === 'suspended') this.ctx.resume();
      this.unlocked = true; return true;
    }
    _decode() {
      const jobs = [];
      for (const k in this.bank) {
        const bin = atob(this.bank[k].mp3), u8 = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i);
        jobs.push(new Promise(res => { try { this.ctx.decodeAudioData(u8.buffer, b => { this.buf[k] = b; res(); }, () => { this.log.push('decode failed: ' + k); res(); }); } catch (e) { this.log.push('decode failed: ' + k); res(); } }));
      }
      Promise.all(jobs).then(() => { this.ready = true; if (this.onReady) this.onReady(); });
    }
    setVolume(v) { this.vol = Math.max(0, Math.min(1, v)); if (this.master) this.master.gain.value = this.vol; }
    get canPlay() { return this.enabled && this.ready && this.ctx && this.ctx.state === 'running'; }
    _start(name, loop) {
      const b = this.bank[name], buf = this.buf[name]; if (!buf) return null;
      const src = this.ctx.createBufferSource(), g = this.ctx.createGain(); src.buffer = buf; g.gain.value = GAIN[name] || 0.9; src.connect(g); g.connect(this.master);
      const off = b.seek / b.rate, dur = b.samples / b.rate;      // skip the MP3 encoder delay (SeekSamples) and trim to the real length
      if (loop) { src.loop = true; src.loopStart = off; src.loopEnd = off + dur; src.start(0, off); } else src.start(0, off, dur);
      const set = this.active[name] || (this.active[name] = new Set()); set.add(src); src.onended = () => set.delete(src);
      return src;
    }
    play(name) { if (!this.canPlay) return; this.log.push('play:' + name); if (this.log.length > 300) this.log.shift(); this._start(name, false); }
    loop(name) { if (!this.canPlay) return; const set = this.active[name]; if (set && set.size) return; this.log.push('loop:' + name); this._start(name, true); }
    stop(name) { const set = this.active[name]; if (!set) return; this.log.push('stop:' + name); for (const s of set) { try { s.stop(); } catch (e) { } } set.clear(); }
    stopAll() { for (const k in this.active) this.stop(k); }
    /** react to the cosmetic events of GogunSim exactly like SetGame.as plays / stops its sounds */
    onEvents(evs) {
      for (let i = 0; i < evs.length; i++) {
        switch (evs[i]) {
          case 'run': this.loop('run'); break;
          case 'jump': this.stop('run'); this.play('ropeup'); break;
          case 'land': this.stop('spin'); break;
          case 'shoot': this.stop('spin'); this.play('shoot'); break;
          case 'ropecatch': this.play('ropecatch'); break;
          case 'spin': this.loop('spin'); break;
          case 'silver': this.play('silvercoin'); break;
          case 'gold': this.play('goldcoin'); break;
          case 'bonus': this.play('coinbonus'); break;
          case 'speedup': this.play('speedup'); break;
          case 'gameover': this.stopAll(); this.play('gameover'); break;
          case 'finish': this.play('fadeinout'); break;
        }
      }
    }
    bgm() { this.loop('gamebg'); }
    ending() { this.stopAll(); this.play('allclear'); }
    /** (re)start the ambient loops that belong to the current sim state (after tab switch, pause, new game) */
    resync(sim) {
      this.stopAll(); if (!this.canPlay || sim.dead || sim.cleared) return;
      this.bgm(); if (sim.frame === 'run') this.loop('run'); else if (sim.frame === 'spin') this.loop('spin');
    }
  }
  return { AudioEngine };
});
