// Trang quản trị Hiệp Sĩ Nét Chì. Không chứa bí mật: mọi quyền do máy chủ kiểm tra (/api/admin/*).
// Mọi chữ hiển thị đi qua textContent để không chạy được mã lạ từ dữ liệu người chơi.
(() => {
'use strict';
const root = document.getElementById('root');
const CLS = { sword: 'Kiếm Sĩ', archer: 'Cung Thủ', mage: 'Pháp Sư', fighter: 'Võ Sĩ' };
const SLOT = { hat: 'Mũ', armor: 'Áo', cape: 'Áo choàng', weapon: 'Vũ khí', boots: 'Giày', gloves: 'Găng', neck: 'Dây chuyền', wing: 'Cánh' };
const RAR = ['Thường', 'Hiếm', 'Sử Thi', 'Huyền Thoại'];
const MAPS = ['Làng Hiệp Sĩ', 'Đồng Bằng Khởi Nguyên', 'Rừng Tuyết Phong', 'Núi Lửa Hắc Ám'];
const ROLE_N = { owner: 'Chủ', gm: 'GM hỗ trợ', viewer: 'Chỉ xem' };
const KIND_N = { drop: 'Rơi đồ hiếm', forge: 'Rèn cao', cheat: 'Nghi gian lận', ban: 'Khóa tài khoản' };
const ACT_N = { login: 'Đăng nhập', login_fail: 'Đăng nhập sai', otp_fail: 'Sai mã 2 lớp', setup_fail: 'Sai mã kích hoạt', setup_2fa: 'Bật mã 2 lớp', denied: 'Bị từ chối quyền',
  char_edit: 'Sửa nhân vật', item_add: 'Tặng đồ', item_del: 'Xóa đồ', ban: 'Khóa tài khoản', unban: 'Mở khóa', mute: 'Cấm chat', kick: 'Đá khỏi game', reset_pw: 'Đặt lại mật khẩu',
  restore: 'Khôi phục nhân vật', announce: 'Thông báo', maint: 'Bảo trì', event: 'Bật sự kiện', event_stop: 'Tắt sự kiện', servers_set: 'Sửa máy chủ', app_cfg: 'Cấu hình ứng dụng',
  tune_set: 'Chỉnh cân bằng', tune_reset: 'Khôi phục cân bằng', admin_add: 'Thêm quản trị', admin_role: 'Đổi quyền', admin_del: 'Xóa quản trị', admin_reset2fa: 'Đặt lại mã 2 lớp' };
let ME = null, TAB = 'overview';
// biểu tượng nét (vẽ bằng SVG, không tải gì từ ngoài)
const IC = {
  chart: 'M4 20V10M10 20V4M16 20v-7M22 20H2', user: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c0-4 4-6 8-6s8 2 8 6', wifi: 'M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01M2 9a15 15 0 0 1 20 0',
  tool: 'M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.5 2.5-2.8-.7-.7-2.8z', scale: 'M12 3v18M5 7h14M5 7l-3 7a4 4 0 0 0 6 0zM19 7l-3 7a4 4 0 0 0 6 0zM8 21h8',
  scroll: 'M8 3h11a2 2 0 0 1 2 2v2h-4M8 3a2 2 0 0 0-2 2v12a2 2 0 0 1-2 2h11a2 2 0 0 0 2-2V7M9 9h5M9 13h5', shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6zM9 12l2 2 4-4',
  lock: 'M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4', bell: 'M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4', party: 'M4 20l4-12 8 8zM14 4l1 2M19 5l-2 2M20 10l-2 0M10 3l.5 2',
  server: 'M4 4h16v6H4zM4 14h16v6H4zM8 7h.01M8 17h.01', phone: 'M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM11 18h2',
  key: 'M15 7a4 4 0 1 1-3.5 6L4 20.5 2.5 19 3 17l2 .5L6 16l-.5-2 2-.5L10 11A4 4 0 0 1 15 7z', out: 'M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11', search: 'M11 18a7 7 0 1 1 0-14 7 7 0 0 1 0 14zM21 21l-5-5',
  sword: 'M14.5 3H21v6.5L9 21.5 2.5 15zM5 13l6 6M3 21l3-3', star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z', alert: 'M12 3l10 18H2zM12 10v5M12 18h.01',
  users: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21c0-4 3-6 7-6s7 2 7 6M17 3.5a4 4 0 0 1 0 7.5M22 21c0-3-1.5-5-4-5.6', plus: 'M12 5v14M5 12h14', clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2',
  gem: 'M6 3h12l4 6-10 12L2 9zM2 9h20M12 21L8 9l4-6 4 6z', gift: 'M3 9h18v4H3zM5 13h14v8H5zM12 9v12M12 9c-2-4-6-4-6-1.5S9 9 12 9zM12 9c2-4 6-4 6-1.5S15 9 12 9z', trash: 'M4 7h16M9 7V4h6v3M6 7l1 14h10l1-14', box: 'M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10', ban: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM5.6 5.6l12.8 12.8', box: 'M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10'
};
function icon(n) { const NS = 'http://www.w3.org/2000/svg', s = document.createElementNS(NS, 'svg'); s.setAttribute('viewBox', '0 0 24 24'); s.setAttribute('class', 'i'); const p = document.createElementNS(NS, 'path'); p.setAttribute('d', IC[n] || IC.star); s.append(p); return s; }
const badge = (n, c) => { const b = document.createElement('span'); b.className = 'badge ' + (c || 'c-sun'); b.append(icon(n)); return b; };
function logoEl(sm) {
  const line = (cls, t) => { const d = document.createElement('span'); d.className = cls; const o = document.createElement('span'); o.className = 'o'; o.textContent = t; const f = document.createElement('span'); f.className = 'f'; f.textContent = t; d.append(o, f); return d; };
  const l = document.createElement('div'); l.className = 'logo' + (sm ? ' sm' : ''); l.append(line('l1', 'Hiệp Sĩ'), line('l2', 'Nét Chì'));
  const r = document.createElement('div'); r.className = 'ribbon'; r.textContent = 'KHU QUẢN TRỊ'; l.append(r); return l;
}

/* ---------- tiện ích ---------- */
function h(tag, attrs, ...kids) {
  const e = document.createElement(tag);
  for (const k in attrs || {}) {
    const v = attrs[k]; if (v == null || v === false) continue;
    if (k === 'class') e.className = v; else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else if (k === 'value') e.value = v; else e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of kids.flat()) if (c != null && c !== false) e.append(c instanceof Node ? c : document.createTextNode(String(c)));
  return e;
}
const fmt = n => (+n || 0).toLocaleString('vi-VN');
const dt = t => t ? new Date(+t).toLocaleString('vi-VN', { hour12: false, day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—';
const ago = t => { if (!t) return '—'; const s = (Date.now() - t) / 1000; return s < 60 ? 'vừa xong' : s < 3600 ? Math.floor(s / 60) + ' phút trước' : s < 86400 ? Math.floor(s / 3600) + ' giờ trước' : Math.floor(s / 86400) + ' ngày trước'; };
const can = r => ME && { viewer: 1, gm: 2, owner: 3 }[ME.role] >= { viewer: 1, gm: 2, owner: 3 }[r];
function toast(msg, bad) { const t = h('div', { class: 'toast' + (bad ? ' bad' : '') }, msg); document.body.append(t); setTimeout(() => t.remove(), 3200); }
async function api(act, body) {
  const r = await fetch('/api/admin/' + act, { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json', 'X-HSNC-Admin': '1' }, body: JSON.stringify(body || {}) });
  let j = {}; try { j = await r.json(); } catch (e) {}
  if (r.status === 401 && j.error === 'auth') { const was = ME; ME = null; showLogin(was ? 'Phiên quản trị đã hết hạn, hãy đăng nhập lại.' : ''); throw new Error('auth'); }
  if (!r.ok) { const e = new Error(j.error || 'Lỗi ' + r.status); e.status = r.status; e.j = j; throw e; }
  return j;
}
async function run(act, body, okMsg) { try { const r = await api(act, body); if (okMsg) toast(okMsg); return r; } catch (e) { if (e.message !== 'auth') toast(e.message, true); return null; } }
function modal(title, body, actions) {
  return new Promise(res => {
    const m = h('div', { class: 'modal' }, h('div', { class: 'card' }, h('h2', null, title), body, h('div', { class: 'row', style: 'justify-content:flex-end' },
      h('button', { class: 'btn sky', onclick: () => { m.remove(); res(null); } }, 'Hủy'),
      ...actions.map(a => h('button', { class: 'btn ' + (a.cls || ''), onclick: () => { const v = a.get ? a.get() : true; m.remove(); res(v); } }, a.t)))));
    document.body.append(m);
    const f = m.querySelector('input,select,textarea'); if (f) f.focus();
  });
}
const confirmBox = (title, text, t, cls) => modal(title, h('p', null, text), [{ t: t || 'Đồng ý', cls: cls || 'red' }]);
function showSecret(title, text, secret) { return modal(title, h('div', { class: 'grid' }, h('p', null, text), h('div', { class: 'secret mono' }, secret), h('p', { class: 'note' }, 'Chỉ hiện một lần. Hãy chép lại ngay.')), [{ t: 'Đã chép', cls: 'green' }]); }
const card = (title, ...kids) => { let ic = null, c = null; if (Array.isArray(title)) { [ic, c, title] = title; } return h('div', { class: 'card' }, title ? h('h2', null, ic ? badge(ic, c) : null, title) : null, ...kids); };
const field = (label, input) => h('label', null, label, input);
const inp = (o) => h('input', o);

/* ---------- đăng nhập 2 lớp ---------- */
function showLogin(msg) {
  root.replaceChildren(); document.body.classList.remove('in');
  const err = h('div', { class: 'err' }, msg || '');
  const box = h('div', { class: 'card' });
  root.append(h('div', { class: 'login' }, logoEl(), box));
  const u = inp({ autocomplete: 'username', maxlength: 32 }), p = inp({ type: 'password', autocomplete: 'current-password', maxlength: 100 });
  const go = h('button', { class: 'btn' }, 'Tiếp tục');
  go.classList.add('big');
  box.append(h('div', { class: 'lock' }, badge('lock', 'c-red')), h('div', { class: 'steps' }, h('span', { class: 'on' }), h('span'), h('span')), h('h2', null, 'Đăng nhập quản trị'), field('Tài khoản game', u), field('Mật khẩu', p), err, go,
    h('p', { class: 'note' }, 'Chỉ tài khoản được cấp quyền mới vào được. Cần thêm mã 2 lớp trên điện thoại (Google Authenticator, Microsoft Authenticator…). Sai nhiều lần sẽ bị khóa 15 phút.'));
  const submit = async () => {
    err.textContent = ''; go.disabled = true;
    try { const r = await api('login', { user: u.value, pass: p.value }); p.value = ''; r.step === 'setup' ? stepSetup(box, r.pre) : stepOtp(box, r.pre); }
    catch (e) { err.textContent = e.message; } finally { go.disabled = false; }
  };
  go.onclick = submit; p.onkeydown = e => { if (e.key === 'Enter') submit(); }; u.onkeydown = e => { if (e.key === 'Enter') p.focus(); };
  u.focus();
}
function otpInput(onDone) {
  const o = inp({ class: 'otp', inputmode: 'numeric', autocomplete: 'one-time-code', maxlength: 6, placeholder: '••••••' });
  o.oninput = () => { o.value = o.value.replace(/\D/g, '').slice(0, 6); if (o.value.length === 6) onDone(o.value); };
  return o;
}
function stepOtp(box, pre) {
  box.replaceChildren();
  const err = h('div', { class: 'err' });
  const send = async v => { err.textContent = ''; try { await api('otp', { pre, otp: v }); start(); } catch (e) { err.textContent = e.message; o.value = ''; if (e.status === 401 && /hết hạn/.test(e.message)) setTimeout(() => showLogin(e.message), 1200); } };
  const o = otpInput(send);
  box.append(h('div', { class: 'lock' }, badge('key', 'c-sun')), h('div', { class: 'steps' }, h('span', { class: 'on' }), h('span', { class: 'on' }), h('span')), h('h2', null, 'Mã 2 lớp'), h('p', { class: 'note' }, 'Mở ứng dụng xác thực trên điện thoại, nhập mã 6 số của "Hiệp Sĩ Nét Chì".'), o, err,
    h('button', { class: 'btn sky', onclick: () => showLogin() }, 'Quay lại'));
  o.focus();
}
function stepSetup(box, pre) {
  box.replaceChildren();
  const err = h('div', { class: 'err' }), code = inp({ placeholder: 'XXXXX-XXXXX-XXXXX-XXXXX', maxlength: 32, autocomplete: 'off', class: 'mono' });
  const go = h('button', { class: 'btn' }, 'Kiểm tra mã');
  box.append(h('div', { class: 'lock' }, badge('shield', 'c-mint')), h('div', { class: 'steps' }, h('span', { class: 'on' }), h('span', { class: 'on' }), h('span')), h('h2', null, 'Bật mã 2 lớp (lần đầu)'), h('p', { class: 'note' }, 'Nhập mã kích hoạt dùng một lần. Chủ game dùng mã gốc được gửi riêng; GM dùng mã mời do chủ tạo (hết hạn sau 48 giờ).'),
    field('Mã kích hoạt', code), err, go);
  go.onclick = async () => {
    err.textContent = ''; go.disabled = true;
    try {
      const r = await api('setup', { pre, code: code.value.trim().toUpperCase() });
      box.replaceChildren();
      const qr = qrcode(0, 'M'); qr.addData(r.uri); qr.make();
      const err2 = h('div', { class: 'err' });
      const o = otpInput(async v => { err2.textContent = ''; try { await api('setup_ok', { pre, otp: v }); toast('Đã bật mã 2 lớp.'); start(); } catch (e) { err2.textContent = e.message; o.value = ''; } });
      box.append(h('div', { class: 'lock' }, badge('phone', 'c-sky')), h('div', { class: 'steps' }, h('span', { class: 'on' }), h('span', { class: 'on' }), h('span', { class: 'on' })), h('h2', null, 'Quét mã bằng điện thoại'),
        h('p', { class: 'note' }, '1. Cài Google Authenticator hoặc Microsoft Authenticator. 2. Bấm "+" → Quét mã QR. 3. Nhập mã 6 số hiện ra để xác nhận.'),
        h('div', { class: 'qr' }, h('img', { src: qr.createDataURL(5, 2), alt: 'Mã QR' })),
        h('p', { class: 'note' }, 'Không quét được? Nhập khóa này bằng tay:'), h('div', { class: 'secret mono', style: 'font-size:15px' }, r.secret.replace(/(.{4})/g, '$1 ').trim()),
        o, err2);
      o.focus();
    } catch (e) { err.textContent = e.message; } finally { go.disabled = false; }
  };
  code.focus();
}

/* ---------- khung chính ---------- */
const TABS = [['overview', 'chart', 'Tổng quan', 'c-sun'], ['players', 'user', 'Người chơi', 'c-sky'], ['online', 'wifi', 'Đang online', 'c-mint'], ['ops', 'tool', 'Vận hành', 'c-red'], ['items', 'gift', 'Kho vật phẩm', 'c-sun'], ['tune', 'scale', 'Cân bằng', 'c-vio'], ['logs', 'scroll', 'Nhật ký', 'c-ink'], ['admins', 'shield', 'Quản trị viên', 'c-red']];
async function start() { try { ME = await api('me'); } catch (e) { if (e.message !== 'auth') showLogin(); return; } layout(); }
let mainEl;
function layout() {
  root.replaceChildren(); document.body.classList.add('in');
  const logout = async () => { if (!await confirmBox('Đăng xuất', 'Thoát khỏi khu quản trị?', 'Đăng xuất')) return; await run('logout'); ME = null; showLogin('Đã đăng xuất.'); };
  const side = h('nav', { class: 'side' }, logoEl(true));
  for (const [k, ic, n, c] of TABS) side.append(h('button', { class: 'nav' + (k === TAB ? ' on' : ''), onclick: () => { TAB = k; layout(); } }, badge(ic, c), n));
  side.append(h('div', { class: 'who' }, badge('user', 'c-sky'), h('div', null, h('b', null, ME.user), h('small', null, ME.roleName)),
    h('button', { class: 'btn sm sky', title: 'Đăng xuất', onclick: () => logout() }, icon('out'))));
  setTimeout(() => { const on = side.querySelector('.nav.on'); if (on && side.scrollWidth > side.clientWidth) side.scrollLeft = on.offsetLeft - (side.clientWidth - on.offsetWidth) / 2; }, 0);
  mainEl = h('main');
  root.append(h('div', { class: 'app' }, side, mainEl));
  const t = TABS.find(x => x[0] === TAB);
  mainEl.append(h('div', { class: 'top' }, h('h1', null, badge(t[1], t[3]), t[2]), h('div', { class: 'sp' }),
    h('div', { class: 'topr' }, h('span', { class: 'chip' }, icon('user'), ME.user + ' · ' + ME.roleName), h('button', { class: 'btn sm red mob', onclick: logout }, icon('out'), 'Đăng xuất'))));
  const body = h('div', { class: 'grid' }); mainEl.append(body);
  VIEWS[TAB](body);
}

/* ---------- biểu đồ online 24 giờ ---------- */
function chart(hist) {
  const NS = 'http://www.w3.org/2000/svg', W = 600, H = 150, P = 22;
  const svg = document.createElementNS(NS, 'svg'); svg.setAttribute('viewBox', `0 0 ${W} ${H}`); svg.setAttribute('class', 'chart');
  const mk = (t, a) => { const e = document.createElementNS(NS, t); for (const k in a) e.setAttribute(k, a[k]); svg.append(e); return e; };
  if (!hist.length) { const t = mk('text', { x: W / 2, y: H / 2, 'text-anchor': 'middle', fill: '#5a6b8c', 'font-weight': 800 }); t.textContent = 'Chưa có dữ liệu (ghi mỗi 5 phút)'; return svg; }
  const t0 = Date.now() - 86400e3, mx = Math.max(4, ...hist.map(x => x.n));
  const X = t => P + (t - t0) / 86400e3 * (W - P * 2), Y = v => H - P - v / mx * (H - P * 2);
  for (const v of [0, Math.round(mx / 2), mx]) { mk('line', { x1: P, x2: W - P, y1: Y(v), y2: Y(v), stroke: '#c9d3e6', 'stroke-width': 1 }); const t = mk('text', { x: 2, y: Y(v) + 4, fill: '#5a6b8c', 'font-size': 11, 'font-weight': 800 }); t.textContent = v; }
  const pts = hist.map(x => X(x.at) + ',' + Y(x.n)).join(' ');
  mk('polyline', { points: pts, fill: 'none', stroke: '#4a8dff', 'stroke-width': 3, 'stroke-linejoin': 'round' });
  for (const [k, lab] of [[0, '24 giờ trước'], [1, 'bây giờ']]) { const t = mk('text', { x: k ? W - P : P, y: H - 4, 'text-anchor': k ? 'end' : 'start', fill: '#5a6b8c', 'font-size': 11, 'font-weight': 800 }); t.textContent = lab; }
  return svg;
}
const charName = c => (c.name || '?') + ' · ' + (CLS[c.cls] || c.cls || '') + ' · Cấp ' + (c.lv | 0);
function evRow(e) { return h('tr', null, h('td', null, dt(e.at)), h('td', null, h('span', { class: 'pill ' + (e.kind === 'cheat' || e.kind === 'ban' ? 'off' : e.kind === 'drop' ? 'warn' : 'blue') }, KIND_N[e.kind] || e.kind)), h('td', null, e.name || ''), h('td', null, e.detail || '')); }

/* ---------- các trang ---------- */
const VIEWS = {
  async overview(body) {
    const o = await run('overview'); if (!o) return;
    const tile = (k, v, ic, c, hot) => h('div', { class: 'tile' + (hot ? ' hot' : '') }, badge(ic, c), h('div', null, h('div', { class: 'v' }, v), h('div', { class: 'k' }, k)));
    body.append(h('div', { class: 'tiles' }, tile('Đang online', fmt(o.online), 'wifi', 'c-mint', true), tile('Dùng ứng dụng mới', fmt(o.onlineV2), 'phone', 'c-sky'), tile('Tài khoản', fmt(o.users), 'users', 'c-sun'), tile('Nhân vật', fmt(o.chars), 'sword', 'c-vio'),
      tile('Đăng ký 24 giờ', fmt(o.new24), 'plus', 'c-mint'), tile('Đăng ký 7 ngày', fmt(o.new7), 'plus', 'c-sky'), tile('Chơi trong 24 giờ', fmt(o.active24), 'clock', 'c-sun'), tile('Đang bị khóa', fmt(o.banned), 'ban', 'c-red'), tile('Bản lưu bất thường', fmt(o.anomalies), 'alert', 'c-red')));
    const st = [];
    if (o.maint && o.maint.on) st.push(h('span', { class: 'pill off' }, '🛠️ Đang bảo trì'));
    if (o.cfg.ev) st.push(h('span', { class: 'pill warn' }, '🎉 ' + o.cfg.ev.name + ' đến ' + dt(o.cfg.ev.until)));
    if (o.cfg.ann) st.push(h('span', { class: 'pill blue' }, '📢 ' + o.cfg.ann.text));
    if (st.length) body.append(card(['bell', 'c-sun', 'Đang áp dụng'], h('div', { class: 'row' }, st)));
    body.append(h('div', { class: 'grid g2' },
      card(['chart', 'c-sky', 'Người online 24 giờ qua'], chart(o.hist)),
      card(['server', 'c-ink', 'Máy chủ'], h('table', null, h('tr', null, h('th', null, 'Máy chủ'), h('th', null, 'Trạng thái'), h('th', null, 'Online')),
        o.bySrv.map(s => h('tr', null, h('td', null, s.name), h('td', null, h('span', { class: 'pill ' + (s.open ? 'on' : 'off') }, s.open ? 'Mở' : 'Đóng')), h('td', null, fmt(s.online))))))));
    body.append(h('div', { class: 'grid g2' },
      card(['star', 'c-sun', 'Top 10 cấp cao'], h('div', { class: 'scroll' }, h('table', null, h('tr', null, h('th', null, '#'), h('th', null, 'Nhân vật'), h('th', null, 'Phái'), h('th', null, 'Cấp'), h('th', null, 'Quái')),
        o.top.map((t, i) => h('tr', { class: 'click', onclick: () => openPlayer(t.uid) }, h('td', null, i + 1), h('td', null, t.name), h('td', null, CLS[t.cls] || t.cls), h('td', null, t.lv), h('td', null, fmt(t.kills))))))),
      card(['gem', 'c-vio', 'Sự kiện gần đây'], h('div', { class: 'scroll' }, h('table', null, o.events.length ? o.events.map(evRow) : h('tr', null, h('td', { class: 'empty' }, 'Chưa có.')))))));
  },
  async players(body) {
    const q = inp({ placeholder: 'Tên tài khoản hoặc tên nhân vật…', maxlength: 32 }), res = h('div');
    const search = async () => { const r = await run('players', { q: q.value }); if (!r) return; res.replaceChildren(h('div', { class: 'scroll' }, h('table', null,
      h('tr', null, h('th', null, 'Tài khoản'), h('th', null, 'Nhân vật'), h('th', null, 'Tạo lúc'), h('th', null, 'Lần cuối'), h('th', null, 'Trạng thái')),
      r.list.length ? r.list.map(u => h('tr', { class: 'click', onclick: () => openPlayer(u.id) }, h('td', null, h('b', null, u.username)), h('td', null, u.chars.map(c => h('div', null, 'S' + c.srv + ': ' + charName(c)))),
        h('td', null, dt(u.created)), h('td', null, ago(u.last_login)), h('td', null, u.online ? h('span', { class: 'pill on' }, 'Online') : '', ' ', u.banned ? h('span', { class: 'pill off' }, 'Bị khóa') : '', ' ', u.staff ? h('span', { class: 'pill blue' }, ROLE_N[u.staff]) : '')))
        : h('tr', null, h('td', null, 'Không tìm thấy.'))))); };
    q.onkeydown = e => { if (e.key === 'Enter') search(); };
    body.append(card(['search', 'c-sky', 'Tìm người chơi'], h('div', { class: 'row' }, h('label', { style: 'flex:1' }, 'Tìm', q), h('button', { class: 'btn', onclick: search }, 'Tìm'))), card(null, res));
    search(); q.focus();
  },
  async online(body) {
    const r = await run('online'); if (!r) return;
    body.append(card(['wifi', 'c-mint', 'Đang online: ' + r.list.length], h('div', { class: 'scroll' }, h('table', null,
      h('tr', null, h('th', null, 'Tài khoản'), h('th', null, 'Nhân vật'), h('th', null, 'Máy chủ'), h('th', null, 'Bản đồ'), h('th', null, 'Ứng dụng'), h('th', null, '')),
      r.list.length ? null : h('tr', null, h('td', { class: 'empty', colspan: 6 }, 'Hiện không có ai online.')),
      r.list.map(c => h('tr', null, h('td', null, h('a', { href: '#', onclick: e => { e.preventDefault(); openPlayer(c.uid); } }, c.user)), h('td', null, (c.name || '—') + (c.lv ? ' · Cấp ' + c.lv : ''), c.hidden ? h('span', { class: 'pill warn' }, ' Tàng hình') : ''),
        h('td', null, 'S' + c.srv), h('td', null, (MAPS[c.map] || '—') + (c.khu ? ' · Khu ' + c.khu : '')), h('td', null, c.v2 ? (c.app || 'pc') : 'Bản cũ'),
        h('td', null, can('gm') ? h('button', { class: 'btn sm red', onclick: async () => { if (await confirmBox('Đá khỏi game', 'Mời ' + c.user + ' ra khỏi game?', 'Đá')) { await run('kick', { uid: c.uid }, 'Đã đá.'); layout(); } } }, 'Đá') : '')))))));
  },
  async ops(body) {
    const c = await run('cfg_get'); if (!c) return;
    // thông báo
    const at = h('textarea', { maxlength: 200, placeholder: 'Nội dung thông báo hiện cho mọi người chơi…' }), am = inp({ type: 'number', value: 60, min: 1, max: 10080 });
    body.append(card(['bell', 'c-sun', 'Thông báo toàn máy chủ'], c.ann && c.ann.until > Date.now() ? h('p', null, 'Đang ghim: "' + c.ann.text + '" đến ' + dt(c.ann.until)) : null,
      field('Nội dung', at), h('div', { class: 'row' }, field('Ghim trong (phút)', am),
        h('button', { class: 'btn', disabled: !can('gm'), onclick: async () => { if (!at.value.trim()) return toast('Nhập nội dung.', true); await run('announce', { text: at.value, minutes: +am.value }, 'Đã gửi thông báo.'); layout(); } }, 'Gửi ngay'),
        c.ann ? h('button', { class: 'btn sky', disabled: !can('gm'), onclick: async () => { await run('announce', { text: '' }, 'Đã gỡ thông báo.'); layout(); } }, 'Gỡ ghim') : null)));
    // sự kiện
    const en = inp({ value: 'Sự kiện cuối tuần', maxlength: 60 }), ee = inp({ type: 'number', step: .5, min: 1, max: 10, value: 2 }), eg = inp({ type: 'number', step: .5, min: 1, max: 10, value: 1 }), ed = inp({ type: 'number', step: .25, min: 1, max: 5, value: 1 }), eh = inp({ type: 'number', min: .25, max: 336, step: .25, value: 24 });
    const on = c.event && c.event.until > Date.now();
    body.append(card(['party', 'c-vio', 'Sự kiện nhân thưởng'], on ? h('p', null, h('span', { class: 'pill warn' }, 'Đang chạy'), ' ' + c.event.name + ': x' + c.event.exp + ' kinh nghiệm, x' + c.event.gold + ' vàng, x' + c.event.drop + ' rơi đồ — đến ' + dt(c.event.until)) : h('p', { class: 'note' }, 'Không có sự kiện nào đang chạy.'),
      h('div', { class: 'row' }, field('Tên', en), field('x Kinh nghiệm', ee), field('x Vàng', eg), field('x Rơi đồ', ed), field('Kéo dài (giờ)', eh)),
      h('div', { class: 'row', style: 'margin-top:8px' }, h('button', { class: 'btn green', disabled: !can('owner'), onclick: async () => { await run('event', { name: en.value, exp: +ee.value, gold: +eg.value, drop: +ed.value, hours: +eh.value }, 'Đã bật sự kiện.'); layout(); } }, 'Bật sự kiện'),
        on ? h('button', { class: 'btn red', disabled: !can('owner'), onclick: async () => { await run('event_stop', {}, 'Đã tắt sự kiện.'); layout(); } }, 'Tắt ngay') : null)));
    // bảo trì
    const mm = inp({ value: (c.maint && c.maint.msg) || 'Máy chủ đang bảo trì, vui lòng quay lại sau ít phút.', maxlength: 200 });
    body.append(card(['tool', 'c-red', 'Bảo trì'], h('p', null, 'Trạng thái: ', h('span', { class: 'pill ' + (c.maint.on ? 'off' : 'on') }, c.maint.on ? 'Đang bảo trì — chỉ quản trị vào được' : 'Bình thường')),
      field('Lời nhắn cho người chơi', mm),
      h('div', { class: 'row', style: 'margin-top:8px' }, c.maint.on
        ? h('button', { class: 'btn green', disabled: !can('owner'), onclick: async () => { await run('maint', { on: false }, 'Đã mở lại máy chủ.'); layout(); } }, 'Kết thúc bảo trì')
        : h('button', { class: 'btn red', disabled: !can('owner'), onclick: async () => { if (await confirmBox('Bật bảo trì', 'Mọi người chơi (trừ quản trị) sẽ bị đưa ra ngoài và không vào được cho tới khi tắt.', 'Bật bảo trì')) { await run('maint', { on: true, msg: mm.value }, 'Đã bật bảo trì.'); layout(); } } }, 'Bật bảo trì'))));
    // máy chủ
    const list = c.servers.map(s => ({ ...s })), tb = h('tbody');
    const draw = () => tb.replaceChildren(...list.map((s, i) => h('tr', null,
      h('td', null, inp({ type: 'number', min: 1, max: 99, value: s.id, style: 'width:70px', oninput: e => s.id = +e.target.value })),
      h('td', null, inp({ value: s.name, maxlength: 24, oninput: e => s.name = e.target.value })),
      h('td', null, inp({ value: s.tag || '', maxlength: 12, oninput: e => s.tag = e.target.value })),
      h('td', null, h('select', { onchange: e => s.open = e.target.value === '1' }, h('option', { value: 1, selected: s.open !== false }, 'Mở'), h('option', { value: 0, selected: s.open === false }, 'Đóng'))),
      h('td', null, list.length > 1 ? h('button', { class: 'btn sm sky', onclick: () => { list.splice(i, 1); draw(); } }, 'Bỏ') : ''))));
    draw();
    body.append(card(['server', 'c-ink', 'Máy chủ'], h('p', { class: 'note' }, 'Máy chủ đóng: người chơi không thấy và không vào được (quản trị vẫn vào được). Bỏ một máy chủ không xóa nhân vật trên đó.'),
      h('div', { class: 'scroll' }, h('table', null, h('thead', null, h('tr', null, h('th', null, 'Số'), h('th', null, 'Tên'), h('th', null, 'Nhãn'), h('th', null, 'Trạng thái'), h('th', null, ''))), tb)),
      h('div', { class: 'row', style: 'margin-top:8px' }, h('button', { class: 'btn sky', disabled: !can('owner'), onclick: () => { list.push({ id: Math.max(...list.map(x => x.id)) + 1, name: 'Server ' + (list.length + 1), tag: 'Mới', open: true }); draw(); } }, '+ Thêm máy chủ'),
        h('button', { class: 'btn green', disabled: !can('owner'), onclick: async () => { await run('servers_set', { list }, 'Đã lưu danh sách máy chủ.'); layout(); } }, 'Lưu'))));
    // ứng dụng
    const km = inp({ type: 'number', min: 1, max: 100, value: c.khuMax || 15, style: 'width:110px' }), ma = inp({ value: c.min_app || '', placeholder: 'vd 2.1.0', maxlength: 16 }), v1 = h('select', null, h('option', { value: 'on', selected: c.v1 !== 'off' }, 'Còn cho vào'), h('option', { value: 'off', selected: c.v1 === 'off' }, 'Tắt hẳn'));
    body.append(card(['phone', 'c-sky', 'Ứng dụng'], h('div', { class: 'row' }, field('Phiên bản tối thiểu (cũ hơn bị buộc cập nhật)', ma), field('Bản cũ (web / ứng dụng vỏ)', v1),
      h('button', { class: 'btn green', disabled: !can('owner'), onclick: async () => { if (v1.value === 'off' && c.v1 !== 'off' && !await confirmBox('Tắt bản cũ', 'Người đang dùng bản web hoặc ứng dụng vỏ cũ sẽ bị đưa ra và phải tải ứng dụng mới.', 'Tắt bản cũ')) return; await run('app_cfg', { min_app: ma.value, v1: v1.value }, 'Đã lưu.'); layout(); } }, 'Lưu'))));
    body.append(card(['users', 'c-mint', 'Khu trong bản đồ'], h('p', { class: 'note' }, 'Mỗi bản đồ chia nhiều khu như Ngọc Rồng Online, mỗi khu có quái và đồ rơi riêng. Khu đầy thì người mới tự vào khu khác. Người chơi đổi khu bằng nút Khu dưới tên bản đồ.'),
      h('div', { class: 'row' }, field('Số người tối đa mỗi khu', km), h('button', { class: 'btn green', disabled: !can('owner'), onclick: async () => { await run('app_cfg', { khuMax: +km.value }, 'Đã lưu. Áp dụng cho lượt vào khu tiếp theo.'); layout(); } }, 'Lưu'))));
  },
  async tune(body) {
    const r = await run('tune_get'); if (!r) return;
    const t = r.tune, ro = !can('owner');
    const num = (v, o) => inp({ type: 'number', value: v, step: o.step || .1, min: o.min, max: o.max, disabled: ro });
    const G = { exp: num(t.exp, { min: .1, max: 20 }), gold: num(t.gold, { min: .1, max: 20 }), drop: num(t.drop, { min: .1, max: 10 }), potPrice: num(t.potPrice, { step: 1, min: 1, max: 100000 }),
      shopMul: num(t.shopMul, { min: .1, max: 20 }), forgeBonus: num(t.forgeBonus, { step: 1, min: -50, max: 50 }), eliteChance: num(t.eliteChance, { step: .01, min: 0, max: .5 }), kiMul: num(t.kiMul ?? 1, { min: 0, max: 5 }), ptMul: num(t.ptMul ?? 1, { min: .1, max: 5 }), wingChance: num(t.wingChance ?? .015, { step: .005, min: 0, max: 1 }) };
    body.append(card(['scale', 'c-vio', 'Toàn game'], h('p', { class: 'note' }, 'Áp dụng ngay trên máy chủ, không cần ra bản ứng dụng mới. 1 = như gốc.' + (ro ? ' (Chỉ chủ mới sửa được.)' : '')),
      h('div', { class: 'row' }, field('x Kinh nghiệm', G.exp), field('x Vàng', G.gold), field('x Tỉ lệ rơi đồ', G.drop), field('Giá bình máu (vàng)', G.potPrice)),
      h('div', { class: 'row', style: 'margin-top:8px' }, field('x Giá đồ cửa hàng', G.shopMul), field('Cộng tỉ lệ rèn (%)', G.forgeBonus), field('Tỉ lệ quái tinh anh (0–0,5)', G.eliteChance)),
      h('div', { class: 'row', style: 'margin-top:8px' }, field('x KI kỹ năng tốn (0 = không tốn)', G.kiMul), field('x Sức mạnh mỗi điểm tiềm năng', G.ptMul), field('Tỉ lệ rơi cánh mỗi lần hạ trùm (0,015 = 1,5%)', G.wingChance))));
    const M = {}, tb = h('tbody');
    for (const [k, m] of Object.entries(r.mons)) {
      const o = t.mon[k] || {}; M[k] = {};
      const cells = ['hp', 'atk', 'def', 'exp', 'gold', 'drop'].map(f => { const i = num(o[f] || 1, { min: .1, max: 20 }); i.style.width = '76px'; M[k][f] = i; return h('td', null, i); });
      tb.append(h('tr', null, h('td', null, h('b', null, m.n), m.boss ? h('span', { class: 'pill warn' }, ' Trùm') : '', h('div', { class: 'note' }, (m.boss ? 'Máu ' + m.hp + ' · Công ' + m.atk + ' · KN ' + m.exp : 'Máu, công, KN theo cấp quái') + ' · Rơi ' + Math.round(m.drop * 100) + '%')), cells));
    }
    body.append(card(['sword', 'c-red', 'Từng loại quái (hệ số nhân)'], h('div', { class: 'scroll' }, h('table', null, h('thead', null, h('tr', null, h('th', null, 'Quái'), ...['Máu', 'Công', 'Thủ', 'Kinh nghiệm', 'Vàng', 'Rơi đồ'].map(x => h('th', null, x)))), tb))));
    if (!ro) body.append(h('div', { class: 'row' },
      h('button', { class: 'btn green', onclick: async () => {
        const tune = Object.fromEntries(Object.entries(G).map(([k, i]) => [k, +i.value])); tune.mon = {};
        for (const k in M) { const o = {}; for (const f in M[k]) if (+M[k][f].value !== 1) o[f] = +M[k][f].value; if (Object.keys(o).length) tune.mon[k] = o; }
        if (await confirmBox('Lưu cân bằng', 'Áp dụng ngay cho mọi người chơi. Quái đang sống giữ chỉ số cũ tới khi hồi sinh.', 'Lưu', 'green')) { await run('tune_set', { tune }, 'Đã lưu cân bằng.'); layout(); }
      } }, 'Lưu thay đổi'),
      h('button', { class: 'btn sky', onclick: async () => { if (await confirmBox('Khôi phục mặc định', 'Đưa mọi hệ số về như luật gốc?', 'Khôi phục')) { await run('tune_reset', {}, 'Đã khôi phục.'); layout(); } } }, 'Khôi phục mặc định')));
  },
  async logs(body) {
    const KINDS = [['admin', 'Thao tác quản trị'], ['game', 'Sự kiện game'], ['chat', 'Trò chuyện'], ['trade', 'Giao dịch'], ['anomaly', 'Bản lưu bất thường']];
    let kind = VIEWS._lk || 'admin'; const q = inp({ placeholder: 'Lọc…', maxlength: 40 }), tb = h('div'), more = h('button', { class: 'btn sky' }, 'Xem thêm'); let before = 0;
    const sub = h('div', { class: 'sub' }, KINDS.map(([k, n]) => h('button', { class: 'btn sm ' + (k === kind ? '' : 'sky'), onclick: () => { VIEWS._lk = k; layout(); } }, n)));
    const rowOf = x => kind === 'admin' ? h('tr', null, h('td', null, dt(x.at)), h('td', null, x.who || '—'), h('td', null, h('span', { class: 'pill ' + (/fail|denied/.test(x.action) ? 'off' : 'blue') }, ACT_N[x.action] || x.action), x.src === 'game' ? h('span', { class: 'pill warn' }, ' trong game') : ''), h('td', { class: 'mono', style: 'font-size:12px' }, x.detail), h('td', null, x.ip))
      : kind === 'game' ? evRow(x)
      : kind === 'chat' ? h('tr', null, h('td', null, dt(x.at)), h('td', null, 'S' + x.srv), h('td', null, h('a', { href: '#', onclick: e => { e.preventDefault(); openPlayer(x.uid); } }, x.name)), h('td', null, x.scope === 'all' ? h('span', { class: 'pill warn' }, 'Thế giới') : MAPS[+String(x.scope).split(':')[1]] || ''), h('td', null, x.text))
      : kind === 'trade' ? h('tr', null, h('td', null, dt(x.at)), h('td', null, 'S' + x.srv), h('td', null, h('a', { href: '#', onclick: e => { e.preventDefault(); openPlayer(x.a); } }, '#' + x.a), ' ↔ ', h('a', { href: '#', onclick: e => { e.preventDefault(); openPlayer(x.b); } }, '#' + x.b)), h('td', { class: 'mono', style: 'font-size:12px' }, x.data))
      : h('tr', { class: 'click', onclick: () => openPlayer(x.uid) }, h('td', null, dt(x.at)), h('td', null, x.name || '#' + x.uid), h('td', null, 'S' + x.srv), h('td', null, x.detail));
    const table = h('table'); tb.append(h('div', { class: 'scroll' }, table));
    const load = async (reset) => { if (reset) { table.replaceChildren(); before = 0; } const r = await run('logs', { kind, q: q.value, before }); if (!r) return; for (const x of r.list) table.append(rowOf(x)); before = r.list.length ? r.list[r.list.length - 1].id : before; more.disabled = r.list.length < 100 || kind === 'anomaly'; if (!table.children.length) table.append(h('tr', null, h('td', null, 'Không có dữ liệu.'))); };
    q.onkeydown = e => { if (e.key === 'Enter') load(true); };
    more.onclick = () => load(false);
    body.append(card(null, sub, h('div', { class: 'row' }, h('label', { style: 'flex:1' }, 'Lọc theo tên / nội dung', q), h('button', { class: 'btn', onclick: () => load(true) }, 'Lọc')), tb, h('div', { style: 'margin-top:10px' }, more)));
    load(true);
  },
  async admins(body) {
    const r = await run('admins'); if (!r) return;
    body.append(card(['shield', 'c-mint', 'Vai trò'], h('div', { class: 'kv' }, h('span', null, 'Chủ'), h('span', null, 'Toàn quyền: sửa nhân vật, tặng đồ, khôi phục, đặt lại mật khẩu, bảo trì, sự kiện, cân bằng, máy chủ, phân quyền.'),
      h('span', null, 'GM hỗ trợ'), h('span', null, 'Xem mọi thứ; khóa/mở khóa, cấm chat, đá người chơi, thông báo; lệnh GM trong game (dịch chuyển, tàng hình, gọi quái thử, hồi máu). Không đụng tới vàng/đồ của ai.'),
      h('span', null, 'Chỉ xem'), h('span', null, 'Xem tổng quan, người chơi, nhật ký. Không thay đổi được gì.'))));
    body.append(card(['users', 'c-sky', 'Danh sách quản trị'], h('div', { class: 'scroll' }, h('table', null, h('tr', null, h('th', null, 'Tài khoản'), h('th', null, 'Vai trò'), h('th', null, 'Mã 2 lớp'), h('th', null, 'Lần cuối'), h('th', null, '')),
      r.list.map(a => h('tr', null, h('td', null, h('b', null, a.user)), h('td', null, can('owner') && a.uid !== ME.uid
        ? h('select', { onchange: async e => { await run('admin_role', { uid: a.uid, role: e.target.value }, 'Đã đổi quyền.'); layout(); } }, Object.entries(ROLE_N).map(([k, n]) => h('option', { value: k, selected: k === a.role }, n)))
        : ROLE_N[a.role]),
        h('td', null, h('span', { class: 'pill ' + (a.totp_on ? 'on' : 'warn') }, a.totp_on ? 'Đã bật' : 'Chờ kích hoạt')), h('td', null, ago(a.last)),
        h('td', null, can('owner') && a.uid !== ME.uid ? h('div', { class: 'row' },
          h('button', { class: 'btn sm sky', onclick: async () => { if (!await confirmBox('Đặt lại mã 2 lớp', 'Tài khoản ' + a.user + ' phải kích hoạt lại bằng mã mời mới.', 'Đặt lại')) return; const x = await run('admin_reset2fa', { uid: a.uid }); if (x) { await showSecret('Mã mời mới', 'Gửi riêng mã này cho ' + a.user + ' (hết hạn sau 48 giờ):', x.code); layout(); } } }, 'Đặt lại 2 lớp'),
          h('button', { class: 'btn sm red', onclick: async () => { if (await confirmBox('Xóa quyền', 'Bỏ quyền quản trị của ' + a.user + '?', 'Xóa quyền')) { await run('admin_del', { uid: a.uid }, 'Đã xóa quyền.'); layout(); } } }, 'Xóa')) : '')))))));
    if (can('owner')) {
      const u = inp({ placeholder: 'Tên tài khoản trong game', maxlength: 32 }), role = h('select', null, h('option', { value: 'gm' }, 'GM hỗ trợ'), h('option', { value: 'viewer' }, 'Chỉ xem'), h('option', { value: 'owner' }, 'Chủ'));
      body.append(card(['plus', 'c-sun', 'Thêm quản trị'], h('p', { class: 'note' }, 'Người đó cần có tài khoản game trước. Sau khi thêm, gửi riêng mã mời cho họ để bật mã 2 lớp ở trang này.'),
        h('div', { class: 'row' }, field('Tài khoản', u), field('Vai trò', role), h('button', { class: 'btn green', onclick: async () => { const x = await run('admin_add', { user: u.value, role: role.value }); if (x) { await showSecret('Mã mời cho ' + x.user, 'Gửi riêng mã này cho ' + x.user + '. Họ đăng nhập trang /admin bằng tài khoản game rồi nhập mã (hết hạn sau 48 giờ):', x.code); layout(); } } }, 'Thêm'))));
    }
  }
};

/* ---------- kho vật phẩm: chọn bất kỳ món nào trong game và tặng ---------- */
const GIFT = { to: null, online: false, srv: 1, cart: [], misc: { pots: 0, stones: 0, gold: 0, exp: 0 }, books: {}, lvl: 10, f: { cls: '', slot: '', r: -1 }, cat: null, note: '' };
function giftTo(uid, srv, ch) { GIFT.to = { uid, srv, name: ch.name, cls: ch.cls, lv: ch.lv, free: (GIFT.cat ? GIFT.cat.max.inv : 30) - (ch.inv || []).length }; GIFT.online = false; GIFT.lvl = Math.max(1, ch.lv | 0); GIFT.cart = []; GIFT.books = {}; GIFT.misc = { pots: 0, stones: 0, gold: 0, exp: 0 }; TAB = 'items'; layout(); }
const RCOL = ['#8a93a8', '#2f6fed', '#a54be0', '#e69a00'];
VIEWS.items = async function (body) {
  const G = GIFT, own = can('owner');
  if (!G.cat || G.cat.lvl !== G.lvl) { const c = await run('catalog', { lvl: G.lvl }); if (!c) return; G.cat = c; }
  const C = G.cat, ST = { atk: 'Công', def: 'Thủ', hp: 'Máu', spd: 'Tốc' };
  const stTxt = st => Object.entries(st).map(([k, v]) => ST[k] + ' ' + v).join(' · ');
  const chips = (list, cur, set) => h('div', { class: 'sub' }, list.map(([v, n]) => h('button', { class: 'btn sm ' + (String(v) === String(cur) ? '' : 'sky'), onclick: () => { set(v); layout(); } }, n)));
  // người nhận
  const rc = card(['user', 'c-sky', 'Người nhận']);
  if (G.online) rc.append(h('div', { class: 'row' }, h('span', { class: 'chip' }, icon('users'), 'Mọi người đang online'), field('Máy chủ', h('select', { onchange: e => G.srv = +e.target.value }, (ME.servers || [{ id: 1, name: 'Server 1' }]).map(x => h('option', { value: x.id, selected: x.id === G.srv }, x.name)))),
    h('button', { class: 'btn sm sky', onclick: () => { G.online = false; layout(); } }, 'Chọn một người')));
  else if (G.to) rc.append(h('div', { class: 'row' }, h('span', { class: 'chip' }, icon('sword'), G.to.name + ' · ' + (CLS[G.to.cls] || '') + ' · Cấp ' + G.to.lv + ' · Máy chủ ' + G.to.srv), h('span', { class: 'note' }, 'Túi còn ' + G.to.free + ' ô'),
    h('button', { class: 'btn sm sky', onclick: () => { G.to = null; layout(); } }, 'Đổi người')));
  else {
    const q = inp({ placeholder: 'Tên tài khoản hoặc nhân vật…', maxlength: 32 }), res = h('div', { class: 'row', style: 'margin-top:8px' });
    const find = async () => { const r = await run('players', { q: q.value }); if (!r) return; res.replaceChildren(...r.list.flatMap(u => u.chars.map(c => h('button', { class: 'btn sm sky', onclick: async () => { const p = await run('player', { uid: u.id }); if (!p) return; const ch = p.chars.find(x => x.srv === c.srv); giftTo(u.id, c.srv, ch); } }, u.username + ' → ' + c.name + ' (S' + c.srv + ', cấp ' + c.lv + ')'))), r.list.length ? null : h('span', { class: 'note' }, 'Không tìm thấy.')); };
    q.onkeydown = e => { if (e.key === 'Enter') find(); };
    rc.append(h('div', { class: 'row' }, h('label', { style: 'flex:1' }, 'Tìm người nhận', q), h('button', { class: 'btn', onclick: find }, 'Tìm'), h('button', { class: 'btn sky', onclick: () => { G.online = true; layout(); } }, icon('users'), 'Tặng mọi người đang online')), res);
  }
  body.append(rc);
  // trang bị
  const lv = inp({ type: 'number', min: 1, max: C.max.lv, value: G.lvl, style: 'width:110px' });
  lv.onchange = () => { G.lvl = Math.max(1, Math.min(C.max.lv, +lv.value || 1)); layout(); };
  const list = C.gear.filter(g => (!G.f.cls || g.cls === G.f.cls || !g.cls) && (!G.f.slot || g.slot === G.f.slot) && (G.f.r < 0 || g.r === G.f.r));
  const add = g => { G.cart.push({ cls: g.cls, slot: g.slot, r: g.r, lvl: G.lvl, up: 0, q: 'base', st: { ...g.st }, lock: false, qty: 1, name: g.name, icon: g.icon, base: g.st, max: g.max }); layout(); toast('Đã thêm ' + g.name + ' vào giỏ quà.'); };
  body.append(card(['sword', 'c-vio', 'Trang bị (' + list.length + ' món)'],
    chips([['', 'Mọi phái'], ...Object.entries(C.cls)], G.f.cls, v => G.f.cls = v),
    chips([['', 'Mọi ô'], ...Object.entries(SLOT)], G.f.slot, v => G.f.slot = v),
    chips([[-1, 'Mọi độ hiếm'], ...C.rar.map((r, i) => [i, r.n])], G.f.r, v => G.f.r = +v),
    h('div', { class: 'row', style: 'margin-bottom:10px' }, field('Cấp đồ (chỉ số theo cấp)', lv)),
    h('div', { class: 'cat' }, list.map(g => h('button', { class: 'gi r' + g.r, onclick: () => add(g), title: 'Thêm vào giỏ' },
      h('img', { src: g.icon, alt: '', loading: 'lazy' }), h('b', { style: 'color:' + RCOL[g.r] }, g.name), h('span', { class: 'note' }, C.rar[g.r].n + ' · ' + SLOT[g.slot] + ' · ' + (C.cls[g.cls] || 'Mọi phái')), h('span', null, stTxt(g.st)), h('span', { class: 'plus' }, icon('plus')))))));
  // vật phẩm khác + sách
  const misc = card(['box', 'c-sun', 'Vật phẩm khác']);
  misc.append(h('div', { class: 'cat' }, C.misc.map(m => { const i = inp({ type: 'number', min: 0, value: G.misc[m.k] || 0 }); i.oninput = () => G.misc[m.k] = Math.max(0, +i.value || 0);
    return h('div', { class: 'gi' }, m.icon && m.k !== 'exp' ? h('img', { src: m.icon, alt: '' }) : badge('star', 'c-sky'), h('b', null, m.n), m.k === 'pots' ? h('span', { class: 'note' }, 'Tối đa mang ' + C.max.pots + ' bình') : null, i); })));
  body.append(misc);
  const bcls = G.to ? [G.to.cls] : Object.keys(C.cls);
  const bk = card(['scroll', 'c-mint', 'Sách kỹ năng' + (G.to ? ' (phái ' + C.cls[G.to.cls] + ')' : '')]);
  if (G.online) bk.append(h('p', { class: 'note' }, 'Mỗi người nhận sách đúng phái của mình theo số thứ tự (1–6).'));
  for (const c of (G.online ? [bcls[0]] : bcls)) bk.append(h('div', { class: 'cat' }, C.books[c].map(b => { const k = b.i, on = G.books[k];
    return h('button', { class: 'gi' + (on ? ' sel' : ''), onclick: () => { G.books[k] = on ? null : { i: k, learn: false }; layout(); } }, h('img', { src: b.icon, alt: '' }), h('b', null, (k + 1) + '. ' + (G.online ? 'Kỹ năng ' + (k + 1) : b.n)), h('span', { class: 'note' }, 'Cấp ' + b.req + (b.price ? ' · ' + fmt(b.price) + ' vàng' : '')),
      on ? h('label', { class: 'chk', onclick: e => e.stopPropagation() }, h('input', { type: 'checkbox', checked: on.learn, onchange: e => on.learn = e.target.checked }), 'Học luôn (nếu đủ cấp)') : null); })));
  body.append(bk);
  // giỏ quà
  const cart = card(['gift', 'c-red', 'Giỏ quà (' + G.cart.reduce((a, x) => a + (+x.qty || 1), 0) + ' món đồ)']);
  if (!G.cart.length) cart.append(h('p', { class: 'empty' }, 'Bấm vào món đồ ở trên để thêm vào giỏ.'));
  G.cart.forEach((x, idx) => {
    const sel = h('select', { onchange: e => { x.q = e.target.value; if (x.q === 'base') x.st = { ...x.base }; if (x.q === 'max') x.st = { ...x.max }; layout(); } }, [['base', 'Mặc định'], ['max', 'Tối đa (như đồ rơi tốt nhất)'], ['custom', 'Tự nhập']].map(([v, n]) => h('option', { value: v, selected: x.q === v }, n)));
    const stIn = x.q === 'custom' ? Object.keys(x.st).map(k => field(ST[k], inp({ type: 'number', min: 1, value: x.st[k], oninput: e => x.st[k] = +e.target.value }))) : [];
    cart.append(h('div', { class: 'cart-row r' + x.r }, h('img', { src: x.icon, alt: '' }),
      h('div', { class: 'grow' }, h('b', { style: 'color:' + RCOL[x.r] }, (x.up ? '+' + x.up + ' ' : '') + x.name + ' · cấp ' + x.lvl), h('span', { class: 'note' }, x.q === 'custom' ? 'Chỉ số tự nhập (không vượt mức tối đa của game)' : stTxt(x.q === 'max' ? x.max : x.base)),
        h('div', { class: 'row' }, field('Rèn +', inp({ type: 'number', min: 0, max: C.max.up, value: x.up, style: 'width:80px', oninput: e => x.up = Math.max(0, Math.min(C.max.up, +e.target.value || 0)) })),
          field('Số lượng', inp({ type: 'number', min: 1, max: 30, value: x.qty, style: 'width:80px', oninput: e => x.qty = Math.max(1, Math.min(30, +e.target.value || 1)) })),
          field('Chỉ số', sel), ...stIn,
          h('label', { class: 'chk' }, h('input', { type: 'checkbox', checked: x.lock, onchange: e => x.lock = e.target.checked }), 'Khóa (không giao dịch được)'))),
      h('button', { class: 'btn sm red', title: 'Bỏ khỏi giỏ', onclick: () => { G.cart.splice(idx, 1); layout(); } }, icon('trash'))));
  });
  const note = inp({ maxlength: 120, placeholder: 'Lời nhắn kèm quà (không bắt buộc)', value: G.note, oninput: e => G.note = e.target.value });
  const send = h('button', { class: 'btn green big', disabled: !own }, icon('gift'), own ? 'Tặng ngay' : 'Chỉ chủ mới tặng được');
  send.onclick = async () => {
    if (!G.online && !G.to) return toast('Chọn người nhận trước.', true);
    const gear = G.cart.map(x => ({ cls: x.cls, slot: x.slot, r: x.r, lvl: x.lvl, up: x.up, q: x.q, st: x.st, lock: x.lock, qty: x.qty }));
    const books = Object.values(G.books).filter(Boolean);
    const sum = [...G.cart.map(x => (x.qty > 1 ? x.qty + '× ' : '') + (x.up ? '+' + x.up + ' ' : '') + x.name), ...C.misc.filter(m => G.misc[m.k]).map(m => fmt(G.misc[m.k]) + ' ' + m.n.toLowerCase()), ...books.map(b => 'sách kỹ năng ' + (b.i + 1))];
    if (!sum.length) return toast('Giỏ quà đang trống.', true);
    const who = G.online ? 'MỌI NGƯỜI đang online trên máy chủ ' + G.srv : G.to.name;
    if (!await confirmBox('Tặng quà', 'Tặng cho ' + who + ': ' + sum.join(', ') + '.', 'Tặng', 'green')) return;
    const r = await run('give', { ...(G.online ? { online: 1, srv: G.srv } : { uid: G.to.uid, srv: G.to.srv }), gear, books, ...G.misc, note: G.note });
    if (!r) return;
    toast(G.online ? 'Đã tặng cho ' + r.n + ' người' + (r.fail.length ? ' (' + r.fail.length + ' người túi đầy)' : '') + '.' : 'Đã tặng: ' + r.got.join(', '));
    if (r.char && G.to) G.to.free = C.max.inv - r.char.inv.length;
    G.cart = []; G.books = {}; G.misc = { pots: 0, stones: 0, gold: 0, exp: 0 }; G.note = ''; layout();
  };
  cart.append(h('div', { class: 'row', style: 'margin-top:12px' }, h('label', { style: 'flex:1' }, 'Lời nhắn', note), send, G.cart.length ? h('button', { class: 'btn sky', onclick: () => { G.cart = []; layout(); } }, 'Xóa giỏ') : null));
  body.append(cart);
};

/* ---------- chi tiết người chơi ---------- */
async function openPlayer(uid) {
  TAB = 'players'; layout(); const body = mainEl.querySelector('.grid'); body.replaceChildren(h('p', { style: 'color:#fff' }, 'Đang tải…'));
  const p = await run('player', { uid }); if (!p) return;
  const u = p.user; body.replaceChildren();
  const act = (t, cls, f, need) => h('button', { class: 'btn sm ' + (cls || ''), disabled: !can(need || 'gm'), onclick: f }, t);
  const reload = () => openPlayer(uid);
  body.append(h('div', null, h('button', { class: 'btn sm sky', onclick: () => { layout(); } }, '← Danh sách')));
  body.append(card(['user', 'c-sky', u.username], h('div', { class: 'row', style: 'margin-bottom:10px' },
      u.banned ? h('span', { class: 'pill off' }, 'Bị khóa đến ' + (u.banned_until > Date.now() + 50 * 365 * 86400e3 ? 'vĩnh viễn' : dt(u.banned_until))) : h('span', { class: 'pill on' }, 'Hoạt động'),
      u.muted ? h('span', { class: 'pill warn' }, 'Cấm chat đến ' + dt(u.muted_until)) : null, u.staff ? h('span', { class: 'pill blue' }, ROLE_N[u.staff]) : null),
    h('div', { class: 'kv' }, h('span', null, 'Mã tài khoản'), h('span', null, '#' + u.id), h('span', null, 'Tạo lúc'), h('span', null, dt(u.created)), h('span', null, 'Đăng nhập cuối'), h('span', null, dt(u.last_login) + (u.last_ip ? ' · IP ' + u.last_ip : '')),
      h('span', null, 'Phiên đăng nhập'), h('span', null, p.sessions), h('span', null, 'Bạn bè'), h('span', null, p.friends), u.ban_reason ? h('span', null, 'Lý do khóa') : null, u.ban_reason ? h('span', null, u.ban_reason) : null),
    h('div', { class: 'row', style: 'margin-top:12px' },
      u.banned ? act('Mở khóa', 'green', async () => { await run('unban', { uid }, 'Đã mở khóa.'); reload(); })
        : act('Khóa tài khoản', 'red', async () => {
          const hrs = h('select', null, [['1', '1 giờ'], ['24', '1 ngày'], ['72', '3 ngày'], ['168', '7 ngày'], ['720', '30 ngày'], ['0', 'Vĩnh viễn']].map(([v, n]) => h('option', { value: v }, n))), rs = inp({ maxlength: 200, placeholder: 'Lý do (người chơi sẽ thấy)' });
          const v = await modal('Khóa ' + u.username, h('div', { class: 'grid' }, field('Thời gian', hrs), field('Lý do', rs)), [{ t: 'Khóa', cls: 'red', get: () => ({ hours: +hrs.value, reason: rs.value }) }]);
          if (v) { await run('ban', { uid, ...v }, 'Đã khóa.'); reload(); } }),
      act(u.muted ? 'Bỏ cấm chat' : 'Cấm chat', 'sky', async () => {
        if (u.muted) { await run('mute', { uid, minutes: 0 }, 'Đã bỏ cấm.'); return reload(); }
        const mi = h('select', null, [['10', '10 phút'], ['60', '1 giờ'], ['1440', '1 ngày'], ['10080', '7 ngày']].map(([v, n]) => h('option', { value: v }, n)));
        const v = await modal('Cấm chat ' + u.username, field('Thời gian', mi), [{ t: 'Cấm', cls: 'red', get: () => +mi.value }]); if (v) { await run('mute', { uid, minutes: v }, 'Đã cấm chat.'); reload(); } }),
      act('Đá khỏi game', 'sky', async () => { if (await confirmBox('Đá khỏi game', 'Mời ' + u.username + ' ra khỏi game?', 'Đá')) await run('kick', { uid }, 'Đã đá.'); }),
      act('Đặt lại mật khẩu', 'sky', async () => { if (!await confirmBox('Đặt lại mật khẩu', 'Tạo mật khẩu tạm mới cho ' + u.username + '. Mọi phiên đang đăng nhập bị đăng xuất.', 'Đặt lại')) return; const r = await run('reset_pw', { uid }); if (r) showSecret('Mật khẩu tạm', 'Gửi riêng cho người chơi, nhắc họ đổi sau khi vào:', r.temp); }, 'owner'))));
  for (const c of p.chars) body.append(charCard(uid, c, p, reload));
  if (!p.chars.length) body.append(card(['sword', 'c-vio', 'Nhân vật'], h('p', { class: 'empty' }, 'Chưa tạo nhân vật.')));
  body.append(h('div', { class: 'grid g2' },
    card(['gem', 'c-vio', 'Sự kiện của người chơi'], h('div', { class: 'scroll' }, h('table', null, p.events.length ? p.events.map(e => evRow({ ...e, name: 'S' + e.srv })) : h('tr', null, h('td', { class: 'empty' }, 'Chưa có.'))))),
    card(['scroll', 'c-ink', 'Lịch sử quản trị'], h('div', { class: 'scroll' }, h('table', null, p.history.length ? p.history.map(x => h('tr', null, h('td', null, dt(x.at)), h('td', null, x.who), h('td', null, ACT_N[x.action] || x.action), h('td', { class: 'mono', style: 'font-size:12px' }, x.detail))) : h('tr', null, h('td', { class: 'empty' }, 'Chưa có.')))))));
}
function charCard(uid, c, p, reload) {
  const own = can('owner'), el = card(['sword', 'c-vio', charName(c) + ' — Máy chủ ' + c.srv]);
  el.append(h('div', { class: 'row', style: 'margin-bottom:8px' }, c.online ? h('span', { class: 'pill on' }, 'Đang online') : h('span', { class: 'pill' }, 'Lưu lúc ' + dt(c.updated)), h('span', { class: 'pill blue' }, MAPS[c.map] || ''), c.anomalies ? h('span', { class: 'pill off' }, 'Bất thường: ' + c.anomalies) : null, c.bad ? h('span', { class: 'pill warn' }, c.bad.length + ' món hỏng được cất riêng') : null));
  const F = {}; const num = (k, v, max) => (F[k] = inp({ type: 'number', min: 0, max, value: v, disabled: !own }));
  el.append(h('div', { class: 'row' }, field('Cấp', num('lv', c.lv, 100)), field('Kinh nghiệm', num('exp', c.exp)), field('Vàng', num('gold', c.gold)), field('Đá cường hóa', num('stones', c.stones)), field('Bình máu', num('pots', c.pots, 20)), field('Quái đã hạ', num('kills', c.kills))));
  if (own) el.append(h('div', { class: 'row', style: 'margin-top:8px' }, h('button', { class: 'btn green sm', onclick: async () => {
    const set = {}; for (const k in F) if (+F[k].value !== +c[k]) set[k] = +F[k].value;
    if (!Object.keys(set).length) return toast('Chưa thay đổi gì.');
    if (await confirmBox('Lưu nhân vật', 'Lưu: ' + Object.entries(set).map(([k, v]) => k + '=' + v).join(', ') + '. Bản trước khi sửa được giữ lại để khôi phục.', 'Lưu', 'green')) { await run('char_edit', { uid, srv: c.srv, set }, 'Đã lưu.'); reload(); }
  } }, 'Lưu chỉ số')));
  const itemBox = (it, eq) => h('div', { class: 'item r' + (it.r | 0) }, h('b', null, (it.up ? '+' + it.up + ' ' : '') + it.name), h('span', { class: 'note' }, (eq ? 'Đang mặc · ' : '') + RAR[it.r | 0] + ' · ' + (SLOT[it.slot] || it.slot) + ' · Cấp ' + it.lvl + ' · ' + (CLS[it.cls] || it.cls) + (it.lock ? ' · Khóa' : '')),
    h('span', null, Object.entries(it.st || {}).map(([k, v]) => ({ atk: 'Công', def: 'Thủ', hp: 'Máu', spd: 'Tốc' }[k] || k) + ' ' + v).join(' · ')),
    own ? h('button', { class: 'btn sm red', style: 'align-self:flex-start;margin-top:4px', onclick: async () => { if (await confirmBox('Xóa đồ', 'Xóa "' + it.name + '" khỏi nhân vật?', 'Xóa')) { await run('item_del', { uid, srv: c.srv, id: it.id }, 'Đã xóa.'); reload(); } } }, 'Xóa') : null);
  const eqs = Object.values(c.eq || {}).filter(Boolean);
  el.append(h('h3', null, 'Trang bị và túi đồ (' + (c.inv || []).length + '/30)'), h('div', { class: 'items' }, eqs.map(it => itemBox(it, true)), (c.inv || []).map(it => itemBox(it, false))));
  if (own) {
    const cls = h('select', null, Object.entries(CLS).map(([k, n]) => h('option', { value: k, selected: k === c.cls }, n))), slot = h('select', null, Object.entries(SLOT).map(([k, n]) => h('option', { value: k }, n))),
      r = h('select', null, RAR.map((n, i) => h('option', { value: i }, n))), lvl = inp({ type: 'number', min: 1, max: 100, value: Math.max(1, Math.floor(c.lv / 5) * 5) }), up = inp({ type: 'number', min: 0, max: 15, value: 0 });
    el.append(h('div', { class: 'row', style: 'margin-top:12px' }, h('button', { class: 'btn', onclick: () => giftTo(uid, c.srv, c) }, icon('gift'), 'Tặng vật phẩm…')));
    const snapsBox = h('div');
    el.append(h('h3', null, 'Khôi phục'), h('div', { class: 'row' },
      h('button', { class: 'btn sm sky', onclick: async () => { const s = await run('snaps', { uid }); if (!s) return; const l = s.list.filter(x => x.srv === c.srv);
        snapsBox.replaceChildren(l.length ? h('table', null, l.map(x => h('tr', null, h('td', null, dt(x.at)), h('td', null, x.reason), h('td', null, x.who || ''), h('td', null, h('button', { class: 'btn sm red', onclick: async () => { if (await confirmBox('Khôi phục', 'Đưa nhân vật về đúng như lúc ' + dt(x.at) + '? (Trạng thái hiện tại cũng được lưu lại trước.)', 'Khôi phục')) { await run('restore', { uid, srv: c.srv, snap: x.id }, 'Đã khôi phục.'); reload(); } } }, 'Khôi phục'))))) : h('p', { class: 'note' }, 'Chưa có bản lưu nào (bản lưu được tạo mỗi khi quản trị sửa nhân vật).')); } }, 'Xem bản lưu'),
      p.backupV1.includes(c.srv) ? h('button', { class: 'btn sm sky', onclick: async () => { if (await confirmBox('Khôi phục bản cũ', 'Đưa nhân vật về bản sao lưu lúc chuyển sang máy chủ mới (trước 2.0)?', 'Khôi phục')) { await run('restore', { uid, srv: c.srv, from: 'v1' }, 'Đã khôi phục.'); reload(); } } }, 'Về bản trước 2.0') : null), snapsBox);
  }
  return el;
}

start();
})();
