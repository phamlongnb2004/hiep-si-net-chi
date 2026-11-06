extends Node2D
class_name Fx
## Hiệu ứng nhìn thấy: số sát thương, ảnh chiêu thức, đạn bay, luồng khạc của rồng.
## Chỉ để hiển thị — máy chủ đã tính sẵn kết quả, ở đây vẽ lại theo tin 'snap'.

var texts: Array = []     # {p, s, col, big, t, max}
var sprs: Array = []      # {img:{u,w,h}, p, h, t, max, a, flip, rot, follow(Node2D), off, glow, px, py}
var projs: Array = []     # {p, v, range, trav, img, len, col, r}
var breaths: Array = []   # {m: Mon, tgt: Node2D, t, parts:[], kn}
var _soft: Texture2D
var parts: Array = []     # hạt sáng: {p, v, life, max, s, col, g}
var rings: Array = []     # sóng tròn: {p, r0, r1, t, max, col, w}
var shake = 0.0           # rung màn hình (giây còn lại × biên độ)
var add_layer: Node2D

## lớp vẽ cộng sáng (ánh sáng, hạt, vệt đạn, sóng) nằm trên lớp thường
class AddLayer extends Node2D:
	var fx
	func _ready() -> void:
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		fx.draw_add(self)
const BRK := {
	"dragon": {"col": ["fffadc", "ffd65a", "ff8c1e", "e64614", "5a281e"], "rise": -70.0},
	"dragon2": {"col": ["ebffbe", "befa5a", "78d732", "46a028", "3c5028"], "rise": -25.0},
	"dragon3": {"col": ["e1f8ff", "96d7ff", "5aaff5", "3c82dc", "bedcfa"], "rise": 25.0}}

func _ready() -> void:
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	gt.width = 64
	gt.height = 64
	_soft = gt
	z_index = 50
	add_layer = AddLayer.new()
	add_layer.fx = self
	add_child(add_layer)

func text(p: Vector2, s: String, col: Color, big := false) -> void:
	texts.append({"p": p + Vector2(randf_range(-8, 8), 0), "s": s, "col": col, "big": big, "t": 0.0, "max": 0.9 if big else 0.75})

## chùm hạt sáng bung ra (trúng đòn, nổ, tung chiêu)
func burst(p: Vector2, col: Color, n := 10, spd := 220.0, sz := 1.0, up := 0.0) -> void:
	for i in n:
		var a = randf() * TAU
		var v = Vector2(cos(a), sin(a) * 0.7 - up) * spd * randf_range(0.4, 1.0)
		var l = randf_range(0.25, 0.55)
		parts.append({"p": p, "v": v, "life": l, "max": l, "s": randf_range(6, 14) * sz, "col": col, "g": 260.0})

func ring(p: Vector2, r1: float, col: Color, mx := 0.4, w := 6.0) -> void:
	rings.append({"p": p, "r0": 8.0, "r1": r1, "t": 0.0, "max": mx, "col": col, "w": w})

func hit_spark(p: Vector2, crit: bool) -> void:
	burst(p, Color(1, 0.85, 0.3) if crit else Color(1, 0.95, 0.85), 14 if crit else 7, 260.0 if crit else 170.0, 1.3 if crit else 0.9)
	if crit:
		ring(p, 46, Color(1, 0.8, 0.25), 0.25, 4)
		shake = max(shake, 0.12)

const CLS_COL = {"sword": Color(0.45, 0.65, 1.0), "mage": Color(1.0, 0.5, 0.2), "archer": Color(0.45, 0.95, 0.45), "fighter": Color(1.0, 0.6, 0.2)}

func fx_img(c: String, n: int) -> Dictionary:
	var a = Data.A.get("fx", {}).get(c, [])
	return a[n] if a is Array and n < a.size() else {}

func spr(img: Dictionary, p: Vector2, h: float, mx: float, a := "pop", o := {}) -> void:
	if img.is_empty():
		return
	var d = {"img": img, "p": p, "h": h, "t": 0.0, "max": mx, "a": a, "flip": false, "rot": 0.0, "follow": null, "off": Vector2.ZERO, "glow": 0.55, "px": 0.5, "py": 0.5, "dl": 0.0, "spin": 0.0}
	if a == "aura" and not o.has("spin"):
		d.spin = 0.25
	d.merge(o, true)
	sprs.append(d)

