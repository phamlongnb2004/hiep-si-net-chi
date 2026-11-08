// Máy chủ Hiệp Sĩ Nét Chì chạy trên Cloudflare (gói miễn phí).
// Worker nhận yêu cầu /api/* và /ws rồi chuyển cho một Durable Object "world" giữ toàn bộ người chơi và cơ sở dữ liệu SQLite.
// Giao thức giống hệt server/index.js nên game không cần sửa.
import { DurableObject } from 'cloudflare:workers';
import * as R from '../shared/rules.js';
import { MapInst, makeFighter, refreshStats } from './sim.js';
import { OPS } from './ops.js';
import { initSocial, onSocial, tradeCancel, friendList } from './social.js';
import { initAdmin, adminHttp, adminTick, onGM, glog, chatLog, publicCfg, isStaff, maintOn, maintMsg, banInfo, mutedUntil } from './admin.js';

const TICK_MS = 100;
const APP_MIN = '2.8.0'; // 2.8.0: đồ theo bậc cấp + nhẫn, khuyên tai, đai lưng, bùa hộ mệnh (bản cũ không hiện được ô đồ mới)
const ARENA_SLOTS = ['12:00', '19:00', '21:00'], ARENA_DUR = 30, ARENA_LEAVE = 40000; // khu trùm: khung giờ mặc định, số phút mở, giây ở lại nhặt đồ sau khi hạ trùm
const KHU_MAX = 15, KHU_SHOW = 5, KHU_CAP = 40; // người tối đa mỗi khu (đổi được trong Admin), số khu luôn hiện, số khu tối đa mỗi bản đồ
const MAX_SAVE = 300 * 1024;
const TOKEN_IDLE = 30 * 86400e3; // phiên đăng nhập hết hạn sau 30 ngày không dùng
const SAVE_EVERY = 15000;
const PROTO = 2;
const ITER = 60000; // vòng lặp băm mật khẩu PBKDF2
// danh sách máy chủ (cụm) trong game; mỗi tài khoản có một nhân vật riêng trên mỗi máy chủ
// Trình duyệt chỉ dành cho admin thử game; người chơi dùng ứng dụng Windows / Android (gửi app=pc|android).
// Thêm admin: biến ADMINS trong Cloudflare (tên tài khoản, cách nhau bằng dấu phẩy).
const ADMIN_DEFAULT = ['phamlongnb2004'];
let ADMINS = new Set(ADMIN_DEFAULT);
const isAdmin = name => ADMINS.has(String(name || '').toLowerCase());
const WEB_MSG = 'Hiệp Sĩ Nét Chì chỉ chơi trên ứng dụng. Hãy tải game cho máy tính hoặc điện thoại.';

const SERVERS = [{ id: 1, name: 'Server 1', tag: 'Mới', open: true }]; // mặc định; admin sửa danh sách ở trang /admin

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};
const json = (code, obj) => new Response(JSON.stringify(obj), { status: code, headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...CORS } });
const okName = s => typeof s === 'string' && /^[\p{L}\p{N}_ ]{3,16}$/u.test(s) && s.trim() === s;
const clean = (s, n) => String(s == null ? '' : s).replace(/[\u0000-\u001f\u007f<>]/g, '').slice(0, n);
const num = (v, lo, hi) => { v = +v; return Number.isFinite(v) ? Math.min(hi, Math.max(lo, v)) : lo; };
const hex = buf => [...new Uint8Array(buf)].map(b => b.toString(16).padStart(2, '0')).join('');
const randHex = n => hex(crypto.getRandomValues(new Uint8Array(n)));
async function hashPass(pass, salt) {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(pass), 'PBKDF2', false, ['deriveBits']);
  return hex(await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt: new TextEncoder().encode(salt), iterations: ITER }, key, 256));
}
const verCmp = (a, b) => { const x = String(a).split('.'), y = String(b).split('.'); for (let i = 0; i < Math.max(x.length, y.length); i++) { const p = +x[i] || 0, q = +y[i] || 0; if (p !== q) return p > q ? 1 : -1; } return 0; };
function sameHex(a, b) { if (a.length !== b.length) return false; let d = 0; for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i); return d === 0; }

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    // xác minh ứng dụng Android (TWA) để chạy toàn màn hình, không hiện thanh địa chỉ
    if (url.pathname === '/.well-known/assetlinks.json') return new Response(env.ASSETLINKS || '[]', { headers: { 'Content-Type': 'application/json' } });
    // link tải cố định: /tai/windows, /tai/android, /tai/linux, /tai/ios -> file của bản mới nhất (ghi trong update/latest.json)
    const tai = /^\/tai\/(windows|android|linux|ios)$/.exec(url.pathname);
    if (tai) {
      try {
        const r = await env.ASSETS.fetch(new Request(new URL('/update/latest.json', url)));
        const m = await r.json(), k = tai[1], u = m.app && m.app[k] && m.app[k].url;
        if (u && /^https:\/\//.test(u)) return new Response(null, { status: 302, headers: { Location: u, 'Cache-Control': 'no-store' } });
      } catch (e) {}
      const k2 = k => k === 'windows' ? '/HiepSiNetChi-Windows.zip' : k === 'android' ? '/HiepSiNetChi.apk' : '/tai-game';
      // chưa phát hành bản gốc: dùng file cũ (ứng dụng vỏ) đang có trên máy chủ
      return new Response(null, { status: 302, headers: { Location: k2(tai[1]), 'Cache-Control': 'no-store' } });
    }
    // trang quản trị: không cho nhúng vào trang khác, không lưu cache, chỉ chạy mã của chính trang
    if (url.pathname === '/admin' || url.pathname === '/admin/') {
      const r = await env.ASSETS.fetch(new Request(new URL('/admin.html', url)));
      const h = new Headers(r.headers);
      h.set('Content-Security-Policy', "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'");
      h.set('X-Frame-Options', 'DENY'); h.set('X-Content-Type-Options', 'nosniff'); h.set('Referrer-Policy', 'no-referrer');
      h.set('Cache-Control', 'no-store'); h.set('X-Robots-Tag', 'noindex, nofollow'); h.set('Strict-Transport-Security', 'max-age=31536000');
      return new Response(r.body, { status: r.status, headers: h });
    }
    if (url.pathname.startsWith('/api/') || url.pathname === '/ws') {
      const world = env.WORLD.get(env.WORLD.idFromName('world'));
      return world.fetch(req);
    }
    return env.ASSETS.fetch(req);
  },
};

