#!/usr/bin/env python3
"""Mũ / áo choàng Thần Thoại (bậc 4) ghép lên nhân vật: myth_layer.png = mũ nghiêng, áo choàng nghiêng, mũ sau lưng, áo choàng sau lưng.
make-myth-layer.py SRC_DIR. Mọi phái dùng chung ảnh; số đo ghép (ox, oy, sc, dy...) lấy theo bậc 3 của phái Kiếm (mũ giáp cùng dáng)."""
import sys, os, json
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import unchecker, bands
SRC = sys.argv[1]
C = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'client', 'assets')
A = json.load(open(f'{C}/assets.json'))
im = unchecker(Image.open(f'{SRC}/myth_layer.png').convert('RGB')); a = np.array(im)[:, :, 3] > 40
parts = {}
for k, (x0, x1) in zip(['hat', 'cape', 'hatb', 'capeb'], bands(np.where(a.sum(0) > 1, a.sum(0), 0), 4)):
    sub = a[:, x0:x1]; ys = np.flatnonzero(sub.any(1)); xs = np.flatnonzero(sub.any(0))
    c = im.crop((x0 + xs[0], ys[0], x0 + xs[-1] + 1, ys[-1] + 1)); f = 150 / max(c.size)
    parts[k] = c.resize((max(1, round(c.width * f)), max(1, round(c.height * f))), Image.LANCZOS)
REF = A['layer']['sword']
for cls in ['sword', 'archer', 'mage', 'fighter']:
    L = A['layer'][cls]
    for k, p in parts.items():
        d = f'{C}/layer/{cls}/{k}/4'; os.makedirs(d, exist_ok=True); p.save(f'{d}/u.webp', quality=90)
        r3 = dict(REF[k][3]); e = {kk: v for kk, v in r3.items() if kk not in ('u', 'w', 'h')}
        if k in ('hat', 'cape'):
            e.update(w=p.width, h=p.height)
        elif k == 'hatb':
            h = float(r3['h']) * 1.05; e.update(w=round(h * p.width / p.height, 1), h=round(h, 1))
        else:
            w = float(r3['w']) * 1.15; e.update(w=round(w, 1), h=round(w * p.height / p.width, 1))
        if k == 'hat': e['sc'] = 0.95
        e['u'] = f'layer/{cls}/{k}/4/u.webp'
        L[k] = L[k][:4] + [e]
json.dump(A, open(f'{C}/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok', {k: p.size for k, p in parts.items()})
