## Màn hình tải bản đồ: hiện khi bấm sang bản đồ/khu khác (hoặc khi vào game), nạp trước ảnh của bản đồ mới
## (cảnh nền, cảnh vật, cổng, thang, quái) từng ít một mỗi khung hình để thanh tải chạy thật, rồi mờ dần.
class_name LoadScreen
extends CanvasLayer

const TIPS := [
	"Mẹo: đứng ở chân thang rồi bấm nhảy để bám thang, giữ lên/xuống để leo.",
	"Mẹo: giữ xuống + nhảy để nhảy xuyên xuống bậc bên dưới.",
	"Mẹo: quái tinh anh cho gấp 3 kinh nghiệm và dễ rơi đồ hiếm.",
	"Mẹo: khu trùm mở theo giờ, gây từ 1% máu trùm là được chia thưởng.",
	"Mẹo: cường hóa từ +5 trở lên nếu thất bại sẽ bị tụt cấp, chuẩn bị đủ đá nhé.",
	"Mẹo: mỗi khu tối đa 15 người, đông quá thì đổi khu ở góc trên.",
	"Mẹo: đồ rơi thuộc về người hạ quái trong 30 giây đầu.",
]
const MIN_T := 0.9        # hiện ít nhất chừng này giây cho đỡ chớp
const WAIT_MAX := 10.0    # chờ máy chủ quá lâu thì tự đóng
const WARM_MAX := 15.0    # chờ nạp ngầm ảnh nhân vật/hiệu ứng (Data.warm_all) tối đa chừng này giây rồi vào luôn

var root: Control
var bg: TextureRect
var shade: ColorRect
var title: Label
var sub: Label
var tip: Label
var bar_bg: Panel
var bar: ColorRect
var pct_l: Label
var busy := false         # đang che màn hình (chặn điều khiển)
var waiting := false      # đã xin chuyển, chưa có bản đồ
var t := 0.0
var shown := 0.0
var prog := 0.0
var queue: Array = []
var bg_rel := ""
var total := 0
var fading := -1.0

