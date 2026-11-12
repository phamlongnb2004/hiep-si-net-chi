#!/usr/bin/env python3
"""Khung nhân vật mặc áo Thần Thoại (tier 4) từ bảng ChatGPT vẽ lại theo tờ tham chiếu bộ Huyền Thoại (tier 3).
make-myth-anim.py SRC_DIR   (SRC_DIR/myth_body_<phái>.png: 6 khung; myth_jd_<phái>.png: 4 nhảy + 4 ngã; myth_climb_<phái>.png: 4 leo)
Mỗi khung mới được thu cùng một tỉ lệ cho cả bảng, đặt vào khung ảnh cùng cỡ với khung tier 3 tương ứng, căn đáy và tâm chân
=> giữ nguyên số đo (tp, hc, ax...) của tier 3 nên mũ, áo choàng, cánh vẫn khớp."""
import sys, os, json
import numpy as np
from PIL import Image
from scipy import ndimage
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
C = f'{R}/client/assets'
SRC = sys.argv[1]
HOLE = float(os.environ.get("HOLE", 1500)) / 724 ** 2   # tóc trắng (quyền thủ): HOLE=1e9 để không đục lỗ
A = json.load(open(f'{C}/assets.json'))

def fg_mask(im):
    a = np.array(im.convert('RGB')).astype(int); lo, hi = a.min(2), a.max(2)
    white = (lo > 232) & (hi - lo < 18)
    lab, n = ndimage.label(white)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    sz = ndimage.sum(white, lab, range(n + 1))
    holes = [i for i in range(1, n + 1) if sz[i] > HOLE * im.height * im.height]  # khoảng trắng lớn bị kẹp (lòng cung, khe tóc)
    fg = ~np.isin(lab, list(border) + holes)
    fg = ndimage.binary_opening(fg, iterations=1)
    return fg

def split(fg, n):
    col = fg.sum(0) > 0
    xs = np.flatnonzero(col)
    gaps = []  # (độ rộng, x0, x1) của các khe trống giữa các phần
    run0 = None
    for x in range(xs[0], xs[-1] + 1):
        if not col[x]:
            if run0 is None: run0 = x
        elif run0 is not None:
            gaps.append((x - run0, run0, x)); run0 = None
    gaps = sorted(gaps, reverse=True)[:n - 1]
    cuts = sorted([(g[1] + g[2]) // 2 for g in gaps])
    edges = [xs[0]] + cuts + [xs[-1] + 1]
    return [(edges[i], edges[i + 1]) for i in range(n)]

def bbox(m):
    ys, xs = np.nonzero(m); return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1

def feet_cx(m, b):
    x0, y0, x1, y1 = b; h = y1 - y0; band = m[y1 - max(3, h * 7 // 100):y1, x0:x1]
    xs = np.nonzero(band)[1]; return x0 + (xs.mean() if len(xs) else (x1 - x0) / 2)

def frames(path, n):
    im = Image.open(path).convert('RGBA'); fg = fg_mask(im)
    arr = np.array(im); arr[:, :, 3] = np.where(fg, 255, 0); im = Image.fromarray(arr)
    out = []
    for x0, x1 in split(fg, n):
        sub = fg[:, x0:x1]; b = bbox(sub); b = (b[0] + x0, b[1], b[2] + x0, b[3])
        out.append((im, fg, b))
    return out

def place(cls, anim, idx, src):
    im, fg, b = src
    ref = Image.open(f'{C}/anim/{anim}_{cls}_3/{idx}/u.webp').convert('RGBA'); rm = np.array(ref)[:, :, 3] > 40; rb = bbox(rm)
    return ref, rm, rb

def build(cls):
    jobs = [('body', f'myth_body_{cls}.png', [('body', i) for i in range(6)], 'body'),
            ('jd', f'myth_jd_{cls}.png', [('jump', i) for i in range(4)] + [('die', i) for i in range(4)], 'jump'),
            ('climb', f'myth_climb_{cls}.png', [('climb', i) for i in range(4)], 'climb')]
    for _, fn, targets, scale_from in jobs:
        p = f'{SRC}/{fn}'
        if not os.path.exists(p): print('thiếu', p); continue
        fr = frames(p, len(targets))
        # tỉ lệ chung cả bảng: trung vị (cao tham chiếu / cao mới) của các khung đứng (không tính khung ngã)
        rs = []
        for (anim, i), (im, fg, b) in zip(targets, fr):
            if anim != scale_from: continue
            ref, rm, rb = place(cls, anim, i, (im, fg, b)); rs.append((rb[3] - rb[1]) / (b[3] - b[1]))
        k = float(np.median(rs))
        for (anim, i), (im, fg, b) in zip(targets, fr):
            ref, rm, rb = place(cls, anim, i, (im, fg, b))
            crop = im.crop(b); crop = crop.resize((max(1, round(crop.width * k)), max(1, round(crop.height * k))), Image.LANCZOS)
            fx = (feet_cx(fg, b) - b[0]) * k; rfx = feet_cx(rm, rb)
            cv = Image.new('RGBA', ref.size)
            cv.alpha_composite(crop, (int(round(rfx - fx)), int(rb[3] - crop.height)))
            d = f'{C}/anim/{anim}_{cls}_4/{i}'; os.makedirs(d, exist_ok=True); cv.save(f'{d}/u.webp', quality=90)
        print(cls, fn, 'tỉ lệ', round(k, 3))
    for anim in ['body', 'jump', 'climb', 'die']:
        if os.path.exists(f'{C}/anim/{anim}_{cls}_4/0/u.webp'):
            A['anim'][f'{anim}_{cls}_4'] = [dict(f, u=f['u'].replace(f'{anim}_{cls}_3/', f'{anim}_{cls}_4/')) for f in A['anim'][f'{anim}_{cls}_3']]

for cls in (sys.argv[2:] or ['sword', 'archer', 'mage', 'fighter']):
    build(cls)
json.dump(A, open(f'{C}/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok')
