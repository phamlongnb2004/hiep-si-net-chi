// Máy chủ online Hiệp Sĩ Nét Chì: tài khoản, lưu nhân vật, đồng bộ vị trí người chơi theo bản đồ, chat.
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');
const makeStore = require('./db');

const PORT = +process.env.PORT || 8080;
const PUBLIC = path.join(__dirname, '..', 'public');
const TICK_MS = 100;            // gửi vị trí 10 lần/giây
const MAX_SAVE = 300 * 1024;    // dung lượng tối đa một bản lưu
const db = makeStore();
// danh sách máy chủ (cụm) trong game; mỗi tài khoản có một nhân vật riêng trên mỗi máy chủ
const SERVERS = [{ id: 1, name: 'Server 1', tag: 'Mới' }];
const srvOf = v => SERVERS.find(x => x.id === (v | 0)) || null;
const count = srv => { let n = 0; for (const c of clients.values()) if (c.srv === srv) n++; return n; };

/* ---------- tiện ích ---------- */
const hashPass = (pass, salt) => crypto.scryptSync(pass, salt, 64).toString('hex');
const okName = s => typeof s === 'string' && /^[\p{L}\p{N}_ ]{3,16}$/u.test(s) && s.trim() === s;
const clean = (s, n) => String(s == null ? '' : s).replace(/[\u0000-\u001f\u007f<>]/g, '').slice(0, n);
const num = (v, lo, hi) => { v = +v; return Number.isFinite(v) ? Math.min(hi, Math.max(lo, v)) : lo; };

