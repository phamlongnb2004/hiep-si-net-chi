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
# mép khối đất (vách trái/phải) do ChatGPT vẽ từ chính dải mặt đất: <SRC>/side/cap_<vùng>.webp (2 mảnh trên nền trắng)
def key_white(im):
    """Xoá nền trắng nối với mép ảnh (chỉ trắng gần tinh khiết để không ăn vào tuyết)."""
    from PIL import ImageDraw, ImageFilter
    px = np.array(im.convert('RGB')).astype(int)
    lo, hi = px.min(2), px.max(2)
    cand = ((lo > 236) & (hi - lo < 14)).astype(np.uint8) * 255
    m = Image.fromarray(cand, 'L').copy(); W, H = m.size
    for xy in [(x, 0) for x in range(0, W, 3)] + [(x, H - 1) for x in range(0, W, 3)] + [(0, y) for y in range(0, H, 3)] + [(W - 1, y) for y in range(0, H, 3)]:
        if m.getpixel(xy) == 255:
            ImageDraw.floodfill(m, xy, 128)
    a = Image.fromarray(np.where(np.array(m) == 128, 0, 255).astype(np.uint8), 'L').filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.7))
    o = im.convert('RGBA'); o.putalpha(a); return o


def caps(path):
    im = Image.open(path)
    im = key_white(im) if np.array(im.convert('RGBA'))[:, :, 3].min() == 255 else im.convert('RGBA')
    a = np.array(im)[:, :, 3] > 100
    cols = np.flatnonzero(a.sum(0) > a.shape[0] * .05)
    # tách 2 mảnh ở khe trống giữa
    gaps = np.flatnonzero(np.diff(cols) > 4)
    mid = (cols[gaps[0]] + cols[gaps[0] + 1]) // 2 if len(gaps) else im.width // 2
    res = {}
    for side, (x0, x1) in (('L', (0, mid)), ('R', (mid, im.width))):
        sub = im.crop((x0, 0, x1, im.height)); sa = np.array(sub)[:, :, 3] > 100
        ys, xs = np.flatnonzero(sa.any(1)), np.flatnonzero(sa.any(0))
        sub = sub.crop((xs[0], ys[0], xs[-1] + 1, ys[-1] + 1)); sa = np.array(sub)[:, :, 3] > 100
        H, W = sa.shape
        # vị trí vách: mép ngoài ở 55-85% chiều cao (thân vách, dưới phần cỏ chìa ra)
        band = sa[int(H * .55):int(H * .85)]
        cs = np.flatnonzero(band.mean(0) > .6)
        wall = (cs[0] if side == 'L' else cs[-1]) if len(cs) else (0 if side == 'L' else W - 1)
        # mặt đi được: hàng đầu tiên phần lõi khối đã đặc
        inner = sa[:, wall + int(W * .2):] if side == 'L' else sa[:, :max(1, wall - int(W * .2))]
        top = top_line(inner.astype(np.uint8) * 255, .85)
        # giữ phần sát vách: phía trong khối chỉ giữ ~bằng bề rộng vách, mờ dần để hoà vào dải mặt đất
        keep = int(W * .62)
        if side == 'L':
            sub = sub.crop((0, 0, min(W, wall + keep), H))
        else:
            c0 = max(0, wall - keep); sub = sub.crop((c0, 0, W, H)); wall -= c0
        arr = np.array(sub).astype(float); h2, w2 = arr.shape[:2]
        fade = int(w2 * .38); ramp = np.linspace(1, 0, fade)
        if side == 'L': arr[:, w2 - fade:, 3] *= ramp[None, :]
        else: arr[:, :fade, 3] *= ramp[::-1][None, :]
        bf = int(h2 * .18); arr[h2 - bf:, :, 3] *= np.linspace(1, 0, bf)[:, None]
        sub = Image.fromarray(arr.clip(0, 255).astype(np.uint8), 'RGBA')
        sub, u = enc(sub, 300, 82)
        k = sub.width / w2
        res[side] = {'u': u, 'w': sub.width, 'h': sub.height, 'top': round(top / h2, 4), 'wall': round(wall / w2, 4)}
    return res


for th in ['grass', 'snow', 'lava']:
    p = os.path.join(SRC, 'side', f'cap_{th}.webp')
    if os.path.exists(p):
        c = caps(p)
        out['capL_' + th] = c['L']; out['capR_' + th] = c['R']
        print('cap', th, {k: (v['w'], v['h'], v['top'], v['wall']) for k, v in c.items()})
with open(OUT, 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('Đã tạo', OUT, round(os.path.getsize(OUT) / 1024), 'KB')
