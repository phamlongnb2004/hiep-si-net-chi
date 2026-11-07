extends Node2D
class_name Hero
## Vẽ nhân vật theo khung hình gốc: thân theo bộ áo, mũ và áo choàng là lớp riêng (giống tools/anim.js).
## Gốc toạ độ = giữa hai chân.

var cls = "sword"
var look = 0            # (áo+1) + 5*(mũ+1) + 25*(choàng+1); -1 = không mặc
var face = 1
var moving = false
var air = false
var swing = 0.0         # 1 -> 0 khi đang đánh
var t = 0.0
var flash = 0.0
var dead = false
var nm = ""
var lv = 0
var hp = 1.0
var show_name = true
var is_me = false
var wing = -1           # độ hiếm cánh đang đeo (0..3), -1 = không có
var title = ""          # danh hiệu (vd Kẻ Kết Liễu, 24 giờ sau khi hạ trùm)
var deb = 0             # trạng thái xấu: 1 choáng, 2 chậm, 4 độc
var climb = false       # đang leo dây/thang: vẽ dáng nhìn từ sau lưng
var _sp: Array = []     # hạt sáng quanh cánh

const HS := 0.8
const FIT := {
	"sword": {"hx": 3, "hw": 48, "hb": .66, "cx": -2, "cy": .47, "ch": 46},
	"archer": {"hx": 4, "hw": 44, "hb": .52, "cx": -2, "cy": .49, "ch": 44},
	"mage": {"hx": 2, "hw": 52, "hb": .42, "cx": -2, "cy": .48, "ch": 46},
	"fighter": {"hx": 3, "hw": 44, "hb": .74, "cx": -1, "cy": .47, "ch": 44}}
const BOB := [0.0, 2.2, 0.0, 2.2]

func _process(dt: float) -> void:
	t += dt
	flash = max(0.0, flash - dt)
	# hạt sáng bay ra từ cánh (cánh càng hiếm càng nhiều)
	if wing >= 0 and not dead:
		var rate = [1.5, 4.0, 7.0, 12.0][clampi(wing, 0, 3)]
		if randf() < rate * dt:
			_sp.append({"p": Vector2(randf_range(-34, 34), randf_range(-70, -20)), "v": Vector2(randf_range(-12, 12), randf_range(-38, -14)), "t": 0.0, "life": randf_range(0.7, 1.4), "s": randf_range(1.5, 3.2)})
	var i = 0
	while i < _sp.size():
		var q = _sp[i]
		q.t += dt
		q.p += q.v * dt
		if q.t >= q.life:
			_sp.remove_at(i)
		else:
			i += 1
	queue_redraw()

const WING_GLOW := [Color(1, 1, 1, 0.0), Color(0.55, 0.85, 1.0, 0.35), Color(0.75, 0.45, 1.0, 0.42), Color(1.0, 0.7, 0.25, 0.5)]
const WING_SP := [Color(1, 1, 1), Color(0.7, 0.92, 1.0), Color(0.85, 0.6, 1.0), Color(1.0, 0.85, 0.35)]

## cánh: 16 khung vỗ cánh, vỗ nhanh khi chạy/nhảy, chậm khi đứng; quầng sáng + hạt sáng theo độ hiếm
## gap > 0: nhìn từ sau, tách hai nửa cánh ra hai bên bả vai.
## gap == 0: nhìn nghiêng, nửa cánh phía lưng xoè đủ, nửa phía mặt thu hẹp và nấp sau thân (không chìa ra trước mặt).
func _wing_tex(tx: Texture2D, rc: Rect2, col: Color, gap: float) -> void:
	var ts: Vector2 = tx.get_size()
	var hw = rc.size.x / 2
	var x0 = rc.position.x
	if gap > 0:
		draw_texture_rect_region(tx, Rect2(x0 - gap, rc.position.y, hw, rc.size.y), Rect2(0, 0, ts.x / 2, ts.y), col)
		draw_texture_rect_region(tx, Rect2(x0 + hw + gap, rc.position.y, hw, rc.size.y), Rect2(ts.x / 2, 0, ts.x / 2, ts.y), col)
		return
	var fw = hw * 0.4   # nửa phía mặt
	if face > 0:
		draw_texture_rect_region(tx, Rect2(x0, rc.position.y, hw, rc.size.y), Rect2(0, 0, ts.x / 2, ts.y), col)
		draw_texture_rect_region(tx, Rect2(x0 + hw, rc.position.y + rc.size.y * 0.06, fw, rc.size.y * 0.9), Rect2(ts.x / 2, 0, ts.x / 2, ts.y), col)
	else:
		draw_texture_rect_region(tx, Rect2(x0 + hw - fw, rc.position.y + rc.size.y * 0.06, fw, rc.size.y * 0.9), Rect2(0, 0, ts.x / 2, ts.y), col)
		draw_texture_rect_region(tx, Rect2(x0 + hw, rc.position.y, hw, rc.size.y), Rect2(ts.x / 2, 0, ts.x / 2, ts.y), col)

