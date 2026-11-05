// Lưu trữ: dùng Postgres khi có biến DATABASE_URL, nếu không thì dùng file JSON.
'use strict';
const fs = require('fs');
const path = require('path');

function fileStore(file) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  let data = { users: {}, sessions: {}, saves: {}, nextId: 1 };
  try { data = Object.assign(data, JSON.parse(fs.readFileSync(file, 'utf8'))); } catch (e) { /* file mới */ }
  let timer = null;
  const flush = () => {
    timer = null;
    const tmp = file + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(data));
    fs.renameSync(tmp, file);
  };
  const dirty = () => { if (!timer) timer = setTimeout(flush, 1500); };
  return {
    kind: 'file',
    async init() {},
    async findUser(name) { return data.users[name.toLowerCase()] || null; },
    async createUser(name, hash, salt) {
      const key = name.toLowerCase();
      if (data.users[key]) return null;
      const u = { id: data.nextId++, username: name, hash, salt, created: Date.now() };
      data.users[key] = u; dirty(); return u;
    },
    async userById(id) { return Object.values(data.users).find(u => u.id === id) || null; },
    async addSession(token, userId) { data.sessions[token] = { userId, created: Date.now() }; dirty(); },
    async sessionUser(token) { const s = data.sessions[token]; return s ? this.userById(s.userId) : null; },
    async dropSession(token) { delete data.sessions[token]; dirty(); },
    // Server 1 giữ khóa cũ (chỉ id) để bản lưu cũ vẫn dùng được
    async getSave(userId, srv = 1) { return data.saves[srv === 1 ? userId : userId + ':' + srv] || null; },
    async putSave(userId, save, srv = 1) { data.saves[srv === 1 ? userId : userId + ':' + srv] = save; dirty(); },
    async top(limit) {
      return Object.entries(data.saves).filter(([id]) => !String(id).includes(':'))
        .map(([id, s]) => ({ id: +id, name: s.name, cls: s.cls, lv: s.lv | 0, kills: s.kills | 0 }))
        .sort((a, b) => b.lv - a.lv || b.kills - a.kills).slice(0, limit);
    },
    async close() { if (timer) { clearTimeout(timer); flush(); } },
  };
}

function pgStore(url) {
  const { Pool } = require('pg');
  const pool = new Pool({ connectionString: url, ssl: /localhost|127\.0\.0\.1/.test(url) ? false : { rejectUnauthorized: false } });
  const q = (sql, args) => pool.query(sql, args);
  const row = r => r.rows[0] || null;
  const user = r => r && { id: r.id, username: r.username, hash: r.pass_hash, salt: r.salt };
  return {
    kind: 'postgres',
    async init() {
      await q(`CREATE TABLE IF NOT EXISTS users(id SERIAL PRIMARY KEY, username TEXT NOT NULL, uname TEXT UNIQUE NOT NULL, pass_hash TEXT NOT NULL, salt TEXT NOT NULL, created TIMESTAMPTZ DEFAULT now())`);
      await q(`CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, user_id INT REFERENCES users(id) ON DELETE CASCADE, created TIMESTAMPTZ DEFAULT now())`);
      await q(`CREATE TABLE IF NOT EXISTS saves(user_id INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE, data JSONB NOT NULL, updated TIMESTAMPTZ DEFAULT now())`);
    },
    async findUser(name) { return user(row(await q('SELECT * FROM users WHERE uname=$1', [name.toLowerCase()]))); },
    async createUser(name, hash, salt) {
      try { return user(row(await q('INSERT INTO users(username,uname,pass_hash,salt) VALUES($1,$2,$3,$4) RETURNING *', [name, name.toLowerCase(), hash, salt]))); }
      catch (e) { if (e.code === '23505') return null; throw e; }
    },
    async userById(id) { return user(row(await q('SELECT * FROM users WHERE id=$1', [id]))); },
    async addSession(token, userId) { await q('INSERT INTO sessions(token,user_id) VALUES($1,$2)', [token, userId]); },
    async sessionUser(token) { return user(row(await q('SELECT u.* FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=$1', [token]))); },
    async dropSession(token) { await q('DELETE FROM sessions WHERE token=$1', [token]); },
    // bản Postgres chỉ hỗ trợ Server 1
    async getSave(userId, srv = 1) { if (srv !== 1) return null; const r = row(await q('SELECT data FROM saves WHERE user_id=$1', [userId])); return r ? r.data : null; },
    async putSave(userId, save, srv = 1) { if (srv !== 1) return; await q('INSERT INTO saves(user_id,data,updated) VALUES($1,$2,now()) ON CONFLICT(user_id) DO UPDATE SET data=EXCLUDED.data, updated=now()', [userId, save]); },
    async top(limit) {
      const r = await q(`SELECT user_id id, data->>'name' name, data->>'cls' cls, COALESCE((data->>'lv')::int,0) lv, COALESCE((data->>'kills')::int,0) kills FROM saves ORDER BY lv DESC, kills DESC LIMIT $1`, [limit]);
      return r.rows;
    },
    async close() { await pool.end(); },
  };
}

module.exports = function makeStore() {
  if (process.env.DATABASE_URL) return pgStore(process.env.DATABASE_URL);
  return fileStore(process.env.DATA_FILE || path.join(__dirname, '..', 'data', 'db.json'));
};
