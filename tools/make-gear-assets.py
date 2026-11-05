# Cắt icon trang bị: mỗi phái một tờ 4 hàng (Thường, Hiếm, Sử Thi, Huyền Thoại) x 4 cột (mũ, áo, áo choàng, vũ khí)
# Dùng: python3 tools/make-gear-assets.py <thư_mục_ảnh>   (đọc <thư_mục>/gear/icons_<phái>.webp) -> tools/gear-assets.json
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import runs, load_rgba, bands

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gear-assets.json')
SIZE = 96


def grid(path, NR=4, NC=4):
    im = load_rgba(path)
    a = np.array(im)[:, :, 3] > 40
    H, W = a.shape
    rows = bands(np.where(a.sum(1) > 2, a.sum(1), 0), NR)
    res = []
    for y0, y1 in rows:
        cols = bands(np.where(a[y0:y1].sum(0) > 1, a[y0:y1].sum(0), 0), NC)
        row = []
        for x0, x1 in cols:
            ys = np.flatnonzero(a[y0:y1, x0:x1].any(1))
            c = im.crop((x0, y0 + ys[0], x1, y0 + ys[-1] + 1))
            m = max(c.width, c.height)
            sq = Image.new('RGBA', (m, m), (0, 0, 0, 0))
            sq.paste(c, ((m - c.width) // 2, (m - c.height) // 2))
            sq = sq.resize((SIZE, SIZE), Image.LANCZOS)
            buf = io.BytesIO()
            sq.save(buf, 'WEBP', quality=84, method=6)
            row.append('data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode())
        res.append(row)
    return res


out = {}
for cls in ['sword', 'archer', 'mage', 'fighter']:
    p = os.path.join(SRC, 'gear', f'icons_{cls}.webp')
    if os.path.exists(p):
        out[cls] = grid(p)
        print(cls, 'ok')
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
