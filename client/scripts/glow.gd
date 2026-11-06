extends Control
class_name GlowFrame
## Ánh sáng chạy vòng quanh ô đồ đã cường hóa. Cấp càng cao: càng nhiều vệt sáng, đuôi dài hơn, màu rực hơn,
## +10 trở lên có viền phát sáng và đốm lấp lánh, +13 trở lên đổi màu cầu vồng.

var up = 0
var t = 0.0
var radius = 12.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t = randf() * 10.0

func _process(dt: float) -> void:
	if up <= 0:
		return
	t += dt
	queue_redraw()

func _style() -> Dictionary:
	if up >= 13: return {"n": 3, "col": Color(1, 0.3, 0.3), "len": 0.42, "spd": 0.55, "w": 5.5, "rainbow": true, "aura": 0.55, "spark": 6}
	if up >= 10: return {"n": 2, "col": Color(1.0, 0.62, 0.0), "len": 0.36, "spd": 0.5, "w": 5.0, "rainbow": false, "aura": 0.4, "spark": 4}
	if up >= 7: return {"n": 2, "col": Color(0.7, 0.25, 1.0), "len": 0.32, "spd": 0.42, "w": 4.5, "rainbow": false, "aura": 0.22, "spark": 0}
	if up >= 4: return {"n": 1, "col": Color(0.0, 0.75, 1.0), "len": 0.3, "spd": 0.36, "w": 4.0, "rainbow": false, "aura": 0.0, "spark": 0}
	return {"n": 1, "col": Color(0.35, 0.65, 1.0), "len": 0.22, "spd": 0.3, "w": 3.5, "rainbow": false, "aura": 0.0, "spark": 0}

## điểm trên chu vi hình chữ nhật bo góc theo tỉ lệ u (0..1)
func _perim(u: float) -> Vector2:
	var r = min(radius, min(size.x, size.y) / 2.0)
	var w = size.x - 2 * r
	var h = size.y - 2 * r
	var arc = PI * r / 2.0
	var L = 2 * w + 2 * h + 4 * arc
	var d = fposmod(u, 1.0) * L
	var segs = [w, arc, h, arc, w, arc, h, arc]
	var i = 0
	while i < 8 and d > segs[i]:
		d -= segs[i]
		i += 1
	i = mini(i, 7)
	match i:
		0: return Vector2(r + d, 0)
		1: return Vector2(size.x - r, r) + Vector2(sin(d / r), -cos(d / r)) * r
		2: return Vector2(size.x, r + d)
		3: return Vector2(size.x - r, size.y - r) + Vector2(cos(d / r), sin(d / r)) * r
		4: return Vector2(size.x - r - d, size.y)
		5: return Vector2(r, size.y - r) + Vector2(-sin(d / r), cos(d / r)) * r
		6: return Vector2(0, size.y - r - d)
		_: return Vector2(r, r) + Vector2(-cos(d / r), -sin(d / r)) * r

func _draw() -> void:
	if up <= 0:
		return
	var S = _style()
	var base: Color = S.col
	draw_set_transform(Vector2(2, 2), 0, Vector2((size.x - 4) / size.x, (size.y - 4) / size.y))
	# viền phát sáng (nhịp thở)
	if S.aura > 0:
		var a: float = S.aura * (0.6 + 0.4 * sin(t * 3.0))
		var c = base
		if S.rainbow:
			c = Color.from_hsv(fposmod(t * 0.15, 1.0), 0.6, 1.0)
		for k in 3:
			var g = 2.0 + k * 2.5
			var cc = c
			cc.a = a / (k + 1.5)
			draw_rect(Rect2(Vector2(-g, -g) * 0.5, size + Vector2(g, g)), cc, false, g)
	# các vệt sáng chạy vòng, đuôi mờ dần
	var n: int = S.n
	var steps = 26
	for j in n:
		var head: float = t * S.spd + float(j) / n
		var pts = PackedVector2Array()
		var cols = PackedColorArray()
		var core = PackedColorArray()
		for k in range(0, steps + 1):
			var u: float = head - S.len * k / steps
			pts.append(_perim(u))
			var f = 1.0 - float(k) / steps
			var c2 = base
			if S.rainbow:
				c2 = Color.from_hsv(fposmod(t * 0.25 + float(j) / n + u * 0.5, 1.0), 0.85, 1.0)
			c2.a = f * 0.55
			cols.append(c2)
			var c3 = c2.lerp(Color.WHITE, 0.55)
			c3.a = f
			core.append(c3)
		# lớp mờ rộng (quầng) rồi lõi sáng mảnh
		draw_polyline_colors(pts, cols, S.w * 2.2, true)
		draw_polyline_colors(pts, core, S.w * 0.8, true)
		var hp = _perim(head)
		var hc = Color(1, 1, 1, 0.95)
		var hg = base if not S.rainbow else Color.from_hsv(fposmod(t * 0.25 + float(j) / n, 1.0), 0.6, 1.0)
		hg.a = 0.5
		draw_circle(hp, S.w * 1.8, hg)
		draw_circle(hp, S.w * 0.8, hc)
	# đốm lấp lánh
	for k in int(S.spark):
		var ph = fposmod(t * 0.7 + k * 0.37, 1.0)
		var pp = _perim(k * 0.173 + floor(t * 0.7 + k * 0.37) * 0.31)
		var sz = sin(ph * PI) * 4.0
		var sc = Color(1, 0.8, 0.2, sin(ph * PI))
		draw_line(pp - Vector2(sz, 0), pp + Vector2(sz, 0), sc, 2.5)
		draw_line(pp - Vector2(0, sz), pp + Vector2(0, sz), sc, 2.5)
