extends Control
class_name DPad
## Phím di chuyển kiểu Ngọc Rồng Online (cảm ứng): ◀ ▶ đi, ▲ nhảy / leo lên, ▼ leo xuống, ↖ ↗ nhảy chéo.
## Giữ ngón tay và trượt sang phím khác được; nhiều ngón cùng lúc (mỗi ngón một phím).
## value giống cần điều khiển cũ: x = -1..1 (trái/phải), y = -1 (lên) .. 1 (xuống).

signal jump
var value = Vector2.ZERO
const B := 84.0           # cỡ một phím
const GAP := 8.0
# tên phím -> (cột, hàng) trên lưới 3x3
const KEYS := {"ul": Vector2(0, 0), "u": Vector2(1, 0), "ur": Vector2(2, 0), "l": Vector2(0, 1), "r": Vector2(2, 1), "d": Vector2(1, 2)}
const DIR := {"ul": Vector2(-1, -1), "u": Vector2(0, -1), "ur": Vector2(1, -1), "l": Vector2(-1, 0), "r": Vector2(1, 0), "d": Vector2(0, 1)}
var _held := {}           # chỉ số ngón -> tên phím

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(B * 3 + GAP * 2, B * 3 + GAP * 2)

func _rect(k: String) -> Rect2:
	var g: Vector2 = KEYS[k]
	return Rect2(g * (B + GAP), Vector2(B, B))

## phím dưới điểm chạm (nới rộng một chút để dễ bấm, ô giữa trống thì chọn phím gần nhất)
func _key_at(p: Vector2) -> String:
	var best = ""
	var bd = 1e9
	for k in KEYS:
		var r: Rect2 = _rect(k)
		var d = r.get_center().distance_to(p)
		if r.grow(GAP).has_point(p):
			return k
		if d < bd:
			bd = d
			best = k
	return best if bd < B * 1.6 else ""

func _press(idx: int, k: String) -> void:
	var old = str(_held.get(idx, ""))
	if k == old:
		return
	if k == "":
		_held.erase(idx)
	else:
		_held[idx] = k
		if k in ["u", "ul", "ur"]:
			jump.emit()
	_update()

func _update() -> void:
	var v = Vector2.ZERO
	for k in _held.values():
		v += DIR[k]
	value = Vector2(clampf(v.x, -1, 1), clampf(v.y, -1, 1))
	queue_redraw()

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		_press(ev.index, _key_at(ev.position) if ev.pressed else "")
		accept_event()
	elif ev is InputEventScreenDrag:
		if _held.has(ev.index):
			_press(ev.index, _key_at(ev.position))
		accept_event()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_press(-1, _key_at(ev.position) if ev.pressed else "")
		accept_event()
	elif ev is InputEventMouseMotion and _held.has(-1):
		_press(-1, _key_at(ev.position))
		accept_event()

## ngón tay rời khỏi màn hình ngoài vùng phím (hoặc mất tiêu điểm): nhả hết
func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _held.has(-1):
		_press(-1, "")
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		_held.clear()
		_update()

func _draw() -> void:
	var on := {}
	for k in _held.values():
		on[k] = true
	for k in KEYS:
		var r: Rect2 = _rect(k)
		var c = r.get_center()
		var hot = on.has(k)
		draw_circle(c, B * 0.5, Color(1, 0.85, 0.3, 0.55) if hot else Color(0.09, 0.13, 0.29, 0.45))
		draw_arc(c, B * 0.5 - 1.5, 0, TAU, 36, Color("ffd23f") if hot else Color(1, 1, 1, 0.75), 3)
		# mũi tên tam giác theo hướng phím
		var d: Vector2 = DIR[k].normalized()
		var n = Vector2(-d.y, d.x)
		# mũi tên có thân (nhìn rõ hướng chéo)
		var L = B * 0.3
		var hw = L * 0.62
		var sw = L * 0.22
		var pts = PackedVector2Array([c + d * L, c + n * hw, c + n * sw, c - d * L * 0.9 + n * sw, c - d * L * 0.9 - n * sw, c - n * sw, c - n * hw])
		draw_colored_polygon(pts, Color.WHITE)
		var outl = pts.duplicate()
		outl.append(pts[0])
		draw_polyline(outl, UI.INK, 3)
