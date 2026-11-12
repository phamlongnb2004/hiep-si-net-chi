extends Control
class_name Bag
## Túi đồ (giống tools/bag.js): lưới 8x4, so sánh với đồ đang mặc, mặc/bán/sắp xếp; thẻ Nhân vật: 4 ô trang bị, chỉ số.
## Mọi thao tác gửi lên máy chủ; túi chỉ vẽ lại khi máy chủ gửi dữ liệu mới.

var game: Game
var tab = "bag"
var sel = {}            # {"from":"inv"|"eq"|"pot", "id", "slot"}
var arm_toss = ""
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
	dim.gui_input.connect(func(ev): if UI.tapped(ev): close())
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
	for k in [["bag", "Túi đồ"], ["char", "Nhân vật"], ["stat", "Chỉ số"], ["skill", "Kỹ năng"], ["pet", "Thú cưng"]]:
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
	# chỉ vẽ lại khi túi đồ/trang bị đổi (không vẽ lại mỗi lần mất máu → hết nhảy chớp)
	g.bag_changed.connect(func(): if visible: render())
	g.me_changed.connect(func(): if visible and gold_l: gold_l.text = "Vàng %s · Đá %d" % [UI.fmt(game.me_data.get("gold", 0)), int(game.me_data.get("stones", 0))])
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
	var own = Data.can_wear(it, game.cls()) or str(it.get("slot", "")) in ["egg", "book"]
	var better = own and not equipped and str(it.get("slot", "")) != "egg" and Data.score(it) > Data.score(game.me_data.eq.get(it.slot))
	return ItemCell.make(it, selected, own, better)

func _click(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if UI.tapped(ev):
			f.call())

func render() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	var d = game.me_data
	if d.is_empty():
		return
	gold_l.text = "Vàng %s · Đá %d" % [UI.fmt(d.get("gold", 0)), int(d.get("stones", 0))]
	if tab == "bag":
		_render_bag(d)
	elif tab == "stat":
		_render_stat(d)
	elif tab == "skill":
		_render_skill(d)
	elif tab == "pet":
		_render_pet(d)
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
	var pn = UI.outlined("x%d" % (Data.pot_total(d, false) + Data.pot_total(d, true)), 14, Color.WHITE, "bold", 4)
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
			var c = _item_cell(it, Data.same_id(sel.get("id"), it.id))
			var iid = it.id
			_click(c, func(): sel = {"from": "inv", "id": iid}; arm_sell = ""; arm_toss = ""; render())
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
	detail.custom_minimum_size = Vector2(320, 0)
	detail.size_flags_horizontal = 0
	body.add_child(detail)
	_render_detail(d)
	_fix_width(detail, 320)

