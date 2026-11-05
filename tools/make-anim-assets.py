# Cắt khung hoạt ảnh nhân vật từ tờ sprite ChatGPT vẽ (2 hàng x 3 cột, nền trong suốt)
# Dùng: python3 tools/make-anim-assets.py <thư_mục_ảnh>   -> tools/anim-assets.json
# Cần: walk_sword.webp, walk_archer.webp, walk_mage.webp, walk_fighter.webp (diện mạo đồ thường)
# và gear/walk_<phái>_<1..3>.webp (diện mạo bộ Hiếm, Sử Thi, Huyền Thoại) nếu có
# Thứ tự khung: 0 đứng, 1-4 bước đi, 5 đánh
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import load_rgba, bands

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
    im = load_rgba(path)
    a = np.array(im)[:, :, 3] > 40
    core = np.array(im)[:, :, 3] > 160          # bỏ quầng sáng mờ khi tìm chỗ chia ô
    rows = bands(core.sum(1) * (core.sum(1) > 2), 2)
    boxes = []
    for y0, y1 in rows:
        cols = bands(core[y0:y1].sum(0) * (core[y0:y1].sum(0) > 1), 3)
        for x0, x1 in cols:
            sub = core[y0:y1, x0:x1]
            ys = np.flatnonzero(sub.any(1))
            boxes.append((x0, y0 + ys[0], x1, y0 + ys[-1] + 1))
    return im, core, boxes


def feet_x(a, b):
    """Tâm x của phần chân (dải 7% dưới cùng), theo toạ độ trong khung."""
    x0, y0, x1, y1 = b
    band = a[y1 - max(4, (y1 - y0) * 7 // 100):y1, x0:x1]
    xs = np.flatnonzero(band.any(0))
    return (xs[0] + xs[-1]) / 2 if len(xs) else (x1 - x0) / 2


res = {}
jobs = []
for cls in ['sword', 'archer', 'mage', 'fighter']:
    # tờ đi bộ cũ (có sẵn mũ/áo choàng) chỉ dùng khi chưa có thân tách lớp
    if not os.path.exists(os.path.join(SRC, 'gear', f'body_{cls}_0.webp')):
        jobs.append((cls, os.path.join(SRC, f'walk_{cls}.webp')))
    # thân không mũ, không áo choàng (mũ và áo choàng ghép riêng theo từng món)
    for t in ('b', 0, 1, 2, 3):   # b = quần áo vải thô khi chưa mặc áo
        p = os.path.join(SRC, 'gear', f'body_{cls}_{t}.webp')
        if os.path.exists(p):
            jobs.append((f'body_{cls}_{t}', p))
# bộ nhớ đệm từng tờ (theo thời gian sửa + dung lượng file nguồn): chạy lại chỉ cắt tờ mới/đổi
CACHE = os.path.join(os.path.dirname(OUT), '.anim-cache')
os.makedirs(CACHE, exist_ok=True)
for cls, path in jobs:
    st_ = os.stat(path)
    ck = os.path.join(CACHE, f'{cls}-{int(st_.st_mtime)}-{st_.st_size}.json')
    if os.path.exists(ck):
        res[cls] = json.load(open(ck))
        continue
    im, a, boxes = frames(path)
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
        # đỉnh đầu theo cột (24 cột, đơn vị hiển thị) để đặt mũ đúng chỗ ở từng khung
        sub = a[b[1]:b[3], b[0]:b[2]]
        tp = []
        for j in range(24):
            x0, x1 = int(sub.shape[1] * j / 24), max(int(sub.shape[1] * (j + 1) / 24), int(sub.shape[1] * j / 24) + 1)
            col = np.flatnonzero(sub[:, x0:x1].any(1))
            tp.append(round(float(col[0] * s * K), 1) if len(col) else round(float(h * K), 1))
        # tâm đầu theo chiều ngang (phần 30% trên cùng), tính từ điểm neo chân: mũ đi theo đầu ở từng khung
        top = sub[:max(1, int(sub.shape[0] * .3))]
        xs = np.nonzero(top)[1]
        hc = round(float((xs.mean() if len(xs) else sub.shape[1] / 2) * s * K - fx * K), 1)
        lst.append({'hc': hc, 'tp': tp, 'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(),
                    'w': round(float(w * K), 1), 'h': round(float(h * K), 1), 'ax': round(float(fx * K), 1)})
    res[cls] = lst
    json.dump(lst, open(ck, 'w'))
    print(cls, [(f['w'], f['h'], f['ax']) for f in lst])

with open(OUT, 'w') as f:
    json.dump(res, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
