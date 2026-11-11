extends Node
## Chạy thử tự động (chỉ khi mở với tham số "-- autotest=<thư mục ảnh>"): đăng ký, vào máy chủ, tạo nhân vật,
## đi, đánh quái, mở túi đồ, chụp màn hình từng bước. Dùng để kiểm tra bản dựng thật trên máy.

var main: Node
var out = "user://shots"
var step = 0
var _fmax = 0.0      # khung hình chậm nhất (ms) trong giây vừa qua (chế độ đo perf)
var _fn = 0
var _pos_n = 0

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
	# chế độ dạo bản đồ: HSNC_TOUR_USER (tài khoản có sẵn), HSNC_TOUR_ACT = gate (vào khu trùm đánh trùm) | left | right (đi và đánh quái)
	if OS.get_environment("HSNC_TOUR_USER") != "":
		await tour(OS.get_environment("HSNC_TOUR_USER"), OS.get_environment("HSNC_TOUR_ACT"))
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") == "climbbig":
		await preview_big()
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") == "items":
		await preview_items()
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") in ["jump", "die"]:
		await preview_jump()
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") == "perf":
		await perf_test()
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") == "pets":
		await preview_pets()
		get_tree().quit()
		return
	if OS.get_environment("HSNC_PREVIEW") == "climb":
		await preview_climb()
		get_tree().quit()
		return
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
	# đồ mới: giày, găng, dây chuyền, cánh + nhân vật đeo cánh (vỗ cánh)
	var cl2 = CanvasLayer.new()
	cl2.layer = 50
	var bg2 = ColorRect.new()
	bg2.color = Color("5d8fd6")
	bg2.size = Vector2(1280, 720)
	cl2.add_child(bg2)
	var row2 = HBoxContainer.new()
	row2.position = Vector2(60, 40)
	row2.add_theme_constant_override("separation", 10)
	for rk in 4:
		for sl in ["boots", "gloves", "neck", "wing"]:
			var it2 = {"slot": sl, "cls": "" if sl in Data.FREE else "mage", "tier": rk, "r": rk, "lvl": 30, "up": 0, "st": {"atk": 5}}
			row2.add_child(ItemCell.make(it2, false, true, false, 66))
	cl2.add_child(row2)
	var cls4 = ["sword", "archer", "mage", "fighter"]
	for rk in 4:
		var hh = Hero.new()
		hh.cls = cls4[rk]
		hh.look = 31 * rk % 125
		hh.wing = rk
		hh.nm = "Cánh %d" % rk
		hh.position = Vector2(200 + rk * 260, 520)
		hh.scale = Vector2(2.2, 2.2)
		cl2.add_child(hh)
	add_child(cl2)
	await wait(1.2)
	await shot("13-new-gear-a")
	await wait(0.13)
	await shot("13-new-gear-b")
	await wait(0.13)
	await shot("13-new-gear-c")
	cl2.queue_free()
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


