# Dựng mảnh mép khối (trái/phải) từ chính dải mặt đất -> khớp màu, khớp mặt trên 100%
# Dùng: python3 tools/make-cap-from-ground.py <vùng> [thư_mục_ảnh]  -> <thư_mục>/side/cap_<vùng>.webp (2 mảnh trên nền trắng)
import sys, os, json, base64, io
import numpy as np
from PIL import Image
th = sys.argv[1]; SRC = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser('~/assets')
d = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'side-assets.json')))
gi = d['ground_' + th]
g = Image.open(io.BytesIO(base64.b64decode(gi['u'].split(',')[1]))).convert('RGBA')
K = 4; g = g.resize((g.width * K, g.height * K), Image.LANCZOS)
G = np.array(g).astype(float); GH, GW = G.shape[:2]
top = int(GH * gi['top'])                               # mặt đi được
# lớp mặt (cỏ/tuyết/đá phiến): từ đỉnh tới hết phần màu mặt; thân đất bên dưới
band = int(GH * .4)
body = G[int(GH * .45):]
PW, PH = 300, 1240
def piece(x0):
    out = np.zeros((PH, PW, 4)); out[:band] = G[:band, x0:x0 + PW]
    y = band; flip = False
    while y < PH:
        blk = body[::-1] if flip else body; h = min(len(blk), PH - y)
        out[y:y + h] = blk[:h, x0:x0 + PW]; y += h; flip = not flip
    return out
rng = np.random.default_rng(7)
wall = 34
n = np.cumsum(rng.normal(0, 1.0, PH)); n = (n - np.convolve(n, np.ones(51) / 51, 'same')) * .9
L = piece(60); A = np.zeros((PH, PW))
xs = np.arange(PW)
for yy in range(PH):
    if yy < band:
        # lớp mặt chìa ra khỏi vách ~16px, mép bo tròn ở dưới (như mái cỏ/tuyết phủ qua mép)
        t = (yy - top) / max(1, band - top)                  # 0 ở mặt đi, 1 ở đáy lớp mặt
        over = 16 * np.sqrt(max(0, 1 - max(0, t) ** 2)) if yy >= top else 16
        edge = wall - over + n[yy] * .6
        a = np.clip((xs - edge) / 3, 0, 1)                   # mép mềm 3px
        A[yy] = a * (L[yy, :, 3] / 255)
    else:
        edge = wall + n[yy]
        A[yy] = np.clip((xs - edge) / 2, 0, 1) * (L[yy, :, 3] / 255)
# tối dần về phía vách (thân đất), bóng dưới mái mặt
for yy in range(band, PH):
    k = .55 + .45 * np.clip((xs - wall) / 52, 0, 1)
    if yy < band + 26: k = k * (.62 + .38 * (yy - band) / 26)
    L[yy, :, :3] *= k[:, None]
    e = int(wall + n[yy]); L[yy, max(0, e):e + 3, :3] *= .5   # viền tối mép vách
L[:, :, 3] = A * 255
R = L[:, ::-1].copy()
sheet = Image.new('RGBA', (PW * 2 + 120, PH + 60), (0, 0, 0, 0))
for i, a in enumerate([L, R]):
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), 'RGBA'); sheet.alpha_composite(im, (30 + i * (PW + 60), 30))
sheet.save(os.path.join(SRC, 'side', f'cap_{th}.webp'), lossless=True)
print('ok', th)
