/* C port of sim.js (faithful logic of the original 고군분투 AS2 game) — used for fast RL training.
 * Build:  gcc -O3 -march=native -shared -fPIC -o libsim.so sim.c -lm
 */
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "data.h"

#define BLOCK_W 150.0
#define GROUND 365.0
#define GX 200.0
#define GRAVITY 3.5
#define DYJUMP 30.0
#define ROPESPEED 40.0
#define DEG 57.295779513
#define NB 8          /* max blocks */
#define NBOX 16
#define QMAP 64
#define QWAIT 32

enum { ST_RUN, ST_JUMP, ST_SHOOT, ST_ROPE, ST_SPIN };
enum { FR_RUN, FR_JUMP, FR_SHOOT, FR_ROPE, FR_SPIN, FR_DIE };
enum { GH_NONE, GH_RUN, GH_JUMP };
enum { RH_NONE, RH_SHOOT, RH_ROPE };

static const int MAXCOUNT[7] = {50, 100, 150, 200, 250, 300, 1000};

typedef struct {
  uint32_t rs, irs;
  int level, count;
  double speed, addspeed, way, nextway;
  int nb; double bx[NB]; int bt[NB];
  int mh, mt; int mq[QMAP];              /* map queue [mh, mt) */
  int nbox; double boxx[NBOX], boxy[NBOX]; int boxn[NBOX];
  double cox[NBOX][MAXCOINS], coy[NBOX][MAXCOINS]; int cgold[NBOX][MAXCOINS], cpit[NBOX][MAXCOINS], calive[NBOX][MAXCOINS];
  int nw, wh; const short *wp[QWAIT]; int wn[QWAIT];   /* itemwait queue [wh, nw) */
  int parr[9], pitem;
  int score, dead, cleared, finishing, stagephase, frameNo, blocksCreated;
  double gy, dy, gx; int status, frame, click, pressed, gh; double ggrav; int rh; double tx, ty, bodyRot;
  int items_on;
  int steps;   /* steps in current episode (for RL wrapper) */
  int maxsteps;
  int coinsEaten, goldEaten;
} Env;

int env_size(void) { return (int)sizeof(Env); }

static inline uint32_t rand32(Env *e) {
  e->rs += 0x6D2B79F5u; uint32_t t = e->rs;
  t = (t ^ (t >> 15)) * (t | 1u);
  t ^= t + (t ^ (t >> 7)) * (t | 61u);
  return t ^ (t >> 14);
}
static inline int rnd(Env *e, int n) { return (int)(rand32(e) % (uint32_t)n); }
static inline int irnd(Env *e, int n) {
  e->irs += 0x6D2B79F5u; uint32_t t = e->irs;
  t = (t ^ (t >> 15)) * (t | 1u);
  t ^= t + (t ^ (t >> 7)) * (t | 61u);
  return (int)((t ^ (t >> 14)) % (uint32_t)n);
}

static double norm180(double a) { return fmod(fmod(a + 180.0, 360.0) + 360.0, 360.0) - 180.0; }

/* ---- forward decls ---- */
static void gRun(Env *e); static void gameOver(Env *e); static void levelUp(Env *e);
static void gRope(Env *e); static void gSpin(Env *e);

static void goFinish(Env *e) { e->speed = 0; e->finishing = 1; e->cleared = 1; }

static void createBlock(Env *e, int type, double x) {
  if (type == 4) goFinish(e);
  e->bx[e->nb] = x; e->bt[e->nb] = type; e->nb++;
  e->blocksCreated++;
  e->count++;
  if (e->count >= MAXCOUNT[e->level]) levelUp(e);
}
static void mpush(Env *e, int v) { e->mq[e->mt++] = v; }
static void levelUp(Env *e) {
  e->level++;
  if (e->level <= 5) { e->count = 0; e->speed += (e->level < 3 ? 3 : 2); }
  else { e->count = 0; static const int END[17] = {2,2,2,2,2,2,2,2,2,2,4,2,2,2,2,2,2}; for (int i = 0; i < 17; i++) mpush(e, END[i]); }
}

static void addPoint(Env *e, int type) {
  if (type == 1) e->score += 5;
  else if (type == 2) e->score += (int)(50 - e->level * 5 + 0.1);
  else if (type == 3) e->score += (int)(100 + e->level * 20 + 0.1);
}
static void onBonus(Env *e) { for (int i = 0; i < 9; i++) if (e->parr[i] == 0) { addPoint(e, 3); e->parr[i] = -1; } }

