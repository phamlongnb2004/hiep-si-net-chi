extends Control
class_name Npc
## Cửa sổ NPC: Thương Nhân (sách kỹ năng, bình máu, học kỹ năng) và Thợ Rèn (cường hoá trang bị).

var game: Game
var mode = "shop"
var tab = "books"
var fit = {}            # {"id", "slot"}
var msg = ""
var msg_ok = true
var body: VBoxContainer
var title: Label
var tabs: HBoxContainer

func setup(g: Game) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: close())
	add_child(dim)
	var card = UI.card(Vector2(860, 540))
	add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	var head = UI.hbox(12)
	v.add_child(head)
	title = UI.label("", 30, UI.INK, "title")
	head.add_child(title)
	tabs = UI.hbox(6)
	head.add_child(tabs)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(close)
	head.add_child(x)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(800, 440)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = UI.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	g.me_changed.connect(func(): if visible: render())
	Net.message.connect(func(m):
		if visible and m.get("t") == "res" and m.get("op") in ["forge", "book", "learn", "buypot"] and m.get("msg"):
			msg = str(m.msg); msg_ok = bool(m.get("ok", false)) and int(m.get("win", 1)) == 1; render())
	visible = false

func open(id: String) -> void:
	mode = "shop" if id == "shop" else "forge"
	tab = "books" if mode == "shop" else "forge"
	msg = ""
	fit = {}
	visible = true
	render()

func close() -> void:
	visible = false

func render() -> void:
	for c in tabs.get_children(): c.queue_free()
	for c in body.get_children(): c.queue_free()
	var d = game.me_data
	if d.is_empty():
		return
	title.text = "Thương Nhân Bảo" if mode == "shop" else "Thợ Rèn Cương"
	if mode == "shop":
		for k in [["books", "Sách kỹ năng"], ["pots", "Bình máu"]]:
			var b = UI.button(k[1], UI.GOLD if tab == k[0] else UI.SKY, 18)
			var kk: String = k[0]
			b.pressed.connect(func(): tab = kk; msg = ""; render())
			tabs.add_child(b)
	body.add_child(UI.label("Vàng: %s · Đá cường hóa: %d" % [UI.fmt(d.gold), int(d.stones)], 18, UI.INK, "bold"))
	if msg != "":
		body.add_child(UI.label(msg, 18, Color("2fa84f") if msg_ok else Color("d9345a"), "bold"))
	match tab:
		"books": _skills(d)
		"pots": _pots(d)
		"forge": _forge(d)

func _row(no: String, h: String, p: String, small: String, btn: Button) -> void:
	var r = PanelContainer.new()
	r.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
	var hb = UI.hbox(12)
	r.add_child(hb)
	var n = UI.label(no, 26, UI.INK, "title")
	n.custom_minimum_size = Vector2(36, 0)
	hb.add_child(n)
	var mid = UI.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(UI.label(h, 20, UI.INK, "bold"))
	var pl = UI.label(p, 15, UI.INK, "body")
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(pl)
	mid.add_child(UI.label(small, 13, Color("5a6b8c"), "semi"))
	hb.add_child(mid)
	btn.custom_minimum_size = Vector2(170, 50)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(btn)
	body.add_child(r)

func _skills(d: Dictionary) -> void:
	body.add_child(UI.label("Mua sách kỹ năng bằng vàng, rồi đạt đủ cấp để học. Kỹ năng đầu tiên học sẵn.", 15, Color("5a6b8c"), "body"))
	var S: Array = Data.D.skills[game.cls()]
	for i in S.size():
		var s: Dictionary = S[i]
		var learned = int(d.sk[i]) == 1
		var b: Button
		if learned:
			b = UI.button("Đã học", UI.GREY, 18)
			b.disabled = true
		elif int(d.books[i]) == 0:
			b = UI.button("Mua sách %sv" % UI.fmt(s.price), UI.GOLD, 18)
			b.disabled = int(d.gold) < int(s.price)
			var ii = i
			b.pressed.connect(func(): Net.send({"t": "book", "i": ii}))
		else:
			var okl = int(d.lv) >= int(s.req)
			b = UI.button("Học" if okl else "Cần cấp %d" % int(s.req), UI.GREEN, 18)
			b.disabled = not okl
			var ij = i
			b.pressed.connect(func(): Net.send({"t": "learn", "i": ij}))
		_row(str(i + 1), str(s.n), str(s.d), "Cấp yêu cầu %d · Hồi chiêu %s giây%s" % [int(s.req), str(s.cd), (" · Sách %s vàng" % UI.fmt(s.price)) if int(s.price) > 0 else ""], b)

