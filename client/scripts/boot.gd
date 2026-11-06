extends Node
## Khởi động: gắn gói ảnh đã tải (nếu còn nguyên vẹn), nạp lại dữ liệu, mở màn chính.

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	if "updtest" in args:
		get_tree().root.add_child.call_deferred(load("res://scripts/updtest.gd").new())
		queue_free()
		return
	var r = Updater.mount()
	if r.ok:
		Data.reload()
	var main = preload("res://scripts/main.gd").new()
	main.name = "Main"
	main.assets_version = int(r.get("assets", 0))
	get_tree().root.add_child.call_deferred(main)
	for a in args:
		if a.begins_with("autotest="):
			get_tree().root.add_child.call_deferred(load("res://scripts/autotest.gd").new())
	queue_free()
