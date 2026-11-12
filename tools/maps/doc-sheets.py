#!/usr/bin/env python3
"""Ảnh cho tài liệu duyệt của một bản đồ: bảng mẫu, vật thể rời, lớp nền, động tác quái, trùm, hiệu ứng.
doc-sheets.py MAPID SRC_DIR OUT_DIR"""
import sys, os, json
from PIL import Image, ImageDraw, ImageFont
H = os.path.dirname(os.path.abspath(__file__)); R = os.path.join(H, '..', '..')
MID, SRC, OUT = sys.argv[1:4]; os.makedirs(OUT, exist_ok=True)
C = json.load(open(f'{H}/maps-b1.json'))[MID]; D = json.load(open(f'{R}/shared/data.json'))
A = f'{R}/client/assets/'; th = C['theme']
F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 22); BG = (236, 242, 250)
def sheet(out, rows, pad=14):
    W = max(sum(i.width for i in r) + pad * (len(r) + 1) for _, r in rows)
    Ht = sum(max(i.height for i in r) + pad + 34 for _, r in rows) + pad
    c = Image.new('RGBA', (W, Ht), BG + (255,)); d = ImageDraw.Draw(c); y = pad
    for lab, r in rows:
        d.text((pad, y), lab, fill=(30, 40, 70), font=F); y += 30; h = max(i.height for i in r); x = pad
        for i in r:
            d.rectangle([x - 2, y - 2, x + i.width + 1, y + h + 1], fill=(250, 252, 255), outline=(205, 214, 230))
            c.alpha_composite(i, (x, y + h - i.height)); x += i.width + pad
        y += h + pad + 4
    c.convert('RGB').save(f'{OUT}/{out}', quality=88)
fr = lambda sp, a: [Image.open(f'{A}mon2/{sp}/{a}{i}.webp').convert('RGBA') for i in range(8)]
sc = lambda L, f: [i.resize((int(i.width * f), int(i.height * f))) for i in L]
fit = lambda L, w: sc(L, min(1, w / sum(i.width + 14 for i in L)))
NM = {'move': 'đi', 'atk': 'đánh', 'idle': 'đứng yên'}
sp = list(C['mons']); boss = sp[-1]
for s in sp[:-1]:
    n = D['mons'][s]['n']; ab = D['mons'][s].get('ab', {}).get('k')
    sheet(f'mon_{s}.jpg', [(f'{n} · đi', fit(fr(s, 'move'), 1700)), (f'{n} · đánh', fit(fr(s, 'atk'), 1700))])
bn = D['mons'][boss]['n']; sk = D['mons'][boss]['sk']
sheet('boss_body.jpg', [(f'{bn} · đứng yên', fit(fr(boss, 'idle'), 1750)), (f'{bn} · đi', fit(fr(boss, 'move'), 1750))])
sheet('boss_skills.jpg', [(f'Chiêu {i+1} · {k["n"]} (thân)', fit(fr(boss, f's{i+1}'), 1750)) for i, k in enumerate(sk)])
vf = lambda n: [Image.open(f'{A}vfx/{n}/{i}.webp').convert('RGBA') for i in range(8)] if os.path.exists(f'{A}vfx/{n}/0.webp') else None
rows = [(f'Hiệu ứng chiêu {i+1} · {k["n"]}', fit(vf(k['fx']), 1700)) for i, k in enumerate(sk) if vf(k['fx'])]
sheet('fx.jpg', rows)
ai = lambda k: Image.open(f'{A}ai/{th}_{k}/u.webp').convert('RGBA')
names = [p.split(':')[0] for p in C['props'].split(',')]
props = [ai(k) for k in names]; props = [i.resize((int(i.width * 180 / i.height), 180)) for i in props]
sd = lambda k: Image.open(f'{A}side/{k}/u.webp').convert('RGBA')
parts = [sd(f'capL_{th}'), sd(f'plat_{th}'), sd(f'capR_{th}')]; parts = [i.resize((int(i.width * .75), int(i.height * .75))) for i in parts]
sheet('kit_objects.jpg', [('Cảnh vật (8 món)', fit(props[:4], 1500)), ('', fit(props[4:], 1500)), ('Mép vách trái · bậc nổi · mép vách phải', parts)])
st = lambda k, w=1300: (lambda i: i.resize((w, int(i.height * w / i.width))))(sd(k))
sheet('kit_layers.jpg', [('Lớp 1 · trời và cảnh xa', [st(f'far_{th}')]), ('Lớp 2 · tầm giữa (nền trong suốt)', [st(f'mid_{th}')]),
                         ('Lớp 3 · dải mặt đất (lát lặp)', [st(f'ground_{th}')]), ('Nền hang trùm', [st(f'far_{th}cave')])])
Image.open(f'{SRC}/{MID}_model.png').convert('RGB').resize((1200, 600)).save(f'{OUT}/model.jpg', quality=88)
print('ok', os.listdir(OUT))
