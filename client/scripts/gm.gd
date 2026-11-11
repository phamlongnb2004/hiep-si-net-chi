extends Control
class_name GmPanel
## Bảng GM trong game: chỉ hiện cho tài khoản quản trị; phải mở khóa bằng mã 2 lớp mỗi lần vào (hiệu lực 2 giờ).
## Mọi lệnh do máy chủ kiểm quyền và ghi nhật ký; ứng dụng chỉ gửi yêu cầu.

var game: Game
var unlocked = false
var hidden_on = false
var body: VBoxContainer
var status_l: Label
var out_l: Label

func setup(g: Game) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.13, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if UI.tapped(ev): close())
	add_child(dim)
	var card = UI.card(Vector2(900, 560))
	add_child(UI.center(card))
	var v = UI.vbox(10)
	card.add_child(v)
	var head = UI.hbox(12)
	v.add_child(head)
	head.add_child(UI.label("Bảng GM", 30, UI.INK, "title"))
	status_l = UI.label("", 16, Color("5a6b8c"), "semi")
	status_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(status_l)
	var x = UI.button("✕", UI.RED, 20)
	x.custom_minimum_size = Vector2(48, 44)
	x.pressed.connect(close)
	head.add_child(x)
	out_l = UI.label("", 17, Color("2a7a3a"), "bold")
	out_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(out_l)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(840, 420)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = UI.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	g.gm_reply.connect(_reply)
	visible = false

func open() -> void:
	visible = true
	out_l.text = ""
	Net.send({"t": "gm", "cmd": "status"})
	render()

func close() -> void:
	visible = false

func _send(m: Dictionary) -> void:
	m["t"] = "gm"
	out_l.add_theme_color_override("font_color", Color("5a6b8c"))
	out_l.text = "Đang gửi…"
	Net.send(m)

func _reply(m: Dictionary) -> void:
	var d = m.get("data")
	if d is Dictionary and d.has("unlocked"):
		var was = unlocked
		unlocked = bool(d.unlocked)
		if was != unlocked and visible:
			render()
	if d is Dictionary and d.has("hidden"):
		hidden_on = bool(d.hidden)
	if m.get("cmd") == "who" and d is Dictionary:
		var names = []
		for p in d.get("list", []):
			names.append("%s (Lv.%d, %s)" % [p.name, int(p.lv), Data.D.maps[clampi(int(p.map), 0, Data.D.maps.size() - 1)].name if int(p.map) >= 0 else "—"])
		out_l.add_theme_color_override("font_color", UI.INK)
		out_l.text = "Đang online (%d): %s" % [names.size(), ", ".join(names)]
		return
	if str(m.get("msg", "")) != "":
		out_l.add_theme_color_override("font_color", Color("2a7a3a") if m.get("ok") else Color("c0143f"))
		out_l.text = str(m.msg)
	if visible and m.get("cmd") in ["hide"]:
		render()

func _row(title: String) -> HBoxContainer:
	body.add_child(UI.label(title, 18, UI.INK, "bold"))
	var r = UI.hbox(8)
	body.add_child(r)
	return r

func _edit(ph: String, w := 180, max_len := 40) -> LineEdit:
	var e = UI.edit(ph)
	e.custom_minimum_size = Vector2(w, 48)
	e.max_length = max_len
	return e

func _opt(items: Array, w := 220) -> OptionButton:
	var o = OptionButton.new()
	o.custom_minimum_size = Vector2(w, 48)
	o.add_theme_font_size_override("font_size", 18)
	for it in items:
		o.add_item(str(it))
	return o

