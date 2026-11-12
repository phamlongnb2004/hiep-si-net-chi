// Luật chơi dùng chung cho máy chủ (Cloudflare) và làm chuẩn để viết lại trong ứng dụng Godot.
// Dữ liệu số (phái, kỹ năng, quái, bản đồ...) nằm trong data.json, xuất từ bản game gốc bằng tools/export-shared-data.js.
// Mọi hàm ở đây là hàm thuần: không đọc giờ, không đọc DOM; số ngẫu nhiên truyền vào qua rng() (0..1).
import D from './data.json';
export { D };

export const MAX_LV = 100, INV_MAX = 30, POT_MAX = 999, GRAV = 2100, JUMP = 820, MAXSTEP = 105;
export const KPOT_GAIN = .45, KPOT_CD = 3, KPOT_MAX = 20; // bình KI (2.9.3)
// bình máu / bình KI 3 cỡ (2.9.4): nhỏ, vừa (= bình cũ), lớn — tỉ lệ hồi và hệ số giá (× giá bình nhỏ)
// 2.9.5: hồi lượng cố định (không theo %): nhỏ hợp cấp thấp, vừa cấp trung, lớn cấp cao; p = giá mỗi bình
export const POT_TIERS = [{ n: 'Nhỏ', hp: 150, ki: 60, p: 20 }, { n: 'Vừa', hp: 600, ki: 200, p: 80 }, { n: 'Lớn', hp: 1500, ki: 450, p: 250 }];
export const HP_KEYS = ['potS', 'pots', 'potL'], KI_KEYS = ['kpotS', 'kpots', 'kpotL'];
// chọn cỡ bình: cỡ nhỏ nhất đủ hồi phần thiếu, không có thì cỡ lớn nhất còn
export const potAmt = (t, ki) => POT_TIERS[t][ki ? 'ki' : 'hp'];
export function pickPot(ch, keys, miss, max) { const ki = keys === KI_KEYS; let best = -1; for (let t = 0; t < 3; t++) { if ((ch[keys[t]] | 0) <= 0) continue; best = t; if (potAmt(t, ki) >= miss) return t; } return best; }
// hồi sinh tại chỗ: khoảng 20 lần hạ quái cùng cấp
export const REVIVE_GOLD = 500, DEATH_DROP = .01; // hồi sinh tại chỗ: một giá cho mọi cấp; gục ngã rơi 1% vàng
export const DEAD_WAIT = 15, reviveCost = () => REVIVE_GOLD;
// bùa nâng cấp kỹ năng: cấp tối đa 6, từ cấp L lên L+1 cần L bùa; mỗi cấp +15% sát thương kỹ năng
export const SKILL_MAX = 6, SKILL_UP = .15, charmCost = L => L;
const _skc = new Map();
export function skillFx(cls, i, lv) {
  lv = Math.max(1, Math.min(SKILL_MAX, lv | 0)); const key = cls + i + ':' + lv; if (_skc.has(key)) return _skc.get(key);
  // sát thương (m) x(1+15%/cấp); bùa lợi (buff): thời gian +8%/cấp, phần cộng thêm của chỉ số +15%/cấp; hồi máu (heal f) +15%/cấp
  const mul = 1 + SKILL_UP * (lv - 1), tm = 1 + .08 * (lv - 1);
  const buf = o => Object.fromEntries(Object.entries(o).map(([k, x]) => [k, typeof x !== 'number' ? x : k === 't' ? x * tm : (k === 'atk' || k === 'def' || k === 'spd') ? 1 + (x - 1) * mul : k === 'crit' ? x * mul : k === 'take' ? Math.min(.6, x * mul) : x]));
  const sc = (v, pk) => Array.isArray(v) ? v.map(x => sc(x)) : v && typeof v === 'object' ? (pk === 'buff' ? buf(v) : Object.fromEntries(Object.entries(v).map(([k, x]) => [k, typeof x === 'number' && (k === 'm' || (pk === 'heal' && k === 'f')) ? x * mul : sc(x, k)]))) : v;
  const r = sc(SKILL_FX[cls][i]); _skc.set(key, r); return r;
}
export const POT_HEAL = .45, POT_CD = 3, POT_PRICE = 30, DEATH_T = 2.6, SAFE_REGEN = .08;
export const WORLD_CHAT_COST = 5000;          // nhắn cả máy chủ tốn vàng (cao) để tránh spam
export const FRIEND_MAX = 100;
export const WING_CHANCE = .015; // cánh: tỉ lệ rơi mỗi lần hạ trùm (rất thấp)
export const LOCK_CHANCE = .4;                // đồ rơi có tỉ lệ bị khóa (không giao dịch được)
export const ELITE_CHANCE = .07;              // quái thường thỉnh thoảng hồi sinh thành tinh anh
export const ELITE = { hp: 3, atk: 1.6, def: 1.5, exp: 3, gold: 3, drop: 2.5, dropMax: .6 };
// Tham số cân bằng do admin chỉnh trên máy chủ (không cần ra bản ứng dụng mới). Mặc định = luật gốc.
// ev: sự kiện tạm thời (x2 kinh nghiệm...), máy chủ tự tắt khi hết giờ.
export const TUNE_DEFAULT = { exp: 1, gold: 1, drop: 1, potPrice: POT_PRICE, shopMul: 1, forgeBonus: 0, eliteChance: ELITE_CHANCE, kiMul: 1, ptMul: 1, wingChance: WING_CHANCE, lvMul: 1, petExp: 1, mon: {}, rar: {} };
export const TUNE = { ...TUNE_DEFAULT, mon: {}, rar: {}, ev: { exp: 1, gold: 1, drop: 1, until: 0, name: '' } };
// áp tham số mới (đã kiểm giới hạn) vào TUNE; trả về bản đã chuẩn hóa để lưu
export function setTune(t) {
  const n = (v, lo, hi, d) => { v = +v; return Number.isFinite(v) ? Math.max(lo, Math.min(hi, v)) : d; };
  const o = {
    exp: n(t.exp, .1, 20, 1), gold: n(t.gold, .1, 20, 1), drop: n(t.drop, .1, 10, 1), potPrice: Math.round(n(t.potPrice, 1, 100000, POT_PRICE)),
    shopMul: n(t.shopMul, .1, 20, 1), forgeBonus: n(t.forgeBonus, -50, 50, 0), eliteChance: n(t.eliteChance, 0, .5, ELITE_CHANCE), kiMul: n(t.kiMul, 0, 5, 1), ptMul: n(t.ptMul, .1, 5, 1), wingChance: n(t.wingChance, 0, 1, WING_CHANCE), lvMul: n(t.lvMul, .2, 10, 1), petExp: n(t.petExp, 0, 5, 1), mon: {} };
  for (const k in (t.mon || {})) if (D.mons[k]) { const m = t.mon[k] || {}, q = {};
    for (const f of ['hp', 'atk', 'def', 'exp', 'gold', 'drop']) { const v = n(m[f], .1, 20, 1); if (v !== 1) q[f] = v; }
    if (Object.keys(q).length) o.mon[k] = q; }
  // tỉ lệ độ hiếm khi đồ rơi ra (%), theo nguồn: mob/elite/boss/wing; chỉ lưu nguồn khác mặc định
  o.rar = {};
  for (const k in RAR_W) { const a = t.rar && t.rar[k]; if (!Array.isArray(a) || a.length !== RAR_W[k].length) continue;
    const v = a.map(x => n(x, 0, 100, 0)), sum = v.reduce((x, y) => x + y, 0); if (!(sum > 0)) continue;
    const q = v.map(x => Math.round(x / sum * 100000) / 1000); if (q.some((x, i) => Math.abs(x - RAR_W[k][i]) > 1e-6)) o.rar[k] = q; }
  Object.assign(TUNE, o); return o;
}
const mt = (type, f) => (TUNE.mon[type] && TUNE.mon[type][f]) || 1;
const evOn = () => TUNE.ev && TUNE.ev.on;
// tên món theo phái (gear.js) và tỉ lệ hiếm khi rơi
export const NOUN = {
  sword: { hat: 'Mũ Giáp', armor: 'Giáp Kỵ Sĩ', cape: 'Áo Choàng', weapon: 'Kiếm' },
  archer: { hat: 'Mũ Trùm', armor: 'Áo Giáp Lá', cape: 'Áo Choàng', weapon: 'Cung' },
  mage: { hat: 'Nón Phép', armor: 'Pháp Bào', cape: 'Khăn Choàng', weapon: 'Trượng' },
  fighter: { hat: 'Khăn Đầu', armor: 'Võ Phục', cape: 'Khăn Choàng', weapon: 'Găng Vuốt' } };
