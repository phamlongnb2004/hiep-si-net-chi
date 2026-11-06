// Bạn bè (tối đa 100, lưu theo tài khoản, xem tên nhân vật trên máy chủ đang chơi) và giao dịch giữa hai người chơi.
// Giao dịch: mời → đồng ý → mỗi bên đặt đồ/vàng → cả hai "Khóa" → cả hai "Đồng ý" → máy chủ kiểm lại và đổi một lần.
// Đồ bị khóa (rơi từ quái có tỉ lệ khóa) và đồ đang mặc không giao dịch được.
import * as R from '../shared/rules.js';

const TRADE_MAX_ITEMS = 10;

export function initSocial(w) {
  w.sql.exec(`CREATE TABLE IF NOT EXISTS friends(uid INTEGER NOT NULL, fid INTEGER NOT NULL, at INTEGER, PRIMARY KEY(uid, fid))`);
  w.sql.exec(`CREATE TABLE IF NOT EXISTS friend_req(from_uid INTEGER NOT NULL, to_uid INTEGER NOT NULL, at INTEGER, PRIMARY KEY(from_uid, to_uid))`);
  w.sql.exec(`CREATE TABLE IF NOT EXISTS trade_log(at INTEGER, srv INTEGER, a INTEGER, b INTEGER, data TEXT)`);
  w.trades = new Map(); w.tradeSeq = 1;
}

/* ---------------- bạn bè ---------------- */
const nameOn = (w, uid, srv) => { const r = w.one('SELECT name, lv, cls FROM chars WHERE user_id=? AND srv=?', uid, srv); return r || null; };
const onlineC = (w, uid, srv) => { for (const c of w.clients.values()) if (c.uid === uid && c.srv === srv && c.v2 && c.ch) return c; for (const c of w.clients.values()) if (c.uid === uid && c.srv === srv) return c; return null; };
const countFriends = (w, uid) => w.one('SELECT COUNT(*) n FROM friends WHERE uid=?', uid).n | 0;

export function friendList(w, c) {
  const list = w.sql.exec('SELECT fid FROM friends WHERE uid=? ORDER BY at', c.uid).toArray().map(r => {
    const ch = nameOn(w, r.fid, c.srv), on = onlineC(w, r.fid, c.srv);
    const u = ch ? null : w.one('SELECT username FROM users WHERE id=?', r.fid);
    return { uid: r.fid, name: ch ? ch.name : (u ? u.username : '?'), lv: ch ? ch.lv | 0 : 0, cls: ch ? ch.cls : '', online: on ? 1 : 0, map: on && on.map >= 0 ? on.map : -1, khu: on && on.inst ? on.inst.khu : 0, id: on ? on.id : 0 };
  });
  const req = w.sql.exec('SELECT from_uid FROM friend_req WHERE to_uid=? ORDER BY at', c.uid).toArray().map(r => {
    const ch = nameOn(w, r.from_uid, c.srv), u = w.one('SELECT username FROM users WHERE id=?', r.from_uid);
    return { uid: r.from_uid, name: ch ? ch.name : (u ? u.username : '?'), lv: ch ? ch.lv | 0 : 0 };
  });
  w.sendTo(c, { t: 'friends', list, req, max: R.FRIEND_MAX });
}

function makeFriends(w, a, b) {
  const now = Date.now();
  w.sql.exec('INSERT OR IGNORE INTO friends(uid,fid,at) VALUES(?,?,?)', a, b, now);
  w.sql.exec('INSERT OR IGNORE INTO friends(uid,fid,at) VALUES(?,?,?)', b, a, now);
  w.sql.exec('DELETE FROM friend_req WHERE (from_uid=? AND to_uid=?) OR (from_uid=? AND to_uid=?)', a, b, b, a);
}
const refresh = (w, uid, srv) => { for (const o of w.clients.values()) if (o.uid === uid && o.v2 && o.ch) friendList(w, o); };

