extends Node
## Chạy thử tự động (chỉ khi mở với tham số "-- autotest=<thư mục ảnh>"): đăng ký, vào máy chủ, tạo nhân vật,
## đi, đánh quái, mở túi đồ, chụp màn hình từng bước. Dùng để kiểm tra bản dựng thật trên máy.

var main: Node
var out = "user://shots"
var step = 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("autotest="):
			out = a.substr(9)
	DirAccess.make_dir_recursive_absolute(out)
	run()

func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(out.path_join(n + ".png"))
	print("ẢNH ", n)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func run() -> void:
	await wait(1.5)
	main = get_tree().root.get_node_or_null("Main")
	await shot("01-login")
	# chế độ thử GM: HSNC_GM_USER/PASS/OTP -> đăng nhập tài khoản quản trị, mở bảng GM, chụp
	if OS.get_environment("HSNC_GM_USER") != "":
		await gm_test()
		get_tree().quit()
		return
	var u = "bot%d" % (Time.get_unix_time_from_system() as int % 100000)
	var r = await Net.login(u, "matkhau1", true)
	print("đăng ký: ", r.code)
	main.show_servers()
	await wait(1.5)
	await shot("02-servers")
	main.enter(1)
	await wait(2.0)
	await shot("03-create")
	Net.send({"t": "create", "name": "Bot " + u.substr(3), "cls": "archer"})
	await wait(2.5)
	await shot("04-village")
	# có người chơi thử (bot) mời giao dịch: đồng ý rồi chụp bảng giao dịch
	var tw = Time.get_ticks_msec()
	while Time.get_ticks_msec() - tw < 8000 and not (main.social.popup and is_instance_valid(main.social.popup)):
		await wait(0.3)
	if main.social.popup and is_instance_valid(main.social.popup):
		await shot("04b-trade-ask")
		for b in main.social.popup.find_children("*", "Button", true, false):
			if b.text == "Đồng ý":
				b.pressed.emit()
		await wait(2.5)
		await shot("04c-trade")
		Net.send({"t": "tr_cancel"})
		await wait(0.5)
	var g: Game = main.game
	# đi sang phải tới cổng
	g.joy = Vector2(1, 0)
	await wait(4.0)
	await shot("05-walk")
	var tw0 = Time.get_ticks_msec()
	var lx = 0.0
	while g.mi == 0 and Time.get_ticks_msec() - tw0 < 40000:
		await wait(0.4)
		if absf(g.me.position.x - lx) < 4:
			g.jump()
		lx = g.me.position.x
	await wait(2.0)
	g.joy = Vector2.ZERO
	await shot("06-map1")
	g.joy = Vector2(1, 0)
	await wait(2.5)
	g.joy = Vector2.ZERO
	# đánh quái gần nhất
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 12000:
		var m = g.nearest_mon(900)
		if m:
			g.focus = m
		if randf() < 0.2:
			g.do_skill(0)
		await wait(0.3)
	await shot("07-fight")
	main.open_bag()
	await wait(0.8)
	await shot("08-bag")
	main.bag.tab = "char"
	main.bag.render()
	await wait(0.8)
	await shot("09-char")
	main.bag.tab = "stat"
	main.bag.render()
	await wait(0.8)
	await shot("09b-stat")
	Net.send({"t": "stat", "k": "atk", "n": 1})
	Net.send({"t": "stat", "k": "ki", "n": 1})
	await wait(1.0)
	await shot("09c-stat-added")
	main.bag.close()
	main.npc.open("gear")
	await wait(0.8)
	await shot("10-gear-shop")
	main.npc.close()
	main.social.open_friends()
	await wait(1.0)
	await shot("11-friends")
	main.social.open_friends()
	Net.send({"t": "khu"})
	await wait(1.0)
	await shot("11b-khu")
	Net.send({"t": "khu", "k": 2})
	await wait(1.5)
	await shot("11c-khu2")
	# ô đồ cường hóa: +3 +6 +9 +12 +15
	var box = HBoxContainer.new()
	box.position = Vector2(200, 250)
	box.add_theme_constant_override("separation", 20)
	for upv in [0, 3, 6, 9, 12, 15]:
		var it = {"slot": "weapon", "cls": "archer", "tier": 3, "r": 3, "lvl": 20, "up": upv, "lock": 1 if upv == 6 else 0, "st": {"atk": 50}}
		box.add_child(ItemCell.make(it, false, true, false, 110))
	var cl = CanvasLayer.new()
	cl.layer = 50
	var bgc = ColorRect.new()
	bgc.color = Color("fffaf0")
	bgc.size = Vector2(1100, 200)
	bgc.position = Vector2(150, 200)
	cl.add_child(bgc)
	cl.add_child(box)
	add_child(cl)
	await wait(0.7)
	await shot("12-glow-a")
	await wait(0.5)
	await shot("12-glow-b")
	cl.queue_free()
	print("XONG cấp=", g.me_data.get("lv"), " vàng=", g.me_data.get("gold"), " túi=", g.me_data.get("inv", []).size())
	get_tree().quit()

func gm_test() -> void:
	var r = await Net.login(OS.get_environment("HSNC_GM_USER"), OS.get_environment("HSNC_GM_PASS"), false)
	print("đăng nhập GM: ", r.code)
	main.enter(1)
	await wait(2.0)
	if main.screen and main.screen.find_child("CreateErr", true, false):
		Net.send({"t": "create", "name": "Chu Game", "cls": "sword"})
		await wait(2.0)
	await shot("g1-hud")
	main.open_gm()
	await wait(0.8)
	await shot("g2-locked")
	Net.send({"t": "gm", "cmd": "unlock", "otp": OS.get_environment("HSNC_GM_OTP")})
	await wait(1.0)
	await shot("g3-unlocked")
	main.gm._send({"cmd": "spawn", "type": "boar", "lv": 3, "n": 3})
	await wait(0.6)
	main.gm._send({"cmd": "tp", "map": 1})
	await wait(1.5)
	main.gm._send({"cmd": "spawn", "type": "dragon", "lv": 10, "n": 1})
	await wait(1.0)
	main.gm.close()
	await wait(0.5)
	await shot("g4-spawned")
	print("XONG GM mons=", main.game.mons.size(), " staff=", main.game.staff)

