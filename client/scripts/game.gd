extends Node2D
class_name Game
## Màn chơi: dựng bản đồ, nhân vật mình (tự đi, nhảy ngay trên máy để mượt; máy chủ kiểm tra lại vị trí),
## người chơi khác và quái theo ảnh chụp 10 lần/giây từ máy chủ, hiệu ứng theo sự kiện.

signal me_changed
signal bag_changed   # tin 'me' đầy đủ (túi đồ, trang bị, vàng, pet thay đổi)
signal log_line(text: String, col: Color)
signal npc_near(id: String)
signal open_npc(id: String)
signal map_changed(name: String)
signal player_tapped(id: int, name: String)
signal announce(text: String)
signal celebrate(m: Dictionary)
signal bag_full
signal cfg_changed
signal gm_reply(m: Dictionary)
signal khu_list(m: Dictionary)

const GRAV := 2100.0
const JUMP := 820.0   # cao tối đa ~160 (2.9.2; trước 760 ~137)
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
var pos_n = 0                   # số lần máy chủ đặt lại vị trí (gửi kèm 'in' để máy chủ bỏ qua gói cũ)
var pets = {}                   # id chủ -> Pet (cả pet của mình)
var mons = {}                   # id -> Mon
var drops = {}                  # id -> Drop
var mi = -1
var khu = 1                   # khu đang ở trong bản đồ (mỗi khu tối đa 15 người)
var M: Dictionary = {}
var ready_map = false

# điều khiển
var joy = Vector2.ZERO          # từ cần điều khiển trên màn hình
var atk_held = false
var jump_q = 0.0
var vy = 0.0
var climb: Array = []        # đang bám dây/thang: [x, yTrên, yDưới, kiểu]
var drop_t = 0.0              # >0: đang nhảy xuống xuyên bậc nổi
var air = false
var focus: Mon = null
# đối tượng đang chọn (chạm 1 lần): quái, người chơi, NPC hoặc đồ rơi — có tam giác ngược chỉ vào
var sel = null            # Node2D (Mon / Hero / Drop) hoặc Dictionary (NPC)
var sel_kind = ""         # "mon", "hero", "npc", "drop"
var pick_goal = null      # đồ đang chạy tới để nhặt
var pick_t = 0.0
var _tap_t = 0.0
var _tap_p = Vector2.ZERO
signal sel_changed
signal toast(text: String)
var move_to = -1.0
var npc_go = ""
var send_t = 0.0
var kb_rem = 0.0   # quãng bị đánh văng còn lại (trượt dần)
var atk_t = 0.0
var cds = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var gcd = 0.0
var pot_cd = 0.0
var kpot_cd = 0.0
var roll_cd = 0.0
var roll_t = 0.0
var roll_dir = 1
var roll_spd = 890.0
# chiêu lướt (khớp shared/rules.js SKILL_FX dash): phái -> chỉ số chiêu -> [quãng, thời gian, lùi]
const SKILL_DASH := {"sword": {3: [290.0, 0.22, false]}, "archer": {3: [250.0, 0.25, true]}, "fighter": {3: [150.0, 0.18, false]}}
# tự động đánh: bật/tắt, loại quái được chọn (theo bản đồ), nhặt đồ, dùng bình
var auto_on = false
var auto_skip = {}               # id quái bỏ qua tạm (đánh mãi không tới) -> hết hạn (giây)
var auto_fT = 0.0
var auto_fid = 0
var auto_sk = 0
var auto_best = 0.0
var auto_hp0 = 0.0
var auto_hT = 0.0
var auto_did = 0
var auto_dT = 0.0
var nav := {}            # bước đường đi của auto (Nav.plan): nhảy lên thanh, rơi xuống, đi ra mép, leo dây
var nav_phase = 0        # 0 đi tới chỗ bắt đầu, 1 đang nhảy/rơi/leo
var nav_re = 0.0
var nav_n0 = -2
var auto_climb = false
var full_t = -100.0
const POT_CD = 3.0
var warping = false
var near_npc = ""
var fade = 0.0
var loading: LoadScreen    # màn hình tải khi sang bản đồ/khu khác
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
	var sm = SelMark.new()
	sm.g = self
	sm.z_index = 50
	add_child(sm)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9
	add_child(cam)
	cam.make_current()
	me = Hero.new()
	me.is_me = true
	ents.add_child(me)
	loading = LoadScreen.new()
	add_child(loading)
	Net.message.connect(_on_msg)
	get_viewport().size_changed.connect(_zoom)
	_zoom()

func _zoom() -> void:
	var h = get_viewport_rect().size.y
	# điện thoại: màn hình nhỏ nên phóng to cảnh (nhân vật to hơn, thấy ít bản đồ hơn)
	var z = clampf(h / 700.0, 0.5, 1.1) * (1.35 if Data.is_touch() else 1.0)
	cam.zoom = Vector2(z, z)

func cls() -> String:
	return str(me_data.get("cls", "sword"))

## ---------- tin từ máy chủ ----------
func _on_msg(m: Dictionary) -> void:
	match str(m.get("t")):
		"welcome":
			my_id = int(m.id)
			pos_n = 0
			staff = str(m.get("staff", ""))
			if m.get("cfg") is Dictionary:
				_set_cfg(m.cfg)
			if m.get("me") is Dictionary:
				_set_me(m.me, true)
			sync_apick()
		"me":
			_set_me(m.me, int(m.get("full", 0)) == 1)
		"map":
			_build_map(m)
		"snap":
			if ready_map:
				_snap(m)
		"pos":
			if OS.get_environment("HSNC_POSLOG") != "": print("POS ", m, " me=", me.position, " t=", Time.get_ticks_msec())
			pos_n = int(m.get("pn", pos_n + 1))
			if m.get("kb"): pf_kb += 1
			elif not m.get("respawn"): pf_corr += 1
			if m.get("kb") and m.has("dx") and not m.get("respawn"):
				# bị đánh văng: đẩy lùi từ CHỖ MÌNH ĐANG ĐỨNG (trượt trong ~0,15 giây) thay vì kéo về vị trí cũ máy chủ còn giữ
				# (vị trí máy chủ chậm hơn theo độ trễ mạng -> trước đây bị giật lùi cả trăm điểm mỗi lần trúng đòn)
				kb_rem += float(m.dx)
			else:
				me.position = Vector2(m.x, m.y)
			last_sent = Vector3(INF, 0, 0)
			vy = 0
			climb = []
			if m.get("respawn"):
				fx.text(me.position + Vector2(0, -90), "Hồi sinh", Color("8fb4ff"), true)
		"gain":
			var mo: Mon = mons.get(int(m.m))
			var p: Vector2 = mo.position if mo else me.position
			fx.text(p + Vector2(0, -110), "+%d EXP" % int(m.exp), Color("8fb4ff"))
			fx.text(p + Vector2(18, -90), "+%d vàng" % int(m.gold), Color("ffd23f"))
			if int(m.get("pct", 0)) > 0:
				fx.text(p + Vector2(0, -132), "Góp %d%% sát thương" % int(m.pct), Color("ffffff"))
		"log":
			log_line.emit(str(m.text), Color.html(str(m.get("col", "#ffffff"))))
		"cfg":
			if m.get("cfg") is Dictionary:
				_set_cfg(m.cfg)
		"ann":
			announce.emit(str(m.get("text", "")))
		"cele":
			celebrate.emit(m)
		"full":
			pick_goal = null
			# đang auto thì nhắc thưa hơn (20 giây/lần) cho đỡ phiền
			var tn = Time.get_ticks_msec() / 1000.0
			if tn - full_t > (20.0 if auto_on else 2.5):
				full_t = tn
				bag_full.emit()
		"pickno":
			pick_goal = null
			toast.emit("Vật phẩm của người khác. Hiện tại chưa thể nhặt được.")
		"gm":
			gm_reply.emit(m)
		"khu":
			khu_list.emit(m)
		"res":
			if m.get("msg"):
				log_line.emit(str(m.msg), Color("9be05a") if m.get("ok") else Color("ffb347"))
			if m.get("op") == "warp":
				warping = false
				loading.cancel()
			if m.get("op") == "khu" and not m.get("ok"):
				loading.cancel()