export function onSocial(w, c, m) {
  const res = (op, ok, msg, extra) => w.sendTo(c, { t: 'res', op, ok, msg, ...(extra || {}) });
  switch (m.t) {
    case 'fr_list': return friendList(w, c), true;
    case 'fr_add': {
      // theo tên nhân vật trên máy chủ này, hoặc theo người chơi đang đứng gần (id)
      let uid = 0;
      if (m.id) { const o = w.clients.get(m.id | 0); if (o && o.srv === c.srv) uid = o.uid; }
      else { const n = String(m.name || '').trim(); const r = n && w.one('SELECT user_id FROM chars WHERE srv=? AND name=? COLLATE NOCASE', c.srv, n); if (r) uid = r.user_id; }
      if (!uid) return res('fr_add', false, 'Không tìm thấy nhân vật này trên máy chủ.'), true;
      if (uid === c.uid) return res('fr_add', false, 'Không thể kết bạn với chính mình.'), true;
      if (w.one('SELECT 1 x FROM friends WHERE uid=? AND fid=?', c.uid, uid)) return res('fr_add', false, 'Hai bạn đã là bạn bè.'), true;
      if (countFriends(w, c.uid) >= R.FRIEND_MAX) return res('fr_add', false, 'Danh sách bạn bè đã đủ ' + R.FRIEND_MAX + ' người.'), true;
      if (countFriends(w, uid) >= R.FRIEND_MAX) return res('fr_add', false, 'Người này đã đủ ' + R.FRIEND_MAX + ' bạn.'), true;
      // người kia đã mời mình trước: đồng ý luôn
      if (w.one('SELECT 1 x FROM friend_req WHERE from_uid=? AND to_uid=?', uid, c.uid)) { makeFriends(w, c.uid, uid); refresh(w, uid, c.srv); friendList(w, c); return res('fr_add', true, 'Đã kết bạn.'), true; }
      w.sql.exec('INSERT OR REPLACE INTO friend_req(from_uid,to_uid,at) VALUES(?,?,?)', c.uid, uid, Date.now());
      for (const o of w.clients.values()) if (o.uid === uid && o.v2 && o.ch) { w.sendTo(o, { t: 'fr_req', uid: c.uid, name: c.ch.name, lv: c.ch.lv }); friendList(w, o); }
      return res('fr_add', true, 'Đã gửi lời mời kết bạn.'), true;
    }
    case 'fr_ok': {
      const uid = m.uid | 0; if (!w.one('SELECT 1 x FROM friend_req WHERE from_uid=? AND to_uid=?', uid, c.uid)) return res('fr_ok', false), true;
      if (countFriends(w, c.uid) >= R.FRIEND_MAX || countFriends(w, uid) >= R.FRIEND_MAX) return res('fr_ok', false, 'Danh sách bạn bè đã đủ ' + R.FRIEND_MAX + ' người.'), true;
      makeFriends(w, c.uid, uid); friendList(w, c); refresh(w, uid, c.srv);
      return res('fr_ok', true, 'Đã kết bạn.'), true;
    }
    case 'fr_no': w.sql.exec('DELETE FROM friend_req WHERE from_uid=? AND to_uid=?', m.uid | 0, c.uid); friendList(w, c); return true;
    case 'fr_del': {
      const uid = m.uid | 0; w.sql.exec('DELETE FROM friends WHERE (uid=? AND fid=?) OR (uid=? AND fid=?)', c.uid, uid, uid, c.uid);
      friendList(w, c); refresh(w, uid, c.srv); return res('fr_del', true, 'Đã xóa bạn.'), true;
    }
    case 'pm': { // nhắn riêng cho bạn bè đang online (miễn phí)
      const uid = m.uid | 0, text = String(m.text || '').replace(/[\u0000-\u001f\u007f<>]/g, '').slice(0, 120).trim();
      if (!text || !w.one('SELECT 1 x FROM friends WHERE uid=? AND fid=?', c.uid, uid)) return true;
      const o = onlineC(w, uid, c.srv); if (!o) return res('pm', false, 'Bạn này đang không online.'), true;
      const msg = { t: 'chat', id: c.id, n: c.ch.name, text, pm: 1, to: o.ch ? o.ch.name : '' };
      w.sendTo(o, msg); w.sendTo(c, msg); return true;
    }
    case 'tr_ask': return tradeAsk(w, c, m), true;
    case 'tr_yes': return tradeYes(w, c, m), true;
    case 'tr_set': return tradeSet(w, c, m), true;
    case 'tr_lock': return tradeFlag(w, c, 'lock'), true;
    case 'tr_ok': return tradeFlag(w, c, 'ok'), true;
    case 'tr_cancel': return tradeCancel(w, c, 'Đã hủy giao dịch.'), true;
  }
  return false;
}

