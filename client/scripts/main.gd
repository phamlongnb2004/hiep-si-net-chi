extends Node
## Luồng màn hình: đăng nhập → chọn máy chủ → tạo nhân vật (nếu chưa có) → vào game.
## Không có chế độ chơi một mình: mọi thứ đi qua máy chủ.

var assets_version = 0
var ui_layer: CanvasLayer
var screen: Control
var bg: Control
var game: Game
var hud: Hud
var bag: Bag
var npc: Npc
var social: Social
var gm: GmPanel
var menu: Control
var updater: Updater
var update_note = ""
var welcome_seen = false
var app_required = false

class Bg extends Control:
	var t = 0.0
	var clouds: Array = []
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cl = Data.A.get("ui", {}).get("clouds", [])
		for i in 7:
			if cl is Array and cl.size() > 0:
				clouds.append({"c": cl[i % cl.size()], "x": randf(), "y": randf_range(0.04, 0.5), "s": randf_range(0.6, 1.2), "v": randf_range(0.004, 0.012)})
	func _process(dt: float) -> void:
		t += dt
		for c in clouds:
			c.x += c.v * dt
			if c.x > 1.25: c.x = -0.25
		queue_redraw()
	func _draw() -> void:
		var tx = Data.tex(Data.A.get("ui", {}).get("bg", ""))
		var s = size
		if tx:
			var k: float = max(s.x / tx.get_width(), s.y / tx.get_height())
			var w = tx.get_width() * k
			var h = tx.get_height() * k
			draw_texture_rect(tx, Rect2((s.x - w) / 2, (s.y - h) / 2, w, h), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, s), Color("1e3c78"))
		for c in clouds:
			var ct = Data.tex(c.c.u)
			if ct:
				var w2: float = c.c.w * c.s
				var h2: float = c.c.h * c.s
				draw_texture_rect(ct, Rect2(c.x * s.x - w2 / 2, c.y * s.y, w2, h2), false, Color(1, 1, 1, 0.85))

func _ready() -> void:
	get_tree().set_auto_accept_quit(true)
	# kéo tay để cuộn trên điện thoại: khung/nền không bấm được nằm trong vùng cuộn phải cho thao tác đi qua
	get_tree().node_added.connect(_scroll_pass)
	get_tree().set_quit_on_go_back(false)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	bg = Bg.new()
	ui_layer.add_child(bg)
	Net.message.connect(_on_msg)
	Net.status.connect(_on_status)
	updater = Updater.new()
	add_child(updater)
	updater.finished.connect(_on_update)
	updater.check(Net.server)
	if Net.token != "":
		show_servers()
	else:
		show_login()

func _set_screen(c: Control) -> void:
	if screen:
		screen.queue_free()
	screen = c
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.theme = UI.theme()
	ui_layer.add_child(c)

func _logo(v: VBoxContainer) -> void:
	var t = UI.outlined("Hiệp Sĩ Nét Chì", 64, Color("ffd23f"), "title", 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

func _err_label() -> Label:
	var e = UI.label("", 17, Color("d9345a"), "bold")
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return e

## ---------- đăng nhập ----------
func show_login(msg := "") -> void:
	bg.visible = true
	var root = Control.new()
	var v = UI.vbox(16)
	var col = UI.vbox(14)
	_logo(col)
	var card = UI.card(Vector2(480, 0))
	col.add_child(card)
	root.add_child(UI.center(col))
	card.add_child(v)
	var reg = [false]
	var tabs = UI.hbox(8)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(tabs)
	var bl = UI.button("Đăng nhập", UI.GOLD, 20)
	var br = UI.button("Đăng ký", UI.SKY, 20)
	tabs.add_child(bl)
	tabs.add_child(br)
	var u = UI.edit("Tên tài khoản")
	u.text = Net.user
	u.max_length = 16
	v.add_child(u)
	var p = UI.edit("Mật khẩu", true)
	p.max_length = 72
	v.add_child(p)
	var p2 = UI.edit("Nhập lại mật khẩu", true)
	p2.visible = false
	v.add_child(p2)
	var e = _err_label()
	e.text = msg
	v.add_child(e)
	var go = UI.button("Vào game", UI.GOLD, 26)
	go.custom_minimum_size = Vector2(0, 60)
	v.add_child(go)
	var note = UI.label(update_note, 15, Color("5a6b8c"), "semi")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.name = "UpdNote"
	v.add_child(note)
	var ver = UI.outlined("Phiên bản %s · Dữ liệu %d" % [Updater.app_version(), assets_version], 14, Color("cfe3ff"), "semi", 4)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)
	var set_tab = func(r: bool):
		reg[0] = r
		p2.visible = r
		go.text = "Tạo tài khoản" if r else "Vào game"
		bl.add_theme_stylebox_override("normal", UI.box(UI.SKY if r else UI.GOLD))
		br.add_theme_stylebox_override("normal", UI.box(UI.GOLD if r else UI.SKY))
	bl.pressed.connect(func(): set_tab.call(false))
	br.pressed.connect(func(): set_tab.call(true))
	var submit = func():
		e.text = ""
		var uu = u.text.strip_edges()
		if uu.length() < 3:
			e.text = "Tên tài khoản 3–16 ký tự."
			return
		if p.text.length() < 6:
			e.text = "Mật khẩu cần từ 6 ký tự."
			return
		if reg[0] and p.text != p2.text:
			e.text = "Hai mật khẩu không giống nhau."
			return
		go.disabled = true
		go.text = "Đang kết nối…"
		var r = await Net.login(uu, p.text, reg[0])
		go.disabled = false
		go.text = "Tạo tài khoản" if reg[0] else "Vào game"
		if r.code == 200:
			show_servers()
		else:
			e.text = str(r.get("error", "Không đăng nhập được."))
	go.pressed.connect(submit)
	p.text_submitted.connect(func(_t): submit.call())
	p2.text_submitted.connect(func(_t): submit.call())
	_set_screen(root)
	if u.text == "":
		u.grab_focus()
	else:
		p.grab_focus()