func tour(u: String, act: String) -> void:
	var nw = act == "art" or act == "artmaps"
	if nw:
		u = "art%d" % (Time.get_unix_time_from_system() as int % 100000)
	var r = await Net.login(u, "matkhau1", nw)
	print("đăng nhập: ", r.code)
	main.show_servers()
	await wait(1.5)
	main.enter(1)
	await wait(3.0)
	if nw:
		Net.send({"t": "create", "name": "Art " + u.substr(3), "cls": OS.get_environment("HSNC_CLS") if OS.get_environment("HSNC_CLS") != "" else "sword"})
		await wait(3.0)
	var g: Game = main.game
	if act == "art":
		await tour_art(g)
		return
	if act == "artmaps":
		await tour_maps(g)
		return
	await shot("t1-" + u)
	if act == "climb":
		await tour_climb(g)
		return
	if act == "maps":
		await tour_maps(g)
		return
	if act == "annshow":
		var msgs = [["⏰ Hang Sói (Rừng Tuyết Phong) mở sau 5 phút", "b1"], ["⚔ Hang Vua Heo đã mở! Cổng ở giữa Đồng Bằng Khởi Nguyên", "b2"],
			["⚔ Thu arena đã kết liễu Vua Heo Rừng!", "b3"], ["Bảo trì máy chủ lúc 23:00 trong 10 phút", "b4"]]
		for m in msgs:
			main.hud.show_ann(m[0])
			for k in 14:
				await wait(0.08)
				await shot("%s-%02d" % [m[1], k])
			await wait(0.6)
		return
	if act == "ann":
		await tour_ann(g)
		return
	if act == "gate":
		g.talk()
		await wait(2.5)
		await shot("t2-arena")
		g.joy = Vector2(1, 0)
		await wait(2.2)
		g.joy = Vector2.ZERO
	else:
		g.joy = Vector2(1 if act == "right" else -1, 0)
		await wait(2.5)
		g.joy = Vector2.ZERO
		await shot("t2-walk")
	var t0 = Time.get_ticks_msec()
	var n = 3
	var last_s = 0
	var dur = float(OS.get_environment("HSNC_TOUR_SEC")) if OS.get_environment("HSNC_TOUR_SEC") != "" else 16.0
	while Time.get_ticks_msec() - t0 < dur * 1000:
		var m = g.nearest_mon(1200)
		if m:
			g.focus = m
		await wait(0.1)
		# chụp lúc trùm/quái đang ra chiêu: có vùng báo hoặc hiệu ứng chiêu
		var busy = g.fx.tgs.size() > 0 or g.fx.vfxs.size() > 0
		if (busy and Time.get_ticks_msec() - last_s > 700) or Time.get_ticks_msec() - last_s > 3000:
			last_s = Time.get_ticks_msec()
			await shot("t%02d-%s" % [n, "skill" if busy else "fight"])
			n += 1

## thông báo khu trùm: báo trước 5 phút, cổng đóng, lúc mở, kết liễu trùm
func tour_ann(g: Game) -> void:
	await wait(2.0)
	await shot("a1-bao-truoc")
	g.talk()
	await wait(1.5)
	await shot("a2-cong-dong")
	var gi = -1
	for i in g.M.portals.size():
		if g.M.portals[i].get("arena"):
			gi = i
	var t0 = Time.get_ticks_msec()
	while not Data.arena_state(int(g.M.portals[gi].to)).open and Time.get_ticks_msec() - t0 < 120000:
		await wait(0.5)
	await wait(2.0)
	await shot("a3-da-mo")
	g.talk()
	await wait(2.5)
	await shot("a4-vao")
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		var m = g.nearest_mon(1500)
		if m == null:
			break
		g.focus = m
		await wait(0.2)
	await wait(1.0)
	await shot("a5-ket-lieu")
	await wait(3.0)
	await shot("a6-sau")

## chụp toàn cảnh từng bản đồ (cửa sổ rất rộng): dựng bản đồ ngay trên máy, rải quái theo các bãi quái để xem
func tour_maps(g: Game) -> void:
	main.hud.visible = false
	var list = OS.get_environment("HSNC_MAPS").split(",")
	for ms in list:
		var i = int(ms)
		var M: Dictionary = Data.D.maps[i]
		var mons = []
		var n = 0
		for sp in M.spots:
			for k in int(sp.cnt):
				var x = float(sp.x) + float(sp.w) / 2 if int(sp.cnt) == 1 else float(sp.x) + 80 + (float(sp.w) - 160) * (k + 0.5) / float(sp.cnt)
				mons.append({"id": 900000 + n, "type": sp.mon, "lv": int(sp.lv[0]), "hpMax": 100, "hp": 100, "x": x, "y": Data.ground_y(M, x)})
				n += 1
		g._build_map({"m": i, "k": 1, "x": float(M.w) / 2, "y": Data.ground_y(M, float(M.w) / 2), "mons": mons, "drops": []})
		g.warping = true
		g.me.visible = false
		await wait(2.0)
		await shot("map%02d" % i)

