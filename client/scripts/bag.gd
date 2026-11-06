extends Control
class_name Bag
## Túi đồ (giống tools/bag.js): lưới 8x4, so sánh với đồ đang mặc, mặc/bán/sắp xếp; thẻ Nhân vật: 4 ô trang bị, chỉ số.
## Mọi thao tác gửi lên máy chủ; túi chỉ vẽ lại khi máy chủ gửi dữ liệu mới.

var game: Game
var tab = "bag"
var sel = {}            # {"from":"inv"|"eq"|"pot", "id", "slot"}
var arm_sell = ""
var body: HBoxContainer
var grid: GridContainer
var detail: VBoxContainer
var tabs: HBoxContainer
var gold_l: Label

func setup(g: Game) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: close())
	add_child(dim)
	var card = UI.card(Vector2(980, 560))
	var cs: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
	cs.bg_color = Color("fffaf0")
	card.add_theme_stylebox_override("panel", cs)
	add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	var head = UI.hbox(12)
	v.add_child(head)
	head.add_child(UI.label("Hành Trang", 30, UI.INK, "title"))
	tabs = UI.hbox(6)
	head.add_child(tabs)
	for k in [["bag", "Túi đồ"], ["char", "Nhân vật"]]:
		var b = UI.button(k[1], UI.SKY, 18)
		var kk: String = k[0]
		b.pressed.connect(func(): tab = kk; sel = {}; render())
		tabs.add_child(b)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	gold_l = UI.label("", 20, UI.INK, "bold")
	head.add_child(gold_l)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(close)
	head.add_child(x)
	body = UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	g.me_changed.connect(func(): if visible: render())
	visible = false

func open() -> void:
	visible = true
	sel = {}
	render()

func close() -> void:
	visible = false

func _cell(sz := 74) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(sz, sz)
	var s = UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false)
	p.add_theme_stylebox_override("panel", s)
	return p

func _item_cell(it: Dictionary, selected: bool, equipped := false) -> PanelContainer:
	var own = str(it.get("cls", "")) == game.cls()
	var better = own and not equipped and Data.score(it) > Data.score(game.me_data.eq.get(it.slot))
	return ItemCell.make(it, selected, own, better)

func _click(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())

func render() -> void:
	for c in body.get_children():
		c.queue_free()
	var d = game.me_data
	if d.is_empty():
		return
	gold_l.text = "Vàng %s · Đá %d" % [UI.fmt(d.get("gold", 0)), int(d.get("stones", 0))]
	if tab == "bag":
		_render_bag(d)
	else:
		_render_char(d)

func _render_bag(d: Dictionary) -> void:
	var left = UI.vbox(10)
	body.add_child(left)
	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	left.add_child(grid)
	var inv: Array = d.get("inv", [])
	# bình máu, đá cường hoá
	var pc = _cell()
	var pt = TextureRect.new()
	pt.texture = Data.tex(Data.A.ai.get("pot", {}).get("u", ""))
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc.add_child(pt)
	var pn = UI.outlined("x%d" % int(d.get("pots", 0)), 14, Color.WHITE, "bold", 4)
	pn.size_flags_vertical = Control.SIZE_SHRINK_END
	pc.add_child(pn)
	_click(pc, func(): sel = {"from": "pot"}; render())
	grid.add_child(pc)
	var sc = _cell()
	var st = TextureRect.new()
	st.texture = Data.tex(Data.A.ai.get("stone", {}).get("u", ""))
	st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sc.add_child(st)
	var sn = UI.outlined("x%d" % int(d.get("stones", 0)), 14, Color.WHITE, "bold", 4)
	sn.size_flags_vertical = Control.SIZE_SHRINK_END
	sc.add_child(sn)
	_click(sc, func(): sel = {"from": "stone"}; render())
	grid.add_child(sc)
	for i in 30:
		if i < inv.size():
			var it: Dictionary = inv[i]
			var c = _item_cell(it, sel.get("id") == it.id)
			var iid = it.id
			_click(c, func(): sel = {"from": "inv", "id": iid}; arm_sell = ""; render())
			grid.add_child(c)
		else:
			grid.add_child(_cell())
	var row = UI.hbox(8)
	left.add_child(row)
	var so = UI.button("Sắp xếp", UI.SKY, 18)
	so.pressed.connect(func(): Net.send({"t": "sort"}))
	row.add_child(so)
	row.add_child(UI.label("%d / 30 ô" % inv.size(), 16, Color("5a6b8c"), "semi"))
	detail = UI.vbox(8)
	detail.custom_minimum_size = Vector2(300, 0)
	body.add_child(detail)
	_render_detail(d)

func _find(d: Dictionary, id) -> Dictionary:
	for it in d.get("inv", []):
		if it.id == id:
			return it
	return {}

func _stat_lines(it: Dictionary, cmp) -> void:
	for k in ["atk", "def", "hp", "spd"]:
		var v = Data.item_stat(it, k)
		if v == 0 and (cmp == null or Data.item_stat(cmp, k) == 0):
			continue
		var t = "%s: %d" % [Data.STAT_N[k], v]
		var col = UI.INK
		if cmp is Dictionary:
			var dv = v - Data.item_stat(cmp, k)
			if dv != 0:
				t += "  (%s%d)" % ["+" if dv > 0 else "", dv]
				col = Color("2fa84f") if dv > 0 else Color("d9345a")
		detail.add_child(UI.label(t, 18, col, "semi"))

