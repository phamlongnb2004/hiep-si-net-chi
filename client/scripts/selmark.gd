extends Node2D
class_name SelMark
## Tam giác ngược nhấp nhô chỉ vào đối tượng đang chọn (quái, người chơi, NPC, đồ rơi).

var g = null
var t = 0.0

func _process(dt: float) -> void:
	t += dt
	var top = _top()
	visible = top != null
	if top != null:
		position = top
		queue_redraw()

func _top():
	if g == null or g.sel == null:
		return null
	var s = g.sel
	match g.sel_kind:
		"npc":
			if s is Dictionary:
				return Vector2(float(s.x), float(s.y) - 190)
		"mon":
			if is_instance_valid(s) and not s.dead():
				return s.position + Vector2(0, -s.hh() - s.lift() - 34)
		"hero":
			if is_instance_valid(s):
				return s.position + Vector2(0, -130)
		"drop":
			if is_instance_valid(s):
				return s.position + Vector2(0, -58)
	g.sel = null
	g.sel_kind = ""
	g.sel_changed.emit()
	return null

func _draw() -> void:
	var y = sin(t * 6.0) * 5.0
	var col = Color("ff5a5a") if g.sel_kind == "mon" else (Color("ffd23f") if g.sel_kind == "drop" else Color("7ee0ff"))
	var p = PackedVector2Array([Vector2(-13, -20 + y), Vector2(13, -20 + y), Vector2(0, 0 + y)])
	draw_colored_polygon(p, col)
	var o = p.duplicate()
	o.append(p[0])
	draw_polyline(o, UI.INK, 3)
