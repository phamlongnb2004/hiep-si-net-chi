extends Node
## Dữ liệu chung: luật chơi (data.json, xuất từ shared/data.json) và mô tả ảnh (assets.json).
## Ảnh nằm trong res://assets/...; gói cập nhật ảnh (.pck) có thể ghi đè các file này khi khởi động.

var D: Dictionary = {}        # luật chơi: cls, skills, mons, maps, rar, forge, sets...
var A: Dictionary = {}        # mô tả ảnh: anim, layer, mon, side, ai, gear, fx, hud, ui
var _tex = {}
var fonts = {}

## Nạp ảnh ngầm bằng luồng nền để lần đầu dùng ảnh trong game không bị đứng hình.
## Nhóm ảnh nhân vật, trang bị, hiệu ứng chiêu, giao diện được nạp sẵn ngay khi mở game (warm_all).
## Muốn nhẹ bộ nhớ hơn (~41 MB) thì bỏ "wingfx" khỏi danh sách; ảnh nào chưa nạp sẵn vẫn nạp lúc cần như cũ.
const WARM_GROUPS := ["fx", "vfx", "annfx", "hud", "layer", "gear", "gear2", "acc", "acc2", "anim", "wingfx"]
const WARM_INFLIGHT := 12     # số ảnh nạp nền cùng lúc, đủ nhanh mà không tranh CPU với màn hình đăng nhập
var warm_total := 0           # tổng số ảnh trong đợt nạp sẵn (để thanh tải tính phần trăm)
var _bg: Array = []           # hàng đợi ảnh cần nạp sẵn
var _bg_i := 0
var _pend := {}               # ảnh đã xin nạp nền, chưa nhận về: khóa ảnh -> đường dẫn res://

const NOUN := {
	"sword": {"hat": "Mũ Giáp", "armor": "Giáp Kỵ Sĩ", "cape": "Áo Choàng", "weapon": "Kiếm"},
	"archer": {"hat": "Mũ Trùm", "armor": "Áo Giáp Lá", "cape": "Áo Choàng", "weapon": "Cung"},
	"mage": {"hat": "Nón Phép", "armor": "Pháp Bào", "cape": "Khăn Choàng", "weapon": "Trượng"},
	"fighter": {"hat": "Khăn Đầu", "armor": "Võ Phục", "cape": "Khăn Choàng", "weapon": "Găng Vuốt"}}
const NOUN2 := {"sword": ["Giày Sắt", "Găng Sắt"], "archer": ["Giày Lá", "Bao Tay Cung"], "mage": ["Hài Phép", "Găng Phép"], "fighter": ["Giày Võ", "Bao Tay Võ"]}
const SLOTS := ["hat", "armor", "cape", "weapon", "boots", "gloves", "neck", "wing", "ring", "earring", "belt", "charm"]
const SLOT_N := {"hat": "Mũ", "armor": "Áo", "cape": "Áo choàng", "weapon": "Vũ khí", "boots": "Giày", "gloves": "Găng", "neck": "Dây chuyền", "wing": "Cánh", "ring": "Nhẫn", "earring": "Khuyên tai", "belt": "Đai lưng", "charm": "Bùa hộ mệnh"}
const FREE := ["neck", "wing", "ring", "earring", "belt", "charm"]   # trang sức, cánh: mọi phái đều dùng được
const ACC_NAME := {"neck": ["Dây Chuyền Đồng", "Dây Chuyền Lam Ngọc", "Dây Chuyền Tử Tinh", "Dây Chuyền Thái Dương"], "wing": ["Cánh Thiên Thần", "Cánh Băng Tinh", "Cánh Ma Tinh", "Cánh Phượng Hoàng"]}
## đồ theo bậc cấp (giống shared/rules.js): 10 bậc, tên bộ theo phái + hậu tố độ hiếm
const BAND_SET := {
	"sword": ["Tập Sự", "Thiết Kỵ", "Ngọc Bích", "Hải Long", "Huyết Nguyệt", "Băng Phách", "Ám Dạ", "Thanh Mộc", "Nham Hỏa", "Thiên Đế"],
	"archer": ["Mộc Cung", "Đồng Diệp", "Lục Phong", "Lam Vũ", "Xích Nguyệt", "Tuyết Ưng", "U Linh", "Tinh Linh", "Viêm Điểu", "Thiên Xạ"],
	"mage": ["Học Đồ", "Đồng Chú", "Ngọc Thạch", "Thủy Triều", "Huyết Ấn", "Hàn Băng", "Hư Không", "Sinh Mệnh", "Dung Nham", "Tinh Tú"],
	"fighter": ["Võ Đồng", "Thiết Quyền", "Bích Hổ", "Lam Giao", "Huyết Lang", "Băng Hổ", "Ảnh Sát", "Lục Long", "Hỏa Quyền", "Thần Long"]}