static void addItem(Env *e) {
  if (e->nw - e->wh <= 0) {
    e->wh = 0; e->nw = 0;
    int n = e->mt - e->mh;
    int idx[NITEMS], ni = 0;
    for (int i = 0; i < NITEMS; i++) {
      if (ITEMKEYLEN[i] != n) continue;
      int ok = 1; for (int j = 0; j < n; j++) if (ITEMKEY[i][j] != e->mq[e->mh + j]) { ok = 0; break; }
      if (ok) idx[ni++] = i;
    }
    int nblocks = 0; const short *(*dummy) = NULL; (void)dummy;
    if (ni) {
      int k = idx[irnd(e, ni)];
      nblocks = n;
      for (int b = 0; b < nblocks; b++) { e->wp[e->nw] = ITEMSLOT[k][b]; e->wn[e->nw] = ITEMBCOUNT[k][b]; e->nw++; }
    }
    e->pitem = e->pitem < 8 ? e->pitem + 1 : 0;
    int cnt = 0;
    for (int b = 0; b < e->nw; b++) for (int j = 0; j < e->wn[b]; j++) if (e->wp[b][j] < 100) cnt++;
    e->parr[e->pitem] = cnt <= 0 ? -1 : cnt;
  }
}
static void createItem(Env *e, double x, double y) {
  if (e->nw - e->wh > 0) {
    const short *p = e->wp[e->wh]; int n = e->wn[e->wh]; e->wh++;
    if (n > 0) {
      int b = e->nbox++;
      e->boxx[b] = x; e->boxy[b] = y; e->boxn[b] = n;
      for (int i = 0; i < n; i++) {
        int s = p[i], gold = 1; if (s >= 100) { gold = 0; s -= 100; }
        e->cox[b][i] = -58.5 + (s % 4) * 37.5; e->coy[b][i] = -480 + floor(s / 4) * 37;
        e->cgold[b][i] = gold; e->cpit[b][i] = e->pitem; e->calive[b][i] = 1;
      }
    }
  }
}
static void deleteItem(Env *e, double x) {
  int w = 0;
  for (int i = 0; i < e->nbox; i++) {
    if (e->boxx[i] < x) continue;
    if (w != i) {
      e->boxx[w] = e->boxx[i]; e->boxy[w] = e->boxy[i]; e->boxn[w] = e->boxn[i];
      memcpy(e->cox[w], e->cox[i], sizeof(double) * MAXCOINS); memcpy(e->coy[w], e->coy[i], sizeof(double) * MAXCOINS);
      memcpy(e->cgold[w], e->cgold[i], sizeof(int) * MAXCOINS); memcpy(e->cpit[w], e->cpit[i], sizeof(int) * MAXCOINS);
      memcpy(e->calive[w], e->calive[i], sizeof(int) * MAXCOINS);
    }
    w++;
  }
  e->nbox = w;
}
static void deleteBlock(Env *e) { for (int i = 1; i < e->nb; i++) { e->bx[i-1] = e->bx[i]; e->bt[i-1] = e->bt[i]; } e->nb--; }

static void getMap(Env *e, int level, int *out, int *len) {
  int lv = level + 1, p = 0;
  if (lv == 1) p = 75; else if (lv == 2) p = 50; else if (lv == 3) p = 40; else if (lv == 4) p = 10; else if (lv == 5) p = 30;
  int l = lv, k;
  if (rnd(e, 100) < p) { l = 0; }
  k = rnd(e, NMAPS[l]);
  *len = MAPLEN[l][k]; for (int i = 0; i < *len; i++) out[i] = MAPDATA[l][k][i];
}