func proj(p: Vector2, ang: float, sp: float, rng: float, kind: String, sz := 1.0) -> void:
	projs.append({"p": p, "v": Vector2(cos(ang), sin(ang)) * sp, "range": rng, "trav": 0.0, "kind": kind, "sz": sz, "ang": ang, "hist": []})

func breath(m: Node2D, tgt: Node2D, kind: String) -> void:
	for b in breaths:
		if b.m == m:
			return
	breaths.append({"m": m, "tgt": tgt, "t": 0.0, "parts": [], "kn": kind if BRK.has(kind) else "dragon", "em": 0.0, "reach": 0.0})

## hiệu ứng chiêu thức theo phái và số thứ tự (giống tools/vfx.js ở mức nhìn thấy)
func skill(cls: String, i: int, who: Node2D, aim: float, tgt: Node2D, face: int) -> void:
	var p = who.position
	var im = fx_img(cls, i)
	# ánh sáng tung chiêu quanh người
	var cc: Color = CLS_COL.get(cls, Color.WHITE)
	ring(p + Vector2(0, -30), 70 + i * 14, cc, 0.35, 5)
	burst(p + Vector2(0, -30), cc, 8 + i * 2, 160, 0.9, 0.4)
	if i >= 4:
		shake = max(shake, 0.18)
	var fl = cos(aim) < 0
	var tp: Vector2 = tgt.position if tgt else p + Vector2(cos(aim) * 240, 0)
	match cls + str(i):
		"sword0", "fighter0": spr(im, p + Vector2(cos(aim) * 55, -26), 120, 0.32, "pop", {"flip": fl})
		"sword1": spr(im, p + Vector2(0, -14), 160, 0.45, "grow")
		"sword2", "fighter2", "mage4", "fighter5": spr(im, p + Vector2(0, -40), 130, 1.2, "aura", {"follow": who, "off": Vector2(0, -40)})
		"sword3", "fighter3": spr(im, p + Vector2(face * 60, -30), 110, 0.35, "dash", {"flip": face < 0})
		"sword4", "fighter4": spr(im, p + Vector2(0, -20), 260, 0.55, "grow")
		"sword5":
			for k in 3:
				spr(im, p + Vector2(0, -30), 230, 0.45, "pop", {"dl": k * 0.3, "follow": who, "off": Vector2(0, -30)})
		"mage0": proj(p + Vector2(0, -30), aim, 520, 460, "fire", 1.3)
		"mage1":
			for o in [[0, 0, .6], [-80, 45, .8], [80, -35, 1.0]]:
				spr(im, tp + Vector2(o[0], o[1] - 40), 120, o[2], "drop")
		"mage2": spr(im, tp + Vector2(0, -10), 300, 5.0, "aura")
		"mage3": spr(im, tp + Vector2(0, -100), 230, 0.4, "flick")
		"mage5":
			spr(fx_img("mage", 5), tp + Vector2(0, -20), 420, 7.0, "aura")
			for o in [[0, 0, .5], [-120, 60, .9], [120, 50, 1.3], [10, -110, 1.7]]:
				spr(fx_img("mage", 1), tp + Vector2(o[0], o[1] - 40), 120, o[2], "drop")
		"archer0": proj(p + Vector2(0, -32), aim, 820, 540, "arrow", 1.3)
		"archer1":
			for k in 9: proj(p + Vector2(0, -32), aim - 0.7 + k * 0.175, 650, 460, "arrow")
		"archer2": spr(im, tp + Vector2(0, -10), 260, 7.0, "aura")
		"archer3":
			spr(im, p + Vector2(-face * 40, -30), 110, 0.4, "dash", {"flip": face > 0})
			for k in [-1, 0, 1]: proj(p + Vector2(0, -32), aim + k * 0.14, 760, 520, "arrow")
		"archer4": proj(p + Vector2(0, -32), aim, 700, 560, "boom", 1.6)
		"archer5":
			for w in 6:
				for k in 12:
					projs.append({"p": p + Vector2(0, -32), "v": Vector2(cos(w * .26 + k * TAU / 12), sin(w * .26 + k * TAU / 12)) * 620, "range": 420.0, "trav": -w * 0.28 * 620, "kind": "arrow", "sz": 1.0, "ang": w * .26 + k * TAU / 12})
		"fighter1": proj(p + Vector2(0, -30), aim, 760, 620, "ki", 2.2)
		_: spr(im, p + Vector2(0, -30), 140, 0.4)

