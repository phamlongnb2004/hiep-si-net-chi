// Mô phỏng một bản đồ trên máy chủ (giao thức v2): quái, đòn đánh, kỹ năng, rơi đồ, kinh nghiệm, vàng.
// Máy chủ quyết định mọi kết quả; ứng dụng chỉ gửi thao tác (đi, đánh, dùng kỹ năng) và vẽ lại những gì máy chủ báo.
import * as R from '../shared/rules.js';
const { D } = R;
const TAU = Math.PI * 2;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const angDiff = (a, b) => { let d = a - b; while (d > Math.PI) d -= TAU; while (d < -Math.PI) d += TAU; return Math.abs(d); };
const rng = Math.random;
const rand = (a, b) => a + rng() * (b - a);
const BR_T = 1.75, BR_C = .5, BR_E = 1.35; // rồng khạc: tổng thời gian, hết lấy hơi, ngừng phun (giống side.js)
const MS = .76;                               // tỉ lệ vẽ quái trong side.js (dùng để ước chỗ miệng rồng)
const OWN_T = 20, DROP_LIFE = 75, PICK_R = 40;

// trạng thái chiến đấu của một người chơi (không lưu xuống cơ sở dữ liệu)
export function makeFighter(ch) {
  const s = R.stats(ch);
  return Object.assign(s, { hp: s.maxHp, ki: s.maxKi, lsAcc: 0, kiWarn: 0, buffs: [], cds: [0, 0, 0, 0, 0, 0], gcd: 0, atkCd: 0, potCd: 0, dead: 0, combo: 0, comboT: 0,
    x: 0, y: 0, face: 1, air: 0, mv: 0, sw: 0, moveAt: 0, dashT: 0, dashLen: 0 });
}
export const lookN = ch => { const t = it => it && it.cls === ch.cls ? clamp(it.tier | 0, 0, 3) : -1; return (t(ch.eq.armor) + 1) + 5 * (t(ch.eq.hat) + 1) + 25 * (t(ch.eq.cape) + 1); };
export function refreshStats(f, ch, keepRatio) {
  const s = R.stats(ch), ratio = f.maxHp > 1 ? f.hp / f.maxHp : 1, kr = f.maxKi > 1 ? f.ki / f.maxKi : 1;
  Object.assign(f, s); f.hp = keepRatio ? Math.max(1, Math.round(f.maxHp * ratio)) : f.maxHp; f.ki = keepRatio ? f.maxKi * kr : f.maxKi;
}

export class MapInst {
  // hooks: send(c,obj), dirty(c), log(c,text,col)
  constructor(srv, mi, hooks) {
    this.srv = srv; this.mi = mi; this.khu = 1; this.M = D.maps[mi]; this.h = hooks;
    this.players = new Map(); this.mons = []; this.drops = []; this.projs = []; this.timers = []; this.ev = [];
    this.seq = 1; this.tk = 0; this.spawnAll();
  }
  gY(x) { return R.groundY(this.M, x); }
  safe(x) { return R.inSafe(this.M, x); }
  spawnAll() {
    for (const s of this.M.spots) for (let i = 0; i < s.cnt; i++) {
      const x = s.cnt === 1 ? s.x + s.w / 2 : s.x + 80 + (s.w - 160) * (i + .5) / s.cnt + rand(-30, 30);
      const lv = Math.floor(rand(s.lv[0], s.lv[1] + 1)), el = R.rollElite(rng, s.mon), st = R.monStats(s.mon, lv, el), t = D.mons[s.mon];
      this.mons.push({ id: this.seq++, type: s.mon, t, lv, el, x, y: this.gY(x), sx: x, x0: s.x + 30, x1: s.x + s.w - 30, ...st, hp: st.hpMax,
        face: 1, state: 'idle', tgt: 0, cd: rand(0, 1), wind: 0, lunge: 0, shoot: rand(2, 4), br: null, dead: false, respawn: 0,
        wx: x, wt: 0, vx: 0, kx: 0, stun: 0, slow: 0, pois: null, hold: false, dmg: new Map() });
    }
  }
  // quái do GM gọi thêm (temp): chết là mất hẳn, không hồi sinh
  addMon(type, lv, x, temp) {
    x = clamp(x, 60, this.M.w - 60);
    const st = R.monStats(type, lv, false), t = D.mons[type];
    const m = { id: this.seq++, type, t, lv, el: false, x, y: this.gY(x), sx: x, x0: x - 300, x1: x + 300, ...st, hp: st.hpMax,
      face: 1, state: 'idle', tgt: 0, cd: rand(0, 1), wind: 0, lunge: 0, shoot: rand(2, 4), br: null, dead: false, respawn: 0,
      wx: x, wt: 0, vx: 0, kx: 0, stun: 0, slow: 0, pois: null, hold: false, dmg: new Map(), temp: !!temp };
    this.mons.push(m); this.ev.push(['nm', this.monInfo(m)]); return m;
  }
  monInfo(m) { return { id: m.id, type: m.type, lv: m.lv, el: m.el ? 1 : 0, hpMax: m.hpMax, x: Math.round(m.x), y: Math.round(m.y), hp: Math.round(m.hp), dead: m.dead ? 1 : 0 }; }
  dropInfo(d) { return { id: d.id, k: d.k, n: d.n || 0, x: Math.round(d.x), y: Math.round(d.y), item: d.item || null, own: d.own }; }
  join(c, x) {
    const f = c.f, p = x != null ? x : this.M.spawn.x; f.x = p; f.y = this.gY(p); f.air = 0; f.moveAt = Date.now();
    this.players.set(c.id, c);
    this.h.send(c, { t: 'map', m: this.mi, k: this.khu, x: Math.round(f.x), y: Math.round(f.y), mons: this.mons.map(m => this.monInfo(m)), drops: this.drops.map(d => this.dropInfo(d)) });
  }
  leave(c) { this.players.delete(c.id); for (const m of this.mons) if (m.tgt === c.id) { m.tgt = 0; if (m.state === 'chase') m.state = 'return'; } }

