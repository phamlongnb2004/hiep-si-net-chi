#!/usr/bin/env python3
"""Cắt bảng khung động tác do AI vẽ (lưới cột x hàng, nền trắng) thành từng khung trong suốt.

cut-sheet.py SHEET OUTDIR PREFIX [--cols 4 --rows 2 --h 160]
- Mỗi ô: xóa nền trắng bằng loang từ mép (giữ phần trắng bên trong nhân vật), bỏ mảnh vụn nhỏ.
- Mọi khung dùng chung một khung bao (căn theo chân) để nhân vật không nhảy khi chạy hoạt ảnh.
- Lưu OUTDIR/PREFIX0..N.webp, in kích thước khung và tâm ngang (cx) để ghi vào assets.json.
"""
import sys, json, argparse
import numpy as np
from PIL import Image
from scipy import ndimage

ap = argparse.ArgumentParser()
ap.add_argument('sheet'); ap.add_argument('out'); ap.add_argument('prefix')
ap.add_argument('--cols', type=int, default=4); ap.add_argument('--rows', type=int, default=2)
ap.add_argument('--h', type=float, default=160, help='chiều cao khung đích (px)')
ap.add_argument('--scale', type=float, default=0, help='hệ số thu cố định (giữ cùng cỡ thân giữa các bảng)')
ap.add_argument('--white', type=int, default=236)
ap.add_argument('--keep-holes', action='store_true', help='giữ vùng trắng bị bao kín (nhân vật lông trắng)')
ap.add_argument('--keep-fx', action='store_true', help='giữ cả mảnh rời (hiệu ứng), không chỉ khối lớn nhất')
a = ap.parse_args()

im = np.array(Image.open(a.sheet).convert('RGB')).astype(int)
H, W = im.shape[:2]
cells = []
for r in range(a.rows):
    for c in range(a.cols):
        x0, x1 = int(c * W / a.cols), int((c + 1) * W / a.cols)
        y0, y1 = int(r * H / a.rows), int((r + 1) * H / a.rows)
        cell = im[y0:y1, x0:x1]
        white = cell.min(axis=2) > a.white
        lab, n = ndimage.label(white)
        border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        fg = ~np.isin(lab, list(border))
        # khoảng trắng bị bao kín (giữa đuôi và thân...) cũng là nền: vùng trắng tinh, đủ lớn
        vw = (cell.min(axis=2) > 243) & ((cell.max(axis=2) - cell.min(axis=2)) < 10)
        lab3, n3 = ndimage.label(vw)
        if n3 and not a.keep_holes:
            sz3 = ndimage.sum(vw, lab3, range(1, n3 + 1))
            holes = [i + 1 for i, s3 in enumerate(sz3) if s3 > cell.shape[0] * cell.shape[1] * 0.004]
            fg &= ~ndimage.binary_dilation(np.isin(lab3, holes), iterations=1)
        fg = ndimage.binary_opening(fg, iterations=1)
        lab2, n2 = ndimage.label(fg)
        if n2:
            sizes = ndimage.sum(fg, lab2, range(1, n2 + 1))
            big = sizes.max()
            keep = [i + 1 for i, s in enumerate(sizes) if s >= (big * 0.02 if a.keep_fx else big * 0.12)]
            fg = np.isin(lab2, keep)
        # viền mềm 1px
        alpha = (ndimage.gaussian_filter(fg.astype(float), 0.6) * 255).clip(0, 255).astype(np.uint8)
        alpha[~ndimage.binary_dilation(fg, iterations=1)] = 0
        rgba = np.dstack([cell.astype(np.uint8), alpha])
        cells.append(rgba)

# khung bao chung, căn đáy (chân) cùng một đường
boxes = []
for c in cells:
    ys, xs = np.where(c[:, :, 3] > 0)
    boxes.append((xs.min(), ys.min(), xs.max(), ys.max()))
foot = [b[3] for b in boxes]
cxs = [(b[0] + b[2]) / 2 for b in boxes]
h_all = max(b[3] - b[1] for b in boxes) + 4
left = max(cx - b[0] for cx, b in zip(cxs, boxes))
right = max(b[2] - cx for cx, b in zip(cxs, boxes))
# tâm ngang chung = trung bình tâm thân của các khung (không lệch theo vũ khí vung ra)
cxm = float(np.median(cxs))
L = max(cxm - min(b[0] for b in boxes), 1); R = max(max(b[2] for b in boxes) - cxm, 1)
fw, fh = int(L + R + 6), int(h_all + 2)
scale = a.scale or a.h / fh
import os
os.makedirs(a.out, exist_ok=True)
for i, (c, b) in enumerate(zip(cells, boxes)):
    canvas = Image.new('RGBA', (fw, fh))
    src = Image.fromarray(c)
    ox = int(L + 3 - cxm)
    oy = int(fh - 2 - b[3])
    canvas.alpha_composite(src, (max(-10**6, ox), oy))
    out = canvas.resize((max(1, round(fw * scale)), max(1, round(fh * scale))), Image.LANCZOS)
    out.save(f'{a.out}/{a.prefix}{i}.webp', quality=88)
print(json.dumps({'w': round(fw * scale, 1), 'h': round(fh * scale, 1), 'cx': round((L + 3) / fw, 4), 'n': len(cells), 'sc': round(scale, 5)}))
