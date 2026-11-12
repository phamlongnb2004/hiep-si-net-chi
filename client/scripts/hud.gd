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
var talk_btn: Button
var pick_btn: Button
var toast_l: Control
var joy   # DPad hoặc Joystick
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
var ann_b: AnnBanner
var cele_b: AnnBanner
var ev_l: Label
var fr_badge: Label
var potb
var kpotb
var kpot_l: Label
var ctl: Control           # lớp chứa các nút điều khiển (dựng lại khi đổi kiểu)
var auto_b: TextureButton
var auto_on_l: Label
var world_log: Array = []   # [tên, nội dung] chat thế giới gần đây
var wt: Control
var rollb
var auto_pop: Control
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
	var square = false        # ô vuông (kiểu nút tròn: ô kỹ năng xếp như Ngọc Rồng)
	var tint := Color.WHITE
	var count = -1            # số lượng (bình) hiện ở góc dưới
	signal pressed
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(ev: InputEvent) -> void:
		if UI.tapped(ev):
			pressed.emit()
			accept_event()
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var r = size.x / 2
		var c = size / 2
		var rr = Rect2(Vector2(3, 3), size - Vector2(6, 6))
		if square:
			draw_style_box(UI.box(Color(0.09, 0.13, 0.29, 0.6), Color(0, 0, 0, 0), 12, 0, false), rr)
		else:
			draw_circle(c, r, Color(0.09, 0.13, 0.29, 0.55))
		# chiêu chưa học: chỉ hiện ô trống
		if tex and not locked:
			var ir = Rect2(c - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6) if square else Rect2(c - Vector2(r, r) * 0.92, Vector2(r, r) * 1.84)
			draw_texture_rect(tex, ir, false, (Color(0.55, 0.7, 1.0, 0.6) if noki else Color.WHITE) * tint)
		if cd > 0.05 and mx > 0 and not locked:
			if square:
				draw_rect(Rect2(rr.position + Vector2(0, rr.size.y * (1.0 - cd / mx)), Vector2(rr.size.x, rr.size.y * cd / mx)), Color(0.05, 0.07, 0.15, 0.62))
			else:
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
		var edge = Color("ffd23f") if big else (Color(1, 1, 1, 0.45) if locked else Color.WHITE)
		if square:
			draw_style_box(UI.box(Color(0, 0, 0, 0), edge, 12, 3, false), rr)
		else:
			draw_arc(c, r - 1.5, 0, TAU, 40, edge, 3)
		if count >= 0:
			var f3: Font = Data.fonts.get("bold")
			var cs = str(count)
			var cw = f3.get_string_size(cs, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string_outline(f3, Vector2(size.x - cw - 4, size.y - 4), cs, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, UI.INK)
			draw_string(f3, Vector2(size.x - cw - 4, size.y - 4), cs, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
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
		for pl in M.get("plats", []):
			draw_line(Vector2(pl[0] * sx, pl[1] * sy), Vector2(pl[2] * sx, pl[3] * sy), Color.html(str(M.get("base", "#5c9e3f"))).lightened(0.25), 2.5)
		for r in M.get("ropes", []):
			draw_line(Vector2(r[0] * sx, r[1] * sy), Vector2(r[0] * sx, r[2] * sy), Color(0.85, 0.7, 0.45, 0.9), 1.5)
		for w in M.get("water", []) + M.get("lava", []):
			draw_rect(Rect2(w[0] * sx, w[2] * sy, (w[1] - w[0]) * sx, 3), Color(1, 0.5, 0.2, 0.9) if M.get("lava", []).has(w) else Color(0.4, 0.75, 1, 0.9))
		for z in M.safes:
			draw_rect(Rect2(z.x * sx, 2, z.w * sx, 4), Color(1, 0.88, 0.43, 0.9))
		for p in M.portals:
			draw_circle(Vector2(p.x * sx, p.y * sy - 6), 3.5, Color("7fc8ff"))
		var bosses = []
		for m in game.mons.values():
			if not m.dead():
				if m._info.get("boss", false):
					bosses.append(m)
				else:
					draw_circle(Vector2(m.position.x * sx, m.position.y * sy - 3), 2.2, Color("d9345a"))
		for h in game.heroes.values():
			draw_circle(Vector2(h.position.x * sx, h.position.y * sy - 4), 3, Color("8fb4ff"))
		draw_circle(Vector2(game.me.position.x * sx, game.me.position.y * sy - 4), 4, Color("ffd23f"))
		# trùm: ngôi sao vàng viền đen, tâm đỏ, vòng sáng nhấp nháy (vẽ trên cùng cho dễ thấy)
		var tt = Time.get_ticks_msec() / 1000.0
		for m in bosses:
			var c = Vector2(clampf(m.position.x * sx, 9, size.x - 9), clampf(m.position.y * sy - 8, 9, size.y - 9))
			var u = fmod(tt * 1.2, 1.0)
			draw_arc(c, 6 + u * 10, 0, TAU, 20, Color(1, 0.3, 0.3, 0.9 * (1 - u)), 2)
			var sp_ = PackedVector2Array()
			for i in 10:
				var an = -PI / 2 + TAU * i / 10.0
				sp_.append(c + Vector2(cos(an), sin(an)) * (8.0 if i % 2 == 0 else 3.6))
			draw_colored_polygon(sp_, Color("ffd23f"))
			var o = sp_.duplicate()
			o.append(sp_[0])
			draw_polyline(o, UI.INK, 1.5)
			draw_circle(c, 2.2, Color("e0303a"))
		draw_rect(Rect2(Vector2.ZERO, size), UI.INK, false, 2)

func setup(g: Game) -> void:
	game = g
	layer = 10
	touch = Data.is_touch()
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
	# nút AUTO chỉ có hình (không nền trắng); đang bật thì có chữ ON xanh ở góc
	auto_b = UI.icon_button(Data.tex(H.ui.get("auto", "")), 62)
	auto_on_l = UI.outlined("ON", 13, Color("7dff8a"), "bold", 5)
	auto_on_l.position = Vector2(36, 40)
	auto_on_l.visible = false
	auto_b.add_child(auto_on_l)
	auto_b.tooltip_text = "Tự động đánh quái"
	auto_b.pressed.connect(open_auto)
	tbtn.add_child(auto_b)
	var pet_b = UI.icon_button(Data.tex(Data.A.get("egg", {}).get("fire", {}).get("icon", "")), 58)
	pet_b.tooltip_text = "Pet"
	pet_b.pressed.connect(func(): g.open_npc.emit("pets"))
	tbtn.add_child(pet_b)
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
	ann_l = UI.outlined("", 22, Color("ffe08a"), "bold", 7)   # giữ lại cho chỗ khác dùng (không hiện)
	ann_l.visible = false
	root.add_child(ann_l)
	ann_b = AnnBanner.new()
	ann_b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ann_b.position = Vector2(-470, 72)
	ann_b.size = Vector2(940, 80)
	ann_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# băng chúc mừng đập đồ lên cao: ngay dưới băng thông báo
	cele_b = AnnBanner.new()
	cele_b.cele = true
	cele_b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cele_b.position = Vector2(-470, 150)
	cele_b.size = Vector2(940, 80)
	cele_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cele_b.visible = false
	ann_b.visible = false
	root.add_child(ann_b)
	root.add_child(cele_b)
	g.announce.connect(show_ann)
	g.celebrate.connect(show_cele)
	g.cfg_changed.connect(_cfg)
	# cụm nút điều khiển (đánh, kỹ năng, bình, lướt, di chuyển): dựng lại khi đổi kiểu điều khiển trong Tùy chọn
	_build_controls()
	talk_btn = UI.button("Nói chuyện", UI.GREEN, 22)
	talk_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	talk_btn.position = Vector2(-90, -150)
	talk_btn.custom_minimum_size = Vector2(180, 56)
	talk_btn.visible = false
	talk_btn.pressed.connect(func(): g.talk())
	root.add_child(talk_btn)
	# nút Nhặt nhỏ ở giữa dưới màn hình khi đang chọn đồ rơi
	pick_btn = UI.button("Nhặt", UI.GREEN, 20)
	pick_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_place(pick_btn, Vector2(-60, -84), Vector2(120, 50))
	pick_btn.visible = false
	pick_btn.pressed.connect(func(): if g.sel_kind == "drop": g.go_pick(g.sel))
	root.add_child(pick_btn)
	g.sel_changed.connect(func(): pick_btn.visible = g.sel_kind == "drop")
	g.toast.connect(_toast)
	g.bag_full.connect(show_full)
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
	potb.count = Data.pot_total(d, false)
	kpotb.count = Data.pot_total(d, true)
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
	kpotb.cd = game.kpot_cd
	if rollb:
		rollb.cd = game.roll_cd
	if auto_b and auto_b.get_meta("on", false) != game.auto_on:
		_auto_style()
	if game.joy != null and joy:
		game.joy = joy.value
	net_l.text = ("Ping %d ms" % Net.ping_ms) if Net.online() else ""
	_dead_ui()
	if Net.online() and overlay.visible:
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
	if m.get("pet"):
		# pet nói với chủ (sau lệnh ditheo/tancong/baove/venha): dòng xanh lá + bong bóng trên đầu pet
		add_log("[Thú cưng] %s: %s" % [m.get("n", ""), m.get("text", "")], Color("7dffb0"))
		var pt = game.pets.get(game.my_id)
		if pt and is_instance_valid(pt):
			pt.say = str(m.get("text", ""))
			pt.say_t = 5.0
		return
	if m.get("all"):
		pre = "[Thế giới] "
		col = Color("ffd23f")
	elif m.get("pm"):
		pre = "[Riêng → %s] " % m.get("to", "")
		col = Color("ff9ee0")
	add_log("%s%s: %s" % [pre, m.get("n", ""), m.get("text", "")], col)
	if m.get("all"):
		# chat thế giới: hiện ở góc trên giữa 5 giây, bấm vào xem các tin gần đây
		world_log.append([str(m.get("n", "")), str(m.get("text", ""))])
		while world_log.size() > 40:
			world_log.pop_front()
		_world_toast(str(m.get("n", "")), str(m.get("text", "")))
	elif not m.get("pm"):
		# chat trong bản đồ: bong bóng trên đầu người nói
		var w = game._who(int(m.get("id", 0)))
		if w:
			w.say = str(m.get("text", ""))
			w.say_t = 5.0

func _net(s: String, inf: String) -> void:
	overlay.visible = s != "online"
	match s:
		"connecting": overlay_l.text = "Đang kết nối máy chủ…"
		"reconnecting": overlay_l.text = inf if inf != "" else "Mất kết nối. Đang kết nối lại…"
		"closed": overlay_l.text = "Đã ngắt kết nối."

func bind_social() -> void:
	fr_b.pressed.connect(func(): social.open_friends())
	social.badge.connect(func(n): fr_badge.text = ("%d" % n) if n > 0 else "")

func show_cele(m: Dictionary) -> void:
	var s = "Chúc mừng %s đã cường hóa %s lên +%d!" % [str(m.get("n", "")), str(m.get("item", "trang bị")), int(m.get("up", 0))]
	cele_b.show_msg(s, "cele")
	add_log("🎉 " + s, Color("ff9be0"))

func show_ann(t: String) -> void:
	if t == "":
		return
	# biểu tượng động theo loại tin: ⏰ sắp mở khu trùm, ⚔ khu trùm mở / kết liễu trùm, còn lại tù và (thông báo chung)
	var kind = "horn"
	var s = t
	if t.begins_with("⏰"):
		kind = "hourglass"
	elif t.begins_with("⚔"):
		kind = "skull" if t.find("kết liễu") >= 0 else "gate"
	if kind != "horn":
		s = t.substr(1).strip_edges()
	ann_b.show_msg(s, kind)
	add_log(s, Color("ffe08a"))

## băng thông báo giữa trên màn hình: biểu tượng vẽ tay 8 khung chạy lặp, nảy vào, sáng nhấp nháy, mờ dần sau 12 giây
class AnnBanner extends Control:
	var text = ""
	var kind = "horn"
	var cele = false        # băng chúc mừng (đập đồ lên cao): nền tím hồng, ngôi sao xoay
	var t = 0.0
	var life = 0.0
	const DUR := 12.0
	const SPD := 80.0       # chữ dài chạy ngang (px/giây)
	const GAP := 90.0
	var clip: Control
	var lab: Label
	var full_w = 0.0
	func _ready() -> void:
		clip = Control.new()
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)
		lab = Label.new()
		lab.add_theme_font_override("font", Data.fonts.get("bold"))
		lab.add_theme_font_size_override("font_size", 22)
		lab.add_theme_color_override("font_color", Color("ffd7f4") if cele else Color(1, 0.88, 0.54))
		lab.add_theme_color_override("font_outline_color", UI.INK)
		lab.add_theme_constant_override("outline_size", 7)
		clip.add_child(lab)
	func show_msg(s: String, k: String) -> void:
		text = s
		kind = k
		t = 0.0
		var f: Font = Data.fonts.get("bold")
		full_w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var over = full_w > size.x - 150
		# chữ dài: chạy ngang trong khung, đủ thời gian chạy hết ít nhất 2 vòng
		life = maxf(DUR, ((full_w + GAP) / SPD) * 2.0 + 3.0) if over else DUR
		lab.text = (text + "     ✦     " + text) if over else text
		visible = true
	func _geo() -> Array:
		var tw = minf(full_w, size.x - 150)
		var ih = 76.0
		var bw = tw + ih + 46
		var x0 = size.x / 2 - bw / 2
		return [tw, ih, bw, x0, 6.0]
	func _process(dt: float) -> void:
		if life <= 0:
			visible = false
			return
		t += dt
		life -= dt
		var G = _geo()
		var al = clampf(t / 0.25, 0, 1) * clampf(life / 0.8, 0, 1)
		clip.position = Vector2(G[3] + G[1] + 22, G[4] + 14)
		clip.size = Vector2(G[0], 38)
		clip.modulate.a = al
		var off = 0.0
		if full_w > G[0] + 1:
			var f: Font = Data.fonts.get("bold")
			var period = f.get_string_size(text + "     ✦     ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			off = -fmod(maxf(0.0, t - 1.2) * SPD, period)
		lab.position = Vector2(off, 0)
		queue_redraw()
	func _draw() -> void:
		var f: Font = Data.fonts.get("bold")
		var fs = 22
		var tw = minf(full_w, size.x - 150)
		var al = clampf(t / 0.25, 0, 1) * clampf(life / 0.8, 0, 1)
		var cx = size.x / 2
		var ih = 76.0
		var bw = tw + ih + 46
		var x0 = cx - bw / 2
		var y0 = 6.0
		# nền băng: tối trong suốt, viền vàng, quét sáng chạy qua lúc vừa hiện
		var sc = 0.85 + 0.15 * _back(clampf(t / 0.35, 0, 1))
		draw_set_transform(Vector2(cx, y0 + 32) * (1 - sc), 0, Vector2(sc, sc))
		var r = Rect2(x0 + ih * 0.45, y0 + 10, bw - ih * 0.45, 46)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.32, 0.08, 0.36, 0.82 * al) if cele else Color(0.08, 0.06, 0.12, 0.78 * al)
		sb.border_color = Color(1, 0.55, 0.9, 0.95 * al) if cele else Color(1, 0.8, 0.3, 0.9 * al)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(23)
		draw_style_box(sb, r)
		if t < 1.2:
			var sx = r.position.x + (r.size.x + 80) * (t / 1.2) - 40
			draw_rect(Rect2(clampf(sx, r.position.x + 10, r.end.x - 30), r.position.y + 3, 20, r.size.y - 6), Color(1, 1, 0.85, 0.25 * al))
		if cele:
			# ngôi sao vàng xoay, tỏa tia, hạt lấp lánh quanh băng
			var c0 = Vector2(x0 + ih * 0.5, y0 + 33)
			draw_circle(c0, ih * 0.46, Color(1, 0.5, 0.85, (0.3 + 0.15 * sin(t * 5.0)) * al))
			for i in 10:
				var an = t * 1.5 + TAU * i / 10.0
				draw_line(c0 + Vector2(cos(an), sin(an)) * 18, c0 + Vector2(cos(an), sin(an)) * (34 + 4 * sin(t * 6 + i)), Color(1, 0.9, 0.4, 0.7 * al), 3)
			var pts = PackedVector2Array()
			for i in 10:
				var an2 = -PI / 2 + t * 0.8 + TAU * i / 10.0
				pts.append(c0 + Vector2(cos(an2), sin(an2)) * (26.0 if i % 2 == 0 else 11.0))
			draw_colored_polygon(pts, Color(1, 0.85, 0.25, al))
			var o2 = pts.duplicate()
			o2.append(pts[0])
			draw_polyline(o2, Color(UI.INK, al), 3)
			for i in 6:
				var u = fmod(t * 0.35 + i / 6.0, 1.0)
				var sp = Vector2(r.position.x + r.size.x * u, r.position.y + (2 if i % 2 == 0 else r.size.y - 2))
				draw_circle(sp, 2.5 + 1.5 * sin(t * 8 + i), Color(1, 1, 0.8, al * 0.9))
			draw_set_transform(Vector2.ZERO)
			return
		# biểu tượng động: 8 khung ~11 khung/giây, nảy nhẹ
		var A: Dictionary = Data.A.get("annfx", {}).get(kind, {})
		if not A.is_empty():
			var k = int(t * 11.0) % 8
			var tx = Data.tex(A.f[k])
			if tx:
				var h = ih * (1.0 + 0.06 * sin(t * 5.0))
				var w = h * float(A.w) / float(A.h)
				var gl = 0.25 + 0.15 * sin(t * 4.0)
				draw_circle(Vector2(x0 + ih * 0.5, y0 + 33), ih * 0.46, Color(1, 0.75, 0.25, gl * al * 0.5))
				draw_texture_rect(tx, Rect2(x0 + ih * 0.5 - w / 2, y0 + 33 - h / 2, w, h), false, Color(1, 1, 1, al))
		draw_set_transform(Vector2.ZERO)
	func _back(u: float) -> float:
		var c = 1.70158
		return 1.0 + (c + 1.0) * pow(u - 1.0, 3) + c * pow(u - 1.0, 2)

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
	var soft = int(m.get("soft", max(1, mx - 2)))
	for e in m.get("list", []):
		var k = int(e[0])
		var n = int(e[1])
		var col = UI.GOLD if k == cur else (UI.RED if n >= soft else (Color("ffd98a") if n >= ceili(mx * 0.45) else UI.GREEN))
		var b = UI.button("Khu %d\n%d/%d" % [k, n, mx], col, 17)
		b.custom_minimum_size = Vector2(96, 70)
		b.disabled = k == cur or n >= mx
		b.pressed.connect(func(): game.loading.begin("%s · Khu %d" % [str(game.M.name), k]); Net.send({"t": "khu", "k": k}); khu_pop.queue_free())
		g.add_child(b)
	v.add_child(UI.label("Đang ở khu %d." % cur, 16, UI.INK, "semi"))


## ---------- nút điều khiển: kiểu "Phím Ngọc Rồng" (mặc định) hoặc "Nút tròn" (ô kỹ năng vuông) ----------
func _build_controls() -> void:
	var g = game
	var H: Dictionary = Data.A.get("hud", {})
	if ctl and is_instance_valid(ctl):
		ctl.queue_free()
	skills.clear()
	joy = null
	ctl = Control.new()
	ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ctl)
	root.move_child(ctl, 0)
	var mode = str(Data.setting("ctl", "dpad")) if touch else "keys"
	var br = Control.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctl.add_child(br)
	var atk = SkillBtn.new()
	atk.tex = Data.tex(H.ui.get("atk", ""))
	atk.big = true
	atk.key = "" if touch else "J"
	atk.gui_input.connect(func(ev):
		if ev is InputEventScreenTouch or (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
			g.atk_held = ev.pressed)
	potb = SkillBtn.new()
	potb.mx = 3.0
	potb.tex = Data.pot_icon(false, 1)
	potb.key = "" if touch else "Q"
	potb.pressed.connect(g.do_pot)
	kpotb = SkillBtn.new()
	kpotb.mx = 3.0
	kpotb.tex = Data.pot_icon(true, 1)
	if not H.ui.has("kpot1"):
		kpotb.tint = Color(0.45, 0.75, 1.6)
	kpotb.key = "" if touch else "R"
	kpotb.pressed.connect(g.do_kpot)
	var rb = SkillBtn.new()
	rb.tex = Data.tex(H.ui.get("roll", ""))
	rb.mx = 1.2
	rb.key = "" if touch else "L"
	rb.pressed.connect(g.do_roll)
	rollb = rb
	var tgb = SkillBtn.new()
	tgb.tex = Data.tex(H.ui.get("target", ""))
	tgb.mx = 0.3
	tgb.key = "" if touch else "Tab"
	tgb.pressed.connect(g.next_target)
	if mode == "joy":
		# kiểu nút tròn: ô kỹ năng vuông một hàng ở dưới (như Ngọc Rồng), nút đánh tròn lớn ở góc
		_place(br, Vector2(-760, -190), Vector2(760, 190))
		atk.size = Vector2(150, 150)
		atk.position = Vector2(760 - 170, 190 - 168)
		br.add_child(atk)
		for i in 6:
			var b = SkillBtn.new()
			b.square = true
			b.size = Vector2(84, 84)
			b.position = Vector2(760 - 190 - (6 - i) * 92, 190 - 100)
			var ii = i
			b.pressed.connect(func(): g.do_skill(ii))
			br.add_child(b)
			skills.append(b)
		for q in [[potb, 0], [kpotb, 1], [rb, 2]]:
			var b2: SkillBtn = q[0]
			b2.square = true
			b2.size = Vector2(74, 74)
			b2.position = Vector2(760 - 190 - (3 - int(q[1])) * 82, 190 - 190)
			br.add_child(b2)
		# nút đổi mục tiêu: tròn, ngay trên nút đánh
		tgb.size = Vector2(70, 70)
		tgb.position = Vector2(760 - 130, -64)
		br.add_child(tgb)
		var js = Joystick.new()
		js.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_place(js, Vector2(20, -280), Vector2(280, 260))
		js.jump.connect(g.jump)
		ctl.add_child(js)
		joy = js
	else:
		# mặc định: nút đánh lớn ở góc, 6 kỹ năng xếp hình cung quanh
		_place(br, Vector2(-460, -350), Vector2(450, 320))
		var ac = Vector2(380, 270)
		atk.size = Vector2(136, 136)
		atk.position = ac - atk.size / 2
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
		potb.size = Vector2(72, 72)
		potb.position = Vector2(-10, 250)
		br.add_child(potb)
		kpotb.size = Vector2(64, 64)
		kpotb.position = Vector2(-6, 170)
		br.add_child(kpotb)
		if touch:
			rb.size = Vector2(88, 88)
			rb.position = Vector2(-120, 230)
			br.add_child(rb)
			# nút đổi mục tiêu: tròn, ngay trên nút lướt
			tgb.size = Vector2(72, 72)
			tgb.position = Vector2(-112, 140)
			br.add_child(tgb)
			# phím di chuyển kiểu Ngọc Rồng: ◀ ▶ đi, ▲ nhảy/leo, ▼ xuống, ↖ ↗ nhảy chéo
			var dp = DPad.new()
			dp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			var ds = Vector2(DPad.B * 3 + DPad.GAP * 2, DPad.B * 3 + DPad.GAP * 2)
			_place(dp, Vector2(24, -ds.y - 20), ds)
			dp.jump.connect(g.jump)
			ctl.add_child(dp)
			joy = dp
		else:
			var hint = UI.outlined("A/D: đi · W/Space: nhảy, bám dây · S: leo xuống · S+Space: xuống bậc · J: đánh · 1-6: kỹ năng · L: lướt · Q: bình máu · R: bình KI · E: nói chuyện · B: túi đồ", 14, Color.WHITE, "semi", 4)
			hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_place(hint, Vector2(16, -30), Vector2(1200, 24))
			ctl.add_child(hint)
	if game.me_data.size() > 0:
		refresh()


## ---------- bảng tự động đánh quái ----------
func _auto_style() -> void:
	if auto_b:
		auto_b.set_meta("on", game.auto_on)
		auto_on_l.visible = game.auto_on
		auto_b.modulate = Color(1.15, 1.15, 1.15) if game.auto_on else Color.WHITE

func open_auto() -> void:
	if auto_pop and is_instance_valid(auto_pop):
		auto_pop.queue_free()
		auto_pop = null
		return
	var a: Dictionary = game.auto_cfg().duplicate(true)
	var save = func(): Data.set_setting("auto", a)
	auto_pop = Control.new()
	auto_pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	auto_pop.theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: open_auto())
	auto_pop.add_child(dim)
	var card = UI.card(Vector2(640, 0))
	auto_pop.add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	var head = UI.hbox(10)
	v.add_child(head)
	var tl = UI.label("Tự động đánh quái", 28, UI.INK, "title")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(open_auto)
	head.add_child(x)
	v.add_child(UI.label("Nhân vật tự chạy bộ tới quái và đánh (không dịch chuyển). Bấm nút đi để điều khiển tay bất cứ lúc nào.", 15, Color("5a6b8c"), "body"))
	v.add_child(_sep())
	v.add_child(UI.label("Quái ở " + str(game.M.get("name", "")) + " (không chọn = đánh tất cả):", 17, UI.INK, "bold"))
	var mons_sel: Dictionary = a.get("mons", {}) if a.get("mons") is Dictionary else {}
	var cur: Array = (mons_sel.get(str(game.mi), []) as Array).duplicate() if mons_sel.get(str(game.mi)) is Array else []
	var types := {}
	for sp in game.M.get("spots", []):
		var t = str(sp.mon)
		var lv: Array = sp.lv
		if not types.has(t):
			types[t] = [int(lv[0]), int(lv[1])]
		else:
			types[t] = [mini(types[t][0], int(lv[0])), maxi(types[t][1], int(lv[1]))]
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	v.add_child(grid)
	if types.is_empty():
		v.add_child(UI.label("Bản đồ này không có quái.", 15, UI.INK, "body"))
	for t in types:
		var cb = _cb("%s (cấp %d–%d)" % [str(Data.D.mons.get(t, {}).get("n", t)), types[t][0], types[t][1]], cur.has(t))
		var tt: String = t
		cb.toggled.connect(func(on):
			if on and not cur.has(tt): cur.append(tt)
			if not on: cur.erase(tt)
			mons_sel[str(game.mi)] = cur
			a["mons"] = mons_sel
			save.call())
		grid.add_child(cb)
	v.add_child(_sep())
	var opt = func(label: String, key: String, def: bool) -> CheckBox:
		var c = _cb(label, bool(a.get(key, def)))
		c.toggled.connect(func(on):
			a[key] = on
			save.call()
			if key == "pick":
				game.sync_apick())
		return c
	v.add_child(opt.call("Tự nhặt đồ rơi (khi Auto, đi gần là nhặt)", "pick", true))
	v.add_child(opt.call("Tự dùng kỹ năng đã học", "skill", true))
	for q in [["hp", "hpPct", "Tự dùng bình máu khi máu dưới", [30, 40, 50, 60, 70], 40], ["ki", "kiPct", "Tự dùng bình KI khi KI dưới", [20, 30, 40, 50], 30]]:
		var row = UI.hbox(10)
		row.add_child(opt.call(q[2], q[0], true))
		var ob = OptionButton.new()
		var vals: Array = q[3]
		for vv in vals:
			ob.add_item("%d%%" % vv)
		ob.selected = maxi(0, vals.find(int(a.get(q[1], q[4]))))
		var kk: String = q[1]
		ob.item_selected.connect(func(i): a[kk] = vals[i]; save.call())
		row.add_child(ob)
		# chọn cỡ bình dùng khi auto
		var tb = OptionButton.new()
		for nm in ["Bình tự chọn", "Bình nhỏ", "Bình vừa", "Bình lớn"]:
			tb.add_item(nm)
		var tk: String = q[0] + "T"
		tb.selected = clampi(int(a.get(tk, -1)) + 1, 0, 3)
		tb.item_selected.connect(func(i): a[tk] = i - 1; save.call())
		row.add_child(tb)
		v.add_child(row)
	v.add_child(_sep())
	var go = UI.button("TẮT AUTO" if game.auto_on else "BẬT AUTO", UI.RED if game.auto_on else UI.GREEN, 22)
	go.custom_minimum_size = Vector2(0, 56)
	go.pressed.connect(func(): game.set_auto(not game.auto_on); _auto_style(); open_auto())
	v.add_child(go)
	root.add_child(auto_pop)

