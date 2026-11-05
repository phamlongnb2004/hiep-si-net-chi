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

// font: bỏ Google Fonts (không cần mạng ngoài), dùng font nhúng
html = html.replace(/<link rel="preconnect"[^>]*>\s*/g, '').replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>\s*/g, '');
const cfg = `<script>window.HSNC_CONFIG={server:${JSON.stringify(server)}};</script>`;
html = html.replace('<title>Hiệp Sĩ Nét Chì</title>', '<title>Hiệp Sĩ Nét Chì</title>\n' + cfg + '\n<style>' + fontCss + '</style>');

// lớp online chèn trước đoạn khởi động game
const anchor = "\nnew ResizeObserver(resize).observe($('app'));";
if (html.split(anchor).length !== 2) throw new Error('Không tìm thấy điểm chèn');
html = html.replace(anchor, '\n' + net + anchor);
html = html.replace('Bản này chơi một mình và lưu tiến trình ngay trên trình duyệt. Chế độ nhiều người chơi cần thêm máy chủ riêng.', 'Đang kết nối máy chủ…');

const out = path.join(root, 'public', 'index.html');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, html);
console.log('Đã tạo', path.relative(root, out), (html.length / 1048576).toFixed(2) + ' MB', 'máy chủ:', server || '(cùng địa chỉ trang)');