function send(res, code, obj, type) {
  const body = typeof obj === 'string' || Buffer.isBuffer(obj) ? obj : JSON.stringify(obj);
  res.writeHead(code, {
    'Content-Type': type || 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Cache-Control': type && !type.startsWith('application/json') ? 'public, max-age=300' : 'no-store',
  });
  res.end(body);
}
function readJson(req) {
  return new Promise((resolve, reject) => {
    let n = 0; const chunks = [];
    req.on('data', c => { n += c.length; if (n > 64 * 1024) { reject(new Error('quá lớn')); req.destroy(); } else chunks.push(c); });
    req.on('end', () => { try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}')); } catch (e) { reject(e); } });
    req.on('error', reject);
  });
}

/* ---------- chống spam đăng nhập ---------- */
const tries = new Map();
function limited(ip) {
  const now = Date.now(), t = tries.get(ip) || { n: 0, at: now };
  if (now - t.at > 60000) { t.n = 0; t.at = now; }
  t.n++; tries.set(ip, t); return t.n > 20;
}

/* ---------- API tài khoản ---------- */
async function api(req, res, url) {
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').split(',')[0].trim();
  if (url.pathname === '/api/health') return send(res, 200, { ok: true, online: clients.size, store: db.kind });
  if (url.pathname === '/api/top') return send(res, 200, { top: await db.top(20) });
  if (req.method !== 'POST') return send(res, 405, { error: 'Sai phương thức' });
  if (limited(ip)) return send(res, 429, { error: 'Thử lại sau một phút.' });
  let b; try { b = await readJson(req); } catch (e) { return send(res, 400, { error: 'Dữ liệu không hợp lệ' }); }
  if (url.pathname === '/api/servers') {
    const u = b.token && await db.sessionUser(String(b.token)).catch(() => null);
    if (!u) return send(res, 401, { error: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' });
    const servers = [];
    for (const x of SERVERS) {
      const sv = await db.getSave(u.id, x.id).catch(() => null);
      servers.push({ id: x.id, name: x.name, tag: x.tag, online: count(x.id), char: sv ? { name: sv.name, cls: sv.cls, lv: sv.lv | 0 } : null });
    }
    return send(res, 200, { servers });
  }
  const user = String(b.user || '').trim(), pass = String(b.pass || '');
  if (url.pathname === '/api/register') {
    if (!okName(user)) return send(res, 400, { error: 'Tên tài khoản 3–16 ký tự, gồm chữ, số, dấu cách hoặc _' });
    if (pass.length < 6 || pass.length > 72) return send(res, 400, { error: 'Mật khẩu cần từ 6 đến 72 ký tự' });
    const salt = crypto.randomBytes(16).toString('hex');
    const u = await db.createUser(user, hashPass(pass, salt), salt);
    if (!u) return send(res, 409, { error: 'Tên tài khoản đã có người dùng' });
    return send(res, 200, await newSession(u));
  }
  if (url.pathname === '/api/login') {
    const u = await db.findUser(user);
    const good = u && crypto.timingSafeEqual(Buffer.from(hashPass(pass, u.salt), 'hex'), Buffer.from(u.hash, 'hex'));
    if (!good) return send(res, 401, { error: 'Sai tên tài khoản hoặc mật khẩu' });
    return send(res, 200, await newSession(u));
  }
  if (url.pathname === '/api/logout') { if (b.token) await db.dropSession(String(b.token)); return send(res, 200, { ok: true }); }
  return send(res, 404, { error: 'Không có' });
}
async function newSession(u) {
  const token = crypto.randomBytes(24).toString('hex');
  await db.addSession(token, u.id);
  return { token, user: u.username };
}

/* ---------- phục vụ file game (chơi trên trình duyệt) ---------- */
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp', '.ico': 'image/x-icon', '.json': 'application/json', '.woff2': 'font/woff2', '.webmanifest': 'application/manifest+json', '.apk': 'application/vnd.android.package-archive', '.exe': 'application/octet-stream' };
function serveFile(req, res, url) {
  let p = decodeURIComponent(url.pathname);
  if (p === '/') p = '/index.html';
  const f = path.normalize(path.join(PUBLIC, p));
  if (!f.startsWith(PUBLIC)) return send(res, 403, 'Forbidden', 'text/plain');
  fs.readFile(f, (err, buf) => {
    if (err) return send(res, 404, 'Không tìm thấy', 'text/plain; charset=utf-8');
    send(res, 200, buf, MIME[path.extname(f)] || 'application/octet-stream');
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  if (req.method === 'OPTIONS') return send(res, 204, '');
  try {
    if (url.pathname.startsWith('/api/')) return await api(req, res, url);
    return serveFile(req, res, url);
  } catch (e) {
    console.error(e); send(res, 500, { error: 'Lỗi máy chủ' });
  }
});

/* ---------- thời gian thực ---------- */
const clients = new Map(); // id -> client
let seq = 1;
const wss = new WebSocketServer({ server, path: '/ws', maxPayload: MAX_SAVE + 4096 });

function wsSend(ws, obj) { if (ws.readyState === 1) ws.send(JSON.stringify(obj)); }
function toMap(from, map, obj, except) {
  const s = JSON.stringify(obj);
  for (const c of clients.values()) if (c.srv === from.srv && c.map === map && c !== except && c.ws.readyState === 1) c.ws.send(s);
}
function toSrv(srv, obj) { const s = JSON.stringify(obj); for (const c of clients.values()) if (c.srv === srv && c.ws.readyState === 1) c.ws.send(s); }

wss.on('connection', async (ws, req) => {
  const url = new URL(req.url, 'http://x');
  const u = await db.sessionUser(String(url.searchParams.get('token') || '')).catch(() => null);
  if (!u) { wsSend(ws, { t: 'err', code: 'auth', msg: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.' }); return ws.close(4001, 'auth'); }
  const srv = srvOf(url.searchParams.get('srv') || 1);
  if (!srv) { wsSend(ws, { t: 'err', code: 'srv', msg: 'Máy chủ này chưa mở.' }); return ws.close(4003, 'srv'); }
  // một tài khoản chỉ online một nơi
  for (const c of clients.values()) if (c.uid === u.id) { wsSend(c.ws, { t: 'err', code: 'dup', msg: 'Tài khoản vừa đăng nhập ở nơi khác.' }); c.ws.close(4002, 'dup'); }
  const c = { id: seq++, uid: u.id, user: u.username, srv: srv.id, ws, map: -1, st: null, lastChat: 0, alive: true, lock: null };
  clients.set(c.id, c);
  const save = await db.getSave(u.id, srv.id).catch(() => null);
  if (save) c.lock = { name: clean(save.name, 16), cls: save.cls };
  wsSend(ws, { t: 'welcome', id: c.id, user: u.username, srv: srv.id, srvName: srv.name, save, online: count(srv.id) });
  toSrv(srv.id, { t: 'count', online: count(srv.id) });

  ws.on('pong', () => { c.alive = true; });
  ws.on('message', async raw => {
    let m; try { m = JSON.parse(raw); } catch (e) { return; }
    if (!m || typeof m !== 'object') return;
    if (m.t === 'st') {
      const map = num(m.m, 0, 20) | 0;
      if (map !== c.map) { if (c.map >= 0) toMap(c, c.map, { t: 'gone', id: c.id }, c); c.map = map; }
      c.st = [c.id, Math.round(num(m.x, 0, 5000)), Math.round(num(m.y, 0, 5000)), m.f < 0 ? -1 : 1, m.mv ? 1 : 0, m.sw ? 1 : 0,
        clean(m.c, 12), num(m.lv, 1, 999) | 0, clean(m.n, 16), num(m.hp, 0, 1), m.dead ? 1 : 0, num(m.g, 0, 99) | 0];
    } else if (m.t === 'chat') {
      const now = Date.now(), text = clean(m.text, 120).trim();
      if (!text || now - c.lastChat < 700) return;
      c.lastChat = now;
      const name = (c.st && c.st[8]) || c.user;
      const msg = { t: 'chat', id: c.id, n: name, text, all: !!m.all };
      if (m.all) toSrv(c.srv, msg); else toMap(c, c.map, msg);
    } else if (m.t === 'save') {
      const d = m.d;
      if (!d || typeof d !== 'object' || typeof d.cls !== 'string') return;
      const s = JSON.stringify(d); if (s.length > MAX_SAVE) return wsSend(ws, { t: 'err', code: 'save', msg: 'Bản lưu quá lớn.' });
      if (c.lock && (d.cls !== c.lock.cls || clean(d.name, 16) !== c.lock.name)) return wsSend(ws, { t: 'err', code: 'lock', msg: 'Tài khoản đã có nhân vật ' + c.lock.name + ' trên máy chủ này.' });
      if (!c.lock) c.lock = { name: clean(d.name, 16), cls: d.cls };
      try { await db.putSave(c.uid, d, c.srv); } catch (e) { console.error('save', e.message); }
    } else if (m.t === 'ping') wsSend(ws, { t: 'pong', at: m.at });
  });
  ws.on('close', () => {
    if (clients.get(c.id) === c) clients.delete(c.id);
    if (c.map >= 0) toMap(c, c.map, { t: 'gone', id: c.id });
    toSrv(c.srv, { t: 'count', online: count(c.srv) });
  });
});

// gửi danh sách người chơi cùng bản đồ
setInterval(() => {
  const byMap = new Map();
  for (const c of clients.values()) if (c.st && c.map >= 0) { const k = c.srv * 100 + c.map; if (!byMap.has(k)) byMap.set(k, []); byMap.get(k).push(c.st); }
  for (const c of clients.values()) {
    if (c.map < 0 || c.ws.readyState !== 1) continue;
    const list = (byMap.get(c.srv * 100 + c.map) || []).filter(s => s[0] !== c.id);
    c.ws.send(JSON.stringify({ t: 'ps', p: list }));
  }
}, TICK_MS);
// ngắt kết nối chết
setInterval(() => {
  for (const c of clients.values()) { if (!c.alive) { c.ws.terminate(); continue; } c.alive = false; try { c.ws.ping(); } catch (e) {} }
}, 30000);

db.init().then(() => {
  server.listen(PORT, () => {
    console.log(`Hiệp Sĩ Nét Chì online: cổng ${PORT}, lưu trữ: ${db.kind}`);
    if (db.kind === 'file' && (process.env.RENDER || process.env.SPACE_ID)) console.warn('CẢNH BÁO: chưa đặt DATABASE_URL. Trên Render/Hugging Face, dữ liệu trong file sẽ mất mỗi lần máy chủ khởi động lại.');
  });
}).catch(e => { console.error('Không kết nối được cơ sở dữ liệu:', e.message); process.exit(1); });
const stop = () => { db.close().finally(() => process.exit(0)); };
process.on('SIGTERM', stop); process.on('SIGINT', stop);
