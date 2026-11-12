extends Node2D
class_name Mon
## Vẽ một con quái theo khung hình gốc (đứng, 4 bước, vồ; rồng có thêm khung khạc). Vị trí do máy chủ gửi, ở đây chỉ làm mượt.

const MS := 0.76
const MH := {"boar": 74, "wolf": 80, "bear": 102, "dragon": 236}
const BR_C := 0.5
const BR_E := 1.35

var id = 0
var type = "boar"
var lv = 1
var hp = 1.0
var hp_max = 1.0
var face = 1
var flags = 0
var target = Vector2.ZERO
var walk = 0.0
var t = 0.0
var flash = 0.0
var lunge = 0.0
var br_t = -1.0          # >=0 khi đang khạc
var mouth = Vector2.ZERO # toạ độ thế giới của miệng rồng
var focused = false
var hover = 0.0
var _k = ""
var elite = false
var die_t = -1.0         # >=0: đang chết (nhấp nháy, mờ dần rồi biến mất)
var hit_t = 0.0          # >0: vừa trúng đòn (ửng đỏ)
var _info: Dictionary = {}
var _art = ""             # ảnh dùng (loài khác có thể mượn ảnh: vua heo dùng ảnh heo lửa)
var _m2: Dictionary = {}  # ảnh kiểu mới: mỗi động tác 8 khung (assets.json → mon2)
var sc = 1.0              # phóng to (trùm mượn ảnh quái thường)
var tint_c = Color.WHITE
var flyh = 0.0            # bay/bơi lơ lửng cao bao nhiêu
var anim = ""             # động tác chạy một lần: atk, s1, s2, s3
var anim_t = 0.0
var anim_dur = 0.0

func setup(info: Dictionary) -> void:
	id = int(info.id)
	type = str(info.type)
	lv = int(info.lv)
	hp_max = float(info.hpMax)
	hp = float(info.get("hp", hp_max))
	position = Vector2(info.x, info.y)
	target = position
	flags = 1 if int(info.get("dead", 0)) else 0
	elite = int(info.get("el", 0)) == 1
	_info = Data.D.mons.get(type, {})
	_k = str(_info.get("kind", "boar"))
	_art = str(_info.get("art", type))
	_m2 = Data.A.get("mon2", {}).get(_art, {})
	sc = float(_info.get("sc", 1.0))
	tint_c = Color.html(str(_info.get("tint", "ffffff")))
	flyh = float(_info.get("fly", 0))
	walk = randf() * 6.0

## chiều cao thân khi vẽ (đã tính phóng to)
func hh() -> float:
	var base: float = float(_info.get("h", 80)) if not _m2.is_empty() else float(MH.get(_k, 80)) * MS
	return base * sc * (1.15 if elite else 1.0)

## nhấc khỏi mặt đất (quái bay/bơi, rồng)
func lift() -> float:
	if _k == "dragon":
		return 70.0 * MS
	return flyh

## chạy một động tác (đánh, chiêu) trong dur giây
func play(a: String, dur: float) -> void:
	if a == "":
		return
	if a == "atk" and _m2.is_empty():
		lunge = 0.25
		return
	anim = a
	anim_t = 0.0
	anim_dur = max(0.3, dur)

func dead() -> bool:
	return flags & 1 != 0

func _process(dt: float) -> void:
	t += dt
	flash = max(0.0, flash - dt)
	lunge = max(0.0, lunge - dt)
	if br_t >= 0:
		br_t += dt
		if br_t > 1.9:
			br_t = -1.0
	var d = target - position
	if d.length() > 400:
		position = target
	else:
		position += d * min(1.0, dt * 12.0)
	var mv = absf(d.x) > 0.6 or flags & 64 != 0
	walk += dt * (2.0 if mv else 0.4)
	if not dead() and absf(d.x) > 1.5 and br_t < 0:
		face = 1 if d.x > 0 else -1
	hit_t = max(0.0, hit_t - dt)
	if anim != "":
		anim_t += dt
		if anim_t >= anim_dur:
			anim = ""
	if die_t >= 0:
		die_t += dt
	visible = not dead() or (die_t >= 0 and die_t < die_len())
	queue_redraw()

## thời gian chết: quái có khung "die" (Ma Long) diễn hết động tác rồi mới mờ đi
func die_len() -> float:
	return 2.4 if not _m2.is_empty() and _m2.a.has("die") else 0.75