## thử leo thang / qua cầu / xuống vực ở Rừng Tuyết (bắt đầu ở cổng Hang Sói, x 3400, tầng 360)
var pos_n = 0
func tour_climb(g: Game) -> void:
	Net.message.connect(func(m): if str(m.get("t")) == "pos": pos_n += 1)
	var step = func(name: String, joy: Vector2, sec: float) -> void:
		g.joy = joy
		await wait(sec)
		print("%s: x=%d y=%d leo=%s bị kéo=%d" % [name, g.me.position.x, g.me.position.y, str(not g.climb.is_empty()), pos_n])
	await step.call("đầu", Vector2.ZERO, 0.5)
	await step.call("đi trái qua cầu", Vector2(-1, 0), 1.6)
	await shot("c1-cau")
	await step.call("tới thang 3000", Vector2(-1, 0), 0.05)
	while g.me.position.x > 3002:
		g.joy = Vector2(-1, 0)
		await wait(0.02)
	g.joy = Vector2(0, 1)
	await wait(0.3)
	await step.call("bám thang xuống", Vector2(0, 1), 1.0)
	await shot("c2-thang")
	await step.call("xuống đáy", Vector2(0, 1), 1.0)
	await step.call("đi tới thang 2600", Vector2(-1, 0), 1.6)
	while g.me.position.x > 2602:
		g.joy = Vector2(-1, 0)
		await wait(0.02)
	g.joy = Vector2.ZERO
	g.jump()
	await step.call("bám thang lên", Vector2(0, -1), 0.8)
	await shot("c3-leo")
	await step.call("lên đỉnh", Vector2(0, -1), 1.2)
	await step.call("đi trái", Vector2(-1, 0), 1.0)
	await shot("c4-tren")
	g.joy = Vector2.ZERO
	await wait(1.0)
	print("vị trí máy chủ khớp: bị kéo về ", pos_n, " lần")


## xem thử icon đồ theo bậc: mỗi hàng một bậc (cấp 5, 15 … 95); 6 món của phái + 5 trang sức
func preview_items() -> void:
	var cv = CanvasLayer.new()
	cv.layer = 100
	get_tree().root.add_child(cv)
	var bg = ColorRect.new()
	bg.color = Color("2a3d5c")
	bg.size = Vector2(1400, 900)
	cv.add_child(bg)
	var c = OS.get_environment("HSNC_CLS")
	if c == "":
		c = "fighter"
	var col = VBoxContainer.new()
	col.position = Vector2(20, 10)
	cv.add_child(col)
	for b in 10:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		col.add_child(row)
		var lvl = b * 10 + 5
		var k = 0
		for sl in ["hat", "armor", "cape", "weapon", "boots", "gloves", "neck", "ring", "earring", "belt", "charm"]:
			var r = (b + k) % 4
			k += 1
			var it = {"slot": sl, "cls": "" if sl in Data.FREE else c, "tier": r, "r": r, "lvl": lvl, "b": Data.band(lvl), "up": 0, "st": {"atk": 5}, "name": Data.gen_name(sl, c, r, lvl)}
			row.add_child(ItemCell.make(it, false, true, false, 80))
	await wait(0.6)
	await shot("items-" + c)


## xem thử dáng nhảy: mỗi lớp 2 bộ áo x (đứng + 4 khung nhảy), kèm mũ/áo choàng/cánh
func preview_jump() -> void:
	var cv = CanvasLayer.new()
	cv.layer = 100
	get_tree().root.add_child(cv)
	var bg = ColorRect.new()
	bg.color = Color("2a3d5c")
	bg.size = Vector2(1400, 900)
	cv.add_child(bg)
	var root = Node2D.new()
	cv.add_child(root)
	var cl = ["sword", "archer", "mage", "fighter"]
	var sets = [[0, -1, -1, -1], [3, 2, 2, 1]]
	if OS.get_environment("HSNC_SET") != "":
		sets = [[1, 0, -1, -1], [4, 3, 3, 3]]
	for r in 4:
		for c in 10:
			var st = sets[c / 5]
			var h = Hero.new()
			h.cls = cl[r]
			h.look = st[0] + 5 * (st[1] + 1) + 25 * (st[2] + 1)
			h.wing = st[3]
			if OS.get_environment("HSNC_PREVIEW") == "die":
				h.die_force = c % 5 - 1
			else:
				h.jump_force = c % 5 - 1
				h.air = c % 5 > 0
			h.nm = ""
			h.position = Vector2(80 + c * 128, 175 + r * 205)
			h.scale = Vector2(1.25, 1.25)
			root.add_child(h)
	for k in 2:
		await wait(0.2)
		await shot("jump-%d" % k)


