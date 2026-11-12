// Quản trị game: phân quyền, đăng nhập 2 lớp (mật khẩu + mã TOTP), phiên ngắn, chống dò mật khẩu, nhật ký mọi thao tác.
// Mọi kiểm tra quyền nằm ở đây, trên máy chủ. Trang /admin và ứng dụng không chứa bí mật nào.
//
// Vai trò: owner (chủ) > gm (hỗ trợ) > viewer (chỉ xem).
// Lần đầu bật mã 2 lớp cần MÃ KÍCH HOẠT dùng một lần: chủ dùng mã gốc (chỉ lưu dạng băm ở đây), GM dùng mã mời do chủ tạo.
import * as R from '../shared/rules.js';
import { refreshStats } from './sim.js';

const BOOT_HASH = '8589c830546d707be0f730af2652f3faeea08b28318a5973c78fbd9d79e4ccd1'; // sha256(mã kích hoạt gốc của chủ)
const ROLE = { viewer: 1, gm: 2, owner: 3 };
const ROLE_N = { viewer: 'Chỉ xem', gm: 'GM hỗ trợ', owner: 'Chủ' };
const NEED = { // quyền tối thiểu cho mỗi thao tác
  me: 1, overview: 1, catalog: 1, give: 3, hatch_skip: 3, hatching: 1, players: 1, player: 1, online: 1, logs: 1, snaps: 1, tune_get: 1, admins: 1, cfg_get: 1,
  ban: 2, unban: 2, mute: 2, kick: 2, announce: 2,
  // đụng tới tài sản/tài khoản người chơi: chỉ chủ (GM có lạm quyền cũng không tự làm giàu hay chiếm tài khoản được)
  char_edit: 3, item_add: 3, item_del: 3, restore: 3, reset_pw: 3, maint: 3, event: 3, event_stop: 3, servers_set: 3, app_cfg: 3, arena_now: 3, tune_set: 3, tune_reset: 3,
  admin_add: 3, admin_role: 3, admin_del: 3, admin_reset2fa: 3 };
const SESS_IDLE = 30 * 60e3, SESS_MAX = 12 * 3600e3, PRE_T = 5 * 60e3, GM_T = 2 * 3600e3;
const FAIL_MAX = 5, FAIL_LOCK = 15 * 60e3;
const COOKIE = 'hsnc_adm';