func _find(d: Dictionary, id) -> Dictionary:
	for it in d.get("inv", []):
		if Data.same_id(it.id, id):
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
		detail.add_child(UI.label("Bình máu & bình KI", 22, UI.INK, "bold"))
		detail.add_child(UI.label("Nhỏ hồi 150 máu/60 KI · Vừa 600/200 · Lớn 1500/450. Mua thêm ở Thương Nhân Bảo trong Làng.", 14, Color("5a6b8c"), "body"))
		for ki in [false, true]:
			for t in 3:
				var key: String = (Data.KI_KEYS if ki else Data.HP_KEYS)[t]
				var r = UI.hbox(8)
				detail.add_child(r)
				var ic = TextureRect.new()
				ic.texture = Data.pot_icon(ki, t)
				ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ic.custom_minimum_size = Vector2(36, 36)
				r.add_child(ic)
				var nl = UI.label("%s %s x%d" % ["KI" if ki else "Máu", str(Data.POT_T[t].n).to_lower(), int(d.get(key, 0))], 16, UI.INK, "semi")
				nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				r.add_child(nl)
				var u = UI.button("Dùng", UI.GREEN, 15)
				u.disabled = int(d.get(key, 0)) <= 0
				var tt: int = t
				var op = "kpot" if ki else "pot"
				u.pressed.connect(func(): Net.send({"t": op, "k": tt}))
				r.add_child(u)
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
	if str(it.slot) == "egg":
		detail.add_child(UI.label(Data.item_name(it), 22, Data.rar_color(r2), "bold"))
		detail.add_child(UI.label("Trứng Thần Thú · rơi khi kết liễu Ma Long Hắc Vực", 16, Color("5a6b8c"), "semi"))
		detail.add_child(UI.label("Mang tới Bà Ấp Trứng trong Làng để ấp. Trứng nở sau 24 giờ thành pet theo bạn chiến đấu.", 16, UI.INK, "body"))
		detail.add_child(UI.label("Giao dịch được · Không bán cho cửa hàng", 15, Color("2fa84f"), "semi"))
		var bp = UI.button("Xem chuồng pet", UI.SKY, 18)
		bp.pressed.connect(func(): game.open_npc.emit("pets"))
		detail.add_child(bp)
		return
	if str(it.slot) == "book":
		_render_book(d, it)
		return
	var nm = UI.label(Data.item_name(it), 22, Data.rar_color(r2) if r2 > 0 else UI.INK, "bold")
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(nm)
	var own = Data.can_wear(it, game.cls())
	detail.add_child(UI.label("%s · %s · Cấp %d" % [Data.D.rar[r2].n, Data.SLOT_N[it.slot], int(it.lvl)], 16, Color("5a6b8c"), "semi"))
	var lv_ok = int(d.get("lv", 1)) >= Data.req_lv(it)
	detail.add_child(UI.label("Cần cấp %d để mặc" % Data.req_lv(it) + ("" if lv_ok else " (bạn chưa đủ cấp)"), 16, UI.INK if lv_ok else Color("d9345a"), "semi"))
	if Data.is_myth(it):
		detail.add_child(UI.label("✦ Thần Thoại · phái nào cũng mặc được · rơi từ Hỗn Mang Ma Thần", 16, Color("ff2e63"), "semi"))
		detail.add_child(UI.label("Mặc 1 món: hào quang nhẹ · mặc từ 3 món: hào quang thần thánh đầy đủ", 14, Color("5a6b8c"), "semi"))
	elif str(it.slot) in Data.FREE:
		detail.add_child(UI.label("Mọi phái đều dùng được" + (" · chỉ rơi từ trùm" if str(it.slot) == "wing" else ""), 16, Color("2fa84f"), "semi"))
	else:
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
	var be = UI.button(("Mặc" if lv_ok else "Chưa đủ cấp") if own else "Khác phái", UI.GREEN, 18)
	be.disabled = not own or not lv_ok
	var iid = it.id
	be.pressed.connect(func(): Net.send({"t": "equip", "id": iid}); sel = {})
	row.add_child(be)
	# vứt bỏ hẳn (bấm 2 lần để chắc chắn)
	var bt = UI.button("Chắc chắn vứt?" if arm_toss == str(iid) else "Vứt", Color("e0565b"), 18)
	bt.pressed.connect(func():
		if arm_toss != str(iid):
			arm_toss = str(iid)
			render()
			return
		Net.send({"t": "toss", "id": iid}); sel = {}; arm_toss = "")
	row.add_child(bt)
	# bán: chỉ khi đứng cạnh Thương Nhân Giáp
	var price = Data.sell_price(it)
	if game.near_shop("gear"):
		var bs = UI.button(("Chắc chắn bán?" if arm_sell == str(iid) else "Bán %s vàng" % UI.fmt(price)), UI.GOLD, 18)
		bs.pressed.connect(func():
			if r2 >= 2 and arm_sell != str(iid):
				arm_sell = str(iid)
				render()
				return
			Net.send({"t": "sell", "id": iid}); sel = {}; arm_sell = "")
		detail.add_child(bs)
	else:
		detail.add_child(UI.label("Bán ở Thương Nhân Giáp trong Làng: %s vàng." % UI.fmt(price), 13, Color("5a6b8c"), "semi"))

