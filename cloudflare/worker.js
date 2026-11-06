// Máy chủ Hiệp Sĩ Nét Chì chạy trên Cloudflare (gói miễn phí).
// Worker nhận yêu cầu /api/* và /ws rồi chuyển cho một Durable Object "world" giữ toàn bộ người chơi và cơ sở dữ liệu SQLite.
// Giao thức giống hệt server/index.js nên game không cần sửa.
import { DurableObject } from 'cloudflare:workers';

const TICK_MS = 100;
const MAX_SAVE = 300 * 1024;
const ITER = 60000; // vòng lặp băm mật khẩu PBKDF2
// danh sách máy chủ (cụm) trong game; mỗi tài khoản có một nhân vật riêng trên mỗi máy chủ
// Trình duyệt chỉ dành cho admin thử game; người chơi dùng ứng dụng Windows / Android (gửi app=pc|android).
// Thêm admin: biến ADMINS trong Cloudflare (tên tài khoản, cách nhau bằng dấu phẩy).
const ADMIN_DEFAULT = ['phamlongnb2004'];
let ADMINS = new Set(ADMIN_DEFAULT);
const isAdmin = name => ADMINS.has(String(name || '').toLowerCase());
const WEB_MSG = 'Hiệp Sĩ Nét Chì chỉ chơi trên ứng dụng. Hãy tải game cho máy tính hoặc điện thoại.';

const SERVERS = [{ id: 1, name: 'Server 1', tag: 'Mới' }];
const srvOf = v => SERVERS.find(x => x.id === (v | 0)) || null;

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
function sameHex(a, b) { if (a.length !== b.length) return false; let d = 0; for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i); return d === 0; }

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    // xác minh ứng dụng Android (TWA) để chạy toàn màn hình, không hiện thanh địa chỉ
    if (url.pathname === '/.well-known/assetlinks.json') return new Response(env.ASSETLINKS || '[]', { headers: { 'Content-Type': 'application/json' } });
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
    this.clients = new Map();
    this.seq = 1;
    this.tries = new Map();
    this.timer = null;
  }

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
    if (url.pathname === '/api/health') return json(200, { ok: true, online: this.clients.size, store: 'cloudflare-sqlite' });
    if (url.pathname === '/api/top') {
      const srv = srvOf(url.searchParams.get('srv') || 1) ? (url.searchParams.get('srv') | 0 || 1) : 1;
      const top = this.sql.exec('SELECT user_id id, name, cls, lv, kills FROM chars WHERE srv=? ORDER BY lv DESC, kills DESC LIMIT 20', srv).toArray();
      return json(200, { top });
    }
    if (req.method !== 'POST') return json(405, { error: 'Sai phương thức' });
    const ip = req.headers.get('CF-Connecting-IP') || '';
    if (this.limited(ip)) return json(429, { error: 'Thử lại sau một phút.' });
    let b; try { b = await req.json(); } catch (e) { return json(400, { error: 'Dữ liệu không hợp lệ' }); }
    if (url.pathname === '/api/servers') {
      const u = b.token && this.one('SELECT u.id, u.username FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=?', String(b.token));
      if (!u) return json(401, { error: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' });
      if (b.app === 'web' && !isAdmin(u.username)) return json(403, { error: WEB_MSG, code: 'app' });
      const servers = SERVERS.map(x => {
        const ch = this.one('SELECT name, cls, lv FROM chars WHERE user_id=? AND srv=?', u.id, x.id);
        let online = 0; for (const c of this.clients.values()) if (c.srv === x.id) online++;
        return { id: x.id, name: x.name, tag: x.tag, online, char: ch ? { name: ch.name, cls: ch.cls, lv: ch.lv | 0 } : null };
      });
      return json(200, { servers });
    }
    const user = String(b.user || '').trim(), pass = String(b.pass || '');
    if (url.pathname === '/api/register') {
      if (b.app === 'web') return json(403, { error: WEB_MSG, code: 'app' });
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
      if (b.app === 'web' && !isAdmin(u.username)) return json(403, { error: WEB_MSG, code: 'app' });
      return json(200, this.newSession(u));
    }
    if (url.pathname === '/api/logout') { if (b.token) this.sql.exec('DELETE FROM sessions WHERE token=?', String(b.token)); return json(200, { ok: true }); }
    return json(404, { error: 'Không có' });
  }

  newSession(u) {
    const token = randHex(24);
    this.sql.exec('INSERT INTO sessions(token,user_id,created) VALUES(?,?,?)', token, u.id, Date.now());
    return { token, user: u.username };
  }

  openSocket(req, url) {
    if (req.headers.get('Upgrade') !== 'websocket') return json(426, { error: 'Cần WebSocket' });
    const pair = new WebSocketPair();
    const [client, ws] = Object.values(pair);
    ws.accept();
    const send = obj => { try { ws.send(JSON.stringify(obj)); } catch (e) {} };
    const token = String(url.searchParams.get('token') || '');
    const srv = srvOf(url.searchParams.get('srv') || 1);
    if (!srv) {
      send({ t: 'err', code: 'srv', msg: 'Máy chủ này chưa mở.' });
      ws.close(4003, 'srv');
      return new Response(null, { status: 101, webSocket: client });
    }
    const u = token && this.one('SELECT u.id, u.username FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=?', token);
    if (!u) {
      send({ t: 'err', code: 'auth', msg: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' });
      ws.close(4001, 'auth');
      return new Response(null, { status: 101, webSocket: client });
    }
    if (url.searchParams.get('app') === 'web' && !isAdmin(u.username)) {
      send({ t: 'err', code: 'app', msg: WEB_MSG });
      ws.close(4005, 'app');
      return new Response(null, { status: 101, webSocket: client });
    }
    for (const c of this.clients.values()) if (c.uid === u.id) { this.sendTo(c, { t: 'err', code: 'dup', msg: 'Tài khoản vừa đăng nhập ở nơi khác.' }); try { c.ws.close(4002, 'dup'); } catch (e) {} this.drop(c); }
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
    this.clients.delete(c.id);
    if (c.map >= 0) this.toMap(c, c.map, { t: 'gone', id: c.id });
    this.toSrv(c.srv, { t: 'count', online: this.count(c.srv) });
    if (!this.clients.size && this.timer) { clearInterval(this.timer); this.timer = null; }
  }

  sendTo(c, obj) { try { c.ws.send(typeof obj === 'string' ? obj : JSON.stringify(obj)); } catch (e) {} }
  count(srv) { let n = 0; for (const c of this.clients.values()) if (c.srv === srv) n++; return n; }
  // chỉ gửi cho người chơi cùng máy chủ (và cùng bản đồ)
  toMap(from, map, obj, except) { const s = JSON.stringify(obj); for (const c of this.clients.values()) if (c.srv === from.srv && c.map === map && c !== except) this.sendTo(c, s); }
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
      const msg = { t: 'chat', id: c.id, n: (c.st && c.st[8]) || c.user, text, all: !!m.all };
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
    this.timer = setInterval(() => {
      const byMap = new Map();
      for (const c of this.clients.values()) if (c.st && c.map >= 0) { const k = c.srv * 100 + c.map; if (!byMap.has(k)) byMap.set(k, []); byMap.get(k).push(c.st); }
      const now = Date.now();
      for (const c of this.clients.values()) {
        if (c.map >= 0) this.sendTo(c, { t: 'ps', p: (byMap.get(c.srv * 100 + c.map) || []).filter(s => s[0] !== c.id) });
        if (c.pending && now - c.lastSave > 15000) this.writeSave(c);
      }
    }, TICK_MS);
  }
}
