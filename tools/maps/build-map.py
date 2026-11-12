#!/usr/bin/env python3
"""Dựng trọn một bản đồ mới từ các bảng AI vẽ: cắt quái/trùm/hiệu ứng, dựng bộ cảnh, ghi assets.json,
chỉnh chiều cao quái trong shared/data.json theo khung chung, thêm FAR_TOP vào world.gd.
build-map.py SRC_DIR MAPID   (cấu hình trong tools/maps/maps-b1.json)"""
import sys, os, json, subprocess, re
H = os.path.dirname(os.path.abspath(__file__)); R = os.path.join(H, '..', '..')
SRC, MID = sys.argv[1], sys.argv[2]
C = json.load(open(f'{H}/maps-b1.json'))[MID]
OUT = f'/tmp/hsnc-build/{MID}'; os.makedirs(OUT, exist_ok=True)
run = lambda *a: json.loads(subprocess.check_output(['python3', *a]).decode().strip().splitlines()[-1])
meta = {'mon': {}, 'fx': {}}
for sp, mv in C['mons'].items():
    src, body, acts = mv[:3]; xo = ['--keep-holes'] if len(mv) > 3 and mv[3].get('keepHoles') else []
    # src: tên trong file m0x_<src>_<act>.png ; body: chiều cao khung gốc (px) ; acts: danh sách động tác, cái đầu là gốc
    first = run(f'{R}/tools/cut-sheet.py', f'{SRC}/{MID}_{src}_{acts[0]}.png', f'{OUT}/{sp}', acts[0], '--h', str(body), *xo)
    cx = {acts[0]: first['cx']}
    for a in acts[1:]:
        cx[a] = run(f'{R}/tools/cut-sheet.py', f'{SRC}/{MID}_{src}_{a}.png', f'{OUT}/{sp}', a, '--scale', str(first['sc']), *xo)['cx']
    meta['mon'][sp] = {'dir': sp, 'acts': acts, 'cx': cx, 'body': body}
for nm, (src, ground, h) in C['fx'].items():
    if not os.path.exists(f'{SRC}/{MID}_fx_{src}.png'): print('thiếu hiệu ứng', nm); continue
    os.makedirs(f'{OUT}/fx', exist_ok=True)
    run(f'{R}/tools/cut-fx.py', f'{SRC}/{MID}_fx_{src}.png', f'{OUT}/fx/{nm}', '--h', str(h), *(['--ground'] if ground else []))
    meta['fx'][nm] = {}
json.dump(meta, open(f'{OUT}/meta.json', 'w'))
out = subprocess.check_output(['python3', f'{R}/tools/add-mon-art.py', OUT]).decode()
print(out)
# chiều cao vẽ trong game: thân mong muốn / (thân trong khung chung)
D = json.load(open(f'{R}/shared/data.json')); A = json.load(open(f'{R}/client/assets/assets.json'))
for sp, want in C['h'].items():
    ratio = meta['mon'][sp]['body'] / A['mon2'][sp]['h']
    D['mons'][sp]['h'] = round(want / ratio)
json.dump(D, open(f'{R}/shared/data.json', 'w'), ensure_ascii=False, indent=1)
th = C['theme']
res = run(f'{R}/tools/make-kit.py', th, SRC, MID, C['props'])
A = json.load(open(f'{R}/client/assets/assets.json'))
for k in ['ground', 'capL', 'capR', 'plat']:
    A['side'][f'{k}_{th}cave'] = dict(A['side'][f'{k}_{th}'])
json.dump(A, open(f'{R}/client/assets/assets.json', 'w'), ensure_ascii=False, separators=(',', ':'))
W = f'{R}/client/scripts/world.gd'; s = open(W).read()
m = re.search(r'const FAR_TOP := \{(.*)\}', s)
d = dict(re.findall(r'"(\w+)": "(#[0-9a-f]+)"', m.group(1)))
d[th] = res.get('far_top', '#888888'); d[th + 'cave'] = res.get('cave_top', '#222222')
s = s.replace(m.group(0), 'const FAR_TOP := {' + ', '.join(f'"{k}": "{v}"' for k, v in d.items()) + '}')
open(W, 'w').write(s)
print('xong', MID, th, res)
