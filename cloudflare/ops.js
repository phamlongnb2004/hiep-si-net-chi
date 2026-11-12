// Thao tác túi đồ, cửa hàng, học kỹ năng, lò rèn: máy chủ kiểm tra rồi mới đổi dữ liệu nhân vật.
// Mỗi hàm trả về { ok, msg, ...thêm } ; dữ liệu nhân vật mới gửi lại bằng tin 'me'.
import * as R from '../shared/rules.js';
import { refreshStats } from './sim.js';
const { D } = R;
const own = (ch, it) => !it.cls || it.cls === ch.cls;
const findInv = (ch, id) => ch.inv.findIndex(it => String(it.id) === String(id));
const nearNpc = (c, id) => { if (c.ch.map !== 0 || !c.inst) return false; const n = D.maps[0].npcs.find(q => q.id === id); return !!n && Math.abs(c.f.x - n.x) < 200; };
const ORD = { weapon: 0, armor: 1, hat: 2, cape: 3, gloves: 4, boots: 5, neck: 6, ring: 7, earring: 8, belt: 9, charm: 10, wing: 11 };

export const OPS = {
  equip(c, m) {
    const ch = c.ch, i = findInv(ch, m.id); if (i < 0) return { ok: false, msg: 'Không có món này.' };
    const it = ch.inv[i]; if (it.slot === 'egg') return { ok: false, msg: 'Mang trứng tới Bà Ấp Trứng trong Làng để ấp.' };
    if (!own(ch, it)) return { ok: false, msg: 'Không cùng phái.' };
    if (ch.lv < R.reqLv(it)) return { ok: false, msg: 'Cần đạt cấp ' + R.reqLv(it) + ' để mặc món này.' };
    const old = ch.eq[it.slot]; ch.eq[it.slot] = it; ch.inv.splice(i, 1); if (old) ch.inv.push(old);
    refreshStats(c.f, ch, true); return { ok: true };
  },
  unequip(c, m) {
    const ch = c.ch, s = String(m.slot); if (!R.SLOTS.includes(s) || !ch.eq[s]) return { ok: false };
    if (ch.inv.length >= R.INV_MAX) return { ok: false, msg: 'Túi đầy.' };
    ch.inv.push(ch.eq[s]); ch.eq[s] = null; refreshStats(c.f, ch, true); return { ok: true };
  },
  sell(c, m) {
    const ch = c.ch, i = findInv(ch, m.id); if (i < 0) return { ok: false, msg: 'Không có món này.' };
    if (!nearNpc(c, 'gear')) return { ok: false, msg: 'Mang đồ tới Thương Nhân Giáp trong Làng để bán.' };
    if (ch.inv[i].slot === 'egg') return { ok: false, msg: 'Không bán được trứng cho cửa hàng.' };
    const g = R.sellPrice(ch.inv[i]); ch.gold += g; ch.inv.splice(i, 1); return { ok: true, gold: g };
  },
  // bán nhiều món một lần ở Thương Nhân Giáp (bỏ qua trứng)
  sellm(c, m) {
    const ch = c.ch; if (!nearNpc(c, 'gear')) return { ok: false, msg: 'Mang đồ tới Thương Nhân Giáp trong Làng để bán.' };
    const ids = Array.isArray(m.ids) ? m.ids.slice(0, R.INV_MAX).map(String) : [];
    let n = 0, g = 0;
    for (const id of ids) { const i = findInv(ch, id); if (i < 0 || ch.inv[i].slot === 'egg') continue; g += R.sellPrice(ch.inv[i]); ch.inv.splice(i, 1); n++; }
    if (!n) return { ok: false, msg: 'Chưa chọn món nào để bán.' };
    ch.gold += g; return { ok: true, gold: g, msg: 'Đã bán ' + n + ' món, nhận ' + g + ' vàng.' };
  },
  // vứt bỏ một món trong túi (mất hẳn); trứng pet không vứt được ở đây
  toss(c, m) {
    const ch = c.ch, i = findInv(ch, m.id); if (i < 0) return { ok: false, msg: 'Không có món này.' };
    if (ch.inv[i].slot === 'egg') return { ok: false, msg: 'Không vứt trứng được, hãy mang tới Bà Ấp Trứng.' };
    const it = ch.inv.splice(i, 1)[0]; return { ok: true, msg: 'Đã vứt ' + (it.name || 'món đồ') + '.' };
  },
  sort(c) {
    const ch = c.ch; ch.inv.sort((a, b) => (own(ch, b) - own(ch, a)) || (b.r - a.r) || (ORD[a.slot] - ORD[b.slot]) || (b.lvl - a.lvl)); return { ok: true };
  },
  // cộng điểm tiềm năng vào một chỉ số
  stat(c, m) {
    const ch = c.ch, k = String(m.k), n = Math.max(1, Math.min(100, m.n | 0)), P = R.PTS[k]; if (!P) return { ok: false };
    ch.pt = ch.pt || {}; const cur = ch.pt[k] | 0, free = R.ptFree(ch);
    if (free < n) return { ok: false, msg: free ? 'Chỉ còn ' + free + ' điểm.' : 'Hết điểm tiềm năng. Lên cấp để nhận thêm.' };
    if (P.max && cur + n > P.max) return { ok: false, msg: P.n + ' đã tối đa (' + P.max + ' điểm).' };
    ch.pt[k] = cur + n; refreshStats(c.f, ch, true); return { ok: true };
  },
  // tẩy điểm: trả lại toàn bộ điểm để cộng lại (lần đầu miễn phí)
  stat_reset(c) {
    const ch = c.ch, cost = R.resetCost(ch); if (!R.ptUsed(ch)) return { ok: false, msg: 'Chưa cộng điểm nào.' };
    if (ch.gold < cost) return { ok: false, msg: 'Tẩy điểm cần ' + cost + ' vàng.' };
    ch.gold -= cost; ch.pt = {}; ch.ptReset = (ch.ptReset | 0) + 1; refreshStats(c.f, ch, true); return { ok: true, cost };
  },
  pot(c, m) {
    const ch = c.ch, f = c.f; if (f.dead > 0 || f.hp >= f.maxHp || f.potCd > 0) return { ok: false };
    const t = m && m.k != null && (ch[R.HP_KEYS[m.k | 0]] | 0) > 0 ? m.k | 0 : R.pickPot(ch, R.HP_KEYS, f.maxHp - f.hp, f.maxHp); if (t < 0 || t > 2) return { ok: false };
    ch[R.HP_KEYS[t]]--; f.potCd = R.POT_CD; const h = R.potAmt(t, false); f.hp = Math.min(f.maxHp, f.hp + h);
    if (c.inst) c.inst.ev.push(['ph', c.id, h]); return { ok: true, heal: h };
  },
  kpot(c, m) {
    const ch = c.ch, f = c.f; if (f.dead > 0 || f.ki >= f.maxKi || f.kpCd > 0) return { ok: false };
    const t = m && m.k != null && (ch[R.KI_KEYS[m.k | 0]] | 0) > 0 ? m.k | 0 : R.pickPot(ch, R.KI_KEYS, f.maxKi - f.ki, f.maxKi); if (t < 0 || t > 2) return { ok: false };
    ch[R.KI_KEYS[t]]--; f.kpCd = R.KPOT_CD; const k = R.potAmt(t, true); f.ki = Math.min(f.maxKi, f.ki + k);
    return { ok: true, ki: k };
  },
  buypot(c, m) {
    // cỡ bình: tier 0 nhỏ, 1 vừa (mặc định, bản cũ), 2 lớn; chỉ mua ở Thương Nhân Bảo, số lượng tùy chọn
    if (!nearNpc(c, 'shop')) return { ok: false, msg: 'Về Thương Nhân Bảo trong Làng để mua bình.' };
    const ch = c.ch, n = Math.max(1, Math.min(R.POT_MAX, m.n | 0 || 1)), t = m.tier == null ? 1 : Math.max(0, Math.min(2, m.tier | 0)), ki = m.k === 'ki', key = (ki ? R.KI_KEYS : R.HP_KEYS)[t];
    const price = Math.round(R.POT_TIERS[t].p * R.TUNE.potPrice / R.POT_PRICE) * n, nm = (ki ? 'bình KI ' : 'bình máu ') + R.POT_TIERS[t].n.toLowerCase();
    if (ch.gold < price || (ch[key] | 0) + n > R.POT_MAX) return { ok: false, msg: ch.gold < price ? 'Không đủ vàng.' : 'Mỗi cỡ mang tối đa ' + R.POT_MAX + ' ' + nm + '.' };
    ch.gold -= price; ch[key] = (ch[key] | 0) + n; return { ok: true, msg: 'Đã mua ' + n + ' ' + nm + '.' };
  },
  // nâng cấp kỹ năng bằng bùa: cấp L lên L+1 cần L bùa, chắc chắn thành công
  skup(c, m) {
    const ch = c.ch, i = m.i | 0, S = D.skills[ch.cls][i]; if (!S) return { ok: false };
    if (!ch.sk[i]) return { ok: false, msg: 'Chưa học ' + S.n + '.' };
    const L = ch.skl[i] | 0 || 1; if (L >= R.SKILL_MAX) return { ok: false, msg: S.n + ' đã đạt cấp tối đa.' };
    const need = R.charmCost(L); if ((ch.charms | 0) < need) return { ok: false, msg: 'Cần ' + need + ' bùa, bạn đang có ' + (ch.charms | 0) + '.' };
    ch.charms -= need; ch.skl[i] = L + 1;
    return { ok: true, msg: S.n + ' lên cấp ' + (L + 1) + '! Sát thương +' + Math.round(R.SKILL_UP * L * 100) + '% so với cấp 1.' };
  },
  // hồi sinh: tại chỗ (mất vàng) hoặc về Làng ngay
  revive(c, m) {
    const ch = c.ch, f = c.f; if (!(f.dead > 0)) return { ok: false };
    if (m.here) {
      const cost = R.reviveCost(ch.lv); if (ch.gold < cost) return { ok: false, msg: 'Cần ' + cost + ' vàng để hồi sinh tại chỗ.' };
      ch.gold -= cost; f.dead = 0; f.hp = Math.round(f.maxHp * .6); f.ki = Math.max(f.ki, Math.round(f.maxKi * .5)); f.pois = null; f.slowT = 0; f.stunT = 0; f.buffs = [];
      if (c.inst) { c.inst.ev.push(['rv', c.id]); c.inst.sendPos(c, { respawn: 1 }); }
      return { ok: true, msg: 'Hồi sinh tại chỗ (-' + cost + ' vàng).' };
    }
    f.dead = .01; return { ok: true }; // về Làng ở lượt tính kế tiếp
  },
  // NPC Thương Nhân Giáp: bán mọi loại đồ của mọi phái, chỉ số mặc định, cấp đồ theo cấp người chơi (bậc 5)
  shopbuy(c, m) {
    const ch = c.ch, cls = String(m.cls), slot = String(m.slot), r = m.r | 0;
    if (!R.CLS_KEYS.includes(cls) || !R.DROP_SLOTS.includes(slot) || r !== 0) return { ok: false, msg: 'Cửa hàng chỉ bán đồ thường.' };
    if (!nearNpc(c, 'gear')) return { ok: false, msg: 'Hãy tới gần Thương Nhân Giáp trong Làng.' };
    if (ch.inv.length >= R.INV_MAX) return { ok: false, msg: 'Túi đầy.' };
    // chọn cấp đồ 1, 5, 10 … 100 (bản cũ không gửi lvl: theo cấp mình)
    const ql = m.lvl | 0, lvl = ql >= 1 ? (ql < 5 ? 1 : Math.min(R.MAX_LV, Math.round(ql / 5) * 5)) : R.shopLevel(ch.lv), price = R.shopPrice(lvl, r);
    if (ch.gold < price) return { ok: false, msg: 'Không đủ vàng.' };
    const it = R.shopItem(cls, slot, r, lvl, 's' + Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36));
    ch.gold -= price; ch.inv.push(it);
    return { ok: true, msg: 'Đã mua ' + it.name + ' (' + price + ' vàng).' };
  },
    book(c, m) {
    const ch = c.ch, i = m.i | 0, S = D.skills[ch.cls][i]; if (!S || ch.books[i]) return { ok: false };
    if (!nearNpc(c, 'shop')) return { ok: false, msg: 'Hãy tới gần Thương Nhân Bảo trong Làng.' };
    if (ch.gold < S.price) return { ok: false, msg: 'Không đủ vàng.' };
    ch.gold -= S.price; ch.books[i] = 1;
    return { ok: true, msg: 'Mua sách ' + S.n + ' (' + S.price + ' vàng)' + (ch.lv < S.req ? '. Đạt cấp ' + S.req + ' để học.' : '. Bấm Học ngay!') };
  },
  learn(c, m) {
    const ch = c.ch, i = m.i | 0, S = D.skills[ch.cls][i]; if (!S || !ch.books[i] || ch.sk[i] || ch.lv < S.req) return { ok: false };
    ch.sk[i] = 1; return { ok: true, msg: 'Đã học kỹ năng ' + S.n + '. Phím ' + (i + 1) + '.' };
  },
  forge(c, m) {
    const ch = c.ch; if (!nearNpc(c, 'smith')) return { ok: false, msg: 'Hãy tới gần Thợ Rèn Cương trong Làng.' };
    let it = null, eq = false;
    if (m.slot && R.SLOTS.includes(m.slot) && ch.eq[m.slot] && (m.id == null || String(ch.eq[m.slot].id) === String(m.id))) { it = ch.eq[m.slot]; eq = true; }
    else { const i = findInv(ch, m.id); if (i >= 0) it = ch.inv[i]; }
    if (!it || it.slot === 'egg') return { ok: false, msg: 'Không có món này.' };
    const f = R.forgeInfo(it);
    if ((it.up || 0) >= D.forge.max) return { ok: false, msg: 'Đã rèn tối đa.' };
    if (ch.gold < f.gold || ch.stones < f.stones) return { ok: false, msg: 'Thiếu vàng hoặc đá cường hóa.' };
    ch.gold -= f.gold; ch.stones -= f.stones;
    let res;
    if (Math.random() * 100 < f.rate) { it.up = f.L; res = { ok: true, win: 1, up: it.up, item: it.name, rar: it.r | 0, msg: 'Rèn thành công! ' + it.name + ' lên +' + f.L + '.' }; }
    else { const d = Math.min(f.drop, it.up || 0); it.up = (it.up || 0) - d; res = { ok: true, win: 0, up: it.up, msg: 'Thất bại! Mất ' + f.stones + ' đá' + (d ? ' và tụt ' + d + ' cấp (còn +' + it.up + ')' : '') + '.' }; }
    if (eq) refreshStats(c.f, ch, true);
    return res;
  },
  /* ---------- Bà Ấp Trứng & pet (2.9.0) ---------- */
  hatch_start(c, m) {
    const ch = c.ch; if (!nearNpc(c, 'egg')) return { ok: false, msg: 'Hãy tới gần Bà Ấp Trứng trong Làng.' };
    if (ch.hatch) return { ok: false, msg: 'Tổ ấp đang có trứng, mỗi lần chỉ ấp 1 quả.' };
    if (ch.pets.length >= R.PET_MAX) return { ok: false, msg: 'Chuồng đã đủ ' + R.PET_MAX + ' pet. Thả bớt pet để ấp thêm.' };
    const i = findInv(ch, m.id); if (i < 0 || ch.inv[i].slot !== 'egg') return { ok: false, msg: 'Không có quả trứng này.' };
    const egg = ch.inv[i], now = Date.now(); ch.inv.splice(i, 1);
    ch.hatch = { sp: egg.sp, start: now, end: now + R.HATCH_MS, cut: 0 };
    return { ok: true, msg: 'Bắt đầu ấp ' + egg.name + '. Trứng nở sau 24 giờ.' };
  },
  hatch_cut(c) {
    const ch = c.ch, h = ch.hatch; if (!nearNpc(c, 'egg')) return { ok: false, msg: 'Hãy tới gần Bà Ấp Trứng trong Làng.' };
    if (!h) return { ok: false, msg: 'Chưa ấp trứng nào.' };
    if (h.cut) return { ok: false, msg: 'Mỗi quả trứng chỉ được rút ngắn 1 lần.' };
    const now = Date.now(), left = h.end - now; if (left <= 0) return { ok: false, msg: 'Trứng đã sẵn sàng nở.' };
    if (ch.gold < R.HATCH_GOLD) return { ok: false, msg: 'Cần ' + R.HATCH_GOLD.toLocaleString('vi-VN') + ' vàng.' };
    ch.gold -= R.HATCH_GOLD; h.end = now + Math.ceil(left * (1 - R.HATCH_CUT)); h.cut = 1;
    return { ok: true, msg: 'Bà Ấp Trứng đã chúc phúc, thời gian ấp còn một nửa.' };
  },
  hatch_open(c) {
    const ch = c.ch, h = ch.hatch; if (!nearNpc(c, 'egg')) return { ok: false, msg: 'Hãy tới gần Bà Ấp Trứng trong Làng.' };
    if (!h) return { ok: false, msg: 'Chưa ấp trứng nào.' };
    if (Date.now() < h.end) return { ok: false, msg: 'Trứng chưa nở.' };
    if (ch.pets.length >= R.PET_MAX) return { ok: false, msg: 'Chuồng đã đủ ' + R.PET_MAX + ' pet.' };
    const p = R.newPet(Math.random, h.sp, 'p' + Date.now().toString(36) + Math.floor(Math.random() * 1e4).toString(36));
    ch.pets.push(p); ch.hatch = null; if (!ch.petOn) { ch.petOn = p.id; if (c.inst) c.inst.syncPet(c); }
    return { ok: true, sp: p.sp, star: p.star, pid: p.id, msg: 'Trứng đã nở! Bạn nhận được ' + p.name + ' ' + p.star + ' sao.' };
  },
  pet_on(c, m) {
    const ch = c.ch, id = String(m.id || '');
    if (id && !ch.pets.some(p => p.id === id)) return { ok: false, msg: 'Không có pet này.' };
    if (ch.petOn) ch.petLast = ch.petOn;
    ch.petOn = id === ch.petOn ? '' : id; if (ch.petOn) ch.petLast = ch.petOn; if (c.inst) c.inst.syncPet(c);
    return { ok: true, msg: ch.petOn ? 'Pet đã ra trận.' : 'Đã cất pet.' };
  },
  // đổi trạng thái pet (nút trong Hành Trang → Thú cưng, hoặc lệnh chat); pet nhắn lại cho chủ
  pet_mode(c, m) {
    const ch = c.ch, mode = String(m.mode || '');
    if (!R.PET_MODES[mode]) return { ok: false, msg: 'Trạng thái không hợp lệ.' };
    if (!ch.pets.length) return { ok: false, msg: 'Bạn chưa có pet. Ấp trứng ở Bà Ấp Trứng trong Làng.' };
    let p = ch.pets.find(q => q.id === ch.petOn);
    if (mode === 'home') {
      if (!p) return { ok: false, msg: 'Pet đang ở nhà rồi.' };
      ch.petLast = p.id; ch.petOn = '';
    } else {
      if (!p) { p = ch.pets.find(q => q.id === ch.petLast) || ch.pets[0]; ch.petOn = p.id; }
      ch.petMode = mode; ch.petLast = p.id;
    }
    if (c.inst) c.inst.syncPet(c);
    const L = R.PET_SAY[mode], say = L[Math.floor(Math.random() * L.length)];
    return { ok: true, mode, petSay: { t: 'chat', id: c.id, n: p.name, text: say, pet: 1, pm: 1, to: ch.name } };
  },
  pet_name(c, m) {
    const ch = c.ch, p = ch.pets.find(q => q.id === String(m.id || '')); if (!p) return { ok: false, msg: 'Không có pet này.' };
    if (p.rn) return { ok: false, msg: 'Mỗi pet chỉ được đổi tên miễn phí 1 lần.' };
    if (!R.okPetName(m.name)) return { ok: false, msg: 'Tên dài 2–12 ký tự, chỉ gồm chữ, số, khoảng trắng.' };
    p.name = m.name.trim(); p.rn = 1; if (c.inst) c.inst.syncPet(c, true);
    return { ok: true, msg: 'Đã đổi tên thành ' + p.name + '.' };
  },
  pet_free(c, m) {
    const ch = c.ch, i = ch.pets.findIndex(q => q.id === String(m.id || '')); if (i < 0) return { ok: false, msg: 'Không có pet này.' };
    const p = ch.pets[i]; if (String(m.confirm || '').trim() !== p.name) return { ok: false, msg: 'Nhập đúng tên pet để xác nhận.' };
    for (const k in p.eq) if (p.eq[k] && typeof p.eq[k] === 'object') ch.inv.push(p.eq[k]); // đồ pet trả về túi
    ch.pets.splice(i, 1); if (ch.petOn === p.id) ch.petOn = ''; if (c.inst) c.inst.syncPet(c);
    return { ok: true, msg: 'Đã thả ' + p.name + ' về tự nhiên.' };
  }
};
