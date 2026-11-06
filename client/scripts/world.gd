extends Node2D
class_name World
## Nền và địa hình: trời, núi xa, lớp giữa (cuộn chậm), dải mặt đất theo từng đoạn bậc/dốc, mép vách, cảnh vật, cổng, NPC.
## Vẽ giống tools/side.js để hai bản trông như nhau.

const GY := 600.0
const GRD_H := 250.0
const SKY := {"grass": ["7cc8ff", "d9f1ff"], "snow": ["a9cbe6", "eef6fb"], "lava": ["3a1414", "a2462a"]}
const DSC := {"house": 1.3, "npc": 0.74}
const BACK_Z := -10

var M: Dictionary = {}
var mi = 0
var theme = "grass"
var decor: Array = []      # {k, x, gy, s, v, txt}
var cam_rect = Rect2(0, 0, 1280, 720)
var near_npc = ""
var t = 0.0

func setup(map_index: int) -> void:
	mi = map_index
	M = Data.D.maps[mi]
	theme = str(M.theme)
	_gen_decor()
	queue_redraw()

func gy(x: float) -> float:
	return Data.ground_y(M, x)

func _side(k: String) -> Dictionary:
	return Data.A.get("side", {}).get(k, {})

func _ai(k: String) -> Dictionary:
	return Data.A.get("ai", {}).get(k, {})

func _gen_decor() -> void:
	decor.clear()
	var r = RandomNumberGenerator.new()
	r.seed = 4242 + mi * 31
	var trees: Array = {"grass": [0, 1, 2], "snow": [3, 3, 3], "lava": [4, 4, 4]}[theme]
	var w: float = M.w
	var busy = func(x: float) -> bool:
		for p in M.portals:
			if absf(p.x - x) < 120: return true
		for n in M.get("npcs", []):
			if absf(n.x - x) < 130: return true
		if M.get("fountain") != null and absf(float(M.fountain) - x) < 110: return true
		for h in M.get("houses", []):
			if absf(float(h[0]) - x) < 110: return true
		return false
	var x = 40.0
	while x < w - 40:
		if not busy.call(x) and absf(gy(x - 46) - gy(x + 46)) <= 2:
			var k = r.randf()
			if k < 0.5:
				decor.append({"k": "tree", "x": x, "s": 0.85 + r.randf() * 0.5, "v": trees[r.randi() % 3], "dy": -6 - r.randf() * 10})
			elif k < 0.75:
				decor.append({"k": "bush", "x": x, "s": 0.8 + r.randf() * 0.5, "dy": -2})
			else:
				decor.append({"k": "rock", "x": x, "s": 0.7 + r.randf() * 0.6, "dy": -2})
		x += 70 + r.randf() * 90
	for h in M.get("houses", []):
		decor.append({"k": "house", "x": float(h[0]), "v": int(h[1]), "dy": -4})
	if M.get("fountain") != null:
		decor.append({"k": "fountain", "x": float(M.fountain), "dy": -2})
	for s in M.spots:
		var sx: float = s.x + 60
		while sx < s.x + s.w / 2 and absf(gy(sx - 50) - gy(sx + 50)) > 1:
			sx += 10
		var lvt = "Cấp %d" % int(s.lv[0]) + ("-%d" % int(s.lv[1]) if s.lv[1] > s.lv[0] else "")
		decor.append({"k": "sign", "x": sx, "txt": [str(s.n), lvt], "dy": -1})
	for d in decor:
		d.gy = gy(d.x) + d.dy

func _process(dt: float) -> void:
	t += dt
	var cam = get_viewport().get_camera_2d()
	if cam:
		var vs = get_viewport_rect().size / cam.zoom
		cam_rect = Rect2(cam.get_screen_center_position() - vs / 2, vs)
	queue_redraw()

