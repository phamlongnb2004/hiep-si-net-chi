extends Node2D
class_name World
## Nền và địa hình: trời, núi xa, lớp giữa (cuộn chậm), dải mặt đất theo từng đoạn bậc/dốc, mép vách, cảnh vật, cổng, NPC.
## Vẽ giống tools/side.js để hai bản trông như nhau.

const GY := 600.0
const GRD_H := 250.0
const SKY := {"grass": ["7cc8ff", "d9f1ff"], "snow": ["a9cbe6", "eef6fb"], "lava": ["3a1414", "a2462a"],
	"beach": ["4fb4f5", "cdeefc"], "reef": ["1d6fa3", "5ec3d6"], "swamp": ["2a2340", "6b6a5a"], "cave": ["0d1b33", "2a4f73"],
	"bamboo": ["5fc4f2", "d6f3ff"], "bamboocave": ["10261c", "2f5a3e"],
	"desert": ["6fc3f5", "fbe7b5"], "desertcave": ["5a3a20", "b07a40"],
	"canyon": ["f08c5a", "ffd6a0"], "canyoncave": ["3a1410", "8a3a22"],
	"sakura": ["8fd0ff", "ffe3ef"], "sakuracave": ["2a1840", "6a4a8a"],
	"glow": ["0b1033", "2a2f6b"], "glowcave": ["0a0c24", "2a2a5a"]}
const HAZE := {"grass": Color(0.82, 0.92, 1, 0.16), "snow": Color(0.88, 0.93, 0.99, 0.2), "lava": Color(0.12, 0.02, 0.03, 0.42),
	"beach": Color(0.9, 0.97, 1, 0.06), "reef": Color(0.1, 0.45, 0.65, 0.18), "swamp": Color(0.3, 0.55, 0.28, 0.12), "cave": Color(0.02, 0.05, 0.12, 0.3),
	"bamboo": Color(0.85, 0.97, 0.95, 0.08), "bamboocave": Color(0.02, 0.08, 0.05, 0.22),
	"desert": Color(1, 0.95, 0.8, 0.07), "desertcave": Color(0.15, 0.08, 0.02, 0.2),
	"canyon": Color(1, 0.8, 0.6, 0.08), "canyoncave": Color(0.15, 0.03, 0.02, 0.22),
	"sakura": Color(1, 0.9, 0.95, 0.07), "sakuracave": Color(0.08, 0.02, 0.1, 0.22),
	"glow": Color(0.05, 0.08, 0.25, 0.18), "glowcave": Color(0.02, 0.03, 0.12, 0.25)}
## cảnh vật của các bộ bản đồ mới (vẽ tách mảnh): cây/cao, bụi/thấp, đá/nhỏ, hiếm
const KIT := {
	"beach": {"tree": ["beach_tree0", "beach_tree1", "beach_tree2"], "bush": ["beach_bush", "beach_shell"], "rock": ["beach_rock", "beach_starfish"], "rare": ["beach_boat"]},
	"reef": {"tree": ["reef_kelp0", "reef_kelp1", "reef_kelp2"], "bush": ["reef_coral", "reef_anemone"], "rock": ["reef_rock", "reef_column"], "rare": ["reef_chest"]},
	"swamp": {"tree": ["swamp_tree0", "swamp_tree1", "swamp_tree2"], "bush": ["swamp_reeds", "swamp_mush"], "rock": ["swamp_rock", "swamp_pool"], "rare": ["swamp_sign"]},
	"cave": {"tree": [], "bush": ["cave_shell"], "rock": ["cave_rock"], "rare": ["cave_boat"]},
	"bamboo": {"tree": ["bamboo_tree0", "bamboo_tree1", "bamboo_tree0"], "bush": ["bamboo_bush", "bamboo_lantern"], "rock": ["bamboo_rock", "bamboo_sign"], "rare": ["bamboo_shrine"]},
	"bamboocave": {"tree": [], "bush": ["bamboo_lantern"], "rock": ["bamboo_rock"], "rare": ["bamboo_lantern"]},
	"desert": {"tree": ["desert_tree0", "desert_tree1", "desert_tree0"], "bush": ["desert_bush", "desert_deco0"], "rock": ["desert_rock", "desert_sign"], "rare": ["desert_deco1"]},
	"desertcave": {"tree": [], "bush": ["desert_deco0"], "rock": ["desert_rock"], "rare": ["desert_deco0"]},
	"canyon": {"tree": ["canyon_tree0", "canyon_tree1", "canyon_tree0"], "bush": ["canyon_bush", "canyon_deco0"], "rock": ["canyon_rock", "canyon_sign"], "rare": ["canyon_deco1"]},
	"canyoncave": {"tree": [], "bush": ["canyon_deco0"], "rock": ["canyon_rock"], "rare": ["canyon_deco0"]},
	"sakura": {"tree": ["sakura_tree0", "sakura_tree1", "sakura_tree0"], "bush": ["sakura_bush", "sakura_deco0"], "rock": ["sakura_rock", "sakura_sign"], "rare": ["sakura_deco1"]},
	"sakuracave": {"tree": [], "bush": ["sakura_deco0"], "rock": ["sakura_rock"], "rare": ["sakura_deco0"]},
	"glow": {"tree": ["glow_tree0", "glow_tree1", "glow_tree0"], "bush": ["glow_bush", "glow_deco0"], "rock": ["glow_rock", "glow_sign"], "rare": ["glow_deco1"]},
	"glowcave": {"tree": [], "bush": ["glow_deco0"], "rock": ["glow_rock"], "rare": ["glow_deco0"]}}
