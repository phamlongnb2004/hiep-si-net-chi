# Dựng mảnh mép khối (trái/phải) từ chính dải mặt đất -> khớp màu, khớp mặt trên 100%
# Dùng: python3 tools/make-cap-from-ground.py <vùng>   -> <SRC>/side/cap_<vùng>.webp (2 mảnh trên nền trắng, cùng định dạng ảnh ChatGPT)
import sys, os, json, base64, io
import numpy as np
from PIL import Image, ImageFilter
th = sys.argv[1]; SRC = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser('~/assets')
d = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'side-assets.json')))
g = Image.open(io.BytesIO(base64.b64decode(d['ground_' + th]['u'].split(',')[1]))).convert('RGBA')
K = 4; g = g.resize((g.width * K, g.height * K), Image.LANCZOS)
G = np.array(g).astype(float); GH, GW = G.shape[:2]
PW, PH = 300, 940
band = int(GH * .42)                                   # lớp mặt trên (đá phiến + khe dung nham)
body = G[int(GH * .45):]                                # phần đá bên dưới để lát tiếp xuống
def piece(x0):
    out = np.zeros((PH, PW, 4))
    out[:band] = G[:band, x0:x0 + PW]
    y = band; flip = False
    while y < PH:
        blk = body[::-1] if flip else body; h = min(len(blk), PH - y)
        out[y:y + h] = blk[:h, x0:x0 + PW]; y += h; flip = not flip
    return out
rng = np.random.default_rng(3)
def edge_mask(wall):
    m = np.zeros((PH, PW)); n = np.cumsum(rng.normal(0, 1.2, PH)); n = (n - np.convolve(n, np.ones(41) / 41, 'same')) * .8
    for yy in range(PH):
        w = wall + n[yy]
        if yy < band + 6:                             # mặt trên chìa ra một chút, góc bo tròn
            t = yy / (band + 6); w = wall - 10 + (1 - np.sqrt(max(0, 1 - (1 - t) ** 2))) * 0 + (8 if yy < 10 else 0) * (1 - yy / 10)
        m[yy, int(max(0, w)):] = 1
    return m
def shade(a, wall):
    xs = np.arange(PW)[None, :]; s = np.clip((xs - wall) / 46, 0, 1)
    k = .5 + .5 * s; a[:, :, :3] *= k[..., None]
    a[band + 6:, :, :3] *= 1                         # giữ màu
    return a
L = piece(40); wall = 26
mL = edge_mask(wall); L = shade(L, wall); L[:, :, 3] = np.minimum(L[:, :, 3], mL * 255)
# viền tối mép vách
for yy in range(PH):
    xs = np.flatnonzero(mL[yy] > 0)
    if len(xs) and yy > band: L[yy, xs[0]:xs[0] + 3, :3] *= .45
R = L[:, ::-1].copy()
sheet = Image.new('RGB', (PW * 2 + 120, PH + 60), 'white')
for i, a in enumerate([L, R]):
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), 'RGBA'); sheet.paste(im, (30 + i * (PW + 60), 30), im)
sheet.save(os.path.join(SRC, 'side', f'cap_{th}.webp'), lossless=True)
print('ok', th, sheet.size)