func _draw_wing(al: float, up: float, back := false) -> void:
	var fx: Array = Data.A.get("wingfx", [])
	var r = clampi(wing, 0, 3)
	if r >= fx.size():
		return
	var frames: Array = fx[r]
	var spd = 14.0 if (moving or air) else 6.0
	var fi = int(t * spd) % frames.size()
	var tx = Data.tex(frames[fi])
	if tx == null:
		return
	var w = 118.0
	var h = w * tx.get_height() / tx.get_width()
	var c = Vector2(0 if back else -10 * face, -40 - up + sin(t * 2.2) * 1.5)
	# nhìn nghiêng: gốc cánh lệch về phía lưng
	draw_set_transform(c, 0, Vector2((0.9 if back else 0.9) * HS * 1.25, (0.9 if back else 1.0) * HS * 1.25))
	var g: Color = WING_GLOW[r]
	# nhìn từ sau: tách hai nửa cánh ra hai bên bả vai để lộ sống lưng
	var gap = 14.0 if back else 0.0
	if g.a > 0:
		var pulse = 0.75 + 0.25 * sin(t * 3.0)
		for k in 3:
			var e = 1.0 + 0.06 * (k + 1)
			_wing_tex(tx, Rect2(-w * e / 2, -h * 0.62 * e, w * e, h * e), Color(g.r, g.g, g.b, g.a * pulse * al / (k + 1)), gap)
	_wing_tex(tx, Rect2(-w / 2, -h * 0.62, w, h), Color(1, 1, 1, al), gap)
	draw_set_transform(Vector2.ZERO)
	var sc: Color = WING_SP[r]
	for q in _sp:
		var k2 = 1.0 - q.t / q.life
		draw_circle(q.p, q.s * k2 + 0.5, Color(sc.r, sc.g, sc.b, 0.85 * k2 * al))
		if r >= 2:
			draw_circle(q.p, q.s * 2.4 * k2, Color(sc.r, sc.g, sc.b, 0.18 * k2 * al))

func _frames() -> Array:
	var a = look % 5 - 1
	var k = "body_%s_%s" % [cls, "b" if a < 0 else str(a)]
	var an: Dictionary = Data.A.get("anim", {})
	if an.has(k):
		return an[k]
	return an.get("body_%s_0" % cls, [])