## cổng khu trùm theo chủ đề (bản đồ cũ mượn cổng hang, tô màu)
const GATE := {"beach": ["beach_gate", Color.WHITE], "reef": ["reef_gate", Color.WHITE], "swamp": ["swamp_gate", Color.WHITE],
	"grass": ["swamp_gate", Color(0.85, 1.0, 0.8)], "snow": ["swamp_gate", Color(0.8, 0.92, 1.1)], "lava": ["swamp_gate", Color(1.2, 0.6, 0.45)], "cave": ["beach_gate", Color.WHITE],
	"bamboo": ["bamboo_gate", Color.WHITE], "bamboocave": ["bamboo_gate", Color.WHITE],
	"desert": ["desert_gate", Color.WHITE], "desertcave": ["desert_gate", Color.WHITE],
	"canyon": ["canyon_gate", Color.WHITE], "canyoncave": ["canyon_gate", Color.WHITE],
	"sakura": ["sakura_gate", Color.WHITE], "sakuracave": ["sakura_gate", Color.WHITE],
	"glow": ["glow_gate", Color.WHITE], "glowcave": ["glow_gate", Color.WHITE]}
## cổng riêng của từng khu trùm (theo bản đồ đích)
const ARENA_GATE := {7: "gate_boar", 8: "gate_wolf", 9: "gate_volcano", 10: "gate_crab", 11: "gate_turtle", 12: "gate_snake"}
const DSC := {"house": 1.3, "npc": 0.74}
const BACK_Z := -10

var M: Dictionary = {}
var mi = 0
var theme = "grass"
var decor: Array = []      # {k, x, gy, s, v, txt}
var cam_rect = Rect2(0, 0, 1280, 720)
var near_npc = ""
var rope_hint = Vector2.INF   # đứng cạnh dây/thang: hiện gợi ý bấm nhảy để leo
var t = 0.0
var hatch = null          # trứng đang ấp của mình (vẽ trên tổ cạnh Bà Ấp Trứng)

## lớp phủ phía trước: dưới nước (tia sáng, bong bóng), sương đầm lầy, hang tối
class Overlay extends Node2D:
	var w
	var bub: Array = []
	func _process(dt: float) -> void:
		if w.theme == "reef":
			if randf() < dt * 6:
				bub.append({"p": Vector2(w.cam_rect.position.x + randf() * w.cam_rect.size.x, w.cam_rect.end.y + 10), "s": randf_range(2, 6), "v": randf_range(40, 90), "ph": randf() * 6})
			for b in bub:
				b.p.y -= b.v * dt
				b.p.x += sin(w.t * 2 + b.ph) * 12 * dt
			bub = bub.filter(func(b): return b.p.y > w.cam_rect.position.y - 20)
		queue_redraw()
	func _draw() -> void:
		var r: Rect2 = w.cam_rect.grow(4)
		match w.theme:
			"reef":
				draw_rect(r, Color(0.1, 0.45, 0.7, 0.13))
				for i in 6:
					var x = r.position.x + fmod(i * 260.0 - r.position.x * 0.3 + sin(w.t * 0.4 + i) * 30, r.size.x + 300) - 150
					var a = 0.05 + 0.03 * sin(w.t * 0.9 + i * 1.7)
					draw_colored_polygon(PackedVector2Array([Vector2(x, r.position.y), Vector2(x + 70, r.position.y), Vector2(x + 250, r.end.y), Vector2(x + 110, r.end.y)]),
						Color(0.8, 1, 1, a))
				for b in bub:
					draw_arc(b.p, b.s, 0, TAU, 12, Color(0.85, 1, 1, 0.55), 1.2)
			"swamp":
				for i in 5:
					var x = r.position.x + fmod(i * 330.0 + w.t * 14.0 - r.position.x * 0.15, r.size.x + 400) - 200
					w._ellipse_on(self, Vector2(x, 590 + sin(w.t + i) * 6), 260, 46, Color(0.55, 0.75, 0.45, 0.10))
			"cave":
				draw_rect(r, Color(0.02, 0.04, 0.1, 0.12))

