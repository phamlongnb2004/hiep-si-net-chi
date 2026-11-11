extends Control
class_name Social
## Bạn bè (tối đa 100), menu khi chạm vào người chơi khác, lời mời và bảng giao dịch.

var game: Game
var friends: Array = []
var reqs: Array = []
var fmax = 100
var panel: Control          # bảng bạn bè
var plist: VBoxContainer
var add_edit: LineEdit
var pmenu: Control          # menu khi chạm người chơi
var popup: Control          # lời mời giao dịch
var trade_ui: Control
var tr: Dictionary = {}     # trạng thái giao dịch hiện tại (máy chủ gửi)
var tr_items: Array = []    # id đồ mình đang đặt
var tr_gold: LineEdit
var tr_body: HBoxContainer
var pm_to = 0
signal badge(n: int)

func setup(g: Game) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.theme()
	Net.message.connect(_on_msg)
	g.player_tapped.connect(_player_menu)

func _dim(parent: Control, close: Callable) -> void:
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: close.call())
	parent.add_child(dim)

func _overlay() -> Control:
	var c = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	return c

## ---------- tin từ máy chủ ----------
func _on_msg(m: Dictionary) -> void:
	match str(m.get("t")):
		"friends":
			friends = m.get("list", [])
			reqs = m.get("req", [])
			fmax = int(m.get("max", 100))
			badge.emit(reqs.size())
			if panel and is_instance_valid(panel):
				_render_friends()
		"fr_req":
			game.log_line.emit("%s muốn kết bạn với bạn (mở Bạn bè để đồng ý)." % m.get("name", ""), Color("ff9ee0"))
		"tr_ask":
			_ask_popup(m)
		"trade":
			tr = m
			if not trade_ui or not is_instance_valid(trade_ui):
				tr_items = []
				_open_trade()
			_render_trade()
		"trade_end":
			game.log_line.emit(str(m.get("msg", "")), Color("9be05a") if int(m.get("ok", 0)) == 1 else Color("ffb347"))
			tr = {}
			if trade_ui and is_instance_valid(trade_ui):
				trade_ui.queue_free()
			trade_ui = null
		"res":
			if str(m.get("op", "")).begins_with("fr_") or str(m.get("op", "")).begins_with("tr_") or m.get("op") == "pm":
				if m.get("msg"):
					game.log_line.emit(str(m.msg), Color("9be05a") if m.get("ok") else Color("ffb347"))

## ---------- chạm vào người chơi khác ----------
func _player_menu(id: int, nm: String) -> void:
	if pmenu and is_instance_valid(pmenu):
		pmenu.queue_free()
	pmenu = _overlay()
	_dim(pmenu, func(): pmenu.queue_free())
	var card = UI.card(Vector2(320, 0))
	pmenu.add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	v.add_child(UI.label(nm, 24, UI.INK, "bold"))
	var is_friend = false
	for f in friends:
		if int(f.get("id", 0)) == id:
			is_friend = true
	if not is_friend:
		var b1 = UI.button("Kết bạn", UI.GREEN, 20)
		b1.pressed.connect(func(): Net.send({"t": "fr_add", "id": id}); pmenu.queue_free())
		v.add_child(b1)
	var b2 = UI.button("Giao dịch", UI.GOLD, 20)
	b2.pressed.connect(func(): Net.send({"t": "tr_ask", "id": id}); pmenu.queue_free())
	v.add_child(b2)
	var b3 = UI.button("Đóng", UI.SKY, 18)
	b3.pressed.connect(func(): pmenu.queue_free())
	v.add_child(b3)

func _ask_popup(m: Dictionary) -> void:
	if popup and is_instance_valid(popup):
		popup.queue_free()
	popup = _overlay()
	var card = UI.card(Vector2(380, 0))
	popup.add_child(UI.center(card))
	var v = UI.vbox(12)
	card.add_child(v)
	v.add_child(UI.label("%s (Cấp %d) mời bạn giao dịch" % [m.get("n", ""), int(m.get("lv", 1))], 20, UI.INK, "bold"))
	var h = UI.hbox(10)
	v.add_child(h)
	var y = UI.button("Đồng ý", UI.GREEN, 20)
	var fid = int(m.id)
	y.pressed.connect(func(): Net.send({"t": "tr_yes", "id": fid}); popup.queue_free())
	h.add_child(y)
	var n = UI.button("Từ chối", UI.SKY, 20)
	n.pressed.connect(func(): popup.queue_free())
	h.add_child(n)
	var p = popup
	get_tree().create_timer(30).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

