// Thao tác túi đồ, cửa hàng, học kỹ năng, lò rèn: máy chủ kiểm tra rồi mới đổi dữ liệu nhân vật.
// Mỗi hàm trả về { ok, msg, ...thêm } ; dữ liệu nhân vật mới gửi lại bằng tin 'me'.
import * as R from '../shared/rules.js';
import { refreshStats } from './sim.js';
const { D } = R;
const own = (ch, it) => !it.cls || it.cls === ch.cls;
const findInv = (ch, id) => ch.inv.findIndex(it => String(it.id) === String(id));
const nearNpc = (c, id) => { if (c.ch.map !== 0 || !c.inst) return false; const n = D.maps[0].npcs.find(q => q.id === id); return !!n && Math.abs(c.f.x - n.x) < 200; };
const ORD = { weapon: 0, armor: 1, hat: 2, cape: 3 };

export const OPS = {
  equip(c, m) {
    const ch = c.ch, i = findInv(ch, m.id); if (i < 0) return { ok: false, msg: 'Không có món này.' };
    const it = ch.inv[i]; if (!own(ch, it)) return { ok: false, msg: 'Không cùng phái.' };
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
    const g = R.sellPrice(ch.inv[i]); ch.gold += g; ch.inv.splice(i, 1); return { ok: true, gold: g };
  },
  sort(c) {
    const ch = c.ch; ch.inv.sort((a, b) => (own(ch, b) - own(ch, a)) || (b.r - a.r) || (ORD[a.slot] - ORD[b.slot]) || (b.lvl - a.lvl)); return { ok: true };
  },
  pot(c) {
    const ch = c.ch, f = c.f; if (f.dead > 0 || ch.pots <= 0 || f.hp >= f.maxHp || f.potCd > 0) return { ok: false };
    ch.pots--; f.potCd = R.POT_CD; const h = Math.round(f.maxHp * R.POT_HEAL); f.hp = Math.min(f.maxHp, f.hp + h);
    if (c.inst) c.inst.ev.push(['ph', c.id, h]); return { ok: true, heal: h };
  },
  buypot(c, m) {
    const ch = c.ch, n = (m.n | 0) === 5 ? 5 : 1, price = R.TUNE.potPrice * n;
    if (ch.gold < price || ch.pots + n > R.POT_MAX) return { ok: false, msg: ch.gold < price ? 'Không đủ vàng.' : 'Mang tối đa ' + R.POT_MAX + ' bình.' };
    ch.gold -= price; ch.pots += n; return { ok: true };
  },
  // NPC Thương Nhân Giáp: bán mọi loại đồ của mọi phái, chỉ số mặc định, cấp đồ theo cấp người chơi (bậc 5)
  shopbuy(c, m) {
    const ch = c.ch, cls = String(m.cls), slot = String(m.slot), r = m.r | 0;
    if (!R.CLS_KEYS.includes(cls) || !R.SLOTS.includes(slot) || r < 0 || r > 3) return { ok: false };
    if (!nearNpc(c, 'gear')) return { ok: false, msg: 'Hãy tới gần Thương Nhân Giáp trong Làng.' };
    if (ch.inv.length >= R.INV_MAX) return { ok: false, msg: 'Túi đầy.' };
    const lvl = R.shopLevel(ch.lv), price = R.shopPrice(lvl, r);
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
    if (!it) return { ok: false, msg: 'Không có món này.' };
    const f = R.forgeInfo(it);
    if ((it.up || 0) >= D.forge.max) return { ok: false, msg: 'Đã rèn tối đa.' };
    if (ch.gold < f.gold || ch.stones < f.stones) return { ok: false, msg: 'Thiếu vàng hoặc đá cường hóa.' };
    ch.gold -= f.gold; ch.stones -= f.stones;
    let res;
    if (Math.random() * 100 < f.rate) { it.up = f.L; res = { ok: true, win: 1, up: it.up, msg: 'Rèn thành công! ' + it.name + ' lên +' + f.L + '.' }; }
    else { const d = Math.min(f.drop, it.up || 0); it.up = (it.up || 0) - d; res = { ok: true, win: 0, up: it.up, msg: 'Thất bại! Mất ' + f.stones + ' đá' + (d ? ' và tụt ' + d + ' cấp (còn +' + it.up + ')' : '') + '.' }; }
    if (eq) refreshStats(c.f, ch, true);
    return res;
  }
};