## ô đánh dấu không bị nháy trắng khi bấm (bỏ hết nền theo trạng thái)
static func _cb(text: String, on: bool) -> CheckBox:
	var c = CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 17)
	for st in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	for fc in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		c.add_theme_color_override(fc, UI.INK)
	return c

func _sep() -> Control:
	var s = ColorRect.new()
	s.color = Color("c9d3e6")
	s.custom_minimum_size = Vector2(0, 2)
	return s


## dòng nhắc ngắn giữa màn hình (vd. đồ của người khác)
func _toast(text: String) -> void:
	if toast_l and is_instance_valid(toast_l):
		toast_l.queue_free()
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color(0.09, 0.12, 0.25, 0.85), Color("ffb347"), 10, 2, false))
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_place(p, Vector2(0, 150), Vector2.ZERO)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = UI.label(text, 18, Color("ffe08a"), "semi")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	root.add_child(p)
	toast_l = p
	var tw = p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
	add_log(text, Color("ffb347"))

## "Hành trang đã đầy" to, giữa màn hình (máy chủ không tự bán nữa, người chơi tự bán hoặc vứt)
var full_l: Control
func show_full() -> void:
	if full_l and is_instance_valid(full_l):
		full_l.queue_free()
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color(0.35, 0.06, 0.1, 0.88), Color("ffb347"), 16, 3, false))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	_place(p, Vector2(0, -60), Vector2.ZERO)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v = UI.vbox(2)
	p.add_child(v)
	var l = UI.outlined("Hành trang đã đầy", 32, Color("ffe08a"), "bold", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var l2 = UI.label("Mở túi để bán hoặc vứt bớt đồ rồi nhặt tiếp.", 16, Color("ffe9d0"), "semi")
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l2)
	root.add_child(p)
	full_l = p
	var tw = p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

