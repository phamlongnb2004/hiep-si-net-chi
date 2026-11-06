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
var _info: Dictionary = {}

func setup(info: Dictionary) -> void:
	id = int(info.id)
	type = str(info.type)
	lv = int(info.lv)
	hp_max = float(info.hpMax)
	hp = float(info.get("hp", hp_max))
	position = Vector2(info.x, info.y)
	target = position
	flags = 1 if int(info.get("dead", 0)) else 0
	_info = Data.D.mons.get(type, {})
	_k = str(_info.get("kind", "boar"))
	walk = randf() * 6.0

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
	visible = not dead()
	queue_redraw()

func _br_frame(bt: float) -> int:
	if bt < BR_C * 0.7: return 0
	if bt < BR_C: return 1
	if bt > BR_E + 0.1: return 5
	return [2, 3, 4, 3][int((bt - BR_C) * 6) % 4]

func _draw() -> void:
	var F: Array = Data.A.get("mon", {}).get(type, [])
	if F.is_empty():
		return
	var fly = _k == "dragon"
	var H: float = MH.get(_k, 80)
	var r: float = _info.get("r", 30)
	hover = (-70.0 - sin(t * 2.2 + id) * 12.0) if fly else 0.0
	var al = 0.55 if flash > 0 and int(t * 30) % 2 == 0 else 1.0
	var base = Transform2D().scaled(Vector2(MS, MS))
	draw_set_transform_matrix(base)
	var sw: float = 44.0 if _k == "boar" else (58.0 if _k == "wolf" else (62.0 if _k == "bear" else 130.0))
	_ellipse(Vector2(0, r * 0.12 - r * 0.5 + r * 0.5), sw * 1.3 * (0.8 if fly else 1.0), r * 0.42, Color(0.1, 0.1, 0.2, 0.25 * (0.5 if fly else 1.0)))
	var xf = base * Transform2D().translated(Vector2(0, hover)) * Transform2D().scaled(Vector2(face, 1))
	if lunge > 0:
		xf = xf * Transform2D().translated(Vector2(sin(lunge / 0.25 * PI) * 10, 0))
	var mv = flags & 64 != 0
	var fi = int(floor(t * 7 + id if fly else walk * 5.5)) % 4
	var q: Dictionary = F[1 + fi] if fly else (F[5] if lunge > 0 and F.size() > 5 else (F[1 + fi] if mv else F[0]))
	var BF: Array = Data.A.get("mon", {}).get(type + "_br", [])
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
		draw_texture_rect(tx, Rect2(-float(q.cx) * H, y0, fw, fh), false, Color(1, 1, 1, al))
	if fly:
		var lx: float = -float(q.cx) * H + float(q.get("mx", 0.92) if q.get("mx") != null else 0.92) * fw
		var ly: float = y0 + float(q.get("my", 0.38) if q.get("my") != null else 0.38) * fh
		mouth = global_position + Vector2(MS * face * lx, MS * (hover + ly))
	# trạng thái, máu, tên
	draw_set_transform(Vector2.ZERO)
	var th: float = round(H * 0.94)
	var top: float = hover * MS + th * (1 - MS) - th
	if flags & 2:
		var f: Font = Data.fonts.get("bold")
		draw_string_outline(f, Vector2(-18 + sin(t * 9) * 8, top - 20), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, UI.INK)
		draw_string(f, Vector2(-18 + sin(t * 9) * 8, top - 20), "★ ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd23f"))
	if flags & 12:
		draw_arc(Vector2(0, 2), sw * MS + 4, 0, TAU, 24, Color("6fcf3f") if flags & 8 else Color("6fb8ff"), 3)
	var boss: bool = _info.get("boss", false)
	var ly2 = top - 8
	if hp < hp_max or boss or focused:
		var bw = 96.0 if boss else 48.0
		draw_rect(Rect2(-bw / 2 - 1.5, ly2 - 1.5, bw + 3, 8), Color("0f1422"))
		draw_rect(Rect2(-bw / 2, ly2, bw * clampf(hp / hp_max, 0, 1), 5), Color("d9345a"))
	var f2: Font = Data.fonts.get("bold")
	var lab = "Lv.%d %s" % [lv, _info.get("n", type)]
	var w = f2.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string_outline(f2, Vector2(-w / 2, ly2 - 5), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(1, 1, 1, 0.85))
	draw_string(f2, Vector2(-w / 2, ly2 - 5), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c0143f") if focused else UI.INK)
	if focused:
		draw_arc(Vector2(0, 3), sw * MS * 0.9, 0, TAU, 28, Color(1, 0.82, 0.25, 0.9), 2.5)

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 20:
		var a = TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