## sách kĩ năng Thiên Địa Diệt: học ngay trong túi (cần cấp 100, mỗi nhân vật học 1 lần)
func _render_book(d: Dictionary, it: Dictionary) -> void:
	var nm = UI.label(Data.item_name(it), 22, Data.rar_color(4), "bold")
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(nm)
	detail.add_child(UI.label("Thần Thoại · Sách kĩ năng · rơi từ Hỗn Mang Ma Thần", 16, Color("5a6b8c"), "semi"))
	var ds = UI.label("Thiên Địa Diệt: gọi cột thánh quang giáng xuống mục tiêu, 700% sát thương vùng rộng và làm choáng 1,5 giây. Hồi chiêu 45 giây. Ô kỹ năng thứ 7 (phím 7).", 16, UI.INK, "body")
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(ds)
	detail.add_child(UI.label("Phái nào cũng học được · Giao dịch được", 15, Color("2fa84f"), "semi"))
	var lv_ok = int(d.get("lv", 1)) >= 100
	var learned = int(d.get("usk", game.me_data.get("usk", 0))) == 1
	detail.add_child(UI.label("Đã học kĩ năng này" if learned else ("Cần cấp 100 để học" + ("" if lv_ok else " (bạn chưa đủ cấp)")), 16, Color("5a6b8c") if learned else (UI.INK if lv_ok else Color("d9345a")), "semi"))
	var row = UI.hbox(8)
	detail.add_child(row)
	var bl = UI.button("Đã học" if learned else ("Học" if lv_ok else "Chưa đủ cấp"), UI.GREEN, 18)
	bl.disabled = learned or not lv_ok
	var iid = it.id
	bl.pressed.connect(func(): Net.send({"t": "usebook", "id": iid}); sel = {})
	row.add_child(bl)
	var bt = UI.button("Chắc chắn vứt?" if arm_toss == str(iid) else "Vứt", Color("e0565b"), 18)
	bt.pressed.connect(func():
		if arm_toss != str(iid):
			arm_toss = str(iid)
			render()
			return
		Net.send({"t": "toss", "id": iid}); sel = {}; arm_toss = "")
	row.add_child(bt)

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
	h.myth = game.me.myth
	h.wing = int(d.eq.wing.r) if d.eq.get("wing") is Dictionary else -1
	h.show_name = false
	h.position = Vector2(110, 230)
	h.scale = Vector2(2.6, 2.6)
	vp.add_child(h)
	left.add_child(pv)
	var slots = GridContainer.new()
	slots.columns = 4
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

# ---------- thú cưng: pet đang theo, chỉ số, trạng thái (đi theo / tấn công / bảo vệ / về nhà) ----------
const PET_SPN := {"fire": "Rồng Lửa", "ice": "Cáo Băng", "wolf": "Sói Sấm", "turtle": "Rùa Ngọc"}
const PET_STAGE := ["Non", "Trưởng thành", "Thần thú"]
const PET_SKN := {"fire": ["Phóng Cầu Lửa", "Phun Lửa", "Hỏa Long Giáng Thế"], "ice": ["Băng Tiễn", "Gió Tuyết", "Bão Băng Chín Đuôi"],
	"wolf": ["Tia Chớp", "Lôi Độn", "Thiên Lôi Giáng"], "turtle": ["Khiên Ngọc", "Suối Hồi Phục", "Thành Đồng Vách Sắt"]}
const PET_MODE := [["follow", "Đi theo", "ditheo", "Đi cạnh bạn, không đánh quái."], ["attack", "Tấn công", "tancong", "Tự đánh mọi con quái quanh bạn."],
	["protect", "Bảo vệ", "baove", "Đánh quái bạn đang đánh và quái đang đánh bạn."], ["home", "Về nhà", "venha", "Cất pet về chuồng, pet biến mất."]]

