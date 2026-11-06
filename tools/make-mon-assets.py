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
# khung khạc của rồng (há mồm, không vẽ lửa): cùng cỡ với khung bay, kèm vị trí miệng ở từng khung
def mouth(sub):
    H, W = sub.shape
    top = sub[:int(H * .75)]
    cols = np.flatnonzero(top.sum(0) >= 2)
    if not len(cols):
        return .92, .38
    xr = cols[-1]; x0 = max(0, xr - int(W * .08))
    ys = np.flatnonzero(top[:, x0:xr + 1].any(1))
    return (xr - W * .03) / W, (ys.mean() if len(ys) else H * .38) / H


for t in ['dragon', 'dragon2', 'dragon3']:
    p = os.path.join(SRC, 'mon', f'breath_{t}.webp')
    if not os.path.exists(p) or t not in out:
        continue
    st = os.stat(p); ck = os.path.join(CACHE, f'{t}_br-v1-{int(st.st_mtime)}-{st.st_size}.json')
    if os.path.exists(ck):
        out[t + '_br'] = json.load(open(ck)); continue
    im, core, boxes = frames(p)
    walk_h = float(np.median([f['hr'] for f in out[t]])) * IDLE_PX
    s = walk_h / float(np.median([b[3] - b[1] for b in boxes]))
    lst = []
    for b in boxes:
        c = im.crop(b); w, h = max(1, round(c.width * s)), max(1, round(c.height * s))
        c = c.resize((w, h), Image.LANCZOS)
        sub = core[b[1]:b[3], b[0]:b[2]]
        band = sub[int(sub.shape[0] * .3):int(sub.shape[0] * .8)]
        xs = np.flatnonzero(band.any(0)); cx = ((xs[0] + xs[-1]) / 2 if len(xs) else sub.shape[1] / 2) * s
        mx, my = mouth(sub)
        buf = io.BytesIO(); c.save(buf, 'WEBP', quality=84, method=6)
        lst.append({'u': 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode(),
                    'hr': round(h / IDLE_PX, 4), 'ar': round(w / h, 4), 'cx': round(cx / IDLE_PX, 4), 'mx': round(mx, 4), 'my': round(my, 4)})
    out[t + '_br'] = lst; json.dump(lst, open(ck, 'w'))
    print(t + '_br', [(f['mx'], f['my']) for f in lst])
# rồng: khớp cỡ + vị trí thân giữa khung bay và khung khạc (không bị phình/nhảy khi đổi khung)
def torso(u):
    a = np.array(Image.open(io.BytesIO(base64.b64decode(u.split(',', 1)[1]))).convert('RGBA'))[:, :, 3] > 120
    H, W = a.shape
    band = a[int(H * .45):int(H * .8)]
    xs = np.flatnonzero(band.sum(0) >= 2)
    x0, x1 = (xs[0], xs[-1]) if len(xs) else (0, W - 1)
    c = (x0 + x1) / 2; half = max(2, int((x1 - x0) * .1))
    ys = np.flatnonzero(a[:, int(c - half):int(c + half) + 1].any(1))
    cy = ((ys[0] + ys[-1]) / 2 / H) if len(ys) else .6
    return (x1 - x0) / H, cy
for t in ['dragon', 'dragon2', 'dragon3']:
    if t not in out:
        continue
    for f in out[t]:
        f['bw'], f['cy'] = (round(float(v), 4) for v in torso(f['u']))
    if t + '_br' in out:
        for f in out[t + '_br']:
            f['bw'], f['cy'] = (round(float(v), 4) for v in torso(f['u']))
        ref = float(np.median([f['bw'] * f['hr'] for f in out[t][1:5]]))
        cur = float(np.median([f['bw'] * f['hr'] for f in out[t + '_br']]))
        k = ref / cur
        for f in out[t + '_br']:
            f['hr'] = round(f['hr'] * k, 4)
        print(t, 'khớp cỡ khung khạc x', round(k, 3))
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
