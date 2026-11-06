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
	for k in [["bag", "Túi đồ"], ["char", "Nhân vật"], ["stat", "Chỉ số"]]:
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
	elif tab == "stat":
		_render_stat(d)
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
		var b = UI.button("Mua (%d vàng)" % Data.pot_price(), UI.GOLD, 18)
		b.disabled = int(d.gold) < Data.pot_price() or int(d.pots) >= 20
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
	for k in [["Máu", "maxHp"], ["KI", "maxKi"], ["Sức đánh", "atk"], ["Giáp", "def"], ["Tốc chạy", "spd"]]:
		detail.add_child(UI.label("%s: %s" % [k[0], UI.fmt(d.get(k[1], 0))], 18, UI.INK, "semi"))
	detail.add_child(UI.label("Chí mạng %s · Né %s" % [_pct(d.get("crit", 0)), _pct(d.get("dodge", 0))], 18, UI.INK, "semi"))
	detail.add_child(UI.label("Hút máu %s · Xuyên giáp %s" % [_pct(d.get("ls", 0)), _pct(d.get("pen", 0))], 18, UI.INK, "semi"))
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

# ---------- điểm tiềm năng (giống Ngọc Rồng Online: lên cấp được điểm, tự cộng vào chỉ số) ----------
const PTS := [
	["hp", "Máu", "maxHp", "+5 máu tối đa mỗi điểm", 0],
	["ki", "KI", "maxKi", "+5 KI tối đa. Kỹ năng tốn KI, KI tự hồi", 0],
	["atk", "Sức đánh", "atk", "+0,7 sức đánh mỗi điểm", 0],
	["def", "Giáp", "def", "+0,3 giáp, giảm sát thương nhận vào", 0],
	["crit", "Chí mạng", "crit", "+0,2% tỉ lệ chí mạng (x1,6 sát thương)", 150],
	["spd", "Tốc chạy", "spd", "+1 tốc độ chạy", 60],
	["dodge", "Né tránh", "dodge", "+0,2% né hoàn toàn đòn của quái", 125],
	["ls", "Hút máu", "ls", "+0,1% sát thương gây ra thành máu", 150],
	["pen", "Xuyên giáp", "pen", "+0,5% bỏ qua giáp của quái", 100],
]
const PT_COL := {"hp": "e8546f", "ki": "4a8dff", "atk": "ff8a3d", "def": "7a8aa8", "crit": "ffb300", "spd": "3ccf91", "dodge": "8b6cff", "ls": "d9345a", "pen": "2fa8a0"}
var arm_reset = false

func _pct(v) -> String:
	var x = float(v) * 100.0
	return ("%d%%" % int(round(x))) if absf(x - round(x)) < 0.05 else ("%.1f%%" % x)

func _render_stat(d: Dictionary) -> void:
	var col = UI.vbox(10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(col)
	var free = int(d.get("ptFree", 0))
	var pt: Dictionary = d.get("pt", {})
	var top = UI.hbox(12)
	col.add_child(top)
	var badge = PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UI.box(Color("fff3b0") if free > 0 else Color.WHITE, UI.INK, 14, 3, true))
	var bl = UI.label("Điểm tiềm năng: %d" % free, 22, UI.INK, "bold")
	badge.add_child(bl)
	top.add_child(badge)
	top.add_child(UI.label("Mỗi lần lên cấp nhận 5 điểm.", 16, Color("5a6b8c"), "semi"))
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var cost = int(d.get("ptCost", 0))
	var used = 0
	for k in pt:
		used += int(pt[k])
	var rb = UI.button(("Bấm lần nữa để tẩy" if arm_reset else "Tẩy điểm") + (" (miễn phí)" if cost == 0 else " (%s vàng)" % UI.fmt(cost)), UI.RED if arm_reset else UI.SKY, 17)
	rb.disabled = used == 0 or int(d.get("gold", 0)) < cost
	rb.pressed.connect(func():
		if arm_reset:
			arm_reset = false
			Net.send({"t": "stat_reset"})
		else:
			arm_reset = true
			render())
	top.add_child(rb)
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 8)
	col.add_child(g)
	for row in PTS:
		var k: String = row[0]
		var n = int(pt.get(k, 0))
		var mx = int(row[4])
		var p = PanelContainer.new()
		p.custom_minimum_size = Vector2(462, 0)
		p.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
		g.add_child(p)
		var h = UI.hbox(8)
		p.add_child(h)
		var dot = ColorRect.new()
		dot.color = Color(PT_COL[k])
		dot.custom_minimum_size = Vector2(8, 44)
		h.add_child(dot)
		var tv = UI.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)
		var v = d.get(row[2], 0)
		var vs = _pct(v) if k in ["crit", "dodge", "ls", "pen"] else UI.fmt(v)
		tv.add_child(UI.label("%s  %s" % [row[1], vs], 18, UI.INK, "bold"))
		tv.add_child(UI.label(("Đã cộng %d" % n) + ((" / %d" % mx) if mx > 0 else "") + " · " + str(row[3]), 13, Color("5a6b8c"), "semi"))
		for step in [1, 5, 10]:
			var b = UI.button("+%d" % step, UI.GREEN if step == 1 else UI.GOLD, 15)
			b.custom_minimum_size = Vector2(46, 40)
			b.disabled = free < step or (mx > 0 and n + step > mx)
			var kk = k
			var nn = step
			b.pressed.connect(func(): arm_reset = false; Net.send({"t": "stat", "k": kk, "n": nn}))
			h.add_child(b)