  /* ---------- di chuyển: ứng dụng gửi vị trí, máy chủ kiểm tra tốc độ, vách đất, độ cao nhảy ---------- */
  move(c, m) {
    const f = c.f; if (f.dead > 0) return;
    const now = Date.now(), dt = clamp((now - f.moveAt) / 1000, .02, 1); f.moveAt = now;
    let x = +m.x, y = +m.y; if (!Number.isFinite(x) || !Number.isFinite(y)) return;
    x = clamp(x, 40, this.M.w - 40);
    const spd = f.spd * R.buffMul(f.buffs, 'spd'), lim = spd * dt * 1.35 + 30 + (f.dashT > 0 ? f.dashLen : 0);
    let bad = false;
    if (Math.abs(x - f.x) > lim) { x = f.x + Math.sign(x - f.x) * lim; bad = true; }
    // vách: không đi xuyên qua khối đất cao hơn chân mình
    const dir = Math.sign(x - f.x), top = Math.min(f.y, y);
    if (dir) for (let s = f.x + dir * 8; dir > 0 ? s <= x : s >= x; s += dir * 8) if (this.gY(s) < top - 6) { x = s - dir * 8; bad = true; break; }
    const g = this.gY(x);
    if (y > g) y = g;
    if (y < g - 150) { y = g - 150; bad = true; }
    f.x = x; f.y = y; f.face = m.f < 0 ? -1 : 1; f.air = m.air ? 1 : 0; f.mv = m.mv ? 1 : 0;
    if (bad) { c.badMoves = (c.badMoves || 0) + 1; this.h.send(c, { t: 'pos', x: Math.round(f.x), y: Math.round(f.y) }); }
  }