static int groundCheck(const Env *e) {
  double hx0 = e->gx - 2, hx1 = e->gx + 2, hy0 = e->gy + 0.05 - 2, hy1 = e->gy + 0.05 + 2;
  for (int i = 0; i < e->nb; i++) {
    if (e->bt[i] != 2 && e->bt[i] != 4) continue;
    if (hx0 <= e->bx[i] + 100 && hx1 >= e->bx[i] - 100 && hy0 <= 403.3 && hy1 >= 353.3) return 1;
  }
  return 0;
}
static int itemRectAt(const Env *e, int frame, double gy, double rot, double *r) {
  double cx, cy, hw = 25, hh = 30;
  switch (frame) {
    case FR_RUN: cx = e->gx + -55.75 + 36.5; cy = gy + -98.15 + 63.45; break;
    case FR_JUMP: case FR_SHOOT: cx = e->gx + -10 + -9.5; cy = gy + -40.5 + 6.45; break;
    case FR_SPIN: cx = e->gx + -2.95 + -5.5; cy = gy + -42.55 + 2.45; break;
    case FR_ROPE: {
      double th = rot / DEG, c = cos(th), s = sin(th);
      cx = e->gx + 14.3 + (c * -24 - s * 30.5); cy = gy + -55.95 + (s * -24 + c * 30.5);
      hw = fabs(c) * 25 + fabs(s) * 30; hh = fabs(s) * 25 + fabs(c) * 30; break; }
    default: return 0;
  }
  r[0] = cx - hw; r[1] = cx + hw; r[2] = cy - hh; r[3] = cy + hh; return 1;
}
static int itemRect(const Env *e, double *r) { return itemRectAt(e, e->frame, e->gy, e->bodyRot, r); }
static void eatItem(Env *e) {
  double r[4]; if (!itemRect(e, r)) return;
  for (int i = 0; i < e->nbox; i++) {
    for (int j = 0; j < e->boxn[i]; j++) {
      if (!e->calive[i][j]) continue;
      double x0, x1, y0, y1;
      if (e->cgold[i][j]) { x0 = -20.35; x1 = 20.4; y0 = -19.85; y1 = 20.9; } else { x0 = -19.8; x1 = 21.1; y0 = -20.35; y1 = 19.85; }
      double cx = e->boxx[i] + e->cox[i][j], cy = e->boxy[i] + e->coy[i][j];
      if (r[0] <= cx + x1 && r[1] >= cx + x0 && r[2] <= cy + y1 && r[3] >= cy + y0) {
        if (e->cgold[i][j]) e->parr[e->cpit[i][j]] -= 1;
        addPoint(e, e->cgold[i][j] ? 2 : 1);
        onBonus(e);
        e->calive[i][j] = 0; e->coinsEaten++; if (e->cgold[i][j]) e->goldEaten++;
      }
    }
  }
}

/* ---- gogoon state machine ---- */
static void gRun(Env *e) { e->status = ST_RUN; e->click = 0; e->frame = FR_RUN; e->gh = GH_RUN; }
static void gameOver(Env *e) { e->dead = 1; e->frame = FR_DIE; e->gh = GH_NONE; e->rh = RH_NONE; }
static void gJump(Env *e) { e->status = ST_JUMP; e->frame = FR_JUMP; e->dy = DYJUMP * e->addspeed; e->gh = GH_JUMP; e->ggrav = GRAVITY; }
static void gShoot(Env *e) { e->status = ST_SHOOT; e->frame = FR_SHOOT; e->tx = e->gx + 12.5; e->ty = e->gy + -54.4; e->rh = RH_SHOOT; }
static void gRope(Env *e) {
  e->gh = GH_NONE; e->frame = FR_ROPE; e->status = ST_ROPE; e->dy = 15 * e->addspeed;
  if (e->ty < 125) e->tx = e->tx - (125 - e->ty - 5);
  e->ty = 125; e->bodyRot = 45; e->rh = RH_ROPE;
}
static void gSpin(Env *e) { e->rh = RH_NONE; e->status = ST_SPIN; e->frame = FR_SPIN; e->dy = DYJUMP + 15 * e->addspeed; e->gh = GH_JUMP; e->ggrav = GRAVITY * 1.5; }
static int checkRope(const Env *e) {
  for (int i = 0; i < e->nb; i++) {
    if (e->bt[i] != 3) continue;
    if (e->tx >= e->bx[i] - 110 && e->tx <= e->bx[i] + 100 && e->ty >= 85 && e->ty <= 135) return 1;
  }
  return 0;
}
static void gJumpFrame(Env *e, double g) {
  if (e->dy > -20) e->dy = e->dy - g * pow(e->addspeed, 2);
  e->gy = e->gy - e->dy;
  if (e->dy < 0) {
    if (e->status != ST_SHOOT) e->status = ST_JUMP;
    if (!(e->gy < GROUND) && groundCheck(e)) { e->gy = GROUND; e->rh = RH_NONE; e->gh = GH_NONE; gRun(e); }
    if (e->gy > 470) gameOver(e);
  }
}
static void gShootFrame(Env *e) {
  if (e->ty > 0) {
    e->ty = e->ty - (ROPESPEED - 5); e->tx = e->tx + (ROPESPEED + 5);
    if (checkRope(e)) gRope(e);
  } else { e->rh = RH_NONE; e->status = ST_JUMP; }
}
static void gRopeFrame(Env *e) {
  if (!(e->gy > 550)) {
    e->tx = e->tx - e->speed * e->addspeed;
    double bx = e->gx + 14.3, by = e->gy + -55.95;
    e->bodyRot = norm180(atan2(e->ty - by, e->tx - bx) * DEG + 70);
    if (e->click) {
      if (e->dy > -30) e->dy = e->dy - GRAVITY * pow(e->addspeed, 2);
      if (e->gy < e->ty + 50) gSpin(e);
    } else { if (e->dy < 30) e->dy = e->dy + GRAVITY * pow(e->addspeed, 2); }
    e->gy = e->gy + e->dy;
    if (e->bodyRot < -70) gSpin(e);
    if (e->tx < 70) gSpin(e);
  } else gameOver(e);
}

