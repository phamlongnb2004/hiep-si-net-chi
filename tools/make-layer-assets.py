# Cắt lớp mũ và áo choàng (nhìn nghiêng, quay phải) để ghép lên nhân vật
# Dùng: python3 tools/make-layer-assets.py <thư_mục_ảnh>   (đọc <thư_mục>/gear/layer_<phái>.webp: hàng 1 = 4 mũ, hàng 2 = 4 áo choàng)
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import runs, load_rgba, bands

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'layer-assets.json')
MAXS = 150


def cut(path, NR=2, NC=4):
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
            f = MAXS / max(c.size)
            c = c.resize((max(1, round(c.width * f)), max(1, round(c.height * f))), Image.LANCZOS)
            buf = io.BytesIO()
            c.save(buf, 'WEBP', quality=86, method=6)
            row.append({'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(), 'w': c.width, 'h': c.height})
        res.append(row)
    return {'hat': res[0], 'cape': res[1]}


out = {}
for cls in ['sword', 'archer', 'mage', 'fighter']:
    p = os.path.join(SRC, 'gear', f'layer_{cls}.webp')
    if os.path.exists(p):
        out[cls] = cut(p)
        print(cls, 'ok')
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
