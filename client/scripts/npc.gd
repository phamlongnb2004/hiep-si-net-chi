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
	mode = id if id in ["shop", "gear"] else ("egg" if id in ["egg", "pets"] else "forge")
	tab = {"shop": "books", "gear": "gear", "egg": "pets" if id == "pets" else "hatch"}.get(mode, "forge")
	free_arm = ""
	name_edit = ""
	msg = ""
	fit = {}
	visible = true
	render()

func close() -> void:
	visible = false

func render() -> void:
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
			b2.pressed.connect(func(): gear_cls = cc; msg = ""; render())
			tabs.add_child(b2)
		for gi in 3:
			var b3 = UI.button(["Giáp & vũ khí", "Giày, găng, dây", "Trang sức"][gi], UI.GREEN if gear_grp == gi else UI.SKY, 16)
			var g2: int = gi
			b3.pressed.connect(func(): gear_grp = g2; msg = ""; render())
			tabs.add_child(b3)
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
		"hatch": _hatch(d)
		"pets": _pets(d)
	UI.wrap_all(body, 200)

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
		var p = ItemCell.make(it, selected, true, false, 76)
		if o.slot != "":
			var e = UI.label("Mặc", 11, Color("2fa84f"), "bold")
			e.size_flags_vertical = Control.SIZE_SHRINK_END
			p.add_child(e)
		var oid = it.id
		var osl: String = o.slot
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(ev):
			if UI.tapped(ev):
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


## Thương Nhân Giáp: đồ mọi phái, mọi độ hiếm, chỉ số mặc định (đồ rơi từ quái có thể thấp hơn hoặc cao hơn)
const SHOP_MUL = [1, 3.5, 10, 32]
func _gear(d: Dictionary) -> void:
	if gear_cls == "":
		gear_cls = game.cls()
	var lvl = max(1, int(floor(int(d.lv) / 5.0)) * 5)
	body.add_child(UI.label("Đồ thường cấp %d (theo cấp của bạn), chỉ số mặc định. Đồ hiếm, sử thi, huyền thoại chỉ có từ quái và trùm." % lvl, 15, Color("5a6b8c"), "body"))
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
			b.pressed.connect(func(): Net.send({"t": "shopbuy", "cls": cs, "slot": ss, "r": rr}))
			v.add_child(b)
			row.add_child(v)
		body.add_child(row)

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
