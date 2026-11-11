extends Node2D
class_name Pet
## Pet đi theo người chơi (vị trí do máy chủ gửi trong ảnh chụp 'q'). Thân và chiêu vẽ tách riêng:
## thân dùng khung động tác (đứng, chạy, nhảy, đánh, xuất chiêu, ngất), hiệu ứng chiêu do fx.gd vẽ đè lên.

var owner_id = 0
var sp = "fire"
var stage = 0
var target = Vector2.ZERO
var face = 1
var act = 0          # 0 thường, 1 đánh, 2 xuất chiêu, 3 ngất
var hp = 1.0
var nm = ""
var lv = 1
var air = false
var mine = false
var t = 0.0
var anim = ""        # động tác chạy một lần (atk/cast) theo sự kiện
var anim_t = 0.0
var anim_dur = 0.0
var moving = false

func setup(q: Array) -> void:
	owner_id = int(q[0])
	position = Vector2(q[3], q[4])
	target = position
	apply(q)

func apply(q: Array) -> void:
	sp = str(q[1])
	stage = int(q[2])
	target = Vector2(q[3], q[4])
	face = int(q[5])
	act = int(q[6])
	hp = float(q[7])
	nm = str(q[8])
	lv = int(q[9])
	air = q.size() > 10 and int(q[10]) == 1

func play(a: String, dur: float) -> void:
	anim = a
	anim_t = 0.0
	anim_dur = dur

func art() -> Dictionary:
	var L: Array = Data.A.get("pet", {}).get(sp, [])
	if L.is_empty():
		return {}
	return L[clampi(stage, 0, L.size() - 1)]

func height() -> float:
	var a = art()
	return float(a.get("h", 50))

func _process(dt: float) -> void:
	t += dt
	var d = target - position
	if d.length() > 500:
		position = target
	else:
		position += d * min(1.0, dt * 10.0)
	moving = absf(d.x) > 1.0
	if anim != "":
		anim_t += dt
		if anim_t >= anim_dur:
			anim = ""
	queue_redraw()

func _frames(A: Dictionary, k: String) -> Array:
	# giai đoạn trưởng thành / thần thú chỉ có đứng, chạy, xuất chiêu: động tác thiếu thì mượn động tác gần nhất
	if A.has(k):
		return A[k]
	match k:
		"atk": return A.get("cast", A.idle)
		"jump": return A.get("run", A.idle)
		"faint": return A.idle
	return A.idle

func _draw() -> void:
	var a = art()
	if a.is_empty():
		return
	var A: Dictionary = a.a
	var W: float = float(a.w)
	var H: float = float(a.h)
	var fr: Array
	var k := 0
	var col := Color.WHITE
	if act == 3:
		fr = _frames(A, "faint")
		k = fr.size() - 1 if A.has("faint") else 0
		col = Color(0.6, 0.6, 0.7, 0.55 + sin(t * 3) * 0.1)
	elif anim != "":
		fr = _frames(A, anim)
		k = mini(fr.size() - 1, int(anim_t / anim_dur * fr.size()))
	elif air:
		fr = _frames(A, "jump")
		k = int(t * 10) % fr.size()
	elif moving:
		fr = _frames(A, "run")
		k = int(t * 12) % fr.size()
	else:
		fr = _frames(A, "idle")
		k = int(t * 7 + owner_id) % fr.size()
	_ellipse(Vector2(0, 2), W * 0.3, W * 0.06, Color(0.1, 0.1, 0.2, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2(face, 1))
	var tx = Data.tex(fr[k]) if mine else Data.tex_async(fr[k])
	if tx:
		if stage == 2 and act != 3:
			# thần thú: viền sáng nhẹ
			var gl = 0.25 + sin(t * 3.0) * 0.1
			for o in [Vector2(2, 0), Vector2(-2, 0), Vector2(0, -2)]:
				draw_texture_rect(tx, Rect2(Vector2(-float(a.cx) * W, -H) + o, Vector2(W, H)), false, Color(1, 0.9, 0.5, gl))
		draw_texture_rect(tx, Rect2(-float(a.cx) * W, -H, W, H), false, col)
	draw_set_transform(Vector2.ZERO)
	# tên + cấp, thanh máu nhỏ
	var f: Font = Data.fonts.get("bold")
	var lab = "%s Lv.%d" % [nm, lv]
	var sz = 12
	var w = f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var y = -H - 6
	if act == 3:
		lab += " (ngất)"
	draw_string_outline(f, Vector2(-w / 2, y), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, UI.INK)
	draw_string(f, Vector2(-w / 2, y), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("ffd23f") if mine else Color("dfe8ff"))
	if hp < 1.0 and act != 3:
		draw_rect(Rect2(-20, y + 3, 40, 4), Color("0f1422"))
		draw_rect(Rect2(-20, y + 3, 40 * clampf(hp, 0, 1), 4), Color("5fe08c"))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 16:
		var an = TAU * i / 16.0
		pts.append(c + Vector2(cos(an) * rx, sin(an) * ry))
	draw_colored_polygon(pts, col)