func _br_frame(bt: float) -> int:
	if bt < BR_C * 0.7: return 0
	if bt < BR_C: return 1
	if bt > BR_E + 0.1: return 5
	return [2, 3, 4, 3][int((bt - BR_C) * 6) % 4]

func _draw() -> void:
	if not _m2.is_empty():
		_draw2()
		return
	var F: Array = Data.A.get("mon", {}).get(_art, [])
	if F.is_empty():
		return
	var fly = _k == "dragon"
	var H: float = MH.get(_k, 80)
	var r: float = _info.get("r", 30)
	hover = (-70.0 - sin(t * 2.2 + id) * 12.0) if fly else 0.0
	var al = 1.0
	if die_t >= 0:
		# chết: nhấp nháy nhanh và mờ dần trong 0,75 giây
		al = (1.0 - die_t / 0.75) * (0.25 if int(die_t * 20) % 2 == 0 else 1.0)
	var tint = Color(1, 1, 1, al)
	if hit_t > 0:
		var k = hit_t / 0.18
		tint = Color(1, 1 - 0.55 * k, 1 - 0.55 * k, al)   # ửng đỏ khi trúng đòn
	var esc = (1.15 if elite else 1.0) * sc
	var base = Transform2D().scaled(Vector2(MS * esc, MS * esc))
	draw_set_transform_matrix(base)
	var sw: float = 44.0 if _k == "boar" else (58.0 if _k == "wolf" else (62.0 if _k == "bear" else 130.0))
	_ellipse(Vector2(0, r * 0.12 - r * 0.5 + r * 0.5), sw * 1.3 * (0.8 if fly else 1.0), r * 0.42, Color(0.1, 0.1, 0.2, 0.25 * (0.5 if fly else 1.0)))
	var xf = base * Transform2D().translated(Vector2(0, hover)) * Transform2D().scaled(Vector2(face, 1))
	if lunge > 0:
		xf = xf * Transform2D().translated(Vector2(sin(lunge / 0.25 * PI) * 10, 0))
	var mv = flags & 64 != 0
	var fi = int(floor(t * 7 + id if fly else walk * 5.5)) % 4
	var q: Dictionary = F[1 + fi] if fly else (F[5] if lunge > 0 and F.size() > 5 else (F[1 + fi] if mv else F[0]))
	var BF: Array = Data.A.get("mon", {}).get(_art + "_br", [])
	if br_t >= 0 and BF.size() >= 6:
		q = BF[_br_frame(br_t)]
	var fh: float = H * float(q.hr)
	var fw: float = fh * float(q.ar)
	var y0 = -fh
	if fly and q.get("cy") != null:
		var refs: Array = []
		for z in F.slice(1, 5):
			refs.append(float(z.hr) * (1.0 - float(z.get("cy", 0.6) if z.get("cy") != null else 0.6)))
		refs.sort()
		y0 = -refs[1] * H - float(q.cy) * fh
	var breathe = sin(t * 2 + id) * 0.015 if (not fly and not mv and lunge <= 0) else 0.0
	draw_set_transform_matrix(xf * Transform2D().scaled(Vector2(1, 1 + breathe)))
	var tx = Data.tex(q.u)
	if tx:
		if elite and die_t < 0:
			# tinh anh: viền sáng vàng tím nhấp nháy quanh thân
			var gl = 0.35 + sin(t * 4.0) * 0.15
			for o in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
				draw_texture_rect(tx, Rect2(Vector2(-float(q.cx) * H, y0) + o, Vector2(fw, fh)), false, Color(1.0, 0.75, 0.25, gl))
		draw_texture_rect(tx, Rect2(-float(q.cx) * H, y0, fw, fh), false, tint * tint_c)
	if fly:
		var lx: float = -float(q.cx) * H + float(q.get("mx", 0.92) if q.get("mx") != null else 0.92) * fw
		var ly: float = y0 + float(q.get("my", 0.38) if q.get("my") != null else 0.38) * fh
		mouth = global_position + Vector2(MS * face * lx, MS * (hover + ly))
	# trạng thái, máu, tên
	draw_set_transform(Vector2.ZERO)
	var th: float = round(H * 0.94)
	var top: float = hover * MS + th * (1 - MS) - th
	if sc != 1.0:
		top = hover * MS - th * MS * esc - 6
	_status(top)
	_bar(top, sw * MS * sc)

