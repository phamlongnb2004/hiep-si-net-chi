// Xuất dữ liệu luật chơi (sau khi mọi module side/gear đã ghi đè) ra shared/data.json
// Dùng: node tools/export-shared-data.js public/<bản-build>.html
const {chromium}=require('playwright');const fs=require('fs'),path=require('path');
(async()=>{
  const src=path.resolve(process.argv[2]||'public/index.html');
  const b=await chromium.launch();const pg=await b.newPage();
  // game nằm trong một hàm đóng: chèn hàm xuất dữ liệu ngay trước đoạn khởi động
  const anchor="\nnew ResizeObserver(resize).observe($('app'));";let html=fs.readFileSync(src,'utf8');
  if(html.split(anchor).length!==2)throw new Error('không thấy điểm chèn');
  const tmp=path.join(require('os').tmpdir(),'hsnc-dump.html');
  html=html.replace(anchor,()=>'\nwindow.__DUMP=()=>'+DUMP+';'+anchor);fs.writeFileSync(tmp,html);
  await pg.goto('file://'+tmp);await pg.waitForTimeout(1500);
  const d=await pg.evaluate(()=>window.__DUMP());
  fs.unlinkSync(tmp);
  await b.close();
  for(const k in d.cls){const c=d.cls[k];d.cls[k]={n:c.n,desc:c.desc,hp:c.hp,hpG:c.hpG,atk:c.atk,atkG:c.atkG,def:c.def,defG:c.defG,spd:c.spd,cd:c.cd,reach:c.reach,crit:c.crit};}
  fs.writeFileSync('shared/data.json',JSON.stringify(d,null,1));
  console.log('ok',Object.keys(d.mons).length,'quái,',d.maps.length,'bản đồ,',fs.statSync('shared/data.json').size,'byte');
})();
const DUMP=`(()=>{
    const pickMap=M=>({name:M.name,lv:M.lv,w:M.w,h:M.h,theme:M.theme,village:!!M.village,spawn:M.spawn,
      safes:M.safes.map(s=>({x:s.x,w:s.w,name:s.name})),
      spots:M.spots.map(s=>({n:s.n,mon:s.mon,lv:s.lv,cnt:s.cnt,x:s.x,w:s.w})),
      npcs:(M.npcs||[]).map(n=>({id:n.id,x:n.x,y:n.y,name:n.name,role:n.role})),
      portals:M.portals.map(p=>({x:p.x,y:p.y,to:p.to,tx:p.tx,ty:p.ty,label:p.label,lv:p.lv})),
      houses:M.houses||[],fountain:M.fountain||null,terr:M.terr});
    const mons={};for(const k in MT){const t=MT[k];mons[k]={n:t.n,kind:t.kind,hp:t.hp,atk:t.atk,def:t.def,exp:t.exp,gold:t.gold,aggro:t.aggro,cd:t.cd,drop:t.drop,boss:!!t.boss,r:t.r,h:t.h,range:t.range,spd:t.spd};}
    return {version:2,world:{gy:window.HSNC_GY,gcd:GCD},cls:CLS,skills:SKILLS,rar:RAR.map(r=>({n:r.n,c:r.c,m:r.m,w:r.w})),
      forge:{rate:FORGE_RATE,max:FORGE_MAX},sets:window.SETN_,slots:SLOT_ORDER,mons,maps:MAPS.map(pickMap)};
  })()`;