var _ov: Overlay

func _ellipse_on(n: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 24:
		var a = TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	n.draw_colored_polygon(pts, col)

func setup(map_index: int) -> void:
	mi = map_index
	M = Data.D.maps[mi]
	theme = str(M.theme)
	if _ov == null:
		_ov = Overlay.new()
		_ov.w = self
		_ov.z_index = 40
		_ov.z_as_relative = false
		add_child(_ov)
	_gen_decor()
	queue_redraw()

func gy(x: float) -> float:
	return Data.ground_y(M, x)

## màu mép trên của ảnh núi xa từng vùng (đo từ ảnh side/far_*/u.webp)
const FAR_TOP := {"grass": "#43aafd", "snow": "#449ff6", "lava": "#421a2b", "beach": "#137ef2", "reef": "#66e4f8", "swamp": "#4934a1", "cave": "#284b6f", "bamboo": "#46c2fd", "bamboocave": "#3f6538", "desert": "#5bacfc", "desertcave": "#883e2a", "canyon": "#9872bf", "canyoncave": "#781719", "sakura": "#8b96e4", "sakuracave": "#8b3983", "glow": "#1c2590", "glowcave": "#1d1f4a"}

func _side(k: String) -> Dictionary:
	return Data.A.get("side", {}).get(k, {})

func _ai(k: String) -> Dictionary:
	return Data.A.get("ai", {}).get(k, {})

func _gen_decor() -> void:
	decor.clear()
	var r = RandomNumberGenerator.new()
	r.seed = 4242 + mi * 31
	var trees: Array = {"grass": [0, 1, 2], "snow": [3, 3, 3], "lava": [4, 4, 4]}.get(theme, [0, 1, 2])
	var kit: Dictionary = KIT.get(theme, {})
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
			if not kit.is_empty():
				var grp = "tree" if k < 0.3 else ("bush" if k < 0.62 else ("rock" if k < 0.93 else "rare"))
				var L: Array = kit[grp]
				if L.is_empty():
					L = kit.rock
				decor.append({"k": "kit", "x": x, "s": 0.7 + r.randf() * 0.25 if grp == "tree" else 0.7 + r.randf() * 0.35, "v": L[r.randi() % L.size()], "dy": 6})
				x += 60 + r.randf() * 80
			elif k < 0.5:
				decor.append({"k": "tree", "x": x, "s": 0.85 + r.randf() * 0.5, "v": trees[r.randi() % 3], "dy": 6 + r.randf() * 4})
			elif k < 0.75:
				decor.append({"k": "bush", "x": x, "s": 0.8 + r.randf() * 0.5, "dy": 5})
			else:
				decor.append({"k": "rock", "x": x, "s": 0.7 + r.randf() * 0.6, "dy": 5})
		x += 70 + r.randf() * 90
	for h in M.get("houses", []):
		decor.append({"k": "house", "x": float(h[0]), "v": int(h[1]), "dy": 6})
	if M.get("fountain") != null:
		decor.append({"k": "fountain", "x": float(M.fountain), "dy": 5})
	for s in M.spots:
		if s.get("p") != null:
			var pl: Array = M.plats[int(s.p)]
			var lvp = "Cấp %d" % int(s.lv[0]) + ("-%d" % int(s.lv[1]) if s.lv[1] > s.lv[0] else "")
			decor.append({"k": "sign", "x": float(pl[0]) + 34, "txt": [str(s.n), lvp], "dy": 5, "py": float(pl[1])})
			continue
		var sx: float = s.x + 60
		while sx < s.x + s.w / 2 and absf(gy(sx - 50) - gy(sx + 50)) > 1:
			sx += 10
		var lvt = "Cấp %d" % int(s.lv[0]) + ("-%d" % int(s.lv[1]) if s.lv[1] > s.lv[0] else "")
		decor.append({"k": "sign", "x": sx, "txt": [str(s.n), lvt], "dy": 5})
	for d in decor:
		d.gy = (float(d.py) if d.has("py") else gy(d.x)) + d.dy
	# không đặt cây/đá trong vũng nước, dung nham
	decor = decor.filter(func(d): return d.k in ["sign", "house", "fountain"] or not (Data.in_zone(M.get("water", []) + M.get("lava", []), d.x, d.gy - 10)))

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
	# trời gắn theo toạ độ bản đồ (không co giãn theo máy quay khi nhảy)
	var top = GY - 900.0
	if cy < top:
		draw_rect(Rect2(cx - 2, cy - 2, vw + 4, top - cy + 4), c0)
	draw_polygon(PackedVector2Array([Vector2(cx - 2, top), Vector2(cx + vw + 2, top), Vector2(cx + vw + 2, GY), Vector2(cx - 2, GY)]), PackedColorArray([c0, c0, c1, c1]))
	draw_rect(Rect2(cx - 2, GY, vw + 4, max(0.0, cy + vh - GY + 2)), c1)
	# núi xa và lớp giữa cuộn chậm: cao cố định theo bản đồ, không phóng to khi máy quay lên cao
	var far = _side("far_" + theme)
	if not far.is_empty():
		var h: float = 620.0
		# phía trên ảnh núi xa (máy quay lên cao): tô đúng màu mép trên của ảnh để không lộ khoảng trời khác màu
		var ft = GY + 30 - h
		if cy < ft + 2:
			draw_rect(Rect2(cx - 2, cy - 2, vw + 4, ft - cy + 6), Color.html(FAR_TOP.get(theme, sk[0])))
		_tile_par(far, cx, ft, h, vw, 0.82)
	var mid = _side("mid_" + theme)
	if not mid.is_empty():
		var h2: float = 720.0 * (0.36 if KIT.has(theme) else 0.42)
		_tile_par(mid, cx, GY - h2 * 0.94, h2, vw, 0.5)
	# sương phủ cảnh nền
	var hz: Color = HAZE.get(theme, HAZE.grass)
	draw_rect(Rect2(cx - 2, cy - 2, vw + 4, vh + 4), hz)
	if theme == "lava":
		var a = Color(1, 0.35, 0.16, 0)
		var b = Color(1, 0.35, 0.16, 0.10)
		draw_polygon(PackedVector2Array([Vector2(cx - 2, GY - 260), Vector2(cx + vw + 2, GY - 260), Vector2(cx + vw + 2, GY), Vector2(cx - 2, GY)]), PackedColorArray([a, a, b, b]))
	_ground(cx, cy, vw, vh)
	_layers(cx, vw)
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
	_rope_hint()

## nước nông / bùn / dung nham, bậc nổi, cầu treo, dây leo và thang (bản đồ nhiều tầng)
const WATER := {"beach": [Color(0.25, 0.65, 0.9, 0.55), Color(0.85, 0.97, 1, 0.9)], "reef": [Color(0.2, 0.55, 0.8, 0.45), Color(0.8, 0.95, 1, 0.8)],
	"swamp": [Color(0.32, 0.38, 0.18, 0.75), Color(0.6, 0.75, 0.35, 0.9)], "cave": [Color(0.15, 0.35, 0.6, 0.6), Color(0.6, 0.85, 1, 0.8)],
	"grass": [Color(0.3, 0.6, 0.9, 0.55), Color(0.85, 0.95, 1, 0.9)], "bamboo": [Color(0.3, 0.7, 0.75, 0.55), Color(0.85, 1, 0.95, 0.9)], "desert": [Color(0.25, 0.7, 0.8, 0.6), Color(0.85, 1, 1, 0.9)], "sakura": [Color(0.4, 0.65, 0.85, 0.55), Color(1, 0.9, 0.95, 0.9)], "glow": [Color(0.2, 0.4, 0.9, 0.55), Color(0.6, 0.9, 1, 0.95)], "snow": [Color(0.55, 0.75, 0.95, 0.6), Color(0.95, 1, 1, 0.95)], "lava": [Color(0.3, 0.6, 0.9, 0.5), Color(1, 1, 1, 0.8)]}
const VINE := ["reef", "swamp"]
const LADDER := {"bamboo": "ladder_bamboo", "bamboocave": "ladder_bamboo", "sakura": "ladder_bamboo", "swamp": "ladder_bamboo", "beach": "ladder_bamboo", "reef": "ladder_bamboo"}

func _layers(cx: float, vw: float) -> void:
	for w in M.get("water", []):
		if float(w[1]) < cx - 20 or float(w[0]) > cx + vw + 20:
			continue
		var col: Array = WATER.get(theme, WATER.beach)
		var y = float(w[2])
		var bot = gy((float(w[0]) + float(w[1])) / 2) + 6
		draw_rect(Rect2(float(w[0]), y, float(w[1]) - float(w[0]), bot - y), col[0])
		var pts = PackedVector2Array()
		var x = float(w[0])
		while x <= float(w[1]):
			pts.append(Vector2(x, y + sin(x * 0.05 + t * 2.4) * 2.5))
			x += 8
		draw_polyline(pts, col[1], 3)
	for w in M.get("lava", []):
		if float(w[1]) < cx - 20 or float(w[0]) > cx + vw + 20:
			continue
		var y2 = float(w[2])
		var bot2 = gy((float(w[0]) + float(w[1])) / 2) + 8
		draw_rect(Rect2(float(w[0]), y2, float(w[1]) - float(w[0]), bot2 - y2), Color(0.95, 0.35, 0.08))
		draw_rect(Rect2(float(w[0]), y2, float(w[1]) - float(w[0]), 10), Color(1, 0.75, 0.25))
		var x2 = float(w[0]) + 10
		var k = 0
		while x2 < float(w[1]) - 10:
			var ph = fmod(t * 0.8 + k * 0.37, 1.0)
			draw_circle(Vector2(x2 + sin(k * 7.0) * 12, y2 + 6 - ph * 10), 3 + 4 * sin(ph * PI), Color(1, 0.85, 0.4, 1 - ph))
			x2 += 38
			k += 1
		_ellipse(Vector2((float(w[0]) + float(w[1])) / 2, y2), (float(w[1]) - float(w[0])) * 0.6, 60, Color(1, 0.45, 0.1, 0.10 + 0.04 * sin(t * 3)))
	var pi = _side("plat_" + theme)
	var ptx = Data.tex(pi.get("u", ""))
	for pl in M.get("plats", []):
		var x0: float = pl[0]
		var x1: float = pl[2]
		if x1 < cx - 60 or x0 > cx + vw + 60:
			continue
		if pl.size() > 4 and str(pl[4]) == "bridge":
			_bridge(pl)
		elif ptx:
			var wd = x1 - x0 + 24
			var dh = clampf(wd * float(pi.h) / float(pi.w), 52, 96)
			_ellipse(Vector2((x0 + x1) / 2, gy((x0 + x1) / 2) + 2), (x1 - x0) * 0.4, 8, Color(0, 0, 0, 0.12))
			draw_texture_rect(ptx, Rect2(x0 - 12, float(pl[1]) - float(pi.get("top", 0.12)) * dh, wd, dh), false)
		else:
			draw_rect(Rect2(x0, float(pl[1]), x1 - x0, 18), Color("8a6a43"))
	for r in M.get("ropes", []):
		var rx: float = r[0]
		if rx < cx - 40 or rx > cx + vw + 40:
			continue
		var lad: bool = r.size() > 3 and str(r[3]) == "ladder"
		var k: String = (LADDER.get(theme, "ladder_wood") if lad else ("vine" if theme in VINE else "rope"))
		var sw = 0.0 if lad else sin(t * 1.3 + rx) * 2.0
		if not _tile_v(k, rx + sw, float(r[1]) - (6 if lad else 4), float(r[2]) - (0 if lad else 6)):
			draw_line(Vector2(rx, float(r[1])), Vector2(rx, float(r[2])), Color("6e4a22"), 5)

## thang/dây: một khúc ảnh lặp theo chiều dọc, khúc cuối cắt bớt cho vừa
func _tile_v(k: String, x: float, y0: float, y1: float) -> bool:
	var a = _ai(k)
	if a.is_empty():
		return false
	var tx = Data.tex(a.u)
	if tx == null:
		return false
	var w: float = a.w
	var h: float = a.h
	var ts: Vector2 = tx.get_size()
	var y = y0
	while y < y1 - 0.5:
		var hh = minf(h, y1 - y)
		draw_texture_rect_region(tx, Rect2(x - w / 2, y, w, hh), Rect2(0, 0, ts.x, ts.y * hh / h))
		y += h
	return true

## cầu treo: ván gỗ võng xuống giữa, dây hai bên
func _rope_hint() -> void:
	if rope_hint == Vector2.INF:
		return
	var f: Font = Data.fonts.get("bold")
	var s = "▲ Nhảy để leo"
	var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var p = rope_hint + Vector2(-w / 2, -96 + sin(t * 4) * 3)
	draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, UI.INK)
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9be05a"))