## ---------- chọn máy chủ ----------
func show_servers() -> void:
	bg.visible = true
	var root = Control.new()
	var col = UI.vbox(14)
	_logo(col)
	var card = UI.card(Vector2(560, 0))
	col.add_child(card)
	root.add_child(UI.center(col))
	var v = UI.vbox(12)
	card.add_child(v)
	v.add_child(UI.label("Chọn máy chủ", 28, UI.INK, "title"))
	var hi = UI.label("Xin chào " + Net.user, 18, Color("5a6b8c"), "semi")
	v.add_child(hi)
	var list = UI.vbox(10)
	v.add_child(list)
	var e = _err_label()
	v.add_child(e)
	var out = UI.button("Đăng xuất", UI.SKY, 18)
	out.pressed.connect(func(): Net.logout(); show_login())
	v.add_child(out)
	_set_screen(root)
	list.add_child(UI.label("Đang tải danh sách…", 18, UI.INK, "semi"))
	var r = await Net.servers()
	if not is_instance_valid(list):
		return
	for c in list.get_children(): c.queue_free()
	if r.code == 401:
		Net.clear_session()
		show_login("Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.")
		return
	if r.code != 200:
		e.text = str(r.get("error", "Không tải được danh sách máy chủ."))
		var again = UI.button("Thử lại", UI.GOLD, 20)
		again.pressed.connect(show_servers)
		list.add_child(again)
		return
	for s in r.servers:
		var ch = s.get("char")
		var t = "%s  ·  %s  ·  %d người online" % [s.name, s.get("tag", ""), int(s.online)]
		if ch is Dictionary:
			t += "\n%s · %s · Cấp %d" % [ch.name, Data.D.cls.get(ch.cls, {}).get("n", ch.cls), int(ch.lv)]
		else:
			t += "\nChưa có nhân vật"
		var b = UI.button(t, UI.GOLD, 20)
		b.custom_minimum_size = Vector2(0, 84)
		var sid = int(s.id)
		b.pressed.connect(func(): enter(sid))
		list.add_child(b)

## ---------- vào máy chủ ----------
func enter(sid: int) -> void:
	if app_required:
		show_login(update_note)
		return
	welcome_seen = false
	_start_game()
	Net.join(sid)

func _start_game() -> void:
	if game:
		return
	game = Game.new()
	add_child(game)
	hud = Hud.new()
	add_child(hud)
	hud.setup(game)
	var top = CanvasLayer.new()
	top.layer = 15
	add_child(top)
	bag = Bag.new()
	top.add_child(bag)
	bag.setup(game)
	social = Social.new()
	top.add_child(social)
	social.setup(game)
	gm = GmPanel.new()
	top.add_child(gm)
	gm.setup(game)
	hud.social = social
	hud.bind_social()
	npc = Npc.new()
	top.add_child(npc)
	npc.setup(game)
	game.open_npc.connect(func(id): if id != "": npc.open(id))
	if screen:
		screen.queue_free()
		screen = null
	bg.visible = false

func _end_game() -> void:
	for n in [game, hud, bag, npc, menu, social, gm]:
		if n and is_instance_valid(n):
			var p = n.get_parent()
			if p is CanvasLayer and p != ui_layer:
				p.queue_free()
			n.queue_free()
	game = null
	hud = null
	bag = null
	npc = null
	menu = null
	social = null
	gm = null

