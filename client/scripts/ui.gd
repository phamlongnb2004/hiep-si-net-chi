class_name UI
## Bộ khung giao diện theo phong cách game: thẻ kem, viền xanh đậm, nút vàng/xanh lá, chữ Baloo.

const INK := Color("16224a")
const CREAM := Color("fff8e6")
const SKY := Color("e8f4ff")
const GOLD := Color("ffc93c")
const GREEN := Color("5ccf6b")
const RED := Color("e8546f")
const BLUE := Color("4a8dff")
const GREY := Color("aab4c8")

static func box(bg: Color, border := INK, radius := 14, bw := 3, shadow := true) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if shadow:
		s.shadow_color = Color(0.03, 0.05, 0.15, 0.45)
		s.shadow_size = 0
		s.shadow_offset = Vector2(0, 4)
	return s

static func theme() -> Theme:
	var t = Theme.new()
	t.default_font = Data.fonts.get("semi")
	t.default_font_size = 20
	for k in ["normal", "hover", "pressed", "disabled", "focus"]:
		var c = GOLD
		if k == "hover": c = GOLD.lightened(0.15)
		elif k == "pressed": c = GOLD.darkened(0.12)
		elif k == "disabled": c = Color("d8dce6")
		var s = box(c, INK, 12, 3, k != "pressed")
		if k == "focus":
			s.bg_color = Color(0, 0, 0, 0)
			s.border_color = Color("ffffff")
		t.set_stylebox(k, "Button", s)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("7a8296"))
	t.set_font("font", "Button", Data.fonts.get("bold"))
	var le = box(Color.WHITE, INK, 10, 3, false)
	t.set_stylebox("normal", "LineEdit", le)
	var lf = le.duplicate()
	lf.border_color = BLUE
	t.set_stylebox("focus", "LineEdit", lf)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color("8a93a8"))
	t.set_font("font", "LineEdit", Data.fonts.get("body"))
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", box(CREAM, INK, 18, 4))
	t.set_stylebox("panel", "Panel", box(CREAM, INK, 18, 4))
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", Data.fonts.get("body"))
	t.set_font("bold_font", "RichTextLabel", Data.fonts.get("body8"))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.13, 0.29, 0.25)
	sb.set_corner_radius_all(6)
	t.set_stylebox("scroll", "VScrollBar", sb)
	var gr = StyleBoxFlat.new()
	gr.bg_color = Color(0.09, 0.13, 0.29, 0.6)
	gr.set_corner_radius_all(6)
	t.set_stylebox("grabber", "VScrollBar", gr)
	t.set_stylebox("grabber_highlight", "VScrollBar", gr)
	t.set_stylebox("grabber_pressed", "VScrollBar", gr)
	return t

static func label(text: String, size := 20, col := INK, font := "semi") -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if Data.fonts.has(font):
		l.add_theme_font_override("font", Data.fonts[font])
	return l

static func outlined(text: String, size := 20, col := Color.WHITE, font := "bold", outline := 6) -> Label:
	var l = label(text, size, col, font)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	return l

static func button(text: String, col := GOLD, size := 22) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if col != GOLD:
		for k in ["normal", "hover", "pressed"]:
			var c = col if k == "normal" else (col.lightened(0.15) if k == "hover" else col.darkened(0.12))
			b.add_theme_stylebox_override(k, box(c, INK, 12, 3, k != "pressed"))
	b.focus_mode = Control.FOCUS_NONE
	return b

static func icon_button(tex: Texture2D, sz := 72) -> TextureButton:
	var b = TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(sz, sz)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func edit(ph: String, secret := false) -> LineEdit:
	var e = LineEdit.new()
	e.placeholder_text = ph
	e.secret = secret
	e.custom_minimum_size = Vector2(0, 52)
	e.add_theme_font_size_override("font_size", 22)
	return e

static func card(min_size := Vector2(460, 0)) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = min_size
	var s = box(CREAM, INK, 22, 4)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 22
	s.content_margin_bottom = 24
	p.add_theme_stylebox_override("panel", s)
	return p

static func vbox(sep := 12) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 12) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func center(c: Control) -> CenterContainer:
	var cc = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.add_child(c)
	return cc

static func fmt(n) -> String:
	var s = str(int(n))
	var o = ""
	var k = 0
	for i in range(s.length() - 1, -1, -1):
		o = s[i] + o
		k += 1
		if k % 3 == 0 and i > 0 and s[i - 1] != "-":
			o = "." + o
	return o


## đường kẻ ngang / dọc phân vùng trong bảng
static func hsep() -> ColorRect:
	var s = ColorRect.new()
	s.color = Color("c9d3e6")
	s.custom_minimum_size = Vector2(0, 2)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

static func vsep() -> ColorRect:
	var s = ColorRect.new()
	s.color = Color("c9d3e6")
	s.custom_minimum_size = Vector2(2, 0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

## mọi chữ dài trong bảng tự xuống dòng để khung không bị kéo rộng
static func wrap_all(n: Node, minw := 160.0) -> void:
	for c in n.get_children():
		if c is Label and c.text.length() > 36:
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.custom_minimum_size.x = max(c.custom_minimum_size.x, minw)
		wrap_all(c, minw)
