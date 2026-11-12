// Ghép bản game: game gốc (đồ họa chibi) + font đóng gói sẵn + lớp online + cấu hình máy chủ.
// Dùng: node tools/build-client.js [địa_chỉ_máy_chủ]   (bỏ trống = dùng chính máy chủ đang phục vụ trang)
'use strict';
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');
const server = (process.argv[2] || process.env.SERVER_URL || '').replace(/\/+$/, '');

let html = fs.readFileSync(path.join(root, 'tools', 'game-base.html'), 'utf8');
const net = fs.readFileSync(path.join(root, 'tools', 'net.js'), 'utf8');
const fontCss = fs.readFileSync(path.join(root, 'tools', 'fonts.css'), 'utf8');
const uiJs = fs.readFileSync(path.join(root, 'tools', 'ui.js'), 'utf8');
const uiAssets = fs.readFileSync(path.join(root, 'tools', 'ui-assets.json'), 'utf8');
const animAssets = fs.readFileSync(path.join(root, 'tools', 'anim-assets.json'), 'utf8');
const animJs = fs.readFileSync(path.join(root, 'tools', 'anim.js'), 'utf8');
const hudJs = fs.readFileSync(path.join(root, 'tools', 'hud.js'), 'utf8');
const hudAssets = fs.readFileSync(path.join(root, 'tools', 'hud-assets.json'), 'utf8');
// tài nguyên không bắt buộc (chưa có thì để trống)
const opt = f => { try { return fs.readFileSync(path.join(root, 'tools', f), 'utf8'); } catch (e) { return '{}'; } };
const gearAssets = opt('gear-assets.json'), layerAssets = opt('layer-assets.json'), fxAssets = opt('fx-assets.json'), sideAssets = opt('side-assets.json'), monAssets = opt('mon-assets.json');
const sideJs = fs.readFileSync(path.join(root, 'tools', 'side.js'), 'utf8');
const gearJs = fs.readFileSync(path.join(root, 'tools', 'gear.js'), 'utf8');
const vfxJs = fs.readFileSync(path.join(root, 'tools', 'vfx.js'), 'utf8');
const bagJs = fs.readFileSync(path.join(root, 'tools', 'bag.js'), 'utf8');

// font: bỏ Google Fonts (không cần mạng ngoài), dùng font nhúng
html = html.replace(/<link rel="preconnect"[^>]*>\s*/g, '').replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>\s*/g, '');
const cfg = `<script>window.HSNC_CONFIG={server:${JSON.stringify(server)}};</script>`;
html = html.replace('<title>Hiệp Sĩ Nét Chì</title>', '<title>Hiệp Sĩ Nét Chì</title>\n' + cfg + '\n<style>' + fontCss + '</style>');

// lớp online chèn trước đoạn khởi động game
const anchor = "\nnew ResizeObserver(resize).observe($('app'));";
if (html.split(anchor).length !== 2) throw new Error('Không tìm thấy điểm chèn');
const inject = '\nwindow.HSNC_UI=' + uiAssets + ';\nwindow.HSNC_ANIM=' + animAssets + ';\nwindow.HSNC_HUD=' + hudAssets
  + ';\nwindow.HSNC_SIDE=' + sideAssets + ';\nwindow.HSNC_MON=' + monAssets + ';\nwindow.HSNC_GEAR=' + gearAssets + ';\nwindow.HSNC_LAYER=' + layerAssets + ';\nwindow.HSNC_FX=' + fxAssets + ';\n'
  + sideJs + '\n' + gearJs + '\n' + animJs + '\n' + vfxJs + '\n' + net + '\n' + uiJs + '\n' + hudJs + '\n' + bagJs + anchor;
html = html.replace(anchor, () => inject);
html = html.replace('Bản này chơi một mình và lưu tiến trình ngay trên trình duyệt. Chế độ nhiều người chơi cần thêm máy chủ riêng.', 'Đang kết nối máy chủ…');

// thông tin ứng dụng web (cài lên màn hình chính, đóng gói APK bằng PWABuilder)
const pwa = '<link rel="manifest" href="manifest.webmanifest">\n<link rel="icon" href="icon-192.png">\n<link rel="apple-touch-icon" href="icon-192.png">\n<meta name="theme-color" content="#10152a">\n'
  + '<script>if("serviceWorker" in navigator&&/^https:$/.test(location.protocol))addEventListener("load",()=>navigator.serviceWorker.register("sw.js").catch(()=>{}));</script>';
html = html.replace('<title>Hiệp Sĩ Nét Chì</title>', '<title>Hiệp Sĩ Nét Chì</title>\n' + pwa);
// màn chờ khi mở trang: trang game nặng, trong lúc tải không để lộ màn bắt đầu cũ
const splash = '<div id="bootSplash" style="position:fixed;inset:0;z-index:9999;display:grid;place-items:center;background:radial-gradient(circle at 50% 45%,#1e3c78,#080e22);color:#fff;font:800 20px \'Baloo 2\',sans-serif;text-shadow:0 2px 0 #16224a">'
  + '<div style="display:flex;flex-direction:column;align-items:center;gap:16px"><div style="width:54px;height:54px;border-radius:50%;border:6px solid rgba(255,255,255,.25);border-top-color:#ffd23f;animation:bsSpin .8s linear infinite"></div><span>Đang tải Hiệp Sĩ Nét Chì…</span></div>'
  + '<style>@keyframes bsSpin{to{transform:rotate(360deg)}}</style></div>';