## ★ choáng, vòng độc/chậm
func _status(top: float) -> void:
	if flags & 2:
		var f: Font = Data.fonts.get("bold")
		draw_string_outline(f, Vector2(-18 + sin(t * 9) * 8, top - 20), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, UI.INK)
		draw_string(f, Vector2(-18 + sin(t * 9) * 8, top - 20), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd23f"))

## thanh máu, tên, vòng chọn mục tiêu
func _bar(top: float, sw: float) -> void:
	draw_set_transform(Vector2.ZERO)
	if flags & 12:
		draw_arc(Vector2(0, 2), sw + 4, 0, TAU, 24, Color("6fcf3f") if flags & 8 else Color("6fb8ff"), 3)
	if die_t >= 0:
		return
	var boss: bool = _info.get("boss", false)
	var ly2 = top - 8
	if hp < hp_max or boss or focused or elite:
		var bw = (220.0 if _info.get("world", false) else 120.0) if boss else 48.0
		draw_rect(Rect2(-bw / 2 - 1.5, ly2 - 1.5, bw + 3, 8), Color("0f1422"))
		draw_rect(Rect2(-bw / 2, ly2, bw * clampf(hp / hp_max, 0, 1), 5), Color("d9345a"))
	var f2: Font = Data.fonts.get("bold")
	var lab = "Lv.%d %s%s" % [lv, _info.get("n", type), " Tinh Anh" if elite else ""]
	if _info.get("nolv", false):
		lab = "☠ %s ☠" % _info.get("n", type)
	var sz = 16 if boss else 14
	var w = f2.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string_outline(f2, Vector2(-w / 2, ly2 - 5), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, Color(1, 1, 1, 0.85))
	draw_string(f2, Vector2(-w / 2, ly2 - 5), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("c0143f") if focused or boss else (Color("b85c00") if elite else UI.INK))
	if focused:
		draw_arc(Vector2(0, 3), sw * 0.9, 0, TAU, 28, Color(1, 0.82, 0.25, 0.9), 2.5)

## quái kiểu mới: đứng / đi / đánh / chiêu, mỗi động tác 8 khung
func _draw2() -> void:
	var A: Dictionary = _m2.a
	var H := hh()
	var W: float = H * float(_m2.w) / float(_m2.h)
	var mv = flags & 64 != 0 or absf(target.x - position.x) > 0.6
	var fr: Array = A.get("idle", A.move)
	var k := 0
	var dl := die_len()
	if die_t >= 0 and A.has("die"):
		fr = A.die
		k = mini(fr.size() - 1, int(die_t / (dl * 0.7) * fr.size()))
	elif anim != "" and A.has(anim):
		fr = A[anim]
		k = mini(fr.size() - 1, int(anim_t / anim_dur * fr.size()))
	elif hit_t > 0 and A.has("hit"):
		fr = A.hit
		k = mini(fr.size() - 1, int((0.18 - hit_t) / 0.18 * fr.size()))
	elif mv or not A.has("idle"):
		fr = A.move
		k = int(t * (11.0 if mv else 7.0) * fr.size() / 8.0 + id) % fr.size()
	else:
		k = int(t * 7.0 * fr.size() / 8.0 + id) % fr.size()
	var bob = sin(t * 2.6 + id) * 5.0 if flyh > 0 else 0.0
	var y0: float = -H - flyh + bob
	var al = 1.0
	if die_t >= 0:
		if A.has("die"):
			al = clampf((dl - die_t) / (dl * 0.3), 0, 1)
		else:
			al = (1.0 - die_t / 0.75) * (0.25 if int(die_t * 20) % 2 == 0 else 1.0)
	var col = Color(tint_c, al)
	var world: bool = _info.get("world", false)
	if world and hp < hp_max * 0.6 and die_t < 0:
		var rg = 0.5 + sin(t * 6.0) * 0.5   # nổi giận: ửng đỏ nhịp nhàng
		col = col * Color(1.0, 1.0 - 0.25 * rg, 1.0 - 0.3 * rg)
	if hit_t > 0:
		var q = hit_t / 0.18
		col = Color(1, 1 - 0.55 * q, 1 - 0.55 * q, al)
	if flags & 128 and not _info.get("world2", false):
		col = col * Color(0.7, 0.85, 1.25)
	# bóng dưới chân
	_ellipse(Vector2(0, 2), W * 0.32 * (0.75 if flyh > 0 else 1.0), W * 0.07, Color(0.1, 0.1, 0.2, 0.22 if flyh > 0 else 0.3))
	var lng = sin(lunge / 0.25 * PI) * 8.0 if lunge > 0 and anim == "" else 0.0
	var au = _info.get("aura")
	if au is Array and die_t < 0:
		_aura(str(au[0]), W * float(au[2]), H * float(au[2]), al, false)
	draw_set_transform(Vector2(lng * face, 0), 0, Vector2(face, 1))
	var tx = Data.tex(fr[k])
	if tx:
		var r = Rect2(-float(_m2.cx) * W, y0, W, H)
		if elite and die_t < 0:
			var gl = 0.35 + sin(t * 4.0) * 0.15
			for o in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
				draw_texture_rect(tx, Rect2(r.position + o, r.size), false, Color(1.0, 0.75, 0.25, gl))
		draw_texture_rect(tx, r, false, col)
	draw_set_transform(Vector2.ZERO)
	if au is Array and die_t < 0:
		_aura(str(au[1]), W * float(au[2]), H * float(au[2]), al * 0.8, true)
	if flags & 128 and _info.get("world2", false):
		# khiên Hỗn Mang: ít hơn 3 người cùng đánh thì chỉ nhận 15% sát thương (vòng tím mờ quanh thân + chữ nhắc)
		var pa = 0.35 + sin(t * 4.0) * 0.12
		for kk in 3:
			draw_arc(Vector2(0, y0 + H * 0.55), W * (0.46 + kk * 0.03), 0, TAU, 48, Color(0.75, 0.35, 1.0, pa * (1.0 - kk * 0.3)), 5.0 - kk)
		var fs: Font = Data.fonts.get("bold")
		var tip = "Khiên Hỗn Mang · cần ít nhất 3 người"
		var tw = fs.get_string_size(tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string_outline(fs, Vector2(-tw / 2, y0 + H * 0.12), tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0.12, 0.02, 0.2, 0.9))
		draw_string(fs, Vector2(-tw / 2, y0 + H * 0.12), tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.9, 0.7, 1.0))
	elif flags & 128:
		var sh: Dictionary = Data.A.get("vfx", {}).get("ml_shield", {})
		if world and not sh.is_empty():
			var sf: Array = sh.f
			var stx = Data.tex(sf[int(t * 10) % sf.size()])
			if stx:
				var sh_h = H * 1.15
				var sh_w = sh_h * float(sh.w) / float(sh.h)
				draw_texture_rect(stx, Rect2(-sh_w / 2, y0 + H * 0.5 - sh_h / 2, sh_w, sh_h), false, Color(1, 1, 1, 0.8))
		else:
			draw_arc(Vector2(0, y0 + H * 0.5), W * 0.42, 0, TAU, 30, Color(0.6, 0.85, 1, 0.55 + sin(t * 8) * 0.2), 3)
	var top = y0 + 4
	_status(top)
	_bar(top, W * 0.36)

## hào quang quanh trùm (lớp sau và lớp trước thân), đặt sát đất, lặp liên tục
func _aura(nm: String, w: float, h: float, al: float, front: bool) -> void:
	var d: Dictionary = Data.A.get("vfx", {}).get(nm, {})
	if d.is_empty():
		return
	var f: Array = d.f
	var tx = Data.tex(f[int(t * 9.0 + id) % f.size()])
	if tx == null:
		return
	# vòng lửa trải rộng theo thân trùm (thân rộng hơn ảnh hào quang), đáy sát đất
	var ww = w * 1.05
	var hh2 = h * 0.95
	if front:
		# lớp trước thân: chỉ phần dưới (khói tím quanh chân) để không che mặt trùm
		var ts = tx.get_size()
		var k = 0.38
		draw_texture_rect_region(tx, Rect2(-ww / 2, -hh2 * k + h * 0.04, ww, hh2 * k), Rect2(0, ts.y * (1.0 - k), ts.x, ts.y * k), Color(1, 1, 1, al))
	else:
		draw_texture_rect(tx, Rect2(-ww / 2, -hh2 + h * 0.04, ww, hh2), false, Color(1, 1, 1, al))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 20:
		var a = TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