## cầu treo: ván (một tấm ảnh lặp dọc theo đường võng), dây tay vịn (một khúc ảnh xoay theo đường cong),
## cọc hai đầu. Thiếu ảnh thì vẽ tay như cũ.
func _bridge(pl: Array) -> void:
	var x0: float = pl[0]
	var y0: float = pl[1]
	var x1: float = pl[2]
	var y1: float = pl[3]
	var sx = "_bamboo" if theme in ["beach", "reef", "swamp", "bamboo", "bamboocave", "sakura"] else ""
	var pk = _ai("bridge_plank" + sx)
	var rp = _ai("bridge_rope" + sx)
	var po = _ai("bridge_post" + sx)
	if not pk.is_empty() and not rp.is_empty() and not po.is_empty():
		_bridge_art(x0, y0, x1, y1, pk, rp, po)
		return
	var n = int((x1 - x0) / 26)
	var rope = PackedVector2Array()
	for i in n + 1:
		var u = float(i) / n
		var x = lerpf(x0, x1, u)
		var y = lerpf(y0, y1, u) + sin(u * PI) * 6
		draw_rect(Rect2(x - 11, y - 2, 22, 11), Color("5a3818"))
		draw_rect(Rect2(x - 10, y - 1, 20, 8), Color("b57a3e"))
		rope.append(Vector2(x, y - 34 + sin(u * PI) * 8))
		if i % 2 == 0:
			draw_line(Vector2(x, y - 1), Vector2(x, y - 34 + sin(u * PI) * 8), Color("6e4a22"), 2)
	draw_polyline(rope, Color("6e4a22"), 3)
	for xx in [x0, x1]:
		var yy = y0 if xx == x0 else y1
		draw_rect(Rect2(xx - 5, yy - 44, 10, 46), Color("5a3818"))