func _set_cfg(c: Dictionary) -> void:
	Data.cfg = c
	if c.has("t"):
		Data.clock_off = float(c.t) - Time.get_unix_time_from_system() * 1000.0
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
	if world:
		world.hatch = me_data.get("hatch") if me_data.get("hatch") is Dictionary else null
	var sc: Array = me_data.get("cds", [])
	for i in mini(7, sc.size()):
		cds[i] = float(sc[i])
	gcd = float(me_data.get("gcd", 0))
	pot_cd = max(pot_cd, float(me_data.get("potCd", 0)))
	kpot_cd = max(kpot_cd, float(me_data.get("kpCd", 0)))
	me.look = _look(me_data)
	me.myth = myth_bits(me_data)
	var wg = me_data.get("eq", {}).get("wing") if me_data.get("eq") is Dictionary else null
	me.wing = int(wg.get("r", 0)) if wg is Dictionary else -1
	me.title = str(me_data.get("title", ""))
	me.deb = (1 if float(me_data.get("stun", 0)) > 0 else 0) | (2 if float(me_data.get("slow", 1)) < 1 else 0) | (4 if int(me_data.get("pois", 0)) else 0)
	me_changed.emit()
	if full:
		bag_changed.emit()

## đồ Thần Thoại đang mặc (giống máy chủ sim.js mythN): bit 1 áo, 2 mũ, 4 áo choàng, (số món << 3)
func myth_bits(d: Dictionary) -> int:
	var eq: Dictionary = d.get("eq", {}) if d.get("eq") is Dictionary else {}
	var b = 0
	var n = 0
	for s in eq:
		if Data.is_myth(eq[s]):
			n += 1
	if Data.is_myth(eq.get("armor")): b |= 1
	if Data.is_myth(eq.get("hat")): b |= 2
	if Data.is_myth(eq.get("cape")): b |= 4
	return b | (n << 3)

func _look(d: Dictionary) -> int:
	var eq: Dictionary = d.get("eq", {}) if d.get("eq") is Dictionary else {}
	var c = str(d.get("cls", ""))
	var tf = func(s: String) -> int:
		var it = eq.get(s)
		return clampi(int(it.get("tier", 0)), 0, 3) if it is Dictionary and (str(it.get("cls", "")) == c or Data.is_myth(it)) else -1
	return (tf.call("armor") + 1) + 5 * (tf.call("hat") + 1) + 25 * (tf.call("cape") + 1)

func _build_map(m: Dictionary) -> void:
	mi = int(m.m)
	khu = int(m.get("k", 1))
	M = Data.D.maps[mi]
	world.setup(mi)
	for h in heroes.values(): h.queue_free()
	for x in mons.values(): x.queue_free()
	for x in drops.values(): x.queue_free()
	for x in pets.values(): x.queue_free()
	heroes.clear(); mons.clear(); drops.clear(); pets.clear()
	sel = null; sel_kind = ""; pick_goal = null
	sel_changed.emit()
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
	var lowest = 600.0
	for t in M.get("terr", []):
		lowest = max(lowest, float(t[1]))
	cam.limit_bottom = int(lowest + 120)
	climb = []
	drop_t = 0.0
	cam.position = me.position
	cam.reset_smoothing()
	ready_map = true
	loading.cls = cls()
	loading.load_map(mi)
	map_changed.emit(str(M.name))

func _add_drop(d: Dictionary) -> void:
	var o = Drop.new()
	o.setup(d)
	ents.add_child(o)
	drops[o.id] = o

## người chơi khác và quái: vẽ trễ một chút, nội suy giữa các ảnh chụp (đi đều, không giật kiểu chạy-dừng).
## Mốc thời gian mỗi ảnh lấy theo nhịp máy chủ (tk, 10 lần/giây) chứ không theo lúc gói tới,
## nên mạng tới lúc nhanh lúc chậm (ping thấp vẫn có) cũng không làm nhân vật/quái giật.
const HB_DELAY := 0.2
const MB_DELAY := 0.17
var tk_off = INF     # (giờ máy - tk*0.1) nhỏ nhất trong ~1 giây gần đây: gói tới sớm nhất = trễ mạng thấp nhất
var tk_os: Array = []
var snap_st = 0.0    # mốc thời gian (giờ máy) của ảnh chụp đang xử lý
var dbg_n = 0
var dbg_starve = 0
# Bảng đo hiệu năng (F3): fps, thời gian khung hình, số ảnh chụp thiếu, số lần bị kéo vị trí / đánh văng
var pf_on := false
var pf_lbl: Label = null
var pf_corr := 0
var pf_kb := 0
var pf_acc := 0.0
var pf_frames := 0
var pf_max := 0.0
var pf_proc_max := 0.0
var pf_t := 0.0

