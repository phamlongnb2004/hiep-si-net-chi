extends Node
## Kết nối máy chủ: đăng nhập qua HTTPS, chơi qua WebSocket (giao thức v2).
## Chỉ chơi online: mất mạng thì dừng điều khiển, tự kết nối lại và nhận lại toàn bộ trạng thái từ máy chủ.

signal message(m: Dictionary)
signal status(state: String, info: String)   # "connecting" | "online" | "reconnecting" | "closed"

const PROTO := 2
var server = "https://hiep-si-net-chi.phamthanhlong-contact.workers.dev"
var app = "pc"
var token = ""
var user = ""
var srv = 1
var state = "closed"
var ping_ms = 0

var _ws: WebSocketPeer = null
var _want = false            # người chơi đang ở trong game: mất kết nối thì tự nối lại
var _retry = 0.0
var _tries = 0
var _ping_t = 0.0
var _last_rx = 0.0
var _stop_reason = ""

func _ready() -> void:
	app = {"Android": "android", "iOS": "ios"}.get(OS.get_name(), "pc")
	var cfg = FileAccess.open("res://data/config.json", FileAccess.READ)
	if cfg:
		var c = JSON.parse_string(cfg.get_as_text())
		if c is Dictionary and c.has("server"):
			server = str(c.server)
	var env = OS.get_environment("HSNC_SERVER")
	if env != "":
		server = env
	var s = ConfigFile.new()
	if s.load("user://session.cfg") == OK:
		token = s.get_value("s", "token", "")
		user = s.get_value("s", "user", "")
		srv = s.get_value("s", "srv", 1)

func save_session() -> void:
	var s = ConfigFile.new()
	s.set_value("s", "token", token)
	s.set_value("s", "user", user)
	s.set_value("s", "srv", srv)
	s.save("user://session.cfg")

func clear_session() -> void:
	token = ""
	save_session()

## ---------- HTTP ----------
func api(path: String, body: Dictionary) -> Dictionary:
	var h = HTTPRequest.new()
	h.timeout = 15
	add_child(h)
	body["app"] = app
	var err = h.request(server + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		h.queue_free()
		return {"code": 0, "error": "Không kết nối được máy chủ."}
	var r = await h.request_completed
	h.queue_free()
	var code: int = r[1]
	var txt: String = (r[3] as PackedByteArray).get_string_from_utf8()
	var j = JSON.parse_string(txt) if txt != "" else null
	var out: Dictionary = j if j is Dictionary else {}
	out["code"] = code
	if r[0] != HTTPRequest.RESULT_SUCCESS:
		out["error"] = "Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại."
	elif code >= 400 and not out.has("error"):
		out["error"] = "Máy chủ báo lỗi (%d)." % code
	return out

func login(u: String, p: String, register := false) -> Dictionary:
	var r = await api("/api/register" if register else "/api/login", {"user": u, "pass": p})
	if r.code == 200 and r.has("token"):
		token = str(r.token)
		user = str(r.user)
		save_session()
	return r

func servers() -> Dictionary:
	return await api("/api/servers", {"token": token})

func logout() -> void:
	if token != "":
		api("/api/logout", {"token": token})
	leave()
	clear_session()

## ---------- WebSocket ----------
func join(server_id: int) -> void:
	srv = server_id
	save_session()
	_want = true
	_tries = 0
	_open()

func leave() -> void:
	_want = false
	if _ws:
		_ws.close(1000, "bye")
	_ws = null
	_set_state("closed", "")

func _open() -> void:
	var u = server.replace("https://", "wss://").replace("http://", "ws://")
	u += "/ws?token=%s&srv=%d&app=%s&proto=%d&v=%s" % [token.uri_encode(), srv, app, PROTO, ProjectSettings.get_setting("application/config/version", "")]
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 20
	if _ws.connect_to_url(u) != OK:
		_ws = null
		_schedule()
		return
	_set_state("connecting" if _tries == 0 else "reconnecting", "")

func send(m: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(m))

func online() -> bool:
	return state == "online"

func _set_state(s: String, info: String) -> void:
	if s == state and info == "":
		return
	state = s
	status.emit(s, info)

func _schedule() -> void:
	if not _want:
		return
	_tries += 1
	_retry = min(10.0, pow(1.6, _tries))
	_set_state("reconnecting", "Mất kết nối. Đang thử lại sau %d giây…" % int(ceil(_retry)))

func _process(dt: float) -> void:
	if _ws == null:
		if _want and _retry > 0:
			_retry -= dt
			if _retry <= 0:
				_open()
		return
	_ws.poll()
	var st = _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if state != "online":
			_tries = 0
			_last_rx = Time.get_ticks_msec()
			_set_state("online", "")
		while _ws.get_available_packet_count() > 0:
			_last_rx = Time.get_ticks_msec()
			var j = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
			if j is Dictionary:
				if j.get("t") == "pong":
					ping_ms = int(Time.get_ticks_msec() - float(j.get("at", 0)))
					continue
				if j.get("t") == "err":
					_on_err(j)
				message.emit(j)
		_ping_t -= dt
		if _ping_t <= 0:
			_ping_t = 3.0
			send({"t": "ping", "at": Time.get_ticks_msec()})
		# không nhận được gì 12 giây: coi như đứt, nối lại
		if Time.get_ticks_msec() - _last_rx > 12000:
			_ws.close()
	elif st == WebSocketPeer.STATE_CLOSED:
		var code = _ws.get_close_code()
		_ws = null
		if _stop_reason != "":
			var r = _stop_reason
			_stop_reason = ""
			_want = false
			_set_state("closed", r)
		elif code in [4001, 4002, 4003, 4005, 4006, 4007, 4008, 4009, 4010]:
			_want = false
			_set_state("closed", "code:%d" % code)
		else:
			_schedule()

func _on_err(j: Dictionary) -> void:
	var c = str(j.get("code", ""))
	if c in ["auth", "dup", "srv", "app", "save", "update", "ban", "maint", "kick"]:
		_stop_reason = c + ":" + str(j.get("msg", ""))
		if c == "auth":
			clear_session()