// giày, găng: theo phái; dây chuyền, cánh: dùng chung mọi phái (cls = '')
for (const c in NOUN) Object.assign(NOUN[c], { boots: { sword: 'Giày Sắt', archer: 'Giày Lá', mage: 'Hài Phép', fighter: 'Giày Võ' }[c], gloves: { sword: 'Găng Sắt', archer: 'Bao Tay Cung', mage: 'Găng Phép', fighter: 'Bao Tay Võ' }[c] });
export const ACC_NAME = { neck: ['Dây Chuyền Đồng', 'Dây Chuyền Lam Ngọc', 'Dây Chuyền Tử Tinh', 'Dây Chuyền Thái Dương'], wing: ['Cánh Thiên Thần', 'Cánh Băng Tinh', 'Cánh Ma Tinh', 'Cánh Phượng Hoàng'] };
// đồ theo bậc cấp (từ 2.8.0): 10 bậc (cấp 1–10, 11–20 … 91–100); mỗi bậc × phái có tên bộ riêng, độ hiếm thêm hậu tố
export const BAND_N = 10;
export const band = lvl => clamp(Math.floor(((lvl | 0) - 1) / 10), 0, BAND_N - 1);
export const BAND_SET = {
  sword: ['Tập Sự', 'Thiết Kỵ', 'Ngọc Bích', 'Hải Long', 'Huyết Nguyệt', 'Băng Phách', 'Ám Dạ', 'Thanh Mộc', 'Nham Hỏa', 'Thiên Đế'],
  archer: ['Mộc Cung', 'Đồng Diệp', 'Lục Phong', 'Lam Vũ', 'Xích Nguyệt', 'Tuyết Ưng', 'U Linh', 'Tinh Linh', 'Viêm Điểu', 'Thiên Xạ'],
  mage: ['Học Đồ', 'Đồng Chú', 'Ngọc Thạch', 'Thủy Triều', 'Huyết Ấn', 'Hàn Băng', 'Hư Không', 'Sinh Mệnh', 'Dung Nham', 'Tinh Tú'],
  fighter: ['Võ Đồng', 'Thiết Quyền', 'Bích Hổ', 'Lam Giao', 'Huyết Lang', 'Băng Hổ', 'Ảnh Sát', 'Lục Long', 'Hỏa Quyền', 'Thần Long'] };
export const BAND_ACC = ['Gỗ Mộc', 'Đồng Thau', 'Bích Ngọc', 'Lam Ngọc', 'Huyết Ngọc', 'Băng Tinh', 'Tử Tinh', 'Lục Bảo', 'Hỏa Tinh', 'Thiên Quang'];
export const RAR_SUF = ['', ' Tinh Xảo', ' Cổ Đại', ' Thần Thánh'];
export const ACC_NOUN = { neck: 'Dây Chuyền', ring: 'Nhẫn', earring: 'Khuyên Tai', belt: 'Đai Lưng', charm: 'Bùa Hộ Mệnh' };
export const FREE_SLOTS = ['neck', 'wing', 'ring', 'earring', 'belt', 'charm'];
export const isFree = slot => FREE_SLOTS.includes(slot);
// cánh: chỉ rơi khi hạ trùm, tỉ lệ rất thấp; độ hiếm của cánh rơi ra
export const W_WING = [60, 28, 10, 2];
// 2.9.3: đồ tốt khó rơi hơn (thường / hiếm / sử thi / huyền thoại)
export const W_MOB = [90, 9, .9, .1], W_BOSS = [52, 38, 8.5, 1.5], W_ELITE = [72, 23, 4.4, .6];
export const RAR_W = { mob: W_MOB, elite: W_ELITE, boss: W_BOSS, wing: W_WING };
export const SLOTS = ['hat', 'armor', 'cape', 'weapon', 'boots', 'gloves', 'neck', 'wing', 'ring', 'earring', 'belt', 'charm'];
// ô đồ rơi từ quái thường / bán ở cửa hàng (cánh thì không)
export const DROP_SLOTS = ['hat', 'armor', 'cape', 'weapon', 'boots', 'gloves', 'neck', 'ring', 'earring', 'belt', 'charm'], DROP_SLOT_W = [1, 1, 1, 1, 1, 1, .6, .5, .5, .5, .5];
// tên món: dây chuyền/nhẫn/khuyên/đai/bùa theo bậc chung; đồ theo phái theo tên bộ của phái; cánh giữ tên theo độ hiếm
// cấp nhân vật cần để mặc (máy chủ kiểm tra khi mặc; đồ đang mặc từ trước vẫn giữ)
export const reqLv = it => Math.max(1, Math.min(MAX_LV, (it && it.lvl) | 0));
export function itemName(slot, c, rk, lvl) {
  const b = band(lvl);
  if (slot === 'wing') return ACC_NAME.wing[rk];
  if (isFree(slot)) return ACC_NOUN[slot] + ' ' + BAND_ACC[b] + RAR_SUF[rk];
  return NOUN[c][slot] + ' ' + BAND_SET[c][b] + RAR_SUF[rk];
}
export const CLS_KEYS = ['sword', 'archer', 'mage', 'fighter'];

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const ri = (rng, a, b) => Math.floor(a + rng() * (b - a + 1));
const pickW = (rng, ws) => { let x = rng() * ws.reduce((a, b) => a + b), k = 0; for (; k < ws.length; k++) { x -= ws[k]; if (x < 0) break; } return Math.min(k, ws.length - 1); };

