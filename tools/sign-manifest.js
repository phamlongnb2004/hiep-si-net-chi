// Ký manifest cập nhật (RSA-SHA256). Khóa riêng KHÔNG nằm trong mã nguồn: truyền đường dẫn qua --key.
// Dùng: node tools/sign-manifest.js --key ~/hsnc-keys/update_priv.pem --in release.json --out public/update/manifest.json
// release.json: { app:{version,min,windows:{url,file},android:{url,file}}, assets:{version,min_app,url,file}, changelog:[...] }
// Với mỗi mục có "file", tự tính sha256 và size.
const fs = require('fs'), crypto = require('crypto'), path = require('path');
const arg = k => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : null; };
const key = fs.readFileSync(arg('key') || process.env.HSNC_UPDATE_KEY, 'utf8');
const rel = JSON.parse(fs.readFileSync(arg('in'), 'utf8')), base = path.dirname(path.resolve(arg('in')));
const fill = o => { if (!o || !o.file) return; const p = path.resolve(base, o.file), b = fs.readFileSync(p);
  o.sha256 = crypto.createHash('sha256').update(b).digest('hex'); o.size = b.length; delete o.file; };
fill(rel.app && rel.app.windows); fill(rel.app && rel.app.android); fill(rel.assets);
rel.updated = new Date().toISOString();
const payload = Buffer.from(JSON.stringify(rel), 'utf8');
const sig = crypto.sign('sha256', payload, { key, padding: crypto.constants.RSA_PKCS1_PADDING });
const pub = crypto.createPublicKey(key);
if (!crypto.verify('sha256', payload, pub, sig)) throw new Error('tự kiểm chữ ký thất bại');
const out = arg('out'); fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify({ payload: payload.toString('base64'), sig: sig.toString('base64') }));
// bản đọc được (không ký) cho trang tải game
fs.writeFileSync(path.join(path.dirname(out), 'latest.json'), JSON.stringify(rel, null, 1));
console.log('Đã ký', out, '— app', rel.app && rel.app.version, '· dữ liệu', rel.assets && rel.assets.version);