func _render_pet(d: Dictionary) -> void:
	var pets: Array = d.get("pets", [])
	if pets.is_empty():
		var v0 = UI.vbox(10)
		v0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(v0)
		v0.add_child(UI.label("Bạn chưa có thú cưng.", 22, UI.INK, "bold"))
		v0.add_child(UI.label("Hạ Ma Long Hắc Vực để nhận trứng, rồi mang tới Bà Ấp Trứng trong Làng để ấp (24 giờ).", 17, Color("5a6b8c"), "semi"))
		return
	var on = str(d.get("petOn", ""))
	var mode = str(d.get("petMode", "protect")) if on != "" else "home"
	var p: Dictionary = pets[0]
	for q in pets:
		if str(q.id) == on:
			p = q
	var sp = str(p.sp)
	var stg = int(p.get("stage", 0))
	var rt: Dictionary = d.get("pet", {}) if d.get("pet") is Dictionary else {}
	# cột trái: pet động + tên, sao, cấp, kinh nghiệm
	var left = UI.vbox(6)
	left.custom_minimum_size = Vector2(250, 0)
	body.add_child(left)
	var pv = SubViewportContainer.new()
	pv.custom_minimum_size = Vector2(250, 190)
	pv.stretch = true
	var vp = SubViewport.new()
	vp.transparent_bg = true
	pv.add_child(vp)
	var pn = Pet.new()
	pn.mine = true
	pn.setup([0, sp, stg, 125, 175, 1, 3 if int(rt.get("faint", 0)) > 0 else 0, 1.0, "", 0, 0])
	pn.show_label = false
	pn.scale = Vector2(1.8, 1.8)
	pn.modulate = Color(1, 1, 1, 0.45) if on == "" else Color.WHITE
	vp.add_child(pn)
	left.add_child(pv)
	left.add_child(UI.label("%s  %s" % [str(p.name), "★".repeat(int(p.star)) + "☆".repeat(5 - int(p.star))], 22, UI.INK, "bold"))
	left.add_child(UI.label("%s · Lv.%d · %s" % [PET_SPN.get(sp, ""), int(p.lv), PET_STAGE[clampi(stg, 0, 2)]], 16, Color("5a6b8c"), "semi"))
	var need = maxi(1, int(p.get("need", 1)))
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, 16)
	bar.show_percentage = false
	bar.max_value = need
	bar.value = int(p.exp)
	left.add_child(bar)
	left.add_child(UI.label("Kinh nghiệm %s / %s" % [UI.fmt(int(p.exp)), UI.fmt(need)], 14, Color("5a6b8c"), "semi"))
	if on == "":
		left.add_child(UI.label("Đang ở nhà", 16, Color("d9345a"), "bold"))
	elif int(rt.get("faint", 0)) > 0:
		left.add_child(UI.label("Đang ngất · hồi sinh sau %d giây" % int(rt.faint), 15, Color("d9345a"), "semi"))
	elif not rt.is_empty():
		left.add_child(UI.label("Máu %d / %d" % [int(rt.hp), int(rt.maxHp)], 15, Color("2fa84f"), "semi"))
	if pets.size() > 1:
		var sw = UI.hbox(6)
		left.add_child(sw)
		for q in pets:
			if str(q.id) == str(p.id):
				continue
			var qid = str(q.id)
			var bq = UI.button("Đổi: %s Lv.%d" % [str(q.name), int(q.lv)], UI.SKY, 14)
			bq.pressed.connect(func(): Net.send({"t": "pet_on", "id": qid}))
			sw.add_child(bq)
	# cột phải: trạng thái, chỉ số, kỹ năng, trang bị
	var right = UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	right.add_child(UI.label("Trạng thái", 20, UI.INK, "bold"))
	var mr = UI.hbox(8)
	right.add_child(mr)
	var mdesc = ""
	for md in PET_MODE:
		var k: String = md[0]
		var cur = k == mode
		if cur:
			mdesc = md[3]
		var b = UI.button(("✔ " if cur else "") + md[1], UI.GOLD if cur else (UI.RED if k == "home" else UI.SKY), 17)
		b.custom_minimum_size = Vector2(124, 46)
		b.pressed.connect(func(): if not cur: Net.send({"t": "pet_mode", "mode": k}))
		mr.add_child(b)
	right.add_child(UI.label(mdesc + " Gõ chat ditheo, tancong, baove, venha để ra lệnh nhanh.", 14, Color("5a6b8c"), "semi"))
	right.add_child(UI.hsep())
	var S: Dictionary = p.get("st", {})
	var pt: Dictionary = p.get("pt", {})
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 26)
	g.add_theme_constant_override("v_separation", 4)
	right.add_child(g)
	var vals = [["Máu", str(int(S.get("maxHp", 0))), "hp"], ["Sức đánh", str(snapped(float(S.get("atk", 0)), 0.1)), "atk"], ["Giáp", str(snapped(float(S.get("def", 0)), 0.1)), "def"],
		["Tốc đánh", "x%s" % str(snapped(float(S.get("aspd", 1)), 0.01)), "aspd"], ["Chí mạng", "%d%%" % int(round(float(S.get("crit", 0)) * 100)), "crit"]]
	for k in vals:
		g.add_child(UI.label("%s: %s  (%d điểm)" % [k[0], k[1], int(pt.get(k[2], 0))], 16, UI.INK, "semi"))
	right.add_child(UI.label("Mỗi cấp +3 điểm tự cộng · sao nhân điểm x%s" % str([0.8, 0.9, 1.0, 1.15, 1.3][clampi(int(p.star) - 1, 0, 4)]), 13, Color("5a6b8c"), "semi"))
	right.add_child(UI.hsep())
	var sks: Array = PET_SKN.get(sp, ["", "", ""])
	for i in 3:
		var unlocked = int(p.lv) >= [10, 40, 80][i]
		right.add_child(UI.label(("✔ " if unlocked else "✖ ") + str(sks[i]) + ("" if unlocked else " (mở ở cấp %d)" % [10, 40, 80][i]), 15, UI.INK if unlocked else Color("8a93a8"), "semi"))
	right.add_child(UI.hsep())
	right.add_child(UI.label("Trang bị pet", 17, UI.INK, "bold"))
	var eqp: Dictionary = p.get("eq", {}) if p.get("eq") is Dictionary else {}
	var er = UI.hbox(8)
	right.add_child(er)
	var has_eq = false
	for k in eqp:
		if eqp[k] is Dictionary:
			has_eq = true
			er.add_child(ItemCell.make(eqp[k], false, true, false))
	if not has_eq:
		right.add_child(UI.label("Pet chưa có trang bị.", 14, Color("8a93a8"), "semi"))

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


