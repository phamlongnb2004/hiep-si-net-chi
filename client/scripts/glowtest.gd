extends Node
## Chụp ô đồ cường hóa +0..+15 (chỉ khi mở với "-- glowtest=<thư mục>")
func _ready() -> void:
	var out = "user://"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("glowtest="):
			out = a.substr(9)
	var cl = CanvasLayer.new()
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color("fffaf0")
	bg.size = Vector2(1280, 720)
	cl.add_child(bg)
	var box = HBoxContainer.new()
	box.position = Vector2(60, 300)
	box.add_theme_constant_override("separation", 26)
	cl.add_child(box)
	for upv in [0, 3, 6, 9, 12, 15]:
		box.add_child(ItemCell.make({"slot": "weapon", "cls": "sword", "tier": 3, "r": 3, "lvl": 20, "up": upv, "lock": 1 if upv == 6 else 0, "st": {"atk": 50}}, false, true, false, 150))
	for i in 2:
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("glow%d.png" % i))
	get_tree().quit()
