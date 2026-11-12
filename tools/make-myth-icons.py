#!/usr/bin/env python3
"""Biểu tượng đồ Thần Thoại, sách kĩ năng, khung ô đồ Thần Thoại và lớp ánh lấp lánh.
make-myth-icons.py SRC_DIR  (wb2_mythic1b.png: mũ, giáp, áo choàng, găng, giày; wb2_mythic2.png: dây chuyền, nhẫn, khuyên, đai, bùa;
wb2_book.png; wb2_frame.png; wb2_frame_fx.png: 4x2 khung ánh)"""
import sys, os, json
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import unchecker, bands
SRC = sys.argv[1]
C = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'client', 'assets')
O = f'{C}/myth'; os.makedirs(f'{O}/fx', exist_ok=True)
A = json.load(open(f'{C}/assets.json'))
ICON = 128

def fit(im, S, pad=0):
    a = np.array(im)[:, :, 3] > 20; ys, xs = np.nonzero(a)
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    f = (S - 2 * pad) / max(im.size); im = im.resize((max(1, round(im.width * f)), max(1, round(im.height * f))), Image.LANCZOS)
    cv = Image.new('RGBA', (S, S)); cv.alpha_composite(im, ((S - im.width) // 2, (S - im.height) // 2)); return cv

def row(path, names):
    im = unchecker(Image.open(path).convert('RGB')); a = np.array(im)[:, :, 3] > 40
    out = {}
    for n, (x0, x1) in zip(names, bands(np.where(a.sum(0) > 1, a.sum(0), 0), len(names))):
        out[n] = fit(im.crop((x0, 0, x1, im.height)), ICON, 2)
    return out

def unwhite(im, inner):
    """Lòng khung: nền trắng -> trong suốt nhưng giữ quầng sáng màu (tách màu khỏi nền trắng)."""
    a = np.array(im.convert('RGB')).astype(float) / 255; x0, y0, x1, y1 = inner
    sub = a[y0:y1, x0:x1]; al = np.clip((1 - sub.min(2)) * 1.6, 0, 1)
    col = np.where(al[..., None] > 0.01, 1 - (1 - sub) / np.maximum(al[..., None], 1e-3), 0)
    out = np.array(im.convert('RGBA')).astype(float) / 255
    out[y0:y1, x0:x1, :3] = np.clip(col, 0, 1); out[y0:y1, x0:x1, 3] = np.minimum(out[y0:y1, x0:x1, 3], al)
    return Image.fromarray((out * 255).astype(np.uint8))

def inner_rect(im):
    g = np.array(im.convert('RGB')).min(2); H, W = g.shape; cy, cx = H // 2, W // 2
    def scan(line, c, d):
        i = c
        while 0 < i < len(line) - 1 and line[i] > 150: i += d
        return i
    l = scan(g[cy], cx, -1); r = scan(g[cy], cx, 1); t = scan(g[:, cx], cy, -1); b = scan(g[:, cx], cy, 1)
    m = 3; return (l + m, t + m, r - m + 1, b - m + 1)

def frame(im):
    rgb = im.convert('RGB'); out = unchecker(rgb); inr = inner_rect(rgb)
    return unwhite(out, inr)

icons = row(f'{SRC}/wb2_mythic1b.png', ['hat', 'armor', 'cape', 'gloves', 'boots'])
icons.update(row(f'{SRC}/wb2_mythic2.png', ['neck', 'ring', 'earring', 'belt', 'charm']))
M = {'icon': {}}
for k, im in icons.items():
    im.save(f'{O}/{k}.webp', quality=90); M['icon'][k] = f'myth/{k}.webp'
fit(unchecker(Image.open(f'{SRC}/wb2_book.png').convert('RGB')), ICON, 2).save(f'{O}/book.webp', quality=90); M['book'] = 'myth/book.webp'
fr = frame(Image.open(f'{SRC}/wb2_frame.png')); fit(fr, 160).save(f'{O}/frame.webp', quality=92); M['frame'] = 'myth/frame.webp'
fx = Image.open(f'{SRC}/wb2_frame_fx.png').convert('RGB'); W, H = fx.size
M['fx'] = []
for j in range(2):
    for i in range(4):
        c = fx.crop((i * W // 4, j * H // 2, (i + 1) * W // 4, (j + 1) * H // 2))
        fit(frame(c), 160).save(f'{O}/fx/{j * 4 + i}.webp', quality=90); M['fx'].append(f'myth/fx/{j * 4 + i}.webp')
A['myth'] = M
json.dump(A, open(f'{C}/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok', list(M['icon']))
