#!/usr/bin/env python3
"""Dựng bộ cảnh cho một chủ đề bản đồ từ các ảnh vật thể rời do AI vẽ trên nền trắng.
make-kit.py THEME SRC_DIR PREFIX   (đọc PREFIX_k_far/mid/ground/parts/props[/cave].png)
Ghi client/assets/side/<loại>_<THEME>/u.webp, client/assets/ai/<THEME>_<tên>/u.webp và mục tương ứng trong assets.json.
Không có ảnh nào là cả bản đồ: bản đồ do game ghép từ các mảnh này (trời, núi xa, lớp giữa, mặt đất, mép vách, bậc nổi, cảnh vật)."""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage
TH, SRC, PRE = sys.argv[1], sys.argv[2], sys.argv[3]
C = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'client', 'assets')
A = json.load(open(f'{C}/assets.json'))
src = lambda k: f'{SRC}/{PRE}_k_{k}.png'

def key_white(im, thr=236):
    px = np.array(im.convert('RGB')).astype(int); lo, hi = px.min(2), px.max(2)
    cand = (lo > thr) & (hi - lo < 16)
    lab, n = ndimage.label(cand)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    a = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8), 'L').filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.7))
    o = im.convert('RGBA'); o.putalpha(a); return o

def seamless(im, frac=.1):
    a = np.array(im).astype(float); W = a.shape[1]; b = max(8, int(W * frac))
    t = np.linspace(0, 1, b)[None, :, None]
    a[:, :b] = a[:, :b] * t + a[:, W - b:] * (1 - t)
    return Image.fromarray(a[:, :W - b].clip(0, 255).astype(np.uint8), im.mode)

def top_line(al, thr=.6):
    rows = np.flatnonzero((al > 128).mean(1) > thr); return int(rows[0]) if len(rows) else 0

def crop(im):
    a = np.array(im)[:, :, 3] > 30; ys, xs = np.flatnonzero(a.any(1)), np.flatnonzero(a.any(0))
    return im.crop((xs[0], ys[0], xs[-1] + 1, ys[-1] + 1))

def save(kind, key, im, w=None, q=84, **meta):
    if w and im.width > w: im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    d = f'{C}/{kind}/{key}'; os.makedirs(d, exist_ok=True); im.save(f'{d}/u.webp', quality=q, method=6)
    A[kind][key] = {'u': f'{kind}/{key}/u.webp', 'w': im.width, 'h': im.height, **meta}
    return im

def pieces(im, n):
    """n vật thể lớn nhất (theo vùng liền), xếp trái->phải, trên->dưới."""
    a = np.array(im)[:, :, 3] > 30
    lab, k = ndimage.label(ndimage.binary_closing(a, iterations=6))
    sz = ndimage.sum(a, lab, range(1, k + 1)); idx = np.argsort(sz)[::-1][:n] + 1
    out = []
    for i in idx:
        sl = ndimage.find_objects((lab == i).astype(int))[0]
        m = (lab[sl] == i)
        p = np.array(im)[sl].copy(); p[:, :, 3] = p[:, :, 3] * m
        out.append(((sl[0].start // (im.height // 2 + 1), sl[1].start), Image.fromarray(p)))
    out.sort(key=lambda t: t[0])
    return [p for _, p in out]

res = {}
if os.path.exists(src('far')):
    im = seamless(Image.open(src('far')).convert('RGB'))
    im = save('side', f'far_{TH}', im, 1472, 80)
    res['far_top'] = '#%02x%02x%02x' % tuple(np.array(im)[:6].reshape(-1, 3).mean(0).astype(int))
if os.path.exists(src('cave')):
    im = seamless(Image.open(src('cave')).convert('RGB'))
    im = save('side', f'far_{TH}cave', im, 1472, 80)
    res['cave_top'] = '#%02x%02x%02x' % tuple(np.array(im)[:6].reshape(-1, 3).mean(0).astype(int))
if os.path.exists(src('mid')):
    im = crop(key_white(Image.open(src('mid')))); im = seamless(im)
    save('side', f'mid_{TH}', im, 1472, 82)
if os.path.exists(src('ground')):
    im = crop(key_white(Image.open(src('ground')))); a = np.array(im)[:, :, 3]
    t = top_line(a); im = seamless(im)
    gi = save('side', f'ground_{TH}', im, 1433, 84, top=round(t / im.height, 4), gh=116.0)
if os.path.exists(src('parts')):
    L, P, R = pieces(key_white(Image.open(src('parts'))), 3)
    for key, im, side in [(f'capL_{TH}', L, 'L'), (f'capR_{TH}', R, 'R')]:
        al = np.array(im)[:, :, 3]; t = top_line(al, .5)
        low = al[int(al.shape[0] * .6):]; cols = np.flatnonzero((low > 128).any(0))
        wall = (cols[0] if side == 'L' else cols[-1]) / al.shape[1]
        save('side', key, im, 360, 86, top=round(t / im.height, 4), wall=round(float(wall), 3), dh=250)
    al = np.array(P)[:, :, 3]; mid = al[:, int(P.width * .3):int(P.width * .7)]
    save('side', f'plat_{TH}', P, 560, 86, top=round(top_line(mid, .8) / P.height, 4))
PROPS = sys.argv[4].split(',') if len(sys.argv) > 4 else []
if os.path.exists(src('props')) and PROPS:
    ps = pieces(key_white(Image.open(src('props'))), len(PROPS))
    for spec, im in zip(PROPS, ps):
        nm, h = spec.split(':'); h = float(h)
        im = save('ai', f'{TH}_{nm}', im, 520, 86); A['ai'][f'{TH}_{nm}']['h'] = h; A['ai'][f'{TH}_{nm}']['w'] = round(h * im.width / im.height, 1)
json.dump(A, open(f'{C}/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print(json.dumps(res), {k: A['side'][k] for k in A['side'] if k.endswith(TH) or k.endswith(TH + 'cave')})