func _perf_tick(dt: float, proc_ms: float) -> void:
	if not pf_on and pf_lbl == null and OS.get_environment("HSNC_PERFHUD") != "":
		_perf_toggle()
	pf_frames += 1
	pf_acc += dt
	pf_max = max(pf_max, dt)
	pf_proc_max = max(pf_proc_max, proc_ms)
	if pf_acc < 1.0:
		return
	if pf_on and pf_lbl:
		pf_lbl.text = "FPS %d | khung tệ nhất %.0f ms | xử lý tệ nhất %.1f ms\nPing %d ms | thiếu ảnh quái %d/%d | bị kéo vị trí %d | văng %d\nNgười khác %d | quái %d" % [
			pf_frames / pf_acc, pf_max * 1000.0, pf_proc_max, Net.ping_ms, dbg_starve, dbg_n, pf_corr, pf_kb, heroes.size(), mons.size()]
	pf_acc = 0.0
	pf_frames = 0
	pf_max = 0.0
	pf_proc_max = 0.0

func _perf_toggle() -> void:
	pf_on = not pf_on
	if pf_on and pf_lbl == null:
		var cl := CanvasLayer.new()
		cl.layer = 100
		pf_lbl = Label.new()
		pf_lbl.position = Vector2(8, 60)
		pf_lbl.add_theme_font_size_override("font_size", 14)
		pf_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		pf_lbl.add_theme_constant_override("outline_size", 4)
		cl.add_child(pf_lbl)
		add_child(cl)
	if pf_lbl:
		pf_lbl.get_parent().visible = pf_on

func _snap_time(tk: int) -> float:
	var now_s = Time.get_ticks_msec() / 1000.0
	var ts = float(tk) * 0.1
	# nhịp máy chủ có thể nhanh/chậm hơn 100ms một chút: lấy độ lệch nhỏ nhất trong 10 ảnh gần nhất (tự theo kịp)
	tk_os.append(now_s - ts)
	while tk_os.size() > 10:
		tk_os.pop_front()
	tk_off = tk_os.min()
	return tk_off + ts

func _hbuf_add(h: Node2D, p: Vector2, st: float = -1.0, key: String = "hb") -> void:
	var now_s = st if st >= 0.0 else Time.get_ticks_msec() / 1000.0
	var b: Array = h.get_meta(key, [])
	if not b.is_empty():
		var last: Vector2 = b[-1][1]
		# ảnh chụp lặp lại vị trí cũ khi đang chạy (máy chủ chụp lệch nhịp gửi của người đó): bỏ, nội suy thẳng qua
		if key == "hb" and last.is_equal_approx(p) and h.get("moving") and now_s - float(b[-1][0]) < 0.25:
			return
		if last.distance_to(p) > 300 or now_s <= float(b[-1][0]):
			b.clear()
	b.append([now_s, p])
	while b.size() > 8:
		b.pop_front()
	h.set_meta(key, b)

func _hbuf_pos(h: Node2D, now_s: float, key: String = "hb", delay: float = HB_DELAY) -> void:
	var b: Array = h.get_meta(key, [])
	if b.is_empty():
		return
	var rt = now_s - delay
	if key == "mb":
		dbg_n += 1
		if rt > float(b[-1][0]):
			dbg_starve += 1
	if b.size() == 1 or rt <= float(b[0][0]):
		h.position = b[0][1] if b.size() == 1 or h.position.distance_to(b[0][1]) > 300 else h.position.lerp(b[0][1], 0.3)
		return
	for i in range(b.size() - 1, 0, -1):
		var t0 = float(b[i - 1][0])
		var t1 = float(b[i][0])
		if rt >= t0:
			var k = clampf((rt - t0) / maxf(0.001, t1 - t0), 0.0, 1.0)
			h.position = (b[i - 1][1] as Vector2).lerp(b[i][1], k)
			return

func _snap(m: Dictionary) -> void:
	var seen = {}
	snap_st = _snap_time(int(m.get("tk", 0)))
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
		h.face = int(q[3])
		h.moving = int(q[4]) == 1
		_hbuf_add(h, Vector2(q[1], q[2]), snap_st)
		h.cls = str(q[6])
		h.lv = int(q[7])
		h.nm = str(q[8])
		h.hp = float(q[9])
		h.dead = int(q[10]) == 1
		h.look = int(q[11])
		h.air = q.size() > 12 and int(q[12]) >= 1
		h.climb = q.size() > 12 and int(q[12]) == 2
		h.wing = int(q[13]) if q.size() > 13 else -1
		h.title = str(q[14]) if q.size() > 14 else ""
		h.deb = int(q[15]) if q.size() > 15 else 0
		h.myth = int(q[16]) if q.size() > 16 else 0
	for id in heroes.keys():
		if not seen.has(id):
			heroes[id].queue_free()
			heroes.erase(id)
	for q in m.m:
		var mo: Mon = mons.get(int(q[0]))
		if mo == null:
			continue
		mo.target = Vector2(q[1], q[2])
		mo.ibuf = true
		_hbuf_add(mo, mo.target, snap_st, "mb")
		mo.hp = float(q[3])
		mo.flags = int(q[5])
		if mo.br_t < 0:
			mo.face = int(q[4])
	var pseen = {}
	for q in m.get("q", []):
		var oid = int(q[0])
		pseen[oid] = true
		var pt: Pet = pets.get(oid)
		if pt == null:
			pt = Pet.new()
			pt.setup(q)
			pt.mine = oid == my_id
			ents.add_child(pt)
			pets[oid] = pt
		else:
			pt.apply(q)
	for oid in pets.keys():
		if not pseen.has(oid):
			pets[oid].queue_free()
			pets.erase(oid)
	for e in m.e:
		_event(e)

const PET_EL := {"fire": "fire", "ice": "ice", "wolf": "thunder", "turtle": "jade"}
const PET_FX := {"fire": ["pf_fireball", "pf_firecone", "pf_fireult"], "ice": ["pf_iceshard", "pf_blizzard", "pf_iceult"],
	"wolf": ["pf_chain", "pf_strike", "pf_thunderult"], "turtle": ["pf_shield", "pf_heal", "pf_jadeult"]}
