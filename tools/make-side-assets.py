# Nền cảnh ngang: trời/núi xa, lớp giữa, dải mặt đất, bậc đá nổi cho 3 vùng (cỏ, tuyết, núi lửa)
# Dùng: python3 tools/make-side-assets.py <thư_mục_ảnh>   (đọc <thư_mục>/side/{far,mid,ground,plat}_<vùng>.webp) -> tools/side-assets.json
import sys, os, io, json, base64
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imgcut import load_rgba

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'side-assets.json')


def seamless(im, frac=.12):
    """Ghép mép phải vào mép trái (trộn dần) để lát ngang không lộ đường nối."""
    a = np.array(im).astype(float)
    W = a.shape[1]; b = max(8, int(W * frac))
    t = np.linspace(0, 1, b)[None, :, None]
    a[:, :b] = a[:, :b] * t + a[:, W - b:] * (1 - t)
    return Image.fromarray(a[:, :W - b].clip(0, 255).astype(np.uint8), im.mode)


def top_line(alpha, thr=.6):
    """Hàng đầu tiên mà phần lớn bề ngang đã đặc (mép mặt đất đi được)."""
    cover = (alpha > 128).mean(1)
    rows = np.flatnonzero(cover > thr)
    return int(rows[0]) if len(rows) else 0


def enc(im, w, q=80):
    if im.width > w:
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    buf = io.BytesIO(); im.save(buf, 'WEBP', quality=q, method=6)
    return im, 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode()


out = {}
for th in ['grass', 'snow', 'lava']:
    p = lambda k: os.path.join(SRC, 'side', f'{k}_{th}.webp')
    if os.path.exists(p('far')):
        im = seamless(Image.open(p('far')).convert('RGB'))
        im, u = enc(im, 1280, 76); out['far_' + th] = {'u': u, 'w': im.width, 'h': im.height}
    if os.path.exists(p('mid')):
        im = load_rgba(p('mid')); a = np.array(im)[:, :, 3]
        ys = np.flatnonzero((a > 40).any(1)); im = im.crop((0, ys[0], im.width, ys[-1] + 1))
        im = seamless(im); im, u = enc(im, 1280, 78); out['mid_' + th] = {'u': u, 'w': im.width, 'h': im.height}
    if os.path.exists(p('ground')):
        im = load_rgba(p('ground')); a = np.array(im)[:, :, 3]
        t = top_line(a); t0 = max(0, t - int(im.height * .06))      # giữ chút cỏ/tuyết nhô lên trên mép
        im = im.crop((0, t0, im.width, im.height)); im = seamless(im)
        top = (t - t0) / im.height
        im, u = enc(im, 1024, 80); out['ground_' + th] = {'u': u, 'w': im.width, 'h': im.height, 'top': round(top, 4)}
    if os.path.exists(p('plat')):
        im = load_rgba(p('plat')); a = np.array(im)[:, :, 3] > 40
        ys, xs = np.flatnonzero(a.any(1)), np.flatnonzero(a.any(0))
        im = im.crop((xs[0], ys[0], xs[-1] + 1, ys[-1] + 1)); al = np.array(im)[:, :, 3]
        mid = al[:, int(im.width * .3):int(im.width * .7)]
        top = top_line(mid, .8) / im.height
        im, u = enc(im, 560, 82); out['plat_' + th] = {'u': u, 'w': im.width, 'h': im.height, 'top': round(top, 4)}
    print(th, [k for k in out if k.endswith(th)])
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