## xem thử dáng leo thang: 4 lớp x 5 bộ áo, kèm mũ/áo choàng/cánh khác nhau (không cần máy chủ)
func preview_climb() -> void:
	var cv = CanvasLayer.new()
	cv.layer = 100
	get_tree().root.add_child(cv)
	var bg = ColorRect.new()
	bg.color = Color("2a3d5c")
	bg.size = Vector2(1400, 900)
	cv.add_child(bg)
	var root = Node2D.new()
	cv.add_child(root)
	var cl = ["sword", "archer", "mage", "fighter"]
	var hs: Array = []
	for r in 4:
		for c in 10:
			var h = Hero.new()
			h.cls = cl[r]
			var a = c % 5
			var hat = -1 if c < 5 else (c - 5) % 4
			var cape = -1 if c < 5 else (c - 4) % 4
			if c == 9:
				hat = 3
				cape = 3
			h.look = a + 5 * (hat + 1) + 25 * (cape + 1)
			h.climb = true
			h.face = -1 if c % 2 == 1 else 1
			h.moving = true
			h.wing = -1 if c < 7 else c - 6
			h.nm = "%s %d" % [cl[r], c]
			h.position = Vector2(70 + c * 128, 150 + r * 190)
			h.scale = Vector2(1.25, 1.25)
			root.add_child(h)
			hs.append(h)
	for k in 4:
		await wait(0.15)
		await shot("climb-%d" % k)
	for h in hs:
		h.climb = false
		h.moving = false
	await wait(0.2)
	await shot("climb-normal")


## ảnh mới: leo thang thật ở làng (thang x 330), rồi dựng tại chỗ cổng các khu trùm và thang/dây các bản đồ
func tour_art(g: Game) -> void:
	main.hud.visible = false
	print("bắt đầu x=%d y=%d" % [g.me.position.x, g.me.position.y])
	var t0 = Time.get_ticks_msec()
	while absf(g.me.position.x - 330) > 3 and Time.get_ticks_msec() - t0 < 15000:
		g.joy = Vector2(signf(330 - g.me.position.x), 0)
		await wait(0.02)
	g.joy = Vector2.ZERO
	await wait(0.3)
	g.jump()
	await wait(0.2)
	g.joy = Vector2(0, -1)
	for k in 4:
		await wait(0.13)
		await shot("art-leo-%d" % k)
	print("leo=%s y=%d" % [str(not g.climb.is_empty()), g.me.position.y])
	g.joy = Vector2.ZERO
	await wait(1.5)
	var items = [[1, 2860], [2, 3400], [3, 2700], [4, 2480], [5, 2900], [6, 2600], [2, 2800], [4, 4020], [5, 2600], [5, 3800], [6, 1030]]
	for it in items:
		var i: int = it[0]
		var x: float = it[1]
		var M: Dictionary = Data.D.maps[i]
		g._build_map({"m": i, "k": 1, "x": x, "y": Data.floor_y(M, x, -100.0), "mons": [], "drops": []})
		g.warping = true
		g.me.visible = false
		if i == 3 and x == 2700:
			await wait(0.35)
			await shot("art-loading")
		await wait(1.5)
		await shot("art-m%d-%d" % [i, int(x)])
	# leo thử ngay trên bản đồ dựng tại chỗ (thang Rừng Tuyết x 2600, bãi biển thang tre x 3140)
	for lad in [[2, [2600, 360, 600, "ladder"]], [5, [3140, 280, 600, "ladder"]], [4, [4020, 380, 600, "rope"]]]:
		var M2: Dictionary = Data.D.maps[lad[0]]
		var q: Array = lad[1]
		g._build_map({"m": lad[0], "k": 1, "x": float(q[0]), "y": 560.0, "mons": [], "drops": []})
		g.me.visible = true
		g.warping = false
		await wait(0.8)
		g.me.position = Vector2(float(q[0]), 560)
		var lk = int(OS.get_environment("HSNC_LOOK")) if OS.get_environment("HSNC_LOOK") != "" else -1
		if lk >= 0:
			g.me.look = lk
			g.me.wing = int(OS.get_environment("HSNC_WING"))
			g.me.cls = OS.get_environment("HSNC_CLS2")
		g.climb = q
		g.joy = Vector2(0, -1)
		for k in 3:
			await wait(0.12)
			print("leo: climb=%s me.climb=%s y=%d" % [str(not g.climb.is_empty()), str(g.me.climb), g.me.position.y])
			g.me.climb = true
			g.me.moving = true
			await shot("art-c%d-%d" % [lad[0], k])
		g.joy = Vector2.ZERO