func open_bag() -> void:
	if bag and not npc.visible:
		bag.open()

func open_gm() -> void:
	if gm and game and game.staff in ["gm", "owner"]:
		gm.open()

func open_menu() -> void:
	if menu and is_instance_valid(menu):
		menu.queue_free()
		menu = null
		return
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var card = UI.card(Vector2(420, 0))
	menu.add_child(UI.center(card))
	var v = UI.vbox(12)
	card.add_child(v)
	v.add_child(UI.label("Tùy chọn", 28, UI.INK, "title"))
	v.add_child(UI.label("Phiên bản %s · Dữ liệu %d · Ping %d ms" % [Updater.app_version(), assets_version, Net.ping_ms], 15, Color("5a6b8c"), "semi"))
	var b1 = UI.button("Tiếp tục chơi", UI.GREEN, 20)
	b1.pressed.connect(open_menu)
	v.add_child(b1)
	# kiểu điều khiển trên điện thoại
	v.add_child(UI.label("Kiểu điều khiển (điện thoại)", 18, UI.INK, "bold"))
	var crow = UI.hbox(8)
	v.add_child(crow)
	for q in [["dpad", "Phím Ngọc Rồng"], ["joy", "Nút tròn"]]:
		var cb = UI.button(q[1], UI.GOLD if str(Data.setting("ctl", "dpad")) == q[0] else UI.SKY, 17)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mk: String = q[0]
		cb.pressed.connect(func():
			Data.set_setting("ctl", mk)
			if hud and is_instance_valid(hud):
				hud._build_controls()
			open_menu(); open_menu())
		crow.add_child(cb)
	v.add_child(UI.label("Phím Ngọc Rồng: ◀ ▶ đi, ▲ nhảy, ↖ ↗ nhảy chéo. Nút tròn: kéo để đi, kéo lên/chéo lên để nhảy; ô kỹ năng vuông.", 13, Color("5a6b8c"), "body"))
	var b2 = UI.button("Đổi máy chủ", UI.SKY, 20)
	b2.pressed.connect(func(): Net.leave(); _end_game(); show_servers())
	v.add_child(b2)
	var b3 = UI.button("Đăng xuất", UI.RED, 20)
	b3.pressed.connect(func(): Net.logout(); _end_game(); show_login())
	v.add_child(b3)
	var b4 = UI.button("Thoát game", UI.GREY, 20)
	b4.pressed.connect(func(): get_tree().quit())
	v.add_child(b4)
	ui_layer.add_child(menu)

## ---------- tạo nhân vật ----------
func show_create() -> void:
	bg.visible = true
	var root = Control.new()
	var card = UI.card(Vector2(1000, 0))
	root.add_child(UI.center(card))
	var v = UI.vbox(14)
	card.add_child(v)
	v.add_child(UI.label("Tạo nhân vật", 30, UI.INK, "title"))
	var row = UI.hbox(14)
	v.add_child(row)
	var pick = ["sword"]
	var cards = {}
	for c in Data.CLS_KEYS:
		var pc = PanelContainer.new()
		pc.custom_minimum_size = Vector2(220, 300)
		pc.add_theme_stylebox_override("panel", UI.box(Color.WHITE, Color("b8c4dc"), 16, 3, false))
		var pv = UI.vbox(4)
		pc.add_child(pv)
		var svc = SubViewportContainer.new()
		svc.custom_minimum_size = Vector2(190, 180)
		svc.stretch = true
		var vp = SubViewport.new()
		vp.transparent_bg = true
		svc.add_child(vp)
		var h = Hero.new()
		h.cls = c
		h.look = 0
		h.show_name = false
		h.position = Vector2(95, 168)
		h.scale = Vector2(1.9, 1.9)
		vp.add_child(h)
		pv.add_child(svc)
		pv.add_child(UI.label(str(Data.D.cls[c].n), 24, UI.INK, "bold"))
		var dl = UI.label(str(Data.D.cls[c].desc), 15, Color("5a6b8c"), "body")
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pv.add_child(dl)
		var cc: String = c
		pc.mouse_filter = Control.MOUSE_FILTER_STOP
		pc.gui_input.connect(func(ev):
			if UI.tapped(ev):
				pick[0] = cc
				for k in cards:
					cards[k].add_theme_stylebox_override("panel", UI.box(Color("fff3c4") if k == cc else Color.WHITE, UI.GOLD.darkened(0.3) if k == cc else Color("b8c4dc"), 16, 4 if k == cc else 3, false)))
		cards[c] = pc
		row.add_child(pc)
	cards.sword.add_theme_stylebox_override("panel", UI.box(Color("fff3c4"), UI.GOLD.darkened(0.3), 16, 4, false))
	var nr = UI.hbox(12)
	v.add_child(nr)
	var name_e = UI.edit("Tên nhân vật (3–16 ký tự)")
	name_e.max_length = 16
	name_e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nr.add_child(name_e)
	var go = UI.button("Bắt đầu", UI.GOLD, 24)
	go.custom_minimum_size = Vector2(200, 56)
	nr.add_child(go)
	var e = _err_label()
	e.name = "CreateErr"
	v.add_child(e)
	go.pressed.connect(func():
		e.text = ""
		Net.send({"t": "create", "name": name_e.text.strip_edges(), "cls": pick[0]}))
	_set_screen(root)