const BAND_ACC := ["Gỗ Mộc", "Đồng Thau", "Bích Ngọc", "Lam Ngọc", "Huyết Ngọc", "Băng Tinh", "Tử Tinh", "Lục Bảo", "Hỏa Tinh", "Thiên Quang"]
const RAR_SUF := ["", " Tinh Xảo", " Cổ Đại", " Thần Thánh"]
const ACC_NOUN := {"neck": "Dây Chuyền", "ring": "Nhẫn", "earring": "Khuyên Tai", "belt": "Đai Lưng", "charm": "Bùa Hộ Mệnh"}

static func band(lvl: int) -> int:
	return clampi(int(floor((lvl - 1) / 10.0)), 0, 9)

## tên món mới (giống itemName ở máy chủ)
func gen_name(slot: String, c: String, r: int, lvl: int) -> String:
	var b = band(lvl)
	if slot == "wing":
		return ACC_NAME.wing[r]
	if slot in FREE:
		return ACC_NOUN[slot] + " " + BAND_ACC[b] + RAR_SUF[r]
	return noun(c, slot) + " " + BAND_SET[c][b] + RAR_SUF[r]

## cấp cần để mặc
static func req_lv(it: Dictionary) -> int:
	return clampi(int(it.get("lvl", 1)), 1, 100)

## món đồ này nhân vật phái c có mặc được không
func can_wear(it: Dictionary, c: String) -> bool:
	return str(it.get("slot", "")) in FREE or str(it.get("cls", "")) == c

func noun(c: String, slot: String) -> String:
	if slot == "boots":
		return NOUN2[c][0]
	if slot == "gloves":
		return NOUN2[c][1]
	return NOUN[c][slot]
const STAT_N := {"atk": "Công", "def": "Thủ", "hp": "Máu", "spd": "Tốc"}
const CLS_KEYS := ["sword", "archer", "mage", "fighter"]

func _ready() -> void:
	reload()
	_load_fonts()

func reload() -> void:
	D = _json("res://data/data.json")
	A = _json("res://assets/assets.json")
	_tex.clear()
	_bg.clear()
	_bg_i = 0
	warm_total = 0

func _json(p: String) -> Dictionary:
	var f = FileAccess.open(p, FileAccess.READ)
	if f == null:
		push_error("Không đọc được " + p)
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}

## ảnh theo đường dẫn tương đối trong assets.json (vd "mon/boar/0/u.webp")
func tex(rel) -> Texture2D:
	if rel == null or str(rel) == "":
		return null
	var k = str(rel)
	if _tex.has(k):
		return _tex[k]
	var t: Texture2D = null
	var p = "res://assets/" + k
	if _pend.has(k):
		var st = ResourceLoader.load_threaded_get_status(_pend[k])
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# ảnh chưa xong: không chặn khung hình và cũng không cache null
			return null
		if st != ResourceLoader.THREAD_LOAD_LOADED:
			_pend.erase(k)
			_tex[k] = null
			return null
		t = ResourceLoader.load_threaded_get(_pend[k])
		_pend.erase(k)
	elif ResourceLoader.exists(p):
		t = load(p)
	_tex[k] = t
	return t