static void stageFrame(Env *e) {
  double sp = e->speed * e->addspeed;
  e->way += sp; e->nextway += sp;
  for (int i = 0; i < e->nb; i++) e->bx[i] -= sp;
  for (int i = 0; i < e->nbox; i++) e->boxx[i] -= sp;
  double nx = BLOCK_W * 5 - (e->nextway - BLOCK_W);
  if (BLOCK_W <= e->nextway) {
    if (e->mt - e->mh <= 0) {
      e->mh = 0; e->mt = 0;
      int m[MAXMAPLEN], len; getMap(e, e->level, m, &len);
      for (int i = 0; i < len; i++) mpush(e, m[i]);
      if (e->items_on) addItem(e);
    }
    int t = e->mq[e->mh++];
    createBlock(e, t, nx);
    if (e->items_on) createItem(e, nx, 520);
    deleteItem(e, -BLOCK_W);
    deleteBlock(e);
    e->nextway = e->nextway - BLOCK_W;
  }
  if (e->items_on) eatItem(e);
}

void env_reset(Env *e, uint32_t seed, int level, int count, int phase, int items_on) {
  memset(e, 0, sizeof(Env));
  e->rs = seed; e->irs = seed ^ 0x9E3779B9u; e->level = level; e->count = 0;
  e->speed = 15; for (int l = 1; l <= level; l++) e->speed += (l < 3 ? 3 : 2);
  e->addspeed = 1; e->items_on = items_on;
  for (int i = 0; i < 9; i++) e->parr[i] = -1;
  e->gy = GROUND; e->gx = GX; e->ggrav = GRAVITY; e->status = ST_RUN; e->frame = FR_RUN;
  for (int i = 0; i < 6; i++) createBlock(e, 2, i * BLOCK_W);
  e->count = count;
  gRun(e);
  if (phase) { for (int i = 0; i < e->nb; i++) e->bx[i] -= phase; e->nextway += phase; e->way += phase; }
}

void env_step(Env *e, int pressed) {
  pressed = pressed ? 1 : 0;
  if (!e->dead) {
    if (pressed && !e->pressed) { e->click = 1; if (e->status == ST_RUN) gJump(e); else if (e->status == ST_JUMP) gShoot(e); }
    else if (!pressed && e->pressed) e->click = 0;
  }
  e->pressed = pressed; e->frameNo++; e->steps++;
  if (e->dead) return;
  if (e->finishing && e->stagephase) e->gx += 30; else stageFrame(e);
  if (e->rh == RH_SHOOT) gShootFrame(e); else if (e->rh == RH_ROPE) gRopeFrame(e);
  if (e->gh == GH_RUN) { if (!groundCheck(e)) gameOver(e); }
  else if (e->gh == GH_JUMP) gJumpFrame(e, e->ggrav);
  if (e->finishing && !e->stagephase) e->stagephase = 1;
}


/* ---- look-ahead helpers (pure functions of the visible state) ---- */
static int groundAt(const Env *e, double gy, double shift) {
  double hx0 = 198, hx1 = 202, hy0 = gy + 0.05 - 2, hy1 = gy + 0.05 + 2;
  for (int i = 0; i < e->nb; i++) {
    if (e->bt[i] != 2 && e->bt[i] != 4) continue;
    double bx = e->bx[i] - shift;
    if (hx0 <= bx + 100 && hx1 >= bx - 100 && hy0 <= 403.3 && hy1 >= 353.3) return 1;
  }
  return 0;
}
/* ballistic flight (gJumpFrame physics) with the world scrolling; returns frames until a safe landing, or -1 */
static int flightSim(const Env *e, double gy, double dy, double g, double sp) {
  for (int f = 1; f <= 60; f++) {
    if (dy > -20) dy = dy - g;
    gy = gy - dy;
    if (dy < 0) {
      if (!(gy < GROUND) && groundAt(e, gy, sp * f)) return f;
      if (gy > 470) return -1;
    }
  }
  return -1;
}
/* would a rope shot issued j frames from now (following the current ballistic flight) hook an anchor?
 * returns k (frame of the hit) or 0; *gyc = height of the hero at the hook.  Death / landing before the hook => 0. */