func basic(cls: String, who: Node2D, aim: float, big: bool) -> void:
	var p = who.position
	match cls:
		"sword": spr(fx_img("sword", 0), p + Vector2(cos(aim) * 40, -26), 90, 0.26, "pop", {"flip": cos(aim) < 0})
		"fighter": spr(fx_img("fighter", 0 if big else 3), p + Vector2(cos(aim) * 44, -24), 90 if big else 50, 0.24, "pop", {"flip": cos(aim) < 0})
		"mage": proj(p + Vector2(0, -30), aim, 460, 400, "fire")
		"archer": proj(p + Vector2(0, -32), aim, 700, 440, "arrow")

func mon_hit(kind: String, p: Vector2, dir: int) -> void:
	var sq: String = {"boar": "hit", "wolf": "bite", "bear": "claw", "dragon": "claw"}.get(kind, "hit")
	var seq = Data.A.get("fx", {}).get("seq", {}).get(sq, [])
	if seq is Array and seq.size() > 0:
		spr(seq[0], p + Vector2(-dir * 6, -36), 84 if sq == "hit" else 72, 0.4, "seq", {"seq": seq, "flip": dir < 0})

func _process(dt: float) -> void:
	for i in range(texts.size() - 1, -1, -1):
		var x = texts[i]
		x.t += dt
		x.p.y -= 34 * dt
		if x.t >= x.max:
			texts.remove_at(i)
	for i in range(sprs.size() - 1, -1, -1):
		var s = sprs[i]
		if s.dl > 0:
			s.dl -= dt
			continue
		s.t += dt
		if s.follow and is_instance_valid(s.follow):
			s.p = s.follow.position + s.off
		if s.t >= s.max:
			sprs.remove_at(i)
	var g = get_parent()
	for i in range(projs.size() - 1, -1, -1):
		var q = projs[i]
		q.p += q.v * dt if q.trav >= 0 else Vector2.ZERO
		q.trav += q.v.length() * dt
		if q.trav >= 0:
			q.hist.push_front(q.p)
			if q.hist.size() > 10:
				q.hist.pop_back()
		var hit = false
		if q.trav > 20 and g and "mons" in g:
			for m in g.mons.values():
				if m.dead():
					continue
				if (m.position + Vector2(0, -float(Mon.MH.get(m._k, 80)) * 0.35)).distance_to(q.p) < float(m._info.get("r", 30)) + 10:
					hit = true
					break
		if hit and q.kind != "ki":
			var col = {"fire": Color(1, 0.55, 0.15), "boom": Color(1, 0.6, 0.2), "arrow": Color(1, 1, 0.8)}.get(q.kind, Color.WHITE)
			burst(q.p, col, 16 if q.kind != "arrow" else 6, 240 if q.kind != "arrow" else 140, 1.4 if q.kind != "arrow" else 0.7)
			if q.kind != "arrow":
				ring(q.p, 60 * q.sz, col, 0.3, 5)
			projs.remove_at(i)
		elif q.trav >= q.range:
			projs.remove_at(i)
	for i in range(parts.size() - 1, -1, -1):
		var pp = parts[i]
		pp.life -= dt
		pp.v *= pow(0.12, dt)
		pp.v.y += pp.g * dt
		pp.p += pp.v * dt
		if pp.life <= 0:
			parts.remove_at(i)
	for i in range(rings.size() - 1, -1, -1):
		rings[i].t += dt
		if rings[i].t >= rings[i].max:
			rings.remove_at(i)
	shake = max(0.0, shake - dt)
	for i in range(breaths.size() - 1, -1, -1):
		var b = breaths[i]
		b.t += dt
		if b.t > 2.6 or not is_instance_valid(b.m) or b.m.dead():
			breaths.remove_at(i)
			continue
		_upd_breath(b, dt)
	queue_redraw()

