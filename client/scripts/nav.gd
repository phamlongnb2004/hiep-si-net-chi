extends RefCounted
class_name Nav
## Tìm đường cho auto: mặt đứng gồm các thanh ngang (bậc nổi) và các đoạn mặt đất (tách ở vách dựng đứng).
## Cạnh: nhảy lên (xuyên thanh từ dưới / lên bậc đất), nhảy qua khe, rơi xuyên thanh, đi ra mép, leo dây/thang.
## plan() trả về bước đầu tiên: {"act", "x" (chỗ bắt đầu), "land" (chỗ đáp), "q" (dây)}; {} nếu đã cùng mặt; null nếu không tới được.

const H_UP := 140.0       # nhảy lên được (đỉnh nhảy ~160, chừa an toàn)
const GAP := 110.0        # khe ngang nhảy qua được
const EDGE := 26.0        # đứng lùi vào trong mép
const CLIFF := 30.0       # mặt đất đổi độ cao quá chừng này trong ≤ 12px = vách → tách đoạn

static var _cache_m = null
static var _nodes: Array = []     # [{"a": x trái, "b": x phải, "p": thanh (Array) hoặc null = đất}]

static func _build(M: Dictionary) -> void:
	if _cache_m == M:
		return
	_cache_m = M
	_nodes = []
	for p in M.get("plats", []):
		_nodes.append({"a": float(p[0]), "b": float(p[2]), "p": p})
	var t: Array = M.get("terr", [])
	var w = float(M.get("w", 2000))
	var a = 40.0
	for i in range(1, t.size()):
		var x0 = float(t[i - 1][0])
		var x1 = float(t[i][0])
		if absf(float(t[i][1]) - float(t[i - 1][1])) > CLIFF and absf(x1 - x0) <= 12:
			var cut = (x0 + x1) * 0.5
			if cut - a > 20:
				_nodes.append({"a": a, "b": cut, "p": null})
			a = cut
	if w - 40 - a > 20 or _nodes.is_empty():
		_nodes.append({"a": a, "b": w - 40, "p": null})

static func _y(M: Dictionary, n: int, x: float) -> float:
	var N: Dictionary = _nodes[n]
	if x < N.a - 1 or x > N.b + 1:
		return INF
	return Data.ground_y(M, x) if N.p == null else Data.plat_y(N.p, clampf(x, N.a, N.b))

static func node_at(M: Dictionary, x: float, y: float) -> int:
	_build(M)
	var best = -2
	var bd = 22.0
	for i in _nodes.size():
		var ny = _y(M, i, x)
		if ny != INF and absf(ny - y) < bd:
			bd = absf(ny - y)
			best = i
	return best

## mặt đứng đầu tiên bên dưới (x, y) khi rơi (bỏ qua nút skip)
static func _below(M: Dictionary, x: float, y: float, skip: int) -> int:
	var best = INF
	var bn = -2
	for i in _nodes.size():
		if i == skip:
			continue
		var ny = _y(M, i, x)
		if ny != INF and ny > y + 4 and ny < best:
			best = ny
			bn = i
	return bn

static func _edges(M: Dictionary, a: int, ax: float) -> Array:
	var out: Array = []
	var A: Dictionary = _nodes[a]
	for b in _nodes.size():
		if b == a:
			continue
		var B: Dictionary = _nodes[b]
		var lo = maxf(A.a, B.a + EDGE)
		var hi = minf(A.b, B.b - EDGE)
		if lo <= hi:
			# chồng nhau theo chiều ngang: nhảy thẳng lên ở điểm gần mình nhất
			var bx = INF
			var x = lo
			while x <= hi:
				var rise = _y(M, a, x) - _y(M, b, x)
				if rise > 12 and rise <= H_UP and absf(x - ax) < absf(bx - ax):
					bx = x
				x += 20.0
			if bx != INF:
				out.append({"to": b, "act": "jump", "x": bx, "land": bx})
		else:
			# khe (hoặc bậc đất liền kề): nhảy từ mép mình sang mép kia
			var right = B.a >= A.b - 1
			var gap = maxf(0.0, (B.a - A.b) if right else (A.a - B.b))
			var lx = (A.b - 10) if right else (A.a + 10)
			var tx = (B.a + EDGE) if right else (B.b - EDGE)
			var ly = _y(M, a, lx)
			var ty = _y(M, b, tx)
			if ly == INF or ty == INF:
				continue
			var rise2 = ly - ty
			if gap <= GAP and rise2 > -20 and rise2 <= H_UP - gap * 0.4:
				out.append({"to": b, "act": "jump", "x": lx, "land": tx})
	# đi xuống: thanh thì rơi xuyên; mọi mặt thì đi ra hai mép
	if A.p != null:
		var mx = clampf(ax, A.a + 10, A.b - 10)
		var t = _below(M, mx, _y(M, a, mx), a)
		if t != -2:
			out.append({"to": t, "act": "drop", "x": mx, "land": mx})
	for e in [[A.a + 4, A.a - 34], [A.b - 4, A.b + 34]]:
		var ex = float(e[0])
		var lx2 = clampf(float(e[1]), 40, float(M.w) - 40)
		var ey = _y(M, a, ex)
		if ey == INF:
			continue
		var t2 = _below(M, lx2, ey, a)
		if t2 != -2 and t2 != a:
			out.append({"to": t2, "act": "walk", "x": ex, "land": lx2})
	# dây / thang: leo lên
	for q in M.get("ropes", []):
		var rx = float(q[0])
		var ya = _y(M, a, rx)
		if ya == INF or absf(ya - float(q[2])) > 40:
			continue
		var t3 = -2
		for d in [0.0, 20.0, -20.0, 40.0, -40.0]:
			t3 = node_at(M, rx + d, float(q[1]))
			if t3 != -2:
				break
		if t3 != -2 and t3 != a:
			out.append({"to": t3, "act": "rope", "x": rx, "land": rx, "q": q})
	return out

static func plan(M: Dictionary, x: float, y: float, tx: float, ty: float):
	var a = node_at(M, x, y)
	var goal = node_at(M, tx, ty)
	if a == -2 or goal == -2 or a == goal:
		return {}
	var dist := {a: 0.0}
	var posx := {a: x}
	var first := {a: null}
	var open: Array = [a]
	var done := {}
	while not open.is_empty():
		var bi = 0
		for k in open.size():
			if dist[open[k]] < dist[open[bi]]:
				bi = k
		var n = open[bi]
		open.remove_at(bi)
		if done.has(n):
			continue
		done[n] = true
		if n == goal:
			return first[n]
		for e in _edges(M, n, posx[n]):
			var to = int(e.to)
			var c = dist[n] + absf(float(e.x) - posx[n]) + absf(float(e.land) - float(e.x)) + 250.0
			if not dist.has(to) or c < dist[to]:
				dist[to] = c
				posx[to] = float(e.land)
				first[to] = e if n == a else first[n]
				if not done.has(to):
					open.append(to)
	return null