func render() -> void:
	for c in body.get_children():
		c.queue_free()
	var owner = game.staff == "owner"
	status_l.text = ("Chủ" if owner else "GM hỗ trợ") + (" · Đã mở khóa" if unlocked else " · Đang khóa")
	if not unlocked:
		body.add_child(UI.label("Nhập mã 6 số trong ứng dụng xác thực (giống khi đăng nhập trang /admin) để mở bảng GM trong 2 giờ.", 17, UI.INK, "body"))
		var r = UI.hbox(8)
		body.add_child(r)
		var otp = _edit("Mã 6 số", 220, 6)
		otp.add_theme_font_size_override("font_size", 26)
		r.add_child(otp)
		var b = UI.button("Mở khóa", UI.GOLD, 20)
		b.pressed.connect(func(): _send({"cmd": "unlock", "otp": otp.text.strip_edges()}); otp.text = "")
		otp.text_submitted.connect(func(_t): b.pressed.emit())
		r.add_child(b)
		return
	# dịch chuyển
	var r1 = _row("Dịch chuyển")
	var maps = []
	for m in Data.D.maps:
		maps.append(m.name)
	var mo = _opt(maps, 280)
	mo.selected = max(0, game.mi)
	r1.add_child(mo)
	var tp = UI.button("Tới bản đồ", UI.SKY, 18)
	tp.pressed.connect(func(): _send({"cmd": "tp", "map": mo.selected}))
	r1.add_child(tp)
	var hide = UI.button("Hiện hình" if hidden_on else "Tàng hình", UI.GOLD if hidden_on else UI.SKY, 18)
	hide.pressed.connect(func(): _send({"cmd": "hide", "on": not hidden_on}))
	r1.add_child(hide)
	var heal = UI.button("Hồi đầy máu", UI.GREEN, 18)
	heal.pressed.connect(func(): _send({"cmd": "heal"}))
	r1.add_child(heal)
	# người chơi
	var r2 = _row("Người chơi (nhập tên nhân vật hoặc tài khoản)")
	var nm = _edit("Tên người chơi", 240, 32)
	r2.add_child(nm)
	for a in [["Tới chỗ", "goto"], ["Kéo tới đây", "pull"], ["Hồi máu", "heal"]]:
		var bb = UI.button(a[0], UI.SKY, 16)
		var cmd: String = a[1]
		bb.pressed.connect(func(): _send({"cmd": cmd, "name": nm.text.strip_edges()}))
		r2.add_child(bb)
	var who = UI.button("Ai đang online?", UI.SKY, 16)
	who.pressed.connect(func(): _send({"cmd": "who"}))
	r2.add_child(who)
	var r3 = UI.hbox(8)
	body.add_child(r3)
	var mins = _opt(["Bỏ cấm chat", "Cấm chat 10 phút", "Cấm chat 1 giờ", "Cấm chat 1 ngày"], 220)
	r3.add_child(mins)
	var mb = UI.button("Áp dụng", UI.GOLD, 16)
	mb.pressed.connect(func(): _send({"cmd": "mute", "name": nm.text.strip_edges(), "minutes": [0, 10, 60, 1440][mins.selected]}))
	r3.add_child(mb)
	var kick = UI.button("Đá khỏi game", UI.RED, 16)
	kick.pressed.connect(func(): _send({"cmd": "kick", "name": nm.text.strip_edges()}))
	r3.add_child(kick)
	# quái
	var r4 = _row("Gọi quái để thử (quái gọi ra không cho kinh nghiệm, vàng, đồ)")
	var keys = Data.D.mons.keys()
	var names = []
	for k in keys:
		names.append(Data.D.mons[k].n)
	var ty = _opt(names, 220)
	r4.add_child(ty)
	var lv = _edit("Cấp", 90, 3)
	lv.text = str(max(1, int(game.me_data.get("lv", 1))))
	r4.add_child(lv)
	var n = _opt(["1 con", "3 con", "5 con", "10 con"], 130)
	r4.add_child(n)
	var sp = UI.button("Gọi", UI.GOLD, 16)
	sp.pressed.connect(func(): _send({"cmd": "spawn", "type": keys[ty.selected], "lv": int(lv.text), "n": [1, 3, 5, 10][n.selected]}))
	r4.add_child(sp)
	var ka = UI.button("Dọn quái bản đồ", UI.RED, 16)
	ka.pressed.connect(func(): _send({"cmd": "killall"}))
	r4.add_child(ka)
	var wbb = UI.button("Gọi Ma Long", UI.RED, 16)
	wbb.pressed.connect(func(): _send({"cmd": "worldboss"}))
	r4.add_child(wbb)
	# thông báo
	var r5 = _row("Thông báo toàn máy chủ")
	var an = _edit("Nội dung thông báo", 560, 200)
	r5.add_child(an)
	var ab = UI.button("Gửi", UI.GOLD, 16)
	ab.pressed.connect(func(): _send({"cmd": "announce", "text": an.text.strip_edges()}); an.text = "")
	r5.add_child(ab)
	# tặng (chỉ chủ)
	if owner:
		var r6 = _row("Tặng (chỉ chủ) — để trống tên = tặng cho chính mình")
		var tn = _edit("Tên người nhận", 200, 32)
		r6.add_child(tn)
		var gold = _edit("Vàng", 120, 10)
		r6.add_child(gold)
		var ex = _edit("Kinh nghiệm", 140, 12)
		r6.add_child(ex)
		var st = _edit("Đá", 90, 6)
		r6.add_child(st)
		var gb = UI.button("Tặng", UI.GREEN, 16)
		gb.pressed.connect(func():
			var m = {"cmd": "give", "gold": int(gold.text), "exp": int(ex.text), "stones": int(st.text)}
			if tn.text.strip_edges() != "": m["name"] = tn.text.strip_edges()
			_send(m))
		r6.add_child(gb)
		var r7 = UI.hbox(8)
		body.add_child(r7)
		var cl = _opt(["Kiếm Sĩ", "Cung Thủ", "Pháp Sư", "Võ Sĩ"], 160)
		r7.add_child(cl)
		var sl = _opt(["Mũ", "Áo", "Áo choàng", "Vũ khí"], 150)
		r7.add_child(sl)
		var rr = _opt(["Thường", "Hiếm", "Sử Thi", "Huyền Thoại"], 170)
		r7.add_child(rr)
		var il = _edit("Cấp đồ", 100, 3)
		r7.add_child(il)
		var ib = UI.button("Tặng đồ", UI.GREEN, 16)
		ib.pressed.connect(func():
			var m = {"cmd": "give", "item": {"cls": ["sword", "archer", "mage", "fighter"][cl.selected], "slot": ["hat", "armor", "cape", "weapon"][sl.selected], "r": rr.selected, "lvl": int(il.text) if il.text != "" else int(game.me_data.get("lv", 1))}}
			if tn.text.strip_edges() != "": m["name"] = tn.text.strip_edges()
			_send(m))
		r7.add_child(ib)