const enc = new TextEncoder();
const hex = b => [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join('');
const sha = async s => hex(await crypto.subtle.digest('SHA-256', enc.encode(s)));
const rnd = n => hex(crypto.getRandomValues(new Uint8Array(n)));
const clean = (s, n) => String(s == null ? '' : s).replace(/[\u0000-\u001f\u007f<>]/g, '').slice(0, n);
const int = (v, lo, hi) => { v = Math.floor(+v); return Number.isFinite(v) ? Math.max(lo, Math.min(hi, v)) : lo; };
const B32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
function b32enc(bytes) { let bits = 0, v = 0, o = ''; for (const b of bytes) { v = (v << 8) | b; bits += 8; while (bits >= 5) { o += B32[(v >>> (bits - 5)) & 31]; bits -= 5; } } if (bits) o += B32[(v << (5 - bits)) & 31]; return o; }
function b32dec(s) { let bits = 0, v = 0; const o = []; for (const ch of s.replace(/=+$/, '')) { const i = B32.indexOf(ch); if (i < 0) continue; v = (v << 5) | i; bits += 5; if (bits >= 8) { o.push((v >>> (bits - 8)) & 255); bits -= 8; } } return new Uint8Array(o); }
// mã TOTP 6 số (RFC 6238, 30 giây, HMAC-SHA1) — tương thích Google Authenticator, Microsoft Authenticator...
async function totp(secret, step) {
  const key = await crypto.subtle.importKey('raw', b32dec(secret), { name: 'HMAC', hash: 'SHA-1' }, false, ['sign']);
  const msg = new ArrayBuffer(8), dv = new DataView(msg); dv.setUint32(0, Math.floor(step / 2 ** 32)); dv.setUint32(4, step >>> 0);
  const h = new Uint8Array(await crypto.subtle.sign('HMAC', key, msg)), o = h[19] & 15;
  return String((((h[o] & 127) << 24) | (h[o + 1] << 16) | (h[o + 2] << 8) | h[o + 3]) % 1e6).padStart(6, '0');
}
// trả về bước thời gian khớp (cho phép lệch ±1 bước), 0 nếu sai; không nhận lại mã đã dùng
async function checkOtp(secret, code, last) {
  code = String(code || '').replace(/\s/g, ''); if (!/^\d{6}$/.test(code)) return 0;
  const now = Math.floor(Date.now() / 30000);
  for (const s of [now, now - 1, now + 1]) if (s > (last || 0) && await totp(secret, s) === code) return s;
  return 0;
}

/* ================= khởi tạo ================= */
export function initAdmin(w) {
  const q = s => w.sql.exec(s);
  q(`CREATE TABLE IF NOT EXISTS admins(uid INTEGER PRIMARY KEY, role TEXT NOT NULL, totp TEXT, totp_on INTEGER DEFAULT 0, totp_last INTEGER DEFAULT 0, setup_hash TEXT, setup_exp INTEGER, pending TEXT, added INTEGER, by_uid INTEGER)`);
  q(`CREATE TABLE IF NOT EXISTS admin_sess(th TEXT PRIMARY KEY, uid INTEGER, created INTEGER, last INTEGER, ip TEXT, ua TEXT)`);
  q(`CREATE TABLE IF NOT EXISTS admin_fail(k TEXT PRIMARY KEY, n INTEGER, first INTEGER, until INTEGER)`);
  q(`CREATE TABLE IF NOT EXISTS admin_log(id INTEGER PRIMARY KEY AUTOINCREMENT, at INTEGER, uid INTEGER, who TEXT, action TEXT, target INTEGER, detail TEXT, ip TEXT, src TEXT)`);
  q(`CREATE TABLE IF NOT EXISTS game_log(id INTEGER PRIMARY KEY AUTOINCREMENT, at INTEGER, kind TEXT, uid INTEGER, srv INTEGER, name TEXT, detail TEXT)`);
  q(`CREATE TABLE IF NOT EXISTS chat_log(id INTEGER PRIMARY KEY AUTOINCREMENT, at INTEGER, srv INTEGER, uid INTEGER, name TEXT, text TEXT, scope TEXT)`);
  q(`CREATE TABLE IF NOT EXISTS char_snap(id INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, srv INTEGER, at INTEGER, by_uid INTEGER, reason TEXT, data TEXT)`);
  q(`CREATE TABLE IF NOT EXISTS online_stat(at INTEGER PRIMARY KEY, n INTEGER, v2 INTEGER)`);
  q(`CREATE TABLE IF NOT EXISTS config(k TEXT PRIMARY KEY, v TEXT)`);
  for (const col of ['banned_until INTEGER', 'ban_reason TEXT', 'muted_until INTEGER', 'last_login INTEGER', 'last_ip TEXT'])
    try { q(`ALTER TABLE users ADD COLUMN ${col}`); } catch (e) {}
  q(`CREATE INDEX IF NOT EXISTS game_log_at ON game_log(at)`);
  q(`CREATE INDEX IF NOT EXISTS chat_log_at ON chat_log(at)`);
  // phiên tạm sau khi đúng mật khẩu, chờ mã 2 lớp (lưu trong bảng vì máy chủ có thể ngủ giữa hai bước)
  q(`CREATE TABLE IF NOT EXISTS admin_pre(k TEXT PRIMARY KEY, uid INTEGER, ip TEXT, exp INTEGER, user TEXT, code_ok INTEGER DEFAULT 0)`);
  // chủ ban đầu: các tài khoản trong danh sách ADMINS (tên tài khoản) — chưa có mã 2 lớp thì cần mã kích hoạt gốc
  for (const name of w.ownerNames()) {
    const u = w.one('SELECT id FROM users WHERE uname=?', name);
    if (u && !w.one('SELECT uid FROM admins WHERE uid=?', u.id)) w.sql.exec('INSERT INTO admins(uid,role,setup_hash,added) VALUES(?,?,?,?)', u.id, 'owner', 'boot', Date.now());
  }
  w.cfg = {};
  for (const r of w.sql.exec('SELECT k, v FROM config').toArray()) try { w.cfg[r.k] = JSON.parse(r.v); } catch (e) {}
  if (w.cfg.tune) R.setTune(w.cfg.tune);
  applyEvent(w);
}
export const setCfg = (w, k, v) => { w.cfg[k] = v; w.sql.exec('INSERT INTO config(k,v) VALUES(?,?) ON CONFLICT(k) DO UPDATE SET v=excluded.v', k, JSON.stringify(v)); };
function applyEvent(w) {
  const e = w.cfg.event, on = !!(e && e.until > Date.now());
  R.TUNE.ev = on ? { exp: e.exp, gold: e.gold, drop: e.drop, until: e.until, name: e.name, on: true } : { exp: 1, gold: 1, drop: 1, until: 0, name: '', on: false };
}
// thông tin công khai gửi cho ứng dụng (giá, sự kiện, thông báo) — không có gì bí mật
export function publicCfg(w) {
  const a = w.cfg.ann, e = R.TUNE.ev;
  return { potPrice: R.TUNE.potPrice, shopMul: R.TUNE.shopMul, forgeBonus: R.TUNE.forgeBonus,
    ev: e.on ? { name: e.name, exp: e.exp, gold: e.gold, drop: e.drop, until: e.until } : null,
    ann: a && a.until > Date.now() ? { text: a.text, until: a.until } : null,
    arena: { ...w.arenaCfg(), now: w.cfg.arenaNow && w.cfg.arenaNow.until > Date.now() ? w.cfg.arenaNow : null }, t: Date.now() };
}
export const isStaff = (w, uid) => !!w.one('SELECT uid FROM admins WHERE uid=?', uid);
export const maintOn = w => !!(w.cfg.maint && w.cfg.maint.on);
export const maintMsg = w => (w.cfg.maint && w.cfg.maint.msg) || 'Máy chủ đang bảo trì, vui lòng quay lại sau.';
export function banInfo(w, uid) {
  const u = w.one('SELECT banned_until, ban_reason FROM users WHERE id=?', uid);
  if (!u || !u.banned_until || u.banned_until < Date.now()) return null;
  const when = u.banned_until > Date.now() + 50 * 365 * 86400e3 ? 'vĩnh viễn' : 'đến ' + new Date(u.banned_until + 7 * 3600e3).toISOString().slice(0, 16).replace('T', ' ');
  return 'Tài khoản bị khóa ' + when + (u.ban_reason ? '. Lý do: ' + u.ban_reason : '') + '.';
}
export const mutedUntil = (w, uid) => { const u = w.one('SELECT muted_until FROM users WHERE id=?', uid); return u && u.muted_until > Date.now() ? u.muted_until : 0; };

export function glog(w, kind, c, detail) {
  try { w.sql.exec('INSERT INTO game_log(at,kind,uid,srv,name,detail) VALUES(?,?,?,?,?,?)', Date.now(), kind, c ? c.uid : 0, c ? c.srv : 0, c ? clean((c.ch && c.ch.name) || c.user, 32) : '', clean(detail, 400)); } catch (e) { console.error(e); }
}
export function chatLog(w, c, name, text, scope) {
  try { w.sql.exec('INSERT INTO chat_log(at,srv,uid,name,text,scope) VALUES(?,?,?,?,?,?)', Date.now(), c.srv, c.uid, clean(name, 32), clean(text, 200), scope); } catch (e) {}
}
function alog(w, a, action, target, detail, ip, src) {
  w.sql.exec('INSERT INTO admin_log(at,uid,who,action,target,detail,ip,src) VALUES(?,?,?,?,?,?,?,?)', Date.now(), a ? a.uid : 0, a ? a.user : '', action, target | 0, clean(typeof detail === 'string' ? detail : JSON.stringify(detail), 1000), clean(ip, 64), src || 'web');
}
// việc định kỳ (gọi mỗi giây từ vòng lặp): hết hạn sự kiện, thống kê online, dọn nhật ký
export function adminTick(w) {
  const now = Date.now();
  if (R.TUNE.ev.on && R.TUNE.ev.until <= now) { applyEvent(w); w.broadcastCfg(); }
  const slot = Math.floor(now / 300e3) * 300e3;
  if (w._statAt !== slot) {
    w._statAt = slot; let v2 = 0; for (const c of w.clients.values()) if (c.v2) v2++;
    w.sql.exec('INSERT OR REPLACE INTO online_stat(at,n,v2) VALUES(?,?,?)', slot, w.clients.size, v2);
    w.sql.exec('DELETE FROM online_stat WHERE at<?', now - 30 * 86400e3);
    w.sql.exec('DELETE FROM chat_log WHERE at<?', now - 30 * 86400e3);
    w.sql.exec('DELETE FROM game_log WHERE at<?', now - 90 * 86400e3);
    w.sql.exec('DELETE FROM admin_sess WHERE last<?', now - SESS_IDLE);
    w.sql.exec('DELETE FROM admin_pre WHERE exp<?', now);
    // người chơi bị máy chủ kéo về vị trí quá nhiều lần: ghi nghi vấn gian lận
    for (const c of w.clients.values()) if (c.badMoves > 40) { glog(w, 'cheat', c, 'Bị kéo về vị trí ' + c.badMoves + ' lần trong 5 phút (nghi tăng tốc/dịch chuyển)'); c.badMoves = 0; } else if (c.badMoves) c.badMoves = 0;
  }
}

/* ================= HTTP: /api/admin/* ================= */
const H = { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer' };
const out = (code, o, extra) => new Response(JSON.stringify(o), { status: code, headers: { ...H, ...(extra || {}) } });
const cookieOf = req => { const m = /(?:^|;\s*)hsnc_adm=([0-9a-f]{64})/.exec(req.headers.get('Cookie') || ''); return m ? m[1] : null; };
const setCookie = (tok, age) => ({ 'Set-Cookie': `${COOKIE}=${tok}; Path=/api/admin; HttpOnly; Secure; SameSite=Strict; Max-Age=${age}` });

function failKey(w, k) {
  const now = Date.now(), r = w.one('SELECT * FROM admin_fail WHERE k=?', k);
  return r && r.until > now ? r.until : 0;
}
function failAdd(w, k, max) {
  const now = Date.now(); let r = w.one('SELECT * FROM admin_fail WHERE k=?', k);
  if (!r || now - r.first > FAIL_LOCK) r = { n: 0, first: now, until: 0 };
  r.n++; if (r.n >= (max || FAIL_MAX)) r.until = now + FAIL_LOCK;
  w.sql.exec('INSERT OR REPLACE INTO admin_fail(k,n,first,until) VALUES(?,?,?,?)', k, r.n, r.first, r.until);
}
const failClear = (w, k) => w.sql.exec('DELETE FROM admin_fail WHERE k=?', k);

async function newSess(w, uid, ip, ua) {
  const tok = rnd(32), now = Date.now();
  w.sql.exec('INSERT INTO admin_sess(th,uid,created,last,ip,ua) VALUES(?,?,?,?,?,?)', await sha(tok), uid, now, now, clean(ip, 64), clean(ua, 200));
  return tok;
}
async function sessOf(w, req) {
  const tok = cookieOf(req); if (!tok) return null;
  const th = await sha(tok), s = w.one('SELECT * FROM admin_sess WHERE th=?', th), now = Date.now();
  if (!s) return null;
  if (now - s.last > SESS_IDLE || now - s.created > SESS_MAX || s.ua !== clean(req.headers.get('User-Agent'), 200)) { w.sql.exec('DELETE FROM admin_sess WHERE th=?', th); return null; }
  const a = w.one('SELECT a.uid, a.role, a.totp_on, u.username user FROM admins a JOIN users u ON u.id=a.uid WHERE a.uid=?', s.uid);
  if (!a || !a.totp_on) { w.sql.exec('DELETE FROM admin_sess WHERE th=?', th); return null; }
  w.sql.exec('UPDATE admin_sess SET last=? WHERE th=?', now, th);
  return { ...a, th };
}

export async function adminHttp(w, req, url) {
  const ip = req.headers.get('CF-Connecting-IP') || '', ua = req.headers.get('User-Agent') || '';
  const act = url.pathname.slice('/api/admin/'.length);
  if (req.method !== 'POST') return out(405, { error: 'Sai phương thức' });
  // chống giả mạo yêu cầu từ trang khác: chỉ nhận JSON, có tiêu đề riêng, cùng nguồn
  const origin = req.headers.get('Origin');
  if (req.headers.get('X-HSNC-Admin') !== '1' || !/application\/json/.test(req.headers.get('Content-Type') || '') || (origin && origin !== url.origin)) return out(403, { error: 'Từ chối' });
  let b; try { b = await req.json(); } catch (e) { return out(400, { error: 'Dữ liệu không hợp lệ' }); }
  if (!b || typeof b !== 'object') return out(400, { error: 'Dữ liệu không hợp lệ' });

  /* ---- đăng nhập ---- */
  if (act === 'login') {
    const name = String(b.user || '').trim().toLowerCase().slice(0, 32), pass = String(b.pass || '').slice(0, 100);
    const lk = Math.max(failKey(w, 'ip:' + ip), failKey(w, 'iu:' + ip + '|' + name), failKey(w, 'u:' + name));
    if (lk) return out(429, { error: 'Sai quá nhiều lần. Thử lại sau ' + Math.ceil((lk - Date.now()) / 60e3) + ' phút.' });
    const u = w.one('SELECT * FROM users WHERE uname=?', name);
    const good = u && await w.checkPass(u, pass);
    if (good && w.ownerNames().includes(u.uname) && !w.one('SELECT uid FROM admins WHERE uid=?', u.id)) w.sql.exec('INSERT INTO admins(uid,role,setup_hash,added) VALUES(?,?,?,?)', u.id, 'owner', 'boot', Date.now());
    const a = good && w.one('SELECT * FROM admins WHERE uid=?', u.id);
    if (!a) { failAdd(w, 'ip:' + ip, 10); failAdd(w, 'iu:' + ip + '|' + name); failAdd(w, 'u:' + name, 25); alog(w, null, 'login_fail', u ? u.id : 0, name, ip); return out(401, { error: 'Sai tài khoản hoặc mật khẩu, hoặc tài khoản không có quyền quản trị.' }); }
    const pre = rnd(24); w.sql.exec('INSERT INTO admin_pre(k,uid,ip,exp,user) VALUES(?,?,?,?,?)', await sha(pre), u.id, ip, Date.now() + PRE_T, u.username);
    return out(200, { step: a.totp_on ? 'otp' : 'setup', pre });
  }
  const preK = b.pre ? await sha(String(b.pre)) : '', P = preK ? w.one('SELECT * FROM admin_pre WHERE k=?', preK) : null;
  const preOk = P && P.exp > Date.now() && P.ip === ip;
  if (act === 'otp' || act === 'setup' || act === 'setup_ok') {
    if (!preOk) return out(401, { error: 'Phiên đăng nhập đã hết hạn, hãy nhập lại mật khẩu.' });
    const a = w.one('SELECT * FROM admins WHERE uid=?', P.uid); if (!a) return out(401, { error: 'Không có quyền.' });
    if (failKey(w, 'u2:' + P.uid)) return out(429, { error: 'Sai mã quá nhiều lần. Thử lại sau 15 phút.' });
    if (act === 'otp') {
      if (!a.totp_on) return out(400, { error: 'Chưa bật mã 2 lớp.' });
      const s = await checkOtp(a.totp, b.otp, a.totp_last);
      if (!s) { failAdd(w, 'u2:' + P.uid); failAdd(w, 'ip:' + ip); alog(w, { uid: P.uid, user: P.user }, 'otp_fail', P.uid, '', ip); return out(401, { error: 'Mã 2 lớp không đúng.' }); }
      w.sql.exec('UPDATE admins SET totp_last=? WHERE uid=?', s, P.uid);
    } else if (act === 'setup') {
      if (a.totp_on) return out(400, { error: 'Tài khoản đã bật mã 2 lớp.' });
      const h = await sha(String(b.code || '').trim().toUpperCase());
      const okCode = (a.setup_hash === 'boot' && h === BOOT_HASH) || (a.setup_hash && a.setup_hash !== 'boot' && h === a.setup_hash && (a.setup_exp || 0) > Date.now());
      if (!okCode) { failAdd(w, 'u2:' + P.uid); failAdd(w, 'ip:' + ip); alog(w, { uid: P.uid, user: P.user }, 'setup_fail', P.uid, '', ip); return out(401, { error: 'Mã kích hoạt không đúng hoặc đã hết hạn.' }); }
      const secret = b32enc(crypto.getRandomValues(new Uint8Array(20)));
      w.sql.exec('UPDATE admins SET pending=? WHERE uid=?', secret, P.uid);
      w.sql.exec('UPDATE admin_pre SET code_ok=1 WHERE k=?', preK);
      return out(200, { secret, uri: `otpauth://totp/${encodeURIComponent('Hiệp Sĩ Nét Chì:' + P.user)}?secret=${secret}&issuer=${encodeURIComponent('Hiệp Sĩ Nét Chì')}&algorithm=SHA1&digits=6&period=30` });
    } else {
      if (!P.code_ok || !a.pending) return out(400, { error: 'Hãy nhập mã kích hoạt trước.' });
      const s = await checkOtp(a.pending, b.otp, 0);
      if (!s) { failAdd(w, 'u2:' + P.uid); return out(401, { error: 'Mã 2 lớp không đúng. Kiểm tra giờ trên điện thoại rồi thử lại.' }); }
      w.sql.exec('UPDATE admins SET totp=pending, pending=NULL, totp_on=1, totp_last=?, setup_hash=NULL, setup_exp=NULL WHERE uid=?', s, P.uid);
      alog(w, { uid: P.uid, user: P.user }, 'setup_2fa', P.uid, '', ip);
    }
    w.sql.exec('DELETE FROM admin_pre WHERE k=?', preK); failClear(w, 'iu:' + ip + '|' + P.user.toLowerCase()); failClear(w, 'u2:' + P.uid);
    const tok = await newSess(w, P.uid, ip, ua);
    alog(w, { uid: P.uid, user: P.user }, 'login', P.uid, '', ip);
    return out(200, { ok: true }, setCookie(tok, SESS_MAX / 1000));
  }

  /* ---- các thao tác cần phiên quản trị ---- */
  const A = await sessOf(w, req);
  if (!A) return out(401, { error: 'auth' });
  if (act === 'logout') { w.sql.exec('DELETE FROM admin_sess WHERE th=?', A.th); return out(200, { ok: true }, setCookie('0'.repeat(64), 0)); }
  const need = NEED[act]; if (!need) return out(404, { error: 'Không có thao tác này' });
  if (ROLE[A.role] < need) { alog(w, A, 'denied', 0, act, ip); return out(403, { error: 'Bạn không có quyền làm việc này.' }); }
  try {
    const r = await ACT[act](w, A, b, ip);
    if (need >= 2) alog(w, A, act, b.uid | 0, logDetail(act, b, r), ip);
    return out(200, r || { ok: true });
  } catch (e) {
    if (e && e.user) return out(400, { error: e.user });
    console.error(e); return out(500, { error: 'Lỗi máy chủ' });
  }
}
const bad = msg => { const e = new Error(msg); e.user = msg; throw e; };
const logDetail = (act, b, r) => { const o = { ...b }; delete o.pre; if (r && r.temp) o.temp = '(đã tạo)'; if (r && r.code) o.code = '(đã tạo)'; return o; };

/* ---- người chơi: chỉnh nhân vật (đang online thì sửa ngay trong trận, offline thì sửa bản lưu) ---- */
const onlineOf = (w, uid, srv) => { for (const c of w.clients.values()) if (c.uid === uid && (srv == null || c.srv === srv)) return c; return null; };
function snapChar(w, uid, srv, d, by, reason) { w.sql.exec('INSERT INTO char_snap(uid,srv,at,by_uid,reason,data) VALUES(?,?,?,?,?,?)', uid, srv, Date.now(), by, reason, JSON.stringify(d)); }
function editChar(w, A, uid, srv, reason, fn) {
  let c = onlineOf(w, uid, srv);
  if (c && !c.v2) { w.sendTo(c, { t: 'err', code: 'kick', msg: 'Quản trị đang cập nhật nhân vật, hãy vào lại.' }); try { c.ws.close(4010, 'kick'); } catch (e) {} w.drop(c); c = null; }
  if (c && c.ch) {
    snapChar(w, uid, srv, c.ch, A.uid, reason); fn(c.ch); c.ch = R.normalizeChar(c.ch);
    refreshStats(c.f, c.ch, true); c.dirty = true; c.bagDirty = true; w.sendMe(c); w.writeChar(c); return c.ch;
  }
  const row = w.one('SELECT data FROM chars WHERE user_id=? AND srv=?', uid, srv); if (!row) bad('Không có nhân vật trên máy chủ này.');
  const d = JSON.parse(row.data); snapChar(w, uid, srv, d, A.uid, reason); fn(d);
  w.sql.exec('UPDATE chars SET data=?, lv=?, kills=?, updated=? WHERE user_id=? AND srv=?', JSON.stringify(d), d.lv | 0, d.kills | 0, Date.now(), uid, srv);
  return d;
}
function kickUser(w, uid, msg, code) {
  for (const c of [...w.clients.values()]) if (c.uid === uid) { w.sendTo(c, { t: 'err', code: code || 'kick', msg }); try { c.ws.close(code === 'ban' ? 4008 : 4010, code || 'kick'); } catch (e) {} w.drop(c); }
}
const userRow = (w, uid) => { const u = w.one('SELECT id, username, created, banned_until, ban_reason, muted_until, last_login, last_ip FROM users WHERE id=?', uid | 0); if (!u) bad('Không có tài khoản.'); return u; };
const eggN = sp => { try { return R.eggName(sp); } catch (e) { return String(sp || ''); } };
const charSummary = d => ({ name: d.name, cls: d.cls, lv: d.lv, exp: d.exp, gold: d.gold, stones: d.stones, pots: d.pots, kills: d.kills, map: d.map, inv: d.inv || [], eq: d.eq || {}, sk: d.sk, bad: d.bad || null, charms: d.charms | 0, hatch: d.hatch ? { ...d.hatch, egg: eggN(d.hatch.sp) } : null, pets: (d.pets || []).map(p => ({ sp: p.sp, name: p.name, lv: p.lv, star: p.star })) });

const ACT = {
  async me(w, A) { return { user: A.user, role: A.role, roleName: ROLE_N[A.role], uid: A.uid, servers: w.servers().map(x => ({ id: x.id, name: x.name })) }; },
  async overview(w) {
    const now = Date.now(), n = s => (w.one(s) || {}).n | 0;
    const online = {}; let v2 = 0; for (const c of w.clients.values()) { online[c.srv] = (online[c.srv] || 0) + 1; if (c.v2) v2++; }
    return {
      users: n('SELECT COUNT(*) n FROM users'), chars: n('SELECT COUNT(*) n FROM chars'),
      new24: w.one('SELECT COUNT(*) n FROM users WHERE created>?', now - 86400e3).n | 0, new7: w.one('SELECT COUNT(*) n FROM users WHERE created>?', now - 7 * 86400e3).n | 0,
      active24: w.one('SELECT COUNT(*) n FROM chars WHERE updated>?', now - 86400e3).n | 0,
      banned: w.one('SELECT COUNT(*) n FROM users WHERE banned_until>?', now).n | 0, anomalies: n('SELECT COUNT(*) n FROM anomalies'),
      online: w.clients.size, onlineV2: v2, bySrv: w.servers().map(s => ({ id: s.id, name: s.name, open: s.open !== false, online: online[s.id] || 0 })),
      top: w.sql.exec('SELECT c.user_id uid, c.srv, c.name, c.cls, c.lv, c.kills FROM chars c ORDER BY c.lv DESC, c.kills DESC LIMIT 10').toArray(),
      hist: w.sql.exec('SELECT at, n, v2 FROM online_stat WHERE at>? ORDER BY at', now - 86400e3).toArray(),
      events: w.sql.exec('SELECT at, kind, uid, srv, name, detail FROM game_log ORDER BY id DESC LIMIT 12').toArray(),
      maint: w.cfg.maint || { on: false }, cfg: publicCfg(w)
    };
  },
  async online(w) {
    return { list: [...w.clients.values()].map(c => ({ id: c.id, uid: c.uid, user: c.user, srv: c.srv, v2: !!c.v2, app: c.app || (c.v2 ? '' : 'v1'), name: c.ch ? c.ch.name : (c.st ? c.st[8] : ''), lv: c.ch ? c.ch.lv : (c.st ? c.st[7] : 0), map: c.map, khu: c.inst ? c.inst.khu : 0, hidden: !!c.hidden, gm: !!(c.gm && c.gm.until > Date.now()) })) };
  },
  async players(w, A, b) {
    const q = '%' + clean(b.q, 32).trim().toLowerCase().replace(/[%_]/g, '') + '%';
    const ids = w.sql.exec(`SELECT DISTINCT u.id FROM users u LEFT JOIN chars c ON c.user_id=u.id WHERE u.uname LIKE ? OR lower(c.name) LIKE ? ORDER BY u.id DESC LIMIT 50`, q, q).toArray().map(r => r.id);
    return { list: ids.map(id => {
      const u = w.one('SELECT id, username, created, banned_until, last_login FROM users WHERE id=?', id);
      return { ...u, banned: u.banned_until > Date.now(), online: !!onlineOf(w, id), staff: (w.one('SELECT role FROM admins WHERE uid=?', id) || {}).role || '',
        chars: w.sql.exec('SELECT srv, name, cls, lv, kills, updated FROM chars WHERE user_id=?', id).toArray() };
    }) };
  },
  async player(w, A, b) {
    const u = userRow(w, b.uid), uid = u.id;
    const chars = w.sql.exec('SELECT srv, data, updated FROM chars WHERE user_id=?', uid).toArray().map(r => {
      const c = onlineOf(w, uid, r.srv), d = c && c.ch ? c.ch : JSON.parse(r.data);
      return { srv: r.srv, updated: r.updated, online: !!c, ...charSummary(d), anomalies: (w.one('SELECT flags FROM anomalies WHERE user_id=? AND srv=?', uid, r.srv) || {}).flags || '' };
    });
    return { user: { ...u, banned: u.banned_until > Date.now(), muted: u.muted_until > Date.now(), staff: (w.one('SELECT role FROM admins WHERE uid=?', uid) || {}).role || '' },
      chars, sessions: w.one('SELECT COUNT(*) n FROM sessions WHERE user_id=?', uid).n | 0,
      friends: (() => { try { return w.one('SELECT COUNT(*) n FROM friends WHERE uid=?', uid).n | 0; } catch (e) { return 0; } })(),
      history: w.sql.exec('SELECT at, who, action, detail FROM admin_log WHERE target=? ORDER BY id DESC LIMIT 30', uid).toArray(),
      events: w.sql.exec('SELECT at, kind, srv, detail FROM game_log WHERE uid=? ORDER BY id DESC LIMIT 30', uid).toArray(),
      backupV1: w.sql.exec('SELECT srv FROM chars_v1_backup WHERE user_id=?', uid).toArray().map(r => r.srv) };
  },
  async snaps(w, A, b) { return { list: w.sql.exec('SELECT s.id, s.srv, s.at, s.reason, u.username who FROM char_snap s LEFT JOIN users u ON u.id=s.by_uid WHERE s.uid=? ORDER BY s.id DESC LIMIT 50', b.uid | 0).toArray() }; },
  async char_edit(w, A, b) {
    const s = b.set || {};
    const d = editChar(w, A, userRow(w, b.uid).id, b.srv | 0, 'Sửa chỉ số', ch => {
      if (s.lv != null) { ch.lv = int(s.lv, 1, R.MAX_LV); ch.exp = 0; }
      if (s.exp != null) ch.exp = int(s.exp, 0, 1e12);
      for (const k of ['gold', 'stones', 'pots', 'kills']) if (s[k] != null) ch[k] = int(s[k], 0, k === 'pots' ? R.POT_MAX : 1e12);
      if (s.name != null) { const n = clean(s.name, 16).trim(); if (!/^[\p{L}\p{N}_ ]{3,16}$/u.test(n)) bad('Tên nhân vật 3–16 ký tự.'); ch.name = n; }
      if (Array.isArray(s.sk)) ch.sk = [0, 1, 2, 3, 4, 5].map(i => (i === 0 || s.sk[i]) ? 1 : 0);
      if (Array.isArray(s.sk)) ch.books = ch.books.map((v, i) => v || ch.sk[i]);
    });
    if (s.name != null) w.sql.exec('UPDATE chars SET name=? WHERE user_id=? AND srv=?', d.name, b.uid | 0, b.srv | 0);
    return { ok: true, char: charSummary(d) };
  },
  async item_add(w, A, b) {
    const slot = String(b.slot), cls = R.isFree(slot) ? R.CLS_KEYS[0] : String(b.cls), r = int(b.r, 0, 3), lvl = int(b.lvl, 1, R.MAX_LV), up = int(b.up, 0, D_forgeMax());
    if (!R.CLS_KEYS.includes(cls) || !R.SLOTS.includes(slot)) bad('Phái hoặc ô đồ không hợp lệ.');
    const d = editChar(w, A, userRow(w, b.uid).id, b.srv | 0, 'Tặng đồ', ch => {
      if ((ch.inv || []).length >= R.INV_MAX) bad('Túi người chơi đã đầy.');
      const it = R.shopItem(cls, slot, r, lvl, 'a' + Date.now().toString(36) + rnd(3)); if (up) it.up = up;
      if (b.name) it.name = clean(b.name, 40);
      ch.inv.push(it);
    });
    return { ok: true, char: charSummary(d) };
  },
  // danh mục mọi vật phẩm đang có trong game (để chọn và tặng)
  async catalog(w, A, b) {
    const lvl = int(b.lvl || 1, 1, R.MAX_LV), gear = [];
    for (const cls of R.CLS_KEYS) for (let r = 0; r < 4; r++) R.SLOTS.forEach((slot, si) => {
      const free = R.isFree(slot); if (free && cls !== R.CLS_KEYS[0]) return; // dây chuyền, cánh: không theo phái, chỉ một bản
      const base = R.shopItem(cls, slot, r, lvl, 'x'), mx = {};
      for (const k in base.st) mx[k] = Math.round(R.baseStats(slot, lvl, r)[k] * 1.25);
      const bd = R.band(lvl);
      gear.push({ cls: free ? '' : cls, slot, r, si, name: base.name, st: base.st, max: mx, icon: slot === 'wing' ? `admin-icons/acc/wing/${r}.webp` : free ? `admin-icons/acc2/${slot}/${bd}.webp` : `admin-icons/gear2/${cls}/${bd}/${slot}.webp` });
    });
    const books = {}; for (const cls of R.CLS_KEYS) books[cls] = R.D.skills[cls].map((s, i) => ({ i, n: s.n, d: s.d, req: s.req, price: s.price, icon: `admin-icons/skills/${cls}/${i}.webp` }));
    return { lvl, gear, books, cls: Object.fromEntries(R.CLS_KEYS.map(k => [k, R.D.cls[k].n])), rar: R.D.rar.map(x => ({ n: x.n, c: x.c })),
      max: { lv: R.MAX_LV, up: R.D.forge.max, inv: R.INV_MAX, pots: R.POT_MAX },
      misc: R.giftMisc() };
  },
  // tặng nhiều vật phẩm một lần: cho một nhân vật, hoặc cho mọi người đang online trên một máy chủ
  async give(w, A, b) {
    const gear = Array.isArray(b.gear) ? b.gear.slice(0, 30) : [], books = Array.isArray(b.books) ? b.books.slice(0, 6) : [];
    // vật phẩm khác: b.misc {khóa: số} (bản trang cũ gửi pots/stones/gold/exp ở ngoài; 'pots' cũ = bình máu vừa)
    const MISC = R.giftMisc(), mi = Object.assign({}, b.misc && typeof b.misc === 'object' ? b.misc : {});
    for (const k of ['pots', 'stones', 'gold', 'exp']) if (b[k] && mi[k] == null) mi[k] = b[k];
    const n = k => { const d = MISC.find(x => x.k === k); return d ? int(mi[k] || 0, 0, d.max) : 0; };
    const eggN = MISC.filter(x => x.egg || x.book || x.myth).reduce((a, x) => a + n(x.k), 0);
    const make = g => {
      const slot = String(g.slot), cls = R.isFree(slot) ? R.CLS_KEYS[0] : String(g.cls), r = int(g.r, 0, 3), lvl = int(g.lvl, 1, R.MAX_LV);
      if (!R.CLS_KEYS.includes(cls) || !R.SLOTS.includes(slot)) bad('Món đồ không hợp lệ.');
      const it = R.shopItem(cls, slot, r, lvl, 'a' + Date.now().toString(36) + rnd(4)); delete it.shop;
      const mx = R.maxItemStat(it);
      if (g.q === 'max') for (const k in it.st) it.st[k] = Math.round(R.baseStats(slot, lvl, r)[k] * 1.25);
      else if (g.q === 'custom' && g.st) for (const k in it.st) it.st[k] = int(g.st[k] ?? it.st[k], 1, mx[k]);
      const up = int(g.up, 0, R.D.forge.max); if (up) it.up = up;
      if (g.lock) it.lock = 1;
      return it;
    };
    const items = []; for (const g of gear) { const q = int(g.qty || 1, 1, 30); for (let i = 0; i < q; i++) items.push(g); }
    if (!items.length && !books.length && !MISC.some(x => n(x.k))) bad('Chưa chọn vật phẩm nào.');
    const note = clean(b.note, 120);
    const apply = (ch) => {
      const room = R.INV_MAX - (ch.inv || []).length; if (items.length + eggN > room) bad('Túi của ' + ch.name + ' chỉ còn ' + Math.max(0, room) + ' ô trống.');
      const got = [];
      for (const g of items) { const it = make(g); ch.inv.push(it); got.push((it.up ? '+' + it.up + ' ' : '') + it.name); }
      for (const x of MISC) {
        const q = n(x.k); if (!q) continue;
        if (x.egg) { for (let i = 0; i < q; i++) ch.inv.push(R.newEgg(x.egg, 'e' + Date.now().toString(36) + rnd(4))); got.push(q + ' ' + x.n.toLowerCase()); }
        else if (x.book) { for (let i = 0; i < q; i++) ch.inv.push(R.newBook('b' + Date.now().toString(36) + rnd(4))); got.push(q + ' ' + x.n); }
        else if (x.myth) { for (let i = 0; i < q; i++) ch.inv.push(R.genMythic(Math.random, Math.max(60, Math.min(R.MAX_LV, ch.lv | 0)), 'y' + Date.now().toString(36) + rnd(4), x.myth)); got.push(q + ' ' + x.n); }
        else if (x.k === 'exp') { R.addExp(ch, q); got.push(q + ' kinh nghiệm'); }
        else if (x.max === R.POT_MAX) { const add = Math.max(0, Math.min(q, R.POT_MAX - (ch[x.k] | 0))); ch[x.k] = (ch[x.k] | 0) + add; got.push(add + ' ' + x.n.toLowerCase()); }
        else { ch[x.k] = (ch[x.k] | 0) + q; got.push(q + ' ' + x.n.toLowerCase()); }
      }
      for (const x of books) { const i = int(x.i ?? x, 0, 5); if (!ch.books[i]) { ch.books[i] = 1; got.push('sách ' + R.D.skills[ch.cls][i].n); } if (x.learn && ch.lv >= R.D.skills[ch.cls][i].req) ch.sk[i] = 1; }
      return got;
    };
    const tell = (uid, srv, got) => { for (const c of w.clients.values()) if (c.uid === uid && c.srv === srv) w.sendTo(c, { t: 'log', text: '🎁 Quản trị tặng bạn: ' + got.join(', ') + (note ? ' — ' + note : ''), col: '#ffd23f' }); };
    if (b.online) {
      const srv = b.srv | 0, done = [], fail = [];
      for (const c of [...w.clients.values()]) if (c.srv === srv && c.v2 && c.ch) {
        try { let got; editChar(w, A, c.uid, srv, 'Quà cho mọi người', ch => { got = apply(ch); }); tell(c.uid, srv, got); done.push(c.ch.name); }
        catch (e) { fail.push((c.ch && c.ch.name) + ': ' + (e.user || 'lỗi')); }
      }
      if (!done.length && !fail.length) bad('Không có ai đang online trên máy chủ này.');
      return { ok: true, n: done.length, done, fail };
    }
    const uid = userRow(w, b.uid).id, srv = b.srv | 0; let got;
    const d = editChar(w, A, uid, srv, 'Tặng vật phẩm', ch => { got = apply(ch); });
    tell(uid, srv, got);
    return { ok: true, n: 1, got, char: charSummary(d) };
  },
  // mọi nhân vật đang ấp trứng (trang Người chơi): để quản trị bỏ qua thời gian ấp cho từng người
  async hatching(w) {
    const L = new Map();
    for (const r of w.sql.exec("SELECT c.user_id AS uid, c.srv AS srv, c.data AS data, u.username AS user FROM chars c JOIN users u ON u.id=c.user_id WHERE json_extract(c.data,'$.hatch.end') IS NOT NULL").toArray()) {
      try { const d = JSON.parse(r.data); if (d.hatch) L.set(r.uid + ':' + r.srv, { uid: r.uid, srv: r.srv, user: r.user, name: d.name, lv: d.lv, sp: d.hatch.sp, egg: eggN(d.hatch.sp), end: d.hatch.end }); } catch (e) {}
    }
    for (const c of w.clients.values()) if (c.v2 && c.ch) { const k = c.uid + ':' + c.srv; if (c.ch.hatch) L.set(k, { uid: c.uid, srv: c.srv, user: c.user, name: c.ch.name, lv: c.ch.lv, sp: c.ch.hatch.sp, egg: eggN(c.ch.hatch.sp), end: c.ch.hatch.end, online: 1 }); else L.delete(k); }
    return { list: [...L.values()].sort((a, b) => a.end - b.end) };
  },
  // bỏ qua thời gian ấp trứng (chỉ quản trị): trứng nở ngay, người chơi tới Bà Ấp Trứng để nhận
  async hatch_skip(w, A, b) {
    const d = editChar(w, A, userRow(w, b.uid).id, b.srv | 0, 'Bỏ qua thời gian ấp trứng', ch => {
      if (!ch.hatch) bad('Nhân vật này không có trứng đang ấp.');
      ch.hatch.end = Date.now();
    });
    for (const c of w.clients.values()) if (c.uid === (b.uid | 0) && c.srv === (b.srv | 0)) w.sendTo(c, { t: 'log', text: '🥚 Quản trị đã cho trứng của bạn nở ngay. Tới Bà Ấp Trứng để nhận pet!', col: '#ffd23f' });
    return { ok: true, char: charSummary(d) };
  },
  async item_del(w, A, b) {
    const d = editChar(w, A, userRow(w, b.uid).id, b.srv | 0, 'Xóa đồ', ch => {
      const i = ch.inv.findIndex(it => String(it.id) === String(b.id));
      if (i >= 0) { ch.inv.splice(i, 1); return; }
      for (const k of R.SLOTS) if (ch.eq[k] && String(ch.eq[k].id) === String(b.id)) { ch.eq[k] = null; return; }
      bad('Không thấy món đồ.');
    });
    return { ok: true, char: charSummary(d) };
  },
  async ban(w, A, b) {
    const u = userRow(w, b.uid); if (w.one('SELECT role FROM admins WHERE uid=?', u.id) && A.role !== 'owner') bad('Chỉ chủ mới khóa được tài khoản quản trị.');
    if (u.id === A.uid) bad('Không tự khóa chính mình.');
    const h = +b.hours, until = h > 0 ? Date.now() + Math.min(h, 24 * 3650) * 3600e3 : Date.now() + 100 * 365 * 86400e3, reason = clean(b.reason, 200);
    w.sql.exec('UPDATE users SET banned_until=?, ban_reason=? WHERE id=?', until, reason, u.id);
    w.sql.exec('DELETE FROM sessions WHERE user_id=?', u.id);
    kickUser(w, u.id, banInfo(w, u.id), 'ban'); glog(w, 'ban', { uid: u.id, srv: 0, user: u.username }, 'Bị ' + A.user + ' khóa: ' + reason);
    return { ok: true };
  },
  async unban(w, A, b) { w.sql.exec('UPDATE users SET banned_until=NULL, ban_reason=NULL WHERE id=?', userRow(w, b.uid).id); return { ok: true }; },
  async mute(w, A, b) {
    const u = userRow(w, b.uid), m = +b.minutes || 0;
    w.sql.exec('UPDATE users SET muted_until=? WHERE id=?', m > 0 ? Date.now() + Math.min(m, 525600) * 60e3 : null, u.id);
    for (const c of w.clients.values()) if (c.uid === u.id) w.sendTo(c, { t: 'log', text: m > 0 ? 'Bạn bị cấm trò chuyện ' + m + ' phút.' : 'Bạn đã được trò chuyện lại.', col: '#ffb347' });
    return { ok: true };
  },
  async kick(w, A, b) { const u = userRow(w, b.uid); kickUser(w, u.id, clean(b.msg, 120) || 'Bạn đã bị quản trị mời ra khỏi game.'); return { ok: true }; },
  async reset_pw(w, A, b) {
    const u = userRow(w, b.uid); if (w.one('SELECT role FROM admins WHERE uid=?', u.id) && A.role !== 'owner') bad('Chỉ chủ mới đặt lại mật khẩu tài khoản quản trị.');
    const A2 = 'abcdefghjkmnpqrstuvwxyz23456789', bytes = crypto.getRandomValues(new Uint8Array(10));
    const temp = [...bytes].map(x => A2[x % A2.length]).join('');
    await w.setPass(u.id, temp); w.sql.exec('DELETE FROM sessions WHERE user_id=?', u.id); kickUser(w, u.id, 'Mật khẩu đã được đặt lại, hãy đăng nhập bằng mật khẩu mới.');
    return { ok: true, temp };
  },
  async restore(w, A, b) {
    const u = userRow(w, b.uid), srv = b.srv | 0;
    let data;
    if (b.from === 'v1') { const r = w.one('SELECT data FROM chars_v1_backup WHERE user_id=? AND srv=?', u.id, srv); if (!r) bad('Không có bản sao lưu cũ.'); data = JSON.parse(r.data); }
    else { const r = w.one('SELECT data, srv FROM char_snap WHERE id=? AND uid=?', b.snap | 0, u.id); if (!r) bad('Không có bản lưu này.'); data = JSON.parse(r.data); if (r.srv !== srv) bad('Bản lưu thuộc máy chủ khác.'); }
    const d = editChar(w, A, u.id, srv, 'Trước khi khôi phục', ch => { for (const k of Object.keys(ch)) delete ch[k]; Object.assign(ch, data); });
    return { ok: true, char: charSummary(d) };
  },
  async announce(w, A, b) {
    const text = clean(b.text, 200).trim(), min = Math.min(int(b.minutes, 0, 10080), 10080);
    setCfg(w, 'ann', text ? { text, until: Date.now() + Math.max(1, min) * 60e3, by: A.user } : null);
    if (text) for (const c of w.clients.values()) w.sendTo(c, c.v2 ? { t: 'ann', text } : { t: 'chat', id: 0, n: '📢 Thông báo', text, all: true });
    w.broadcastCfg(); return { ok: true };
  },
  async maint(w, A, b) {
    setCfg(w, 'maint', { on: !!b.on, msg: clean(b.msg, 200), by: A.user, at: Date.now() });
    if (b.on) for (const c of [...w.clients.values()]) if (!isStaff(w, c.uid)) { w.sendTo(c, { t: 'err', code: 'maint', msg: maintMsg(w) }); try { c.ws.close(4009, 'maint'); } catch (e) {} w.drop(c); }
    return { ok: true };
  },
  async event(w, A, b) {
    const n = (v, hi) => Math.max(1, Math.min(hi, +v || 1));
    const ev = { name: clean(b.name, 60) || 'Sự kiện', exp: n(b.exp, 10), gold: n(b.gold, 10), drop: n(b.drop, 5), until: Date.now() + Math.max(.25, Math.min(+b.hours || 1, 336)) * 3600e3, by: A.user };
    setCfg(w, 'event', ev); applyEvent(w); w.broadcastCfg();
    for (const c of w.clients.values()) if (c.v2) w.sendTo(c, { t: 'ann', text: '🎉 ' + ev.name + ': x' + ev.exp + ' kinh nghiệm, x' + ev.gold + ' vàng, x' + ev.drop + ' rơi đồ!' });
    return { ok: true };
  },
  async event_stop(w) { setCfg(w, 'event', null); applyEvent(w); w.broadcastCfg(); return { ok: true }; },
  async cfg_get(w) { return { servers: w.servers(), min_app: w.cfg.min_app || w.env.MIN_APP || '', v1: w.cfg.v1 || w.env.V1 || 'on', maint: w.cfg.maint || { on: false }, ann: w.cfg.ann || null, event: w.cfg.event || null, khuMax: w.khuMax(), arena: w.arenaCfg(), arenaNow: w.cfg.arenaNow && w.cfg.arenaNow.until > Date.now() ? w.cfg.arenaNow : null }; },
  async servers_set(w, A, b) {
    if (!Array.isArray(b.list) || !b.list.length || b.list.length > 20) bad('Danh sách máy chủ không hợp lệ.');
    const seen = new Set(), list = b.list.map(s => { const id = int(s.id, 1, 99); if (seen.has(id)) bad('Trùng số máy chủ.'); seen.add(id); return { id, name: clean(s.name, 24) || 'Server ' + id, tag: clean(s.tag, 12), open: s.open !== false }; });
    setCfg(w, 'servers', list); return { ok: true, servers: list };
  },
  async app_cfg(w, A, b) {
    if (b.min_app != null) { const v = clean(b.min_app, 16).trim(); if (v && !/^\d+(\.\d+){0,3}$/.test(v)) bad('Phiên bản dạng 2.1.0'); setCfg(w, 'min_app', v); }
    if (b.v1 != null) setCfg(w, 'v1', b.v1 === 'off' ? 'off' : 'on');
    if (b.khuMax != null) setCfg(w, 'khuMax', int(b.khuMax, 1, 100));
    if (b.arena != null) {
      const slots = String(b.arena.slots || '').split(/[ ,;]+/).filter(Boolean);
      if (!slots.length || slots.length > 12 || slots.some(x => !/^([01]?\d|2[0-3]):[0-5]\d$/.test(x))) bad('Khung giờ dạng 12:00, 19:00, 21:00');
      setCfg(w, 'arena', { on: b.arena.on !== false, slots, dur: int(b.arena.dur, 5, 180) }); w.broadcastCfg();
    }
    if (b.v1 === 'off') for (const c of [...w.clients.values()]) if (!c.v2) { w.sendTo(c, { t: 'err', code: 'app', msg: 'Bản này đã ngừng. Hãy tải ứng dụng mới tại trang /tai-game.' }); try { c.ws.close(4005, 'app'); } catch (e) {} w.drop(c); }
    return { ok: true };
  },
  // mở mọi khu trùm ngay (min phút), hoặc đóng lại (min = 0)
  async arena_now(w, A, b) { const m = int(b.min, 0, 180); setCfg(w, 'arenaNow', m ? { at: Date.now(), until: Date.now() + m * 60e3, by: A.user } : null); w.broadcastCfg(); return { ok: true }; },
  async tune_get(w) {
    return { tune: { ...R.TUNE, ev: undefined }, def: R.TUNE_DEFAULT,
      // để trang Cân bằng hiện tỉ lệ rơi thật (quái thường chỉ rơi đồ ITEM_DROP × "drop" của quái)
      rates: { itemDrop: R.ITEM_DROP, eliteCap: .3, eliteMul: 1.2, w: R.RAR_W, rar: R.D.rar.map(x => x.n) },
      mons: Object.fromEntries(Object.entries(R.D.mons).map(([k, m]) => [k, { n: m.n, hp: m.hp, atk: m.atk, def: m.def, exp: m.exp, gold: m.gold, drop: m.drop, boss: !!m.boss }])) };
  },
  async tune_set(w, A, b) { const t = R.setTune(b.tune || {}); setCfg(w, 'tune', t); w.broadcastCfg(); return { ok: true, tune: t }; },
  async tune_reset(w) { const t = R.setTune(R.TUNE_DEFAULT); setCfg(w, 'tune', t); w.broadcastCfg(); return { ok: true, tune: t }; },
  async logs(w, A, b) {
    const kind = String(b.kind), q = '%' + clean(b.q, 40).toLowerCase().replace(/[%_]/g, '') + '%', before = b.before ? b.before | 0 : 2 ** 31, lim = 100;
    if (kind === 'admin') return { list: w.sql.exec('SELECT id, at, who, action, target, detail, ip, src FROM admin_log WHERE id<? AND (lower(who) LIKE ? OR action LIKE ? OR lower(detail) LIKE ?) ORDER BY id DESC LIMIT ?', before, q, q, q, lim).toArray() };
    if (kind === 'game') return { list: w.sql.exec('SELECT id, at, kind, uid, srv, name, detail FROM game_log WHERE id<? AND (lower(name) LIKE ? OR kind LIKE ? OR lower(detail) LIKE ?) ORDER BY id DESC LIMIT ?', before, q, q, q, lim).toArray() };
    if (kind === 'chat') return { list: w.sql.exec('SELECT id, at, srv, uid, name, text, scope FROM chat_log WHERE id<? AND (lower(name) LIKE ? OR lower(text) LIKE ?) ORDER BY id DESC LIMIT ?', before, q, q, lim).toArray() };
    if (kind === 'trade') { try { return { list: w.sql.exec('SELECT rowid id, at, srv, a, b, data FROM trade_log WHERE rowid<? ORDER BY rowid DESC LIMIT ?', before, lim).toArray() }; } catch (e) { return { list: [] }; } }
    if (kind === 'anomaly') return { list: w.sql.exec('SELECT a.user_id uid, a.srv, a.flags detail, a.at, c.name FROM anomalies a LEFT JOIN chars c ON c.user_id=a.user_id AND c.srv=a.srv ORDER BY a.at DESC LIMIT 200').toArray() };
    bad('Loại nhật ký không hợp lệ.');
  },
  async admins(w) {
    return { list: w.sql.exec('SELECT a.uid, u.username user, a.role, a.totp_on, a.added, (SELECT MAX(last) FROM admin_sess s WHERE s.uid=a.uid) last FROM admins a JOIN users u ON u.id=a.uid ORDER BY a.added').toArray().map(r => ({ ...r, roleName: ROLE_N[r.role] })) };
  },
  async admin_add(w, A, b) {
    const u = w.one('SELECT id, username FROM users WHERE uname=?', String(b.user || '').trim().toLowerCase()); if (!u) bad('Không có tài khoản này (người đó cần đăng ký trong game trước).');
    const role = ROLE[b.role] ? b.role : 'gm'; if (w.one('SELECT uid FROM admins WHERE uid=?', u.id)) bad('Tài khoản này đã có quyền.');
    const code = invite(); w.sql.exec('INSERT INTO admins(uid,role,setup_hash,setup_exp,added,by_uid) VALUES(?,?,?,?,?,?)', u.id, role, await sha(code), Date.now() + 48 * 3600e3, Date.now(), A.uid);
    return { ok: true, code, user: u.username };
  },
  async admin_role(w, A, b) {
    const uid = b.uid | 0; if (uid === A.uid) bad('Không tự đổi quyền của mình.'); if (!ROLE[b.role]) bad('Vai trò không hợp lệ.');
    w.sql.exec('UPDATE admins SET role=? WHERE uid=?', b.role, uid); return { ok: true };
  },
  async admin_del(w, A, b) {
    const uid = b.uid | 0; if (uid === A.uid) bad('Không tự xóa quyền của mình.');
    if (w.one('SELECT role FROM admins WHERE uid=?', uid)?.role === 'owner' && (w.one("SELECT COUNT(*) n FROM admins WHERE role='owner'").n | 0) <= 1) bad('Phải còn ít nhất một chủ.');
    w.sql.exec('DELETE FROM admins WHERE uid=?', uid); w.sql.exec('DELETE FROM admin_sess WHERE uid=?', uid);
    for (const c of w.clients.values()) if (c.uid === uid) { c.gm = null; c.hidden = false; }
    return { ok: true };
  },
  async admin_reset2fa(w, A, b) {
    const uid = b.uid | 0; if (!w.one('SELECT uid FROM admins WHERE uid=?', uid)) bad('Không có quản trị này.');
    const code = invite();
    w.sql.exec('UPDATE admins SET totp=NULL, totp_on=0, totp_last=0, pending=NULL, setup_hash=?, setup_exp=? WHERE uid=?', await sha(code), Date.now() + 48 * 3600e3, uid);
    w.sql.exec('DELETE FROM admin_sess WHERE uid=?', uid); return { ok: true, code };
  }
};
const D_forgeMax = () => R.D.forge.max;
function invite() { const A2 = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789', b = crypto.getRandomValues(new Uint8Array(20)); return [0, 1, 2, 3].map(g => [...b.slice(g * 5, g * 5 + 5)].map(x => A2[x % 32]).join('')).join('-'); }

/* ================= lệnh GM trong game (giao thức v2) ================= */
// GM phải mở khóa bằng mã 2 lớp mỗi lần vào game; hiệu lực 2 giờ.
export async function onGM(w, c, m) {
  const reply = (ok, msg, data) => w.sendTo(c, { t: 'gm', ok, msg, cmd: m.cmd, data });
  const a = w.one('SELECT * FROM admins WHERE uid=?', c.uid);
  if (!a || ROLE[a.role] < ROLE.gm) return reply(false, 'Không có quyền.');
  const cmd = String(m.cmd || '');
  if (cmd === 'status') return reply(true, '', { role: a.role, unlocked: !!(c.gm && c.gm.until > Date.now()), totp: !!a.totp_on });
  if (cmd === 'unlock') {
    if (!a.totp_on) return reply(false, 'Hãy bật mã 2 lớp ở trang /admin trước.');
    if (failKey(w, 'u2:' + c.uid)) return reply(false, 'Sai mã quá nhiều lần. Thử lại sau 15 phút.');
    const s = await checkOtp(a.totp, m.otp, a.totp_last);
    if (!s) { failAdd(w, 'u2:' + c.uid); alog(w, { uid: c.uid, user: c.user }, 'gm_otp_fail', c.uid, '', '', 'game'); return reply(false, 'Mã 2 lớp không đúng.'); }
    w.sql.exec('UPDATE admins SET totp_last=? WHERE uid=?', s, c.uid); failClear(w, 'u2:' + c.uid);
    c.gm = { until: Date.now() + GM_T, role: a.role }; alog(w, { uid: c.uid, user: c.user }, 'gm_unlock', c.uid, '', '', 'game');
    return reply(true, 'Đã mở bảng GM trong 2 giờ.', { role: a.role, unlocked: true });
  }
  if (!c.gm || c.gm.until < Date.now()) return reply(false, 'Bảng GM đang khóa. Nhập mã 2 lớp để mở.');
  const A = { uid: c.uid, user: c.user }, I = c.inst, log = d => alog(w, A, 'gm_' + cmd, d && d.target || 0, d || m, '', 'game');
  const findP = name => { name = String(name || '').trim().toLowerCase(); for (const o of w.clients.values()) if (o.v2 && o.ch && o.srv === c.srv && (o.ch.name.toLowerCase() === name || o.user.toLowerCase() === name)) return o; return null; };
  const target = m.name ? findP(m.name) : c;
  if (m.name && !target) return reply(false, 'Không thấy người chơi "' + clean(m.name, 20) + '" đang online trên máy chủ này.');
  switch (cmd) {
    case 'tp': { const mi = int(m.map, 0, R.D.maps.length - 1); w.enterMap(c, mi, m.x != null ? int(m.x, 40, R.D.maps[mi].w - 40) : null); log({ map: mi }); return reply(true, 'Đã tới ' + R.D.maps[mi].name); }
    case 'goto': { if (!target || target === c) return reply(false, 'Nhập tên người chơi.'); w.enterMap(c, target.map, target.f.x, target.inst ? target.inst.khu : 1, true); log({ target: target.uid }); return reply(true, 'Đã tới chỗ ' + target.ch.name); }
    case 'pull': { if (!target || target === c) return reply(false, 'Nhập tên người chơi.'); w.enterMap(target, c.map, c.f.x, c.inst ? c.inst.khu : 1, true); w.sendTo(target, { t: 'log', text: 'Bạn được quản trị đưa tới.', col: '#8fb4ff' }); log({ target: target.uid }); return reply(true, 'Đã kéo ' + target.ch.name + ' tới.'); }
    case 'hide': { c.hidden = !!m.on; log({ on: c.hidden }); return reply(true, c.hidden ? 'Đang tàng hình: người chơi và quái không thấy bạn.' : 'Đã hiện hình.', { hidden: c.hidden }); }
    case 'heal': { const t = target || c; t.f.hp = t.f.maxHp; t.f.dead = 0; t.meDirty = true; log({ target: t.uid }); return reply(true, 'Đã hồi đầy máu cho ' + t.ch.name); }
    case 'spawn': {
      if (!I) return reply(false, 'Chưa ở bản đồ nào.');
      if (!R.D.mons[m.type]) return reply(false, 'Không có loại quái này.');
      const n = int(m.n, 1, 10), lv = int(m.lv, 1, R.MAX_LV);
      for (let i = 0; i < n; i++) I.addMon(String(m.type), lv, c.f.x + c.f.face * (120 + i * 50), true);
      log({ type: m.type, lv, n }); return reply(true, 'Đã gọi ' + n + ' ' + R.D.mons[m.type].n + ' cấp ' + lv + '.');
    }
    case 'worldboss2': { if (!I || !I.M.spots || !I.M.spots.length || I.M.village) return reply(false, 'Đứng ở bản đồ săn quái.'); const old = w.wb2 && w.wb2.get(c.srv); if (old && old.m && !old.m.dead) return reply(false, 'Hỗn Mang Ma Thần đang có ở ' + old.inst.M.name + ' khu ' + old.inst.khu + '.'); if (!w.wb2) w.wb2 = new Map(); w.wb2Spawn(c.srv, c.map, I.khu, c.f.x + c.f.face * 450); w.wb2.get(c.srv).born = Date.now(); log({ map: c.map }); return reply(true, 'Đã gọi Hỗn Mang Ma Thần.'); }
    case 'worldboss': { if (!I || !I.M.spots || !I.M.spots.length) return reply(false, 'Đứng ở bản đồ săn quái.'); const old = w.wb && w.wb.get(c.srv); if (old && old.m && !old.m.dead) return reply(false, 'Boss đang có ở ' + old.inst.M.name + '.'); if (!w.wb) w.wb = new Map(); w.wbSpawn(c.srv, c.map, I.khu, c.f.x + c.f.face * 400); log({ map: c.map }); return reply(true, 'Đã gọi Ma Long Hắc Vực.'); }
    case 'killall': { if (!I) return reply(false, ''); let n = 0; for (const q of I.mons) if (!q.dead) { I.kill(q, null); n++; } log({ n }); return reply(true, 'Đã dọn ' + n + ' quái (không rơi đồ).'); }
    case 'give': {
      if (ROLE[c.gm.role] < ROLE.owner) return reply(false, 'Chỉ chủ mới tặng đồ, vàng, kinh nghiệm.');
      const t = target, ch = t.ch, got = [];
      if (m.gold) { ch.gold += int(m.gold, 0, 1e9); got.push(int(m.gold, 0, 1e9) + ' vàng'); }
      if (m.stones) { ch.stones += int(m.stones, 0, 1e6); got.push(int(m.stones, 0, 1e6) + ' đá'); }
      if (m.exp) { const up = R.addExp(ch, int(m.exp, 0, 1e12)); got.push(int(m.exp, 0, 1e12) + ' kinh nghiệm'); if (up) refreshStats(t.f, ch, false); }
      if (m.item) {
        const it = m.item, cls = R.CLS_KEYS.includes(it.cls) ? it.cls : ch.cls, slot = R.SLOTS.includes(it.slot) ? it.slot : 'weapon';
        if (ch.inv.length >= R.INV_MAX) return reply(false, 'Túi đầy.');
        const o = R.shopItem(cls, slot, int(it.r, 0, 3), int(it.lvl || ch.lv, 1, R.MAX_LV), 'g' + Date.now().toString(36) + rnd(3)); if (it.up) o.up = int(it.up, 0, R.D.forge.max);
        ch.inv.push(o); got.push(o.name);
      }
      if (!got.length) return reply(false, 'Chưa chọn gì để tặng.');
      t.dirty = true; t.bagDirty = true; t.meDirty = true;
      if (t !== c) w.sendTo(t, { t: 'log', text: 'Quản trị tặng bạn: ' + got.join(', '), col: '#ffd23f' });
      log({ target: t.uid, got }); return reply(true, 'Đã tặng ' + t.ch.name + ': ' + got.join(', '));
    }
    case 'kick': { if (!target || target === c) return reply(false, 'Nhập tên người chơi.'); if (isStaff(w, target.uid) && c.gm.role !== 'owner') return reply(false, 'Không đá được quản trị khác.'); kickUser(w, target.uid, clean(m.msg, 120) || 'Bạn đã bị quản trị mời ra khỏi game.'); log({ target: target.uid }); return reply(true, 'Đã đá ' + target.ch.name); }
    case 'mute': { if (!target || target === c) return reply(false, 'Nhập tên người chơi.'); const mins = int(m.minutes, 0, 525600); w.sql.exec('UPDATE users SET muted_until=? WHERE id=?', mins ? Date.now() + mins * 60e3 : null, target.uid); w.sendTo(target, { t: 'log', text: mins ? 'Bạn bị cấm trò chuyện ' + mins + ' phút.' : 'Bạn đã được trò chuyện lại.', col: '#ffb347' }); log({ target: target.uid, mins }); return reply(true, mins ? 'Đã cấm ' + target.ch.name + ' trò chuyện ' + mins + ' phút.' : 'Đã bỏ cấm.'); }
    case 'announce': { const text = clean(m.text, 200).trim(); if (!text) return reply(false, 'Nhập nội dung.'); for (const o of w.clients.values()) if (o.srv === c.srv) w.sendTo(o, o.v2 ? { t: 'ann', text } : { t: 'chat', id: 0, n: '📢 Thông báo', text, all: true }); log({ text }); return reply(true, 'Đã gửi thông báo.'); }
    case 'who': return reply(true, '', { list: [...w.clients.values()].filter(o => o.srv === c.srv).map(o => ({ name: o.ch ? o.ch.name : o.user, lv: o.ch ? o.ch.lv : 0, map: o.map, user: o.user })) });
    default: return reply(false, 'Lệnh không hợp lệ.');
  }
}