static int catchPredict(const Env *e, int j, double sp, double *gyc) {
  if (e->gh != GH_JUMP || e->status == ST_SHOOT) return 0;
  double gy = e->gy, dy = e->dy, g = e->ggrav;
  for (int f = 1; f <= j; f++) {
    if (dy > -20) dy = dy - g;
    gy = gy - dy;
    if (dy < 0) { if (!(gy < GROUND) && groundAt(e, gy, sp * f)) return 0; if (gy > 470) return 0; }
  }
  if (e->status == ST_SPIN && !(dy < 0)) return 0;
  double ty = gy + -54.4, tx = 12.5 + GX;
  for (int k = 1; k <= 16; k++) {
    if (!(ty > 0)) break;
    ty = ty - 35; tx = tx + 45;
    double shift = sp * (j + k);
    for (int i = 0; i < e->nb; i++) {
      if (e->bt[i] != 3) continue;
      double bx = e->bx[i] - shift;
      if (tx >= bx - 110 && tx <= bx + 100 && ty >= 85 && ty <= 135) { *gyc = gy; return k; }
    }
    if (dy > -20) dy = dy - g;
    gy = gy - dy;
    if (dy < 0) { if (!(gy < GROUND) && groundAt(e, gy, sp * (j + k))) return 0; if (gy > 470) return 0; }
  }
  return 0;
}

/* ---- observation (must match features() in sim.js) ---- */
#define OBS_DIM 64
#define OBS_DIM2 84
static int g_obs_ver = 1;
static float g_alive = 0.02f, g_coinw = 0.0f, g_clear = 2.0f;
void set_obs_version(int v) { g_obs_ver = (v == 2) ? 2 : 1; }
void set_reward(float alive, float coin_w, float clear_bonus) { g_alive = alive; g_coinw = coin_w; g_clear = clear_bonus; }
int obs_dim(void) { return g_obs_ver == 2 ? OBS_DIM2 : OBS_DIM; }
static inline double clampd(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }

/* ---- coin look-ahead (observation v2) ---- */
#define CMAX 640
typedef struct { double cx, cy; int gold, val; } Cand;
static double coinHold(const Env *e, int label, double gy, double rot, double sp, int F, const Cand *c, int n) {
  double r[4]; if (!n || !itemRectAt(e, label, gy, rot, r)) return 0;
  unsigned char taken[CMAX]; memset(taken, 0, (size_t)n); double v = 0;
  for (int f = 1; f <= F; f++) {
    double s = sp * f;
    for (int i = 0; i < n; i++) {
      if (taken[i]) continue;
      double x0, x1, y0, y1; if (c[i].gold) { x0 = -20.35; x1 = 20.4; y0 = -19.85; y1 = 20.9; } else { x0 = -19.8; x1 = 21.1; y0 = -20.35; y1 = 19.85; }
      double cx = c[i].cx - s;
      if (r[0] <= cx + x1 && r[1] >= cx + x0 && r[2] <= c[i].cy + y1 && r[3] >= c[i].cy + y0) { taken[i] = 1; v += c[i].val; }
    }
  }
  return v;
}
static double coinFlight(const Env *e, int label, double gy, double dy, double g, double sp, const Cand *c, int n) {
  if (!n) return 0; unsigned char taken[CMAX]; memset(taken, 0, (size_t)n); double v = 0;
  for (int f = 1; f <= 60; f++) {
    double r[4], s = sp * f;
    if (itemRectAt(e, label, gy, 0, r)) for (int i = 0; i < n; i++) {
      if (taken[i]) continue;
      double x0, x1, y0, y1; if (c[i].gold) { x0 = -20.35; x1 = 20.4; y0 = -19.85; y1 = 20.9; } else { x0 = -19.8; x1 = 21.1; y0 = -20.35; y1 = 19.85; }
      double cx = c[i].cx - s;
      if (r[0] <= cx + x1 && r[1] >= cx + x0 && r[2] <= c[i].cy + y1 && r[3] >= c[i].cy + y0) { taken[i] = 1; v += c[i].val; }
    }
    if (dy > -20) dy = dy - g;
    gy = gy - dy;
    if (dy < 0) { if (!(gy < GROUND) && groundAt(e, gy, s)) break; if (gy > 470) break; }
  }
  return v;
}
static int coinFeatures(const Env *e, float *o, int k, double sp) {
  int lab = e->frame == FR_DIE ? FR_RUN : e->frame; double r0[4]; itemRectAt(e, lab, e->gy, e->bodyRot, r0);
  double icx = (r0[0] + r0[1]) / 2, icy = (r0[2] + r0[3]) / 2; int gv = (int)(50 - e->level * 5 + 0.1);
  Cand cands[CMAX]; int n = 0;
  for (int i = 0; i < e->nbox; i++) for (int j = 0; j < e->boxn[i]; j++) {
    if (!e->calive[i][j]) continue; double cx = e->boxx[i] + e->cox[i][j];
    if (cx >= icx - 60 && cx <= icx + 720 && n < CMAX) { cands[n].cx = cx; cands[n].cy = e->boxy[i] + e->coy[i][j]; cands[n].gold = e->cgold[i][j]; cands[n].val = e->cgold[i][j] ? gv : 5; n++; }
  }
  for (int i = 1; i < n; i++) {   /* stable insertion sort by (cx, cy) */
    Cand key = cands[i]; int j = i - 1;
    while (j >= 0 && (cands[j].cx > key.cx || (cands[j].cx == key.cx && cands[j].cy > key.cy))) { cands[j + 1] = cands[j]; j--; }
    cands[j + 1] = key;
  }
  for (int i = 0; i < 6; i++) {
    if (i < n) { o[k++] = (float)clampd((cands[i].cx - icx) / 300, -1, 2.5); o[k++] = (float)clampd((cands[i].cy - icy) / 200, -2, 2); o[k++] = cands[i].gold ? 1.f : 0.f; }
    else { o[k++] = 2.5f; o[k++] = 0.f; o[k++] = 0.f; }
  }
  double hold = coinHold(e, lab, e->gy, e->bodyRot, sp, 24, cands, n), fv = 0;
  if (e->gh == GH_JUMP) fv = coinFlight(e, lab, e->gy, e->dy, e->ggrav, sp, cands, n);
  else if (e->gh == GH_RUN) fv = coinFlight(e, FR_JUMP, GROUND, DYJUMP * e->addspeed, GRAVITY, sp, cands, n);
  o[k++] = (float)clampd(hold / 100, 0, 3); o[k++] = (float)clampd(fv / 100, 0, 3);
  return k;
}
void env_obs(const Env *e, float *o) {
  double sp = e->speed * e->addspeed; if (sp < 1) sp = 1;
  int k = 0;
  o[k++] = (float)((e->gy - GROUND) / 150.0);
  o[k++] = (float)(e->dy / 30.0);
  for (int s = 0; s < 5; s++) o[k++] = (e->status == s) ? 1.f : 0.f;
  o[k++] = (float)e->click; o[k++] = (float)e->pressed;
  o[k++] = (e->rh == RH_SHOOT) ? 1.f : 0.f; o[k++] = (e->rh == RH_ROPE) ? 1.f : 0.f;
  int ra = e->rh != RH_NONE;
  o[k++] = ra ? (float)((e->tx - GX) / 300.0) : 0.f;
  o[k++] = ra ? (float)((e->ty - e->gy) / 300.0) : 0.f;
  o[k++] = (e->rh == RH_ROPE) ? (float)(e->bodyRot / 90.0) : 0.f;
  o[k++] = (float)(sp / 27.0);
  o[k++] = (float)(e->level / 6.0);
  /* geometry */
  double cur = 198.0; int ch = 1;
  while (ch) { ch = 0; for (int i = 0; i < e->nb; i++) if ((e->bt[i] == 2 || e->bt[i] == 4) && e->bx[i] - 100 <= cur && e->bx[i] + 100 > cur) { cur = e->bx[i] + 100; ch = 1; } }
  double tSupport = (cur - 198.0) / sp;
  double nextStart = 900.0; for (int i = 0; i < e->nb; i++) if ((e->bt[i] == 2 || e->bt[i] == 4) && e->bx[i] - 100 > cur && e->bx[i] - 100 < nextStart) nextStart = e->bx[i] - 100;
  double tNext = (nextStart - 202.0) / sp;
  o[k++] = (float)clampd(tSupport / 20.0, -1, 2);
  o[k++] = (float)clampd(tNext / 30.0, -1, 3);
  o[k++] = (float)clampd((nextStart - cur) / 450.0, -1, 2);
  int na = 0;
  for (int i = 0; i < e->nb && na < 2; i++) if (e->bt[i] == 3 && e->bx[i] + 100 >= 150) {
    double rx = e->bx[i] - 5 - 212.5;
    o[k++] = (float)(rx / 300.0); o[k++] = (float)clampd(rx / (sp * 20.0), -3, 3); o[k++] = 1.f; na++;
  }
  while (na < 2) { o[k++] = 0.f; o[k++] = 0.f; o[k++] = 0.f; na++; }
  for (int i = 0; i < 6; i++) {
    if (i < e->nb) {
      o[k++] = (float)((e->bx[i] - GX) / 300.0);
      o[k++] = (e->bt[i] == 1) ? 1.f : 0.f; o[k++] = (e->bt[i] == 2 || e->bt[i] == 4) ? 1.f : 0.f; o[k++] = (e->bt[i] == 3) ? 1.f : 0.f;
    } else { o[k++] = 2.5f; o[k++] = 0.f; o[k++] = 0.f; o[k++] = 0.f; }
  }
  /* look-ahead features */
  int kc = 0, jfirst = -1, jlast = -1; double gyc0 = 0, gyc = 0;
  for (int j = 0; j < 12; j++) {
    int hit = catchPredict(e, j, sp, &gyc);
    if (j < 4) o[k++] = hit ? 1.f : 0.f;
    if (j == 0) { kc = hit; gyc0 = hit ? gyc : 0; }
    if (hit) { if (jfirst < 0) jfirst = j; jlast = j; }
  }
  o[k++] = (float)(kc / 12.0);
  int fl = (e->gh == GH_JUMP) ? flightSim(e, e->gy, e->dy, e->ggrav, sp) : 0;
  o[k++] = (e->gh == GH_JUMP && fl > 0) ? 1.f : 0.f; o[k++] = (float)(fl > 0 ? fl / 30.0 : 0.0);
  int jl = flightSim(e, GROUND, DYJUMP * e->addspeed, GRAVITY, sp);
  o[k++] = jl > 0 ? 1.f : 0.f; o[k++] = (float)(jl > 0 ? jl / 30.0 : 0.0);
  int sl = (e->rh == RH_ROPE) ? flightSim(e, e->gy, DYJUMP + 15 * e->addspeed, GRAVITY * 1.5, sp) : 0;
  o[k++] = (e->rh == RH_ROPE && sl > 0) ? 1.f : 0.f; o[k++] = (float)(sl > 0 ? sl / 40.0 : 0.0);
  o[k++] = kc ? (float)((gyc0 - GROUND) / 150.0) : 0.f;
  o[k++] = (float)((jfirst + 1) / 12.0); o[k++] = (float)((jlast + 1) / 12.0);
  o[k++] = (e->rh == RH_ROPE) ? (float)clampd((e->tx - 70.0) / sp / 20.0, -1, 2) : 0.f;
  if (g_obs_ver == 2) coinFeatures(e, o, k, sp);
}