func _draw() -> void:
	var set = _frames()
	if set.is_empty():
		return
	var al = 0.45 if dead else 1.0
	if flash > 0 and int(t * 30) % 2 == 0:
		al *= 0.5
	if climb and _draw_climb(al):
		_labels()
		return
	var ph = t * 8.5
	var fi = int(floor(ph)) % 4
	var fr = ph - floor(ph)
	var q: Dictionary = set[0]
	if swing > 0:
		q = set[5]
	elif air:
		q = set[1]
	elif moving:
		q = set[1 + fi]
	var up = 0.0
	if moving and swing <= 0 and not air:
		up = BOB[fi] + (BOB[(fi + 1) % 4] - BOB[fi]) * fr
	# bóng dưới chân
	var sk = 1.0 - up * 0.05
	draw_set_transform(Vector2.ZERO, 0, Vector2(HS, HS))
	_ellipse(Vector2(0, 1.5), 28 * sk, 7, Color(0.1, 0.12, 0.2, 0.28 * al))
	# cánh sau lưng (vẽ trước thân)
	if wing >= 0:
		_draw_wing(al, up)
	# thân
	var xf = Transform2D().scaled(Vector2(HS, HS))
	xf = xf * Transform2D().scaled(Vector2(face, 1))
	var sy = 1.0
	var sx = 1.0
	var rot = 0.0
	if moving and swing <= 0:
		rot = 0.03
	elif swing <= 0:
		var b = sin(t * 2.6)
		sy = 1 + b * 0.016
		sx = 1 - b * 0.008
	var lunge = sin(min(1.0, (1 - swing) * 1.3) * PI) * 6.0 if swing > 0 else 0.0
	xf = xf * Transform2D(rot, Vector2.ZERO) * Transform2D().translated(Vector2(lunge, -up)) * Transform2D().scaled(Vector2(sx, sy))
	var F: Dictionary = FIT.get(cls, FIT.sword)
	var L: Dictionary = Data.A.get("layer", {}).get(cls, {})
	var tc = int(look / 25) - 1
	var th = int(look / 5) % 5 - 1
	var mod = Color(1, 1, 1, al)
	# áo choàng phía sau
	if tc >= 0 and L.has("cape") and tc < L.cape.size():
		var cp: Dictionary = L.cape[tc]
		var ct = Data.tex(cp.u)
		if ct:
			var ch: float = F.ch * (0.96 if swing > 0 else 1.0)
			var cw: float = ch * cp.w / cp.h
			var sway = 0.0
			if moving:
				sway = sin(t * 8.5 * PI / 2) * 0.07 + 0.12
			elif swing > 0:
				sway = 0.18
			else:
				sway = sin(t * 2) * 0.03
			draw_set_transform_matrix(xf * Transform2D().translated(Vector2(F.cx, -q.h * (1 - F.cy))) * Transform2D(sway, Vector2.ZERO))
			draw_texture_rect(ct, Rect2(-cw * 0.92, -ch * 0.06, cw, ch), false, mod)
	var bt = Data.tex(q.u)
	if bt:
		draw_set_transform_matrix(xf)
		draw_texture_rect(bt, Rect2(-q.ax, -q.h, q.w, q.h), false, mod)
	# mũ trên đỉnh tóc của khung đang vẽ
	if th >= 0 and L.has("hat") and th < L.hat.size() and q.has("tp"):
		var ht: Dictionary = L.hat[th]
		var htx = Data.tex(ht.u)
		if htx:
			# ox/oy/sc: chỉnh riêng từng mũ cho ôm đầu (lùi về sau gáy, hạ xuống, co giãn)
			var hx: float = F.hx + float(ht.get("ox", 0.0)) + (float(q.hc) - float(set[0].hc) if q.get("hc") != null and set[0].get("hc") != null else 0.0)
			var hw2: float = F.hw * float(ht.get("sc", 1.0))
			var x0 = hx - hw2 * 0.32
			var x1 = hx + hw2 * 0.32
			var tp: Array = q.tp
			var n = tp.size()
			var top: float = q.h
			for j in n:
				var cx: float = (j + 0.5) / n * q.w - q.ax
				if cx >= x0 and cx <= x1:
					top = min(top, float(tp[j]))
			var hh: float = hw2 * ht.h / ht.w
			var y: float = -q.h + top + hw2 * F.hb + float(ht.get("oy", 0.0))
			draw_set_transform_matrix(xf)
			draw_texture_rect(htx, Rect2(hx - hw2 / 2, y - hh, hw2, hh), false, mod)
	draw_set_transform(Vector2.ZERO)
	_labels()