func _upd_breath(b: Dictionary, dt: float) -> void:
	var m: Mon = b.m
	var mo: Vector2 = m.mouth if m.mouth != Vector2.ZERO else m.position + Vector2(m.face * 80, -120)
	var tg: Vector2 = (b.tgt.position if is_instance_valid(b.tgt) else m.position + Vector2(m.face * 300, 0)) + Vector2(0, -28)
	var a = atan2(tg.y - mo.y, (tg.x - mo.x) * m.face)
	a = clampf(a, -0.15, 1.05)
	var L = clampf(mo.distance_to(tg) + 80, 260, 620)
	var dir = Vector2(cos(a) * m.face, sin(a))
	var on: bool = b.t > Mon.BR_C and b.t < Mon.BR_E
	b.mo = mo
	if b.t < Mon.BR_C:
		if randf() < dt * 34:
			var r = randf_range(55, 110)
			var aa = randf() * TAU
			b.parts.append({"p": mo + Vector2(cos(aa) * r, sin(aa) * r * 0.7), "v": Vector2.ZERO, "life": 0.32, "max": 0.32, "s": randf_range(5, 9), "pull": true})
	elif on:
		b.em += dt * 150
		var sp = L / 0.5
		while b.em >= 1:
			b.em -= 1
			var da = randf_range(-0.13, 0.13)
			var d = dir.rotated(da * m.face)
			var l = randf_range(0.42, 0.56)
			b.parts.append({"p": mo, "v": d * sp * randf_range(0.85, 1.08), "life": l, "max": l, "s": randf_range(0.8, 1.2), "pull": false})
	var rise: float = BRK[b.kn].rise
	for i in range(b.parts.size() - 1, -1, -1):
		var q = b.parts[i]
		q.life -= dt
		if q.pull:
			q.p += (mo - q.p) * min(1.0, dt * 9)
		else:
			q.p += q.v * dt
			var dr = pow(0.35, dt)
			q.v.x *= dr
			q.v.y = q.v.y * dr + rise * dt * 2.2
			var w = get_parent().get_node_or_null("World")
			if w:
				var gq: float = w.gy(q.p.x) - 6
				if q.p.y > gq:
					q.p.y = gq
					q.v.y = -absf(q.v.y) * 0.15
		if q.life <= 0:
			b.parts.remove_at(i)