/* ---- vector helpers for the trainer ---- */
static inline void step_one(Env *e, int action, float *obs_row, float *rew_row, uint8_t *flag_row, int od) {
  int score0 = e->score;
  env_step(e, action);
  float r = e->dead ? 0.0f : g_alive; uint8_t f = 0;
  if (g_coinw != 0.0f) r += g_coinw * (float)(e->score - score0);
  if (e->dead) { f |= 1; }
  else if (e->cleared) { f |= 2; r += g_clear; }
  else if (e->maxsteps > 0 && e->steps >= e->maxsteps) f |= 4;
  *rew_row = r; *flag_row = f;
  env_obs(e, obs_row); (void)od;
}
void vec_step(Env *envs, int n, const int32_t *act, float *obs, float *rew, uint8_t *flag) {
  const int od = obs_dim();
#ifdef _OPENMP
  #pragma omp parallel for schedule(static)
#endif
  for (int i = 0; i < n; i++) step_one(&envs[i], act[i], obs + (size_t)i * od, &rew[i], &flag[i], od);
}
void vec_obs(const Env *envs, int n, float *obs) {
  const int od = obs_dim();
#ifdef _OPENMP
  #pragma omp parallel for schedule(static)
#endif
  for (int i = 0; i < n; i++) env_obs(&envs[i], obs + (size_t)i * od);
}