func _draw() -> void:
	if M.is_empty():
		return
	var cx = cam_rect.position.x
	var cy = cam_rect.position.y
	var vw = cam_rect.size.x
	var vh = cam_rect.size.y
	# trời
	var sk: Array = SKY.get(theme, SKY.grass)
	var c0 = Color.html(sk[0])
	var c1 = Color.html(sk[1])
	draw_polygon(PackedVector2Array([Vector2(cx - 2, cy - 2), Vector2(cx + vw + 2, cy - 2), Vector2(cx + vw + 2, GY), Vector2(cx - 2, GY)]), PackedColorArray([c0, c0, c1, c1]))
	draw_rect(Rect2(cx - 2, GY, vw + 4, max(0.0, cy + vh - GY + 2)), c1)
	# núi xa và lớp giữa cuộn chậm
	var far = _side("far_" + theme)
	if not far.is_empty():
		var h: float = max(GY - cy + 40, vh * 0.85)
		_tile_par(far, cx, GY + 30 - h, h, vw, 0.82)
	var mid = _side("mid_" + theme)
	if not mid.is_empty():
		var h2: float = vh * 0.42
		_tile_par(mid, cx, GY - h2 * 0.94, h2, vw, 0.5)
	# sương phủ cảnh nền
	var hz: Color = {"grass": Color(0.82, 0.92, 1, 0.16), "snow": Color(0.88, 0.93, 0.99, 0.2), "lava": Color(0.12, 0.02, 0.03, 0.42)}[theme]
	draw_rect(Rect2(cx - 2, cy - 2, vw + 4, vh + 4), hz)
	if theme == "lava":
		var a = Color(1, 0.35, 0.16, 0)
		var b = Color(1, 0.35, 0.16, 0.10)
		draw_polygon(PackedVector2Array([Vector2(cx - 2, GY - 260), Vector2(cx + vw + 2, GY - 260), Vector2(cx + vw + 2, GY), Vector2(cx - 2, GY)]), PackedColorArray([a, a, b, b]))
	_ground(cx, cy, vw, vh)
	# cảnh vật phía sau nhân vật (cây, nhà, biển, NPC, cổng)
	for d in decor:
		if d.x < cx - 260 or d.x > cx + vw + 260:
			continue
		_decor(d)
	for n in M.get("npcs", []):
		if n.x > cx - 200 and n.x < cx + vw + 200:
			_npc(n)
	for p in M.portals:
		if p.x > cx - 200 and p.x < cx + vw + 200:
			_portal(p)

func _tile_par(a: Dictionary, cx: float, y: float, h: float, vw: float, k: float) -> void:
	var tx = Data.tex(a.u)
	if tx == null:
		return
	var px = cx * k
	var w: float = h * a.w / a.h
	var x0 = cx - px
	var x = floor(x0 / w) * w
	draw_set_transform(Vector2(px, 0))
	while x < x0 + vw + w:
		draw_texture_rect(tx, Rect2(x, y, w + 1, h), false)
		x += w
	draw_set_transform(Vector2.ZERO)

## lát ảnh theo chiều ngang trong khoảng [a0, a1] (cắt ảnh ở hai đầu)
func _tile_clip(tx: Texture2D, src: Rect2, dw: float, y: float, h: float, a0: float, a1: float, flip := false, seg := Transform2D()) -> void:
	# lật dọc: soi gương quanh giữa dải (Godot không vẽ được hình chữ nhật âm)
	draw_set_transform_matrix(seg * Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2(0, 2 * y + h)) if flip else seg)
	var x = floor(a0 / dw) * dw
	while x < a1:
		var l: float = max(x, a0)
		var r: float = min(x + dw, a1)
		if r > l:
			var u0 = (l - x) / dw
			var u1 = (r - x) / dw
			var s = Rect2(src.position.x + src.size.x * u0, src.position.y, src.size.x * (u1 - u0), src.size.y)
			var dst = Rect2(l, y, r - l + 0.6, h)
			draw_texture_rect_region(tx, dst, s)
		x += dw

