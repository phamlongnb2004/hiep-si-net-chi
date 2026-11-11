extends Node
## Dữ liệu chung: luật chơi (data.json, xuất từ shared/data.json) và mô tả ảnh (assets.json).
## Ảnh nằm trong res://assets/...; gói cập nhật ảnh (.pck) có thể ghi đè các file này khi khởi động.

var D: Dictionary = {}        # luật chơi: cls, skills, mons, maps, rar, forge, sets...
var A: Dictionary = {}        # mô tả ảnh: anim, layer, mon, side, ai, gear, fx, hud, ui
var _tex = {}
var fonts = {}

const NOUN := {
	"sword": {"hat": "Mũ Giáp", "armor": "Giáp Kỵ Sĩ", "cape": "Áo Choàng", "weapon": "Kiếm"},
	"archer": {"hat": "Mũ Trùm", "armor": "Áo Giáp Lá", "cape": "Áo Choàng", "weapon": "Cung"},
	"mage": {"hat": "Nón Phép", "armor": "Pháp Bào", "cape": "Khăn Choàng", "weapon": "Trượng"},
	"fighter": {"hat": "Khăn Đầu", "armor": "Võ Phục", "cape": "Khăn Choàng", "weapon": "Găng Vuốt"}}
const NOUN2 := {"sword": ["Giày Sắt", "Găng Sắt"], "archer": ["Giày Lá", "Bao Tay Cung"], "mage": ["Hài Phép", "Găng Phép"], "fighter": ["Giày Võ", "Bao Tay Võ"]}
const SLOTS := ["hat", "armor", "cape", "weapon", "boots", "gloves", "neck", "wing", "ring", "earring", "belt", "charm"]
const SLOT_N := {"hat": "Mũ", "armor": "Áo", "cape": "Áo choàng", "weapon": "Vũ khí", "boots": "Giày", "gloves": "Găng", "neck": "Dây chuyền", "wing": "Cánh", "ring": "Nhẫn", "earring": "Khuyên tai", "belt": "Đai lưng", "charm": "Bùa hộ mệnh", "egg": "Trứng"}
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

func _json(p: String) -> Dictionary:
	var f = FileAccess.open(p, FileAccess.READ)
	if f == null:
		push_error("Không đọc được " + p)
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}

## ảnh theo đường dẫn tương đối trong assets.json (vd "mon/boar/0/u.webp")
var hitch_watch := false      # bật sau màn hình chờ: ghi lại ảnh nạp muộn (gây khựng)
var late_loads: Array = []
func tex(rel) -> Texture2D:
	if rel == null or str(rel) == "":
		return null
	var k = str(rel)
	if _tex.has(k):
		return _tex[k]
	if not _sync_tex:
		return tex_async(rel)
	var t: Texture2D = null
	var p = "res://assets/" + k
	var t0 = Time.get_ticks_usec()
	if ResourceLoader.exists(p):
		t = load(p)
	_tex[k] = t
	# đo khựng: ảnh phải nạp ngay giữa lúc chơi (chưa nạp trước ở màn hình chờ)
	if hitch_watch:
		var ms = (Time.get_ticks_usec() - t0) / 1000.0
		late_loads.append([k, ms])
		if late_loads.size() > 200:
			late_loads.pop_front()
	return t

## nạp ảnh ở luồng nền (đồ rơi khi đang đánh): chưa xong thì trả null, khung hình không bị khựng
var _async_on := false
func tex_async(rel) -> Texture2D:
	if rel == null or str(rel) == "":
		return null
	var k = str(rel)
	if _tex.has(k):
		return _tex[k]
	var p = "res://assets/" + k
	if not ResourceLoader.exists(p):
		_tex[k] = null
		return null
	var st = ResourceLoader.load_threaded_get_status(p)
	if st == ResourceLoader.THREAD_LOAD_LOADED:
		_tex[k] = ResourceLoader.load_threaded_get(p)
		return _tex[k]
	if st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or st == ResourceLoader.THREAD_LOAD_FAILED:
		if ResourceLoader.load_threaded_request(p) != OK:
			_tex[k] = load(p)
			return _tex[k]
	return null