func _bridge_art(x0: float, y0: float, x1: float, y1: float, pk: Dictionary, rp: Dictionary, po: Dictionary) -> void:
	var sag = 4.0
	var deck = func(u: float) -> Vector2:
		return Vector2(lerpf(x0, x1, u), lerpf(y0, y1, u) + sin(u * PI) * sag)
	var rail = func(u: float) -> Vector2:
		return Vector2(lerpf(x0, x1, u), lerpf(y0, y1, u) - 40.0 + sin(u * PI) * 14.0)
	var L = x1 - x0
	# dây treo dọc: nối tay vịn xuống ván, mỗi tấm thứ hai
	var pw: float = pk.w
	var n = max(2, int(round(L / pw)))
	var ptx = Data.tex(pk.u)
	var rtx = Data.tex(rp.u)
	for i in n + 1:
		if i % 2 == 0:
			var u = float(i) / n
			draw_line(deck.call(u) + Vector2(0, -2), rail.call(u), Color("8a6434"), 2.5)
	# tay vịn sau (mờ hơn), rồi ván, rồi tay vịn trước
	_rope_curve(rtx, rp, rail, L, Color(0.78, 0.74, 0.7, 1.0), Vector2(0, 4))
	for i in n:
		var u = (i + 0.5) / n
		var c: Vector2 = deck.call(u)
		var d: Vector2 = deck.call(minf(1.0, u + 0.01)) - deck.call(maxf(0.0, u - 0.01))
		draw_set_transform(c, d.angle(), Vector2.ONE)
		# đổi tấm theo vị trí cho đỡ lặp
		var tw = L / n + 1.0
		draw_texture_rect(ptx, Rect2(-tw / 2, -float(pk.h) * 0.35, tw, pk.h), false, Color(1, 1, 1) if i % 3 else Color(0.92, 0.88, 0.84))
	draw_set_transform(Vector2.ZERO)
	_rope_curve(rtx, rp, rail, L, Color.WHITE, Vector2.ZERO)
	var otx = Data.tex(po.u)
	for e in [[x0, y0], [x1, y1]]:
		draw_texture_rect(otx, Rect2(e[0] - float(po.w) / 2, e[1] - float(po.h) + 10, po.w, po.h), false)

