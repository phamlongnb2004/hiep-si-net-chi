extends Node
## Chạy thử tự động (chỉ khi mở với tham số "-- autotest=<thư mục ảnh>"): đăng ký, vào máy chủ, tạo nhân vật,
## đi, đánh quái, mở túi đồ, chụp màn hình từng bước. Dùng để kiểm tra bản dựng thật trên máy.

var main: Node
var out := "user://shots"
var step := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("autotest="):
			out = a.substr(9)
	DirAccess.make_dir_recursive_absolute(out)
	run()

func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(n + ".png"))
	print("ẢNH ", n)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func run() -> void:
	await wait(1.5)
	main = get_tree().root.get_node_or_null("Main")
	await shot("01-login")
	var u := "bot%d" % (Time.get_unix_time_from_system() as int % 100000)
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
	var g: Game = main.game
	# đi sang phải tới cổng
	g.joy = Vector2(1, 0)
	await wait(4.0)
	await shot("05-walk")
	var tw0 := Time.get_ticks_msec()
	var lx := 0.0
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
	var t0 := Time.get_ticks_msec()
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
	main.bag.close()
	print("XONG cấp=", g.me_data.get("lv"), " vàng=", g.me_data.get("gold"), " túi=", g.me_data.get("inv", []).size())
	get_tree().quit()
