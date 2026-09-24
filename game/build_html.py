#!/usr/bin/env python3
"""Assemble the single-file HTML:  python3 build_html.py [weights.json] [out.html] [scene.json]"""
import sys, json, os
here = os.path.dirname(os.path.abspath(__file__))
def rd(p): return open(os.path.join(here, p), encoding='utf-8').read()
weights = sys.argv[1] if len(sys.argv) > 1 else 'weights.json'; out = sys.argv[2] if len(sys.argv) > 2 else 'gogun_ai.html'
scene = sys.argv[3] if len(sys.argv) > 3 else os.path.join(here, 'scene.json')
html = rd('template.html')
rep = {'/*DATA_JSON*/': json.dumps(json.load(open(os.path.join(here, 'gogun_data.json'))), separators=(',', ':')),
       '/*SCENE_JSON*/': open(scene, encoding='utf-8').read(),
       '/*WEIGHTS_JSON*/': open(weights if os.path.isabs(weights) else os.path.join(here, weights), encoding='utf-8').read(),
       '/*SIM_JS*/': rd('sim.js'), '/*TRAINER_JS*/': rd('trainer.js'), '/*WORKER_JS*/': rd('worker_glue.js'), '/*RENDER_JS*/': rd('render.js'),
       '/*NETVIEW_JS*/': rd('netview.js'), '/*TRAINCTL_JS*/': rd('trainctl.js'), '/*AUDIO_JS*/': rd('audio.js'), '/*BATTLE_JS*/': rd('battle.js'), '/*APP_JS*/': rd('app.js'),
       '/*AUDIO_JSON*/': open(os.path.join(here, 'sounds.json'), encoding='utf-8').read(), '/*LADDER_JSON*/': open(os.path.join(here, 'ladder.json'), encoding='utf-8').read() if os.path.exists(os.path.join(here, 'ladder.json')) else '[]'}
for k, v in rep.items():
    assert k in html, k
    html = html.replace(k, v)
open(out, 'w', encoding='utf-8').write(html)
print('wrote', out, os.path.getsize(out) // 1024, 'KB')