/* ---------------- giao dịch ---------------- */
const tradeOf = (w, c) => c.trade ? w.trades.get(c.trade) : null;
const other = (T, c) => T.a === c ? T.b : T.a;
function tradeAsk(w, c, m) {
  const o = w.clients.get(m.id | 0);
  if (!o || !o.v2 || !o.ch || o === c || o.srv !== c.srv || o.inst !== c.inst) return w.sendTo(c, { t: 'res', op: 'tr_ask', ok: false, msg: 'Người này không ở cùng bản đồ và khu.' });
  if (c.trade || o.trade) return w.sendTo(c, { t: 'res', op: 'tr_ask', ok: false, msg: 'Một trong hai người đang giao dịch.' });
  c.tradeAsk = { to: o.id, at: Date.now() };
  w.sendTo(o, { t: 'tr_ask', id: c.id, n: c.ch.name, lv: c.ch.lv });
  w.sendTo(c, { t: 'res', op: 'tr_ask', ok: true, msg: 'Đã mời ' + o.ch.name + ' giao dịch.' });
}
function tradeYes(w, c, m) {
  const o = w.clients.get(m.id | 0);
  if (!o || !o.tradeAsk || o.tradeAsk.to !== c.id || Date.now() - o.tradeAsk.at > 60000 || o.inst !== c.inst || o.trade || c.trade) return w.sendTo(c, { t: 'res', op: 'tr_yes', ok: false, msg: 'Lời mời đã hết hạn.' });
  o.tradeAsk = null;
  const T = { id: w.tradeSeq++, a: o, b: c, offer: new Map([[o.id, { items: [], gold: 0 }], [c.id, { items: [], gold: 0 }]]), lock: new Set(), ok: new Set() };
  w.trades.set(T.id, T); o.trade = T.id; c.trade = T.id; sendTrade(w, T);
}
function viewFor(T, c) {
  const me = T.offer.get(c.id), o = other(T, c), th = T.offer.get(o.id);
  const items = (ch, ids) => ids.map(id => ch.inv.find(it => String(it.id) === String(id))).filter(Boolean);
  return { t: 'trade', id: T.id, me: { items: items(c.ch, me.items), gold: me.gold, lock: T.lock.has(c.id) ? 1 : 0, ok: T.ok.has(c.id) ? 1 : 0 },
    them: { id: o.id, n: o.ch.name, lv: o.ch.lv, items: items(o.ch, th.items), gold: th.gold, lock: T.lock.has(o.id) ? 1 : 0, ok: T.ok.has(o.id) ? 1 : 0 } };
}
const sendTrade = (w, T) => { w.sendTo(T.a, viewFor(T, T.a)); w.sendTo(T.b, viewFor(T, T.b)); };
function tradeSet(w, c, m) {
  const T = tradeOf(w, c); if (!T) return;
  if (T.lock.has(c.id)) return w.sendTo(c, { t: 'res', op: 'tr_set', ok: false, msg: 'Đã khóa, hãy hủy khóa để đổi.' });
  const ids = Array.isArray(m.items) ? [...new Set(m.items.map(String))].slice(0, TRADE_MAX_ITEMS) : [];
  const ok = [];
  for (const id of ids) { const it = c.ch.inv.find(x => String(x.id) === id); if (it && !it.lock) ok.push(id); }
  const gold = Math.max(0, Math.min(c.ch.gold, Math.floor(+m.gold || 0)));
  T.offer.set(c.id, { items: ok, gold });
  T.lock.clear(); T.ok.clear();             // đổi đồ thì cả hai phải khóa lại từ đầu
  sendTrade(w, T);
  if (ok.length < ids.length) w.sendTo(c, { t: 'res', op: 'tr_set', ok: false, msg: 'Đồ bị khóa không giao dịch được.' });
}
function tradeFlag(w, c, k) {
  const T = tradeOf(w, c); if (!T) return;
  if (k === 'lock') { if (T.lock.has(c.id)) { T.lock.delete(c.id); T.ok.clear(); } else T.lock.add(c.id); }
  else { if (T.lock.size < 2) return w.sendTo(c, { t: 'res', op: 'tr_ok', ok: false, msg: 'Cả hai cần khóa trước.' }); T.ok.add(c.id); }
  if (T.ok.size === 2) return tradeDo(w, T);
  sendTrade(w, T);
}
function tradeDo(w, T) {
  const A = T.a, B = T.b, oa = T.offer.get(A.id), ob = T.offer.get(B.id);
  const pick = (c, o) => o.items.map(id => c.ch.inv.find(x => String(x.id) === String(id)));
  const ia = pick(A, oa), ib = pick(B, ob);
  const fail = msg => { tradeEnd(w, T, msg); };
  if (ia.some(x => !x || x.lock) || ib.some(x => !x || x.lock)) return fail('Đồ trong giao dịch đã thay đổi, giao dịch bị hủy.');
  if (A.ch.gold < oa.gold || B.ch.gold < ob.gold) return fail('Không đủ vàng, giao dịch bị hủy.');
  if (A.ch.inv.length - ia.length + ib.length > R.INV_MAX || B.ch.inv.length - ib.length + ia.length > R.INV_MAX) return fail('Túi đồ không đủ chỗ, giao dịch bị hủy.');
  A.ch.inv = A.ch.inv.filter(x => !ia.includes(x)); B.ch.inv = B.ch.inv.filter(x => !ib.includes(x));
  A.ch.inv.push(...ib); B.ch.inv.push(...ia);
  A.ch.gold += ob.gold - oa.gold; B.ch.gold += oa.gold - ob.gold;
  w.sql.exec('INSERT INTO trade_log(at,srv,a,b,data) VALUES(?,?,?,?,?)', Date.now(), A.srv, A.uid, B.uid, JSON.stringify({ a: { items: ia.map(x => x.id), gold: oa.gold }, b: { items: ib.map(x => x.id), gold: ob.gold } }));
  // ghi ngay để không mất đồ nếu máy chủ khởi động lại
  for (const c of [A, B]) { c.bagDirty = true; c.dirty = true; w.writeChar(c); w.sendMe(c); }
  tradeEnd(w, T, 'Giao dịch thành công!', true);
}
function tradeEnd(w, T, msg, ok) {
  w.trades.delete(T.id);
  for (const c of [T.a, T.b]) { c.trade = 0; w.sendTo(c, { t: 'trade_end', ok: ok ? 1 : 0, msg }); }
}
export function tradeCancel(w, c, msg) { const T = tradeOf(w, c); if (T) tradeEnd(w, T, msg || 'Giao dịch đã hủy.'); }
