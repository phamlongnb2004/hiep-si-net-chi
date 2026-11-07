extends CanvasLayer
class_name Hud
## Giao diện trong trận: máu/kinh nghiệm, vàng, bản đồ nhỏ, nút đánh, 6 kỹ năng, bình máu, nhảy, túi đồ, trò chuyện, nhật ký.

var game: Game
var root: Control
var hp_bar: Control
var info: Label
var gold_l: Label
var stone_l: Label
var map_l: Label
var net_l: Label
var logbox: VBoxContainer
var skills: Array = []
var pot_l: Label
var talk_btn: Button
var joy: Joystick
var mini: Control
var chat_edit: LineEdit
var banner: Label
var overlay: Control
var overlay_l: Label
var touch = false
var social
var fr_b: TextureButton
var gm_b: Button
var ann_l: Label
var ev_l: Label
var fr_badge: Label
var potb
var pt_badge: Label
var khu_b: Button
var khu_pop: Control

class SkillBtn extends Control:
	var tex: Texture2D
	var cd = 0.0
	var mx = 1.0
	var locked = false
	var noki = false
	var key = ""
	var big = false
	signal pressed
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			pressed.emit()
			accept_event()
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var r = size.x / 2
		var c = size / 2
		draw_circle(c, r, Color(0.09, 0.13, 0.29, 0.55))
		if tex:
			draw_texture_rect(tex, Rect2(c - Vector2(r, r) * 0.92, Vector2(r, r) * 1.84), false, Color(1, 1, 1, 0.45) if locked else (Color(0.55, 0.7, 1.0, 0.6) if noki else Color.WHITE))
		if cd > 0.05 and mx > 0:
			var pts = PackedVector2Array([c])
			var a0 = -PI / 2
			var n = 24
			for i in n + 1:
				var a = a0 + TAU * (cd / mx) * i / n
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, Color(0.05, 0.07, 0.15, 0.62))
			var f: Font = Data.fonts.get("bold")
			var s = str(int(ceil(cd)))
			var w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string_outline(f, c + Vector2(-w / 2, 8), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, UI.INK)
			draw_string(f, c + Vector2(-w / 2, 8), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_arc(c, r - 1.5, 0, TAU, 40, Color("ffd23f") if big else Color.WHITE, 3)
		if locked:
			var lk = Data.tex(Data.A.hud.ui.get("lock", ""))
			if lk:
				draw_texture_rect(lk, Rect2(c - Vector2(14, 14), Vector2(28, 28)), false)
		if key != "":
			var f2: Font = Data.fonts.get("bold")
			draw_string_outline(f2, Vector2(4, 16), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, UI.INK)
			draw_string(f2, Vector2(4, 16), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

class Bars extends Control:
	var hp = 1.0
	var hpm = 1.0
	var ki = 0.0
	var kim = 1.0
	var ex = 0.0
	var exn = 1.0
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var w = size.x
		draw_rect(Rect2(0, 0, w, 22), UI.INK)
		draw_rect(Rect2(3, 3, (w - 6) * clampf(hp / hpm, 0, 1), 16), Color("e8546f"))
		draw_rect(Rect2(3, 3, (w - 6) * clampf(hp / hpm, 0, 1), 6), Color(1, 1, 1, 0.25))
		# KI
		draw_rect(Rect2(0, 25, w, 15), UI.INK)
		draw_rect(Rect2(2, 27, (w - 4) * clampf(ki / kim, 0, 1), 11), Color("38c6ff"))
		draw_rect(Rect2(0, 43, w, 10), UI.INK)
		draw_rect(Rect2(2, 45, (w - 4) * clampf(ex / exn, 0, 1), 6), Color("ffd23f"))
		var f: Font = Data.fonts.get("bold")
		var ks = "KI %d / %d" % [int(ki), int(kim)]
		var kw = f.get_string_size(ks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string_outline(f, Vector2(w / 2 - kw / 2, 37), ks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, UI.INK)
		draw_string(f, Vector2(w / 2 - kw / 2, 37), ks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		var s = "%d / %d" % [int(hp), int(hpm)]
		var sw = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string_outline(f, Vector2(w / 2 - sw / 2, 17), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, UI.INK)
		draw_string(f, Vector2(w / 2 - sw / 2, 17), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

class MiniMap extends Control:
	var game: Game
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if game == null or game.M.is_empty():
			return
		var M = game.M
		var sx = size.x / float(M.w)
		var sy = size.y / 720.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.13, 0.29, 0.6))
		var pts = PackedVector2Array([Vector2(0, size.y)])
		for t in M.terr:
			pts.append(Vector2(t[0] * sx, t[1] * sy))
		pts.append(Vector2(size.x, size.y))
		draw_colored_polygon(pts, Color.html(str(M.get("base", "#5c9e3f"))))
		for z in M.safes:
			draw_rect(Rect2(z.x * sx, 2, z.w * sx, 4), Color(1, 0.88, 0.43, 0.9))
		for p in M.portals:
			draw_circle(Vector2(p.x * sx, p.y * sy - 6), 3.5, Color("7fc8ff"))
		for m in game.mons.values():
			if not m.dead():
				draw_circle(Vector2(m.position.x * sx, m.position.y * sy - 3), 2.2 if not m._info.get("boss", false) else 4.0, Color("d9345a"))
		for h in game.heroes.values():
			draw_circle(Vector2(h.position.x * sx, h.position.y * sy - 4), 3, Color("8fb4ff"))
		draw_circle(Vector2(game.me.position.x * sx, game.me.position.y * sy - 4), 4, Color("ffd23f"))
		draw_rect(Rect2(Vector2.ZERO, size), UI.INK, false, 2)

func setup(g: Game) -> void:
	game = g
	layer = 10
	touch = DisplayServer.is_touchscreen_available() or OS.get_name() == "Android" or OS.get_environment("HSNC_TOUCH") == "1"
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	var H: Dictionary = Data.A.get("hud", {})
	# ô thông tin trái trên
	var tl = UI.vbox(4)
	tl.position = Vector2(16, 12)
	root.add_child(tl)
	info = UI.outlined("", 20)
	tl.add_child(info)
	var bars = Bars.new()
	bars.custom_minimum_size = Vector2(300, 53)
	hp_bar = bars
	tl.add_child(bars)
	var res = UI.hbox(8)
	tl.add_child(res)
	res.add_child(_icon(H.ui.get("gold", ""), 26))
	gold_l = UI.outlined("0", 18)
	res.add_child(gold_l)
	res.add_child(_icon(H.ui.get("stone", ""), 24))
	stone_l = UI.outlined("0", 18)
	res.add_child(stone_l)
	logbox = UI.vbox(2)
	logbox.position = Vector2(16, 136)
	logbox.custom_minimum_size = Vector2(380, 0)
	logbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(logbox)
	# phải trên: bản đồ nhỏ, tên bản đồ, mạng
	var tr = UI.vbox(4)
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-236, 12)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(tr)
	map_l = UI.outlined("", 18)
	map_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	map_l.custom_minimum_size = Vector2(220, 0)
	tr.add_child(map_l)
	# nút đổi khu (giống Ngọc Rồng Online)
	khu_b = UI.button("Khu 1", UI.SKY, 15)
	khu_b.custom_minimum_size = Vector2(0, 34)
	khu_b.size_flags_horizontal = Control.SIZE_SHRINK_END
	khu_b.tooltip_text = "Đổi khu"
	khu_b.pressed.connect(func(): Net.send({"t": "khu"}))
	tr.add_child(khu_b)
	mini = MiniMap.new()
	mini.game = g
	mini.custom_minimum_size = Vector2(220, 70)
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(mini)
	net_l = UI.outlined("", 14, Color("cfe3ff"), "semi", 4)
	net_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(net_l)
	var tbtn = UI.hbox(8)
	tbtn.alignment = BoxContainer.ALIGNMENT_END
	tr.add_child(tbtn)
	var bag_b = UI.icon_button(Data.tex(H.ui.get("bag", "")), 58)
	bag_b.pressed.connect(func(): g.get_parent().open_bag())
	tbtn.add_child(bag_b)
	pt_badge = UI.outlined("", 14, Color("ffd23f"), "bold", 5)
	pt_badge.position = Vector2(34, -4)
	bag_b.add_child(pt_badge)
	var chat_b = UI.icon_button(Data.tex(H.ui.get("chat", "")), 58)
	chat_b.pressed.connect(_toggle_chat)
	tbtn.add_child(chat_b)
	fr_b = UI.icon_button(Data.tex(H.ui.get("talk", "")), 58)
	fr_b.tooltip_text = "Bạn bè"
	tbtn.add_child(fr_b)
	fr_badge = UI.outlined("", 14, Color("ff5d7d"), "bold", 5)
	fr_badge.position = Vector2(38, -4)
	fr_b.add_child(fr_badge)
	var menu_b = UI.icon_button(Data.tex(H.ui.get("menu", "")), 58)
	menu_b.pressed.connect(func(): g.get_parent().open_menu())
	tbtn.add_child(menu_b)
	# nút GM: chỉ hiện với tài khoản quản trị (máy chủ vẫn kiểm quyền từng lệnh)
	gm_b = UI.button("GM", UI.RED, 18)
	gm_b.custom_minimum_size = Vector2(58, 58)
	gm_b.visible = false
	gm_b.pressed.connect(func(): g.get_parent().open_gm())
	tbtn.add_child(gm_b)
	ev_l = UI.outlined("", 15, Color("ffd23f"), "bold", 5)
	ev_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(ev_l)
	# thông báo của quản trị: dải chữ ở giữa phía trên
	ann_l = UI.outlined("", 22, Color("ffe08a"), "bold", 7)
	ann_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ann_l.position = Vector2(-380, 64)
	ann_l.custom_minimum_size = Vector2(760, 0)
	ann_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ann_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ann_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ann_l.modulate.a = 0
	root.add_child(ann_l)
	g.announce.connect(show_ann)
	g.cfg_changed.connect(_cfg)
	# cụm nút phải dưới: nút đánh lớn ở góc, 6 kỹ năng xếp hình cung quanh nút đánh
	var br = Control.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.position = Vector2(-460, -350)
	br.size = Vector2(460, 350)
	br.size = Vector2(450, 320)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(br)
	var ac = Vector2(380, 270)
	var atk = SkillBtn.new()
	atk.tex = Data.tex(H.ui.get("atk", ""))
	atk.big = true
	atk.size = Vector2(136, 136)
	atk.position = ac - atk.size / 2
	atk.key = "" if touch else "J"
	atk.gui_input.connect(func(ev):
		if ev is InputEventScreenTouch or (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
			g.atk_held = ev.pressed)
	br.add_child(atk)
	for i in 6:
		var b = SkillBtn.new()
		b.size = Vector2(80, 80)
		var ang = deg_to_rad([182, 226, 270, 197, 233, 268][i])
		b.position = ac + Vector2(cos(ang), sin(ang)) * (150.0 if i < 3 else 246.0) - b.size / 2
		b.key = "" if touch else str(i + 1)
		var ii = i
		b.pressed.connect(func(): g.do_skill(ii))
		br.add_child(b)
		skills.append(b)
	potb = SkillBtn.new()
	potb.mx = 3.0
	potb.tex = Data.tex(H.ui.get("pot", ""))
	potb.size = Vector2(72, 72)
	potb.position = Vector2(-10, 250)
	potb.key = "" if touch else "Q"
	potb.pressed.connect(g.do_pot)
	br.add_child(potb)
	pot_l = UI.outlined("0", 16)
	pot_l.position = Vector2(44, 304)
	br.add_child(pot_l)
	# nút nhảy và cần điều khiển (cảm ứng)
	if touch:
		var jb = SkillBtn.new()
		jb.tex = Data.tex(H.ui.get("roll", ""))
		jb.size = Vector2(88, 88)
		jb.position = Vector2(-120, 230)
		jb.pressed.connect(g.jump)
		br.add_child(jb)
		joy = Joystick.new()
		joy.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		joy.position = Vector2(20, -280)
		joy.size = Vector2(280, 260)
		joy.jump.connect(g.jump)
		root.add_child(joy)
	else:
		var hint = UI.outlined("A/D: đi · W/Space: nhảy · J: đánh · 1-6: kỹ năng · Q: bình máu · E: nói chuyện · B: túi đồ", 14, Color.WHITE, "semi", 4)
		hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		hint.position = Vector2(16, -30)
		root.add_child(hint)
	talk_btn = UI.button("Nói chuyện", UI.GREEN, 22)
	talk_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	talk_btn.position = Vector2(-90, -150)
	talk_btn.custom_minimum_size = Vector2(180, 56)
	talk_btn.visible = false
	talk_btn.pressed.connect(func(): g.talk())
	root.add_child(talk_btn)
	chat_edit = UI.edit("Nhắn cùng bản đồ · gõ /all trước để nhắn cả máy chủ (5.000 vàng)")
	chat_edit.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chat_edit.position = Vector2(-260, 80)
	chat_edit.custom_minimum_size = Vector2(520, 50)
	chat_edit.visible = false
	chat_edit.max_length = 120
	chat_edit.text_submitted.connect(_send_chat)
	root.add_child(chat_edit)
	banner = UI.outlined("", 44, Color("ffd23f"), "title", 10)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-400, 150)
	banner.custom_minimum_size = Vector2(800, 0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0
	root.add_child(banner)
	# lớp phủ mất kết nối
	overlay = ColorRect.new()
	overlay.color = Color(0.03, 0.05, 0.13, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)
	overlay_l = UI.outlined("", 28, Color.WHITE, "bold", 8)
	overlay_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(UI.center(overlay_l))
	g.me_changed.connect(refresh)
	g.log_line.connect(add_log)
	g.npc_near.connect(func(id):
		talk_btn.visible = id != ""
		talk_btn.text = "Vào khu trùm" if str(id).begins_with("gate:") else "Nói chuyện")
	g.map_changed.connect(func(n): map_l.text = n; khu_b.text = "Khu %d  ▾" % g.khu; show_banner("%s · Khu %d" % [n, g.khu]); if khu_pop and is_instance_valid(khu_pop): khu_pop.queue_free())
	g.khu_list.connect(open_khu)
	Net.status.connect(_net)
	root.visible = false
	g.map_changed.connect(func(_n): root.visible = true)
	_net(Net.state, "")

func _icon(rel, sz: int) -> TextureRect:
	var t = TextureRect.new()
	t.texture = Data.tex(rel)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(sz, sz)
	return t

func refresh() -> void:
	var d = game.me_data
	if d.is_empty():
		return
	var c = str(d.get("cls", "sword"))
	info.text = "%s  ·  Cấp %d  ·  %s" % [d.get("name", ""), int(d.get("lv", 1)), Data.D.cls[c].n]
	var b: Bars = hp_bar
	b.hp = float(d.get("hp", 1))
	b.hpm = max(1.0, float(d.get("maxHp", 1)))
	b.ki = float(d.get("ki", 0))
	b.kim = max(1.0, float(d.get("maxKi", 1)))
	b.ex = float(d.get("exp", 0))
	var pf = int(d.get("ptFree", 0))
	pt_badge.text = ("+%d" % pf) if pf > 0 else ""
	b.exn = max(1.0, float(d.get("need", 1)))
	gold_l.text = UI.fmt(d.get("gold", 0))
	stone_l.text = str(int(d.get("stones", 0)))
	pot_l.text = "%d" % int(d.get("pots", 0))
	var icons: Array = Data.A.hud.skills.get(c, [])
	var sk: Array = d.get("sk", [])
	for i in 6:
		var s: SkillBtn = skills[i]
		s.tex = Data.tex(icons[i]) if i < icons.size() else null
		s.locked = i >= sk.size() or int(sk[i]) == 0
		s.mx = float(Data.D.skills[c][i].cd)
		var kc: Array = d.get("kc", [])
		s.noki = i < kc.size() and float(d.get("ki", 0)) < float(kc[i])

func _process(_dt: float) -> void:
	if game == null:
		return
	for i in 6:
		skills[i].cd = game.cds[i]
	potb.cd = game.pot_cd
	if game.joy != null and joy:
		game.joy = joy.value
	net_l.text = ("Ping %d ms" % Net.ping_ms) if Net.online() else ""
	if game.me.dead and Net.online():
		overlay.visible = true
		overlay_l.text = "Bạn đã gục ngã. Đang hồi sinh ở điểm an toàn…"
	elif Net.online() and overlay.visible:
		overlay.visible = false

func add_log(text: String, col: Color) -> void:
	var l = UI.outlined(text, 15, col, "semi", 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(380, 0)
	logbox.add_child(l)
	while logbox.get_child_count() > 6:
		logbox.get_child(0).free()
	var tw = l.create_tween()
	tw.tween_interval(6)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)

func show_banner(s: String) -> void:
	banner.text = s
	var tw = banner.create_tween()
	banner.modulate.a = 0
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)

func _toggle_chat() -> void:
	chat_edit.visible = not chat_edit.visible
	if chat_edit.visible:
		chat_edit.grab_focus()

func _send_chat(t: String) -> void:
	t = t.strip_edges()
	if t != "":
		# "/all ..." = nhắn cả máy chủ (tốn vàng); còn lại nhắn những người cùng bản đồ (miễn phí)
		var all = t.begins_with("/all ")
		if all:
			t = t.substr(5).strip_edges()
		if t != "":
			Net.send({"t": "chat", "text": t, "all": all})
	chat_edit.text = ""
	chat_edit.visible = false

func chat(m: Dictionary) -> void:
	var pre = ""
	var col = Color("ffffff")
	if m.get("all"):
		pre = "[Thế giới] "
		col = Color("ffd23f")
	elif m.get("pm"):
		pre = "[Riêng → %s] " % m.get("to", "")
		col = Color("ff9ee0")
	add_log("%s%s: %s" % [pre, m.get("n", ""), m.get("text", "")], col)

func _net(s: String, inf: String) -> void:
	overlay.visible = s != "online"
	match s:
		"connecting": overlay_l.text = "Đang kết nối máy chủ…"
		"reconnecting": overlay_l.text = inf if inf != "" else "Mất kết nối. Đang kết nối lại…"
		"closed": overlay_l.text = "Đã ngắt kết nối."

func bind_social() -> void:
	fr_b.pressed.connect(func(): social.open_friends())
	social.badge.connect(func(n): fr_badge.text = ("%d" % n) if n > 0 else "")

func show_ann(t: String) -> void:
	if t == "":
		return
	# phông chữ không có hình 📢: tin đã có biểu tượng riêng (⏰ ⚔) thì để nguyên, còn lại ghi "Thông báo:"
	var s = t if t.begins_with("⏰") or t.begins_with("⚔") else "Thông báo: " + t
	ann_l.text = s
	add_log(s, Color("ffe08a"))
	var tw = ann_l.create_tween()
	ann_l.modulate.a = 0
	tw.tween_property(ann_l, "modulate:a", 1.0, 0.3)
	tw.tween_interval(12)
	tw.tween_property(ann_l, "modulate:a", 0.0, 1.0)

func _cfg() -> void:
	var e = Data.cfg.get("ev")
	if e is Dictionary:
		var t = Time.get_datetime_dict_from_unix_time(int(float(e.until) / 1000.0) + 7 * 3600)
		ev_l.text = "🎉 %s: x%s KN · x%s vàng · x%s rơi đồ (đến %02d:%02d)" % [e.name, str(e.exp), str(e.gold), str(e.drop), t.hour, t.minute]
	else:
		ev_l.text = ""
	gm_b.visible = game.staff in ["gm", "owner"]


# bảng chọn khu: số người mỗi khu, khu đầy không vào được
func open_khu(m: Dictionary) -> void:
	if khu_pop and is_instance_valid(khu_pop):
		khu_pop.queue_free()
	khu_pop = Control.new()
	khu_pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	khu_pop.theme = UI.theme()
	root.add_child(khu_pop)
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: khu_pop.queue_free())
	khu_pop.add_child(dim)
	var card = UI.card(Vector2(560, 0))
	khu_pop.add_child(UI.center(card))
	var v = UI.vbox(12)
	card.add_child(v)
	var head = UI.hbox(10)
	v.add_child(head)
	var t = UI.label("Chọn khu · %s" % str(game.M.get("name", "")), 26, UI.INK, "title")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(func(): khu_pop.queue_free())
	head.add_child(x)
	var mx = int(m.get("max", 15))
	v.add_child(UI.label("Mỗi khu tối đa %d người. Mỗi khu có quái và đồ rơi riêng." % mx, 16, Color("5a6b8c"), "semi"))
	var g = GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	var cur = int(m.get("cur", 1))
	for e in m.get("list", []):
		var k = int(e[0])
		var n = int(e[1])
		var col = UI.GOLD if k == cur else (UI.RED if n >= mx else (Color("ffd98a") if n >= mx * 0.7 else UI.GREEN))
		var b = UI.button("Khu %d\n%d/%d" % [k, n, mx], col, 17)
		b.custom_minimum_size = Vector2(96, 70)
		b.disabled = k == cur or n >= mx
		b.pressed.connect(func(): Net.send({"t": "khu", "k": k}); khu_pop.queue_free())
		g.add_child(b)
	v.add_child(UI.label("Đang ở khu %d." % cur, 16, UI.INK, "semi"))