func _world_toast(n: String, text: String) -> void:
	if wt and is_instance_valid(wt):
		wt.queue_free()
	wt = PanelContainer.new()
	wt.add_theme_stylebox_override("panel", UI.box(Color(0.09, 0.12, 0.25, 0.82), Color("ffd23f"), 12, 2, false))
	wt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wt.position = Vector2(-280, 12)
	wt.custom_minimum_size = Vector2(560, 0)
	wt.mouse_filter = Control.MOUSE_FILTER_STOP
	var l = UI.label("[Thế giới] %s: %s" % [n, text], 16, Color("ffe08a"), "semi")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(536, 0)
	wt.add_child(l)
	wt.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: open_world_chat())
	root.add_child(wt)
	var tw = wt.create_tween()
	tw.tween_interval(4.5)
	tw.tween_property(wt, "modulate:a", 0.0, 0.5)
	tw.tween_callback(wt.queue_free)

func open_world_chat() -> void:
	var pop = Control.new()
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pop.theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: pop.queue_free())
	pop.add_child(dim)
	var card = UI.card(Vector2(640, 0))
	pop.add_child(UI.center(card))
	var v = UI.vbox(8)
	card.add_child(v)
	var head = UI.hbox(10)
	v.add_child(head)
	var tl = UI.label("Chat thế giới gần đây", 26, UI.INK, "title")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(pop.queue_free)
	head.add_child(x)
	v.add_child(UI.hsep())
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(600, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list = UI.vbox(6)
	sc.add_child(list)
	if world_log.is_empty():
		list.add_child(UI.label("Chưa có tin nhắn nào.", 16, Color("5a6b8c"), "body"))
	for i in range(world_log.size() - 1, -1, -1):
		var q: Array = world_log[i]
		var l = UI.label("%s: %s" % [q[0], q[1]], 16, UI.INK, "body")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(580, 0)
		list.add_child(l)
		list.add_child(UI.hsep())
	v.add_child(UI.label("Nhắn cả máy chủ: mở khung chat, gõ /all trước nội dung (5.000 vàng).", 13, Color("5a6b8c"), "body"))
	root.add_child(pop)


## đặt nút theo mép màn hình (dùng offset nên đúng cả khi dựng lại lúc đang chơi)
func _place(c: Control, off: Vector2, sz: Vector2) -> void:
	c.offset_left = off.x
	c.offset_top = off.y
	c.offset_right = off.x + sz.x
	c.offset_bottom = off.y + sz.y


## ---------- gục ngã: đếm ngược về Làng, hoặc hồi sinh tại chỗ mất vàng ----------
var dead_pan: Control
var dead_l: Label
var dead_end = 0.0
func _dead_ui() -> void:
	var dead = game.me.dead and Net.online()
	if not dead:
		if dead_pan and is_instance_valid(dead_pan):
			dead_pan.queue_free()
			dead_pan = null
		return
	var d = game.me_data
	if dead_pan == null or not is_instance_valid(dead_pan):
		dead_end = Time.get_ticks_msec() / 1000.0 + float(d.get("deadT", 15))
		dead_pan = ColorRect.new()
		(dead_pan as ColorRect).color = Color(0.2, 0.02, 0.05, 0.45)
		dead_pan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dead_pan.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(dead_pan)
		var card = UI.card(Vector2(520, 0))
		dead_pan.add_child(UI.center(card))
		var v = UI.vbox(12)
		card.add_child(v)
		var t = UI.label("Bạn đã gục ngã", 30, Color("c0143f"), "title")
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		v.add_child(UI.hsep())
		dead_l = UI.label("", 20, UI.INK, "bold")
		dead_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(dead_l)
		var cost = int(d.get("rvCost", 0))
		var b1 = UI.button("Hồi sinh tại chỗ · %s vàng" % UI.fmt(cost), UI.GOLD, 20)
		b1.custom_minimum_size = Vector2(0, 56)
		b1.disabled = int(d.get("gold", 0)) < cost
		b1.pressed.connect(func(): Net.send({"t": "revive", "here": 1}))
		v.add_child(b1)
		if int(d.get("gold", 0)) < cost:
			v.add_child(UI.label("Không đủ vàng để hồi sinh tại chỗ.", 15, Color("d9345a"), "semi"))
		var b2 = UI.button("Về Làng ngay", UI.SKY, 20)
		b2.custom_minimum_size = Vector2(0, 52)
		b2.pressed.connect(func(): Net.send({"t": "revive", "home": 1}))
		v.add_child(b2)
		v.add_child(UI.label("Hồi sinh tại chỗ: 60% máu. Về Làng: đầy máu, đầy KI.", 14, Color("5a6b8c"), "body"))
	var left = maxf(0.0, dead_end - Time.get_ticks_msec() / 1000.0)
	dead_l.text = "Tự hồi sinh ở Làng sau %d giây" % ceili(left)
