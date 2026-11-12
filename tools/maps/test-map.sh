#!/bin/bash
# Chụp toàn cảnh + chạy thử một bản đồ mới trên máy chủ thử cục bộ (wrangler dev cổng 8799).
# test-map.sh OUT MAIN_IDX CAVE_IDX WIDTH LV_MAIN LV_BOSS
OUT=$1; MI=$2; CI=$3; W=$4; LV=$5; LB=$6
G=/home/claude/godot/Godot_v4.5.1-stable_linux.x86_64
cd "$(dirname "$0")/../../client" || exit 1
mkdir -p $OUT/b $OUT/pm $OUT/pc
export HSNC_SERVER=http://localhost:8799
HSNC_MAPWAIT=10 HSNC_TOUR_USER=x HSNC_TOUR_ACT=artmaps HSNC_MAPS=$MI timeout 150 xvfb-run -a -s "-screen 0 $((W+100))x1000x24" $G --path . --resolution ${W}x900 -- autotest=$OUT > $OUT/log.txt 2>&1
HSNC_MAPWAIT=10 HSNC_TOUR_USER=x HSNC_TOUR_ACT=artmaps HSNC_MAPS=$CI timeout 150 xvfb-run -a -s "-screen 0 2100x1000x24" $G --path . --resolution 2000x900 -- autotest=$OUT/b > $OUT/logb.txt 2>&1
HSNC_PREVIEW=perf HSNC_MAP=$MI HSNC_X=600 HSNC_Y=600 HSNC_LV=$LV HSNC_AUTO=1 HSNC_SECS=24 HSNC_SHOTEVERY=3 timeout 200 xvfb-run -a -s "-screen 0 1690x780x24" $G --path . --resolution 1690x780 -- autotest=$OUT/pm > $OUT/pm/log.txt 2>&1
HSNC_PREVIEW=perf HSNC_MAP=$CI HSNC_X=500 HSNC_Y=600 HSNC_LV=$LB HSNC_AUTO=1 HSNC_SECS=24 HSNC_SHOTEVERY=1 timeout 200 xvfb-run -a -s "-screen 0 1690x780x24" $G --path . --resolution 1690x780 -- autotest=$OUT/pc > $OUT/pc/log.txt 2>&1
grep -h "SCRIPT ERROR" $OUT/*.txt $OUT/p*/log.txt | head -3
grep AUTO $OUT/pm/log.txt | tail -2; grep AUTO $OUT/pc/log.txt | tail -2
python3 - "$OUT" "$MI" "$CI" "$W" <<'P'
import sys, os
from PIL import Image
o, mi, ci, w = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
d = f'{o}/doc'; os.makedirs(d, exist_ok=True)
a = Image.open(f'{o}/map{mi:02d}.png').convert('RGB'); h = w // 2
a.crop((0, 100, h, 900)).resize((1800, round(800 * 1800 / h))).save(f'{d}/map_a.jpg', quality=88)
a.crop((h, 100, w, 900)).resize((1800, round(800 * 1800 / h))).save(f'{d}/map_b.jpg', quality=88)
Image.open(f'{o}/b/map{ci:02d}.png').convert('RGB').crop((0, 100, 2000, 900)).resize((1500, 600)).save(f'{d}/cave.jpg', quality=88)
for k in ['pm', 'pc']:
    fs = sorted(f for f in os.listdir(f'{o}/{k}') if f.startswith('t') and f.endswith('.png'))
    ims = [Image.open(f'{o}/{k}/{f}').convert('RGB').crop((150, 120, 1450, 720)).resize((433, 200)) for f in fs]
    c = Image.new('RGB', (433 * 5, 200 * ((len(ims) + 4) // 5)))
    for i, im in enumerate(ims): c.paste(im, ((i % 5) * 433, (i // 5) * 200))
    c.save(f'{o}/{k}_sheet.jpg')
P
