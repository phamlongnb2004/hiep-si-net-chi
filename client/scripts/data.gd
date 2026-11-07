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
const SLOTS := ["hat", "armor", "cape", "weapon", "boots", "gloves", "neck", "wing"]
const SLOT_N := {"hat": "Mũ", "armor": "Áo", "cape": "Áo choàng", "weapon": "Vũ khí", "boots": "Giày", "gloves": "Găng", "neck": "Dây chuyền", "wing": "Cánh"}
const FREE := ["neck", "wing"]   # dây chuyền, cánh: mọi phái đều dùng được
const ACC_NAME := {"neck": ["Dây Chuyền Đồng", "Dây Chuyền Lam Ngọc", "Dây Chuyền Tử Tinh", "Dây Chuyền Thái Dương"], "wing": ["Cánh Thiên Thần", "Cánh Băng Tinh", "Cánh Ma Tinh", "Cánh Phượng Hoàng"]}

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
func tex(rel) -> Texture2D:
	if rel == null or str(rel) == "":
		return null
	var k = str(rel)
	if _tex.has(k):
		return _tex[k]
	var t: Texture2D = null
	var p = "res://assets/" + k
	if ResourceLoader.exists(p):
		t = load(p)
	_tex[k] = t
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
	return {"L": L, "rate": clampi(int(rate[min(L - 1, rate.size() - 1)]) + int(cfg.get("forgeBonus", 0)), 1, 100), "stones": 1 + int(floor((L - 1) / 2.0)),
		"gold": int(round((40.0 + float(it.lvl) * 6.0) * pow(L, 1.5))), "drop": 0 if L <= 5 else (1 if L <= 10 else 2)}

func rar_color(r: int) -> Color:
	return Color.html(str(D.rar[clampi(r, 0, 3)].c))

func item_name(it: Dictionary) -> String:
	return ("+%d " % int(it.up) if int(it.get("up", 0)) > 0 else "") + str(it.name)

## ảnh biểu tượng của một món đồ (theo phái, bộ, ô)
func item_icon(it: Dictionary) -> Texture2D:
	var g: Dictionary = A.get("gear", {})
	var c = str(it.get("cls", ""))
	var sl = str(it.get("slot", ""))
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
