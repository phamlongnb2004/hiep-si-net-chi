extends Control
class_name Npc
## Cửa sổ NPC: Thương Nhân (sách kỹ năng, bình máu, học kỹ năng) và Thợ Rèn (cường hoá trang bị).

var game: Game
var mode = "shop"
var tab = "books"
var fit = {}            # {"id", "slot"}
var msg = ""
var msg_ok = true
var gear_cls = ""
var gear_lv = 0       # cấp đồ đang xem ở Thương Nhân Giáp (0 = theo cấp mình)
var gear_grp = 0      # 0: mũ áo choàng vũ khí; 1: giày, găng, dây chuyền; 2: nhẫn, khuyên, đai, bùa
var body: VBoxContainer
var title: Label
var tabs: HBoxContainer
var timer_lb: Label = null   # đếm ngược trứng đang ấp
var free_arm = ""            # pet đang chờ xác nhận thả (bước 2)
var free_at = 0.0
var free_btn: Button = null
var name_edit = ""           # pet đang mở ô đổi tên

func setup(g: Game) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if UI.tapped(ev): close())
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
	g.bag_changed.connect(func(): if visible and name_edit == "" and free_arm == "": render())
	Net.message.connect(func(m):
		if visible and m.get("t") == "res" and m.get("op") in ["forge", "book", "learn", "buypot", "shopbuy", "hatch_start", "hatch_cut", "hatch_open", "pet_on", "pet_name", "pet_free"] and m.get("msg"):
			msg = str(m.msg); msg_ok = bool(m.get("ok", false)) and int(m.get("win", 1)) == 1; render())
	visible = false

func open(id: String) -> void:
	_last_view = ""
	mode = id if id in ["shop", "gear"] else ("egg" if id in ["egg", "pets"] else "forge")
	tab = {"shop": "books", "gear": "gear", "egg": "pets" if id == "pets" else "hatch"}.get(mode, "forge")
	free_arm = ""
	name_edit = ""
	msg = ""
	fit = {}
	gear_lv = 0
	fpick = {}
	visible = true
	render()

func close() -> void:
	visible = false

var _last_view = ""
func render() -> void:
	# vẽ lại cùng một bảng (cập nhật túi/pet): giữ chỗ đang cuộn, đổi bảng thì về đầu
	var sc: ScrollContainer = body.get_parent()
	var view = mode + "/" + tab
	var keep = sc.scroll_vertical if view == _last_view else 0
	_last_view = view
	for c in tabs.get_children():
		tabs.remove_child(c)
		c.queue_free()
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	var d = game.me_data
	if d.is_empty():
		return
	timer_lb = null
	free_btn = null
	title.text = {"shop": "Thương Nhân Bảo", "gear": "Thương Nhân Giáp", "egg": "Bà Ấp Trứng"}.get(mode, "Thợ Rèn Cương")
	if mode == "egg":
		for k in [["hatch", "Ấp trứng"], ["pets", "Chuồng pet"]]:
			var be = UI.button(k[1], UI.GOLD if tab == k[0] else UI.SKY, 18)
			var ke: String = k[0]
			be.pressed.connect(func(): tab = ke; msg = ""; free_arm = ""; render())
			tabs.add_child(be)
	if mode == "gear":
		for c in Data.CLS_KEYS:
			var b2 = UI.button(str(Data.D.cls[c].n), UI.GOLD if gear_cls == c else UI.SKY, 16)
			var cc: String = c
			b2.pressed.connect(func(): gear_cls = cc; tab = "gear"; msg = ""; render())
			tabs.add_child(b2)
		for gi in 3:
			var b3 = UI.button(["Giáp & vũ khí", "Giày, găng, dây", "Trang sức"][gi], UI.GREEN if gear_grp == gi and tab == "gear" else UI.SKY, 16)
			var g2: int = gi
			b3.pressed.connect(func(): gear_grp = g2; tab = "gear"; msg = ""; render())
			tabs.add_child(b3)
		var bs = UI.button("Bán đồ", UI.GOLD if tab == "sell" else Color("e0565b"), 16)
		bs.pressed.connect(func(): tab = "sell"; sell_sel = {}; sell_arm = false; msg = ""; render())
		tabs.add_child(bs)
	if mode == "shop":
		for k in [["books", "Sách kỹ năng"], ["pots", "Bình máu & KI"]]:
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
		"gear": _gear(d)
		"sell": _sell(d)
		"hatch": _hatch(d)
		"pets": _pets(d)
	UI.wrap_all(body, 200)
	_pass_mouse(body)
	sc.scroll_vertical = keep
	if keep > 0:
		_restore_scroll.call_deferred(sc, keep)