## dây cong: ghép các khúc ảnh dây nằm ngang, mỗi khúc xoay theo hướng đường cong
func _rope_curve(tx: Texture2D, rp: Dictionary, f: Callable, L: float, col: Color, off: Vector2) -> void:
	var sw: float = rp.w
	var m = max(2, int(ceil(L / sw)))
	for i in m:
		var a: Vector2 = f.call(float(i) / m) + off
		var b: Vector2 = f.call(float(i + 1) / m) + off
		draw_set_transform((a + b) / 2, (b - a).angle(), Vector2.ONE)
		var len = a.distance_to(b) + 1.0
		draw_texture_rect(tx, Rect2(-len / 2, -float(rp.h) / 2, len, rp.h), false, col)
	draw_set_transform(Vector2.ZERO)

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
			var h: float = float(gr.get("gh", GRD_H))
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
		if ct and cap.has("dh"):
			var hk: float = cap.dh
			var wk: float = hk * cap.w / cap.h
			draw_texture_rect(ct, Rect2(x0 - float(cap.wall) * wk, top - float(cap.top) * hk, wk, hk), false)
		elif ct and gr.has("h"):
			var tk: float = cap.get("tk", 4)
			var wc: float = cap.w * GRD_H / gr.h / tk
			var hc: float = wc * cap.h / cap.w
			var dx: float = x0 - float(cap.get("wall", 0)) * wc + (-1 if dir > 0 else 1)
			draw_texture_rect(ct, Rect2(dx, top + 4 - float(cap.get("top", 0)) * hc, wc, hc), false)
		else:
			draw_rect(Rect2(x0 if dir > 0 else x0 - 3, top + 8, 3, bot - top + 30), Color(0.08, 0.05, 0.02, 0.5))

