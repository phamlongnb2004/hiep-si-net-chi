# Cắt icon kỹ năng + icon nút từ tờ icon ChatGPT vẽ (nền trong suốt)
# Dùng: python3 tools/make-hud-assets.py <thư_mục_ảnh>   -> tools/hud-assets.json
# Cần: skill_icons.webp (4 hàng x 6), ui_icons.webp (3 hàng x 4)
import sys, os, io, json, base64
import numpy as np
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'hud-assets.json')


def runs(mask, gap, minlen):
    idx = np.flatnonzero(mask)
    out = []
    for i in idx:
        if out and i - out[-1][1] <= gap:
            out[-1][1] = i
        else:
            out.append([i, i])
    return [(a, b + 1) for a, b in out if b + 1 - a >= minlen]


def unchecker(im):
    """Ảnh không có kênh trong suốt thật (nền ô cờ vẽ sẵn): xoá nền sáng nối với mép ảnh."""
    from PIL import ImageDraw, ImageFilter
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


def grid(path, nr, nc, size):
    im = Image.open(path).convert('RGBA')
    if np.array(im)[:, :, 3].min() == 255:
        im = unchecker(im)
    a = np.array(im)[:, :, 3] > 40
    H, W = a.shape
    rows = runs(a.sum(1) > 2, 3, H // (nr * 3))
    if len(rows) != nr:
        raise SystemExit(f'{path}: {len(rows)} hàng, cần {nr}')
    res = []
    for y0, y1 in rows:
        cols = runs(a[y0:y1].sum(0) > 2, 3, W // (nc * 3))
        if len(cols) != nc:
            raise SystemExit(f'{path}: hàng {y0} có {len(cols)} cột, cần {nc}')
        for x0, x1 in cols:
            sub = a[y0:y1, x0:x1]
            ys = np.flatnonzero(sub.any(1))
            b = (x0, y0 + ys[0], x1, y0 + ys[-1] + 1)
            c = im.crop(b)
            # đặt vào ô vuông, giữ tỉ lệ
            m = max(c.width, c.height)
            sq = Image.new('RGBA', (m, m), (0, 0, 0, 0))
            sq.paste(c, ((m - c.width) // 2, (m - c.height) // 2))
            sq = sq.resize((size, size), Image.LANCZOS)
            buf = io.BytesIO()
            sq.save(buf, 'WEBP', quality=85, method=6)
            res.append('data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode())
    return res


out = {}
sk = grid(os.path.join(SRC, 'skill_icons.webp'), 4, 6, 112)
out['skills'] = {c: sk[i * 6:(i + 1) * 6] for i, c in enumerate(['sword', 'mage', 'archer', 'fighter'])}
p = os.path.join(SRC, 'ui_icons.webp')
if os.path.exists(p):
    names = ['atk', 'pot', 'bag', 'roll', 'book', 'menu', 'chat', 'map', 'gold', 'stone', 'lock', 'talk']
    out['ui'] = dict(zip(names, grid(p, 3, 4, 112)))
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