## xin nạp một ảnh ở luồng nền; về sau tex() lấy thẳng từ bộ nhớ đệm
func prefetch(rel) -> bool:
	if rel == null:
		return true
	var k = str(rel)
	if k == "" or _tex.has(k) or _pend.has(k):
		return true
	# giữ giới hạn tải chung, kể cả khi màn hình tải bản đồ yêu cầu thêm ảnh
	if _pend.size() >= WARM_INFLIGHT:
		return false
	var p = "res://assets/" + k
	if not ResourceLoader.exists(p):
		_tex[k] = null
		return true
	if ResourceLoader.load_threaded_request(p) == OK:
		_pend[k] = p
	else:
		# tránh lặp lại một yêu cầu không hợp lệ ở mọi khung hình
		_tex[k] = null
	return true

## true nếu ảnh đã được yêu cầu hoặc đã có kết quả trong cache
func has_tex(rel) -> bool:
	if rel == null:
		return false
	var k = str(rel)
	return _tex.has(k) or _pend.has(k)

## lập danh sách ảnh nhân vật, trang bị, hiệu ứng rồi nạp dần ngầm (gọi một lần sau khi dữ liệu đã nạp xong)
func warm_all() -> void:
	var urls: Array = []
	for g in WARM_GROUPS:
		_collect(A.get(g), urls)
	var seen := {}
	_bg.clear()
	_bg_i = 0
	for u in urls:
		if not seen.has(u):
			seen[u] = true
			_bg.append(u)
	warm_total = _bg.size()

## số ảnh trong đợt nạp sẵn còn chưa xong
func warm_left() -> int:
	return (_bg.size() - _bg_i) + _pend.size()

## gom mọi đường dẫn .webp nằm trong một nhánh của assets.json
static func _collect(v, out: Array) -> void:
	if v is String:
		if v.ends_with(".webp"):
			out.append(v)
	elif v is Array:
		for x in v:
			_collect(x, out)
	elif v is Dictionary:
		for key in v:
			_collect(v[key], out)

func _process(_dt: float) -> void:
	# nhận ảnh đã nạp xong từ luồng nền
	if not _pend.is_empty():
		var done: Array = []
		for k in _pend:
			var st = ResourceLoader.load_threaded_get_status(_pend[k])
			if st == ResourceLoader.THREAD_LOAD_LOADED:
				_tex[k] = ResourceLoader.load_threaded_get(_pend[k])
				done.append(k)
			elif st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_tex[k] = null   # nạp lỗi: giữ như cũ, không thử lại liên tục
				done.append(k)
		for k in done:
			_pend.erase(k)
	# đẩy thêm ảnh vào hàng nạp nền cho đủ WARM_INFLIGHT
	while _bg_i < _bg.size() and _pend.size() < WARM_INFLIGHT - 4:
		if not prefetch(_bg[_bg_i]):
			break
		_bg_i += 1

func _font(fam: String, w: int) -> Font:
	var base = "res://fonts/%s-%d-" % [fam, w]
	var main: FontFile = load(base + "latin.woff2") if ResourceLoader.exists(base + "latin.woff2") else null
	if main == null:
		return ThemeDB.fallback_font
	var fb: Array[Font] = []
	for s in ["vi", "ext"]:
		if ResourceLoader.exists(base + s + ".woff2"):
			fb.append(load(base + s + ".woff2"))
	var v = FontVariation.new()
	v.base_font = main
	v.fallbacks = fb
	return v

func _load_fonts() -> void:
	fonts["title"] = _font("LilitaOne", 400)
	fonts["bold"] = _font("Baloo2", 800)
	fonts["semi"] = _font("Baloo2", 700)
	fonts["body"] = _font("Nunito", 700)
	fonts["body8"] = _font("Nunito", 800)
	fonts["hand"] = _font("PatrickHand", 400)