## đường dẫn ảnh của đồ (không nạp)
var _sync_tex := true
func item_icon_async(it: Dictionary) -> Texture2D:
	_sync_tex = false
	var t = item_icon(it)
	_sync_tex = true
	return t

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
	# 75% giá cửa hàng của món cùng cấp; đồ hiếm và đồ đã rèn bán cao hơn (khớp shared/rules.js sellPrice)
	var lv = float(it.lvl)
	var shop = round((25.0 + lv * 9.0) * (1.0 + lv / 3.0) * 3.5 * float(cfg.get("shopMul", 1.0)))
	var rm = [1.0, 1.3, 1.7, 2.2][clampi(int(it.r), 0, 3)]
	return int(round(shop * 0.75 * rm * (1.0 + 0.15 * float(it.get("up", 0)))))

## so mã đồ an toàn: đồ rơi mang mã số, đồ cửa hàng mang mã chữ ("s…"); so int với String trong GDScript là lỗi
## (lỗi làm hàm vẽ ô bỏ dở → ô đồ cửa hàng biến mất, túi trông như bị đảo lộn sau khi chạm một món)
static func same_id(a, b) -> bool:
	if a == null or b == null:
		return false
	return str(a) == str(b)

func score(it) -> float:
	if it == null or not (it is Dictionary):
		return 0.0
	return item_stat(it, "atk") * 2.0 + item_stat(it, "def") * 1.5 + item_stat(it, "hp") * 0.1 + item_stat(it, "spd") * 0.6

## tham số do máy chủ gửi (admin chỉnh được): giá bình máu, hệ số giá cửa hàng, cộng tỉ lệ rèn, sự kiện, thông báo
var cfg: Dictionary = {}
## bình 3 cỡ (khớp shared/rules.js POT_TIERS)
## hồi lượng cố định: nhỏ cho cấp thấp, vừa cho cấp giữa, lớn cho cấp cao; tối đa 999 mỗi loại
const POT_T := [{"n": "Nhỏ", "hp": 150, "ki": 60, "p": 20}, {"n": "Vừa", "hp": 600, "ki": 200, "p": 80}, {"n": "Lớn", "hp": 1500, "ki": 450, "p": 250}]
const POT_MAX := 999
const HP_KEYS := ["potS", "pots", "potL"]
const KI_KEYS := ["kpotS", "kpots", "kpotL"]
func pot_total(d: Dictionary, ki: bool) -> int:
	var n = 0
	for k in (KI_KEYS if ki else HP_KEYS):
		n += int(d.get(k, 0))
	return n
func pot_icon(ki: bool, t: int) -> Texture2D:
	var ui: Dictionary = A.get("hud", {}).get("ui", {})
	var k = ("kpot%d" if ki else "pot%d") % t
	return tex(ui.get(k, ui.get("pot", "")))
func tier_price(t: int) -> int:
	return int(round(float(POT_T[t].p) * pot_price() / 30.0))

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
	return ("+%d " % int(it.up) if int(it.get("up", 0)) > 0 else "") + str(it.get("name", ""))

## ảnh biểu tượng của một món đồ (theo phái, bộ, ô)
func item_icon(it: Dictionary) -> Texture2D:
	var g: Dictionary = A.get("gear", {})
	var c = str(it.get("cls", ""))
	var sl = str(it.get("slot", ""))
	if sl == "egg":
		return tex(A.get("egg", {}).get(str(it.get("sp", "fire")), {}).get("icon", ""))
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

## tùy chọn trên máy (kiểu điều khiển, auto...): lưu ở user://settings.cfg
var _cfgs := {}
var _cfg_loaded := false
func setting(k: String, def = null):
	if not _cfg_loaded:
		_cfg_loaded = true
		var f = FileAccess.open("user://settings.json", FileAccess.READ)
		if f:
			var v = JSON.parse_string(f.get_as_text())
			if v is Dictionary:
				_cfgs = v
	return _cfgs.get(k, def)

func set_setting(k: String, v) -> void:
	setting(k)
	_cfgs[k] = v
	var f = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_cfgs))

## máy cảm ứng (điện thoại, máy tính bảng): phím ảo, phóng to nhân vật
func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_name() in ["Android", "iOS"] or OS.get_environment("HSNC_TOUCH") == "1"

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