## hiệu ứng chiêu pet (vẽ riêng, đè lên động tác xuất chiêu của thân)
func _pet_skill(p: Pet, i: int, at: Vector2) -> void:
	var nmx: String = PET_FX.get(p.sp, PET_FX.fire)[clampi(i, 0, 2)]
	var flip = at.x < p.position.x
	if p.sp == "turtle":
		var o = _who(p.owner_id)
		var op: Vector2 = o.position if o else p.position
		fx.vfx(nmx, op + Vector2(0, -30), 150 if i < 2 else 200)
		return
	if p.sp == "fire" and i == 1 or p.sp == "ice" and i == 2:
		fx.vfx(nmx, p.position + Vector2(-110 if flip else 110, -30), 170, flip)
	else:
		fx.vfx(nmx, at + Vector2(0, -40), 150 if i < 2 else 230, flip)
	if i == 2 and me and absf(at.x - me.position.x) < 600:
		fx.shake = max(fx.shake, 0.15)

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
					fx.hit_spark(mo.position + Vector2(0, -mo.hh() * 0.45 - mo.lift()), crit)
				if int(e[4]) == my_id or crit:
					fx.text(mo.position + Vector2(0, -mo.hh() * 0.95 - mo.lift()), str(int(e[2])) + ("!" if crit else ""),
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
		"pa":  # pet đánh thường: chủ, quái
			var pa: Pet = pets.get(int(e[1]))
			var pm: Mon = mons.get(int(e[2]))
			if pa:
				pa.play("atk", 0.35)
				if pm:
					fx.vfx("hit_" + PET_EL.get(pa.sp, "fire"), pm.position + Vector2(0, -pm.hh() * 0.45 - pm.lift()), 70, pm.position.x < pa.position.x)
		"ps":  # pet xuất chiêu: chủ, số chiêu, x, y, quái
			var ps: Pet = pets.get(int(e[1]))
			if ps:
				ps.play("cast", 0.7)
				_pet_skill(ps, int(e[2]), Vector2(e[3], e[4]))
		"plv":  # pet lên cấp (e[3] = 1: tiến hóa)
			var pl: Pet = pets.get(int(e[1]))
			if pl:
				fx.vfx("pf_levelup", pl.position + Vector2(0, -20), 120)
				fx.text(pl.position + Vector2(0, -pl.height() - 30), "Tiến hóa!" if int(e[3]) == 1 else "Lên cấp %d" % int(e[2]), Color("7dffb0"), true)
		"pf":  # pet ngất
			var pf: Pet = pets.get(int(e[1]))
			if pf:
				fx.text(pf.position + Vector2(0, -pf.height() - 20), "Ngất!", Color("ff9a7a"), int(e[1]) == my_id)
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
				mo3.set_meta("mb", [[snap_st, mo3.position]])
		"ma":  # quái vồ
			var mo4: Mon = mons.get(int(e[1]))
			var w5 = _who(int(e[2]))
			if mo4:
				mo4.lunge = 0.25
				mo4.play("atk", 0.45)
				if w5:
					var afx = str(mo4._info.get("afx", ""))
					if afx != "":
						fx.vfx(afx, w5.position + Vector2(0, -20), 110, w5.position.x < mo4.position.x)
					else:
						fx.mon_hit(mo4._k, w5.position, 1 if w5.position.x >= mo4.position.x else -1)
		"b":   # rồng khạc
			var mo5: Mon = mons.get(int(e[1]))
			if mo5:
				mo5.br_t = 0.0
				mo5.face = 1 if (_who(int(e[2])) and _who(int(e[2])).position.x >= mo5.position.x) else -1
				fx.breath(mo5, _who(int(e[2])), mo5.type)
		"tg":  # vùng báo trước chiêu: kiểu, a, b, y, thời gian
			fx.telegraph(str(e[1]), float(e[2]), float(e[3]), float(e[4]), float(e[5]))
		"fx":  # hiệu ứng 8 khung: tên, x, y, cao, lật
			fx.vfx(str(e[1]), Vector2(e[2], e[3]), float(e[4]), int(e[5]) < 0)
			if str(e[1]) in ["shockwave", "rock_spikes", "tail_sweep"] and me and absf(float(e[2]) - me.position.x) < 500:
				fx.shake = max(fx.shake, 0.18)
		"bs":  # quái/trùm ra chiêu: id, động tác, thời gian, tên chiêu
			var mo6: Mon = mons.get(int(e[1]))
			if mo6:
				mo6.play(str(e[2]), float(e[3]))
				if e.size() > 4 and str(e[4]) != "" and mo6._info.get("boss", false):
					fx.text(mo6.position + Vector2(0, -mo6.hh() - mo6.lift() - 40), str(e[4]), Color("ff7a4d"), true)
		"mp":  # đạn quái bay ra: id, hình, x, y, vận tốc, thời gian
			fx.mon_proj(int(e[1]), str(e[2]), Vector2(e[3], e[4]), float(e[5]), float(e[6]))
		"mpx":
			fx.mon_proj_end(int(e[1]))
		"st":  # người chơi bị choáng
			var w7 = _who(int(e[1]))
			if w7:
				fx.text(w7.position + Vector2(0, -100), "Choáng!", Color("ffd23f"), int(e[1]) == my_id)
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
	# vách đất cao hơn chân; dốc thoải (tăng ít theo từng bước đi) thì vẫn đi được
	return world.gy(x) < y - max(3.0, absf(x - me.position.x) * 0.85)

## mặt đứng dưới chân (đất hoặc bậc nổi)
func floor_at(x: float, y: float) -> float:
	return Data.floor_y(M, x, y, drop_t > 0)

func _move_x(nx: float) -> bool:
	# bước dài (lướt nhanh, khung hình chậm): chia nhỏ từng đoạn ≤ 12px để chân bám theo dốc như máy chủ
	var d = nx - me.position.x
	if absf(d) > 12.0:
		var n = int(ceil(absf(d) / 12.0))
		var st = d / n
		for k in n:
			if not _move_x1(me.position.x + st):
				return k > 0
		return true
	return _move_x1(nx)

func _move_x1(nx: float) -> bool:
	nx = clampf(nx, 40, float(M.w) - 40)
	if _wall(nx, me.position.y):
		return false
	me.position.x = nx
	# đi lên dốc: chân theo mặt dốc
	if not air:
		var g = world.gy(nx)
		if g < me.position.y and me.position.y - g < 24:
			me.position.y = g
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

func _portal_name(i: int) -> String:
	var ps: Array = M.get("portals", [])
	if i < 0 or i >= ps.size():
		return ""
	var to = int(ps[i].get("to", -1))
	return str(Data.D.maps[to].name) if to >= 0 and to < Data.D.maps.size() else ""

func can_act() -> bool:
	return ready_map and Net.online() and not me.dead and not warping and not loading.busy

func do_attack() -> void:
	if not can_act() or atk_t > 0:
		return
	var c: Dictionary = Data.D.cls[cls()]
	atk_t = float(c.cd)
	var tg: Mon = focus if focus and not focus.dead() else (sel if sel_kind == "mon" and is_instance_valid(sel) and not sel.dead() and me.position.distance_to(sel.position) < float(c.reach) + 120 else nearest_mon(float(c.reach) + 20))
	var aim = atan2(tg.position.y - me.position.y, tg.position.x - me.position.x) if tg else (0.0 if me.face > 0 else PI)
	me.face = 1 if cos(aim) >= 0 else -1
	Net.send({"t": "atk", "tg": tg.id if tg else 0})
	_swing(me)
	fx.basic(cls(), me, aim, false)

func do_skill(i: int) -> void:
	if not can_act():
		return
	var sk: Array = me_data.get("sk", [])
	if i == 6:   # Thiên Địa Diệt: kĩ năng học từ sách của Hỗn Mang Ma Thần (mọi phái)
		if int(me_data.get("usk", 0)) != 1:
			log_line.emit("Chưa học Thiên Địa Diệt. Sách rơi từ Hỗn Mang Ma Thần, cần cấp 100.", Color("ffb347"))
			return
		sk = sk.duplicate()
		while sk.size() < 7:
			sk.append(0)
		sk[6] = 1
	var S: Dictionary = Data.D.skills[cls()][i] if i < 6 else USK_S
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
	# chiêu lướt: tự lướt mượt ngay trên máy (như nút lướt), không chờ máy chủ đặt lại vị trí → hết giật
	var msg = {"t": "sk", "i": i, "tg": tg.id if tg else 0}
	var dsh = SKILL_DASH.get(cls(), {}).get(i)
	if dsh != null and climb.is_empty() and float(me_data.get("stun", 0)) <= 0 and float(me_data.get("ki", 0)) >= _ki_cost(i):
		roll_dir = (-1 if dsh[2] else 1) * (1 if cos(aim) >= 0 else -1)
		roll_t = float(dsh[1])
		roll_spd = float(dsh[0]) / float(dsh[1])
		msg["dp"] = 1
	Net.send(msg)
	_swing(me)
	fx.skill(cls(), i, me, aim, tg, me.face)

const USK_S := {"n": "Thiên Địa Diệt", "cd": 45, "req": 100}

func _ki_cost(i: int) -> float:
	var kc: Array = me_data.get("kc", [])
	return float(kc[i]) if i < kc.size() else 0.0

## tier: -1 tự chọn cỡ vừa đủ, 0/1/2 nhỏ/vừa/lớn (hết cỡ đó thì máy chủ tự chọn cỡ khác)
func do_pot(tier := -1) -> void:
	# bình máu có thời gian hồi để không bấm liên tục được
	if can_act() and pot_cd <= 0.05:
		pot_cd = POT_CD
		var m = {"t": "pot"}
		if tier >= 0 and int(me_data.get(Data.HP_KEYS[tier], 0)) > 0:
			m.k = tier
		Net.send(m)

func do_kpot(tier := -1) -> void:
	if can_act() and kpot_cd <= 0.05:
		kpot_cd = POT_CD
		var m = {"t": "kpot"}
		if tier >= 0 and int(me_data.get(Data.KI_KEYS[tier], 0)) > 0:
			m.k = tier
		Net.send(m)

## lướt ngang ~160 về hướng đang nhìn (hoặc hướng đang bấm), hồi 1,2 giây
func do_roll() -> void:
	if not can_act() or roll_cd > 0.05 or not climb.is_empty():
		return
	roll_cd = 1.2
	roll_t = 0.18
	roll_spd = 890.0
	roll_dir = (1 if joy.x > 0.3 else (-1 if joy.x < -0.3 else me.face))
	me.face = roll_dir
	Net.send({"t": "roll", "d": roll_dir})
	fx.burst(me.position + Vector2(-roll_dir * 20, -12), Color(1, 1, 1, 0.75), 8, 160.0, 0.8)

## ---------- tự động đánh quái (chạy bộ tới quái, không dịch chuyển) ----------
func auto_cfg() -> Dictionary:
	var a = Data.setting("auto", {})
	return a if a is Dictionary else {}

func _auto_types() -> Array:
	var sel: Dictionary = auto_cfg().get("mons", {})
	var L = sel.get(str(mi), [])
	return L if L is Array else []

func _auto_pick() -> Mon:
	var want = _auto_types()
	var best: Mon = null
	var bs = 1e9
	var now = Time.get_ticks_msec() / 1000.0
	for mo in mons.values():
		if mo.dead() or (want.size() > 0 and not want.has(mo.type)):
			continue
		if auto_skip.get(mo.id, 0.0) > now:
			continue
		var s = absf(mo.position.x - me.position.x) + absf(mo.position.y - me.position.y) * 2.5
		if s < bs:
			bs = s
			best = mo
	return best

func _auto_drop():
	var best = null
	var bd = 650.0
	var now = Time.get_ticks_msec() / 1000.0
	for d in drops.values():
		if d.own != 0 and d.own != my_id and d.lock_left() > 0:
			continue
		if auto_skip.get(-d.id, 0.0) > now:
			continue
		# túi đầy: auto bỏ qua trang bị (vẫn nhặt bình, đá, vàng, bùa)
		if d.item is Dictionary and not d.item.is_empty() and me_data.get("inv", []).size() >= 30:
			continue
		if absf(d.position.y - me.position.y) > 150:
			continue
		var dd = absf(d.position.x - me.position.x)
		if dd < bd:
			bd = dd
			best = d
	return best

func _auto_tick(dt: float) -> void:
	var a = auto_cfg()
	var now = Time.get_ticks_msec() / 1000.0
	# bình máu / bình KI
	var hp = float(me_data.get("hp", 1))
	var hpm = max(1.0, float(me_data.get("maxHp", 1)))
	if a.get("hp", true) and hp < hpm * float(a.get("hpPct", 40)) / 100.0 and Data.pot_total(me_data, false) > 0:
		do_pot(int(a.get("hpT", -1)))
	var ki = float(me_data.get("ki", 0))
	var kim = max(1.0, float(me_data.get("maxKi", 1)))
	if a.get("ki", true) and ki < kim * float(a.get("kiPct", 30)) / 100.0 and Data.pot_total(me_data, true) > 0:
		do_kpot(int(a.get("kiT", -1)))
	# nhặt đồ trước khi đánh tiếp (đồ không tới được sau 5 giây thì bỏ qua)
	if a.get("pick", true):
		var d = _auto_drop()
		if d and (focus == null or absf(d.position.x - me.position.x) < 300):
			if d.id != auto_did:
				auto_did = d.id
				auto_dT = 0.0
			auto_dT += dt
			if auto_dT > 5.0:
				auto_skip[-d.id] = now + 60.0
			else:
				focus = null
				move_to = d.position.x
				return
	if focus == null or focus.dead():
		focus = _auto_pick()
		auto_fT = 0.0
	if focus == null:
		return
	# không tới gần thêm được (quái ở bậc không lên được) trong 4 giây, hoặc đánh 10 giây không mất máu: đổi quái khác, bỏ qua 25 giây
	var dx = focus.position.x - me.position.x
	var dy = focus.position.y - me.position.y
	var dist = absf(dx) + absf(dy) * 1.5
	if focus.id != auto_fid:
		auto_fid = focus.id
		auto_fT = 0.0
		auto_best = dist
		auto_hp0 = focus.hp
		auto_hT = 0.0
	if dist < auto_best - 24:
		auto_best = dist
		auto_fT = 0.0
	var close = absf(dx) < 130 and absf(dy) < 80
	if close:
		auto_fT = 0.0
		auto_hT += dt
	else:
		auto_fT += dt
	if focus.hp < auto_hp0:
		auto_hp0 = focus.hp
		auto_hT = 0.0
	if auto_fT > (7.0 if not nav.is_empty() else 4.0) or auto_hT > 10.0:
		auto_skip[focus.id] = now + 25.0
		focus = _auto_pick()
		nav = {}
		return
	# đường đi khi quái ở thanh ngang khác: tính lại mỗi 0,4 giây lúc đang đứng
	nav_re -= dt
	if not air and climb.is_empty() and nav_phase == 0 and nav_re <= 0:
		nav_re = 0.4
		var pl = Nav.plan(M, me.position.x, me.position.y, focus.position.x, focus.position.y)
		if pl == null:
			auto_skip[focus.id] = now + 25.0
			focus = _auto_pick()
			nav = {}
			return
		if (pl as Dictionary).is_empty() or nav.is_empty() or str(pl.act) != str(nav.get("act")) or absf(float(pl.x) - float(nav.get("x", 0))) > 30:
			nav = pl
			nav_phase = 0
	if not air and nav.is_empty():
		if dy < -60 and absf(dx) < 110:
			jump_q = 0.15       # quái ở bậc trên: nhảy lên (xuyên bậc từ dưới)
		elif dy > 60 and absf(dx) < 70 and world.gy(me.position.x) > me.position.y + 10:
			drop_t = 0.3         # quái ở dưới: rơi xuyên bậc đang đứng
			air = true
			vy = 60
	# kỹ năng: chỉ dùng khi đã tới gần quái (cận chiến: trong tầm đánh; đánh xa: trong ~400) và cùng tầng
	var cl: Dictionary = Data.D.cls[cls()]
	var rng = (float(cl.reach) + 70.0 + float(focus._info.get("r", 30)) * 0.5) if cls() in ["sword", "fighter"] else 400.0
	if a.get("skill", true) and nav.is_empty() and absf(dx) < rng and absf(dy) < 90 and climb.is_empty():
		var sk: Array = me_data.get("sk", [])
		var kc: Array = me_data.get("kc", [])
		var nsk = 7 if int(me_data.get("usk", 0)) == 1 else 6
		if nsk == 7:
			sk = sk.duplicate()
			while sk.size() < 7:
				sk.append(0)
			sk[6] = 1
		for k in nsk:
			var i = (auto_sk + k) % nsk
			if i < sk.size() and int(sk[i]) == 1 and cds[i] <= 0.05 and gcd <= 0.05 and (i >= kc.size() or ki >= float(kc[i])):
				do_skill(i)
				auto_sk = i + 1
				break

func _nav_go() -> void:
	nav_n0 = Nav.node_at(M, me.position.x, me.position.y)
	nav_phase = 1
	auto_fT = 0.0
	match str(nav.act):
		"jump":
			jump_q = 0.15
		"drop":
			drop_t = 0.3
			air = true
			vy = 60
		"rope":
			var f0 = focus
			_grab(nav.q)
			focus = f0
			auto_climb = true

## tự nhặt khi đi ngang: chỉ khi đang Auto và bật "Tự nhặt đồ rơi"; còn lại phải bấm vào đồ rồi nhặt
func sync_apick() -> void:
	Net.send({"t": "apick", "on": 1 if auto_on and bool(auto_cfg().get("pick", true)) else 0})

func set_auto(on: bool) -> void:
	auto_on = on
	sync_apick()
	auto_skip.clear()
	nav = {}
	nav_phase = 0
	auto_climb = false
	if not on:
		focus = null
		move_to = -1
	log_line.emit("Tự động đánh: " + ("BẬT" if on else "TẮT"), Color("9be05a") if on else Color("ffb347"))

func jump() -> void:
	# đứng ở chân dây/thang (hoặc trên đỉnh, đang giữ xuống) thì bám leo thay vì nhảy
	if climb.is_empty() and can_act():
		var q = Data.rope_at(M, me.position.x, me.position.y)
		if not q.is_empty() and me.position.y > float(q[1]) + 8:
			_grab(q)
			return
	if not climb.is_empty():
		climb = []
		vy = -JUMP * 0.55
		air = true
		return
	# giữ xuống + nhảy: rơi xuyên bậc nổi đang đứng
	if (joy.y > 0.5 or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) and not air and world.gy(me.position.x) > me.position.y + 10:
		drop_t = 0.3
		air = true
		vy = 60
		return
	jump_q = 0.15

func _grab(q: Array) -> void:
	climb = q
	me.position.x = float(q[0])
	vy = 0
	focus = null
	move_to = -1

## chạm/nhấp vào thế giới: chọn quái, đi tới NPC hoặc đi tới chỗ đó
## đang đứng cạnh NPC (Làng) — vd. chỉ bán đồ được ở Thương Nhân Giáp
func near_shop(id: String) -> bool:
	if mi != 0:
		return false
	for n in M.get("npcs", []):
		if str(n.id) == id:
			return absf(me.position.x - float(n.x)) < 190
	return false

## nói chuyện với NPC gần, hoặc vào cổng khu trùm
func talk() -> void:
	if near_npc.begins_with("gate:"):
		if not warping and can_act():
			loading.begin(_portal_name(int(near_npc.substr(5))))
			Net.send({"t": "warp", "p": int(near_npc.substr(5))})
		return
	if near_npc != "":
		open_npc.emit(near_npc)

## chạm 1 lần: chỉ chọn đối tượng; chạm 2 lần liền: làm việc với đối tượng (đánh / nói chuyện / nhặt) hoặc chạy bộ tới chỗ đó
func tap_world(screen_pos: Vector2) -> void:
	if not can_act():
		return
	var wp = get_canvas_transform().affine_inverse() * screen_pos
	var now = Time.get_ticks_msec() / 1000.0
	var dbl = now - _tap_t < 0.38 and screen_pos.distance_to(_tap_p) < 70
	_tap_t = 0.0 if dbl else now
	_tap_p = screen_pos
	var hit = _pick_at(wp)
	if not dbl:
		set_sel(hit[0], hit[1])
		return
	_act_on(hit[0], hit[1], wp)

func set_sel(kind: String, obj) -> void:
	sel_kind = kind
	sel = obj
	sel_changed.emit()

## tìm đối tượng dưới điểm chạm: [loại, đối tượng]
func _pick_at(wp: Vector2) -> Array:
	var cand = []
	for d in drops.values():
		var dd = (d.position + Vector2(0, -16)).distance_to(wp)
		if dd < 46:
			cand.append([dd - 10, "drop", d])
	for mo in mons.values():
		if mo.dead():
			continue
		var dm = (mo.position + Vector2(0, -mo.hh() * 0.45 - mo.lift())).distance_to(wp)
		if dm < max(70.0, mo.hh() * 0.55):
			cand.append([dm, "mon", mo])
	for id in heroes:
		var h: Hero = heroes[id]
		var dh = (h.position + Vector2(0, -40)).distance_to(wp)
		if dh < 60:
			h.set_meta("pid", id)
			cand.append([dh, "hero", h])
	for n in M.get("npcs", []):
		if absf(wp.x - n.x) < 70 and wp.y > n.y - 170 and wp.y < n.y + 20:
			cand.append([absf(wp.x - n.x) + 20, "npc", n])
	if cand.is_empty():
		return ["", null]
	cand.sort_custom(func(a, b): return a[0] < b[0])
	return [cand[0][1], cand[0][2]]

func _act_on(kind: String, obj, wp: Vector2) -> void:
	set_sel(kind, obj)
	match kind:
		"drop":
			go_pick(obj)
		"mon":
			focus = obj
			move_to = -1
		"hero":
			player_tapped.emit(int(obj.get_meta("pid", 0)), obj.nm)
		"npc":
			npc_go = str(obj.id)
			move_to = obj.x
			focus = null
		_:
			for i in M.portals.size():
				var pt: Dictionary = M.portals[i]
				if pt.get("arena") and absf(wp.x - float(pt.x)) < 110 and wp.y > float(pt.y) - 240 and wp.y < float(pt.y) + 20:
					npc_go = "gate:%d" % i
					move_to = float(pt.x)
					focus = null
					return
			focus = null
			move_to = wp.x

## chạy tới đồ rồi nhặt (đồ người khác còn khóa: báo, không chạy)
func go_pick(d) -> void:
	if d == null or not is_instance_valid(d):
		return
	if d.own != 0 and d.own != my_id and d.lock_left() > 0:
		toast.emit("Vật phẩm của người khác. Hiện tại chưa thể nhặt được.")
		return
	pick_goal = d
	focus = null
	move_to = d.position.x

## nút đổi mục tiêu: quái gần kế tiếp (trong 520), xoay vòng
func next_target() -> void:
	var L = []
	for mo in mons.values():
		if mo.dead():
			continue
		var d = absf(mo.position.x - me.position.x) + absf(mo.position.y - me.position.y) * 1.5
		if d < 520:
			L.append([d, mo])
	if L.is_empty():
		toast.emit("Không có mục tiêu nào ở gần.")
		return
	L.sort_custom(func(a, b): return a[0] < b[0])
	var i = 0
	if sel_kind == "mon":
		for k in L.size():
			if L[k][1] == sel:
				i = (k + 1) % L.size()
	set_sel("mon", L[i][1])
	if focus != null:
		focus = L[i][1]

func _process(dt: float) -> void:
	var pf_t0 := Time.get_ticks_usec()
	_process_main(dt)
	_perf_tick(dt, (Time.get_ticks_usec() - pf_t0) / 1000.0)

func _process_main(dt: float) -> void:
	fade = max(0.0, fade - dt * 2)
	if not ready_map:
		return
	atk_t = max(0.0, atk_t - dt)
	gcd = max(0.0, gcd - dt)
	pot_cd = max(0.0, pot_cd - dt)
	kpot_cd = max(0.0, kpot_cd - dt)
	roll_cd = max(0.0, roll_cd - dt)
	for i in 7:
		cds[i] = max(0.0, cds[i] - dt)
	for mo in mons.values():
		mo.focused = mo == focus
	var now_s = Time.get_ticks_msec() / 1000.0
	for h in heroes.values():
		_hbuf_pos(h, now_s)
	for mo in mons.values():
		if mo.ibuf:
			_hbuf_pos(mo, now_s, "mb", MB_DELAY)
	_control(dt)
	if kb_rem != 0.0:
		var st = signf(kb_rem) * minf(absf(kb_rem), 1100.0 * dt)
		kb_rem -= st
		var moved = 0.0
		while absf(moved) < absf(st):
			var k = signf(st) * minf(8.0, absf(st) - absf(moved))
			if not _move_x1(me.position.x + k):
				kb_rem = 0.0
				break
			moved += k
		if absf(kb_rem) < 0.5:
			kb_rem = 0.0
	cam.position = me.position + Vector2(0, -60)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (fx.shake * 40.0) if fx.shake > 0 else Vector2.ZERO
	# đứng ở chân dây/thang: gợi ý bấm nhảy để leo
	var rq = Data.rope_at(M, me.position.x, me.position.y) if climb.is_empty() and not air else []
	world.rope_hint = Vector2(float(rq[0]), me.position.y) if not rq.is_empty() and me.position.y > float(rq[1]) + 8 else Vector2.INF
	# NPC gần
	var nn = ""
	for n in M.get("npcs", []):
		if absf(me.position.x - n.x) < 115:
			nn = str(n.id)
	for i in M.portals.size():
		if M.portals[i].get("arena") and absf(me.position.x - float(M.portals[i].x)) < 100 and absf(me.position.y - float(M.portals[i].y)) < 70:
			nn = "gate:%d" % i
	if nn != near_npc:
		near_npc = nn
		world.near_npc = nn
		npc_near.emit(nn)
	if npc_go != "" and npc_go == near_npc:
		npc_go = ""
		move_to = -1
		talk()

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
		pick_goal = null
		npc_go = ""
	elif auto_on and not warping:
		_auto_tick(dt)
	if focus and focus.dead():
		focus = null
	var dx = 0.0
	var in_reach = false
	var c: Dictionary = Data.D.cls[cls()]
	if manual:
		dx = clampf(ix, -1, 1)
	elif focus and auto_on and not nav.is_empty():
		# auto đang theo đường đi: tới chỗ bắt đầu → nhảy / rơi / leo → tới chỗ đáp
		var tx = float(nav.x) if nav_phase == 0 else float(nav.land)
		var d3 = tx - p.x
		if absf(d3) > 6:
			dx = signf(d3)
		if nav_phase == 0 and absf(d3) <= 10 and not air and climb.is_empty():
			_nav_go()
		elif nav_phase == 1 and not air and climb.is_empty() and (Nav.node_at(M, p.x, p.y) != nav_n0 or absf(d3) <= 8):
			nav = {}
			nav_phase = 0
			nav_re = 0.0
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
	drop_t = max(0.0, drop_t - dt)
	var iy = joy.y
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): iy += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): iy -= 1
	# đứng trên đỉnh dây/thang, giữ xuống: bám leo xuống
	if climb.is_empty() and iy > 0.6 and not air:
		var q2 = Data.rope_at(M, me.position.x, me.position.y, 24)
		if not q2.is_empty() and absf(me.position.y - float(q2[1])) < 14:
			_grab(q2)
	if not climb.is_empty():
		if auto_on and auto_climb:
			iy = -1.0
			dx = 0.0
		_climb(dt, iy, dx)
		if climb.is_empty():
			auto_climb = false
		return
	jump_q = max(0.0, jump_q - dt)
	if jump_q > 0 and not air:
		vy = -JUMP
		air = true
		jump_q = 0
	# trọng lực
	var g0 = floor_at(p.x, p.y)
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
	air = not (vy == 0 and absf(me.position.y - floor_at(me.position.x, me.position.y)) < 1)
	var spd = float(me_data.get("spd", c.spd))
	if float(me_data.get("stun", 0)) > 0:
		spd *= 0.05
	elif float(me_data.get("slow", 1)) < 1:
		spd *= float(me_data.get("slow", 1))
	for b in me_data.get("buffs", []):
		if b.get("id") in ["roll", "rage"]:
			spd *= 1.35 if b.id == "roll" else 1.25
	if roll_t > 0:
		_move_x(me.position.x + roll_dir * roll_spd * minf(dt, roll_t))
		roll_t -= dt
		dx = 0
		me.face = roll_dir
	me.moving = dx != 0
	if me.moving:
		var s = spd * (0.85 if me.swing > 0 else 1.0) * (0.92 if air else 1.0) * (0.6 if Data.in_zone(M.get("water", []), me.position.x, me.position.y) else 1.0)
		if not _move_x(me.position.x + dx * s * dt) and not manual and not air and world.gy(me.position.x + dx * 24) > me.position.y - 125:
			jump_q = 0.15
		if not focus:
			me.face = 1 if dx > 0 else -1
	if air:
		me.moving = true
	me.air = air
	me.climb = not climb.is_empty()
	if focus and absf(focus.position.x - me.position.x) > 4:
		me.face = 1 if focus.position.x > me.position.x else -1
	# đang chọn đồ: bấm đánh = chạy tới nhặt
	if atk_held and sel_kind == "drop" and is_instance_valid(sel):
		if pick_goal != sel:
			go_pick(sel)
	elif atk_held and sel_kind == "mon" and is_instance_valid(sel) and not sel.dead() and focus != sel:
		focus = sel
	elif atk_held or in_reach or Input.is_key_pressed(KEY_J):
		do_attack()
	# tới gần đồ đang muốn nhặt thì xin nhặt
	if pick_goal != null:
		if not is_instance_valid(pick_goal):
			pick_goal = null
		else:
			pick_t -= dt
			if absf(pick_goal.position.x - me.position.x) < 70 and absf(pick_goal.position.y - me.position.y) < 110 and pick_t <= 0:
				pick_t = 0.5
				Net.send({"t": "pick", "id": pick_goal.id})
	# cổng: đứng trên đất ở cổng thì xin máy chủ chuyển bản đồ
	if not air and not warping:
		for i in M.portals.size():
			var pt: Dictionary = M.portals[i]
			if pt.get("arena"):
				continue
			if absf(me.position.x - pt.x) < 46 and absf(me.position.y - float(pt.y)) < 60:
				warping = true
				focus = null
				move_to = -1
				fade = 1.0
				loading.begin(_portal_name(i))
				Net.send({"t": "warp", "p": i})
				break
	# gửi vị trí 10 lần/giây (và ngay khi dừng lại)
	send_t -= dt
	var cur = Vector3(round(me.position.x), round(me.position.y), me.face)
	if send_t <= 0 or (cur != last_sent and not me.moving):
		if cur != last_sent or send_t <= -1.0:
			Net.send({"t": "in", "x": me.position.x, "y": me.position.y, "f": me.face, "mv": 1 if me.moving else 0, "air": 1 if air else 0, "pk": pos_n})
			last_sent = cur
		send_t = SEND_DT

