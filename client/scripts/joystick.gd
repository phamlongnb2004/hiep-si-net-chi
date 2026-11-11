extends Control
class_name Joystick
## Cần điều khiển cảm ứng (nút tròn): kéo trái/phải để đi, kéo lên để nhảy thẳng, kéo chéo lên để nhảy chéo, kéo xuống để leo xuống.

signal jump
var value = Vector2.ZERO
var _idx = -1
var _c = Vector2.ZERO
var _k = Vector2.ZERO
var _jumped = false
const R := 70.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(240, 240)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _idx < 0:
			_idx = ev.index
			_c = ev.position
			_k = _c
			_jumped = false
		elif not ev.pressed and ev.index == _idx:
			_idx = -1
			value = Vector2.ZERO
		accept_event()
		queue_redraw()
	elif ev is InputEventScreenDrag and ev.index == _idx:
		var d: Vector2 = ev.position - _c
		if d.length() > R:
			d = d.normalized() * R
		_k = _c + d
		# 8 hướng: kéo chéo lên là nhảy chéo (đi hết tốc), kéo thẳng lên là nhảy thẳng
		value = Vector2.ZERO
		if d.length() > R * 0.3:
			var a = rad_to_deg(d.angle())   # 0 = phải, -90 = lên
			var sec = int(round(a / 45.0)) % 8
			value = [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)][(sec + 8) % 8]
		if value.y < 0 and not _jumped:
			_jumped = true
			jump.emit()
		elif value.y >= 0:
			_jumped = false
		accept_event()
		queue_redraw()

func _draw() -> void:
	var c = _c if _idx >= 0 else Vector2(size.x * 0.5, size.y * 0.55)
	var k = _k if _idx >= 0 else c
	draw_circle(c, R + 12, Color(0.09, 0.13, 0.29, 0.28))
	draw_arc(c, R + 12, 0, TAU, 40, Color(1, 1, 1, 0.5), 3)
	draw_circle(k, 34, Color(1, 1, 1, 0.82))
	draw_arc(k, 34, 0, TAU, 32, UI.INK, 3)
