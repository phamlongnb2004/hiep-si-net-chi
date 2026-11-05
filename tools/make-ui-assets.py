# Tạo tools/ui-assets.json cho màn hình mở đầu từ ảnh ChatGPT vẽ.
# Dùng: python3 tools/make-ui-assets.py <thư_mục_có_bg-island.webp_và_clouds.webp>
import base64, io, json, os, sys
from PIL import Image

src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), 'src')
out = {}

def uri(im, q):
    b = io.BytesIO(); im.save(b, 'WEBP', quality=q, method=6)
    return 'data:image/webp;base64,' + base64.b64encode(b.getvalue()).decode()

bg = Image.open(os.path.join(src, 'bg-island.webp')).convert('RGB')
out['bg'] = uri(bg.resize((1600, round(1600 * bg.height / bg.width)), Image.LANCZOS), 80)
out['bgSmall'] = uri(bg.resize((96, round(96 * bg.height / bg.width)), Image.LANCZOS), 50)

# vị trí 6 đám mây trong tấm ảnh mây (1200 px chiều ngang)
BOXES = [(32, 65, 422, 267), (497, 92, 846, 257), (941, 116, 1160, 247), (16, 334, 429, 558), (472, 402, 838, 529), (889, 379, 1184, 537)]
cl = Image.open(os.path.join(src, 'clouds.webp')).convert('RGBA')
clouds = []
for b in BOXES:
    c = cl.crop(b); c = c.resize((round(c.width * .8), round(c.height * .8)), Image.LANCZOS)
    clouds.append({'u': uri(c, 82), 'w': c.width, 'h': c.height})
out['clouds'] = clouds

p = os.path.join(os.path.dirname(__file__), 'ui-assets.json')
json.dump(out, open(p, 'w'), separators=(',', ':'))
print('ui-assets.json', round(os.path.getsize(p) / 1024), 'KB')