func _ground(cx: float, cy: float, vw: float, vh: float) -> void:
	var T: Array = M.get("terr", [[0, GY], [M.w, GY]])
	var gr = _side("ground_" + theme)
	var gt = Data.tex(gr.get("u", ""))
	var base = Color.html(str(M.get("base", "#5c9e3f")))
	for i in T.size() - 1:
		var x0: float = T[i][0]
		var y0: float = T[i][1]
		var x1: float = T[i + 1][0]
		var y1: float = T[i + 1][1]
		if x1 <= x0 or x1 < cx - 4 or x0 > cx + vw + 4:
			continue
		var k = (y1 - y0) / (x1 - x0)
		var a0: float = max(x0, cx - 4) - 0.6
		var a1: float = min(x1, cx + vw + 4) + 0.6
		var seg = Transform2D(Vector2(1, k), Vector2(0, 1), Vector2(0, y0 - GY - k * x0))
		draw_set_transform_matrix(seg)
		if gt:
			var iw = float(gt.get_width())
			var ih = float(gt.get_height())
			var h = GRD_H
			var dw: float = h * gr.w / gr.h
			var y: float = GY - h * float(gr.get("top", 0)) + 4
			_tile_clip(gt, Rect2(0, 0, iw, ih), dw, y, h, a0, a1, false, seg)
			var yb = y + h - 2
			var bsrc = Rect2(0, ih * 0.45, iw, ih * 0.55)
			var bh = h * 0.55
			var lim = cy + vh + 30 - (y0 - GY)
			var f = false
			while yb < lim:
				f = not f
				_tile_clip(gt, bsrc, dw, yb, bh, a0, a1, f, seg)
				yb += bh - 1
		else:
			draw_rect(Rect2(a0, GY, a1 - a0, cy + vh - GY + 300), base)
	draw_set_transform(Vector2.ZERO)
	# vách khối đất: bóng ở chân vách + mép vẽ sẵn
	for i in T.size() - 1:
		var x0: float = T[i][0]
		var y0: float = T[i][1]
		var x1: float = T[i + 1][0]
		var y1: float = T[i + 1][1]
		if x1 != x0 or absf(y1 - y0) < 2 or x0 < cx - 60 or x0 > cx + vw + 60:
			continue
		var top: float = min(y0, y1)
		var bot: float = max(y0, y1)
		var dir = 1 if y1 < y0 else -1
		_ellipse(Vector2(x0 - dir * 14, bot + 2), 48, 9, Color(0, 0, 0, 0.22))
		var cap = _side(("capL_" if dir > 0 else "capR_") + theme)
		var ct = Data.tex(cap.get("u", ""))
		if ct and gr.has("h"):
			var tk: float = cap.get("tk", 4)
			var wc: float = cap.w * GRD_H / gr.h / tk
			var hc: float = wc * cap.h / cap.w
			var dx: float = x0 - float(cap.get("wall", 0)) * wc + (-1 if dir > 0 else 1)
			draw_texture_rect(ct, Rect2(dx, top + 4 - float(cap.get("top", 0)) * hc, wc, hc), false)
		else:
			draw_rect(Rect2(x0 if dir > 0 else x0 - 3, top + 8, 3, bot - top + 30), Color(0.08, 0.05, 0.02, 0.5))

func _spr(k: String, x: float, gyv: float, s: float, ay := 0.95) -> void:
	var a = _ai(k)
	var tx = Data.tex(a.get("u", ""))
	if tx == null:
		return
	var w: float = a.w * s
	var h: float = a.h * s
	draw_texture_rect(tx, Rect2(x - w / 2, gyv - h * ay, w, h), false)

func _decor(d: Dictionary) -> void:
	match d.k:
		"tree": _spr("tree%d" % int(d.v), d.x, d.gy, d.s * 1.25)
		"bush": _spr("bush" + theme, d.x, d.gy, d.s)
		"rock": _spr("rock" + theme, d.x, d.gy, d.s)
		"house": _spr("house%d" % int(d.v), d.x, d.gy, DSC.house)
		"fountain": _spr("fountain", d.x, d.gy, 1.0)
		"sign": _sign(d)

