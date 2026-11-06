extends Node2D
class_name Game
## Màn chơi: dựng bản đồ, nhân vật mình (tự đi, nhảy ngay trên máy để mượt; máy chủ kiểm tra lại vị trí),
## người chơi khác và quái theo ảnh chụp 10 lần/giây từ máy chủ, hiệu ứng theo sự kiện.

signal me_changed
signal log_line(text: String, col: Color)
signal npc_near(id: String)
signal open_npc(id: String)
signal map_changed(name: String)
signal player_tapped(id: int, name: String)
signal announce(text: String)
signal cfg_changed
signal gm_reply(m: Dictionary)

const GRAV := 2100.0
const JUMP := 760.0
const SEND_DT := 0.1

var world: World
var ents: Node2D
var fx: Fx
var cam: Camera2D
var me: Hero
var my_id = 0
var staff = ""                # vai trò quản trị của tài khoản này (rỗng = người chơi)
var me_data: Dictionary = {}     # tin 'me' (chỉ số, túi đồ...) do máy chủ gửi
var heroes = {}                 # id -> Hero (người khác)
var mons = {}                   # id -> Mon
var drops = {}                  # id -> Drop
var mi = -1
var M: Dictionary = {}
var ready_map = false

# điều khiển
var joy = Vector2.ZERO          # từ cần điều khiển trên màn hình
var atk_held = false
var jump_q = 0.0
var vy = 0.0
var air = false
var focus: Mon = null
var move_to = -1.0
var npc_go = ""
var send_t = 0.0
var atk_t = 0.0
var cds = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var gcd = 0.0
var pot_cd = 0.0
const POT_CD = 3.0
var warping = false
var near_npc = ""
var fade = 0.0
var last_sent = Vector3.ZERO

func _ready() -> void:
	world = World.new()
	world.name = "World"
	add_child(world)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	fx = Fx.new()
	fx.name = "Fx"
	add_child(fx)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9
	add_child(cam)
	cam.make_current()
	me = Hero.new()
	me.is_me = true
	ents.add_child(me)
	Net.message.connect(_on_msg)
	get_viewport().size_changed.connect(_zoom)
	_zoom()

func _zoom() -> void:
	var h = get_viewport_rect().size.y
	var z = clampf(h / 700.0, 0.5, 1.1)
	cam.zoom = Vector2(z, z)

func cls() -> String:
	return str(me_data.get("cls", "sword"))

## ---------- tin từ máy chủ ----------
func _on_msg(m: Dictionary) -> void:
	match str(m.get("t")):
		"welcome":
			my_id = int(m.id)
			staff = str(m.get("staff", ""))
			if m.get("cfg") is Dictionary:
				_set_cfg(m.cfg)
			if m.get("me") is Dictionary:
				_set_me(m.me, true)
		"me":
			_set_me(m.me, int(m.get("full", 0)) == 1)
		"map":
			_build_map(m)
		"snap":
			if ready_map:
				_snap(m)
		"pos":
			me.position = Vector2(m.x, m.y)
			vy = 0
			if m.get("respawn"):
				fx.text(me.position + Vector2(0, -90), "Hồi sinh", Color("8fb4ff"), true)
		"gain":
			var mo: Mon = mons.get(int(m.m))
			var p: Vector2 = mo.position if mo else me.position
			fx.text(p + Vector2(0, -110), "+%d EXP" % int(m.exp), Color("8fb4ff"))
			fx.text(p + Vector2(18, -90), "+%d vàng" % int(m.gold), Color("ffd23f"))
		"log":
			log_line.emit(str(m.text), Color.html(str(m.get("col", "#ffffff"))))
		"cfg":
			if m.get("cfg") is Dictionary:
				_set_cfg(m.cfg)
		"ann":
			announce.emit(str(m.get("text", "")))
		"gm":
			gm_reply.emit(m)
		"res":
			if m.get("msg"):
				log_line.emit(str(m.msg), Color("9be05a") if m.get("ok") else Color("ffb347"))
			if m.get("op") == "warp":
				warping = false

func _set_cfg(c: Dictionary) -> void:
	Data.cfg = c
	if c.get("ann") is Dictionary:
		announce.emit(str(c.ann.get("text", "")))
	cfg_changed.emit()
	me_changed.emit()