func _spr(k: String, x: float, gyv: float, s: float, ay := 0.95, mod := Color.WHITE) -> void:
	var a = _ai(k)
	var tx = Data.tex(a.get("u", ""))
	if tx == null:
		return
	var w: float = a.w * s
	var h: float = a.h * s
	draw_texture_rect(tx, Rect2(x - w / 2, gyv - h * ay, w, h), false, mod)

func _decor(d: Dictionary) -> void:
	match d.k:
		"tree": _spr("tree%d" % int(d.v), d.x, d.gy, d.s * 1.25)
		"bush": _spr("bush" + theme, d.x, d.gy, d.s)
		"rock": _spr("rock" + theme, d.x, d.gy, d.s)
		"house": _spr("house%d" % int(d.v), d.x, d.gy, DSC.house)
		"fountain": _spr("fountain", d.x, d.gy, 1.0)
		"sign": _sign(d)
		"kit": _spr(d.v, d.x, d.gy, d.s)

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
	if str(n.id) == "egg":
		_npc_egg(n)
		return
	_spr("shop" if str(n.id) == "gear" else str(n.id), n.x, n.y + 5, DSC.npc, 0.95, Color(0.75, 0.88, 1.0) if str(n.id) == "gear" else Color.WHITE)
	var f: Font = Data.fonts.get("bold")
	var a = _ai("shop" if str(n.id) == "gear" else str(n.id))
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

## khung động tác từ assets.json (npc_egg, nest): trả ảnh theo thời gian
func _anim_tex(a: Dictionary, act: String, fps: float, ofs: float) -> Texture2D:
	var L: Array = a.get("a", {}).get(act, a.get("a", {}).get("idle", []))
	if L.is_empty():
		return null
	return Data.tex(L[int(t * fps + ofs) % L.size()])