if (html.split('<section id="start" class="overlay">').length !== 2) throw new Error('Không tìm thấy màn bắt đầu');
html = html.replace('<section id="start" class="overlay">', () => splash + '\n<section id="start" class="overlay" hidden>');
const out = path.join(root, 'public', 'index.html');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, html);
for (const f of fs.readdirSync(path.join(root, 'tools', 'pwa'))) fs.copyFileSync(path.join(root, 'tools', 'pwa', f), path.join(root, 'public', f));
// file cài đặt (Windows, Android) để trang tải game phục vụ ngay trên máy chủ này; cả hai mở thẳng máy chủ game nên luôn là bản mới
// bản cũ (ứng dụng vỏ) vẫn phục vụ tới khi có bản gốc trên GitHub Releases
for (const f of ['HiepSiNetChi-Windows.zip', 'HiepSiNetChi.apk']) { const p = path.join(root, 'release-files', f); if (fs.existsSync(p) && !fs.existsSync(path.join(root, 'release-files', 'update', 'latest.json'))) fs.copyFileSync(p, path.join(root, 'public', f)); }
// ứng dụng gốc (Godot) nằm ở GitHub Releases (file lớn hơn giới hạn 25 MB của Cloudflare); ở đây chỉ có manifest đã ký và bản đọc được
{ const ud = path.join(root, 'release-files', 'update'); if (fs.existsSync(ud)) { fs.mkdirSync(path.join(root, 'public', 'update'), { recursive: true }); for (const f of fs.readdirSync(ud)) if (/\.json$/.test(f)) fs.copyFileSync(path.join(ud, f), path.join(root, 'public', 'update', f)); } }
// dấu phiên bản: ghi lại mỗi lần đóng gói (Cloudflare tự đóng gói mỗi lần đẩy cập nhật)
{ const sha = (process.env.WORKERS_CI_COMMIT_SHA || process.env.CF_PAGES_COMMIT_SHA || '').slice(0, 7), d = new Date();
  const v = d.toISOString().slice(0, 10).replace(/-/g, '.') + (sha ? '-' + sha : '');
  fs.writeFileSync(path.join(root, 'public', 'version.json'), JSON.stringify({ v, built: d.toISOString(), commit: sha })); }
// trang tải game (/tai-game) và ảnh của nó
for (const f of fs.readdirSync(path.join(root, 'tools', 'site'))) fs.copyFileSync(path.join(root, 'tools', 'site', f), path.join(root, 'public', f));
// biểu tượng vật phẩm cho trang quản trị (kho vật phẩm): lấy từ ảnh của ứng dụng gốc
{ const A = path.join(root, 'client', 'assets'), O = path.join(root, 'public', 'admin-icons');
  const cp = (src, dst) => { if (!fs.existsSync(src)) return; fs.mkdirSync(path.dirname(dst), { recursive: true }); fs.copyFileSync(src, dst); };
  for (const cls of ['sword', 'archer', 'mage', 'fighter']) for (let r = 0; r < 4; r++) for (let i = 0; i < 6; i++) cp(path.join(A, 'gear', cls, String(r), i + '.webp'), path.join(O, 'gear', cls, String(r), i + '.webp'));
  for (const k of ['neck', 'wing']) for (let r = 0; r < 4; r++) cp(path.join(A, 'acc', k, r + '.webp'), path.join(O, 'acc', k, r + '.webp'));
  // đồ theo bậc cấp (2.8.0)
  for (const cls of ['sword', 'archer', 'mage', 'fighter']) for (let b = 0; b < 10; b++) for (const k of ['hat', 'armor', 'cape', 'weapon', 'boots', 'gloves']) cp(path.join(A, 'gear2', cls, String(b), k + '.webp'), path.join(O, 'gear2', cls, String(b), k + '.webp'));
  for (const k of ['neck', 'ring', 'earring', 'belt', 'charm']) for (let b = 0; b < 10; b++) cp(path.join(A, 'acc2', k, b + '.webp'), path.join(O, 'acc2', k, b + '.webp'));
  for (const cls of ['sword', 'archer', 'mage', 'fighter']) for (let i = 0; i < 6; i++) cp(path.join(A, 'hud', 'skills', cls, i + '.webp'), path.join(O, 'skills', cls, i + '.webp'));
  for (const k of ['pot', 'stone', 'gold', 'book']) cp(path.join(A, 'hud', 'ui', k + '.webp'), path.join(O, k + '.webp'));
  // vật phẩm khác (bình 3 cỡ, bùa) và trứng thú cưng: trang quản trị dùng admin-icons/misc/*, admin-icons/egg/<loài>.webp
  for (const k of ['pot0', 'pot1', 'pot2', 'kpot0', 'kpot1', 'kpot2', 'charm']) cp(path.join(A, 'hud', 'ui', k + '.webp'), path.join(O, 'misc', k + '.webp'));
  if (fs.existsSync(path.join(A, 'egg'))) for (const sp of fs.readdirSync(path.join(A, 'egg'))) cp(path.join(A, 'egg', sp, '0.webp'), path.join(O, 'egg', sp + '.webp')); }
console.log('Đã tạo', path.relative(root, out), (html.length / 1048576).toFixed(2) + ' MB', 'máy chủ:', server || '(cùng địa chỉ trang)');