func _set_me(d: Dictionary, full: bool) -> void:
	if full:
		me_data = d.duplicate(true)
	else:
		for k in d:
			me_data[k] = d[k]
	me.cls = cls()
	me.nm = str(me_data.get("name", ""))
	me.lv = int(me_data.get("lv", 1))
	me.dead = int(me_data.get("dead", 0)) == 1
	var sc: Array = me_data.get("cds", [])
	for i in mini(6, sc.size()):
		cds[i] = float(sc[i])
	gcd = float(me_data.get("gcd", 0))
	pot_cd = max(pot_cd, float(me_data.get("potCd", 0)))
	me.look = _look(me_data)
	me_changed.emit()

func _look(d: Dictionary) -> int:
	var eq: Dictionary = d.get("eq", {}) if d.get("eq") is Dictionary else {}
	var c = str(d.get("cls", ""))
	var tf = func(s: String) -> int:
		var it = eq.get(s)
		return clampi(int(it.get("tier", 0)), 0, 3) if it is Dictionary and str(it.get("cls", "")) == c else -1
	return (tf.call("armor") + 1) + 5 * (tf.call("hat") + 1) + 25 * (tf.call("cape") + 1)

func _build_map(m: Dictionary) -> void:
	mi = int(m.m)
	M = Data.D.maps[mi]
	world.setup(mi)
	for h in heroes.values(): h.queue_free()
	for x in mons.values(): x.queue_free()
	for x in drops.values(): x.queue_free()
	heroes.clear(); mons.clear(); drops.clear()
	fx.projs.clear(); fx.sprs.clear(); fx.breaths.clear()
	for info in m.mons:
		var mo = Mon.new()
		mo.setup(info)
		ents.add_child(mo)
		mons[mo.id] = mo
	for d in m.drops:
		_add_drop(d)
	me.position = Vector2(m.x, m.y)
	vy = 0
	focus = null
	move_to = -1
	warping = false
	fade = 1.0
	cam.limit_left = 0
	cam.limit_right = int(M.w)
	cam.limit_top = -400
	cam.limit_bottom = 720
	cam.position = me.position
	cam.reset_smoothing()
	ready_map = true
	map_changed.emit(str(M.name))

func _add_drop(d: Dictionary) -> void:
	var o = Drop.new()
	o.setup(d)
	ents.add_child(o)
	drops[o.id] = o

func _snap(m: Dictionary) -> void:
	var seen = {}
	for q in m.p:
		var id = int(q[0])
		if id == my_id:
			continue
		seen[id] = true
		var h: Hero = heroes.get(id)
		if h == null:
			h = Hero.new()
			h.position = Vector2(q[1], q[2])
			ents.add_child(h)
			heroes[id] = h
		h.set_meta("tp", Vector2(q[1], q[2]))
		h.face = int(q[3])
		h.moving = int(q[4]) == 1
		h.cls = str(q[6])
		h.lv = int(q[7])
		h.nm = str(q[8])
		h.hp = float(q[9])
		h.dead = int(q[10]) == 1
		h.look = int(q[11])
		h.air = q.size() > 12 and int(q[12]) == 1
	for id in heroes.keys():
		if not seen.has(id):
			heroes[id].queue_free()
			heroes.erase(id)
	for q in m.m:
		var mo: Mon = mons.get(int(q[0]))
		if mo == null:
			continue
		mo.target = Vector2(q[1], q[2])
		mo.hp = float(q[3])
		mo.flags = int(q[5])
		if mo.br_t < 0:
			mo.face = int(q[4])
	for e in m.e:
		_event(e)

func _who(id: int) -> Node2D:
	return me if id == my_id else heroes.get(id)

