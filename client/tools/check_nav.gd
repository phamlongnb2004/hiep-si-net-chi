extends RefCounted
## Kiểm tra tìm đường của auto trên mọi bản đồ: từ mỗi mặt đứng (đất/thanh) tới mỗi khu quái và cổng,
## đi theo từng bước plan() (dịch tới chỗ đáp rồi tìm tiếp) xem có tới nơi không.
## Dùng: HSNC_PREVIEW=navcheck godot --headless --path client -- autotest=/tmp/x [chỉ số bản đồ: HSNC_MAPS=13,15]
static func run() -> void:
	var D = JSON.parse_string(FileAccess.get_file_as_string("res://data/data.json"))
	var only := []
	for a in OS.get_environment("HSNC_MAPS").split(",", false):
		only.append(int(a))
	var total_bad := 0
	for mi in D.maps.size():
		if not only.is_empty() and not mi in only:
			continue
		var M: Dictionary = D.maps[mi]
		Nav._cache_m = null
		Nav._build(M)
		var nodes: Array = Nav._nodes.duplicate()
		var goals := []
		for s in M.get("spots", []):
			if s.has("p"):
				var p = M.plats[int(s.p)]
				goals.append(["quái " + str(s.n), (float(p[0]) + float(p[2])) / 2.0, Data.plat_y(p, (float(p[0]) + float(p[2])) / 2.0)])
			else:
				var gx = float(s.x) + float(s.w) / 2.0
				goals.append(["quái " + str(s.n), gx, Data.ground_y(M, gx)])
		for pt in M.get("portals", []):
			goals.append(["cổng " + str(pt.label), float(pt.x), float(pt.y)])
		var bad := []
		for i in nodes.size():
			var N: Dictionary = nodes[i]
			var sx = (float(N.a) + float(N.b)) / 2.0
			var sy = Nav._y(M, i, sx)
			for g in goals:
				var x = sx
				var y = sy
				var ok = false
				for step in 40:
					var pl = Nav.plan(M, x, y, g[1], g[2])
					if pl == null:
						break
					if (pl as Dictionary).is_empty():
						ok = true
						break
					# thực hiện bước: tới chỗ đáp
					x = float(pl.land)
					var to = int(pl.get("to", -1)) if pl.has("to") else -1
					if pl.act == "rope":
						y = float(pl.q[1])
					elif to >= 0:
						y = Nav._y(M, to, x)
					if y == INF:
						break
				if not ok:
					bad.append("  từ mặt %d [%d..%d] y%d → %s" % [i, int(N.a), int(N.b), int(sy), g[0]])
		print("%d %s: %d lỗi" % [mi, M.name, bad.size()])
		for b in bad.slice(0, 12):
			print(b)
		total_bad += bad.size()
	print("TONG ", total_bad)
