#!/usr/bin/env python3
"""Headless Chromium end-to-end check of gogun_ai.html:
  1) 4 viewport sizes: every tab renders, no horizontal overflow, no console errors, human click makes the hero jump
  2) coin bug: an eaten coin must disappear (node removed) within 15 frames
  3) no emoji / pictograph characters in the page text
  4) training: START FROM SCRATCH (1 worker) advances iterations and creates a live model; STOP works
  5) EXPORT downloads a valid actor JSON; IMPORT loads it back and selects it
usage: python3 ui_check.py gogun_ai.html [screenshot_prefix]"""
import sys, time, json, re, tempfile, os
from playwright.sync_api import sync_playwright
html = sys.argv[1]; out = sys.argv[2] if len(sys.argv) > 2 else None
VIEWS = [('phone-320', 320, 640, 2), ('phone-390', 390, 844, 2), ('tablet-768', 768, 1024, 1), ('desktop-1280', 1280, 900, 1)]
EMOJI = re.compile('[\u2190-\u21FF\u2300-\u23FF\u2460-\u27BF\u2B00-\u2BFF\U0001F000-\U0001FAFF\uFE0F\u200D\u25CF\u25CB]')
ok = True
def check(name, cond, extra=''):
    global ok; ok = ok and bool(cond); print(('PASS ' if cond else 'FAIL ') + name + (' ' + str(extra) if extra != '' else ''))
with sync_playwright() as p:
    b = p.chromium.launch(args=['--no-sandbox', '--disable-gpu']); problems = []
    for name, vw, vh, dpr in VIEWS:
        ctx = b.new_context(viewport={'width': vw, 'height': vh}, device_scale_factor=dpr, is_mobile=(vw < 600), has_touch=(vw < 600))
        pg = ctx.new_page(); pg.on('pageerror', lambda e: problems.append(name + ' PAGEERROR ' + str(e))); pg.on('console', lambda m: problems.append(name + ' ' + m.text) if m.type == 'error' else None)
        pg.goto('file://' + html); pg.wait_for_function('window.__gogunReady === true', timeout=60000); time.sleep(0.8)
        ov = 0
        for tab in ('play', 'net', 'train', 'info'):
            pg.evaluate(f'window.__gogun.setTab("{tab}")'); time.sleep(0.4)
            if tab == 'net':
                for v in ('graph', 'weights', 'inputs'):
                    pg.click(f'button[data-view="{v}"]'); time.sleep(0.3); ov = max(ov, pg.evaluate('document.documentElement.scrollWidth - document.documentElement.clientWidth'))
                    if out: pg.screenshot(path=f'{out}_{name}_net_{v}.png', full_page=True)
                pg.click('button[data-view="graph"]')
            else:
                ov = max(ov, pg.evaluate('document.documentElement.scrollWidth - document.documentElement.clientWidth'))
                if out: pg.screenshot(path=f'{out}_{name}_{tab}.png', full_page=True)
        pg.evaluate('window.__gogun.setTab("play"); window.__gogun.setPaused(true)'); pg.click('#m-me'); pg.evaluate('window.__gogun.setPaused(true)')
        pg.locator('#cv').click()   # scrolls into view first, then a real click (down+up) at the resolved on-screen position
        pg.evaluate('window.__gogun.stepOnce(); window.__gogun.stepOnce()'); st = pg.evaluate('window.__gogun.sim.status')
        check(f'layout {name}: overflow {ov}px, click -> {st}', ov == 0 and st == 'jump'); ctx.close()
    ctx = b.new_context(viewport={'width': 1100, 'height': 800}, accept_downloads=True); pg = ctx.new_page()
    pg.on('pageerror', lambda e: problems.append('PAGEERROR ' + str(e))); pg.on('console', lambda m: problems.append(m.text) if m.type == 'error' else None)
    pg.goto('file://' + html); pg.wait_for_function('window.__gogunReady === true', timeout=60000)
    # 2) coin removal
    r = pg.evaluate('''(() => { const g = window.__gogun; g.setPaused(true); g.newGame(); let eaten = null;
      for (let i = 0; i < 4000 && !eaten; i++) { g.stepOnce(); for (const box of g.sim.boxes) for (const c of box.all) if (c.eaten && !eaten) eaten = c; }
      if (!eaten) return { err: 'no coin eaten' }; let gone = -1;
      for (let k = 0; k < 30; k++) { const n = g.view.coinNodes.get(eaten); if (n && n.removed) { gone = k; break; } g.stepOnce(); }
      return { gone }; })()''')
    check('coin disappears after being eaten', 'gone' in r and 0 <= r['gone'] <= 15, r)
    # 3) emoji scan of the visible text
    txt = pg.evaluate('document.body.innerText'); check('no emoji / pictograph characters in page text', not EMOJI.search(txt))
    # 4) training from scratch
    pg.evaluate('window.__gogun.setPaused(false); window.__gogun.setTab("train")'); pg.select_option('#s-workers', '1'); pg.click('#t-scratch')
    t0 = time.time(); it = 0
    while time.time() - t0 < 60:
        time.sleep(3); it = int(re.sub(r'\D.*', '', pg.inner_text('#m-iter')) or 0)
        if it >= 4: break
    live = pg.evaluate('!!window.__gogun.models.live && window.__gogun.S.sel === "live"')
    check(f'browser training advances (iteration {it}) and selects the live model', it >= 4 and live)
    pg.click('#t-stop'); time.sleep(1.5); check('STOP returns to idle', 'IDLE' in pg.inner_text('#train-sub'))
    # 5) export / import round trip
    with pg.expect_download() as dl: pg.click('#t-export')
    path = os.path.join(tempfile.gettempdir(), 'gogun_export_test.json'); dl.value.save_as(path); j = json.load(open(path))
    shapes = [(len(l['W']), len(l['W'][0])) for l in j['layers']]
    check('EXPORT writes a 64-H-H-1 actor json', j['obs_dim'] == 64 and shapes[0][0] == 64 and shapes[2][1] == 1, shapes)
    pg.set_input_files('#t-file', path); time.sleep(1.0)
    check('IMPORT loads it and selects it', pg.evaluate('window.__gogun.S.sel') == 'imp')
    print('console/page problems:', problems or 'none'); ok = ok and not problems
    b.close()
print('ALL CHECKS PASSED' if ok else 'SOME CHECKS FAILED'); sys.exit(0 if ok else 1)