func _event(e: Array) -> void:
	match str(e[0]):
		"h":   # quái trúng đòn: id, sát thương, cờ (1 chí mạng, 2 độc), người đánh
			var mo: Mon = mons.get(int(e[1]))
			if mo:
				mo.hit_t = 0.18
				var crit = int(e[3]) & 1 == 1
				var dot = int(e[3]) & 2 == 2
				if int(e[4]) == my_id and not dot:
					fx.hit_spark(mo.position + Vector2(0, -float(Mon.MH.get(mo._k, 80)) * 0.4), crit)
				if int(e[4]) == my_id or crit:
					fx.text(mo.position + Vector2(0, -float(Mon.MH.get(mo._k, 80)) * 0.9), str(int(e[2])) + ("!" if crit else ""),
						Color("7ddc5a") if dot else (Color("ffb300") if crit else Color.WHITE), crit)
		"p":   # người chơi mất máu
			var w = _who(int(e[1]))
			if w:
				w.flash = 0.25
				fx.text(w.position + Vector2(0, -80), "-%d" % int(e[2]), Color("ff5d7d"), int(e[1]) == my_id)
		"pm":  # người chơi né được đòn
			var wm = _who(int(e[1]))
			if wm:
				fx.text(wm.position + Vector2(0, -80), "Né!", Color("b9a8ff"), int(e[1]) == my_id)
		"ph":
			var w2 = _who(int(e[1]))
			if w2:
				fx.text(w2.position + Vector2(0, -80), "+%d" % int(e[2]), Color("5fe08c"), true)
		"a":   # người chơi đánh thường
			var w3 = _who(int(e[1]))
			if w3 and int(e[1]) != my_id:
				w3.swing = 1.0
				fx.basic(w3.cls, w3, float(e[2]), int(e[3]) == 1)
				_swing(w3)
		"s":   # dùng kỹ năng: người, số, hướng, mục tiêu
			var w4 = _who(int(e[1]))
			if w4 and int(e[1]) != my_id:
				_swing(w4)
				fx.skill(w4.cls, int(e[2]), w4, float(e[3]), mons.get(int(e[4])), w4.face)
		"nm":  # quái mới (quản trị gọi ra)
			if e[1] is Dictionary and not mons.has(int(e[1].id)):
				var nmo = Mon.new()
				nmo.setup(e[1])
				ents.add_child(nmo)
				mons[nmo.id] = nmo
		"rm":  # quái bị xóa hẳn
			var rmo: Mon = mons.get(int(e[1]))
			if rmo:
				if focus == rmo:
					focus = null
				rmo.queue_free()
				mons.erase(int(e[1]))
		"k":
			var mo2: Mon = mons.get(int(e[1]))
			if mo2:
				mo2.flags |= 1
				mo2.die_t = 0.0
				if focus == mo2:
					focus = null
		"r":
			var mo3: Mon = mons.get(int(e[1]))
			if mo3:
				mo3.flags = 0
				mo3.die_t = -1.0
				if e.size() > 5:
					mo3.elite = int(e[4]) == 1
					mo3.hp_max = float(e[5])
				mo3.hp = mo3.hp_max
				mo3.position = Vector2(e[2], e[3])
				mo3.target = mo3.position
		"ma":  # quái vồ
			var mo4: Mon = mons.get(int(e[1]))
			var w5 = _who(int(e[2]))
			if mo4:
				mo4.lunge = 0.25
				if w5:
					fx.mon_hit(mo4._k, w5.position, 1 if w5.position.x >= mo4.position.x else -1)
		"b":   # rồng khạc
			var mo5: Mon = mons.get(int(e[1]))
			if mo5:
				mo5.br_t = 0.0
				mo5.face = 1 if (_who(int(e[2])) and _who(int(e[2])).position.x >= mo5.position.x) else -1
				fx.breath(mo5, _who(int(e[2])), mo5.type)
		"d":
			_add_drop(e[1])
		"g", "x":
			var d: Drop = drops.get(int(e[1]))
			if d:
				d.queue_free()
				drops.erase(int(e[1]))
		"lv":
			var w6 = _who(int(e[1]))
			if w6:
				fx.text(w6.position + Vector2(0, -120), "LÊN CẤP %d!" % int(e[2]), Color("ffd23f"), true)

func _swing(h: Hero) -> void:
	h.swing = 1.0
	var tw = create_tween()
	tw.tween_property(h, "swing", 0.0, 0.3)

## ---------- điều khiển nhân vật mình ----------
func _wall(x: float, y: float) -> bool:
	return world.gy(x) < y - 3

func _move_x(nx: float) -> bool:
	nx = clampf(nx, 40, float(M.w) - 40)
	if _wall(nx, me.position.y):
		return false
	me.position.x = nx
	return true