## ---------- luật chơi phía ứng dụng (chỉ để hiển thị; kết quả thật do máy chủ quyết định) ----------
static func ground_y(m: Dictionary, x: float) -> float:
	var t: Array = m.get("terr", [])
	if t.is_empty():
		return 600.0
	if x <= t[0][0]:
		return t[0][1]
	var lo = 0
	var hi = t.size() - 1
	while hi - lo > 1:
		var mid = (lo + hi) >> 1
		if t[mid][0] <= x:
			lo = mid
		else:
			hi = mid
	var a: Array = t[lo]
	var b: Array = t[hi]
	if b[0] == a[0]:
		return b[1]
	return a[1] + (b[1] - a[1]) * clampf((x - a[0]) / (b[0] - a[0]), 0.0, 1.0)

## ---------- bản đồ nhiều tầng: bậc nổi [x0, y0, x1, y1, kiểu], dây/thang [x, yTrên, yDưới, kiểu], nước/dung nham [x0, x1, y] ----------
static func plat_y(p: Array, x: float) -> float:
	if x < float(p[0]) or x > float(p[2]):
		return INF
	var w = float(p[2]) - float(p[0])
	return float(p[1]) + (float(p[3]) - float(p[1])) * (0.0 if w <= 0 else (x - float(p[0])) / w)

## mặt đứng gần nhất dưới chân (đất hoặc bậc nổi); skip: bỏ qua bậc nổi (đang nhảy xuống xuyên bậc)
static func floor_y(m: Dictionary, x: float, y: float, skip := false, tol := 6.0) -> float:
	var best = ground_y(m, x)
	if skip:
		return best
	for p in m.get("plats", []):
		var py = plat_y(p, x)
		if py != INF and py >= y - tol and py < best:
			best = py
	return best

## dây/thang gần chỗ đứng (trả về mảng dây hoặc rỗng)
static func rope_at(m: Dictionary, x: float, y: float, r := 30.0) -> Array:
	for q in m.get("ropes", []):
		if absf(x - float(q[0])) < r and y >= float(q[1]) - 12 and y <= float(q[2]) + 12:
			return q
	return []

static func in_zone(list: Array, x: float, y: float) -> bool:
	for w in list:
		if x > float(w[0]) and x < float(w[1]) and y > float(w[2]) - 4:
			return true
	return false

static func in_safe(m: Dictionary, x: float) -> bool:
	for z in m.get("safes", []):
		if x > z.x + 8 and x < z.x + z.w - 8:
			return true
	return false

static func exp_need(l: int) -> int:
	return int(floor(30.0 * pow(l, 1.45)))

func item_stat(it: Dictionary, k: String) -> int:
	var st: Dictionary = it.get("st", {})
	return int(round(float(st.get(k, 0)) * (1.0 + 0.12 * float(it.get("up", 0)))))

func sell_price(it: Dictionary) -> int:
	return int(round((4.0 + float(it.lvl) * 2.2) * float(D.rar[int(it.r)].m) * (1.0 + 0.35 * float(it.get("up", 0)))))

func score(it) -> float:
	if it == null or not (it is Dictionary):
		return 0.0
	return item_stat(it, "atk") * 2.0 + item_stat(it, "def") * 1.5 + item_stat(it, "hp") * 0.1 + item_stat(it, "spd") * 0.6

## tham số do máy chủ gửi (admin chỉnh được): giá bình máu, hệ số giá cửa hàng, cộng tỉ lệ rèn, sự kiện, thông báo
var cfg: Dictionary = {}
func pot_price() -> int:
	return int(cfg.get("potPrice", 30))
func shop_mul() -> float:
	return float(cfg.get("shopMul", 1.0))

func forge_info(it: Dictionary) -> Dictionary:
	var L = int(it.get("up", 0)) + 1
	var rate: Array = D.forge.rate
	var lv = float(it.lvl)
	return {"L": L, "rate": clampi(int(rate[min(L - 1, rate.size() - 1)]) + int(cfg.get("forgeBonus", 0)), 1, 100), "stones": L + 1,
		"gold": int(round((40.0 + lv * 6.0) * (1.0 + lv / 3.0) * pow(L, 1.6) * 1.5)), "drop": 0 if L <= 4 else (1 if L <= 9 else 2)}

