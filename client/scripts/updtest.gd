extends Node
## Thử bộ cập nhật (chỉ chạy khi mở với "-- updtest"): kiểm manifest, tải gói, in kết quả rồi thoát.
func _ready() -> void:
	print("GẮN LÚC KHỞI ĐỘNG: ", Updater.mount())
	var u := Updater.new()
	add_child(u)
	var srv := OS.get_environment("HSNC_UPDATE")
	u.check(srv if srv != "" else Net.server)
	var r = await u.finished
	print("KẾT QUẢ: ", JSON.stringify(r).substr(0, 400))
	print("TRẠNG THÁI: ", Updater.read_state())
	get_tree().quit()