func nearest_mon(r: float) -> Mon:
	var b: Mon = null
	var bd = r
	for mo in mons.values():
		if mo.dead():
			continue
		var d = me.position.distance_to(mo.position) - float(mo._info.get("r", 30))
		if d < bd:
			bd = d
			b = mo
	return b

func can_act() -> bool:
	return ready_map and Net.online() and not me.dead and not warping

func do_attack() -> void:
	if not can_act() or atk_t > 0:
		return
	var c: Dictionary = Data.D.cls[cls()]
	atk_t = float(c.cd)
	var tg: Mon = focus if focus and not focus.dead() else nearest_mon(float(c.reach) + 20)
	var aim = atan2(tg.position.y - me.position.y, tg.position.x - me.position.x) if tg else (0.0 if me.face > 0 else PI)
	me.face = 1 if cos(aim) >= 0 else -1
	Net.send({"t": "atk", "tg": tg.id if tg else 0})
	_swing(me)
	fx.basic(cls(), me, aim, false)

func do_skill(i: int) -> void:
	if not can_act():
		return
	var sk: Array = me_data.get("sk", [])
	var S: Dictionary = Data.D.skills[cls()][i]
	if i >= sk.size() or int(sk[i]) == 0:
		log_line.emit("Chưa học " + str(S.n) + (" (cần cấp %d)" % int(S.req) if int(me_data.get("lv", 1)) < int(S.req) else " — mua sách ở Thương Nhân trong Làng"), Color("ffb347"))
		return
	if cds[i] > 0.05 or gcd > 0.05:
		return
	cds[i] = float(S.cd)
	gcd = float(Data.D.world.gcd)
	var tg: Mon = focus if focus and not focus.dead() else nearest_mon(460)
	var aim = atan2(tg.position.y - me.position.y, tg.position.x - me.position.x) if tg else (0.0 if me.face > 0 else PI)
	me.face = 1 if cos(aim) >= 0 else -1
	Net.send({"t": "sk", "i": i, "tg": tg.id if tg else 0})
	_swing(me)
	fx.skill(cls(), i, me, aim, tg, me.face)

func do_pot() -> void:
	# bình máu có thời gian hồi để không bấm liên tục được
	if can_act() and pot_cd <= 0.05:
		pot_cd = POT_CD
		Net.send({"t": "pot"})

func jump() -> void:
	jump_q = 0.15

## chạm/nhấp vào thế giới: chọn quái, đi tới NPC hoặc đi tới chỗ đó
func tap_world(screen_pos: Vector2) -> void:
	if not can_act():
		return
	var wp = get_canvas_transform().affine_inverse() * screen_pos
	var best: Mon = null
	var bd = 90.0
	for mo in mons.values():
		if mo.dead():
			continue
		var c = mo.position + Vector2(0, -float(Mon.MH.get(mo._k, 80)) * 0.4)
		var d = c.distance_to(wp)
		if d < bd:
			bd = d
			best = mo
	# người chơi khác gần chỗ chạm hơn quái: mở menu kết bạn / giao dịch
	var hb = null
	var hd = 70.0
	for id in heroes:
		var h: Hero = heroes[id]
		var d2 = (h.position + Vector2(0, -36)).distance_to(wp)
		if d2 < hd:
			hd = d2
			hb = id
	if hb != null and (best == null or hd < bd):
		player_tapped.emit(int(hb), heroes[hb].nm)
		return
	if best:
		focus = best
		move_to = -1
		return
	for n in M.get("npcs", []):
		if absf(wp.x - n.x) < 70 and wp.y > n.y - 170 and wp.y < n.y + 20:
			npc_go = str(n.id)
			move_to = n.x
			focus = null
			return
	focus = null
	move_to = wp.x

func _process(dt: float) -> void:
	fade = max(0.0, fade - dt * 2)
	if not ready_map:
		return
	atk_t = max(0.0, atk_t - dt)
	gcd = max(0.0, gcd - dt)
	pot_cd = max(0.0, pot_cd - dt)
	for i in 6:
		cds[i] = max(0.0, cds[i] - dt)
	for mo in mons.values():
		mo.focused = mo == focus
	for h in heroes.values():
		var tp: Vector2 = h.get_meta("tp", h.position)
		h.position = h.position.lerp(tp, min(1.0, dt * 12)) if h.position.distance_to(tp) < 300 else tp
	_control(dt)
	cam.position = me.position + Vector2(0, -60)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (fx.shake * 40.0) if fx.shake > 0 else Vector2.ZERO
	# NPC gần
	var nn = ""
	for n in M.get("npcs", []):
		if absf(me.position.x - n.x) < 115:
			nn = str(n.id)
	if nn != near_npc:
		near_npc = nn
		world.near_npc = nn
		npc_near.emit(nn)
	if npc_go != "" and npc_go == near_npc:
		npc_go = ""
		move_to = -1
		open_npc.emit(near_npc)