## ---------- tin mạng ----------
func _on_msg(m: Dictionary) -> void:
	match str(m.get("t")):
		"welcome":
			welcome_seen = true
			if m.get("me") == null:
				show_create()
			elif screen:
				screen.queue_free()
				screen = null
				bg.visible = false
		"res":
			if m.get("op") == "create":
				if m.get("ok"):
					if screen:
						screen.queue_free()
						screen = null
					bg.visible = false
				elif screen and screen.find_child("CreateErr", true, false):
					screen.find_child("CreateErr", true, false).text = str(m.get("msg", ""))
		"chat":
			if hud:
				hud.chat(m)

# kéo tay bắt đầu trên một nút nằm trong vùng cuộn: ScrollContainer không nhận được thao tác (nút giữ lại),
# nên tự cuộn vùng đó theo ngón tay; nhả tay ngoài nút thì nút không bị bấm nhầm
var _drag_sc: ScrollContainer = null
var _drag_mode := 0
var _drag_acc := 0.0
func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch and ev.index == 0:
		_drag_mode = 0
		_drag_sc = null
		_drag_acc = 0.0
	elif ev is InputEventScreenDrag and ev.index == 0:
		if _drag_mode == 0:
			_drag_mode = 2
			var h: Node = get_viewport().gui_get_hovered_control()
			while h and not (h is BaseButton):
				h = h.get_parent() if h.get_parent() is Control else null
			if h:
				var p = h.get_parent()
				while p and not (p is ScrollContainer):
					p = p.get_parent()
				if p:
					_drag_sc = p
					_drag_mode = 1
		if _drag_mode == 1 and is_instance_valid(_drag_sc):
			_drag_acc += absf(ev.relative.y)
			if _drag_acc > 8.0:
				_drag_sc.scroll_vertical -= int(round(ev.relative.y))

func _scroll_pass(n: Node) -> void:
	if n is PanelContainer or n is Panel or n is ColorRect:
		_scroll_pass_check.call_deferred(n)

func _scroll_pass_check(n: Node) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	var c := n as Control
	if c.mouse_filter != Control.MOUSE_FILTER_STOP or c.gui_input.get_connections().size() > 0:
		return
	var p = c.get_parent()
	while p:
		if p is ScrollContainer:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()

func _notification(what: int) -> void:
	# nút Quay lại trên Android: mở bảng tùy chọn thay vì thoát ngay
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game:
			if bag and bag.visible: bag.close()
			elif npc and npc.visible: npc.close()
			else: open_menu()
		else:
			get_tree().quit()

func _on_status(s: String, info: String) -> void:
	if s != "closed" or info == "":
		return
	var code = info.split(":")[0]
	var msg = info.substr(info.find(":") + 1)
	_end_game()
	match code:
		"auth":
			show_login("Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.")
		"dup":
			show_login("Tài khoản vừa đăng nhập ở nơi khác.")
		"ban", "maint", "kick":
			show_login(msg)
		"update":
			app_required = true
			show_login("Đã có bản mới. Hãy tải lại ứng dụng tại trang /tai-game rồi cài đè (không mất nhân vật).")
		_:
			show_login(msg if msg != "" else "Đã ngắt kết nối.")

func _on_update(r: Dictionary) -> void:
	if not r.get("ok"):
		return
	if r.get("app_required"):
		app_required = true
		update_note = "Cần cập nhật ứng dụng bản %s để chơi tiếp. Tải tại trang /tai-game." % str(r.get("app_version", ""))
	elif r.get("app_update") is Dictionary and not (r.app_update as Dictionary).is_empty():
		update_note = "Có bản ứng dụng mới %s — tải tại trang /tai-game." % str(r.get("app_version", ""))
	if r.get("assets") is Dictionary and r.assets.get("ok") and r.assets.get("restart"):
		update_note += ("\n" if update_note != "" else "") + "Đã tải dữ liệu mới, mở lại game để dùng."
	if screen and screen.find_child("UpdNote", true, false):
		screen.find_child("UpdNote", true, false).text = update_note