func _draw() -> void:
	# đạn
	for q in projs:
		if q.trav < 0:
			continue
		var p: Vector2 = q.p
		match q.kind:
			"arrow":
				var d: Vector2 = q.v.normalized()
				draw_line(p - d * 22 * q.sz, p, Color("5a3b1a"), 3)
				draw_line(p - d * 4, p + d * 4, Color("dfe6f2"), 4)
			"fire", "boom":
				draw_texture_rect(_soft, Rect2(p - Vector2(22, 22) * q.sz, Vector2(44, 44) * q.sz), false, Color(1, 0.55, 0.15, 0.9))
				draw_texture_rect(_soft, Rect2(p - Vector2(10, 10) * q.sz, Vector2(20, 20) * q.sz), false, Color(1, 0.95, 0.7, 1))
			"ki":
				draw_texture_rect(_soft, Rect2(p - Vector2(30, 30) * q.sz, Vector2(60, 60) * q.sz), false, Color(0.47, 0.75, 1, 0.9))
				draw_texture_rect(_soft, Rect2(p - Vector2(12, 12) * q.sz, Vector2(24, 24) * q.sz), false, Color(1, 1, 1, 1))
	# ảnh chiêu
	for s in sprs:
		if s.dl > 0:
			continue
		var u: float = clampf(s.t / s.max, 0, 1)
		var sc = 1.0
		var al = 1.0
		var pos: Vector2 = s.p
		var img: Dictionary = s.img
		match s.a:
			"pop":
				sc = 0.6 + 0.4 * _back(min(1.0, u * 2.2))
				al = min(1.0, u * 10.0) * (1.0 if u < 0.6 else 1.0 - (u - 0.6) / 0.4)
			"grow":
				sc = 0.25 + 1.05 * _ease(u)
				al = 1.0 - u * u
			"aura":
				sc = 0.9 + sin(s.t * 7) * 0.05
				al = min(1.0, min(u * 6, (1 - u) * 4))
			"drop":
				var v = _ease(min(1.0, u / 0.35))
				pos.y -= (1 - v) * 260
				al = 1.0 if u < 0.7 else 1.0 - (u - 0.7) / 0.3
			"dash":
				sc = 0.7 + 0.3 * _ease(u)
				al = 1.0 - u
			"flick":
				al = min(1.0, u * 8) * (1 - pow(u, 3))
			"seq":
				var F: Array = s.seq
				var k = mini(F.size() - 1, int(u * F.size()))
				img = F[k]
			_:
				al = 1.0 - u
		var tx = Data.tex(img.get("u", ""))
		if tx == null or al <= 0:
			continue
		var h: float = s.h * sc
		var w: float = h * float(img.w) / float(img.h)
		draw_set_transform(pos, s.rot + s.spin * s.t, Vector2(-1 if s.flip else 1, 1))
		draw_texture_rect(tx, Rect2(-w * s.px, -h * s.py, w, h), false, Color(1, 1, 1, al))
	draw_set_transform(Vector2.ZERO)
	# luồng khạc
	for b in breaths:
		var col: Array = BRK[b.kn].col
		var t: float = b.t
		for q in b.parts:
			if q.pull:
				var a: float = q.life / q.max
				var r: float = q.s * (0.6 + a)
				draw_texture_rect(_soft, Rect2(q.p - Vector2(r, r), Vector2(r, r) * 2), false, Color.html(col[1]) * Color(1, 1, 1, 0.9 * (1 - a) + 0.1))
				continue
			var u: float = 1.0 - q.life / q.max
			var ci = mini(3, int(u * 4.6))
			var rr: float = (8 + u * 40) * q.s
			var c = Color.html(col[ci])
			c.a = (1.0 - u) * 0.85
			draw_texture_rect(_soft, Rect2(q.p - Vector2(rr, rr), Vector2(rr, rr) * 2), false, c)
		if b.has("mo"):
			var glow = t / Mon.BR_C if t < Mon.BR_C else max(0.0, 1 - (t - Mon.BR_C) / 0.12)
			if glow > 0:
				var R = 24 + glow * 30
				draw_texture_rect(_soft, Rect2(b.mo - Vector2(R, R), Vector2(R, R) * 2), false, Color(1, 1, 1, 0.85 * glow))
	# số
	var f: Font = Data.fonts.get("bold")
	for x in texts:
		var u: float = x.t / x.max
		var sz = 24 if x.big else 18
		var c: Color = x.col
		c.a = 1.0 - max(0.0, u - 0.6) / 0.4
		var w = f.get_string_size(x.s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_string_outline(f, x.p - Vector2(w / 2, 0), x.s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 6, Color(UI.INK, c.a))
		draw_string(f, x.p - Vector2(w / 2, 0), x.s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)

func _back(u: float) -> float:
	var c = 1.70158
	return 1.0 + (c + 1.0) * pow(u - 1.0, 3) + c * pow(u - 1.0, 2)

func _ease(u: float) -> float:
	return 1.0 - pow(1.0 - u, 3)


## vẽ phần cộng sáng: vệt đạn, ánh chiêu, hạt, sóng tròn
func draw_add(L: Node2D) -> void:
	for q in projs:
		if q.trav < 0:
			continue
		var col = {"fire": Color(1, 0.5, 0.15), "boom": Color(1, 0.55, 0.2), "ki": Color(0.45, 0.75, 1.0), "arrow": Color(0.9, 1, 0.8)}.get(q.kind, Color.WHITE)
		var n = q.hist.size()
		for k in n:
			var f = 1.0 - float(k) / n
			var r = (16.0 if q.kind != "arrow" else 6.0) * q.sz * (0.35 + 0.65 * f)
			var c = col
			c.a = f * (0.55 if q.kind != "arrow" else 0.35)
			L.draw_texture_rect(_soft, Rect2(q.hist[k] - Vector2(r, r), Vector2(r, r) * 2), false, c)
	for s in sprs:
		if s.dl > 0 or s.glow <= 0:
			continue
		var img: Dictionary = s.img
		if s.a == "seq":
			continue
		var tx = Data.tex(img.get("u", ""))
		if tx == null:
			continue
		var u: float = clampf(s.t / s.max, 0, 1)
		var al = sin(u * PI) * s.glow * 0.6
		var sc = 1.0 + 0.12 * u
		var h: float = s.h * sc
		var w: float = h * float(img.w) / float(img.h)
		L.draw_set_transform(s.p, s.rot + s.spin * s.t, Vector2(-1 if s.flip else 1, 1))
		L.draw_texture_rect(tx, Rect2(-w * s.px, -h * s.py, w, h), false, Color(1, 1, 1, al))
	L.draw_set_transform(Vector2.ZERO)
	for pp in parts:
		var f = pp.life / pp.max
		var r = pp.s * (0.5 + 0.5 * f)
		var c: Color = pp.col
		c.a = f
		L.draw_texture_rect(_soft, Rect2(pp.p - Vector2(r, r), Vector2(r, r) * 2), false, c)
	for rg in rings:
		var u = rg.t / rg.max
		var r = lerpf(rg.r0, rg.r1, _ease(u))
		var c: Color = rg.col
		c.a = (1.0 - u) * 0.9
		L.draw_arc(rg.p, r, 0, TAU, 48, c, rg.w * (1.0 - u * 0.6), true)
		c.a *= 0.35
		L.draw_arc(rg.p, r * 0.92, 0, TAU, 48, c, rg.w * 2.2, true)
