# Cắt khung hoạt ảnh quái (2 hàng x 3 cột: đứng, 4 bước/vỗ cánh, đánh) từ tờ ChatGPT vẽ
# Dùng: python3 tools/make-mon-assets.py <thư_mục_ảnh>   (đọc <thư_mục>/mon/mon_<loài>.webp) -> tools/mon-assets.json
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import load_rgba, bands

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'mon-assets.json')
IDLE_PX = 150   # chiều cao ảnh lưu của khung đứng
TYPES = ['boar', 'boar2', 'boar3', 'boar4', 'wolf', 'wolf2', 'wolf3', 'wolf4', 'bear', 'bear2', 'bear3', 'dragon', 'dragon2', 'dragon3']
CACHE = os.path.join(os.path.dirname(OUT), '.mon-cache')
os.makedirs(CACHE, exist_ok=True)


def body_only(c):
    """Chỉ giữ mảng liền với thân (loại vệt cào, tia lửa rời). Hơi thở dính miệng rồng: cắt ở cổ họng."""
    from PIL import ImageDraw
    a = np.array(c)[:, :, 3]
    m = Image.fromarray(((a > 40) * 255).astype(np.uint8), 'L').copy()
    H, W = a.shape
    band = a[int(H * .3):int(H * .8)] > 160
    cols = np.flatnonzero(band.sum(0) > band.shape[0] * .35)
    sx = int(np.median(cols)) if len(cols) else W // 2
    ys = np.flatnonzero(a[:, sx] > 160)
    sy = int(np.median(ys)) if len(ys) else H // 2
    ImageDraw.floodfill(m, (sx, sy), 128)
    keep = np.array(m) == 128
    out = np.array(c).copy(); out[:, :, 3] = np.where(keep, out[:, :, 3], 0)
    o = Image.fromarray(out, 'RGBA'); bb = o.getbbox()
    return o.crop(bb) if bb else c


def frames(path):
    im = load_rgba(path)
    core = np.array(im)[:, :, 3] > 160
    rows = bands(core.sum(1) * (core.sum(1) > 2), 2)
    boxes = []
    for y0, y1 in rows:
        cols = bands(core[y0:y1].sum(0) * (core[y0:y1].sum(0) > 1), 3)
        for x0, x1 in cols:
            sub = core[y0:y1, x0:x1]
            ys = np.flatnonzero(sub.any(1)); xs = np.flatnonzero(sub.any(0))
            boxes.append((x0 + xs[0], y0 + ys[0], x0 + xs[-1] + 1, y0 + ys[-1] + 1))
    return im, core, boxes


out = {}
for t in TYPES:
    p = os.path.join(SRC, 'mon', f'mon_{t}.webp')
    if not os.path.exists(p):
        continue
    st = os.stat(p); ck = os.path.join(CACHE, f'{t}-v2-{int(st.st_mtime)}-{st.st_size}.json')
    if os.path.exists(ck):
        out[t] = json.load(open(ck)); continue
    im, core, boxes = frames(p)
    h0 = boxes[0][3] - boxes[0][1]; s = IDLE_PX / h0
    # neo: giữa thân theo chiều ngang của khung đứng (giữ cố định khi đổi khung để không trượt)
    lst = []
    for fi, b in enumerate(boxes):
        c = im.crop(b)
        if fi == 5:
            c = body_only(c)   # khung đánh: bỏ vệt cào/hơi thở vẽ sẵn, hiệu ứng tấn công vẽ riêng trong game
        w, h = max(1, round(c.width * s)), max(1, round(c.height * s))
        c = c.resize((w, h), Image.LANCZOS)
        sub = core[b[1]:b[3], b[0]:b[2]]
        band = sub[int(sub.shape[0] * .25):int(sub.shape[0] * .75)]   # thân giữa, bỏ đầu/đuôi/chân
        xs = np.flatnonzero(band.any(0))
        cx = ((xs[0] + xs[-1]) / 2 if len(xs) else sub.shape[1] / 2) * s
        buf = io.BytesIO(); c.save(buf, 'WEBP', quality=84, method=6)
        lst.append({'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(),
                    'hr': round(h / IDLE_PX, 4), 'ar': round(w / h, 4), 'cx': round(cx / IDLE_PX, 4)})
    out[t] = lst; json.dump(lst, open(ck, 'w'))
    print(t, [(f['hr'], f['ar']) for f in lst])
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
