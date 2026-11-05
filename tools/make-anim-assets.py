# Cắt khung hoạt ảnh nhân vật từ tờ sprite ChatGPT vẽ (2 hàng x 3 cột, nền trong suốt)
# Dùng: python3 tools/make-anim-assets.py <thư_mục_ảnh>   -> tools/anim-assets.json
# Cần: walk_sword.webp, walk_archer.webp, walk_mage.webp, walk_fighter.webp
# Thứ tự khung: 0 đứng, 1-4 bước đi, 5 đánh
import sys, os, io, json, base64
import numpy as np
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'anim-assets.json')
IDLE_H = 230      # chiều cao ảnh lưu của khung đứng (hiển thị = 230 * 0.35 ≈ 80)
K = 0.35          # tỉ lệ ảnh lưu -> đơn vị thế giới


def runs(mask, gap):
    """Các đoạn liên tục True, gộp đoạn cách nhau < gap."""
    idx = np.flatnonzero(mask)
    if not len(idx):
        return []
    out = [[idx[0], idx[0]]]
    for i in idx[1:]:
        if i - out[-1][1] <= gap:
            out[-1][1] = i
        else:
            out.append([i, i])
    return [(a, b + 1) for a, b in out]


def frames(path):
    im = Image.open(path).convert('RGBA')
    a = np.array(im)[:, :, 3] > 40
    H, W = a.shape
    rows = [r for r in runs(a.sum(1) > 2, H // 40) if r[1] - r[0] > H // 6]
    if len(rows) != 2:
        raise SystemExit(f'{path}: tìm thấy {len(rows)} hàng, cần 2')
    boxes = []
    for y0, y1 in rows:
        cols = [c for c in runs(a[y0:y1].sum(0) > 1, W // 60) if c[1] - c[0] > W // 20]
        if len(cols) != 3:
            raise SystemExit(f'{path}: hàng {y0}-{y1} có {len(cols)} cột, cần 3')
        for x0, x1 in cols:
            sub = a[y0:y1, x0:x1]
            ys = np.flatnonzero(sub.any(1))
            boxes.append((x0, y0 + ys[0], x1, y0 + ys[-1] + 1))
    return im, a, boxes


def feet_x(a, b):
    """Tâm x của phần chân (dải 7% dưới cùng), theo toạ độ trong khung."""
    x0, y0, x1, y1 = b
    band = a[y1 - max(4, (y1 - y0) * 7 // 100):y1, x0:x1]
    xs = np.flatnonzero(band.any(0))
    return (xs[0] + xs[-1]) / 2 if len(xs) else (x1 - x0) / 2


res = {}
for cls in ['sword', 'archer', 'mage', 'fighter']:
    im, a, boxes = frames(os.path.join(SRC, f'walk_{cls}.webp'))
    s = IDLE_H / (boxes[0][3] - boxes[0][1])
    # neo chân: lấy tâm chân của khung đứng, các khung đi bộ dùng tâm chân riêng
    lst = []
    for i, b in enumerate(boxes):
        c = im.crop(b)
        w, h = max(1, round(c.width * s)), max(1, round(c.height * s))
        c = c.resize((w, h), Image.LANCZOS)
        buf = io.BytesIO()
        c.save(buf, 'WEBP', quality=86, method=6)
        fx = feet_x(a, b) * s
        if i == 5:  # khung đánh: giữ thân ở chỗ cũ, đòn vươn về trước
            fx = min(fx, w * 0.42)
        lst.append({'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(),
                    'w': round(float(w * K), 1), 'h': round(float(h * K), 1), 'ax': round(float(fx * K), 1)})
    res[cls] = lst
    print(cls, [(f['w'], f['h'], f['ax']) for f in lst])

with open(OUT, 'w') as f:
    json.dump(res, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
