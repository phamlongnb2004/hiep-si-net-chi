extends SceneTree
## Đóng gói ảnh + dữ liệu thành một gói cập nhật (.pck) cho ứng dụng đã cài (không chứa mã chương trình).
## Dùng: godot --headless --path client --script res://tools/make_pack.gd -- out=../build/assets-3.pck

func _init() -> void:
	var out := "res://../build/assets.pck"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	var pk := PCKPacker.new()
	if pk.pck_start(out) != OK:
		push_error("không ghi được " + out)
		quit(1)
		return
	var n := 0
	for f in _walk("res://assets"):
		if f.ends_with(".import"):
			var cfg := ConfigFile.new()
			cfg.load(f)
			var dest: String = cfg.get_value("remap", "path", "")
			if dest == "":
				for k in cfg.get_section_keys("remap"):
					if k.begins_with("path."):
						dest = cfg.get_value("remap", k)
						break
			if dest != "" and FileAccess.file_exists(dest):
				pk.add_file(f, ProjectSettings.globalize_path(f))
				pk.add_file(dest, ProjectSettings.globalize_path(dest))
				n += 1
		elif f.ends_with(".json"):
			pk.add_file(f, ProjectSettings.globalize_path(f))
	pk.add_file("res://data/data.json", ProjectSettings.globalize_path("res://data/data.json"))
	pk.flush()
	print("Đã đóng gói %d ảnh vào %s" % [n, out])
	quit(0)

func _walk(d: String) -> Array:
	var out: Array = []
	var da := DirAccess.open(d)
	if da == null:
		return out
	for f in da.get_files():
		out.append(d.path_join(f))
	for s in da.get_directories():
		out.append_array(_walk(d.path_join(s)))
	return out
