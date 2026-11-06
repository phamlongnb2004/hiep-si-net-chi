// Luật chơi dùng chung cho máy chủ (Cloudflare) và làm chuẩn để viết lại trong ứng dụng Godot.
// Dữ liệu số (phái, kỹ năng, quái, bản đồ...) nằm trong data.json, xuất từ bản game gốc bằng tools/export-shared-data.js.
// Mọi hàm ở đây là hàm thuần: không đọc giờ, không đọc DOM; số ngẫu nhiên truyền vào qua rng() (0..1).
import D from './data.json';
export { D };

export const MAX_LV = 60, INV_MAX = 30, POT_MAX = 20, GRAV = 2100, JUMP = 760, MAXSTEP = 105;
export const POT_HEAL = .45, POT_CD = 1, POT_PRICE = 30, DEATH_T = 2.6, SAFE_REGEN = .08;
// tên món theo phái (gear.js) và tỉ lệ hiếm khi rơi
export const NOUN = {
  sword: { hat: 'Mũ Giáp', armor: 'Giáp Kỵ Sĩ', cape: 'Áo Choàng', weapon: 'Kiếm' },
  archer: { hat: 'Mũ Trùm', armor: 'Áo Giáp Lá', cape: 'Áo Choàng', weapon: 'Cung' },
  mage: { hat: 'Nón Phép', armor: 'Pháp Bào', cape: 'Khăn Choàng', weapon: 'Trượng' },
  fighter: { hat: 'Khăn Đầu', armor: 'Võ Phục', cape: 'Khăn Choàng', weapon: 'Găng Vuốt' } };
export const W_MOB = [80, 16.5, 3.1, .4], W_BOSS = [30, 48, 18.5, 3.5];
export const SLOTS = ['hat', 'armor', 'cape', 'weapon'];
export const CLS_KEYS = ['sword', 'archer', 'mage', 'fighter'];

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const ri = (rng, a, b) => Math.floor(a + rng() * (b - a + 1));
const pickW = (rng, ws) => { let x = rng() * ws.reduce((a, b) => a + b), k = 0; for (; k < ws.length; k++) { x -= ws[k]; if (x < 0) break; } return Math.min(k, ws.length - 1); };

/* ---------- cấp, chỉ số ---------- */
export const expNeed = l => Math.floor(30 * Math.pow(l, 1.45));
export const itemStat = (it, k) => Math.round(((it.st && it.st[k]) || 0) * (1 + .12 * (it.up || 0)));
export const sellPrice = it => Math.round((4 + it.lvl * 2.2) * D.rar[it.r].m * (1 + .35 * (it.up || 0)));
export const score = it => it ? itemStat(it, 'atk') * 2 + itemStat(it, 'def') * 1.5 + itemStat(it, 'hp') * .1 + itemStat(it, 'spd') * .6 : 0;
// chỉ số gốc của nhân vật (chưa tính bùa tạm thời)
export function stats(ch) {
  const c = D.cls[ch.cls], l = ch.lv - 1;
  let hp = c.hp + c.hpG * l, atk = c.atk + c.atkG * l, def = c.def + c.defG * l, spd = c.spd;
  for (const k of SLOTS) { const it = ch.eq && ch.eq[k]; if (!it) continue; hp += itemStat(it, 'hp'); atk += itemStat(it, 'atk'); def += itemStat(it, 'def'); spd += itemStat(it, 'spd'); }
  return { maxHp: Math.round(hp), atk: Math.round(atk), def: Math.round(def), spd, crit: c.crit };
}
// cộng kinh nghiệm, trả về số cấp vừa lên
export function addExp(ch, n) {
  ch.exp += n; let up = 0;
  while (ch.lv < MAX_LV && ch.exp >= expNeed(ch.lv)) { ch.exp -= expNeed(ch.lv); ch.lv++; up++; }
  if (ch.lv >= MAX_LV) ch.exp = Math.min(ch.exp, expNeed(MAX_LV) - 1);
  return up;
}