/* ---- auto-reset stepping with a built-in curriculum (no Python loop per episode; used by the GPU trainer) ---- */
typedef struct { float level_w[6]; float p_full; int max_steps, full_steps; float p_trans; int items_on; } Curr;
static Curr g_cur = {{1.f/6, 1.f/6, 1.f/6, 1.f/6, 1.f/6, 1.f/6}, 0.1f, 1500, 9000, 0.0f, 0};
void set_curriculum(const float *level_w, float p_full, int max_steps, int full_steps, float p_trans, int items_on) {
  for (int i = 0; i < 6; i++) g_cur.level_w[i] = level_w[i];
  g_cur.p_full = p_full; g_cur.max_steps = max_steps; g_cur.full_steps = full_steps; g_cur.p_trans = p_trans; g_cur.items_on = items_on;
}
static inline uint32_t mix32(uint32_t x) { x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; x ^= x >> 16; return x; }
static void auto_reset(Env *e, uint32_t salt) {
  static const int MAXC[6] = {50, 100, 150, 200, 250, 300}; static const int SPD[6] = {15, 18, 21, 23, 25, 27};
  uint32_t s = mix32(e->rs ^ mix32(salt) ^ (uint32_t)e->frameNo * 2654435761u);
  #define RND() (s = mix32(s + 0x9E3779B9u))
  #define RNDF() ((RND() >> 8) * (1.0f / 16777216.0f))
  int level, count, phase, ms;
  if (RNDF() < g_cur.p_full) { level = 0; count = 0; phase = 0; ms = g_cur.full_steps; }
  else if (RNDF() < g_cur.p_trans) { level = (int)(RNDF() * 5); count = MAXC[level] - (1 + (int)(RNDF() * 13)); phase = (int)(RNDF() * SPD[level]); ms = 450; }
  else {
    float tot = 0; for (int i = 0; i < 6; i++) tot += g_cur.level_w[i];
    float r = RNDF() * tot; level = 5; for (int i = 0; i < 6; i++) { r -= g_cur.level_w[i]; if (r <= 0) { level = i; break; } }
    count = (int)(RNDF() * MAXC[level]); phase = (int)(RNDF() * SPD[level]); ms = g_cur.max_steps;
  }
  uint32_t seed = (RND() & 0x7fffffffu) | 1u;
  env_reset(e, seed, level, count, phase, g_cur.items_on); e->maxsteps = ms;
}
void vec_init_auto(Env *envs, int n, uint32_t salt) {
#ifdef _OPENMP
  #pragma omp parallel for schedule(static)
#endif
  for (int i = 0; i < n; i++) { memset(&envs[i], 0, sizeof(Env)); envs[i].rs = mix32(salt + (uint32_t)i * 0x9E3779B9u); auto_reset(&envs[i], salt ^ (uint32_t)i); }
}
/* tobs/elevel/elen are filled only for rows whose episode ended (flag != 0): terminal observation, level and length of the finished episode;
   obs then holds the FIRST observation of the new episode. */
void vec_step_auto(Env *envs, int n, const int32_t *act, float *obs, float *rew, uint8_t *flag, float *tobs, int32_t *elevel, int32_t *elen) {
  const int od = obs_dim();
#ifdef _OPENMP
  #pragma omp parallel for schedule(static)
#endif
  for (int i = 0; i < n; i++) {
    Env *e = &envs[i]; float *orow = obs + (size_t)i * od;
    step_one(e, act[i], orow, &rew[i], &flag[i], od);
    if (flag[i]) {
      memcpy(tobs + (size_t)i * od, orow, sizeof(float) * (size_t)od); elevel[i] = e->level; elen[i] = e->steps;
      auto_reset(e, (uint32_t)i); env_obs(e, orow);
    }
  }
}
void vec_reset(Env *envs, int i, uint32_t seed, int level, int count, int phase, int maxsteps, int items_on) {
  env_reset(&envs[i], seed, level, count, phase, items_on); envs[i].maxsteps = maxsteps;
}
/* introspection for tests */
double env_get(const Env *e, int what) {
  switch (what) {
    case 0: return e->gy; case 1: return e->dy; case 2: return e->status; case 3: return e->way; case 4: return e->speed;
    case 5: return e->level; case 6: return e->count; case 7: return e->score; case 8: return e->dead; case 9: return e->cleared;
    case 10: return e->tx; case 11: return e->ty; case 12: return e->bodyRot; case 13: return e->nb; case 14: return e->coinsEaten;
    case 15: return e->frame; case 16: return e->click;
  }
  return 0;
}
double env_block(const Env *e, int i, int what) { return what == 0 ? e->bx[i] : e->bt[i]; }

void vec_set_steps(Env *envs, int i, int steps, int maxsteps) { envs[i].steps = steps; envs[i].maxsteps = maxsteps; }