func _restore_scroll(sc: ScrollContainer, v: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = v

## khung/ảnh không phải nút: cho thao tác cuộn (lăn chuột, kéo tay) đi qua tới ScrollContainer
func _pass_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is PanelContainer or c is TextureRect or c is BoxContainer or c is GridContainer:
			if (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP and not (c as Control).gui_input.get_connections().size():
				(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_mouse(c)

## bán nhiều món một lúc: chạm để đánh dấu, rồi bấm Bán (bấm 2 lần để chắc chắn)
var sell_sel := {}
var sell_arm := false
func _sell(d: Dictionary) -> void:
	var inv: Array = []
	for it in d.inv:
		if str(it.get("slot", "")) != "egg":
			inv.append(it)
	var total = 0
	var cnt = 0
	for it in inv:
		if sell_sel.has(str(it.id)):
			total += Data.sell_price(it)
			cnt += 1
	var top = UI.hbox(8)
	body.add_child(top)
	var all_b = UI.button("Chọn hết", UI.SKY, 15)
	all_b.pressed.connect(func():
		for it in inv: sell_sel[str(it.id)] = true
		sell_arm = false; render())
	top.add_child(all_b)
	var com_b = UI.button("Chọn đồ thường", UI.SKY, 15)
	com_b.pressed.connect(func():
		sell_sel = {}
		for it in inv:
			if int(it.r) == 0 and int(it.get("up", 0)) == 0: sell_sel[str(it.id)] = true
		sell_arm = false; render())
	top.add_child(com_b)
	var no_b = UI.button("Bỏ chọn", UI.SKY, 15)
	no_b.pressed.connect(func(): sell_sel = {}; sell_arm = false; render())
	top.add_child(no_b)
	var go = UI.button(("Chắc chắn bán %d món?" % cnt) if sell_arm else ("Bán %d món · %s vàng" % [cnt, UI.fmt(total)]), Color("e0565b") if sell_arm else UI.GOLD, 17)
	go.disabled = cnt == 0
	go.pressed.connect(func():
		if not sell_arm:
			sell_arm = true; render(); return
		var ids = sell_sel.keys()
		sell_sel = {}; sell_arm = false
		Net.send({"t": "sellm", "ids": ids}))
	top.add_child(go)
	body.add_child(UI.label("Chạm vào món đồ để đánh dấu bán (giá bằng 75% giá cửa hàng, đồ hiếm và đồ đã rèn bán cao hơn).", 14, Color("5a6b8c"), "body"))
	var g = GridContainer.new()
	g.columns = 9
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	body.add_child(g)
	for it in inv:
		var on = sell_sel.has(str(it.id))
		var cell = ItemCell.make(it, on, true, false, 76)
		if on:
			var ck = UI.outlined("✓", 26, Color("7dff8a"), "bold", 6)
			ck.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			ck.size_flags_horizontal = Control.SIZE_SHRINK_END
			ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(ck)
		var pl = UI.outlined(UI.fmt(Data.sell_price(it)), 11, Color("ffe08a"), "bold", 4)
		pl.size_flags_vertical = Control.SIZE_SHRINK_END
		pl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(pl)
		var iid = str(it.id)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.gui_input.connect(func(ev):
			if UI.tapped(ev):
				if sell_sel.has(iid): sell_sel.erase(iid)
				else: sell_sel[iid] = true
				sell_arm = false
				render())
		g.add_child(cell)
	if inv.is_empty():
		body.add_child(UI.label("Túi chưa có món nào để bán.", 16, UI.INK, "body"))

func _row(no: String, h: String, p: String, small: String, btn: Button, icon: Texture2D = null) -> void:
	var r = PanelContainer.new()
	r.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
	var hb = UI.hbox(12)
	r.add_child(hb)
	if icon:
		var ic = TextureRect.new()
		ic.texture = icon
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(64, 64)
		hb.add_child(ic)
	else:
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
		_row(str(i + 1), str(s.n), str(s.d), "Cấp yêu cầu %d · Hồi chiêu %s giây%s" % [int(s.req), str(s.cd), (" · Sách %s vàng" % UI.fmt(s.price)) if int(s.price) > 0 else ""], b, Data.tex(Data.A.get("hud", {}).get("ui", {}).get("book%d" % clampi(i, 1, 5), "")))

var pot_q := {}     # số lượng đang chọn cho từng loại bình (giữ khi bảng vẽ lại)

func _pots(d: Dictionary) -> void:
	body.add_child(UI.label("Bình hồi lượng cố định: Nhỏ cho cấp thấp, Vừa cho cấp giữa, Lớn cho cấp cao. Mỗi loại mang tối đa %d bình. Chỉ mua được ở đây." % Data.POT_MAX, 15, Color("5a6b8c"), "body"))
	body.add_child(UI.hsep())
	for ki in [false, true]:
		for t in 3:
			var key: String = (Data.KI_KEYS if ki else Data.HP_KEYS)[t]
			var have = int(d.get(key, 0))
			var pr = Data.tier_price(t)
			var room = maxi(0, Data.POT_MAX - have)
			var r = PanelContainer.new()
			r.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
			var hb = UI.hbox(10)
			r.add_child(hb)
			var ic = TextureRect.new()
			ic.texture = Data.pot_icon(ki, t)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(52, 52)
			hb.add_child(ic)
			var mid = UI.vbox(2)
			mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mid.add_child(UI.label("%s %s" % ["Bình KI" if ki else "Bình máu", str(Data.POT_T[t].n).to_lower()], 18, UI.INK, "bold"))
			mid.add_child(UI.label("Hồi %d %s · Có %d/%d · %s vàng/bình" % [int(Data.POT_T[t].ki if ki else Data.POT_T[t].hp), "KI" if ki else "máu", have, Data.POT_MAX, UI.fmt(pr)], 13, Color("5a6b8c"), "semi"))
			hb.add_child(mid)
			var qk = key
			var q = clampi(int(pot_q.get(qk, 1)), 1, maxi(1, room))
			pot_q[qk] = q
			var spin = SpinBox.new()
			spin.min_value = 1
			spin.max_value = maxi(1, room)
			spin.step = 1
			spin.value = q
			spin.custom_minimum_size = Vector2(96, 44)
			spin.select_all_on_focus = true
			var minus = UI.button("−", UI.SKY, 20)
			minus.custom_minimum_size = Vector2(44, 44)
			minus.pressed.connect(func(): spin.value = spin.value - 1)
			var plus = UI.button("+", UI.SKY, 20)
			plus.custom_minimum_size = Vector2(44, 44)
			plus.pressed.connect(func(): spin.value = spin.value + 1)
			hb.add_child(minus)
			hb.add_child(spin)
			hb.add_child(plus)
			var buy = UI.button("Mua %s v" % UI.fmt(pr * q), UI.GOLD, 15)
			buy.custom_minimum_size = Vector2(130, 44)
			buy.disabled = room <= 0 or int(d.gold) < pr * q
			var tt: int = t
			var kk = "ki" if ki else ""
			var upd = func(v):
				pot_q[qk] = int(v)
				buy.text = "Mua %s v" % UI.fmt(pr * int(v))
				buy.disabled = room <= 0 or int(game_gold()) < pr * int(v)
			spin.value_changed.connect(upd)
			buy.pressed.connect(func(): Net.send({"t": "buypot", "n": int(spin.value), "tier": tt, "k": kk}))
			hb.add_child(buy)
			var mx = UI.button("Tối đa", UI.BLUE, 14)
			mx.custom_minimum_size = Vector2(80, 44)
			mx.disabled = room <= 0 or pr <= 0
			mx.pressed.connect(func(): spin.value = clampi(int(game_gold()) / maxi(1, pr), 1, maxi(1, room)))
			hb.add_child(mx)
			body.add_child(r)

func game_gold() -> int:
	return int(game.me_data.get("gold", 0))

var fpick = {}           # món đang xem trong danh sách (chưa đặt vào ô)

## lò rèn: trên cùng 2 ô (trang bị cần rèn · đá cường hóa), dưới là túi đồ; chạm một món để xem chi tiết rồi "Chọn món này"
func _forge(d: Dictionary) -> void:
	var list: Array = []
	for s2 in Data.SLOTS:
		if d.eq.get(s2) is Dictionary:
			list.append({"it": d.eq[s2], "slot": s2})
	for it in d.inv:
		if str(it.get("slot", "")) != "egg":
			list.append({"it": it, "slot": ""})
	var cur = null
	var pk = null
	for o in list:
		if Data.same_id(fit.get("id"), o.it.id):
			cur = o
		if Data.same_id(fpick.get("id"), o.it.id):
			pk = o
	# ---- hàng trên: ô trang bị + ô đá + thông tin rèn ----
	var top = UI.hbox(14)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(top)
	var slot_box = UI.vbox(4)
	var sl
	if cur:
		sl = ItemCell.make(cur.it, true, true, false, 96)
	else:
		sl = PanelContainer.new()
		sl.custom_minimum_size = Vector2(96, 96)
		sl.add_theme_stylebox_override("panel", UI.box(Color("eef2fb"), Color("8fa0c4"), 14, 3, false))
		var q = UI.label("+", 44, Color("8fa0c4"), "title")
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sl.add_child(q)
	slot_box.add_child(sl)
	var sll = UI.label("Trang bị" if cur == null else "+%d" % int(cur.it.get("up", 0)), 14, Color("5a6b8c"), "bold")
	sll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_box.add_child(sll)
	top.add_child(slot_box)
	var plus = UI.label("+", 34, UI.INK, "title")
	top.add_child(plus)
	var f = Data.forge_info(cur.it) if cur else {}
	var need = int(f.get("stones", 0))
	var st_box = UI.vbox(4)
	var sp2 = PanelContainer.new()
	sp2.custom_minimum_size = Vector2(96, 96)
	sp2.add_theme_stylebox_override("panel", UI.box(Color("eef6ff"), Color("5aa0e0"), 14, 3, false))
	var si = TextureRect.new()
	si.texture = Data.tex(Data.A.ai.get("stone", {}).get("u", ""))
	si.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp2.add_child(si)
	var sn = UI.outlined("x%d" % int(d.stones), 18, Color.WHITE, "bold", 5)
	sn.size_flags_vertical = Control.SIZE_SHRINK_END
	sn.size_flags_horizontal = Control.SIZE_SHRINK_END
	sp2.add_child(sn)
	st_box.add_child(sp2)
	var stl = UI.label(("Cần %d đá" % need) if cur else "Đá cường hóa", 14, (Color("d9345a") if cur and int(d.stones) < need else Color("5a6b8c")), "bold")
	stl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_box.add_child(stl)
	top.add_child(st_box)
	var info = UI.vbox(6)
	info.custom_minimum_size = Vector2(330, 0)
	top.add_child(info)
	if cur == null:
		var hint = UI.label("Chọn một món trong túi bên dưới rồi bấm \"Chọn món này\" để đặt vào ô.", 16, Color("5a6b8c"), "semi")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(hint)
	else:
		var it2: Dictionary = cur.it
		info.add_child(UI.label(Data.item_name(it2) + "  →  +%d" % int(f.L), 19, Data.rar_color(int(it2.r)), "bold"))
		if int(it2.get("up", 0)) >= int(Data.D.forge.max):
			info.add_child(UI.label("Đã rèn tối đa.", 17, UI.INK, "semi"))
		else:
			var l2 = UI.label("Thành công %d%% · %s vàng%s" % [int(f.rate), UI.fmt(f.gold), (" · Thất bại tụt %d cấp" % int(f.drop)) if int(f.drop) > 0 else ""], 16, UI.INK, "semi")
			l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(l2)
			var br = UI.hbox(8)
			info.add_child(br)
			var b = UI.button("Rèn", UI.GOLD, 22)
			b.custom_minimum_size = Vector2(150, 52)
			b.disabled = int(d.gold) < int(f.gold) or int(d.stones) < need
			var cid = it2.id
			var cs: String = cur.slot
			b.pressed.connect(func():
				var m = {"t": "forge", "id": cid}
				if cs != "": m["slot"] = cs
				Net.send(m))
			br.add_child(b)
			var bo = UI.button("Bỏ ra", UI.SKY, 16)
			bo.custom_minimum_size = Vector2(90, 52)
			bo.pressed.connect(func(): fit = {}; msg = ""; render())
			br.add_child(bo)
	body.add_child(UI.hsep())
	# ---- dưới: túi đồ (trái) + chi tiết món đang xem (phải) ----
	var low = UI.hbox(14)
	body.add_child(low)
	var g = GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	low.add_child(g)
	for o in list:
		var it: Dictionary = o.it
		var p = ItemCell.make(it, Data.same_id(fpick.get("id"), it.id) or Data.same_id(fit.get("id"), it.id), true, false, 70)
		if o.slot != "":
			var e = UI.label("Mặc", 11, Color("2fa84f"), "bold")
			e.size_flags_vertical = Control.SIZE_SHRINK_END
			p.add_child(e)
		var oid = it.id
		var osl: String = o.slot
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(ev):
			if UI.tapped(ev):
				fpick = {"id": oid, "slot": osl}; render())
		g.add_child(p)
	if list.is_empty():
		low.add_child(UI.label("Bạn chưa có trang bị. Hạ quái để nhặt đồ rồi quay lại.", 16, UI.INK, "body"))
		return
	var det = UI.vbox(6)
	det.custom_minimum_size = Vector2(300, 0)
	low.add_child(det)
	if pk == null:
		det.add_child(UI.label("Chạm vào một món để xem.", 16, Color("5a6b8c"), "semi"))
		return
	var it3: Dictionary = pk.it
	var nl = UI.label(Data.item_name(it3) + (" +%d" % int(it3.get("up", 0)) if int(it3.get("up", 0)) > 0 else ""), 20, Data.rar_color(int(it3.r)), "bold")
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det.add_child(nl)
	det.add_child(UI.label("%s · Cấp %d%s" % [str(Data.D.rar[int(it3.r)].n), int(it3.get("lvl", 1)), " · Đang mặc" if pk.slot != "" else ""], 15, Color("5a6b8c"), "semi"))
	for k in ["atk", "def", "hp", "spd"]:
		var v = Data.item_stat(it3, k)
		if v != 0:
			det.add_child(UI.label("%s: %d" % [Data.STAT_N[k], v], 17, UI.INK, "semi"))
	var fi = Data.forge_info(it3)
	if int(it3.get("up", 0)) < int(Data.D.forge.max):
		det.add_child(UI.label("Rèn lên +%d: %d%% · %d đá · %s vàng" % [int(fi.L), int(fi.rate), int(fi.stones), UI.fmt(fi.gold)], 14, Color("5a6b8c"), "semi"))
	var ch = UI.button("Đang ở ô rèn" if Data.same_id(fit.get("id"), it3.id) else "Chọn món này", UI.GREEN, 18)
	ch.custom_minimum_size = Vector2(0, 50)
	ch.disabled = Data.same_id(fit.get("id"), it3.id)
	var pid = it3.id
	var psl: String = pk.slot
	ch.pressed.connect(func(): fit = {"id": pid, "slot": psl}; msg = ""; render())
	det.add_child(ch)


## Thương Nhân Giáp: đồ mọi phái, mọi độ hiếm, chỉ số mặc định (đồ rơi từ quái có thể thấp hơn hoặc cao hơn)
const SHOP_MUL = [1, 3.5, 10, 32]
func _gear(d: Dictionary) -> void:
	if gear_cls == "":
		gear_cls = game.cls()
	if gear_lv <= 0:
		gear_lv = max(1, int(floor(int(d.lv) / 5.0)) * 5)
	var lvl = gear_lv
	# chọn cấp đồ: 1, 5, 10 … 100 (đồ cao hơn cấp mình mua được nhưng chưa mặc được)
	var lr = UI.hbox(8)
	body.add_child(lr)
	lr.add_child(UI.label("Cấp đồ:", 17, UI.INK, "bold"))
	for st2 in [[-10, "«"], [-5, "‹"]]:
		var bb = UI.button(str(st2[1]), UI.SKY, 18)
		bb.custom_minimum_size = Vector2(48, 42)
		var dd: int = st2[0]
		bb.pressed.connect(func(): gear_lv = _glv(gear_lv + dd); render())
		lr.add_child(bb)
	var lvl_l = UI.label("Cấp %d" % lvl, 20, UI.GOLD.darkened(0.35), "bold")
	lvl_l.custom_minimum_size = Vector2(90, 0)
	lvl_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lr.add_child(lvl_l)
	for st3 in [[5, "›"], [10, "»"]]:
		var bb2 = UI.button(str(st3[1]), UI.SKY, 18)
		bb2.custom_minimum_size = Vector2(48, 42)
		var dd2: int = st3[0]
		bb2.pressed.connect(func(): gear_lv = _glv(gear_lv + dd2); render())
		lr.add_child(bb2)
	var mine = UI.button("Cấp của tôi", UI.GREEN, 15)
	mine.pressed.connect(func(): gear_lv = max(1, int(floor(int(d.lv) / 5.0)) * 5); render())
	lr.add_child(mine)
	body.add_child(UI.label("Đồ thường, chỉ số mặc định%s. Đồ hiếm, sử thi, huyền thoại chỉ có từ quái và trùm." % ("" if lvl <= int(d.lv) else " · cần cấp %d mới mặc được" % lvl), 15, Color("5a6b8c") if lvl <= int(d.lv) else Color("b0552f"), "body"))
	for r in 1:   # chỉ bán đồ thường (đồ hiếm phải săn từ quái, trùm)
		var row = UI.hbox(10)
		var nm = UI.label(str(Data.D.rar[r].n), 18, Data.rar_color(r) if r > 0 else UI.INK, "bold")
		nm.custom_minimum_size = Vector2(120, 0)
		row.add_child(nm)
		for slot in [["hat", "armor", "cape", "weapon"], ["boots", "gloves", "neck"], ["ring", "earring", "belt", "charm"]][gear_grp]:
			var it = _shop_item(gear_cls, slot, r, lvl)
			var price = int(round((25 + lvl * 9) * (1.0 + lvl / 3.0) * 3.5 * SHOP_MUL[r] * Data.shop_mul()))
			var v = UI.vbox(2)
			var cell = ItemCell.make(it, false, Data.can_wear(it, game.cls()), false, 70)
			v.add_child(cell)
			var st = []
			for k in it.st:
				st.append("%s %d" % [Data.STAT_N[k], int(it.st[k])])
			var sl = UI.label(", ".join(st), 12, UI.INK, "semi")
			sl.custom_minimum_size = Vector2(150, 0)
			v.add_child(sl)
			var b = UI.button("%s vàng" % UI.fmt(price), UI.GOLD, 14)
			b.disabled = int(d.gold) < price or d.inv.size() >= 30
			var cs: String = gear_cls
			var ss: String = slot
			var rr: int = r
			var lv2: int = lvl
			b.pressed.connect(func(): Net.send({"t": "shopbuy", "cls": cs, "slot": ss, "r": rr, "lvl": lv2}))
			v.add_child(b)
			row.add_child(v)
		body.add_child(row)

## cấp đồ cửa hàng: 1, 5, 10 … 100
func _glv(v: int) -> int:
	if v < 5:
		return 1
	return clampi(int(round(v / 5.0)) * 5, 5, 100)

func _shop_item(c: String, slot: String, r: int, lvl: int) -> Dictionary:
	var m = float(Data.D.rar[r].m)
	var base = 3 + lvl * 1.4
	var st = {}
	match slot:
		"hat": st = {"def": base * 0.6 * m, "hp": base * 3 * m}
		"armor": st = {"def": base * m, "hp": base * 5 * m}
		"cape": st = {"spd": (2 + lvl * 0.3) * m, "def": base * 0.4 * m}
		"boots": st = {"spd": (1.5 + lvl * 0.25) * m, "def": base * 0.3 * m}
		"gloves": st = {"atk": base * 0.5 * m, "def": base * 0.2 * m}
		"neck": st = {"hp": base * 2.5 * m, "atk": base * 0.35 * m}
		"ring": st = {"atk": base * 0.7 * m, "spd": (1 + lvl * 0.15) * m}
		"earring": st = {"hp": base * 2 * m, "atk": base * 0.3 * m}
		"belt": st = {"hp": base * 3 * m, "def": base * 0.45 * m}
		"charm": st = {"def": base * 0.6 * m, "hp": base * 1.5 * m, "atk": base * 0.2 * m}
		_: st = {"atk": base * 1.3 * m}
	for k in st:
		st[k] = max(1, int(round(st[k])))
	if slot in Data.FREE:
		return {"id": "", "slot": slot, "cls": "", "tier": r, "r": r, "lvl": lvl, "b": Data.band(lvl), "name": Data.gen_name(slot, c, r, lvl), "st": st, "shop": 1}
	return {"id": "", "slot": slot, "cls": c, "tier": r, "r": r, "lvl": lvl, "b": Data.band(lvl), "name": Data.gen_name(slot, c, r, lvl), "st": st, "shop": 1}

## ---------- Bà Ấp Trứng: ấp 24 giờ, trả vàng rút ngắn một nửa (1 lần), nở thành pet ----------
const STAGE_N := ["Non", "Trưởng thành", "Thần thú"]
const PST := [["hp", "Máu"], ["atk", "Sức đánh"], ["def", "Giáp"], ["aspd", "Tốc đánh"], ["crit", "Chí mạng"]]
const SP_N := {"fire": "Rồng Lửa", "ice": "Cáo Băng", "wolf": "Sói Sấm", "turtle": "Rùa Ngọc"}
const SP_SK := {"fire": ["Phóng Cầu Lửa", "Phun Lửa", "Hỏa Long Giáng Thế"], "ice": ["Băng Tiễn", "Gió Tuyết", "Bão Băng Chín Đuôi"],
	"wolf": ["Tia Chớp", "Lôi Độn", "Thiên Lôi Giáng"], "turtle": ["Khiên Ngọc", "Suối Hồi Phục", "Thành Đồng Vách Sắt"]}
const SK_LV := [10, 40, 80]

func _process(_dt: float) -> void:
	if not visible:
		return
	if timer_lb and game.me_data.get("hatch") is Dictionary:
		timer_lb.text = _left_text(game.me_data.hatch)
	if free_btn:
		var w = free_at - Time.get_ticks_msec() / 1000.0
		free_btn.disabled = w > 0
		free_btn.text = "Thả vĩnh viễn (%d)" % ceili(w) if w > 0 else "Thả vĩnh viễn"

func _left_text(h: Dictionary) -> String:
	var left = (float(h.end) - Data.now_ms()) / 1000.0
	if left <= 0:
		return "Trứng đã sẵn sàng nở!"
	return "Còn %02d:%02d:%02d" % [int(left / 3600), int(left / 60) % 60, int(left) % 60]

func _egg_tex(sp: String) -> Texture2D:
	return Data.tex(Data.A.get("egg", {}).get(sp, {}).get("icon", ""))

func _pet_tex(sp: String, stage: int) -> Texture2D:
	var L: Array = Data.A.get("pet", {}).get(sp, [])
	if L.is_empty():
		return null
	var a: Dictionary = L[clampi(stage, 0, L.size() - 1)].a
	var fr: Array = a.get("idle", [])
	return Data.tex(fr[0]) if not fr.is_empty() else null

func _pic(tx: Texture2D, sz: float) -> TextureRect:
	var t = TextureRect.new()
	t.texture = tx
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(sz, sz)
	return t

func _hatch(d: Dictionary) -> void:
	var pets: Array = d.get("pets", [])
	body.add_child(UI.label("Mang Trứng Thần Thú (rơi khi kết liễu Ma Long Hắc Vực) tới đây để ấp. Mỗi lần ấp 1 quả, nở sau 24 giờ. Chuồng chứa tối đa 3 pet.", 15, Color("5a6b8c"), "body"))
	body.add_child(UI.hsep())
	var h = d.get("hatch")
	if h is Dictionary:
		var hb = UI.hbox(16)
		body.add_child(hb)
		hb.add_child(_pic(_egg_tex(str(h.sp)), 120))
		var v = UI.vbox(8)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(v)
		v.add_child(UI.label("Đang ấp: Trứng " + str(SP_N.get(str(h.sp), "")), 22, UI.INK, "bold"))
		timer_lb = UI.label(_left_text(h), 26, Color("b85c00"), "title")
		v.add_child(timer_lb)
		var ready = float(h.end) <= Data.now_ms()
		if ready:
			var bo = UI.button("Nở", UI.GREEN, 22)
			bo.custom_minimum_size = Vector2(200, 56)
			bo.disabled = pets.size() >= 3
			bo.pressed.connect(func(): Net.send({"t": "hatch_open"}))
			v.add_child(bo)
			if pets.size() >= 3:
				v.add_child(UI.label("Chuồng đã đủ 3 pet, hãy thả bớt một pet.", 15, Color("d9345a"), "semi"))
		else:
			var cut = int(h.get("cut", 0)) == 1
			var bc = UI.button("Đã rút ngắn" if cut else "Rút ngắn một nửa · 2.000.000 vàng", UI.GREY if cut else UI.GOLD, 18)
			bc.custom_minimum_size = Vector2(340, 52)
			bc.disabled = cut or int(d.gold) < 2000000
			bc.pressed.connect(func(): Net.send({"t": "hatch_cut"}))
			v.add_child(bc)
			v.add_child(UI.label("Mỗi quả trứng chỉ được rút ngắn 1 lần, không nở ngay được.", 14, Color("5a6b8c"), "semi"))
		return
	var eggs: Array = []
	for it in d.inv:
		if str(it.get("slot", "")) == "egg":
			eggs.append(it)
	if eggs.is_empty():
		body.add_child(UI.label("Bạn chưa có trứng nào. Hạ Ma Long Hắc Vực (xuất hiện khoảng 30 phút một lần ở các bản đồ săn quái) bằng đòn cuối để nhận trứng, hoặc giao dịch với người chơi khác.", 17, UI.INK, "body"))
		return
	for it in eggs:
		var b = UI.button("Ấp trứng này", UI.GREEN, 18)
		b.disabled = pets.size() >= 3
		var eid = it.id
		b.pressed.connect(func(): Net.send({"t": "hatch_start", "id": eid}))
		var r = PanelContainer.new()
		r.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
		var hb2 = UI.hbox(12)
		r.add_child(hb2)
		hb2.add_child(_pic(_egg_tex(str(it.sp)), 72))
		var mid = UI.vbox(2)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(UI.label(str(it.name), 20, UI.INK, "bold"))
		mid.add_child(UI.label("Nở thành " + str(SP_N.get(str(it.sp), "")) + " · sao (tư chất) ngẫu nhiên 1–5", 14, Color("5a6b8c"), "semi"))
		hb2.add_child(mid)
		b.custom_minimum_size = Vector2(170, 50)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb2.add_child(b)
		body.add_child(r)

func _pets(d: Dictionary) -> void:
	var pets: Array = d.get("pets", [])
	body.add_child(UI.label("Pet ra trận đi theo bạn, tự đánh quái và nhận kinh nghiệm (bạn được thêm 10%%). Mỗi cấp pet được 3 điểm chỉ số ngẫu nhiên. Chuồng %d / 3." % pets.size(), 15, Color("5a6b8c"), "body"))
	body.add_child(UI.hsep())
	if pets.is_empty():
		body.add_child(UI.label("Chưa có pet. Ấp Trứng Thần Thú ở Bà Ấp Trứng trong Làng.", 17, UI.INK, "body"))
		return
	var on = str(d.get("petOn", ""))
	var rt: Dictionary = d.get("pet", {}) if d.get("pet") is Dictionary else {}
	for p in pets:
		var pid = str(p.id)
		var sp = str(p.sp)
		var stg = int(p.get("stage", 0))
		var r = PanelContainer.new()
		r.add_theme_stylebox_override("panel", UI.box(Color("fffbe9") if pid == on else Color.WHITE, Color("e0a400") if pid == on else Color("b8c4dc"), 12, 3 if pid == on else 2, false))
		body.add_child(r)
		var hb = UI.hbox(14)
		r.add_child(hb)
		hb.add_child(_pic(_pet_tex(sp, stg), 110))
		var v = UI.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(v)
		v.add_child(UI.label("%s  %s" % [str(p.name), "★".repeat(int(p.star)) + "☆".repeat(5 - int(p.star))], 22, UI.INK, "bold"))
		var st_line = "%s · Lv.%d · %s · Kinh nghiệm %s / %s" % [SP_N.get(sp, ""), int(p.lv), STAGE_N[clampi(stg, 0, 2)], UI.fmt(int(p.exp)), UI.fmt(int(p.get("need", 0)))]
		v.add_child(UI.label(st_line, 14, Color("5a6b8c"), "semi"))
		if pid == on and not rt.is_empty():
			if int(rt.get("faint", 0)) > 0:
				v.add_child(UI.label("Đang ngất · tự hồi sinh sau khoảng %d giây" % int(rt.faint), 14, Color("d9345a"), "semi"))
			else:
				v.add_child(UI.label("Máu %d / %d" % [int(rt.hp), int(rt.maxHp)], 14, Color("2fa84f"), "semi"))
		var S: Dictionary = p.get("st", {})
		var pt: Dictionary = p.get("pt", {})
		var vals = {"hp": str(int(S.get("maxHp", 0))), "atk": str(snapped(float(S.get("atk", 0)), 0.1)), "def": str(snapped(float(S.get("def", 0)), 0.1)),
			"aspd": "x%s" % str(snapped(float(S.get("aspd", 1)), 0.01)), "crit": "%d%%" % int(round(float(S.get("crit", 0)) * 100))}
		v.add_child(UI.hsep())
		var g = GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 18)
		v.add_child(g)
		for k in PST:
			g.add_child(UI.label("%s %s (%d điểm)" % [k[1], vals[k[0]], int(pt.get(k[0], 0))], 13, UI.INK, "semi"))
		var sks: Array = SP_SK.get(sp, [])
		var sk_t = []
		for i in 3:
			sk_t.append(("✔ " + str(sks[i])) if int(p.lv) >= SK_LV[i] else (str(sks[i]) + " (mở ở cấp %d)" % SK_LV[i]))
		v.add_child(UI.hsep())
		v.add_child(UI.label("Kỹ năng: " + "  ·  ".join(sk_t), 13, Color("3d4a66"), "semi"))
		var row = UI.hbox(8)
		v.add_child(row)
		var bo = UI.button("Cất về chuồng" if pid == on else "Ra trận", UI.SKY if pid == on else UI.GREEN, 16)
		bo.pressed.connect(func(): Net.send({"t": "pet_on", "id": pid}))
		row.add_child(bo)
		if int(p.get("rn", 0)) == 0:
			var bn = UI.button("Đổi tên (miễn phí 1 lần)", UI.GOLD, 16)
			bn.pressed.connect(func(): name_edit = "" if name_edit == pid else pid; free_arm = ""; render())
			row.add_child(bn)
		var bf = UI.button("Thả pet", UI.RED, 16)
		bf.pressed.connect(func(): free_arm = "" if free_arm == pid else pid; free_at = Time.get_ticks_msec() / 1000.0 + 3.0; name_edit = ""; render())
		row.add_child(bf)
		if name_edit == pid:
			var nr = UI.hbox(8)
			v.add_child(nr)
			var le = LineEdit.new()
			le.placeholder_text = "Tên mới (2–12 ký tự)"
			le.max_length = 12
			le.custom_minimum_size = Vector2(260, 44)
			nr.add_child(le)
			var ok = UI.button("Lưu tên", UI.GREEN, 16)
			ok.pressed.connect(func(): Net.send({"t": "pet_name", "id": pid, "name": le.text.strip_edges()}); name_edit = "")
			nr.add_child(ok)
			nr.add_child(UI.label("Chỉ đổi được 1 lần.", 13, Color("b85c00"), "semi"))
		if free_arm == pid:
			var fr = UI.vbox(6)
			v.add_child(fr)
			fr.add_child(UI.label("Thả pet là XÓA VĨNH VIỄN, không lấy lại được. Đồ pet đang đeo trả về túi.", 15, Color("d9345a"), "bold"))
			var fr2 = UI.hbox(8)
			fr.add_child(fr2)
			var le2 = LineEdit.new()
			le2.placeholder_text = "Nhập đúng tên: " + str(p.name)
			le2.custom_minimum_size = Vector2(300, 44)
			fr2.add_child(le2)
			var bx = UI.button("Thả vĩnh viễn (3)", UI.RED, 16)
			bx.disabled = true
			free_btn = bx
			var pname = str(p.name)
			bx.pressed.connect(func():
				if le2.text.strip_edges() != pname:
					msg = "Tên chưa đúng, nhập đúng \"%s\" để thả." % pname; msg_ok = false; render(); return
				Net.send({"t": "pet_free", "id": pid, "confirm": le2.text.strip_edges()}); free_arm = "")
			fr2.add_child(bx)
			var bc = UI.button("Hủy", UI.GREY, 16)
			bc.pressed.connect(func(): free_arm = ""; render())
			fr2.add_child(bc)
