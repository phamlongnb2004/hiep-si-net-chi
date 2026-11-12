#!/usr/bin/env python3
"""Đưa ảnh quái/trùm/hiệu ứng đã cắt (tools/cut-sheet.py, tools/cut-fx.py) vào client/assets và assets.json.
add-mon-art.py SRC_DIR  (SRC_DIR/<loài>/<động tác><i>.webp, SRC_DIR/fx/<tên>/<i>.webp, SRC_DIR/meta.json)"""
import json, os, shutil, sys
from PIL import Image
SRC = sys.argv[1]
C = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'client', 'assets')
A = json.load(open(f'{C}/assets.json'))
meta = json.load(open(f'{SRC}/meta.json'))
for sp, m in meta.get('mon', {}).items():
    d = f'{C}/mon2/{sp}'; os.makedirs(d, exist_ok=True)
    acts = {}
    # mọi động tác dùng chung một khung (game vẽ mọi khung vào cùng một hình chữ nhật):
    # đặt từng khung vào khung chung, căn đáy và căn theo tâm thân (cx) của động tác đó
    ims = {a: [Image.open(f'{SRC}/{m["dir"]}/{a}{i}.webp').convert('RGBA') for i in range(8)] for a in m['acts']}
    L = max(m['cx'][a] * ims[a][0].width for a in ims); R = max((1 - m['cx'][a]) * ims[a][0].width for a in ims)
    H = max(ims[a][0].height for a in ims); W = int(L + R + 1)
    for a, fr in ims.items():
        for i, im in enumerate(fr):
            cv = Image.new('RGBA', (W, H)); cv.alpha_composite(im, (int(round(L - m['cx'][a] * im.width)), H - im.height))
            cv.save(f'{d}/{a}{i}.webp', quality=88)
        acts[a] = [f'mon2/{sp}/{a}{i}.webp' for i in range(8)]
    A['mon2'][sp] = {'w': W, 'h': H, 'cx': round(L / W, 4), 'a': acts}
    print(sp, W, H, round(L / W, 4), 'thân/khung', round(m['body'] / H, 3))
for nm, v in meta.get('fx', {}).items():
    d = f'{C}/vfx/{nm}'; os.makedirs(d, exist_ok=True)
    for i in range(8): shutil.copy(f'{SRC}/fx/{nm}/{i}.webp', f'{d}/{i}.webp')
    im = Image.open(f'{d}/0.webp')
    A['vfx'][nm] = {'w': im.width, 'h': im.height, 'f': [f'vfx/{nm}/{i}.webp' for i in range(8)], **v}
json.dump(A, open(f'{C}/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok')
