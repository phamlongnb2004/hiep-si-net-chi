extends Control
class_name MythFrame
## Khung ô đồ Thần Thoại: khung vàng cánh thiên thần, ánh cầu vồng lấp lánh chạy quanh (8 khung ảnh lặp),
## vẽ tràn ra ngoài ô một chút cho cánh và đá quý nhô ra.

var t = 0.0
var over := false   # true: lớp ánh phủ lên trên ảnh đồ (mờ), false: khung nền sau ảnh đồ

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t = randf() * 10.0

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _draw() -> void:
	var M: Dictionary = Data.A.get("myth", {})
	var fx: Array = M.get("fx", [])
	var k = int(t * 9.0) % maxi(1, fx.size())
	var tx = Data.tex(fx[k]) if fx.size() > 0 else Data.tex(M.get("frame", ""))
	if tx == null:
		return
	var e = max(size.x, size.y) * 0.16
	var r = Rect2(Vector2(-e, -e * 1.1), size + Vector2(e * 2, e * 2.1))
	if over:
		var a = 0.25 + 0.2 * sin(t * 3.0)
		draw_texture_rect(tx, r, false, Color(1, 1, 1, a))
	else:
		draw_texture_rect(tx, r, false)