## xem to: mỗi lớp 4 mũ, khi leo (trên) và khi đứng (dưới), phóng 3 lần
func preview_big() -> void:
	var cv = CanvasLayer.new()
	cv.layer = 100
	get_tree().root.add_child(cv)
	var bg = ColorRect.new()
	bg.color = Color("2a3d5c")
	bg.size = Vector2(1600, 1100)
	cv.add_child(bg)
	var root = Node2D.new()
	cv.add_child(root)
	var cl = ["sword", "archer", "mage", "fighter"] if OS.get_environment("HSNC_ROWS") == "" else OS.get_environment("HSNC_ROWS").split(",")
	var hs: Array = []
	for r in cl.size():
		for c in 8:
			var h = Hero.new()
			h.cls = cl[r]
			var hat = c % 4
			h.look = (c % 4 + 1) % 5 + 5 * (hat + 1)
			var side = OS.get_environment("HSNC_SIDE") != ""
			h.climb = c < 4 and not side
			h.moving = c < 4 and not side
			if side:
				# 0..3: mũ 0..3 đứng yên, 4..7: mũ 0..3 đang chạy; không áo choàng
				h.look = 2 + 5 * (c % 4 + 1)
				h.moving = c >= 4
			h.nm = ""
			h.position = Vector2(95 + c * 195, 215 + r * 238)
			h.scale = Vector2(2.3, 2.3)
			root.add_child(h)
			hs.append(h)
	for k in 4:
		await wait(0.14)
		await shot("big-%d" % k)