/* ---------- đồ ---------- */
export function genItem(rng, lvl, boss, cls, id) {
  const c = rng() < .75 && D.sets[cls] ? cls : CLS_KEYS[ri(rng, 0, CLS_KEYS.length - 1)];
  const rk = pickW(rng, boss ? W_BOSS : W_MOB), R = D.rar[rk], m = R.m, base = 3 + lvl * 1.4, slot = SLOTS[Math.floor(rng() * 4)], st = {};
  if (slot === 'hat') { st.def = Math.round(base * .6 * m); st.hp = Math.round(base * 3 * m); }
  else if (slot === 'armor') { st.def = Math.round(base * m); st.hp = Math.round(base * 5 * m); }
  else if (slot === 'cape') { st.spd = Math.round((2 + lvl * .3) * m); st.def = Math.round(base * .4 * m); }
  else st.atk = Math.round(base * 1.3 * m);
  const it = { id, slot, cls: c, tier: rk, style: 0, col: R.c.length === 7 ? R.c : '#8a93a8', r: rk, lvl, name: NOUN[c][slot] + ' ' + D.sets[c][rk], st };
  if (slot === 'weapon') it.wk = c;
  return it;
}
// đồ cũ (trước khi có phái) thuộc về phái của nhân vật: giống fixIt trong gear.js
export function fixItem(it, cls) {
  if (!it) return;
  if (!D.sets[it.cls]) it.cls = D.sets[it.wk] ? it.wk : cls;
  it.tier = clamp(it.r | 0, 0, 3); if (it.slot === 'weapon') it.wk = it.cls;
}
export const validItem = it => !!(it && typeof it === 'object' && SLOTS.includes(it.slot) && it.st && typeof it.name === 'string' && D.rar[it.r] && typeof it.col === 'string' && /^#[0-9a-fA-F]{6}$/.test(it.col));
// chỉ số lớn nhất có thể có của một món (để đánh dấu bản lưu bất thường, không sửa)
export function maxItemStat(it) {
  const m = D.rar[3].m, base = 3 + (it.lvl || 1) * 1.4;
  return { atk: Math.round(base * 1.3 * m) + 1, def: Math.round(base * m) + 1, hp: Math.round(base * 5 * m) + 1, spd: Math.round((2 + (it.lvl || 1) * .3) * m) + 1 };
}

/* ---------- lò rèn ---------- */
export function forgeInfo(it) {
  const L = (it.up || 0) + 1;
  return { L, rate: D.forge.rate[L - 1], stones: 1 + Math.floor((L - 1) / 2), gold: Math.round((40 + it.lvl * 6) * Math.pow(L, 1.5)), drop: L <= 5 ? 0 : L <= 10 ? 1 : 2 };
}

/* ---------- quái ---------- */
export function monStats(type, lv) {
  const t = D.mons[type];
  return { hpMax: Math.round(t.hp * (1 + .28 * (lv - 1))), atk: t.atk * (1 + .12 * (lv - 1)), def: t.def + lv * .5 };
}
export const monExp = (type, lv) => Math.round(D.mons[type].exp * (1 + .45 * (lv - 1)));
export const monGold = (rng, type, lv) => { const g = D.mons[type].gold; return ri(rng, g[0], g[1]) * (1 + Math.floor(lv / 3)); };
export const respawnTime = (rng, type) => D.mons[type].boss ? 90 : 9 + rng() * 5;
// vật phẩm rơi khi hạ quái
export function monDrops(rng, type, lv, cls, nextId) {
  const t = D.mons[type], ds = [];
  if (rng() < t.drop) ds.push({ k: 'item', item: genItem(rng, lv, !!t.boss, cls, nextId()) });
  if (t.boss) { ds.push({ k: 'item', item: genItem(rng, lv, true, cls, nextId()) }); ds.push({ k: 'pot' }); ds.push({ k: 'pot' }); }
  if (rng() < .14) ds.push({ k: 'pot' });
  const sn = t.boss ? ri(rng, 5, 8) : (rng() < .34 + Math.min(.1, lv * .004) ? 1 : 0);
  if (sn) ds.push({ k: 'stone', n: sn });
  return ds;
}

/* ---------- sát thương ---------- */
// người chơi đánh quái: raw = công * hệ số
export function dmgToMon(rng, raw, mdef, crit, dot) {
  let d = dot ? raw : raw * (.9 + rng() * .2) - mdef * .4, c = false;
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

/* ---------- nhân vật mới ---------- */
export function newChar(cls, name) {
  return { cls, name, lv: 1, exp: 0, gold: 0, pots: 5, kills: 0, stones: 0, sk: [1, 0, 0, 0, 0, 0], books: [1, 0, 0, 0, 0, 0], inv: [], eq: { hat: null, armor: null, cape: null, weapon: null }, map: 0, mv: 2 };
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
  for (const k of ['lv', 'exp', 'gold', 'pots', 'kills', 'stones']) c[k] = Math.max(0, Math.floor(+c[k] || 0));
  c.lv = Math.max(1, c.lv); c.map = clamp(c.map | 0, 0, D.maps.length - 1);
  c.inv.forEach(it => fixItem(it, c.cls)); for (const k of SLOTS) fixItem(c.eq[k], c.cls);
  // đồ khác phái đang mặc (bản cũ): đưa vào túi giống gear.js
  for (const k of SLOTS) { const it = c.eq[k]; if (it && it.cls !== c.cls) { c.eq[k] = null; c.inv.push(it); } }
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