## chữ dài tự xuống dòng trong khung cố định (khung không bị kéo rộng)
## ---------- thẻ Kỹ năng: 6 chiêu của phái, chiêu chưa học tối màu; nâng cấp bằng bùa (cấp L lên L+1 tốn L bùa) ----------
var sk_sel = 0
var sk_ask = false
const SKILL_MAX := 6

func _render_skill(d: Dictionary) -> void:
	var c = game.cls()
	var S: Array = Data.D.skills.get(c, [])
	var icons: Array = Data.A.get("hud", {}).get("skills", {}).get(c, [])
	var sk: Array = d.get("sk", [])
	var skl: Array = d.get("skl", [])
	var charms = int(d.get("charms", 0))
	var left = UI.vbox(10)
	body.add_child(left)
	var g = GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	left.add_child(g)
	for i in S.size():
		var learned = i < sk.size() and int(sk[i]) == 1
		var lv = int(skl[i]) if i < skl.size() else 1
		var p = _cell(112)
		if i == sk_sel:
			p.add_theme_stylebox_override("panel", UI.box(Color("fff3c4"), Color("ffb020"), 12, 3, false))
		var ic = TextureRect.new()
		ic.texture = Data.tex(icons[i]) if i < icons.size() else null
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(84, 84)
		ic.modulate = Color.WHITE if learned else Color(0.25, 0.27, 0.35, 0.85)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ic)
		var ll = UI.outlined(("Lv.%d" % lv) if learned else "Chưa học", 19, Color("ffd23f") if learned else Color("c9d3e6"), "bold", 5)
		ll.size_flags_vertical = Control.SIZE_SHRINK_END
		ll.size_flags_horizontal = Control.SIZE_SHRINK_END
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ll)
		var ii = i
		_click(p, func(): sk_sel = ii; sk_ask = false; render())
		g.add_child(p)
	var cr = UI.hbox(8)
	left.add_child(cr)
	var ci = TextureRect.new()
	ci.texture = Data.tex(Data.A.get("hud", {}).get("ui", {}).get("charm", ""))
	ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ci.custom_minimum_size = Vector2(40, 40)
	cr.add_child(ci)
	cr.add_child(UI.label("Bùa nâng cấp: %d" % charms, 18, UI.INK, "bold"))
	left.add_child(UI.label("Bùa rơi rất hiếm từ quái tinh anh và trùm.", 13, Color("5a6b8c"), "body"))
	detail = UI.vbox(8)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	if sk_sel >= S.size():
		return
	var s: Dictionary = S[sk_sel]
	var learned2 = sk_sel < sk.size() and int(sk[sk_sel]) == 1
	var L = int(skl[sk_sel]) if sk_sel < skl.size() else 1
	detail.add_child(UI.label(str(s.n), 26, UI.INK, "title"))
	detail.add_child(UI.label(("Cấp %d / %d" % [L, SKILL_MAX]) if learned2 else "Chưa học · mua sách ở Thương Nhân Bảo trong Làng", 17, Color("2f6fd0") if learned2 else Color("b0552f"), "bold"))
	var dl = UI.label(str(s.d), 16, UI.INK, "body")
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(dl)
	var kc: Array = d.get("kc", [])
	var info = "Cấp yêu cầu %d · Hồi chiêu %s giây" % [int(s.req), str(s.cd)]
	if sk_sel < kc.size():
		info += " · Tốn %d KI" % int(kc[sk_sel])
	detail.add_child(UI.label(info, 14, Color("5a6b8c"), "semi"))
	detail.add_child(UI.hsep())
	var pw = int(round(15.0 * (L - 1)))
	detail.add_child(UI.label("Sức mạnh hiện tại: +%d%% sát thương / hiệu quả" % pw, 16, UI.INK, "semi"))
	if L < SKILL_MAX:
		detail.add_child(UI.label("Cấp %d: +%d%% (tốn %d bùa, chắc chắn thành công)" % [L + 1, pw + 15, L], 16, Color("2fa84f"), "semi"))
	else:
		detail.add_child(UI.label("Đã đạt cấp tối đa.", 16, Color("2fa84f"), "semi"))
	if not learned2 or L >= SKILL_MAX:
		return
	if sk_ask:
		var box = PanelContainer.new()
		box.add_theme_stylebox_override("panel", UI.box(Color("fff3c4"), Color("ffb020"), 12, 2, false))
		var bv = UI.vbox(8)
		box.add_child(bv)
		var q = UI.label("Bạn đang có %d bùa, nâng cấp %s lên cấp %d tốn %d bùa. Nâng cấp?" % [charms, str(s.n), L + 1, L], 16, UI.INK, "semi")
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bv.add_child(q)
		var br = UI.hbox(10)
		bv.add_child(br)
		var ok = UI.button("Đồng ý", UI.GREEN, 18)
		ok.disabled = charms < L
		var ij = sk_sel
		ok.pressed.connect(func(): sk_ask = false; Net.send({"t": "skup", "i": ij}))
		br.add_child(ok)
		var no = UI.button("Hủy", UI.GREY, 18)
		no.pressed.connect(func(): sk_ask = false; render())
		br.add_child(no)
		detail.add_child(box)
	else:
		var up = UI.button("Nâng cấp (%d bùa)" % L, UI.GOLD, 20)
		up.custom_minimum_size = Vector2(0, 52)
		up.pressed.connect(func(): sk_ask = true; render())
		detail.add_child(up)
		if charms < L:
			detail.add_child(UI.label("Chưa đủ bùa (đang có %d)." % charms, 14, Color("b0552f"), "semi"))

func _fix_width(box: Control, w: float) -> void:
	for c in box.get_children():
		if c is Label:
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c.custom_minimum_size.x = w
		elif c is HBoxContainer:
			c.custom_minimum_size.x = 0
