class_name Updater
extends Node
## Cập nhật có chữ ký: tải manifest (đã ký RSA-SHA256), so phiên bản, tải gói ảnh/dữ liệu (.pck) có tiếp tục khi đứt,
## kiểm SHA-256 + kích thước, lưu bản cũ để quay lại nếu bản mới lỗi. Ứng dụng (exe/apk) chỉ báo có bản mới, không tự thay.

signal progress(done: int, total: int)
signal finished(result: Dictionary)

const PUB := "res://data/update_pub.pem"
const DIR := "user://packs/"
const STATE := "user://packs/state.json"
var base = ""

static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

static func ver_cmp(a: String, b: String) -> int:
	var x = a.split(".")
	var y = b.split(".")
	for i in max(x.size(), y.size()):
		var p = int(x[i]) if i < x.size() else 0
		var q = int(y[i]) if i < y.size() else 0
		if p != q:
			return 1 if p > q else -1
	return 0

static func read_state() -> Dictionary:
	var f = FileAccess.open(STATE, FileAccess.READ)
	if f == null:
		return {}
	var j = JSON.parse_string(f.get_as_text())
	return j if j is Dictionary else {}

static func write_state(s: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f = FileAccess.open(STATE, FileAccess.WRITE)
	f.store_string(JSON.stringify(s))

static func sha256_file(p: String) -> String:
	var f = FileAccess.open(p, FileAccess.READ)
	if f == null:
		return ""
	var h = HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	while f.get_position() < f.get_length():
		h.update(f.get_buffer(1 << 16))
	return h.finish().hex_encode()

## lúc khởi động: gắn gói đã tải nếu còn nguyên vẹn; hỏng thì quay về gói trước hoặc ảnh có sẵn trong ứng dụng
## bản dữ liệu ảnh có sẵn trong ứng dụng này; gói tải về cũ hơn thì bỏ qua (không ghi đè ảnh mới)
const BUNDLED := 28

static func mount() -> Dictionary:
	var s = read_state()
	for k in ["current", "previous"]:
		var e = s.get(k)
		if not (e is Dictionary):
			continue
		if ver_cmp(app_version(), str(e.get("min_app", "0"))) < 0 or int(e.get("version", 0)) < BUNDLED:
			continue
		var p = DIR + str(e.file)
		if FileAccess.file_exists(p) and sha256_file(p) == str(e.sha256) and ProjectSettings.load_resource_pack(p, true):
			if k == "previous":
				s["current"] = e
				s.erase("previous")
				write_state(s)
			return {"ok": true, "assets": int(e.version), "from": k}
	return {"ok": false, "assets": 0}

func verify(man: Dictionary) -> Dictionary:
	if not (man.get("payload") is String and man.get("sig") is String):
		return {}
	var key = CryptoKey.new()
	if key.load(PUB, true) != OK:
		push_error("Thiếu khóa công khai cập nhật")
		return {}
	var payload: PackedByteArray = Marshalls.base64_to_raw(man.payload)
	var sig: PackedByteArray = Marshalls.base64_to_raw(man.sig)
	var hc = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(payload)
	var digest = hc.finish()
	if not Crypto.new().verify(HashingContext.HASH_SHA256, digest, sig, key):
		return {}
	var j = JSON.parse_string(payload.get_string_from_utf8())
	return j if j is Dictionary else {}

func _fetch(url: String, headers := PackedStringArray(), to_file := "") -> Array:
	var h = HTTPRequest.new()
	h.timeout = 0 if to_file != "" else 20
	h.download_chunk_size = 1 << 16
	if to_file != "":
		h.download_file = to_file
	add_child(h)
	if h.request(url, headers) != OK:
		h.queue_free()
		return [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray()]
	var t = Timer.new()
	add_child(t)
	t.wait_time = 0.25
	t.timeout.connect(func(): progress.emit(h.get_downloaded_bytes(), h.get_body_size()))
	t.start()
	var r = await h.request_completed
	t.queue_free()
	h.queue_free()
	return [r[0], r[1], r[3]]

## kiểm tra cập nhật; tải gói ảnh nếu có bản mới hợp lệ
func check(server: String) -> void:
	base = server
	var r = await _fetch(server + "/update/manifest.json?t=%d" % Time.get_unix_time_from_system())
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		finished.emit({"ok": false, "why": "net"})
		return
	var man = JSON.parse_string((r[2] as PackedByteArray).get_string_from_utf8())
	var m = verify(man if man is Dictionary else {})
	if m.is_empty():
		finished.emit({"ok": false, "why": "sig"})
		return
	var out = {"ok": true, "manifest": m}
	var plat = {"Android": "android", "Linux": "linux", "iOS": "ios"}.get(OS.get_name(), "windows")
	var app: Dictionary = m.get("app", {})
	if ver_cmp(app_version(), str(app.get("min", "0"))) < 0:
		out["app_required"] = true
	if ver_cmp(app_version(), str(app.get("version", "0"))) < 0:
		out["app_update"] = app.get(plat, {})
		out["app_version"] = app.get("version")
	var a: Dictionary = m.get("assets", {})
	var st = read_state()
	var cur = int(st.get("current", {}).get("version", 0)) if st.get("current") is Dictionary else 0
	cur = maxi(cur, BUNDLED)
	if not a.is_empty() and int(a.get("version", 0)) > cur and ver_cmp(app_version(), str(a.get("min_app", "0"))) >= 0:
		var res = await download_pack(a)
		out["assets"] = res
	finished.emit(out)

func download_pack(a: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(DIR)
	var name = "assets-%d.pck" % int(a.version)
	var part = DIR + name + ".part"
	var size = int(a.size)
	# tiếp tục từ chỗ đứt: ghép phần đã có với phần còn thiếu (Range)
	var have = 0
	if FileAccess.file_exists(part):
		have = FileAccess.open(part, FileAccess.READ).get_length()
		if have > size:
			DirAccess.remove_absolute(part)
			have = 0
	if have < size:
		var tmp = DIR + name + ".chunk"
		var url = str(a.url)
		if not url.begins_with("http"):
			url = base + "/" + url.trim_prefix("/")
		var r = await _fetch(url, PackedStringArray(["Range: bytes=%d-" % have]) if have > 0 else PackedStringArray(), tmp)
		# mã 0 = đứt giữa chừng: coi như máy chủ đã trả đúng đoạn xin (cuối cùng vẫn kiểm SHA-256)
		var resumed: bool = have > 0 and r[1] != 200
		# giữ lại phần đã tải được (kể cả khi đứt giữa chừng) để lần sau tải tiếp
		if FileAccess.file_exists(tmp) and r[1] in [0, 200, 206]:
			var chunk = FileAccess.open(tmp, FileAccess.READ)
			var f: FileAccess
			if resumed:
				f = FileAccess.open(part, FileAccess.READ_WRITE)
				f.seek_end()
			else:
				f = FileAccess.open(part, FileAccess.WRITE)
			while chunk.get_position() < chunk.get_length():
				f.store_buffer(chunk.get_buffer(1 << 16))
			f.close()
			chunk.close()
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)
		if r[0] != HTTPRequest.RESULT_SUCCESS or not (r[1] in [200, 206]):
			var h2 = FileAccess.open(part, FileAccess.READ).get_length() if FileAccess.file_exists(part) else 0
			return {"ok": false, "why": "download", "have": h2}
	var fsz = FileAccess.open(part, FileAccess.READ).get_length()
	if fsz != size:
		return {"ok": false, "why": "size", "have": fsz}
	if sha256_file(part) != str(a.sha256):
		DirAccess.remove_absolute(part)
		return {"ok": false, "why": "hash"}
	DirAccess.rename_absolute(part, DIR + name)
	var st = read_state()
	if st.get("current") is Dictionary:
		var old: Dictionary = st.current
		if st.get("previous") is Dictionary and str(st.previous.file) != str(old.file):
			DirAccess.remove_absolute(DIR + str(st.previous.file))
		st["previous"] = old
	st["current"] = {"version": int(a.version), "file": name, "sha256": str(a.sha256), "min_app": str(a.get("min_app", "0"))}
	write_state(st)
	return {"ok": true, "version": int(a.version), "restart": true}