func _labels() -> void:
	if show_name and nm != "":
		var f: Font = Data.fonts.get("bold")
		var s = ("Lv.%d " % lv if lv > 0 else "") + nm
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var y = -84.0
		draw_string_outline(f, Vector2(-w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, UI.INK)
		draw_string(f, Vector2(-w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffd23f") if is_me else Color.WHITE)
		if title != "":
			var tt = "« " + title + " »"
			var tw = f.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string_outline(f, Vector2(-tw / 2, y - 17), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, UI.INK)
			draw_string(f, Vector2(-tw / 2, y - 17), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ff7a4d"))
		if deb & 1:
			draw_string_outline(f, Vector2(-16 + sin(t * 9) * 6, y - (34 if title != "" else 18)), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, UI.INK)
			draw_string(f, Vector2(-16 + sin(t * 9) * 6, y - (34 if title != "" else 18)), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffd23f"))
		if deb & 4:
			for k in 3:
				var bp = Vector2(sin(t * 2 + k * 2.1) * 16, -40 - fmod(t * 30 + k * 13, 40))
				draw_circle(bp, 3.5, Color(0.55, 0.95, 0.3, 0.7))
		if deb & 2:
			draw_arc(Vector2(0, 0), 26, 0, TAU, 24, Color(0.45, 0.75, 1, 0.6), 3)
		if not is_me and hp < 1.0:
			draw_rect(Rect2(-22, y + 4, 44, 6), UI.INK)
			draw_rect(Rect2(-21, y + 5, 42 * clampf(hp, 0, 1), 4), Color("5fe08c"))

## leo thang: nhìn từ sau lưng, 4 khung tay chân luân phiên (chỉ đổi khung khi đang trèo).
## Mũ và áo choàng dùng ảnh mặt sau; cánh mọc từ lưng, vẽ đè lên thân, xoè đủ hai bên.
var _cph = 0.0
func _draw_climb(al: float) -> bool:
	var a = look % 5 - 1
	var an: Dictionary = Data.A.get("anim", {})
	var set: Array = an.get("climb_%s_%s" % [cls, "b" if a < 0 else str(a)], an.get("climb_%s_b" % cls, []))
	if set.size() < 4:
		return false
	if moving:
		_cph = t * 7.0
	var q: Dictionary = set[int(_cph) % set.size()]
	var tx = Data.tex(q.u)
	if tx == null:
		return false
	var mod = Color(1, 1, 1, al)
	var L: Dictionary = Data.A.get("layer", {}).get(cls, {})
	var tc = int(look / 25) - 1
	var th = int(look / 5) % 5 - 1
	draw_set_transform(Vector2.ZERO, 0, Vector2(HS, HS))
	draw_texture_rect(tx, Rect2(-q.ax, -q.h, q.w, q.h), false, mod)
	# áo choàng mặt sau: treo từ vai, phủ lưng
	if tc >= 0 and L.has("capeb") and tc < L.capeb.size():
		var cp: Dictionary = L.capeb[tc]
		var ct = Data.tex(cp.u)
		if ct:
			var sw = sin(t * 2.4) * 0.03
			draw_set_transform(Vector2(0, (-q.h + float(q.sy)) * HS), sw, Vector2(HS, HS))
			draw_texture_rect(ct, Rect2(-float(cp.w) / 2, -4, cp.w, cp.h), false, mod)
	# cánh mọc từ giữa lưng: nhìn từ sau thì lưng quay về phía người xem nên cánh vẽ đè lên thân
	# (gốc cánh ở giữa ảnh, hai cánh xoè lên hai bên đầu; vẽ trước mũ để mũ vẫn ở trên)
	if wing >= 0:
		var root_y = (-float(q.h) + float(q.sy)) * HS + 9.0
		_draw_wing(al, -40.0 - root_y, true)
	# mũ mặt sau trên đỉnh đầu
	if th >= 0 and L.has("hatb") and th < L.hatb.size():
		var ht: Dictionary = L.hatb[th]
		var htx = Data.tex(ht.u)
		if htx:
			draw_set_transform(Vector2((float(q.hx) - q.ax) * HS, (-q.h + float(q.hy)) * HS), 0, Vector2(HS, HS))
			draw_texture_rect(htx, Rect2(-float(ht.w) / 2, -float(ht.h) + float(ht.get("dy", 0)), ht.w, ht.h), false, mod)
	draw_set_transform(Vector2.ZERO)
	return true

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 20:
		var a = TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