func _render_detail(d: Dictionary) -> void:
	var f = str(sel.get("from", ""))
	if f == "":
		detail.add_child(UI.label("Chọn một món để xem.", 18, Color("5a6b8c"), "semi"))
		return
	if f == "pot":
		detail.add_child(UI.label("Bình máu", 24, UI.INK, "bold"))
		detail.add_child(UI.label("Hồi 45% máu tối đa. Mang tối đa 20 bình.", 16, UI.INK, "body"))
		var r = UI.hbox(8)
		detail.add_child(r)
		var u = UI.button("Dùng", UI.GREEN, 18)
		u.pressed.connect(game.do_pot)
		r.add_child(u)
		var b = UI.button("Mua (30 vàng)", UI.GOLD, 18)
		b.disabled = int(d.gold) < 30 or int(d.pots) >= 20
		b.pressed.connect(func(): Net.send({"t": "buypot", "n": 1}))
		r.add_child(b)
		return
	if f == "stone":
		detail.add_child(UI.label("Đá cường hóa", 24, UI.INK, "bold"))
		detail.add_child(UI.label("Dùng ở Thợ Rèn Cương trong Làng để rèn trang bị (tối đa +15).", 16, UI.INK, "body"))
		return
	var it = _find(d, sel.get("id"))
	if it.is_empty():
		sel = {}
		return
	var r2 = int(it.r)
	var nm = UI.label(Data.item_name(it), 22, Data.rar_color(r2) if r2 > 0 else UI.INK, "bold")
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(nm)
	var own = str(it.get("cls", "")) == game.cls()
	detail.add_child(UI.label("%s · %s · Cấp %d" % [Data.D.rar[r2].n, Data.SLOT_N[it.slot], int(it.lvl)], 16, Color("5a6b8c"), "semi"))
	detail.add_child(UI.label("Phái: " + str(Data.D.cls.get(it.get("cls", ""), {}).get("n", "?")) + ("" if own else " (bạn không mặc được)"), 16, UI.INK if own else Color("d9345a"), "semi"))
	if int(it.get("lock", 0)) == 1:
		detail.add_child(UI.label("Đồ khóa: không giao dịch được", 15, Color("b85c00"), "semi"))
	elif int(it.get("shop", 0)) == 1:
		detail.add_child(UI.label("Đồ cửa hàng (chỉ số mặc định)", 15, Color("5a6b8c"), "semi"))
	else:
		detail.add_child(UI.label("Không khóa: giao dịch được", 15, Color("2fa84f"), "semi"))
	_stat_lines(it, d.eq.get(it.slot))
	var row = UI.hbox(8)
	detail.add_child(row)
	var be = UI.button("Mặc" if own else "Khác phái", UI.GREEN, 18)
	be.disabled = not own
	var iid = it.id
	be.pressed.connect(func(): Net.send({"t": "equip", "id": iid}); sel = {})
	row.add_child(be)
	var price = Data.sell_price(it)
	var bs = UI.button(("Chắc chắn bán?" if arm_sell == str(iid) else "Bán %d vàng" % price), UI.GOLD, 18)
	bs.pressed.connect(func():
		if r2 >= 2 and arm_sell != str(iid):
			arm_sell = str(iid)
			render()
			return
		Net.send({"t": "sell", "id": iid}); sel = {}; arm_sell = "")
	row.add_child(bs)

func _render_char(d: Dictionary) -> void:
	var left = UI.vbox(10)
	body.add_child(left)
	var pv = SubViewportContainer.new()
	pv.custom_minimum_size = Vector2(220, 260)
	pv.stretch = true
	var vp = SubViewport.new()
	vp.transparent_bg = true
	pv.add_child(vp)
	var h = Hero.new()
	h.cls = game.cls()
	h.look = game.me.look
	h.show_name = false
	h.position = Vector2(110, 230)
	h.scale = Vector2(2.6, 2.6)
	vp.add_child(h)
	left.add_child(pv)
	var slots = GridContainer.new()
	slots.columns = 2
	slots.add_theme_constant_override("h_separation", 8)
	slots.add_theme_constant_override("v_separation", 8)
	body.add_child(slots)
	for s in Data.SLOTS:
		var it = d.eq.get(s)
		var box = UI.vbox(4)
		box.add_child(UI.label(Data.SLOT_N[s], 16, Color("5a6b8c"), "semi"))
		if it is Dictionary:
			var c = _item_cell(it, sel.get("slot") == s, true)
			_click(c, func(): sel = {"from": "eq", "slot": s}; render())
			box.add_child(c)
		else:
			box.add_child(_cell())
		slots.add_child(box)
	detail = UI.vbox(8)
	detail.custom_minimum_size = Vector2(300, 0)
	body.add_child(detail)
	var c: Dictionary = Data.D.cls[game.cls()]
	detail.add_child(UI.label("%s · Cấp %d" % [c.n, int(d.lv)], 22, UI.INK, "bold"))
	for k in [["Máu", "maxHp"], ["Công", "atk"], ["Thủ", "def"], ["Tốc", "spd"]]:
		detail.add_child(UI.label("%s: %s" % [k[0], UI.fmt(d.get(k[1], 0))], 18, UI.INK, "semi"))
	detail.add_child(UI.label("Chí mạng: %d%%" % int(round(float(d.get("crit", 0)) * 100)), 18, UI.INK, "semi"))
	detail.add_child(UI.label("Quái đã hạ: %s" % UI.fmt(d.get("kills", 0)), 18, UI.INK, "semi"))
	if sel.get("from") == "eq":
		var it2 = d.eq.get(sel.slot)
		if it2 is Dictionary:
			detail.add_child(UI.label(Data.item_name(it2), 20, Data.rar_color(int(it2.r)), "bold"))
			_stat_lines(it2, null)
			var bu = UI.button("Tháo", UI.SKY, 18)
			bu.disabled = d.inv.size() >= 30
			var sl: String = sel.slot
			bu.pressed.connect(func(): Net.send({"t": "unequip", "slot": sl}); sel = {})
			detail.add_child(bu)