func _ready() -> void:
	layer = 40
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var base = ColorRect.new()
	base.color = Color("0d1426")
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(base)
	bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(bg)
	shade = ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.12, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	root.add_child(box)
	sub = UI.outlined("ĐANG TẢI BẢN ĐỒ", 18, Color("cfe3ff"), "bold", 5)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	title = UI.outlined("", 44, UI.GOLD, "bold", 9)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var mid = CenterContainer.new()
	box.add_child(mid)
	bar_bg = Panel.new()
	bar_bg.custom_minimum_size = Vector2(520, 22)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.border_color = Color("ffe08a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(11)
	bar_bg.add_theme_stylebox_override("panel", sb)
	mid.add_child(bar_bg)
	bar = ColorRect.new()
	bar.color = Color("ffc93c")
	bar.position = Vector2(4, 4)
	bar.size = Vector2(0, 14)
	bar_bg.add_child(bar)
	pct_l = UI.outlined("0%", 18, Color.WHITE, "bold", 5)
	pct_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(pct_l)
	tip = UI.outlined("", 18, Color("e8eefc"), "semi", 5)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(640, 0)
	var tc = CenterContainer.new()
	tc.add_child(tip)
	box.add_child(tc)
	visible = false

## bắt đầu che màn hình khi vừa xin chuyển (chưa biết bản đồ mới thì để tên trống)
func begin(map_name := "") -> void:
	visible = true
	busy = true
	waiting = true
	fading = -1.0
	root.modulate.a = 1.0
	t = 0.0
	shown = 0.0
	prog = 0.0
	queue.clear()
	bg_rel = ""
	total = 0
	title.text = map_name
	tip.text = TIPS[randi() % TIPS.size()]
	_bar()

## máy chủ đã gửi bản đồ: đặt ảnh nền, lập danh sách ảnh cần nạp trước
func load_map(mi: int) -> void:
	if not visible:
		begin()
	waiting = false
	var M: Dictionary = Data.D.maps[mi]
	title.text = str(M.name)
	var th = str(M.get("theme", "grass"))
	var side: Dictionary = Data.A.get("side", {})
	var far = side.get("far_" + th, side.get("far_grass", {}))
	bg_rel = str(far.get("u", "")) if far is Dictionary else ""
	bg.texture = null
	queue = _assets_for(M, th)
	# bảo đảm ảnh nền xa cũng được nạp nền, không gọi load() đồng bộ trong lúc đổi bản đồ
	if bg_rel != "" and not queue.has(bg_rel):
		queue.push_front(bg_rel)
	# gồm cả phần ảnh nhân vật/hiệu ứng đang nạp ngầm (lần vào game đầu tiên), để vào xong là mượt ngay
	total = max(1, queue.size() + Data.warm_left())

func cancel() -> void:
	if visible and waiting:
		_finish()

func _assets_for(M: Dictionary, th: String) -> Array:
	var out: Array = []
	var seen := {}
	var add = func(e):
		if e is Dictionary and e.has("u") and not seen.has(e.u):
			seen[e.u] = true
			out.append(str(e.u))
	for k in Data.A.get("side", {}):
		if str(k).ends_with("_" + th):
			add.call(Data.A.side[k])
	for k in Data.A.get("ai", {}):
		var ks = str(k)
		if ks.begins_with(th + "_") or ks.begins_with("gate_") or ks.begins_with("ladder") or ks.begins_with("bridge") or ks in ["rope", "vine"]:
			add.call(Data.A.ai[k])
	var types := {}
	for sp in M.get("spots", []):
		types[str(sp.mon)] = true
	for b in M.get("bosses", []):
		if b is Dictionary and b.has("mon"):
			types[str(b.mon)] = true
	var m2: Dictionary = Data.A.get("mon2", {})
	var m1: Dictionary = Data.A.get("mon", {})
	for ty in types:
		var art = str(Data.D.mons.get(ty, {}).get("art", ty))
		for key in [ty, art]:
			var v = m2.get(key)
			if v is Dictionary and v.get("a") is Dictionary:
				for an in v.a.values():
					for f in an:
						if not seen.has(f):
							seen[f] = true
							out.append(str(f))
			var v1 = m1.get(key)
			if v1 is Array:
				for f in v1:
					add.call(f)
	return out

func _bar() -> void:
	var w = bar_bg.custom_minimum_size.x - 8
	bar.size.x = w * clampf(prog, 0.0, 1.0)
	pct_l.text = "%d%%" % int(round(prog * 100))

func _process(dt: float) -> void:
	# tiếp tục nạp nền cả sau khi màn hình đã hết thời gian chờ tối đa
	var n = 0
	while not queue.is_empty() and n < 6:
		var rel = str(queue.front())
		if not Data.prefetch(rel):
			break
		queue.pop_front()
		n += 1
	if bg_rel != "" and Data.has_tex(bg_rel):
		bg.texture = Data.tex(bg_rel)
	if not visible:
		return
	t += dt
	shown += dt
	if fading >= 0.0:
		fading += dt
		root.modulate.a = 1.0 - clampf(fading / 0.35, 0.0, 1.0)
		if fading >= 0.35:
			visible = false
			busy = false
		return
	if waiting:
		# chờ máy chủ: thanh nhích dần tới 30%
		prog = minf(0.3, prog + dt * 0.25)
		if t > WAIT_MAX:
			_finish()
	else:
		var warm = Data.warm_left()
		var timed_out = shown >= WARM_MAX
		var real = 0.3 + 0.7 * (1.0 - minf(1.0, float(queue.size() + warm) / float(total)))
		if timed_out:
			# hết thời gian chờ: vào game nhưng vẫn tiếp tục nạp các ảnh còn lại ở nền
			real = 1.0
		prog = move_toward(prog, real, dt * 1.6)
		if (timed_out or (queue.is_empty() and warm == 0)) and prog >= 0.999 and shown >= MIN_T:
			_finish()
	_bar()

func _finish() -> void:
	prog = 1.0
	_bar()
	waiting = false
	if fading < 0.0:
		fading = 0.0