func _control(dt: float) -> void:
	var p = me.position
	if not can_act():
		me.moving = false
		return
	var ix = joy.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): ix += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): ix -= 1
	var manual = absf(ix) > 0.18
	if manual:
		focus = null
		move_to = -1
		npc_go = ""
	if focus and focus.dead():
		focus = null
	var dx = 0.0
	var in_reach = false
	var c: Dictionary = Data.D.cls[cls()]
	if manual:
		dx = clampf(ix, -1, 1)
	elif focus:
		var ddx = focus.position.x - p.x
		var need = float(c.reach) - 10 + float(focus._info.get("r", 30)) * 0.5
		if absf(ddx) > need * 0.9:
			dx = signf(ddx)
		elif absf(focus.position.y - p.y) < 120 or float(c.reach) > 200:
			in_reach = true
	elif move_to >= 0:
		var d2 = move_to - p.x
		if absf(d2) > 8:
			dx = signf(d2)
		else:
			move_to = -1
	jump_q = max(0.0, jump_q - dt)
	if jump_q > 0 and not air:
		vy = -JUMP
		air = true
		jump_q = 0
	# trọng lực
	var g0 = world.gy(p.x)
	vy += GRAV * dt
	var ny = me.position.y + vy * dt
	if vy >= 0:
		if ny >= g0:
			ny = g0
			vy = 0
		elif not air and g0 - ny < 20:
			ny = g0
			vy = 0
	me.position.y = ny
	air = not (vy == 0 and absf(me.position.y - world.gy(me.position.x)) < 1)
	var spd = float(me_data.get("spd", c.spd))
	for b in me_data.get("buffs", []):
		if b.get("id") in ["roll", "rage"]:
			spd *= 1.35 if b.id == "roll" else 1.25
	me.moving = dx != 0
	if me.moving:
		var s = spd * (0.85 if me.swing > 0 else 1.0) * (0.92 if air else 1.0)
		if not _move_x(me.position.x + dx * s * dt) and not manual and not air and world.gy(me.position.x + dx * 24) > me.position.y - 125:
			jump_q = 0.15
		if not focus:
			me.face = 1 if dx > 0 else -1
	if air:
		me.moving = true
	me.air = air
	if focus and absf(focus.position.x - me.position.x) > 4:
		me.face = 1 if focus.position.x > me.position.x else -1
	if atk_held or in_reach or Input.is_key_pressed(KEY_J):
		do_attack()
	# cổng: đứng trên đất ở cổng thì xin máy chủ chuyển bản đồ
	if not air and not warping:
		for i in M.portals.size():
			var pt: Dictionary = M.portals[i]
			if absf(me.position.x - pt.x) < 46:
				warping = true
				focus = null
				move_to = -1
				fade = 1.0
				Net.send({"t": "warp", "p": i})
				break
	# gửi vị trí 10 lần/giây (và ngay khi dừng lại)
	send_t -= dt
	var cur = Vector3(round(me.position.x), round(me.position.y), me.face)
	if send_t <= 0 or (cur != last_sent and not me.moving):
		if cur != last_sent or send_t <= -1.0:
			Net.send({"t": "in", "x": me.position.x, "y": me.position.y, "f": me.face, "mv": 1 if me.moving else 0, "air": 1 if air else 0})
			last_sent = cur
		send_t = SEND_DT

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_W, KEY_UP, KEY_SPACE, KEY_K: jump()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6: do_skill(ev.keycode - KEY_1)
			KEY_Q: do_pot()
			KEY_B: get_parent().open_bag()
			KEY_E:
				if near_npc != "":
					open_npc.emit(near_npc)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		tap_world(ev.position)
	elif ev is InputEventScreenTouch and ev.pressed:
		tap_world(ev.position)