## xem thử pet (4 loài x 3 giai đoạn, các động tác), Ma Long, bảng Bà Ấp Trứng (không cần máy chủ)
func preview_pets() -> void:
	var cv = CanvasLayer.new()
	cv.layer = 100
	get_tree().root.add_child(cv)
	var bg = ColorRect.new()
	bg.color = Color("2a3d5c")
	bg.size = Vector2(1400, 900)
	cv.add_child(bg)
	var root = Node2D.new()
	cv.add_child(root)
	var sps = ["fire", "ice", "wolf", "turtle"]
	var acts = [[0, ""], [0, "run"], [0, "atk"], [0, "cast"], [3, ""], [1, ""], [1, "cast"], [2, ""], [2, "cast"]]
	var pets = []
	for r in 4:
		for c in acts.size():
			var p = Pet.new()
			var a = acts[c]
			var st = a[0] if a[0] < 3 else 0
			p.setup([r, sps[r], st, 70 + c * 120, 120 + r * 110, 1, 3 if a[0] == 3 else 0, 0.6, "Pet " + sps[r], [5, 45, 85][st], 0])
			p.mine = r == 0
			root.add_child(p)
			pets.append([p, a[1]])
	var ms = []
	var x = 100
	for an in ["idle", "claw", "breath", "ult", "die"]:
		var m = Mon.new()
		m.setup({"id": 900 + ms.size(), "type": "malong", "lv": 45, "hpMax": 1000, "hp": 500 if an != "idle" else 1000, "x": x, "y": 760})
		m.scale = Vector2(0.5, 0.5)
		root.add_child(m)
		ms.append([m, an])
		x += 230
	var dl = Mon.new()
	dl.setup({"id": 950, "type": "dragonling", "lv": 40, "hpMax": 100, "x": 1220, "y": 760})
	root.add_child(dl)
	for k in 3:
		for q in pets:
			if q[1] == "run":
				q[0].target = q[0].position + Vector2(5, 0)
			elif q[1] != "":
				q[0].play(q[1], 0.9)
				q[0].anim_t = 0.25 + k * 0.25
		for q in ms:
			if q[1] == "die":
				q[0].flags = 1
				q[0].die_t = 0.3 + k * 0.4
			elif q[1] != "idle":
				q[0].play(q[1], 1.2)
				q[0].anim_t = 0.3 + k * 0.3
		await wait(0.05)
		await shot("pets-%d" % k)
	# làng: Bà Ấp Trứng + tổ đang ấp (trứng đã sẵn sàng nở)
	root.queue_free()
	var vw = SubViewport.new()
	vw.size = Vector2i(1400, 900)
	var vc = SubViewportContainer.new()
	vc.size = Vector2(1400, 900)
	cv.add_child(vc)
	vc.add_child(vw)
	var cam = Camera2D.new()
	cam.position = Vector2(1070, 420)
	vw.add_child(cam)
	cam.make_current()
	var wd = World.new()
	vw.add_child(wd)
	wd.setup(0)
	wd.hatch = {"sp": "fire", "end": Data.now_ms() - 1000}
	wd.near_npc = "egg"
	await wait(0.4)
	await shot("pets-village")
	vc.queue_free()
	# bảng NPC (hiển thị bằng dữ liệu giả)
	var g = Game.new()
	var now = Data.now_ms()
	g.me_data = {"lv": 50, "gold": 3000000, "stones": 3, "cls": "sword", "inv": [{"id": "e1", "slot": "egg", "sp": "ice", "name": "Trứng Cáo Băng", "r": 3, "lvl": 1, "st": {}}],
		"eq": {}, "hatch": {"sp": "wolf", "start": now - 3600e3, "end": now + 5 * 3600e3, "cut": 0}, "petOn": "p1", "pet": {"hp": 300, "maxHp": 420, "faint": 0, "lv": 42},
		"pets": [{"id": "p1", "sp": "fire", "name": "Lửa Nhỏ", "lv": 42, "exp": 1200, "need": 9000, "star": 4, "rn": 1, "stage": 1, "pt": {"hp": 20, "atk": 70, "def": 15, "aspd": 10, "crit": 11},
			"st": {"maxHp": 1400, "atk": 160.2, "def": 40.1, "aspd": 1.14, "crit": 0.07}},
			{"id": "p2", "sp": "turtle", "name": "Rùa Ngọc", "lv": 8, "exp": 50, "need": 400, "star": 1, "rn": 0, "stage": 0, "pt": {"hp": 14, "atk": 3, "def": 4, "aspd": 2, "crit": 1},
			"st": {"maxHp": 300, "atk": 20.0, "def": 9.0, "aspd": 1.02, "crit": 0.03}}]}
	var n = Npc.new()
	cv.add_child(n)
	n.setup(g)
	n.open("pets")
	n.free_arm = "p2"
	n.free_at = Time.get_ticks_msec() / 1000.0 + 3.0
	n.render()
	await wait(0.3)
	await shot("pets-npc1")
	n.free_arm = ""
	n.open("egg")
	await wait(0.3)
	await shot("pets-npc2")
	g.me_data.hatch = null
	n.render()
	await wait(0.2)
	await shot("pets-npc3")


func _process(dt: float) -> void:
	_fmax = max(_fmax, dt * 1000.0)
	_fn += 1