func _pots(d: Dictionary) -> void:
	body.add_child(UI.label("Bình máu hồi 45% máu tối đa. Mang tối đa 20 bình.", 15, Color("5a6b8c"), "body"))
	for o in [[1, 30], [5, 150]]:
		var b = UI.button("Mua %dv" % o[1], UI.GOLD, 18)
		b.disabled = int(d.gold) < o[1] or int(d.pots) + o[0] > 20
		var n: int = o[0]
		b.pressed.connect(func(): Net.send({"t": "buypot", "n": n}))
		_row("♥", "Bình máu x%d" % o[0], "", "Giá %d vàng · Đang có %d / 20" % [o[1], int(d.pots)], b)

func _forge(d: Dictionary) -> void:
	body.add_child(UI.label("Chọn trang bị cần rèn. Rèn tối đa +15, càng cao càng khó; thất bại từ +6 có thể bị tụt cấp.", 15, Color("5a6b8c"), "body"))
	var list: Array = []
	for s in Data.SLOTS:
		if d.eq.get(s) is Dictionary:
			list.append({"it": d.eq[s], "slot": s})
	for it in d.inv:
		list.append({"it": it, "slot": ""})
	var g = GridContainer.new()
	g.columns = 9
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	body.add_child(g)
	var cur = null
	for o in list:
		var it: Dictionary = o.it
		var selected: bool = fit.get("id") == it.id
		if selected:
			cur = o
		var p = PanelContainer.new()
		p.custom_minimum_size = Vector2(76, 76)
		p.add_theme_stylebox_override("panel", UI.box(Color.WHITE, UI.BLUE if selected else Data.rar_color(int(it.r)), 12, 4 if selected else 2, false))
		var t = TextureRect.new()
		t.texture = Data.item_icon(it)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.add_child(t)
		if int(it.get("up", 0)) > 0:
			var u = UI.outlined("+%d" % int(it.up), 13, Color("ffd23f"), "bold", 4)
			u.size_flags_horizontal = Control.SIZE_SHRINK_END
			u.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			p.add_child(u)
		if o.slot != "":
			var e = UI.label("Mặc", 11, Color("2fa84f"), "bold")
			e.size_flags_vertical = Control.SIZE_SHRINK_END
			p.add_child(e)
		var oid = it.id
		var osl: String = o.slot
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				fit = {"id": oid, "slot": osl}; msg = ""; render())
		g.add_child(p)
	if list.is_empty():
		body.add_child(UI.label("Bạn chưa có trang bị. Hạ quái để nhặt đồ rồi quay lại.", 16, UI.INK, "body"))
	if cur:
		var it2: Dictionary = cur.it
		var f = Data.forge_info(it2)
		body.add_child(UI.label(Data.item_name(it2) + "  →  +%d" % int(f.L), 22, Data.rar_color(int(it2.r)), "bold"))
		if int(it2.get("up", 0)) >= int(Data.D.forge.max):
			body.add_child(UI.label("Đã rèn tối đa.", 18, UI.INK, "semi"))
			return
		body.add_child(UI.label("Tỉ lệ thành công %d%% · Cần %d đá, %s vàng%s" % [int(f.rate), int(f.stones), UI.fmt(f.gold), (" · Thất bại tụt %d cấp" % int(f.drop)) if int(f.drop) > 0 else ""], 18, UI.INK, "semi"))
		var b = UI.button("Rèn", UI.GOLD, 22)
		b.custom_minimum_size = Vector2(200, 56)
		b.disabled = int(d.gold) < int(f.gold) or int(d.stones) < int(f.stones)
		var cid = it2.id
		var cs: String = cur.slot
		b.pressed.connect(func():
			var m = {"t": "forge", "id": cid}
			if cs != "": m["slot"] = cs
			Net.send(m))
		body.add_child(b)