/* ---------- cấp, chỉ số ---------- */
// cấp 1-30 giữ như cũ; sau 30 mỗi cấp khó hơn 15%, sau 60 mỗi cấp khó hơn 18% (cấp 99 cần ~500 triệu kinh nghiệm)
export const expMul = l => l <= 30 ? 1 : l <= 60 ? Math.pow(1.15, l - 30) : Math.pow(1.15, 30) * Math.pow(1.18, l - 60);
// kinh nghiệm lên cấp: tính theo số quái cùng cấp phải hạ (6 + 2,2×cấp: cấp 1 ~8 con, cấp 10 ~28, cấp 20 ~50, cấp 30 ~72, cấp 40 ~94),
// không thấp hơn công thức cũ (cấp rất cao vẫn giữ độ khó cũ). Hệ số TUNE.lvMul để admin chỉnh nhanh (mặc định 1).
const expOld = l => 30 * Math.pow(l, 1.45) * expMul(l);
export const expNeed = l => Math.floor(Math.max(expOld(l), (6 + 2.2 * l) * monCurve(l, 4)) * (TUNE.lvMul || 1));
export const itemStat = (it, k) => Math.round(((it.st && it.st[k]) || 0) * (1 + .12 * (it.up || 0)));
// bán cho Thương Nhân Giáp: 75% giá đồ thường cùng cấp trong cửa hàng; đồ hiếm trở lên cao hơn một chút
export const SELL_RAR = [1, 1.3, 1.7, 2.2];
export const sellPrice = it => Math.round(Math.round((25 + it.lvl * 9) * (1 + it.lvl / 3) * 3.5 * TUNE.shopMul) * .75 * (SELL_RAR[it.r] || 1) * (1 + .15 * (it.up || 0)));
export const score = it => it ? itemStat(it, 'atk') * 2 + itemStat(it, 'def') * 1.5 + itemStat(it, 'hp') * .1 + itemStat(it, 'spd') * .6 : 0;
/* ---------- điểm tiềm năng: mỗi lần lên cấp được PT_PER_LV điểm, người chơi tự cộng vào chỉ số ----------
  v: mỗi điểm cộng bao nhiêu; max: số điểm tối đa được dồn vào chỉ số đó (chỉ số tỉ lệ có trần) */
export const PT_PER_LV = 5;
export const PTS = {
  hp: { n: 'Máu', v: 5 }, atk: { n: 'Sức đánh', v: .7 }, def: { n: 'Giáp', v: .3 }, ki: { n: 'KI', v: 5 },
  crit: { n: 'Chí mạng', v: .002, max: 150 }, spd: { n: 'Tốc chạy', v: 1, max: 60 }, dodge: { n: 'Né tránh', v: .002, max: 125 },
  ls: { n: 'Hút máu', v: .001, max: 150 }, pen: { n: 'Xuyên giáp', v: .005, max: 100 }
};
export const PT_KEYS = Object.keys(PTS);
export const ptTotal = ch => Math.max(0, (ch.lv - 1) * PT_PER_LV);
export const ptUsed = ch => PT_KEYS.reduce((a, k) => a + ((ch.pt && ch.pt[k]) | 0), 0);
export const ptFree = ch => Math.max(0, ptTotal(ch) - ptUsed(ch));
// tẩy điểm: lần đầu miễn phí, sau đó tốn vàng theo cấp
export const resetCost = ch => (ch.ptReset | 0) < 1 ? 0 : 200 * ch.lv;
// KI: kỹ năng tốn KI, đánh thường không tốn; KI tự hồi (nhanh gấp đôi trong vùng an toàn)
export const KI_BASE = [8, 14, 20, 26, 32, 40], KI_REGEN = .04;
export const kiCost = (lv, i) => Math.round((KI_BASE[i] || 20) * (1 + (lv - 1) * .025) * TUNE.kiMul);
// chỉ số gốc của nhân vật (chưa tính bùa tạm thời)
export function stats(ch) {
  const c = D.cls[ch.cls], l = ch.lv - 1, p = ch.pt || {}, P = k => ((p[k] | 0) * PTS[k].v * (k === 'spd' ? 1 : TUNE.ptMul));
  let hp = c.hp + c.hpG * l + P('hp'), atk = c.atk + c.atkG * l + P('atk'), def = c.def + c.defG * l + P('def'), spd = c.spd + P('spd');
  for (const k of SLOTS) { const it = ch.eq && ch.eq[k]; if (!it) continue; hp += itemStat(it, 'hp'); atk += itemStat(it, 'atk'); def += itemStat(it, 'def'); spd += itemStat(it, 'spd'); }
  const r3 = x => Math.round(x * 1000) / 1000;
  return { maxHp: Math.round(hp), atk: Math.round(atk), def: Math.round(def), spd: Math.round(spd), crit: r3(c.crit + P('crit')), maxKi: Math.round(60 + 6 * l + P('ki')),
    dodge: r3(Math.min(.25, P('dodge'))), ls: r3(Math.min(.15, P('ls'))), pen: r3(Math.min(.5, P('pen'))) };
}
// cộng kinh nghiệm, trả về số cấp vừa lên
export function addExp(ch, n) {
  ch.exp += n; let up = 0;
  while (ch.lv < MAX_LV && ch.exp >= expNeed(ch.lv)) { ch.exp -= expNeed(ch.lv); ch.lv++; up++; }
  if (ch.lv >= MAX_LV) ch.exp = Math.min(ch.exp, expNeed(MAX_LV) - 1);
  return up;
}

