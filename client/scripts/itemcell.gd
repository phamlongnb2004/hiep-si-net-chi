class_name ItemCell
## Ô đồ dùng chung (túi, nhân vật, lò rèn, giao dịch, cửa hàng): ảnh, cấp, +cường hóa có ánh sáng chạy viền, khóa, ▲ đồ tốt hơn.

static func make(it: Dictionary, selected := false, own := true, better := false, sz := 74) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(sz, sz)
	var r = int(it.get("r", 0))
	var s = UI.box(Color.WHITE.lerp(Data.rar_color(r), 0.18 if r > 0 else 0.0), Data.rar_color(r) if r > 0 else Color("b8c4dc"), 12, 4 if selected else 2, false)
	if selected:
		s.border_color = UI.BLUE
	p.add_theme_stylebox_override("panel", s)
	var t = TextureRect.new()
	t.texture = Data.item_icon(it)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not own:
		t.modulate = Color(1, 1, 1, 0.55)
	p.add_child(t)
	var up = int(it.get("up", 0))
	if up > 0:
		var g = GlowFrame.new()
		g.up = up
		p.add_child(g)
	var lv = UI.label("Trứng" if str(it.get("slot", "")) == "egg" else "Lv.%d" % int(it.get("lvl", 1)), 12, UI.INK, "bold")
	lv.size_flags_vertical = Control.SIZE_SHRINK_END
	lv.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_child(lv)
	if up > 0:
		var u = UI.outlined("+%d" % up, 13, Color("ffd23f"), "bold", 4)
		u.size_flags_horizontal = Control.SIZE_SHRINK_END
		u.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		p.add_child(u)
	if int(it.get("lock", 0)) == 1:
		var lk = TextureRect.new()
		lk.texture = Data.tex(Data.A.get("hud", {}).get("ui", {}).get("lock", ""))
		lk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lk.custom_minimum_size = Vector2(18, 18)
		lk.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		lk.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		p.add_child(lk)
	if better:
		var b = UI.label("▲", 14, Color("2fa84f"), "bold")
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.size_flags_vertical = Control.SIZE_SHRINK_END
		p.add_child(b)
	return p

static func clickable(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())
