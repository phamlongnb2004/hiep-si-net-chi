#!/usr/bin/env python3
"""Cắt bảng hiệu ứng (lưới 4x2, nền trắng) thành 8 khung trong suốt, GIỮ nguyên vị trí trong ô
(không căn từng khung), cắt theo khung bao chung của mọi ô.
cut-fx.py SHEET OUTDIR --h 200 [--ground]   (--ground: chừa khoảng dưới để đáy hiệu ứng nằm ở 62% chiều cao,
khớp cách vẽ fx.gd: ảnh đặt từ -0.62h tới +0.38h quanh điểm phát)"""
import argparse, os, json
import numpy as np
from PIL import Image
from scipy import ndimage
ap = argparse.ArgumentParser(); ap.add_argument('sheet'); ap.add_argument('out')
ap.add_argument('--cols', type=int, default=4); ap.add_argument('--rows', type=int, default=2)
ap.add_argument('--h', type=float, default=200); ap.add_argument('--white', type=int, default=238)
ap.add_argument('--ground', action='store_true')
a = ap.parse_args()
im = np.array(Image.open(a.sheet).convert('RGB')).astype(int); H, W = im.shape[:2]
cw, ch = W // a.cols, H // a.rows
cells = []
for r in range(a.rows):
    for c in range(a.cols):
        cell = im[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw]
        lo, hi = cell.min(2), cell.max(2)
        white = (lo > a.white) & (hi - lo < 16)
        lab, n = ndimage.label(white)
        border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        fg = ~np.isin(lab, list(border))
        lab2, n2 = ndimage.label(fg)
        if n2:
            sz = ndimage.sum(fg, lab2, range(1, n2 + 1)); fg = np.isin(lab2, [i + 1 for i, s in enumerate(sz) if s >= 30])
        al = (ndimage.gaussian_filter(fg.astype(float), .6) * 255).clip(0, 255).astype(np.uint8)
        al[~ndimage.binary_dilation(fg, iterations=1)] = 0
        cells.append(np.dstack([cell.astype(np.uint8), al]))
U = np.zeros(cells[0].shape[:2], bool)
for c in cells: U |= c[:, :, 3] > 0
ys, xs = np.flatnonzero(U.any(1)), np.flatnonzero(U.any(0))
x0, x1, y0, y1 = xs[0] - 3, xs[-1] + 4, ys[0] - 3, ys[-1] + 3
# căn giữa ngang quanh tâm ô
cxc = cw / 2; hw = max(cxc - x0, x1 - cxc); x0, x1 = int(cxc - hw), int(cxc + hw)
fh = y1 - y0; fw = x1 - x0
TH = int(fh / .62) if a.ground else fh
sc = a.h / TH
os.makedirs(a.out, exist_ok=True)
for i, c in enumerate(cells):
    cv = Image.new('RGBA', (fw, TH)); src = Image.fromarray(c)
    cv.alpha_composite(src, (-x0, -y0))
    cv.resize((round(fw * sc), round(TH * sc)), Image.LANCZOS).save(f'{a.out}/{i}.webp', quality=86)
print(json.dumps({'w': round(fw * sc), 'h': round(TH * sc)}))