## leo dây/thang: lên xuống theo cần điều khiển (W/S), tới đỉnh thì bước lên mặt trên, tới chân thì xuống đất
func _climb(dt: float, iy: float, dx: float) -> void:
	var q = climb
	me.air = true
	me.climb = true
	me.moving = absf(iy) > 0.3
	me.position.x = float(q[0])
	if absf(iy) > 0.3:
		me.position.y += signf(iy) * 170.0 * dt
	if me.position.y <= float(q[1]):
		me.position.y = float(q[1])
		climb = []
		air = false
		vy = 0
		# đỉnh thang sát mép vách: bước sang chỗ có mặt đứng
		if absf(floor_at(me.position.x, me.position.y) - me.position.y) > 4:
			for d in [20, -20, 40, -40, 60, -60]:
				if absf(floor_at(me.position.x + d, me.position.y) - me.position.y) < 4:
					me.position.x += d
					break
	elif me.position.y >= float(q[2]) or (absf(dx) > 0.5 and absf(iy) < 0.3):
		# chạm đất hoặc đẩy ngang: buông dây
		me.position.y = min(me.position.y, float(q[2]))
		climb = []
		vy = 0
		air = true
	send_t -= dt
	if send_t <= 0:
		Net.send({"t": "in", "x": me.position.x, "y": me.position.y, "f": me.face, "mv": 1 if me.moving else 0, "air": 2 if not climb.is_empty() else 1, "pk": pos_n})
		send_t = SEND_DT

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_F3: _perf_toggle()
			KEY_W, KEY_UP, KEY_SPACE, KEY_K: jump()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7: do_skill(ev.keycode - KEY_1)
			KEY_Q: do_pot()
			KEY_R: do_kpot()
			KEY_L: do_roll()
			KEY_TAB: next_target()
			KEY_F:
				if sel_kind == "drop" and is_instance_valid(sel):
					go_pick(sel)
			KEY_B: get_parent().open_bag()
			KEY_E:
				if near_npc != "":
					talk()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and ev.device != InputEvent.DEVICE_ID_EMULATION:
		# chuột giả lập từ cảm ứng bỏ qua (đã xử lý ở ScreenTouch), kẻo một chạm bị tính thành chạm đúp
		tap_world(ev.position)
	elif ev is InputEventScreenTouch and ev.pressed:
		tap_world(ev.position)
