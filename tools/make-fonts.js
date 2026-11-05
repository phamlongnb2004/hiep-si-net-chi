// Tạo tools/fonts.css: nhúng font có đủ dấu tiếng Việt (Baloo 2 cho tiêu đề, Nunito cho chữ thường).
// Tên font cũ trong game ("Lilita One", "Patrick Hand") được trỏ sang font mới, nên mọi chữ trong game đều đổi theo.
// Dùng: npm i --no-save @fontsource/baloo-2@5 @fontsource/nunito@5 && node tools/make-fonts.js [thư_mục_node_modules]
'use strict';
const fs = require('fs');
const path = require('path');
const nm = process.argv[2] || path.join(__dirname, '..', 'node_modules');
const SUBSETS = ['latin', 'latin-ext', 'vietnamese'];

// [tên khai báo, gói, độ đậm của file, độ đậm khai báo]
const FACES = [
  ['Baloo 2', 'baloo-2', 700, 700], ['Baloo 2', 'baloo-2', 800, 800],
  ['Nunito', 'nunito', 600, 600], ['Nunito', 'nunito', 700, 700], ['Nunito', 'nunito', 800, 800],
  ['Lilita One', 'baloo-2', 800, 400], ['Lilita One', 'baloo-2', 800, 700],
  ['Patrick Hand', 'nunito', 700, 400], ['Patrick Hand', 'nunito', 800, 700],
];

const out = [];
for (const [family, pkg, w, declared] of FACES) {
  const css = fs.readFileSync(path.join(nm, '@fontsource', pkg, `${w}.css`), 'utf8');
  for (const block of css.match(/@font-face\s*\{[^}]*\}/g) || []) {
    const file = (block.match(/url\(\.\/files\/([^)]+?\.woff2)\)/) || [])[1];
    const range = (block.match(/unicode-range:\s*([^;]+);/) || [])[1];
    if (!file || !SUBSETS.some(s => file.includes(`-${s}-${w}-`))) continue;
    const b64 = fs.readFileSync(path.join(nm, '@fontsource', pkg, 'files', file)).toString('base64');
    out.push(`@font-face{font-family:'${family}';font-style:normal;font-weight:${declared};font-display:swap;src:url(data:font/woff2;base64,${b64}) format('woff2');${range ? 'unicode-range:' + range + ';' : ''}}`);
  }
}
fs.writeFileSync(path.join(__dirname, 'fonts.css'), out.join('\n'));
console.log('fonts.css:', out.length, 'khối,', Math.round(out.join('').length / 1024), 'KB');