## đo giật: tới bản đồ có Cá Kiếm, đứng cho quái đánh, nhảy từ trên cao; in khung hình chậm nhất, FPS, ping mỗi giây
## (cần máy chủ thử có lệnh devtp/devlv — chỉ bản chạy cục bộ)
func perf_test() -> void:
	var u = "pf%d" % (Time.get_unix_time_from_system() as int % 100000)
	await Net.login(u, "matkhau1", true)
	main.show_servers()
	await wait(1.0)
	main.enter(1)
	await wait(2.0)
	Net.send({"t": "create", "name": "Pf " + u.substr(2), "cls": "sword"})
	await wait(2.5)
	Net.message.connect(func(m): if m.get("t") == "pos": _pos_n += 1)
	var g: Game = main.game
	Net.send({"t": "devlv", "lv": int(OS.get_environment("HSNC_LV")) if OS.get_environment("HSNC_LV") != "" else 22})
	Net.send({"t": "devtp", "map": int(OS.get_environment("HSNC_MAP")) if OS.get_environment("HSNC_MAP") != "" else 6, "x": int(OS.get_environment("HSNC_X")) if OS.get_environment("HSNC_X") != "" else 1650, "y": int(OS.get_environment("HSNC_Y")) if OS.get_environment("HSNC_Y") != "" else 0})
	await wait(3.0)
	if OS.get_environment("HSNC_CTL") != "":
		Data.set_setting("ctl", OS.get_environment("HSNC_CTL"))
		main.hud._build_controls()
	if OS.get_environment("HSNC_AUTO") != "":
		g.set_auto(true)
	await shot("perf-0")
	if OS.get_environment("HSNC_UI") != "":
		# chọn quái gần nhất bằng nút đổi mục tiêu, rồi chọn một đồ rơi giả, mở các bảng mới
		g.next_target()
		await wait(0.5)
		await shot("ui-sel")
		var fd = {"id": 999999, "k": "gold", "n": 120, "x": g.me.position.x + 120, "y": g.me.position.y, "own": 12345, "lk": 50}
		var o = Drop.new()
		o.setup(fd)
		g.ents.add_child(o)
		g.drops[o.id] = o
		g.set_sel("drop", o)
		g.go_pick(o)
		await wait(0.6)
		await shot("ui-drop")
		main.hud.open_auto()
		await wait(0.5)
		await shot("ui-auto")
		main.hud.open_auto()
		main.open_bag()
		main.bag.tab = "skill"
		main.bag.render()
		await wait(0.5)
		await shot("ui-skill")
		main.bag.sk_ask = true
		main.bag.render()
		await wait(0.3)
		await shot("ui-skill2")
		main.bag.close()
		g.open_npc.emit("shop")
		await wait(0.8)
		await shot("ui-shop")
		main.npc.tab = "pots"
		main.npc.render()
		await wait(0.5)
		await shot("ui-pots")
	var secs = int(OS.get_environment("HSNC_SECS")) if OS.get_environment("HSNC_SECS") != "" else 20
	for i in secs:
		_fmax = 0.0
		_fn = 0
		if OS.get_environment("HSNC_PROF") != "":
			var parts = [null, g.world, g.ents, g.fx, main.hud]
			for k in parts.size():
				if parts[k]:
					parts[k].visible = k != int(i / 3)
		if OS.get_environment("HSNC_JUMP") != "" and i % 3 == 0:
			g.jump()
		if OS.get_environment("HSNC_WALK") != "":
			g.joy = Vector2(1 if (i / 4) % 2 == 0 else -1, 0)
			if OS.get_environment("HSNC_WALK") == "fall":
				g.joy = Vector2(1, 0) if i >= 1 and i <= 3 else Vector2.ZERO
		await wait(1.0)
		print("PERF t=%d fps=%d maxframe=%dms proc=%.1fms ping=%d pos=%d hp=%s x=%d y=%d draws=%d tex=%dMB" % [i, _fn, int(_fmax), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Net.ping_ms, _pos_n, str(g.me_data.get("hp")), int(g.me.position.x), int(g.me.position.y),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576)])
		if OS.get_environment("HSNC_AUTO") != "":
			print("AUTO focus=%s fx=%s skip=%d mto=%d drops=%d" % [str(g.focus.id) if g.focus else "-", str(int(g.focus.position.x)) + "," + str(int(g.focus.position.y)) if g.focus else "", g.auto_skip.size(), int(g.move_to), g.drops.size()])
		if i == 2 and OS.get_environment("HSNC_DIE") != "":
			Net.send({"t": "devdie"})
		if i == 4:
			Net.send({"t": "chat", "text": "Xin chào cả nhà, ai đi săn cua không?"})
			main.hud.chat({"all": true, "n": "Long", "text": "Ma Long sắp xuất hiện, ai đi cùng không?"})
		if i == 6:
			await shot("perf-1")