/* ---------- đồ ---------- */
// chỉ số mặc định của một món (đồ bán ở NPC); đồ rơi từ quái dao động 80%..125% quanh mức này
export function baseStats(slot, lvl, rk) {
  const m = D.rar[rk].m, base = 3 + lvl * 1.4, st = {};
  if (slot === 'hat') { st.def = base * .6 * m; st.hp = base * 3 * m; }
  else if (slot === 'armor') { st.def = base * m; st.hp = base * 5 * m; }
  else if (slot === 'cape') { st.spd = (2 + lvl * .3) * m; st.def = base * .4 * m; }
  else if (slot === 'boots') { st.spd = (1.5 + lvl * .25) * m; st.def = base * .3 * m; }
  else if (slot === 'gloves') { st.atk = base * .5 * m; st.def = base * .2 * m; }
  else if (slot === 'neck') { st.hp = base * 2.5 * m; st.atk = base * .35 * m; }
  else if (slot === 'ring') { st.atk = base * .7 * m; st.spd = (1 + lvl * .15) * m; }
  else if (slot === 'earring') { st.hp = base * 2 * m; st.atk = base * .3 * m; }
  else if (slot === 'belt') { st.hp = base * 3 * m; st.def = base * .45 * m; }
  else if (slot === 'charm') { st.def = base * .6 * m; st.hp = base * 1.5 * m; st.atk = base * .2 * m; }
  else if (slot === 'wing') { st.hp = base * 3 * m; st.atk = base * .6 * m; st.def = base * .5 * m; st.spd = (2 + lvl * .3) * m; }
  else st.atk = base * 1.3 * m;
  return st;
}
function makeItem(id, slot, c, rk, lvl, st) {
  const R = D.rar[rk], free = isFree(slot);
  const it = { id, slot, cls: free ? '' : c, tier: rk, style: 0, col: R.c.length === 7 ? R.c : '#8a93a8', r: rk, lvl, b: band(lvl), name: itemName(slot, c, rk, lvl), st };
  if (slot === 'weapon') it.wk = c;
  return it;
}
// mode: false/'mob' quái thường, true/'boss' trùm, 'elite' tinh anh
export function genItem(rng, lvl, mode, cls, id) {
  const c = rng() < .75 && D.sets[cls] ? cls : CLS_KEYS[ri(rng, 0, CLS_KEYS.length - 1)];
  const src = mode === 'wing' ? 'wing' : mode === 'elite' ? 'elite' : (mode === true || mode === 'boss') ? 'boss' : 'mob', ws = (TUNE.rar && TUNE.rar[src]) || RAR_W[src];
  const wing = mode === 'wing', rk = pickW(rng, ws), slot = wing ? 'wing' : DROP_SLOTS[pickW(rng, DROP_SLOT_W)], b = baseStats(slot, lvl, rk), st = {};
  for (const k in b) st[k] = Math.max(1, Math.round(b[k] * (.8 + rng() * .45)));
  const it = makeItem(id, slot, c, rk, lvl, st);
  if (rng() < LOCK_CHANCE) it.lock = 1;
  return it;
}
// đồ bán ở NPC Trang Bị: chỉ số mặc định, không khóa
export const SHOP_TIER_MUL = [1, 3.5, 10, 32];
export const shopLevel = lv => Math.max(1, Math.floor(lv / 5) * 5);
// giá tăng theo cấp đồ nhanh như vàng rơi theo cấp quái (×(1 + cấp/3)): đồ trắng cùng cấp ≈ 45–60 lần hạ quái, đồ huyền thoại ≈ 1.500–2.000
export const shopPrice = (lvl, rk) => Math.round((25 + lvl * 9) * (1 + lvl / 3) * 3.5 * SHOP_TIER_MUL[rk] * TUNE.shopMul);
export function shopItem(c, slot, rk, lvl, id) {
  const b = baseStats(slot, lvl, rk), st = {};
  for (const k in b) st[k] = Math.max(1, Math.round(b[k]));
  const it = makeItem(id, slot, c, rk, lvl, st); it.shop = 1; return it;
}
// đồ cũ (trước khi có phái) thuộc về phái của nhân vật: giống fixIt trong gear.js
export function fixItem(it, cls) {
  if (!it) return;
  if (it.slot === 'egg') { it.cls = ''; it.tier = 3; if (!PET_SP[it.sp]) it.sp = 'fire'; return; }
  if (isFree(it.slot)) { it.cls = ''; it.tier = clamp(it.r | 0, 0, 3); return; }
  if (!D.sets[it.cls]) it.cls = D.sets[it.wk] ? it.wk : cls;
  it.tier = clamp(it.r | 0, 0, 3); if (it.slot === 'weapon') it.wk = it.cls;
}
export const validItem = it => !!(it && typeof it === 'object' && (SLOTS.includes(it.slot) || it.slot === 'egg') && it.st && typeof it.name === 'string' && D.rar[it.r] && typeof it.col === 'string' && /^#[0-9a-fA-F]{6}$/.test(it.col));
// chỉ số lớn nhất có thể có của một món (để đánh dấu bản lưu bất thường, không sửa)
export function maxItemStat(it) {
  const m = D.rar[3].m * 1.25, base = 3 + (it.lvl || 1) * 1.4;
  return { atk: Math.round(base * 1.3 * m) + 1, def: Math.round(base * m) + 1, hp: Math.round(base * 5 * m) + 1, spd: Math.round((2 + (it.lvl || 1) * .3) * m) + 1 };
}

/* ---------- lò rèn ---------- */
export function forgeInfo(it) {
  const L = (it.up || 0) + 1;
  // đá = cấp đích + 1, vàng tăng theo cấp đồ và cấp rèn; thất bại từ +5 tụt 1 cấp, từ +10 tụt 2 cấp
  return { L, rate: Math.max(1, Math.min(100, D.forge.rate[L - 1] + TUNE.forgeBonus)), stones: L + 1, gold: Math.round((40 + it.lvl * 6) * (1 + it.lvl / 3) * Math.pow(L, 1.6) * 1.5), drop: L <= 4 ? 0 : L <= 9 ? 1 : 2 };
}

/* ---------- quái ---------- */
// Quái thường: sức mạnh chỉ theo CẤP (bảng mốc, nội suy theo log); loài khác nhau ở tốc độ, cách đánh, hình dáng
// -> quái cấp cao hơn luôn mạnh hơn quái cấp thấp hơn, kể cả khác loài. Trùm (rồng) giữ công thức riêng.
const MON_LV = [ // cấp, máu, công, thủ, kinh nghiệm
  [1, 30, 7, .5, 12], [5, 120, 17, 4, 70], [9, 330, 33, 8, 230], [12, 430, 40, 9.5, 380], [15, 650, 55, 12, 600],
  [19, 1000, 75, 15, 1000], [24, 1400, 100, 19, 1450], [30, 2000, 130, 24, 2200], [60, 5200, 300, 50, 17600], [100, 11000, 560, 90, 283000]];
const MON_FAM = { snail: { hp: 1, atk: .9, def: 1.8 }, croc: { hp: 1.3, atk: 1, def: 1.2 }, jelly: { hp: .85, atk: 1, def: .8 }, gull: { hp: .85, atk: 1, def: .9 }, swordfish: { hp: .9, atk: 1.1, def: 1 }, snakelet: { hp: .5, atk: .6, def: .6 }, dragonling: { hp: 1.2, atk: .9, def: .9 } }; // có thể thêm chênh lệch theo loài, vd { bear: { hp: 1.02, atk: 1, def: 1 } } (giữ nhỏ để cấp cao vẫn mạnh hơn)
export function monCurve(lv, i) {
  const T = MON_LV; lv = Math.max(1, lv);
  let a = T[0], b = T[1];
  for (let k = 1; k < T.length; k++) { a = T[k - 1]; b = T[k]; if (lv <= b[0]) break; }
  const f = (lv - a[0]) / (b[0] - a[0]); // sau mốc cuối: kéo dài theo độ dốc đoạn cuối
  return Math.exp(Math.log(a[i]) + (Math.log(b[i]) - Math.log(a[i])) * f);
}
const famOf = type => MON_FAM[type.replace(/\d+$/, '')] || { hp: 1, atk: 1, def: 1 };
export function monStats(type, lv, elite) {
  const t = D.mons[type], e = elite ? ELITE : { hp: 1, atk: 1, def: 1 };
  // Boss Hoang Dã: theo đường cong quái thường cùng cấp, nhân hệ số lớn
  // trùm thế giới có cấp cố định (Ma Long: siêu mạnh, không phụ thuộc bản đồ xuất hiện)
  if (t.world && t.fixLv) lv = t.fixLv;
  if (t.world) return { hpMax: Math.round(monCurve(lv, 1) * t.hpm * mt(type, 'hp')), atk: monCurve(lv, 2) * t.atkm * mt(type, 'atk'), def: monCurve(lv, 3) * t.defm * mt(type, 'def') };
  if (t.boss) return { hpMax: Math.round(t.hp * (1 + .28 * (lv - 1)) * e.hp * mt(type, 'hp')), atk: t.atk * (1 + .12 * (lv - 1)) * e.atk * mt(type, 'atk'), def: (t.def + lv * .5) * e.def * mt(type, 'def') };
  const F = famOf(type);
  return { hpMax: Math.round(monCurve(lv, 1) * F.hp * e.hp * mt(type, 'hp')), atk: monCurve(lv, 2) * F.atk * e.atk * mt(type, 'atk'), def: monCurve(lv, 3) * F.def * e.def * mt(type, 'def') };
}
const monExpBase = (type, lv) => D.mons[type].boss ? D.mons[type].exp * (1 + .45 * (lv - 1)) : monCurve(lv, 4);
export const monExp = (type, lv, elite) => Math.round(monExpBase(type, lv) * (elite ? ELITE.exp : 1) * TUNE.exp * mt(type, 'exp') * (evOn() ? TUNE.ev.exp : 1));
export const monGold = (rng, type, lv, elite) => { const g = D.mons[type].gold; return Math.round(ri(rng, g[0], g[1]) * (1 + Math.floor(lv / 3)) * (elite ? ELITE.gold : 1) * TUNE.gold * mt(type, 'gold') * (evOn() ? TUNE.ev.gold : 1)); };
export const respawnTime = (rng, type) => D.mons[type].boss ? 90 : 9 + rng() * 5;
export const rollElite = (rng, type) => !D.mons[type].boss && rng() < TUNE.eliteChance;
// vật phẩm rơi khi hạ quái (tinh anh: tỉ lệ rơi đồ cao hơn và đồ hiếm dễ ra hơn, nhưng không phải lần nào cũng rơi)
export const ITEM_DROP = .25;
export function monDrops(rng, type, lv, cls, nextId, elite) {
  // 2.9.8: đồ rơi ít hơn nhiều (quái thường ~1/4 trước: 5–10%, tinh anh tối đa 30%); trùm giữ nguyên
  const t = D.mons[type], ds = [], dm = TUNE.drop * mt(type, 'drop') * (evOn() ? TUNE.ev.drop : 1), dc = Math.min(.95, (t.boss ? t.drop : elite ? Math.min(.3, t.drop * 1.2) : t.drop * ITEM_DROP) * dm);
  if (rng() < dc) ds.push({ k: 'item', item: genItem(rng, lv, t.boss ? 'boss' : elite ? 'elite' : 'mob', cls, nextId()) });
  if (t.boss) { ds.push({ k: 'item', item: genItem(rng, lv, 'boss', cls, nextId()) }); ds.push({ k: 'pot' }); ds.push({ k: 'pot' }); }
  if (t.boss && rng() < TUNE.wingChance * (evOn() ? TUNE.ev.drop : 1)) ds.push({ k: 'item', item: genItem(rng, lv, 'wing', cls, nextId()) });
  if (rng() < (elite ? .25 : .07)) ds.push({ k: 'pot' });
  // đá cường hóa khó có hơn (2.9.5); bùa kỹ năng cực hiếm, chỉ tinh anh và trùm
  const sn = t.boss ? ri(rng, 2, 4) : elite ? (rng() < .5 ? ri(rng, 1, 2) : 0) : (rng() < .05 + Math.min(.03, lv * .001) ? 1 : 0);
  if (t.boss ? rng() < (t.world ? .3 : .05) : elite && rng() < .012) ds.push({ k: 'charm', n: 1 });
  if (sn) ds.push({ k: 'stone', n: sn });
  return ds;
}

/* ---------- sát thương ---------- */
// người chơi đánh quái: raw = công * hệ số
export function dmgToMon(rng, raw, mdef, crit, dot, pen) {
  let d = dot ? raw : raw * (.9 + rng() * .2) - mdef * .4 * (1 - (pen || 0)), c = false;
  if (!dot && rng() < crit) { d *= 1.6; c = true; }
  return { d: Math.max(1, Math.round(d)), c };
}
// quái đánh người chơi
export const dmgToPlayer = (rng, raw, def, defMul, takeMul) => Math.max(1, Math.round((raw * (.88 + rng() * .24) - def * defMul * .5) * takeMul));

/* ---------- kỹ năng (mô tả bằng dữ liệu để máy chủ tự tính, ứng dụng chỉ vẽ hiệu ứng theo mã kỹ năng) ----------
   melee: đánh hình quạt quanh người  {r, half, m, kb}
   aoe:   vùng tròn tại tâm (self|tgt) {r, m, kb, stun, slow, pois:[giây, hệ số công/giây]}
   proj:  đạn {sp, m, r, range, pierce, splash, n, spread, ring}
   buff:  {id, t, atk, def, crit, spd, take}     heal: {f}
   dash:  lướt ngang {len, t, m, stun, back, end:{aoe}}
   zone:  vùng gây sát thương mỗi 0,5 giây {at, r, t, m, slow, pois}
   meteor: thiên thạch rơi trễ {at, pts:[[dx,dy,trễ]], r, m}
   chain: sét đánh n quái gần nhất {n, range, m, stun, step}
   rep:   lặp lại {n, every, fx:[...]} */
export const SKILL_FX = {
  sword: [
    [{ melee: { r: 120, half: 1.0, m: 2.0, kb: 220 } }],
    [{ melee: { r: 135, half: Math.PI, m: 2.4, kb: 320 } }],
    [{ buff: { id: 'shield', t: 8, def: 2 } }],
    [{ dash: { len: 290, t: .22, m: 2.6, stun: 1 } }],
    [{ buff: { id: 'roar', t: 10, atk: 1.4, crit: .15 } }, { aoe: { at: 'self', r: 230, m: .6, stun: 1, kb: 220 } }],
    [{ rep: { n: 3, every: .3, fx: [{ aoe: { at: 'self', r: 240, m: 3.3, kb: 260 } }] } }]],
  mage: [
    [{ proj: { sp: 520, m: 2.2, r: 13, range: 460, splash: 85 } }],
    [{ meteor: { at: 'tgt', d: 240, pts: [[0, 0, .6], [-80, 45, .8], [80, -35, 1.0]], r: 90, m: 2.6 } }],
    [{ zone: { at: 'tgt', d: 240, r: 150, t: 5, m: .6, slow: 1 } }, { aoe: { at: 'tgt', d: 240, r: 150, m: 1.4, slow: 2 } }],
    [{ chain: { n: 5, range: 480, m: 2.6, stun: .5, step: .08 } }],
    [{ buff: { id: 'ward', t: 7, take: .3 } }, { heal: { f: .2 } }],
    [{ zone: { at: 'tgt', d: 260, r: 230, t: 7, m: 1.3 } }, { meteor: { at: 'tgt', d: 260, pts: [[0, 0, .5], [-120, 60, .9], [120, 50, 1.3], [10, -110, 1.7]], r: 90, m: 3 } }]],
  archer: [
    [{ proj: { sp: 820, m: 2.6, r: 8, range: 540, pierce: 1 } }],
    [{ proj: { sp: 650, m: 1.3, r: 7, range: 460, pierce: 1, n: 9, spread: .175 } }],
    [{ zone: { at: 'tgt', d: 200, r: 130, t: 7, m: .3, slow: .6, pois: [3, .5] } }],
    [{ dash: { len: 250, t: .25, back: 1 } }, { buff: { id: 'roll', t: 3, spd: 1.35 } }, { delay: .12, fx: [{ proj: { sp: 760, m: 1.5, r: 7, range: 520, pierce: 1, n: 3, spread: .14 } }] }],
    [{ proj: { sp: 700, m: 4.2, r: 10, range: 560, splash: 140 } }],
    [{ rep: { n: 6, every: .28, fx: [{ proj: { sp: 620, m: 1.2, r: 7, range: 420, pierce: 1, n: 12, ring: 1 } }] } }]],
  fighter: [
    [{ melee: { r: 115, half: 1.2, m: 2.2, kb: 260 } }],
    [{ proj: { sp: 760, m: 3.4, r: 34, range: 620, pierce: 1 } }],
    [{ heal: { f: .3 } }, { buff: { id: 'zen', t: 6, def: 1.4 } }],
    [{ dash: { len: 150, t: .18, m: 1.6, stun: 1, end: { aoe: { at: 'front', r: 140, m: 2.4, stun: 1, kb: 340 } } } }],
    [{ aoe: { at: 'self', r: 250, m: 3.0, stun: 1.5, kb: 330 } }],
    [{ buff: { id: 'rage', t: 12, atk: 1.6, spd: 1.25, crit: .2 } }]]
};
// đánh thường theo phái
export const BASIC = {
  sword: { melee: { r: 85, half: 1.2, m: 1, kb: 150 } },
  fighter: { combo: 1 }, // 2 đòn nhẹ (r 64, x0.75) rồi 1 đòn nặng (r 95, x1.9)
  mage: { proj: { sp: 460, m: 1.15, r: 11, range: 400, splash: 55 } },
  archer: { proj: { sp: 700, m: .95, r: 7, range: 440 } }
};
// hệ số bùa: crit cộng dồn, còn lại nhân
export function buffMul(buffs, k) { let v = k === 'crit' ? 0 : 1; for (const b of buffs) { const x = b[k]; if (x == null) continue; if (k === 'crit') v += x; else v *= x; } return v; }

/* ---------- địa hình ---------- */
export function groundY(map, x) {
  const t = map.terr; if (!t) return D.world.gy; if (x <= t[0][0]) return t[0][1];
  let lo = 0, hi = t.length - 1; while (hi - lo > 1) { const m = (lo + hi) >> 1; if (t[m][0] <= x) lo = m; else hi = m; }
  const a = t[lo], b = t[hi]; return b[0] === a[0] ? b[1] : a[1] + (b[1] - a[1]) * clamp((x - a[0]) / (b[0] - a[0]), 0, 1);
}
export const inSafe = (map, x) => map.safes.some(z => x > z.x + 8 && x < z.x + z.w - 8);
/* ---------- bản đồ nhiều tầng (từ 2.7.0): bậc nổi, dây leo / thang, nước, dung nham ---------- */
// bậc nổi: [x0, y0, x1, y1, kiểu] (cầu có thể nghiêng); đứng được ở trên, nhảy xuyên từ dưới lên
export function platY(p, x) { return x < p[0] || x > p[2] ? null : p[1] + (p[3] - p[1]) * (p[2] === p[0] ? 0 : (x - p[0]) / (p[2] - p[0])); }
// mặt đứng gần nhất dưới chân (đất hoặc bậc nổi) tại x, khi chân đang ở độ cao y
export function floorY(map, x, y, tol) {
  const g = groundY(map, x); let best = g; tol = tol == null ? 6 : tol;
  for (const p of map.plats || []) { const py = platY(p, x); if (py != null && py >= y - tol && py < best) best = py; }
  return best;
}
// dây leo / thang: [x, yTrên, yDưới, kiểu]
export const onRope = (map, x, y) => (map.ropes || []).some(r => Math.abs(x - r[0]) < 34 && y >= r[1] - 14 && y <= r[2] + 14);
export const inWater = (map, x, y) => (map.water || []).some(w => x > w[0] && x < w[1] && y > w[2] - 4);
export const inLava = (map, x, y) => (map.lava || []).some(w => x > w[0] + 6 && x < w[1] - 6 && y > w[2] - 4);

/* ---------- nhân vật mới ---------- */
export function newChar(cls, name) {
  return { cls, name, lv: 1, exp: 0, gold: 0, pots: 2, potS: 5, potL: 0, kpots: 1, kpotS: 3, kpotL: 0, kills: 0, stones: 0, sk: [1, 0, 0, 0, 0, 0], books: [1, 0, 0, 0, 0, 0], inv: [], eq: { hat: null, armor: null, cape: null, weapon: null }, map: 0, mv: 2, pt: {}, ptReset: 0 };
}
// chuẩn hóa bản lưu cũ để máy chủ dùng: giữ nguyên mọi giá trị, chỉ thêm trường còn thiếu
export function normalizeChar(d) {
  const c = Object.assign(newChar(d.cls, d.name), d);
  // món hỏng không dùng được: cất riêng vào c.bad (vẫn lưu lại, không xóa)
  const bad = Array.isArray(c.bad) ? c.bad : [];
  c.inv = Array.isArray(c.inv) ? c.inv.filter(it => validItem(it) || (bad.push(it), false)) : [];
  const eq = c.eq && typeof c.eq === 'object' ? c.eq : {}; c.eq = {};
  for (const k of SLOTS) { c.eq[k] = validItem(eq[k]) && eq[k].slot === k ? eq[k] : null; if (eq[k] && !c.eq[k]) bad.push(eq[k]); }
  if (bad.length) c.bad = bad; else delete c.bad;
  for (const k of ['sk', 'books']) { const a = Array.isArray(c[k]) ? c[k] : []; c[k] = [0, 1, 2, 3, 4, 5].map(i => a[i] ? 1 : 0); c[k][0] = 1; }
  if (c.kpots == null) c.kpots = 3;
  if (!Array.isArray(c.skl) || c.skl.length !== 6) c.skl = [1, 1, 1, 1, 1, 1];
  c.skl = c.skl.map(v => Math.max(1, Math.min(SKILL_MAX, v | 0)));
  for (const k of ['lv', 'exp', 'gold', 'pots', 'kpots', 'potS', 'potL', 'kpotS', 'kpotL', 'kills', 'stones', 'charms']) c[k] = Math.max(0, Math.floor(+c[k] || 0));
  c.lv = Math.max(1, c.lv); c.map = clamp(c.map | 0, 0, D.maps.length - 1);
  // điểm tiềm năng: nhân vật cũ chưa có -> để trống (được cộng bù theo cấp hiện tại); điểm vượt quá số được nhận -> trả lại hết để cộng lại
  const pt = c.pt && typeof c.pt === 'object' ? c.pt : {}; c.pt = {};
  for (const k of PT_KEYS) { const v = Math.max(0, Math.min(PTS[k].max || 1e6, Math.floor(+pt[k] || 0))); if (v) c.pt[k] = v; }
  if (ptUsed(c) > ptTotal(c)) c.pt = {};
  c.ptReset = Math.max(0, Math.floor(+c.ptReset || 0));
  c.inv.forEach(it => fixItem(it, c.cls)); for (const k of SLOTS) fixItem(c.eq[k], c.cls);
  // pet (từ 2.9.0): tối đa PET_MAX con, pet đang ra trận, trứng đang ấp
  c.pets = (Array.isArray(c.pets) ? c.pets : []).filter(p => p && PET_SP[p.sp]).slice(0, PET_MAX).map(fixPet);
  if (!c.pets.some(p => p.id === c.petOn)) c.petOn = '';
  if (!c.pets.some(p => p.id === c.petLast)) c.petLast = c.petOn || '';
  if (!PET_MODES[c.petMode]) c.petMode = 'protect';
  c.hatch = c.hatch && PET_SP[c.hatch.sp] && +c.hatch.end > 0 ? { sp: c.hatch.sp, start: +c.hatch.start || 0, end: +c.hatch.end, cut: c.hatch.cut ? 1 : 0 } : null;
  // đồ khác phái đang mặc (bản cũ): đưa vào túi giống gear.js
  for (const k of SLOTS) { const it = c.eq[k]; if (it && !isFree(k) && it.cls !== c.cls) { c.eq[k] = null; c.inv.push(it); } }
  let n = 1; const seen = new Set();
  for (const it of [...c.inv, ...SLOTS.map(k => c.eq[k]).filter(Boolean)]) { if (it.id == null || seen.has(it.id)) it.id = 'o' + (n++); seen.add(it.id); }
  return c;
}
// bất thường trong bản lưu cũ: chỉ báo lại, không cắt dữ liệu
export function anomalies(c) {
  const a = [];
  if (c.lv > MAX_LV) a.push('lv>' + MAX_LV);
  if (c.inv.length > INV_MAX) a.push('inv=' + c.inv.length);
  if (c.pots > POT_MAX) a.push('pots=' + c.pots);
  if (c.gold > 5e6) a.push('gold=' + c.gold);
  if (c.bad) a.push('bad-items=' + c.bad.length);
  for (const it of [...c.inv, ...SLOTS.map(k => c.eq[k]).filter(Boolean)]) {
    if ((it.up || 0) > D.forge.max) a.push('up:' + it.name + '+' + it.up);
    const mx = maxItemStat(it); for (const k in it.st) if (it.st[k] > (mx[k] || 0)) { a.push('st:' + it.name + ':' + k + '=' + it.st[k]); break; }
  }
  return a;
}

/* ================= PET (từ 2.9.0) =================
 * Boss Hoang Dã rơi trứng (món 'egg' trong túi, giao dịch được, không bán cửa hàng) → ấp ở Bà Ấp Trứng → pet.
 * Pet theo chủ đánh quái, lên cấp bằng kinh nghiệm quái (chủ hưởng ké PET_SHARE), cộng điểm chỉ số ngẫu nhiên.
 */
export const PET_SP = {
  fire: { n: 'Rồng Lửa', bias: 'atk', el: 'fire', sk: ['Phóng Cầu Lửa', 'Phun Lửa', 'Hỏa Long Giáng Thế'] },
  ice: { n: 'Cáo Băng', bias: 'crit', el: 'ice', sk: ['Băng Tiễn', 'Gió Tuyết', 'Bão Băng Chín Đuôi'] },
  wolf: { n: 'Sói Sấm', bias: 'aspd', el: 'thunder', sk: ['Tia Chớp', 'Lôi Độn', 'Thiên Lôi Giáng'] },
  turtle: { n: 'Rùa Ngọc', bias: 'hp', el: 'jade', sk: ['Khiên Ngọc', 'Suối Hồi Phục', 'Thành Đồng Vách Sắt'] }
};
export const PET_KEYS = Object.keys(PET_SP);
// danh sách vật phẩm tặng được ở trang quản trị (không phải trang bị/sách). Thêm vật phẩm mới vào đây là trang quản trị tự có ô tặng.
export function giftMisc() {
  const L = [];
  POT_TIERS.forEach((t, i) => L.push({ k: HP_KEYS[i], n: 'Bình máu ' + t.n.toLowerCase(), max: POT_MAX, icon: 'admin-icons/misc/pot' + i + '.webp' }));
  POT_TIERS.forEach((t, i) => L.push({ k: KI_KEYS[i], n: 'Bình KI ' + t.n.toLowerCase(), max: POT_MAX, icon: 'admin-icons/misc/kpot' + i + '.webp' }));
  L.push({ k: 'charms', n: 'Bùa kỹ năng', max: 1e6, icon: 'admin-icons/misc/charm.webp' });
  L.push({ k: 'stones', n: 'Đá cường hóa', max: 1e6, icon: 'admin-icons/stone.webp' });
  L.push({ k: 'gold', n: 'Vàng', max: 1e10, icon: 'admin-icons/gold.webp' });
  L.push({ k: 'exp', n: 'Kinh nghiệm', max: 1e12 });
  for (const sp of PET_KEYS) L.push({ k: 'egg:' + sp, n: eggName(sp), max: 30, egg: sp, icon: 'admin-icons/egg/' + sp + '.webp' });
  return L;
}
// trạng thái pet (như đệ tử Ngọc Rồng): đi theo (không đánh), tấn công (đánh mọi quái quanh chủ), bảo vệ (đánh quái đang đánh chủ), về nhà (cất pet)
export const PET_MODES = { follow: 'Đi theo', attack: 'Tấn công', protect: 'Bảo vệ', home: 'Về nhà' };
// lệnh chat (bỏ dấu, bỏ khoảng trắng): ditheo/follow, tancong/attack, baove/protect, venha/gohome
export const PET_CMD = { ditheo: 'follow', follow: 'follow', tancong: 'attack', attack: 'attack', baove: 'protect', protect: 'protect', venha: 'home', gohome: 'home', home: 'home' };
export const petCmd = text => { const k = String(text || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'd').toLowerCase().replace(/[^a-z]/g, ''); return PET_CMD[k] || ''; };
export const PET_SAY = {
  follow: ['Vâng chủ nhân, em sẽ theo sát chủ nhân!', 'Em đi theo chủ nhân đây, không đánh quái nữa ạ.'],
  attack: ['Tuân lệnh! Em sẽ tấn công mọi con quái quanh đây!', 'Xông lên! Quái nào ở gần em cũng không tha!'],
  protect: ['Chủ nhân yên tâm, kẻ nào đánh chủ nhân em sẽ xử nó!', 'Em sẽ bảo vệ chủ nhân, quái nào đánh chủ nhân là em ra tay!'],
  home: ['Em về nhà nghỉ đây, khi nào cần cứ gọi em nhé!', 'Chào chủ nhân, em về chuồng đây ạ!']
};
export const PET_STAT = { hp: 'Máu', atk: 'Sức đánh', def: 'Giáp', aspd: 'Tốc đánh', crit: 'Chí mạng' };
// pet chỉ nhận kinh nghiệm theo phần máu quái do chính pet đánh mất; quái cao cấp hơn pet tính như quái đó ở cấp của pet; nhân TUNE.petExp (mặc định 1)
export const PET_EXP = 1;
// e: kinh nghiệm chủ nhận từ con quái (đã nhân phần chia khi đánh chung); quái cao cấp hơn pet: pet nhận như quái đó ở cấp của pet
export const petExpGain = (e, petLv, type, monLv, elite) => { const full = monExp(type, monLv, elite), same = monExp(type, Math.min(monLv, petLv), elite);
  return Math.max(1, Math.round(e * (full > 0 ? same / full : 1) * (TUNE.petExp != null ? TUNE.petExp : PET_EXP))); };
export const PET_MAX = 3, PET_SK_LV = [10, 40, 80], PET_SK_CD = [8, 15, 40], PET_REVIVE = 60, PET_SHARE = .1, PET_PT = 3;
export const HATCH_MS = 24 * 3600e3, HATCH_CUT = .5, HATCH_GOLD = 2000000;
export const STAR_MUL = [.8, .9, 1, 1.15, 1.3];
export const petStage = lv => lv >= 80 ? 2 : lv >= 40 ? 1 : 0;
export const eggName = sp => 'Trứng ' + PET_SP[sp].n;
export function newEgg(sp, id) { return { id, slot: 'egg', sp, name: eggName(sp), r: 3, col: '#ffb020', lvl: 1, st: {}, tier: 3, cls: '' }; }
export function fixPet(p) {
  const q = { id: String(p.id || ''), sp: p.sp, name: typeof p.name === 'string' && p.name ? p.name.slice(0, 12) : PET_SP[p.sp].n,
    lv: clamp(Math.floor(+p.lv || 1), 1, MAX_LV), exp: Math.max(0, Math.floor(+p.exp || 0)), star: clamp(p.star | 0 || 1, 1, 5), rn: p.rn ? 1 : 0, pt: {}, eq: p.eq && typeof p.eq === 'object' ? p.eq : {} };
  for (const k in PET_STAT) q.pt[k] = Math.max(0, Math.floor(+(p.pt && p.pt[k]) || 0));
  if (!q.id) q.id = 'p' + Math.floor(Math.random() * 1e9).toString(36);
  return q;
}
export function newPet(rng, sp, id) {
  const r = rng() * 100, star = r < 50 ? 1 : r < 78 ? 2 : r < 92 ? 3 : r < 98 ? 4 : 5; // pet ngon hiếm: 50/28/14/6/2 %
  const p = fixPet({ id, sp, lv: 1, star });
  for (let i = 0; i < PET_PT * 2; i++) petPoint(rng, p); // điểm khởi đầu ngẫu nhiên
  return p;
}
// một điểm chỉ số ngẫu nhiên: 50% vào chỉ số thiên hướng của loài, còn lại chia đều
export function petPoint(rng, p) { const ks = Object.keys(PET_STAT), k = rng() < .5 ? PET_SP[p.sp].bias : ks[Math.floor(rng() * ks.length)]; p.pt[k] = (p.pt[k] | 0) + 1; }
export function petStats(p) {
  const m = STAR_MUL[p.star - 1] || 1, L = p.lv, t = p.pt;
  return { maxHp: Math.round(80 + 22 * L + t.hp * 14 * m), atk: Math.round((5 + 1.5 * L + t.atk * 1.3 * m) * 10) / 10, def: Math.round((2 + .7 * L + t.def * .9 * m) * 10) / 10,
    aspd: Math.min(2.2, 1 + t.aspd * .012 * m), crit: Math.min(.5, .03 + t.crit * .003 * m) };
}
// cap: pet không vượt quá cấp chủ + 5
export function petAddExp(rng, p, n, cap = MAX_LV) {
  cap = Math.min(MAX_LV, cap);
  if (p.lv >= cap) { p.exp = Math.min(p.exp + n, expNeed(p.lv) - 1); return 0; }
  p.exp += n; let up = 0;
  while (p.lv < cap && p.exp >= expNeed(p.lv)) { p.exp -= expNeed(p.lv); p.lv++; up++; for (let i = 0; i < PET_PT; i++) petPoint(rng, p); }
  if (p.lv >= cap) p.exp = Math.min(p.exp, expNeed(p.lv) - 1);
  return up;
}
export const okPetName = s => typeof s === 'string' && s.trim().length >= 2 && s.trim().length <= 12 && /^[\p{L}\p{N} _]+$/u.test(s.trim());
