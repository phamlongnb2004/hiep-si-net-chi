extends Node2D
class_name Drop
## Đồ rơi trên đất (máy chủ tự nhặt khi người chơi đi qua).

var id = 0
var k = "item"
var n = 0
var item: Dictionary = {}
var t = 0.0

func setup(d: Dictionary) -> void:
	id = int(d.id)
	k = str(d.k)
	n = int(d.get("n", 0))
	item = d.item if d.get("item") is Dictionary else {}
	position = Vector2(d.x, d.y)
	t = randf() * 6

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _draw() -> void:
	var bob = sin(t * 4) * 2.2
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 10, Color(0.1, 0.13, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	var tx: Texture2D = null
	var S = 30.0
	if k == "item":
		tx = Data.item_icon(item)
		var r = int(item.get("r", 0))
		if r >= 1:
			var c = Data.rar_color(r)
			c.a = 0.35
			draw_circle(Vector2(0, -14 + bob), 20, c)
		if r >= 2:
			S = 34
	elif k == "pot":
		tx = Data.tex(Data.A.ai.get("pot", {}).get("u", ""))
		S = 26
	else:
		tx = Data.tex(Data.A.ai.get("stone", {}).get("u", ""))
		S = 24
	if tx:
		var w = S * tx.get_width() / max(tx.get_width(), tx.get_height())
		var h = S * tx.get_height() / max(tx.get_width(), tx.get_height())
		draw_texture_rect(tx, Rect2(-w / 2, -h - 2 + bob, w, h), false)