## ---------- bạn bè ----------
func open_friends() -> void:
	if panel and is_instance_valid(panel):
		panel.queue_free()
		panel = null
		return
	panel = _overlay()
	_dim(panel, func(): panel.queue_free(); panel = null)
	var card = UI.card(Vector2(620, 520))
	panel.add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	var head = UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("Bạn bè", 30, UI.INK, "title"))
	var cnt = UI.label("", 18, Color("5a6b8c"), "semi")
	cnt.name = "Count"
	cnt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cnt)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(func(): panel.queue_free(); panel = null)
	head.add_child(x)
	var ar = UI.hbox(8)
	v.add_child(ar)
	add_edit = UI.edit("Tên nhân vật cần kết bạn")
	add_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_edit.max_length = 16
	ar.add_child(add_edit)
	var ab = UI.button("Kết bạn", UI.GREEN, 18)
	ab.pressed.connect(func():
		if add_edit.text.strip_edges() != "":
			Net.send({"t": "fr_add", "name": add_edit.text.strip_edges()})
			add_edit.text = "")
	ar.add_child(ab)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(560, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	plist = UI.vbox(8)
	plist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(plist)
	Net.send({"t": "fr_list"})
	_render_friends()

func _row(parent: Control) -> HBoxContainer:
	var pc = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 12, 2, false))
	var h = UI.hbox(10)
	pc.add_child(h)
	parent.add_child(pc)
	return h

func _render_friends() -> void:
	if not plist or not is_instance_valid(plist):
		return
	for c in plist.get_children():
		c.queue_free()
	var cnt = panel.find_child("Count", true, false)
	if cnt:
		cnt.text = "%d / %d" % [friends.size(), fmax]
	if not reqs.is_empty():
		plist.add_child(UI.label("Lời mời kết bạn", 18, UI.INK, "bold"))
		for r in reqs:
			var h = _row(plist)
			var l = UI.label("%s · Cấp %d" % [r.name, int(r.get("lv", 0))], 18, UI.INK, "semi")
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			var uid = int(r.uid)
			var y = UI.button("Đồng ý", UI.GREEN, 16)
			y.pressed.connect(func(): Net.send({"t": "fr_ok", "uid": uid}))
			h.add_child(y)
			var n = UI.button("Từ chối", UI.SKY, 16)
			n.pressed.connect(func(): Net.send({"t": "fr_no", "uid": uid}))
			h.add_child(n)
	plist.add_child(UI.label("Danh sách bạn" if not friends.is_empty() else "Chưa có bạn. Chạm vào người chơi khác hoặc nhập tên để kết bạn.", 16, Color("5a6b8c"), "semi"))
	var on = friends.filter(func(f): return int(f.online) == 1)
	var off = friends.filter(func(f): return int(f.online) != 1)
	for f in on + off:
		var h = _row(plist)
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = Color("3fcf6b") if int(f.online) == 1 else Color("aab4c8")
		h.add_child(dot)
		var where = ""
		if int(f.online) == 1 and int(f.get("map", -1)) >= 0:
			where = " · " + str(Data.D.maps[int(f.map)].name)
		var l = UI.label("%s · Cấp %d%s" % [f.name, int(f.get("lv", 0)), where], 17, UI.INK, "semi")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var uid = int(f.uid)
		if int(f.online) == 1:
			var pm = UI.button("Nhắn", UI.SKY, 16)
			var fname: String = f.name
			pm.pressed.connect(func(): _pm(uid, fname))
			h.add_child(pm)
		var del = UI.button("Xóa", UI.RED, 16)
		del.pressed.connect(func(): Net.send({"t": "fr_del", "uid": uid}))
		h.add_child(del)

func _pm(uid: int, nm: String) -> void:
	var box = _overlay()
	_dim(box, func(): box.queue_free())
	var card = UI.card(Vector2(460, 0))
	box.add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	v.add_child(UI.label("Nhắn riêng cho " + nm, 20, UI.INK, "bold"))
	var e = UI.edit("Nội dung…")
	e.max_length = 120
	v.add_child(e)
	var send = func():
		if e.text.strip_edges() != "":
			Net.send({"t": "pm", "uid": uid, "text": e.text.strip_edges()})
		box.queue_free()
	e.text_submitted.connect(func(_t): send.call())
	var b = UI.button("Gửi", UI.GOLD, 20)
	b.pressed.connect(send)
	v.add_child(b)
	e.grab_focus()

## ---------- giao dịch ----------
func _open_trade() -> void:
	trade_ui = _overlay()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trade_ui.add_child(dim)
	var card = UI.card(Vector2(1040, 560))
	trade_ui.add_child(UI.center(card))
	tr_body = UI.hbox(16)
	card.add_child(tr_body)