func _sign(d: Dictionary) -> void:
	var a = _ai("sign")
	var tx = Data.tex(a.get("u", ""))
	var f: Font = Data.fonts.get("bold")
	var n1: String = d.txt[0]
	var n2: String = d.txt[1]
	var W: float = a.get("w", 80)
	var H: float = a.get("h", 105)
	var t1 = f.get_string_size(n1, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var t2 = f.get_string_size(n2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var bw: float = max(W * 0.86, max(t1, t2) + 26)
	var ox: float = d.x - W / 2
	var oy: float = d.gy - H * 0.96
	if tx:
		var iw = float(tx.get_width())
		var ih = float(tx.get_height())
		draw_texture_rect(tx, Rect2(ox, oy, W, H), false)
		# tấm ván kéo dài cho vừa chữ (3 mảnh)
		var sy = ih * 0.24
		var sh = ih * 0.36
		var dy = oy + H * 0.24
		var dh = H * 0.36
		var cap = iw * 0.26
		var dcap = W * 0.26
		var bx: float = d.x - bw / 2 - W * 0.035
		draw_texture_rect_region(tx, Rect2(bx, dy, dcap, dh), Rect2(0, sy, cap, sh))
		draw_texture_rect_region(tx, Rect2(bx + dcap, dy, bw - 2 * dcap, dh), Rect2(cap, sy, iw - 2 * cap, sh))
		draw_texture_rect_region(tx, Rect2(bx + bw - dcap, dy, dcap, dh), Rect2(iw - cap, sy, cap, sh))
	var mx: float = d.x - W * 0.02
	var my: float = oy + H * 0.24 + H * 0.18
	draw_string_outline(f, Vector2(mx - t1 / 2, my - 2), n1, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(1, 0.93, 0.78, 0.55))
	draw_string(f, Vector2(mx - t1 / 2, my - 2), n1, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("3a2410"))
	draw_string(f, Vector2(mx - t2 / 2, my + 12), n2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a3b10"))

func _npc(n: Dictionary) -> void:
	_spr(str(n.id), n.x, n.y, DSC.npc)
	var f: Font = Data.fonts.get("bold")
	var a = _ai(str(n.id))
	var top: float = n.y - float(a.get("h", 190)) * DSC.npc * 0.95 - 8
	for i in 2:
		var s: String = n.name if i == 0 else n.role
		var sz = 16 if i == 0 else 12
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var y = top - (18 if i == 0 else 2)
		draw_string_outline(f, Vector2(n.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 5, UI.INK)
		draw_string(f, Vector2(n.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("ffd23f") if i == 0 else Color.WHITE)
	if near_npc == str(n.id):
		var b = -top + n.y
		draw_string_outline(f, Vector2(n.x - 40, top - 40 + sin(t * 4) * 3), "Bấm để nói chuyện", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, UI.INK)
		draw_string(f, Vector2(n.x - 40, top - 40 + sin(t * 4) * 3), "Bấm để nói chuyện", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9be05a"))

func _portal(p: Dictionary) -> void:
	var a = _ai("gate")
	var glow = 0.5 + sin(t * 3) * 0.2
	_ellipse(Vector2(p.x, p.y - 50), 46, 62, Color(0.6, 0.9, 1, 0.22 * glow))
	_spr("gate", p.x, p.y, 1.0)
	var f: Font = Data.fonts.get("bold")
	var top: float = p.y - float(a.get("h", 115)) - 10
	for i in 2:
		var s: String = p.label if i == 0 else p.lv
		var sz = 15 if i == 0 else 12
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var y = top - (14 if i == 0 else 0)
		draw_string_outline(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 5, UI.INK)
		draw_string(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color.WHITE)

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 24:
		var a = TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