func rar_color(r: int) -> Color:
	return Color.html(str(D.rar[clampi(r, 0, 3)].c))

func item_name(it: Dictionary) -> String:
	return ("+%d " % int(it.up) if int(it.get("up", 0)) > 0 else "") + str(it.name)

## ảnh biểu tượng của một món đồ (theo phái, bộ, ô)
func item_icon(it: Dictionary) -> Texture2D:
	var g: Dictionary = A.get("gear", {})
	var c = str(it.get("cls", ""))
	var sl = str(it.get("slot", ""))
	# đồ theo bậc cấp (có trường b): ảnh riêng theo bậc
	if it.has("b") and sl != "wing":
		var b = clampi(int(it.b), 0, 9)
		if sl in FREE:
			var ac2: Array = A.get("acc2", {}).get(sl, [])
			if b < ac2.size():
				return tex(ac2[b])
		else:
			var g2: Array = A.get("gear2", {}).get(c, [])
			if b < g2.size() and g2[b] is Dictionary and g2[b].has(sl):
				return tex(g2[b][sl])
	if sl in FREE:
		var ac: Array = A.get("acc", {}).get(sl, [])
		var rr = clampi(int(it.get("r", 0)), 0, 3)
		return tex(ac[rr]) if rr < ac.size() else null
	if g.has(c):
		var row: Array = g[c][clampi(int(it.get("tier", it.get("r", 0))), 0, 3)]
		var si = SLOTS.find(str(it.slot))
		if si >= 0 and si < row.size():
			return tex(row[si])
	return null

## ---------- khu trùm: giờ mở (giống máy chủ, theo giờ Việt Nam) ----------
var clock_off := 0.0   # mili giây: giờ máy chủ - giờ máy này

func now_ms() -> float:
	return Time.get_unix_time_from_system() * 1000.0 + clock_off

func _hms(ms: float) -> String:
	var s = int(ms / 1000.0)
	return ("%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]) if s >= 3600 else ("%d:%02d" % [s / 60, s % 60])

func _vn(ms: float) -> String:
	var s = int((ms + 7 * 3600e3) / 1000.0) % 86400
	return "%02d:%02d" % [s / 3600, (s / 60) % 60]

## trạng thái cổng khu trùm (bản đồ khu trùm mi): {open, text}
func arena_state(mi: int) -> Dictionary:
	var A: Dictionary = D.maps[mi].get("arena", {})
	var cf: Dictionary = cfg.get("arena", {}) if cfg.get("arena") is Dictionary else {}
	var now = now_ms()
	var f = cf.get("now")
	if f is Dictionary and float(f.get("until", 0)) > now:
		return {"open": true, "text": "Đang mở · còn " + _hms(float(f.until) - now)}
	if cf.get("on", true) == false:
		return {"open": false, "text": "Tạm đóng"}
	var slots: Array = cf.get("slots", ["12:00", "19:00", "21:00"])
	var dur: float = float(cf.get("dur", 30)) * 60e3
	var VN = 7 * 3600e3
	var day = floor((now + VN) / 864e5) * 864e5 - VN
	var nxt = INF
	for d in [-1, 0, 1]:
		for sl in slots:
			var p = str(sl).split(":")
			var st = day + d * 864e5 + (int(p[0]) * 60 + (int(p[1]) if p.size() > 1 else 0) + int(A.get("ofs", 0))) * 60e3
			if now >= st and now < st + dur:
				return {"open": true, "text": "Đang mở · còn " + _hms(st + dur - now)}
			if st > now:
				nxt = min(nxt, st)
	if nxt == INF:
		return {"open": false, "text": "Đang đóng"}
	return {"open": false, "text": "Mở lúc %s (còn %s)" % [_vn(nxt), _hms(nxt - now)]}