  /* ---------- chiến đấu ---------- */
  patk(f) { return f.atk * R.buffMul(f.buffs, 'atk'); }
  alive() { return this.mons.filter(m => !m.dead); }
  findTarget(f, id, maxR) {
    let m = id ? this.mons.find(q => q.id === id && !q.dead) : null;
    if (m && Math.hypot(m.x - f.x, m.y - f.y) > maxR + 120) m = null;
    if (!m) { let bd = maxR; for (const q of this.mons) { if (q.dead) continue; const d = Math.hypot(q.x - f.x, q.y - f.y) - q.t.r; if (d < bd) { bd = d; m = q; } } }
    return m;
  }
  hitMon(c, m, raw, o) {
    if (m.dead) return 0; o = o || {}; const f = c.f;
    const r = R.dmgToMon(rng, raw, m.def, f.crit + R.buffMul(f.buffs, 'crit'), o.dot, f.pen);
    m.hp -= r.d;
    // hút máu: hồi theo sát thương gây ra (không tính độc)
    if (f.ls > 0 && !o.dot && f.hp > 0 && f.hp < f.maxHp) { f.lsAcc += Math.min(r.d, m.hp + r.d) * f.ls; if (f.lsAcc >= 1) { const h = Math.floor(f.lsAcc); f.lsAcc -= h; f.hp = Math.min(f.maxHp, f.hp + h); c.meDirty = true; } } m.dmg.set(c.id, (m.dmg.get(c.id) || 0) + r.d);
    if (o.kb) m.kx += Math.sign(m.x - f.x || f.face) * o.kb * (m.t.boss ? .15 : 1);
    if (m.state === 'idle') { m.state = 'chase'; m.tgt = c.id; }
    this.ev.push(['h', m.id, r.d, (r.c ? 1 : 0) | (o.dot ? 2 : 0), c.id]);
    if (m.hp <= 0) this.kill(m, c);
    return r.d;
  }
  status(m, o) {
    if (m.dead) return; const k = m.t.boss ? .35 : 1;
    if (o.stun) m.stun = Math.max(m.stun, o.stun * k);
    if (o.slow) m.slow = Math.max(m.slow, o.slow);
    if (o.pois) m.pois = { t: o.pois[0], dps: o.pois[1], acc: 0, by: o.by };
  }
  melee(c, aim, r, half, mult, kb) {
    const f = c.f; let n = 0;
    for (const m of this.mons) { if (m.dead) continue; const dx = m.x - f.x, dy = m.y - f.y; if (Math.hypot(dx, dy) > r + m.t.r) continue; if (half < Math.PI && angDiff(Math.atan2(dy, dx), aim) > half) continue; this.hitMon(c, m, this.patk(f) * mult, { kb }); n++; }
    return n;
  }
  aoe(c, x, y, r, mult, o) {
    for (const m of this.mons) { if (m.dead || Math.hypot(m.x - x, m.y - y) > r + m.t.r) continue; this.hitMon(c, m, this.patk(c.f) * mult, { kb: o.kb || 0 }); this.status(m, { ...o, by: c.id }); }
  }
  shoot(c, a, p, mult, ox, oy) {
    this.projs.push({ c, x: ox, y: oy, vx: Math.cos(a) * p.sp, vy: Math.sin(a) * p.sp, sp: p.sp, dmg: mult, r: p.r, range: p.range, trav: 0, pierce: !!p.pierce, splash: p.splash || 0, hit: new Set() });
  }
  later(t, fn) { this.timers.push({ t, fn }); }
  aimPoint(f, tgt, aim, d) { return tgt && !tgt.dead ? { x: tgt.x, y: tgt.y } : { x: clamp(f.x + Math.cos(aim) * d, 40, this.M.w - 40), y: f.y }; }
  // lướt ngang: dừng ở vách, đánh quái trên đường đi
  dash(c, aim, o) {
    const f = c.f, dir = (o.back ? -1 : 1) * (Math.cos(aim) >= 0 ? 1 : -1); let x = f.x;
    for (let s = 0; s < o.len; s += 10) { const nx = clamp(x + dir * 10, 40, this.M.w - 40); if (this.gY(nx) < f.y - 6) break; x = nx; }
    f.dashT = o.t + .4; f.dashLen = Math.abs(x - f.x);
    if (o.m) { const a = Math.min(f.x, x) - 60, b = Math.max(f.x, x) + 60; for (const m of this.mons) if (!m.dead && m.x + m.t.r > a && m.x - m.t.r < b && Math.abs(m.y - f.y) < 110) { this.hitMon(c, m, this.patk(f) * o.m, { kb: 180 }); this.status(m, { stun: o.stun }); } }
    const sx = f.x; f.x = x; f.y = Math.min(f.y, this.gY(x));
    if (o.end) this.later(o.t, () => { if (f.dead > 0) return; this.run(c, [o.end], aim, null, 0); });
    return sx;
  }
  run(c, list, aim, tgt, w) {
    const f = c.f;
    for (const e of list) {
      if (e.melee) this.melee(c, aim, e.melee.r, e.melee.half, e.melee.m, e.melee.kb);
      if (e.aoe) { const o = e.aoe, p = o.at === 'self' ? f : o.at === 'front' ? { x: f.x + Math.cos(aim) * 40, y: f.y } : this.aimPoint(f, tgt, aim, o.d || 240); this.aoe(c, p.x, p.y, o.r, o.m, o); }
      if (e.proj) { const p = e.proj, n = p.n || 1, mult = this.patk(f) * p.m;
        for (let i = 0; i < n; i++) { const a = p.ring ? w * .26 + i * TAU / n : aim - (n - 1) / 2 * (p.spread || 0) + i * (p.spread || 0); this.shoot(c, a, p, mult, f.x, f.y); } }
      if (e.buff) { const b = e.buff; f.buffs = f.buffs.filter(x => x.id !== b.id); f.buffs.push({ ...b, max: b.t }); }
      if (e.heal) { const h = Math.round(f.maxHp * e.heal.f); f.hp = Math.min(f.maxHp, f.hp + h); this.ev.push(['ph', c.id, h]); }
      if (e.dash) this.dash(c, aim, e.dash);
      if (e.zone) { const z = e.zone, p = this.aimPoint(f, tgt, aim, z.d || 240), mult = z.m, pois = z.pois ? [z.pois[0], this.patk(f) * z.pois[1]] : null;
        for (let k = 1; k <= Math.round(z.t / .5); k++) this.later(k * .5, () => this.aoe(c, p.x, p.y, z.r, mult, { slow: z.slow, pois })); }
      if (e.meteor) { const o = e.meteor, b = this.aimPoint(f, tgt, aim, o.d || 240), dmg = this.patk(f) * o.m;
        for (const q of o.pts) { const x = b.x + q[0], y = b.y + q[1]; this.later(q[2], () => { for (const m of this.mons) if (!m.dead && Math.hypot(m.x - x, m.y - y) < o.r + m.t.r) this.hitMon(c, m, dmg, { kb: 200 }); }); } }
      if (e.chain) { const o = e.chain, l = this.alive().filter(m => Math.hypot(m.x - f.x, m.y - f.y) < o.range).sort((p, q) => Math.hypot(p.x - f.x, p.y - f.y) - Math.hypot(q.x - f.x, q.y - f.y)).slice(0, o.n);
        l.forEach((m, i) => this.later(i * o.step, () => { if (m.dead) return; this.hitMon(c, m, this.patk(f) * o.m, { kb: 60 }); this.status(m, { stun: o.stun }); })); }
      if (e.rep) for (let i = 0; i < e.rep.n; i++) this.later(i * e.rep.every, () => { if (f.dead > 0 || !this.players.has(c.id)) return; this.run(c, e.rep.fx, aim, tgt, i); });
      if (e.delay) this.later(e.delay, () => { if (f.dead > 0 || !this.players.has(c.id)) return; this.run(c, e.fx, aim, tgt, 0); });
    }
  }
  attack(c, m) {
    const f = c.f, ch = c.ch, cl = D.cls[ch.cls]; if (f.dead > 0 || f.atkCd > .05) return;
    const tgt = this.findTarget(f, m.tg | 0, cl.reach + 20);
    const aim = tgt ? Math.atan2(tgt.y - f.y, tgt.x - f.x) : (f.face > 0 ? 0 : Math.PI);
    f.face = Math.cos(aim) >= 0 ? 1 : -1; f.atkCd = cl.cd;
    let big = 0;
    if (ch.cls === 'fighter') { f.combo++; f.comboT = .9; big = f.combo % 3 === 0 ? 1 : 0; this.melee(c, aim, big ? 95 : 64, 1.4, big ? 1.9 : .75, big ? 260 : 90); }
    else this.run(c, [R.BASIC[ch.cls]], aim, tgt, 0);
    this.ev.push(['a', c.id, +aim.toFixed(2), big]);
  }
  skill(c, m) {
    const f = c.f, ch = c.ch, i = m.i | 0, S = D.skills[ch.cls][i]; if (!S || f.dead > 0) return;
    if (!ch.sk[i]) return this.h.log(c, 'Chưa học ' + S.n + (ch.lv < S.req ? ' (cần cấp ' + S.req + ')' : ' — mua sách ở Thương Nhân trong Làng'), '#ffb347');
    if (f.cds[i] > .05 || f.gcd > .05) return;
    const cost = R.kiCost(ch.lv, i);
    if (f.ki < cost) { if (f.kiWarn <= 0) { f.kiWarn = 2; this.h.log(c, 'Không đủ KI (cần ' + cost + '). Chờ KI hồi hoặc cộng điểm vào KI.', '#7fc8ff'); } return; }
    f.ki -= cost; f.cds[i] = S.cd; f.gcd = D.world.gcd;
    const tgt = this.findTarget(f, m.tg | 0, 460), aim = tgt ? Math.atan2(tgt.y - f.y, tgt.x - f.x) : (f.face > 0 ? 0 : Math.PI);
    f.face = Math.cos(aim) >= 0 ? 1 : -1;
    const sx = f.x; this.run(c, R.SKILL_FX[ch.cls][i], aim, tgt, 0);
    this.ev.push(['s', c.id, i, +aim.toFixed(2), tgt ? tgt.id : 0, Math.round(sx)]);
    if (f.x !== sx) this.h.send(c, { t: 'pos', x: Math.round(f.x), y: Math.round(f.y), dash: 1 });
    c.meDirty = true;
  }
  hurt(c, raw) {
    const f = c.f; if (f.dead > 0 || f.dashT > .4) return;
    if (f.dodge > 0 && rng() < f.dodge) { this.ev.push(['pm', c.id]); return; } // né tránh
    const d = R.dmgToPlayer(rng, raw, f.def, R.buffMul(f.buffs, 'def'), R.buffMul(f.buffs, 'take'));
    f.hp -= d; this.ev.push(['p', c.id, d]); c.meDirty = true;
    if (f.hp <= 0) {
      f.hp = 0; f.dead = R.DEATH_T; const lost = Math.floor(c.ch.gold * .1); c.ch.gold -= lost; this.h.dirty(c);
      this.h.log(c, 'Bạn đã gục ngã' + (lost ? ' và mất ' + lost + ' vàng' : '') + '. Hồi sinh ở điểm an toàn...', '#d9345a');
      for (const m of this.mons) if (m.tgt === c.id) { m.tgt = 0; if (m.state === 'chase') m.state = 'return'; }
    }
  }
  // phần thưởng (kinh nghiệm, vàng, đồ rơi) thuộc về người đánh đòn cuối
  kill(m, killer) {
    m.dead = true; m.respawn = R.respawnTime(rng, m.type); m.state = 'idle'; m.kx = 0; m.vx = 0; m.br = null; m.stun = 0; m.slow = 0; m.pois = null; m.tgt = 0;
    const best = killer && this.players.has(killer.id) ? killer : null;
    m.dmg.clear(); this.ev.push(['k', m.id, best ? best.id : 0]);
    if (m.temp) { m.gone = true; return; } // quái GM gọi ra để thử: không cho kinh nghiệm, vàng, đồ (tránh lạm quyền)
    if (!best) return;
    const ch = best.ch, e = R.monExp(m.type, m.lv, m.el), g = R.monGold(rng, m.type, m.lv, m.el);
    ch.kills++; ch.gold += g;
    const up = R.addExp(ch, e);
    this.h.send(best, { t: 'gain', m: m.id, exp: e, gold: g });
    if (up) { refreshStats(best.f, ch, false); this.ev.push(['lv', best.id, ch.lv]); this.h.log(best, 'Lên cấp ' + ch.lv + ' · +' + up * R.PT_PER_LV + ' điểm tiềm năng (Túi đồ → Chỉ số)', '#ffd23f'); }
    for (const d of R.monDrops(rng, m.type, m.lv, ch.cls, () => 'i' + Date.now().toString(36) + (this.seq++), m.el)) {
      const o = { id: this.seq++, k: d.k, n: d.n, item: d.item, x: clamp(m.x + rand(-34, 34), 40, this.M.w - 40), y: 0, life: DROP_LIFE, own: best.id, ownT: OWN_T };
      o.y = this.gY(o.x); this.drops.push(o); this.ev.push(['d', this.dropInfo(o)]);
      if (d.item && d.item.r >= 2 && this.h.glog) this.h.glog('drop', best, 'Rơi ' + d.item.name + ' (' + D.rar[d.item.r].n + ') từ ' + m.t.n + ' cấp ' + m.lv + (m.el ? ' tinh anh' : ''));
    }
    best.meDirty = true; this.h.dirty(best);
  }
  pickup(c, d) {
    const ch = c.ch;
    if (d.k === 'pot') { if (ch.pots < R.POT_MAX) { ch.pots++; this.h.log(c, 'Nhặt được 1 bình máu', '#d9345a'); } else { ch.gold += 15; this.h.log(c, 'Đã đủ bình máu, đổi lấy 15 vàng', '#ffd23f'); } }
    else if (d.k === 'stone') { ch.stones += d.n; this.h.log(c, 'Nhặt được ' + d.n + ' Đá cường hóa', '#6fd0ff'); }
    else if (d.item) {
      if (ch.inv.length >= R.INV_MAX) { const g = R.sellPrice(d.item); ch.gold += g; this.h.log(c, 'Túi đầy, tự bán ' + d.item.name + ' được ' + g + ' vàng.', '#8a93a8'); }
      else { ch.inv.push(d.item); this.h.log(c, 'Nhặt được ' + d.item.name + ' (' + D.rar[d.item.r].n + ')', D.rar[d.item.r].c); }
    }
    this.ev.push(['g', d.id, c.id]); c.meDirty = true; this.h.dirty(c);
  }