## Bà Ấp Trứng: đứng cạnh tổ ấp; tổ sáng khi đang ấp trứng của mình, trứng lấp lánh khi đã sẵn sàng nở
func _npc_egg(n: Dictionary) -> void:
	var A: Dictionary = Data.A
	var na: Dictionary = A.get("npc_egg", {})
	var ne: Dictionary = A.get("nest", {})
	var H := 140.0
	if not ne.is_empty():
		var nh := 62.0
		var nw: float = nh * float(ne.w) / float(ne.h)
		var on = hatch is Dictionary
		var ntx = _anim_tex(ne, "on" if on else "idle", 6.0, 0.0)
		var nx: float = n.x + 92
		if ntx:
			draw_texture_rect(ntx, Rect2(nx - nw / 2, n.y + 4 - nh, nw, nh), false)
		if on:
			var eg: Dictionary = A.get("egg", {}).get(str(hatch.get("sp", "fire")), {})
			if not eg.is_empty():
				var ready = float(hatch.get("end", 0)) <= Data.now_ms()
				var ef: Array = eg.f
				var etx = Data.tex(ef[int(t * (9.0 if ready else 4.0)) % ef.size()])
				if etx:
					var eh := 46.0
					draw_texture_rect(etx, Rect2(nx - eh * 0.46, n.y - nh * 0.55 - eh + sin(t * 2.0) * 1.5, eh * 0.92, eh), false)
				if ready:
					var sh: Dictionary = A.get("vfx", {}).get("egg_shine", {})
					if not sh.is_empty():
						var stx = Data.tex(sh.f[int(t * 10) % sh.f.size()])
						if stx:
							draw_texture_rect(stx, Rect2(nx - 50, n.y - nh * 0.55 - 75, 100, 86), false, Color(1, 1, 1, 0.85))
	if not na.is_empty():
		var W: float = H * float(na.w) / float(na.h)
		var act = "talk" if near_npc == "egg" else ("tend" if int(t / 4.0) % 3 == 2 else "idle")
		var tx = _anim_tex(na, act, 6.0, 0.0)
		if tx:
			draw_texture_rect(tx, Rect2(n.x - W * float(na.cx), n.y + 5 - H * 0.97, W, H), false)
	var f: Font = Data.fonts.get("bold")
	var top: float = n.y - H * 0.97 - 6
	for i in 2:
		var s: String = n.name if i == 0 else n.role
		var sz = 16 if i == 0 else 12
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var y = top - (18 if i == 0 else 2)
		draw_string_outline(f, Vector2(n.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 5, UI.INK)
		draw_string(f, Vector2(n.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("ffd23f") if i == 0 else Color.WHITE)
	if near_npc == "egg":
		draw_string_outline(f, Vector2(n.x - 40, top - 40 + sin(t * 4) * 3), "Bấm để nói chuyện", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, UI.INK)
		draw_string(f, Vector2(n.x - 40, top - 40 + sin(t * 4) * 3), "Bấm để nói chuyện", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9be05a"))

func _portal(p: Dictionary) -> void:
	if p.get("arena"):
		_arena_gate(p)
		return
	var a = _ai("gate")
	var glow = 0.5 + sin(t * 3) * 0.2
	_ellipse(Vector2(p.x, p.y - 50), 46, 62, Color(0.6, 0.9, 1, 0.22 * glow))
	_spr("gate", p.x, p.y + 5, 1.0)
	var f: Font = Data.fonts.get("bold")
	var top: float = p.y - float(a.get("h", 115)) - 10
	for i in 2:
		var s: String = p.label if i == 0 else p.lv
		var sz = 15 if i == 0 else 12
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var y = top - (14 if i == 0 else 0)
		draw_string_outline(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 5, UI.INK)
		draw_string(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color.WHITE)

## cổng khu trùm: mở thì sáng và đếm giờ còn lại, đóng thì tối và hiện giờ mở
func _arena_gate(p: Dictionary) -> void:
	var st: Dictionary = Data.arena_state(int(p.to))
	var g: Array = GATE.get(theme, GATE.grass)
	var own: String = ARENA_GATE.get(int(p.to), "")
	if own != "" and not _ai(own).is_empty():
		g = [own, Color.WHITE]
	var op: bool = st.open
	var mod: Color = g[1] if op else g[1] * Color(0.55, 0.55, 0.62)
	if op:
		var glow = 0.5 + sin(t * 3) * 0.25
		_ellipse(Vector2(p.x, p.y - 90), 120, 110, Color(1, 0.75, 0.3, 0.16 * glow))
	_spr(g[0], p.x, p.y + 8, 1.0, 0.97, mod)
	var a = _ai(g[0])
	var f: Font = Data.fonts.get("bold")
	var top: float = p.y - float(a.get("h", 230)) - 12
	var lines = [[str(p.label), 17, Color("ffd23f")], [str(p.lv), 12, Color.WHITE], [st.text, 13, Color("9be05a") if op else Color("ffb3a3")]]
	for i in 3:
		var s: String = lines[i][0]
		var sz: int = lines[i][1]
		var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var y = top - 34 + i * 17
		draw_string_outline(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 5, UI.INK)
		draw_string(f, Vector2(p.x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, lines[i][2])

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 24:
		var a = TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
