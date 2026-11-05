# Cắt hiệu ứng chiêu vẽ trên nền đen (2 hàng x 3 cột) -> ảnh trong suốt (độ sáng thành độ trong)
# Dùng: python3 tools/make-fx-assets.py <thư_mục_ảnh>   (đọc <thư_mục>/gear/fx_<phái>.webp) -> tools/fx-assets.json
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import bands

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fx-assets.json')
MAXS = 200


def unblack(c):
    """Nền đen -> trong suốt: alpha = kênh sáng nhất, màu được khôi phục (bỏ nhân trước)."""
    px = np.array(c.convert('RGB')).astype(float)
    a = px.max(2)
    a = np.clip((a - 12) * 255 / 243, 0, 255)          # bỏ nhiễu gần đen
    s = np.where(a > 0, 255 / np.maximum(px.max(2), 1), 0)[..., None]
    rgb = np.clip(px * s, 0, 255)
    return Image.fromarray(np.dstack([rgb, a]).astype(np.uint8), 'RGBA')


def cut(path):
    im = Image.open(path).convert('RGB')
    L = np.array(im).max(2) > 40
    rows = bands(L.sum(1) * (L.sum(1) > 3), 2)
    res = []
    for y0, y1 in rows:
        cols = bands(L[y0:y1].sum(0) * (L[y0:y1].sum(0) > 3), 3)
        for x0, x1 in cols:
            sub = L[y0:y1, x0:x1]
            ys, xs = np.flatnonzero(sub.any(1)), np.flatnonzero(sub.any(0))
            m = 6
            box = (max(0, x0 + xs[0] - m), max(0, y0 + ys[0] - m), min(im.width, x0 + xs[-1] + 1 + m), min(im.height, y0 + ys[-1] + 1 + m))
            c = unblack(im.crop(box))
            f = MAXS / max(c.size)
            c = c.resize((max(1, round(c.width * f)), max(1, round(c.height * f))), Image.LANCZOS)
            buf = io.BytesIO()
            c.save(buf, 'WEBP', quality=78, method=6)
            res.append({'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(), 'w': c.width, 'h': c.height})
    return res


out = {}
for cls in ['sword', 'mage', 'archer', 'fighter', 'mon']:   # mon = đòn đánh của quái
    p = os.path.join(SRC, 'gear', f'fx_{cls}.webp')
    if os.path.exists(p):
        out[cls] = cut(p)
        print(cls, [(f['w'], f['h']) for f in out[cls]])
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