  /* ---------- vòng lặp ---------- */
  tick(dt) {
    this.tk++;
    for (let i = this.timers.length - 1; i >= 0; i--) { const s = this.timers[i]; s.t -= dt; if (s.t <= 0) { this.timers.splice(i, 1); try { s.fn(); } catch (e) { console.error(e); } } }
    for (const c of this.players.values()) this.tickPlayer(c, dt);
    this.tickMons(dt); this.tickProjs(dt);
    if (this.mons.some(m => m.gone)) { for (const m of this.mons) if (m.gone) this.ev.push(['rm', m.id]); this.mons = this.mons.filter(m => !m.gone); }
    for (let i = this.drops.length - 1; i >= 0; i--) {
      const d = this.drops[i]; d.life -= dt; d.ownT -= dt;
      if (d.life <= 0) { this.drops.splice(i, 1); this.ev.push(['x', d.id]); continue; }
      for (const c of this.players.values()) { if (c.f.dead > 0 || (d.ownT > 0 && d.own !== c.id)) continue; if (Math.hypot(c.f.x - d.x, c.f.y - d.y) < PICK_R + 20) { this.drops.splice(i, 1); this.pickup(c, d); break; } }
    }
  }
  tickPlayer(c, dt) {
    const f = c.f;
    if (f.dead > 0) { f.dead -= dt; if (f.dead <= 0) { f.dead = 0; f.hp = f.maxHp; f.ki = f.maxKi; f.x = this.M.spawn.x; f.y = this.gY(f.x); f.buffs = []; this.h.send(c, { t: 'pos', x: Math.round(f.x), y: Math.round(f.y), respawn: 1 }); c.meDirty = true; } return; }
    f.atkCd = Math.max(0, f.atkCd - dt); f.gcd = Math.max(0, f.gcd - dt); f.potCd = Math.max(0, f.potCd - dt); f.dashT = Math.max(0, f.dashT - dt);
    for (let i = 0; i < 6; i++) if (f.cds[i] > 0) f.cds[i] = Math.max(0, f.cds[i] - dt);
    const nb = f.buffs.length; f.buffs = f.buffs.filter(b => (b.t -= dt) > 0); if (f.buffs.length !== nb) c.meDirty = true;
    f.comboT -= dt; if (f.comboT <= 0) f.combo = 0;
    f.kiWarn -= dt;
    if (f.ki < f.maxKi) { f.ki = Math.min(f.maxKi, f.ki + (f.maxKi * R.KI_REGEN + 1) * dt * (this.safe(f.x) ? 2 : 1)); if (this.tk % 5 === 0 || f.ki >= f.maxKi) c.meDirty = true; }
    if (this.safe(f.x) && f.hp < f.maxHp) { f.hp = Math.min(f.maxHp, f.hp + f.maxHp * R.SAFE_REGEN * dt); if (this.tk % 5 === 0) c.meDirty = true; }
  }
  // chọn người chơi gần nhất trong tầm của quái
  near(m, r) { let b = null, bd = r; for (const c of this.players.values()) { const f = c.f; if (c.hidden || f.dead > 0 || this.safe(f.x) || Math.abs(f.y - m.y) > 180) continue; const d = Math.abs(f.x - m.x); if (d < bd) { bd = d; b = c; } } return b; }
  tickMons(dt) {
    for (const m of this.mons) {
      if (m.dead) { m.respawn -= dt; if (m.respawn <= 0) { m.el = R.rollElite(rng, m.type); Object.assign(m, R.monStats(m.type, m.lv, m.el)); m.dead = false; m.hp = m.hpMax; m.x = m.sx; m.y = this.gY(m.x); m.vx = 0; m.state = 'idle'; this.ev.push(['r', m.id, Math.round(m.x), Math.round(m.y), m.el ? 1 : 0, m.hpMax]); } continue; }
      const px = m.x;
      m.cd -= dt; m.shoot -= dt; m.lunge = Math.max(0, m.lunge - dt);
      if (m.kx) { m.x = clamp(m.x + m.kx * dt, 30, this.M.w - 30); m.kx *= Math.pow(.02, dt); if (Math.abs(m.kx) < 4) m.kx = 0; }
      if (m.slow > 0) m.slow -= dt;
      if (m.pois) { const q = m.pois; q.t -= dt; q.acc += dt; if (q.acc >= .5) { q.acc -= .5; const c = this.players.get(q.by); if (c) this.hitMon(c, m, q.dps * .5, { dot: true }); } if (q.t <= 0) m.pois = null; if (m.dead) continue; }
      let want = 0; const spd = m.t.spd * (m.slow > 0 ? .4 : 1);
      if (m.stun > 0) { m.stun -= dt; m.vx *= Math.pow(.001, dt); m.br = null; }
      else {
        let tc = m.tgt ? this.players.get(m.tgt) : null;
        if (tc && (tc.f.dead > 0 || this.safe(tc.f.x))) { tc = null; m.tgt = 0; }
        const home = Math.abs(m.x - m.sx);
        if (m.state === 'idle') {
          m.wt -= dt; if (m.wt <= 0) { m.wt = rand(2, 4.5); m.wx = clamp(m.sx + rand(-150, 150), m.x0, m.x1); }
          const d = m.wx - m.x; if (Math.abs(d) > 10) want = Math.sign(d) * spd * .35;
          const c = this.near(m, m.t.aggro); if (c) { m.state = 'chase'; m.tgt = c.id; }
        } else if (m.state === 'chase') {
          if (!tc || home > 700) { m.state = 'return'; m.tgt = 0; }
          else {
            const f = tc.f, dx = f.x - m.x, adx = Math.abs(dx);
            if (m.hold && adx > m.t.range * 1.05) m.hold = false; else if (!m.hold && adx < m.t.range * .75) m.hold = true;
            if (!m.hold && !m.br) want = Math.sign(dx) * spd;
            if (adx > 2 && !m.br) m.face = dx >= 0 ? 1 : -1;
            if (Math.hypot(dx, f.y - m.y) <= m.t.range + 14 && m.cd <= 0 && !(m.wind > 0)) { m.cd = m.t.cd; m.wind = .24; }
            if (m.wind > 0) { m.wind -= dt; m.hold = true; if (m.wind <= 0) { m.lunge = .25; this.ev.push(['ma', m.id, tc.id]); if (Math.hypot(f.x - m.x, f.y - m.y) <= m.t.range + 30) this.hurt(tc, m.atk); } }
            if (m.t.kind === 'dragon' && m.shoot <= 0 && !m.br && adx < 500 && adx > 120) { m.shoot = 3.6; m.br = { t: 0, hit: 0, reach: 0, tgt: tc.id }; this.ev.push(['b', m.id, tc.id]); }
          }
        } else {
          const d = m.sx - m.x; want = Math.sign(d) * spd * 1.2; m.hp = Math.min(m.hpMax, m.hp + m.hpMax * .25 * dt);
          if (Math.abs(d) < 12) { m.state = 'idle'; m.hp = m.hpMax; want = 0; }
        }
        m.vx += (want - m.vx) * Math.min(1, dt * 7); if (Math.abs(m.vx) < 3 && want === 0) m.vx = 0;
      }
      m.x = clamp(m.x + m.vx * dt, 30, this.M.w - 30);
      if (Math.abs(this.gY(m.x) - this.gY(px)) > 6) { m.x = px; m.vx = 0; m.kx = 0; } // không leo/nhảy bậc đất
      m.y = this.gY(m.x);
      if (m.br) this.tickBreath(m, dt);
    }
    // quái không đứng chồng lên nhau
    const L = this.mons; for (let i = 0; i < L.length; i++) { const m = L[i]; if (m.dead) continue; for (let j = i + 1; j < L.length; j++) { const o = L[j]; if (o.dead) continue; const ddx = o.x - m.x, min = (m.t.r + o.t.r) * .55; if (Math.abs(ddx) < min) { const p = (min - Math.abs(ddx)) * .5 * (ddx >= 0 ? 1 : -1) * Math.min(1, dt * 10); if (Math.abs(this.gY(m.x - p) - this.gY(m.x)) < 6) m.x -= p; if (Math.abs(this.gY(o.x + p) - this.gY(o.x)) < 6) o.x += p; } } }
  }
  // rồng khạc: luồng thẳng từ miệng tới người chơi, gây sát thương 4 lần/giây khi đang phun
  tickBreath(m, dt) {
    const b = m.br; b.t += dt; if (b.t >= BR_T) { m.br = null; return; }
    const c = this.players.get(b.tgt); if (!c) return;
    const f = c.f; if (b.t < BR_C) m.face = f.x >= m.x ? 1 : -1;
    const H = (m.t.h || 200) / .94 * MS, mo = { x: m.x + m.face * H * .72 * MS, y: m.y + (-70 * MS) - H * .58 };
    let a = Math.atan2(f.y - 28 - mo.y, (f.x - mo.x) * m.face); a = clamp(a, -.15, 1.05);
    const L = clamp(Math.hypot(f.x - mo.x, f.y - 28 - mo.y) + 80, 260, 620), gdx = Math.cos(a) * m.face, gdy = Math.sin(a);
    if (b.t > BR_C && b.t < BR_E) {
      b.reach = Math.min(L, b.reach + dt * L * 3.2); b.hit -= dt;
      if (b.hit <= 0 && f.dead <= 0 && !this.safe(f.x)) {
        const px = f.x - mo.x, py = f.y - 30 - mo.y, along = px * gdx + py * gdy, across = Math.abs(-px * gdy + py * gdx);
        if (along > 0 && along < b.reach + 20 && across < 24 + along * .16) { b.hit = .25; this.hurt(c, m.atk * .42); }
      }
    }
  }
  tickProjs(dt) {
    for (let i = this.projs.length - 1; i >= 0; i--) {
      const p = this.projs[i]; p.x += p.vx * dt; p.y += p.vy * dt; p.trav += p.sp * dt; let dead = p.trav >= p.range;
      if (!this.players.has(p.c.id)) dead = true;
      else for (const m of this.mons) {
        if (m.dead || p.hit.has(m.id)) continue;
        if (Math.hypot(m.x - p.x, m.y - p.y) < m.t.r + p.r) {
          p.hit.add(m.id); this.hitMon(p.c, m, p.dmg, { kb: 80 });
          if (p.splash) for (const o of this.mons) { if (o === m || o.dead) continue; if (Math.hypot(o.x - p.x, o.y - p.y) < p.splash + o.t.r) this.hitMon(p.c, o, p.dmg * .6, { kb: 60 }); }
          if (!p.pierce) { dead = true; break; }
        }
      }
      if (dead) this.projs.splice(i, 1);
    }
  }
  // ảnh chụp trạng thái gửi 10 lần/giây
  snap(extra) {
    const p = [];
    for (const c of this.players.values()) { if (c.hidden) continue; const f = c.f, ch = c.ch; p.push([c.id, Math.round(f.x), Math.round(f.y), f.face, f.mv, f.atkCd > 0 ? 1 : 0, ch.cls, ch.lv, ch.name, +(f.hp / f.maxHp).toFixed(3), f.dead > 0 ? 1 : 0, lookN(ch), f.air, ch.eq.wing ? ch.eq.wing.r | 0 : -1]); }
    if (extra) p.push(...extra);
    const m = [];
    for (const q of this.mons) m.push([q.id, Math.round(q.x), Math.round(q.y), Math.max(0, Math.round(q.hp)), q.face,
      (q.dead ? 1 : 0) | (q.stun > 0 ? 2 : 0) | (q.slow > 0 ? 4 : 0) | (q.pois ? 8 : 0) | (q.lunge > 0 ? 16 : 0) | (q.br ? 32 : 0) | (Math.abs(q.vx) > 12 ? 64 : 0)]);
    const ev = this.ev; this.ev = [];
    return { t: 'snap', tk: this.tk, p, m, e: ev };
  }
}