func _side(title: String, s: Dictionary, mine: bool) -> VBoxContainer:
	var v = UI.vbox(8)
	v.custom_minimum_size = Vector2(300, 0)
	v.add_child(UI.label(title, 22, UI.INK, "bold"))
	v.add_child(UI.hsep())
	var g = GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for it in s.get("items", []):
		var c = ItemCell.make(it, false, true, false, 66)
		if mine and int(s.get("lock", 0)) == 0:
			var iid = str(it.id)
			ItemCell.clickable(c, func(): tr_items.erase(iid); _push())
		g.add_child(c)
	v.add_child(g)
	v.add_child(UI.hsep())
	v.add_child(UI.label("Vàng: " + UI.fmt(s.get("gold", 0)), 18, UI.INK, "semi"))
	var st = "Đã đồng ý" if int(s.get("ok", 0)) == 1 else ("Đã khóa" if int(s.get("lock", 0)) == 1 else "Đang chọn…")
	v.add_child(UI.label(st, 17, Color("2fa84f") if int(s.get("lock", 0)) == 1 else Color("5a6b8c"), "bold"))
	return v

func _push() -> void:
	var gold = int(tr_gold.text) if tr_gold and tr_gold.text.is_valid_int() else 0
	Net.send({"t": "tr_set", "items": tr_items, "gold": gold})

func _render_trade() -> void:
	if not tr_body or not is_instance_valid(tr_body) or tr.is_empty():
		return
	for c in tr_body.get_children():
		tr_body.remove_child(c)
		c.queue_free()
	var me: Dictionary = tr.get("me", {})
	var th: Dictionary = tr.get("them", {})
	tr_items = []
	for it in me.get("items", []):
		tr_items.append(str(it.id))
	# túi của mình: chọn đồ không khóa
	var left = UI.vbox(8)
	left.custom_minimum_size = Vector2(330, 0)
	left.add_child(UI.label("Túi đồ (chạm để đưa vào)", 18, UI.INK, "bold"))
	left.add_child(UI.hsep())
	var g = GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 5)
	g.add_theme_constant_override("v_separation", 5)
	for it in game.me_data.get("inv", []):
		if tr_items.has(str(it.id)):
			continue
		var c = ItemCell.make(it, false, true, false, 60)
		if int(it.get("lock", 0)) == 1:
			c.modulate = Color(1, 1, 1, 0.45)
		elif int(me.get("lock", 0)) == 0:
			var iid = str(it.id)
			ItemCell.clickable(c, func():
				if tr_items.size() < 10:
					tr_items.append(iid)
					_push())
		g.add_child(c)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(330, 330)
	sc.add_child(g)
	left.add_child(sc)
	left.add_child(UI.label("Đồ khóa (mờ) không giao dịch được.", 13, Color("5a6b8c"), "body"))
	tr_body.add_child(left)
	tr_body.add_child(UI.vsep())
	var mid = _side("Bạn đưa", me, true)
	var gr = UI.hbox(6)
	tr_gold = UI.edit("Vàng")
	tr_gold.text = str(int(me.get("gold", 0)))
	tr_gold.custom_minimum_size = Vector2(150, 46)
	tr_gold.editable = int(me.get("lock", 0)) == 0
	tr_gold.text_submitted.connect(func(_t): _push())
	gr.add_child(tr_gold)
	var sg = UI.button("Đặt vàng", UI.SKY, 16)
	sg.disabled = int(me.get("lock", 0)) == 1
	sg.pressed.connect(_push)
	gr.add_child(sg)
	mid.add_child(gr)
	tr_body.add_child(mid)
	tr_body.add_child(UI.vsep())
	var right = _side("%s đưa" % th.get("n", ""), th, false)
	var btns = UI.vbox(8)
	var lk = UI.button("Hủy khóa" if int(me.get("lock", 0)) == 1 else "Khóa", UI.GOLD, 20)
	lk.disabled = int(me.get("ok", 0)) == 1
	lk.pressed.connect(func(): Net.send({"t": "tr_lock"}))
	btns.add_child(lk)
	var okb = UI.button("Đồng ý giao dịch", UI.GREEN, 20)
	okb.disabled = not (int(me.get("lock", 0)) == 1 and int(th.get("lock", 0)) == 1) or int(me.get("ok", 0)) == 1
	okb.pressed.connect(func(): Net.send({"t": "tr_ok"}))
	btns.add_child(okb)
	var cb = UI.button("Hủy", UI.RED, 18)
	cb.pressed.connect(func(): Net.send({"t": "tr_cancel"}))
	btns.add_child(cb)
	btns.add_child(UI.label("Cả hai cùng Khóa rồi cùng Đồng ý thì mới đổi. Đổi đồ/vàng sẽ mở khóa lại.", 13, Color("5a6b8c"), "body"))
	right.add_child(UI.hsep())
	right.add_child(btns)
	tr_body.add_child(right)
	UI.wrap_all(tr_body, 280)
