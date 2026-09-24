import sys, time
from playwright.sync_api import sync_playwright
html = sys.argv[1]; out = sys.argv[2]; secs = int(sys.argv[3])
with sync_playwright() as p:
    b = p.chromium.launch(args=['--no-sandbox', '--disable-gpu'])
    pg = b.new_page(viewport={'width': 1280, 'height': 900}); logs = []
    pg.on('console', lambda m: logs.append(m.type + ': ' + m.text) if m.type in ('error', 'warning') else None); pg.on('pageerror', lambda e: logs.append('PAGEERROR ' + str(e)))
    pg.goto('file://' + html); pg.wait_for_function('window.__gogunReady === true', timeout=60000)
    print('hardwareConcurrency in this browser:', pg.evaluate('navigator.hardwareConcurrency'))
    pg.evaluate('window.__gogun.setTab("train")')
    pg.select_option('#s-workers', '1')
    pg.click('#t-scratch')
    t0 = time.time()
    while time.time() - t0 < secs:
        time.sleep(10)
        print(f'{time.time()-t0:4.0f}s  iter', pg.inner_text('#m-iter'), '| frames', pg.inner_text('#m-steps'), '| speed', pg.inner_text('#m-sps'), '| ep', pg.inner_text('#m-len'), '| dead', pg.inner_text('#m-dead'), '| model', pg.evaluate('window.__gogun.S.sel'))
    pg.screenshot(path=out + '_train_running.png', full_page=True)
    pg.click('#t-eval')
    for _ in range(40):
        time.sleep(3)
        v = pg.inner_text('#m-eval')
        if v != 'running...': break
    print('eval result:', v)
    pg.click('#t-stop'); time.sleep(1.5)
    print('log tail:', pg.inner_text('#log').split('\n')[-3:])
    print('train-sub:', pg.inner_text('#train-sub'))
    print('problems:', logs or 'none')
    b.close()
