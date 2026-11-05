# Tiện ích cắt ảnh dùng chung cho các script make-*-assets.py
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def runs(mask, gap, minlen=1):
    """Các đoạn liên tục True (gộp đoạn cách nhau <= gap), bỏ đoạn ngắn hơn minlen."""
    idx = np.flatnonzero(mask)
    out = []
    for i in idx:
        if out and i - out[-1][1] <= gap:
            out[-1][1] = i
        else:
            out.append([i, i])
    return [(a, b + 1) for a, b in out if b + 1 - a >= minlen]


def unchecker(im):
    """Ảnh không có kênh trong suốt thật (nền ô cờ vẽ sẵn): xoá nền sáng xám nối với mép ảnh."""
    px = np.array(im.convert('RGB')).astype(int)
    lo, hi = px.min(2), px.max(2)
    cand = ((lo > 190) & (hi - lo < 22)).astype(np.uint8) * 255
    m = Image.fromarray(cand, 'L').copy()
    W, H = m.size
    border = [(x, 0) for x in range(W)] + [(x, H - 1) for x in range(W)] + [(0, y) for y in range(H)] + [(W - 1, y) for y in range(H)]
    for xy in border:
        if m.getpixel(xy) == 255:
            ImageDraw.floodfill(m, xy, 128)
    bg = np.array(m) == 128
    a = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8), 'L')
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    out = im.convert('RGBA')
    out.putalpha(a)
    return out


def load_rgba(path):
    im = Image.open(path).convert('RGBA')
    if np.array(im)[:, :, 3].min() == 255:
        im = unchecker(im)
    return im


def bands(prof, n):
    """Chia thành n dải: mỗi đường cắt đặt ở chỗ thưa nhất gần vị trí chia đều; bỏ phần trống hai đầu dải."""
    prof = np.asarray(prof, float)
    nz = np.flatnonzero(prof > 0)
    lo, hi = (nz[0], nz[-1] + 1) if len(nz) else (0, len(prof))
    step = (hi - lo) / n
    cuts = [lo]
    for k in range(1, n):
        c = lo + step * k
        a, b = int(c - step * .3), int(c + step * .3) + 1
        cuts.append(a + int(np.argmin(prof[a:b])))
    cuts.append(hi)
    out = []
    for a, b in zip(cuts[:-1], cuts[1:]):
        seg = np.flatnonzero(prof[a:b] > 0)
        out.append((a + seg[0], a + seg[-1] + 1) if len(seg) else (a, b))
    return out