export class World extends DurableObject {
  constructor(ctx, env) {
    if (env && env.ADMINS) ADMINS = new Set([...ADMIN_DEFAULT, ...String(env.ADMINS).split(',').map(x => x.trim().toLowerCase()).filter(Boolean)]);
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.sql.exec(`CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, uname TEXT UNIQUE NOT NULL, pass_hash TEXT NOT NULL, salt TEXT NOT NULL, created INTEGER)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, user_id INTEGER NOT NULL, created INTEGER)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS saves(user_id INTEGER PRIMARY KEY, data TEXT NOT NULL, lv INTEGER, kills INTEGER, name TEXT, cls TEXT, updated INTEGER)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS chars(user_id INTEGER NOT NULL, srv INTEGER NOT NULL, data TEXT NOT NULL, lv INTEGER, kills INTEGER, name TEXT, cls TEXT, updated INTEGER, PRIMARY KEY(user_id, srv))`);
    // nhân vật cũ (trước khi có chọn máy chủ) chuyển sang Server 1
    this.sql.exec(`INSERT OR IGNORE INTO chars(user_id,srv,data,lv,kills,name,cls,updated) SELECT user_id,1,data,lv,kills,name,cls,updated FROM saves`);
    this.sql.exec(`DELETE FROM saves`);
    // giao thức v2: sao lưu bảng nhân vật một lần trước khi máy chủ bắt đầu tự ghi; phiên có hạn dùng; ghi lại bản lưu bất thường
    this.sql.exec(`CREATE TABLE IF NOT EXISTS chars_v1_backup AS SELECT * FROM chars`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS anomalies(user_id INTEGER, srv INTEGER, flags TEXT, at INTEGER, PRIMARY KEY(user_id, srv))`);
    try { this.sql.exec(`ALTER TABLE sessions ADD COLUMN last INTEGER`); } catch (e) {}
    this.sql.exec(`UPDATE sessions SET last=? WHERE last IS NULL`, Date.now()); // phiên cũ: tính hạn từ lúc nâng cấp, không đẩy ai ra
    this.insts = new Map(); this.arenaDone = new Map(); this.arenaAnn = new Set();
    initSocial(this);
    initAdmin(this);
    this.clients = new Map();
    this.seq = 1;
    this.tries = new Map();
    this.timer = null;
    this._tk = 0;
  }

  ownerNames() { return [...ADMINS]; }
  servers() { return Array.isArray(this.cfg && this.cfg.servers) && this.cfg.servers.length ? this.cfg.servers : SERVERS; }
  srvOf(v) { return this.servers().find(x => x.id === (v | 0)) || null; }
  async checkPass(u, pass) { return sameHex(await hashPass(pass, u.salt), u.pass_hash); }
  async setPass(uid, pass) { const salt = randHex(16); this.sql.exec('UPDATE users SET pass_hash=?, salt=? WHERE id=?', await hashPass(pass, salt), salt, uid); }
  broadcastCfg() { const m = JSON.stringify({ t: 'cfg', cfg: publicCfg(this) }); for (const c of this.clients.values()) if (c.v2) this.sendTo(c, m); }
  // bản ứng dụng tối thiểu: cao nhất trong (Admin, biến MIN_APP, APP_MIN theo mã máy chủ — dữ liệu bản đồ đổi thì bản cũ không chơi được)
  minApp() { return [(this.cfg && this.cfg.min_app) || '', this.env.MIN_APP || '', APP_MIN].reduce((a, b) => b && (!a || verCmp(b, a) > 0) ? b : a, ''); }
  v1Off() { return ((this.cfg && this.cfg.v1) || this.env.V1) === 'off'; }
  one(sql, ...args) { const r = this.sql.exec(sql, ...args).toArray(); return r[0] || null; }

  async fetch(req) {
    const url = new URL(req.url);
    try {
      if (url.pathname === '/ws') return this.openSocket(req, url);
      return await this.api(req, url);
    } catch (e) {
      console.error(e); return json(500, { error: 'Lỗi máy chủ' });
    }
  }

  limited(ip) {
    const now = Date.now(), t = this.tries.get(ip) || { n: 0, at: now };
    if (now - t.at > 60000) { t.n = 0; t.at = now; }
    t.n++; this.tries.set(ip, t); return t.n > 20;
  }

  async api(req, url) {
    if (url.pathname.startsWith('/api/admin/')) return adminHttp(this, req, url);
    if (url.pathname === '/api/health') return json(200, { ok: true, online: this.clients.size, store: 'cloudflare-sqlite' });
    if (url.pathname === '/api/top') {
      const srv = this.srvOf(url.searchParams.get('srv') || 1) ? (url.searchParams.get('srv') | 0 || 1) : 1;
      const top = this.sql.exec('SELECT user_id id, name, cls, lv, kills FROM chars WHERE srv=? ORDER BY lv DESC, kills DESC LIMIT 20', srv).toArray();
      return json(200, { top });
    }
    if (req.method !== 'POST') return json(405, { error: 'Sai phương thức' });
    const ip = req.headers.get('CF-Connecting-IP') || '';
    if (this.limited(ip)) return json(429, { error: 'Thử lại sau một phút.' });
    let b; try { b = await req.json(); } catch (e) { return json(400, { error: 'Dữ liệu không hợp lệ' }); }
    if (url.pathname === '/api/servers') {
      const u = this.session(b.token);
      if (!u) return json(401, { error: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' });
      if (b.app === 'web' && !isAdmin(u.username)) return json(403, { error: WEB_MSG, code: 'app' });
      const staff = isStaff(this, u.id), ban = banInfo(this, u.id);
      if (ban) return json(403, { error: ban, code: 'ban' });
      if (maintOn(this) && !staff) return json(503, { error: maintMsg(this), code: 'maint' });
      const servers = this.servers().filter(x => x.open !== false || staff).map(x => {
        const ch = this.one('SELECT name, cls, lv FROM chars WHERE user_id=? AND srv=?', u.id, x.id);
        let online = 0; for (const c of this.clients.values()) if (c.srv === x.id) online++;
        return { id: x.id, name: x.name, tag: x.tag, online, char: ch ? { name: ch.name, cls: ch.cls, lv: ch.lv | 0 } : null };
      });
      return json(200, { servers });
    }
    const user = String(b.user || '').trim(), pass = String(b.pass || '');
    if (url.pathname === '/api/register') {
      if (b.app === 'web') return json(403, { error: WEB_MSG, code: 'app' });
      if (maintOn(this)) return json(503, { error: maintMsg(this), code: 'maint' });
      if (!okName(user)) return json(400, { error: 'Tên tài khoản 3–16 ký tự, gồm chữ, số, dấu cách hoặc _' });
      if (pass.length < 6 || pass.length > 72) return json(400, { error: 'Mật khẩu cần từ 6 đến 72 ký tự' });
      if (this.one('SELECT id FROM users WHERE uname=?', user.toLowerCase())) return json(409, { error: 'Tên tài khoản đã có người dùng' });
      const salt = randHex(16), h = await hashPass(pass, salt);
      const u = this.one('INSERT INTO users(username,uname,pass_hash,salt,created) VALUES(?,?,?,?,?) RETURNING id, username', user, user.toLowerCase(), h, salt, Date.now());
      return json(200, this.newSession(u));
    }
    if (url.pathname === '/api/login') {
      const u = this.one('SELECT * FROM users WHERE uname=?', user.toLowerCase());
      const good = u && sameHex(await hashPass(pass, u.salt), u.pass_hash);
      if (!good) return json(401, { error: 'Sai tên tài khoản hoặc mật khẩu' });
      const ban = banInfo(this, u.id); if (ban) return json(403, { error: ban, code: 'ban' });
      if (maintOn(this) && !isStaff(this, u.id)) return json(503, { error: maintMsg(this), code: 'maint' });
      this.sql.exec('UPDATE users SET last_login=?, last_ip=? WHERE id=?', Date.now(), ip, u.id);
      if (b.app === 'web' && !isAdmin(u.username)) return json(403, { error: WEB_MSG, code: 'app' });
      return json(200, this.newSession(u));
    }
    if (url.pathname === '/api/logout') { if (b.token) this.sql.exec('DELETE FROM sessions WHERE token=?', String(b.token)); return json(200, { ok: true }); }
    return json(404, { error: 'Không có' });
  }

  // phiên còn hạn thì gia hạn, quá 30 ngày không dùng thì xóa
  session(token) {
    if (!token) return null; token = String(token);
    const u = this.one('SELECT u.id, u.username, s.last FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=?', token);
    if (!u) return null;
    const now = Date.now();
    if (now - (u.last || 0) > TOKEN_IDLE) { this.sql.exec('DELETE FROM sessions WHERE token=?', token); return null; }
    if (now - (u.last || 0) > 3600e3) this.sql.exec('UPDATE sessions SET last=? WHERE token=?', now, token);
    return u;
  }

  newSession(u) {
    const token = randHex(24);
    this.sql.exec('INSERT INTO sessions(token,user_id,created,last) VALUES(?,?,?,?)', token, u.id, Date.now(), Date.now());
    return { token, user: u.username };
  }

  openSocket(req, url) {
    if (req.headers.get('Upgrade') !== 'websocket') return json(426, { error: 'Cần WebSocket' });
    const pair = new WebSocketPair();
    const [client, ws] = Object.values(pair);
    ws.accept();
    const send = obj => { try { ws.send(JSON.stringify(obj)); } catch (e) {} };
    const token = String(url.searchParams.get('token') || '');
    const srv = this.srvOf(url.searchParams.get('srv') || 1);
    if (!srv) {
      send({ t: 'err', code: 'srv', msg: 'Máy chủ này chưa mở.' });
      ws.close(4003, 'srv');
      return new Response(null, { status: 101, webSocket: client });
    }
    const u = this.session(token);
    if (!u) {
      send({ t: 'err', code: 'auth', msg: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' });
      ws.close(4001, 'auth');
      return new Response(null, { status: 101, webSocket: client });
    }
    const ban = banInfo(this, u.id), staff = isStaff(this, u.id);
    if (ban) { send({ t: 'err', code: 'ban', msg: ban }); ws.close(4008, 'ban'); return new Response(null, { status: 101, webSocket: client }); }
    if ((maintOn(this) || srv.open === false) && !staff) { send({ t: 'err', code: 'maint', msg: srv.open === false ? 'Máy chủ này đang đóng.' : maintMsg(this) }); ws.close(4009, 'maint'); return new Response(null, { status: 101, webSocket: client }); }
    if (url.searchParams.get('app') === 'web' && !isAdmin(u.username)) {
      send({ t: 'err', code: 'app', msg: WEB_MSG });
      ws.close(4005, 'app');
      return new Response(null, { status: 101, webSocket: client });
    }
    for (const c of this.clients.values()) if (c.uid === u.id) { this.sendTo(c, { t: 'err', code: 'dup', msg: 'Tài khoản vừa đăng nhập ở nơi khác.' }); try { c.ws.close(4002, 'dup'); } catch (e) {} this.drop(c); }
    if ((url.searchParams.get('proto') | 0) >= 2) {
      // ứng dụng quá cũ: báo cập nhật (bản tối thiểu đặt bằng biến MIN_APP trong Cloudflare)
      if (this.minApp() && verCmp(url.searchParams.get('v') || '0', this.minApp()) < 0) {
        send({ t: 'err', code: 'update', msg: 'Đã có bản mới, hãy cập nhật ứng dụng để chơi tiếp.' }); ws.close(4007, 'update');
        return new Response(null, { status: 101, webSocket: client });
      }
      this.openV2(ws, u, srv, url); return new Response(null, { status: 101, webSocket: client });
    }
    // giao thức cũ (bản web / ứng dụng vỏ): tắt hẳn khi chuyển sang ứng dụng gốc (biến V1=off)
    if (this.v1Off() && !staff) {
      send({ t: 'err', code: 'app', msg: 'Bản này đã ngừng. Hãy tải ứng dụng Hiệp Sĩ Nét Chì mới tại trang /tai-game.' }); ws.close(4005, 'app');
      return new Response(null, { status: 101, webSocket: client });
    }
    const c = { id: this.seq++, uid: u.id, user: u.username, srv: srv.id, ws, map: -1, st: null, lastChat: 0, lastSave: 0, pending: null, lock: null };
    this.clients.set(c.id, c);
    const sv = this.one('SELECT data, name, cls FROM chars WHERE user_id=? AND srv=?', u.id, srv.id);
    if (sv) c.lock = { name: sv.name, cls: sv.cls };
    send({ t: 'welcome', id: c.id, user: u.username, srv: srv.id, srvName: srv.name, save: sv ? JSON.parse(sv.data) : null, online: this.count(srv.id) });
    this.toSrv(srv.id, { t: 'count', online: this.count(srv.id) });
    ws.addEventListener('message', ev => this.onMessage(c, ev.data));
    const bye = () => this.drop(c);
    ws.addEventListener('close', bye);
    ws.addEventListener('error', bye);
    this.startTick();
    return new Response(null, { status: 101, webSocket: client });
  }

  drop(c) {
    if (this.clients.get(c.id) !== c) return;
    if (c.pending) this.writeSave(c);
    if (c.v2) { tradeCancel(this, c, 'Người kia đã thoát, giao dịch bị hủy.'); if (c.dirty) this.writeChar(c); this.friendsChanged(c); if (c.inst) { c.inst.leave(c); this.gcInst(c.inst); c.inst = null; } }
    this.clients.delete(c.id);
    if (c.map >= 0) this.toMap(c, c.map, { t: 'gone', id: c.id });
    this.toSrv(c.srv, { t: 'count', online: this.count(c.srv) });
    if (!this.clients.size && this.timer) { clearInterval(this.timer); this.timer = null; }
  }

  sendTo(c, obj) { try { c.ws.send(typeof obj === 'string' ? obj : JSON.stringify(obj)); } catch (e) {} }
  count(srv) { let n = 0; for (const c of this.clients.values()) if (c.srv === srv) n++; return n; }
  // chỉ gửi cho người chơi cùng máy chủ (và cùng bản đồ)
  toMap(from, map, obj, except) { const s = JSON.stringify(obj); for (const c of this.clients.values()) if (c.srv === from.srv && c.map === map && c !== except && (!c.v2 || !c.inst || c.inst.khu === 1)) this.sendTo(c, s); }
  toSrv(srv, obj) { const s = JSON.stringify(obj); for (const c of this.clients.values()) if (c.srv === srv) this.sendTo(c, s); }

  writeSave(c) {
    const d = c.pending; c.pending = null; c.lastSave = Date.now();
    this.sql.exec('INSERT INTO chars(user_id,srv,data,lv,kills,name,cls,updated) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(user_id,srv) DO UPDATE SET data=excluded.data, lv=excluded.lv, kills=excluded.kills, updated=excluded.updated',
      c.uid, c.srv, JSON.stringify(d), d.lv | 0, d.kills | 0, clean(d.name, 16), clean(d.cls, 12), Date.now());
  }

  onMessage(c, raw) {
    let m; try { m = JSON.parse(raw); } catch (e) { return; }
    if (!m || typeof m !== 'object') return;
    if (m.t === 'st') {
      const map = num(m.m, 0, 20) | 0;
      if (map !== c.map) { if (c.map >= 0) this.toMap(c, c.map, { t: 'gone', id: c.id }, c); c.map = map; }
      c.st = [c.id, Math.round(num(m.x, 0, 5000)), Math.round(num(m.y, 0, 5000)), m.f < 0 ? -1 : 1, m.mv ? 1 : 0, m.sw ? 1 : 0,
        clean(m.c, 12), num(m.lv, 1, 999) | 0, clean(m.n, 16), num(m.hp, 0, 1), m.dead ? 1 : 0, num(m.g, 0, 255) | 0, m.air ? 1 : 0];
    } else if (m.t === 'chat') {
      const now = Date.now(), text = clean(m.text, 120).trim();
      if (!text || now - c.lastChat < 700) return;
      c.lastChat = now;
      if (mutedUntil(this, c.uid)) return;
      const msg = { t: 'chat', id: c.id, n: (c.st && c.st[8]) || c.user, text, all: !!m.all };
      chatLog(this, c, msg.n, text, m.all ? 'all' : 'map:' + c.map);
      if (m.all) this.toSrv(c.srv, msg); else this.toMap(c, c.map, msg);
    } else if (m.t === 'save') {
      const d = m.d;
      if (!d || typeof d !== 'object' || typeof d.cls !== 'string') return;
      if (JSON.stringify(d).length > MAX_SAVE) return this.sendTo(c, { t: 'err', code: 'save', msg: 'Bản lưu quá lớn.' });
      // nhân vật đã tạo trên máy chủ này thì không đổi được phái hay tên
      if (c.lock && (d.cls !== c.lock.cls || clean(d.name, 16) !== c.lock.name)) return this.sendTo(c, { t: 'err', code: 'lock', msg: 'Tài khoản đã có nhân vật ' + c.lock.name + ' trên máy chủ này.' });
      if (!c.lock) c.lock = { name: clean(d.name, 16), cls: clean(d.cls, 12) };
      c.pending = d;
      // gộp bớt lượt ghi để nằm trong giới hạn miễn phí
      if (Date.now() - c.lastSave > 15000) this.writeSave(c);
    } else if (m.t === 'ping') this.sendTo(c, { t: 'pong', at: m.at });
  }

  startTick() {
    if (this.timer) return;
    this.timer = setInterval(() => { try { this.tick(); } catch (e) { console.error(e); } }, TICK_MS);
  }

  tick() {
    // người chơi bản cũ (v1): vị trí do ứng dụng tự báo
    const byMap = new Map();
    for (const c of this.clients.values()) if (!c.v2 && c.st && c.map >= 0) { const k = c.srv * 100 + c.map; if (!byMap.has(k)) byMap.set(k, []); byMap.get(k).push(c.st); }
    // bản đồ v2: máy chủ chạy quái, đòn đánh; gửi ảnh chụp cho người chơi v2 và vị trí cho người chơi v1 cùng bản đồ
    for (const inst of this.insts.values()) {
      inst.tick(TICK_MS / 1000);
      const k = inst.srv * 100 + inst.mi, k1 = inst.khu === 1;
      const sn = inst.snap(k1 ? byMap.get(k) : null), s = JSON.stringify(sn);
      for (const c of inst.players.values()) {
        this.sendTo(c, s);
        if (c.meDirty || c.bagDirty) this.sendMe(c);
      }
      if (k1 && sn.p.length) { const v2 = sn.p.filter(q => inst.players.has(q[0])); if (v2.length) { if (!byMap.has(k)) byMap.set(k, []); byMap.get(k).push(...v2); } }
    }
    const now = Date.now();
    if (++this._tk % 10 === 0) { adminTick(this); this.arenaTick(now); }
    for (const c of this.clients.values()) {
      if (!c.v2 && c.map >= 0) this.sendTo(c, { t: 'ps', p: (byMap.get(c.srv * 100 + c.map) || []).filter(s => s[0] !== c.id) });
      if (c.pending && now - c.lastSave > SAVE_EVERY) this.writeSave(c);
      if (c.v2 && c.dirty && now - c.lastSave > SAVE_EVERY) this.writeChar(c);
    }
  }

  /* ================= GIAO THỨC v2: máy chủ quyết định mọi kết quả ================= */
  openV2(ws, u, srv, url) {
    const c = { id: this.seq++, v2: true, uid: u.id, user: u.username, srv: srv.id, ws, map: -1, ch: null, f: null, inst: null, lastChat: 0, lastSave: Date.now(), dirty: false, meDirty: false, bagDirty: false, rate: { n: 0, at: Date.now() }, app: clean(url.searchParams.get('app'), 12) };
    this.clients.set(c.id, c);
    const row = this.one('SELECT data FROM chars WHERE user_id=? AND srv=?', u.id, srv.id);
    if (row) { try { this.loadChar(c, JSON.parse(row.data)); } catch (e) { console.error('bản lưu hỏng', u.id, e); this.sendTo(c, { t: 'err', code: 'save', msg: 'Bản lưu nhân vật bị lỗi, hãy báo quản trị.' }); try { ws.close(4006, 'save'); } catch (e2) {} this.clients.delete(c.id); return; } }
    this.sendTo(c, { t: 'welcome', proto: PROTO, id: c.id, user: u.username, srv: srv.id, srvName: srv.name, online: this.count(srv.id), me: c.ch ? this.meOf(c, true) : null, cfg: publicCfg(this), staff: (this.one('SELECT role FROM admins WHERE uid=?', u.id) || {}).role || '' });
    this.toSrv(srv.id, { t: 'count', online: this.count(srv.id) });
    if (c.ch) { const A = R.D.maps[c.ch.map] && R.D.maps[c.ch.map].arena; if (A) this.enterMap(c, A.from, A.gx); else this.enterMap(c, c.ch.map, null); friendList(this, c); }
    ws.addEventListener('message', ev => this.onV2(c, ev.data));
    const bye = () => this.drop(c);
    ws.addEventListener('close', bye);
    ws.addEventListener('error', bye);
    this.startTick();
  }
  loadChar(c, d) {
    const ch = R.normalizeChar(d), bad = R.anomalies(ch);
    if (bad.length) this.sql.exec('INSERT INTO anomalies(user_id,srv,flags,at) VALUES(?,?,?,?) ON CONFLICT(user_id,srv) DO UPDATE SET flags=excluded.flags, at=excluded.at', c.uid, c.srv, bad.join(' | ').slice(0, 2000), Date.now());
    c.ch = ch; c.f = makeFighter(ch);
  }
  // mỗi bản đồ chia nhiều khu (như Ngọc Rồng Online), mỗi khu tối đa KHU_MAX người; khu là một bản sao bản đồ riêng (quái, đồ rơi riêng)
  instOf(srv, mi, k) { const key = srv * 10000 + mi * 100 + k; let i = this.insts.get(key); if (!i) { i = new MapInst(srv, mi, this.hooks()); i.khu = k; this.insts.set(key, i); } return i; }
  gcInst(inst) { if (!inst.players.size) this.insts.delete(inst.srv * 10000 + inst.mi * 100 + inst.khu); }
  khuN(srv, mi, k) { const i = this.insts.get(srv * 10000 + mi * 100 + k); return i ? i.players.size : 0; }
  khuMax() { return Math.max(1, Math.min(100, (this.cfg && this.cfg.khuMax) | 0 || KHU_MAX)); }
  // chọn khu: giữ số khu mong muốn nếu còn chỗ, không thì khu nhỏ nhất còn chỗ
  pickKhu(srv, mi, want) { const mx = this.khuMax(); if (want && want <= KHU_CAP && this.khuN(srv, mi, want) < mx) return want; for (let k = 1; k <= KHU_CAP; k++) if (this.khuN(srv, mi, k) < mx) return k; return KHU_CAP; }
  /* ---------- khu trùm: mở theo khung giờ (giờ Việt Nam), mỗi khu một con trùm, hạ xong là đóng tới khung sau ---------- */
  arenaCfg() { const a = this.cfg.arena || {}; return { on: a.on !== false, slots: Array.isArray(a.slots) && a.slots.length ? a.slots : ARENA_SLOTS, dur: a.dur || ARENA_DUR }; }
  // trả { open, start, end, next } cho bản đồ khu trùm mi lúc now
  arenaWin(mi, now) {
    const A = R.D.maps[mi].arena, cf = this.arenaCfg(), f = this.cfg.arenaNow;
    if (f && f.until > now) return { open: true, start: f.at, end: f.until, next: 0 };
    if (!cf.on) return { open: false, start: 0, end: 0, next: 0 };
    const VN = 7 * 3600e3, day = Math.floor((now + VN) / 864e5) * 864e5 - VN; let next = Infinity;
    for (let d = -1; d <= 1; d++) for (const sl of cf.slots) {
      const [hh, mm] = String(sl).split(':').map(Number), st = day + d * 864e5 + ((hh * 60 + (mm || 0) + (A.ofs || 0)) * 60e3), en = st + cf.dur * 60e3;
      if (now >= st && now < en) return { open: true, start: st, end: en, next: 0 };
      if (st > now) next = Math.min(next, st);
    }
    return { open: false, start: 0, end: 0, next: next === Infinity ? 0 : next };
  }
  arenaKhu(srv, mi, win) { const mx = this.khuMax(); for (let k = 1; k <= KHU_CAP; k++) { if (this.arenaDone.get(srv * 10000 + mi * 100 + k) === win.start) continue; if (this.khuN(srv, mi, k) < mx) return k; } return 0; }
  // vào khu trùm qua cổng: kiểm tra giờ mở, cấp, khu còn trùm
  enterArena(c, mi) {
    const M = R.D.maps[mi], A = M.arena, now = Date.now(), win = this.arenaWin(mi, now), vn = t => new Date(t + 7 * 3600e3).toISOString().slice(11, 16);
    const no = msg => this.sendTo(c, { t: 'res', op: 'warp', ok: false, msg });
    if (!win.open) { const left = win.next ? win.next - now : 0, h = Math.floor(left / 3600e3), m = Math.floor(left % 3600e3 / 60e3);
      return no(M.name + ' đang đóng.' + (win.next ? ' Mở lúc ' + vn(win.next) + ' (còn ' + (left < 60e3 ? Math.ceil(left / 1e3) + ' giây' : (h ? h + ' giờ ' : '') + m + ' phút') + ').' : '')); }
    if (c.ch.lv < A.req && !isStaff(this, c.uid)) return no('Cần cấp ' + A.req + ' để vào ' + M.name + '.');
    const k = this.arenaKhu(c.srv, mi, win); if (!k) return no('Trùm ở mọi khu đã bị hạ. Chờ khung giờ sau.');
    this.enterMap(c, mi, null, k, true);
    this.sendTo(c, { t: 'log', text: 'Vào ' + M.name + ' · Khu ' + k + ' · đóng lúc ' + vn(win.end), col: '#ffd23f' });
  }
  // mỗi giây: đóng khu hết giờ / đã hạ trùm, báo trước giờ mở
  arenaTick(now) {
    for (const inst of [...this.insts.values()]) {
      const A = inst.M.arena; if (!A) continue;
      const win = this.arenaWin(inst.mi, now), key = inst.srv * 10000 + inst.mi * 100 + inst.khu;
      if (inst.cleared && win.open) this.arenaDone.set(key, win.start);
      let why = !win.open ? 'Khu trùm đã hết giờ.' : inst.cleared && now - inst.cleared > ARENA_LEAVE ? 'Trùm đã bị hạ, khu trùm đóng.' : '';
      if (!why) continue;
      for (const c of [...inst.players.values()]) { this.enterMap(c, A.from, A.gx); this.sendTo(c, { t: 'log', text: why, col: '#ffb347' }); }
    }
    for (const srv of new Set([...this.clients.values()].map(c => c.srv))) R.D.maps.forEach((M, mi) => {
      if (!M.arena) return; const w5 = this.arenaWin(mi, now + 300e3), w0 = this.arenaWin(mi, now);
      const k5 = srv + ':' + mi + ':5:' + w5.start, k0 = srv + ':' + mi + ':0:' + w0.start;
      if (w5.open && !w0.open && w5.start > now && !this.arenaAnn.has(k5)) { this.arenaAnn.add(k5); this.srvAnn(srv, '⏰ ' + M.name + ' (' + R.D.maps[M.arena.from].name + ') mở sau ' + Math.max(1, Math.round((w5.start - now) / 60e3)) + ' phút'); }
      if (w0.open && now - w0.start < 60e3 && !this.arenaAnn.has(k0)) { this.arenaAnn.add(k0); this.srvAnn(srv, '⚔ ' + M.name + ' đã mở! Cổng ở giữa ' + R.D.maps[M.arena.from].name); }
    });
    if (this.arenaAnn.size > 500) this.arenaAnn.clear();
  }
  khuList(c) {
    const mx = this.khuMax(); let hi = 0; for (const i of this.insts.values()) if (i.srv === c.srv && i.mi === c.map && i.players.size) hi = Math.max(hi, i.khu);
    const n = Math.min(KHU_CAP, Math.max(KHU_SHOW, hi + 1)), list = [];
    for (let k = 1; k <= n; k++) list.push([k, this.khuN(c.srv, c.map, k)]);
    return { t: 'khu', cur: c.inst ? c.inst.khu : 1, max: mx, list };
  }
  hooks() { return { send: (c, o) => this.sendTo(c, o), dirty: c => { c.dirty = true; c.bagDirty = true; }, log: (c, text, col) => this.sendTo(c, { t: 'log', text, col }), glog: (k, c, d) => glog(this, k, c, d), ann: (inst, text) => this.srvAnn(inst.srv, text) }; }
  // thông báo lớn giữa màn hình (kèm dòng trong nhật ký) cho cả máy chủ
  srvAnn(srv, text) { const s = JSON.stringify({ t: 'ann', text }); for (const c of this.clients.values()) if (c.v2 && c.srv === srv) this.sendTo(c, s); }
  srvLog(srv, text, col) { const s = JSON.stringify({ t: 'log', text, col }); for (const c of this.clients.values()) if (c.v2 && c.srv === srv) this.sendTo(c, s); }
  // báo cho bạn bè đang online cập nhật danh sách (online/offline, bản đồ)
  friendsChanged(c) {
    try { for (const r of this.sql.exec('SELECT fid FROM friends WHERE uid=?', c.uid).toArray()) for (const o of this.clients.values()) if (o.uid === r.fid && o.v2 && o.ch && o !== c) friendList(this, o); } catch (e) { console.error(e); }
  }
  // khu: số khu muốn vào; force: vào đúng khu đó dù đầy (quản trị dịch chuyển tới người chơi)
  enterMap(c, mi, x, khu, force) {
    tradeCancel(this, c, 'Đổi bản đồ, giao dịch bị hủy.');
    const want = khu || (c.inst ? c.inst.khu : 1);
    if (c.inst) { c.inst.leave(c); this.gcInst(c.inst); }
    if (c.map >= 0) this.toMap(c, c.map, { t: 'gone', id: c.id }, c);
    mi = Math.max(0, Math.min(R.D.maps.length - 1, mi | 0)); c.ch.map = mi; c.map = mi;
    const k = force && khu ? Math.max(1, Math.min(KHU_CAP, khu | 0)) : this.pickKhu(c.srv, mi, want);
    c.inst = this.instOf(c.srv, mi, k); c.inst.join(c, x); c.dirty = true;
    this.friendsChanged(c);
  }
  meOf(c, full) {
    const ch = c.ch, f = c.f;
    const o = { lv: ch.lv, exp: ch.exp, need: R.expNeed(ch.lv), gold: ch.gold, pots: ch.pots, stones: ch.stones, kills: ch.kills, sk: ch.sk, books: ch.books, map: ch.map,
      hp: Math.round(f.hp), maxHp: f.maxHp, atk: f.atk, def: f.def, spd: f.spd, crit: f.crit, dead: f.dead > 0 ? 1 : 0,
      ki: Math.floor(f.ki), maxKi: f.maxKi, dodge: f.dodge, ls: f.ls, pen: f.pen, pt: ch.pt || {}, ptFree: R.ptFree(ch), ptCost: R.resetCost(ch), kc: [0, 1, 2, 3, 4, 5].map(i => R.kiCost(ch.lv, i)),
      cds: f.cds.map(x => +x.toFixed(2)), gcd: +f.gcd.toFixed(2), potCd: +f.potCd.toFixed(2), buffs: f.buffs.map(b => ({ id: b.id, t: +b.t.toFixed(1), max: b.max })),
      stun: f.stunT > 0 ? +f.stunT.toFixed(1) : 0, slow: f.slowT > 0 ? f.slowM : 1, pois: f.pois ? 1 : 0, title: ch.title && ch.title.until > Date.now() ? ch.title.n : '' };
    if (full) Object.assign(o, { name: ch.name, cls: ch.cls, inv: ch.inv, eq: ch.eq });
    return o;
  }
  sendMe(c) { const full = c.bagDirty; c.meDirty = false; c.bagDirty = false; this.sendTo(c, { t: 'me', full: full ? 1 : 0, me: this.meOf(c, full) }); }
  writeChar(c) {
    if (!c.ch) return; const d = c.ch; c.dirty = false; c.lastSave = Date.now();
    this.sql.exec('INSERT INTO chars(user_id,srv,data,lv,kills,name,cls,updated) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(user_id,srv) DO UPDATE SET data=excluded.data, lv=excluded.lv, kills=excluded.kills, updated=excluded.updated',
      c.uid, c.srv, JSON.stringify(d), d.lv | 0, d.kills | 0, clean(d.name, 16), clean(d.cls, 12), Date.now());
  }
  onV2(c, raw) {
    if (typeof raw !== 'string' || raw.length > 4096) return;
    const now = Date.now(); if (now - c.rate.at > 1000) { c.rate.n = 0; c.rate.at = now; } if (++c.rate.n > 80) return; // chặn gửi dồn dập
    let m; try { m = JSON.parse(raw); } catch (e) { return; }
    if (!m || typeof m !== 'object' || typeof m.t !== 'string') return;
    if (m.t === 'ping') return this.sendTo(c, { t: 'pong', at: m.at });
    if (m.t === 'create') {
      if (c.ch) return;
      const name = clean(m.name, 16).trim();
      if (!okName(name)) return this.sendTo(c, { t: 'res', op: 'create', ok: false, msg: 'Tên nhân vật 3–16 ký tự, gồm chữ, số, dấu cách hoặc _' });
      if (!R.CLS_KEYS.includes(m.cls)) return this.sendTo(c, { t: 'res', op: 'create', ok: false, msg: 'Phái không hợp lệ.' });
      this.loadChar(c, R.newChar(m.cls, name)); this.writeChar(c);
      this.sendTo(c, { t: 'res', op: 'create', ok: true }); this.sendTo(c, { t: 'me', full: 1, me: this.meOf(c, true) });
      return this.enterMap(c, 0, null);
    }
    if (!c.ch || !c.inst) return;
    if (m.t === 'gm') return void onGM(this, c, m).catch(e => console.error(e));
    if (onSocial(this, c, m)) return;
    const I = c.inst;
    switch (m.t) {
      case 'in': return I.move(c, m);
      case 'atk': return I.attack(c, m);
      case 'sk': return I.skill(c, m);
      case 'khu': {
        if (m.k == null) return this.sendTo(c, this.khuList(c));
        const k = m.k | 0, now = Date.now();
        if (k < 1 || k > KHU_CAP || k === I.khu) return;
        if (c.f.dead > 0) return this.sendTo(c, { t: 'res', op: 'khu', ok: false, msg: 'Đang gục ngã, chưa đổi khu được.' });
        if (now - (c.khuAt || 0) < 5000) return this.sendTo(c, { t: 'res', op: 'khu', ok: false, msg: 'Chờ vài giây rồi đổi khu.' });
        if (I.M.arena && !this.insts.has(c.srv * 10000 + c.map * 100 + k)) return this.sendTo(c, { t: 'res', op: 'khu', ok: false, msg: 'Khu ' + k + ' chưa có người vào trong khung giờ này.' });
        if (I.M.arena && this.arenaDone.get(c.srv * 10000 + c.map * 100 + k) === this.arenaWin(c.map, now).start) return this.sendTo(c, { t: 'res', op: 'khu', ok: false, msg: 'Trùm ở khu ' + k + ' đã bị hạ.' });
        if (this.khuN(c.srv, c.map, k) >= this.khuMax() && !isStaff(this, c.uid)) return this.sendTo(c, { t: 'res', op: 'khu', ok: false, msg: 'Khu ' + k + ' đã đầy (' + this.khuMax() + ' người).' });
        c.khuAt = now; this.enterMap(c, c.map, c.f.x, k, true);
        return this.sendTo(c, { t: 'res', op: 'khu', ok: true, msg: 'Đã vào khu ' + k + '.' });
      }
      case 'warp': {
        const p = I.M.portals[m.p | 0]; if (!p || c.f.dead > 0 || Math.abs(c.f.x - p.x) > (p.arena ? 120 : 70) || Math.abs(c.f.y - p.y) > 90) return this.sendTo(c, { t: 'res', op: 'warp', ok: false });
        if (R.D.maps[p.to].arena) return this.enterArena(c, p.to);
        return this.enterMap(c, p.to, p.tx);
      }
      case 'chat': {
        const text = clean(m.text, 120).trim(); if (!text || now - c.lastChat < 700) return; c.lastChat = now;
        if (mutedUntil(this, c.uid)) return this.sendTo(c, { t: 'res', op: 'chat', ok: false, msg: 'Bạn đang bị cấm trò chuyện.' });
        const msg = { t: 'chat', id: c.id, n: c.ch.name, text, all: !!m.all };
        chatLog(this, c, c.ch.name, text, m.all ? 'all' : 'map:' + c.map);
        if (m.all) {
          // nhắn cả máy chủ tốn vàng
          if (c.ch.gold < R.WORLD_CHAT_COST) return this.sendTo(c, { t: 'res', op: 'chat', ok: false, msg: 'Nhắn cả máy chủ cần ' + R.WORLD_CHAT_COST + ' vàng.' });
          c.ch.gold -= R.WORLD_CHAT_COST; c.dirty = true; c.meDirty = true;
          for (const o of this.clients.values()) if (o.srv === c.srv) this.sendTo(o, o.v2 ? msg : { t: 'chat', id: c.id, n: c.ch.name, text, all: true });
          return;
        }
        for (const o of this.clients.values()) if (o.srv === c.srv && o.map === c.map && (o.v2 ? o.inst === c.inst : c.inst.khu === 1)) this.sendTo(o, msg);
        return;
      }
      default: {
        const op = OPS[m.t]; if (!op) return;
        const r = op(c, m) || { ok: false };
        this.sendTo(c, { t: 'res', op: m.t, rq: m.rq | 0, ...r });
        if (r.ok) { c.dirty = true; c.bagDirty = true; this.sendMe(c); }
        if (m.t === 'forge' && r.win && r.up >= 8) glog(this, 'forge', c, 'Rèn thành công lên +' + r.up);
      }
    }
  }
}
