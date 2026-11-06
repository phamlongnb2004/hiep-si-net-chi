// Tách toàn bộ ảnh nhúng (data:image/...) trong bản game ra file riêng cho ứng dụng Godot, kèm file mô tả (khung, tâm, tỉ lệ).
// Dùng: node tools/export-godot-assets.js public/<bản-build>.html client/assets
const {chromium}=require('playwright');const fs=require('fs'),path=require('path'),crypto=require('crypto');
(async()=>{
  const src=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]||'client/assets');
  const b=await chromium.launch();const pg=await b.newPage();await pg.goto('file://'+src);await pg.waitForTimeout(1500);
  const G=await pg.evaluate(()=>{const o={};for(const k of ['UI','ANIM','HUD','SIDE','MON','GEAR','LAYER','FX'])o[k.toLowerCase()]=window['HSNC_'+k]||{};
    const ai=window.HSNC_AI||{};o.ai={};for(const k in ai){const a=ai[k];if(a&&a.i&&a.i.src)o.ai[k]={u:a.i.src,w:a.w,h:a.h};}return o;});
  await b.close();
  let n=0,bytes=0;const seen=new Map();
  const walk=(v,p)=>{
    if(typeof v==='string'&&/^data:image\//.test(v)){
      const m=v.match(/^data:image\/(\w+);base64,(.*)$/);if(!m)return v;
      const buf=Buffer.from(m[2],'base64'),h=crypto.createHash('sha1').update(buf).digest('hex').slice(0,10);
      if(seen.has(h))return seen.get(h);
      const rel=p.join('/').replace(/[^\w\/.-]/g,'_')+'.'+(m[1]==='jpeg'?'jpg':m[1]);
      fs.mkdirSync(path.dirname(path.join(out,rel)),{recursive:true});fs.writeFileSync(path.join(out,rel),buf);n++;bytes+=buf.length;seen.set(h,rel);return rel;}
    if(Array.isArray(v))return v.map((x,i)=>walk(x,[...p,String(i)]));
    if(v&&typeof v==='object'){const o={};for(const k in v)o[k]=walk(v[k],[...p,k]);return o;}
    return v;};
  const meta={};for(const g in G)meta[g]=walk(G[g],[g]);
  fs.writeFileSync(path.join(out,'assets.json'),JSON.stringify(meta));
  console.log('ok',n,'ảnh',(bytes/1048576).toFixed(1),'MB');
})();
