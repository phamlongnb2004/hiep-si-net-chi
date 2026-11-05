
/* ===== GÓC NHÌN NGANG (kiểu game nhập vai cuộn ngang): mặt đất nằm ngang, đi trái/phải, nhảy, bậc đá, nền nhiều lớp ===== */
try{
const SA=window.HSNC_SIDE||{};
const GY=600,WH=720;                 // y của mặt đất (chân nhân vật), chiều cao thế giới
const GRAV=2100,JUMP=760;            // trọng lực, lực nhảy (nhảy cao ~135)
window.HSNC_GY=GY;
const SI={};
for(const k in SA){const im=new Image();im.src=SA[k].u;SI[k]={i:im,w:SA[k].w,h:SA[k].h,top:SA[k].top||0};}
const S=k=>{const a=SI[k];return a&&a.i.complete&&a.i.naturalWidth?a:null;};

/* --- bản đồ dạng dải ngang --- */
const R=(x,w)=>({x,y:0,w,h:WH});
const spotsRow=(x0,list,w)=>list.map((s,i)=>Object.assign({x:x0+i*w,y:0,w:w-40,h:WH},s));
const plats=(spots)=>{const a=[];spots.forEach((s,i)=>{a.push({x:s.x+s.w*.18,y:GY-125,w:230});if(i%2===0)a.push({x:s.x+s.w*.55,y:GY-245,w:190});else a.push({x:s.x+s.w*.62,y:GY-125,w:200});});return a;};
const M0={name:'Làng Hiệp Sĩ',lv:'Khu an toàn',w:2600,h:WH,theme:'grass',base:'#5c9e3f',village:true,spawn:{x:1300,y:GY},
  safes:[Object.assign(R(0,2600),{name:'Làng Hiệp Sĩ'})],spots:[],
  npcs:[{id:'shop',x:880,y:GY,name:'Thương Nhân Bảo',role:'Cửa hàng · Sách kỹ năng'},{id:'smith',x:1720,y:GY,name:'Thợ Rèn Cương',role:'Lò rèn · Cường hóa đồ'}],
  houses:[[230,0],[520,1],[2080,2],[2370,3]],fountain:1300,platforms:[{x:330,y:GY-130,w:220},{x:2160,y:GY-130,w:220}],
  portals:[{x:2540,y:GY,to:1,tx:200,ty:GY,label:'Đồng Bằng Khởi Nguyên',lv:'Cấp 1-11',col:'#9be05a'}]};
const sp1=spotsRow(700,[
  {n:'Bãi Heo Rừng',mon:'boar',lv:[1,3],cnt:6,col:'#c6e3a0'},
  {n:'Đồi Heo Nanh Đen',mon:'boar2',lv:[3,5],cnt:6,col:'#b4d98f'},
  {n:'Rừng Sói Xám',mon:'wolf',lv:[5,7],cnt:6,col:'#bcd9cf'},
  {n:'Thung Sói Đêm',mon:'wolf2',lv:[7,9],cnt:6,col:'#a9c8d4'},
  {n:'Hang Gấu Nâu',mon:'bear',lv:[9,11],cnt:5,col:'#e6caa0'}],860);
const M1={name:'Đồng Bằng Khởi Nguyên',lv:'Cấp 1-11',w:5400,h:WH,theme:'grass',base:'#5c9e3f',spawn:{x:260,y:GY},
  safes:[Object.assign(R(0,600),{name:'Làng Khởi Đầu'}),Object.assign(R(5060,340),{name:'Cổng Rừng Tuyết'})],spots:sp1,platforms:plats(sp1),
  houses:[[150,1],[430,2]],
  portals:[{x:60,y:GY,to:0,tx:2440,ty:GY,label:'Làng Hiệp Sĩ',lv:'Khu an toàn',col:'#ffd23f'},{x:5340,y:GY,to:2,tx:200,ty:GY,label:'Rừng Tuyết Phong',lv:'Cấp 10+',col:'#7fc8ff'}]};
const sp2=spotsRow(520,[
  {n:'Đồng Heo Tuyết',mon:'boar3',lv:[10,12],cnt:6,col:'#dcebf5'},
  {n:'Rừng Thông Sói Tuyết',mon:'wolf3',lv:[12,14],cnt:6,col:'#cfe3f2'},
  {n:'Hang Gấu Nâu Núi',mon:'bear',lv:[13,15],cnt:5,col:'#e3dccf'},
  {n:'Vực Sói Đêm',mon:'wolf2',lv:[13,15],cnt:6,col:'#c5d6e6'},
  {n:'Đỉnh Gấu Đen',mon:'bear2',lv:[15,17],cnt:5,col:'#d3dbe6'},
  {n:'Bãi Gấu Trắng',mon:'bear3',lv:[17,19],cnt:5,col:'#eef3f8'}],800);
const M2={name:'Rừng Tuyết Phong',lv:'Cấp 10-19',w:5700,h:WH,theme:'snow',base:'#e8f1f6',spawn:{x:220,y:GY},
  safes:[Object.assign(R(0,440),{name:'Cổng Đồng Bằng'}),Object.assign(R(5340,360),{name:'Cổng Núi Lửa'})],spots:sp2,platforms:plats(sp2),
  portals:[{x:60,y:GY,to:1,tx:5180,ty:GY,label:'Đồng Bằng Khởi Nguyên',lv:'Cấp 1-11',col:'#9be05a'},{x:5640,y:GY,to:3,tx:200,ty:GY,label:'Núi Lửa Hắc Ám',lv:'Cấp 19+',col:'#ff8a2b'}]};
const sp3=spotsRow(520,[
  {n:'Bãi Heo Lửa',mon:'boar4',lv:[19,21],cnt:6,col:'#d9b8a6'},
  {n:'Đèo Sói Lửa',mon:'wolf4',lv:[21,23],cnt:6,col:'#d3a99a'},
  {n:'Hang Gấu Than',mon:'bear2',lv:[22,24],cnt:5,col:'#b9a8ae'},
  {n:'Đầm Rồng Độc',mon:'dragon2',lv:[22,22],cnt:1,col:'#a9c9a0'},
  {n:'Đỉnh Rồng Băng',mon:'dragon3',lv:[26,26],cnt:1,col:'#b4d2e8'},
  {n:'Hang Rồng Lửa',mon:'dragon',lv:[30,30],cnt:1,col:'#e5a79a'}],800);
const M3={name:'Núi Lửa Hắc Ám',lv:'Cấp 19-30',w:5400,h:WH,theme:'lava',base:'#ae9b95',spawn:{x:220,y:GY},
  safes:[Object.assign(R(0,440),{name:'Cổng Rừng Tuyết'})],spots:sp3,platforms:plats(sp3),
  portals:[{x:60,y:GY,to:2,tx:5480,ty:GY,label:'Rừng Tuyết Phong',lv:'Cấp 10-19',col:'#7fc8ff'}]};
MAPS.splice(0,MAPS.length,M0,M1,M2,M3);

/* --- dựng bản đồ: cảnh vật đứng trên mặt đất, luôn nằm sau nhân vật --- */
const BACK=200;                      // y sắp xếp của cảnh nền: vẫn trong vùng camera nhìn thấy, nhưng nhỏ hơn y của mọi nhân vật (thấp nhất ~220 khi nhảy từ bậc cao) nên luôn vẽ trước
genDecor=function(){
  const M=MAP,r=mulberry(4242+MAPI*31),th=THEMES[M.theme];DECOR=[];FLATS.clear();
  const add=(o,gy)=>{o.gy=gy==null?GY:gy;o.y=BACK+DECOR.length*.001;DECOR.push(o);};
  const busy=x=>M.portals.some(p=>Math.abs(p.x-x)<120)||(M.npcs||[]).some(n=>Math.abs(n.x-x)<130)||(M.fountain&&Math.abs(M.fountain-x)<110)||(M.houses||[]).some(h=>Math.abs(h[0]-x)<110);
  // hàng cây, đá, bụi phía sau
  for(let x=40;x<M.w-40;x+=70+r()*90){if(busy(x))continue;const k=r();
    if(k<.5)add({k:'tree',x,s:.85+r()*.5,v:th.trees[Math.floor(r()*3)]},GY-6-r()*10);
    else if(k<.75)add({k:'bush',x,s:.8+r()*.5},GY-2);else add({k:'rock',x,s:.7+r()*.6},GY-2);}
  (M.houses||[]).forEach(h=>add({k:'house',x:h[0],v:h[1]},GY-4));
  if(M.fountain)add({k:'fountain',x:M.fountain},GY-2);
  for(const n of M.npcs||[])add({k:'npc',x:n.x,n},GY);
  for(const s of M.spots)add({k:'sign',x:s.x+50,txt:s.n+' · Cấp '+s.lv[0]+(s.lv[1]>s.lv[0]?'-'+s.lv[1]:'')},GY-1);
  for(const p of M.portals)add({k:'portal',x:p.x,p},GY);
};
const _ddi=drawDecorItem;
drawDecorItem=function(d){if(d.gy==null)return _ddi(d);const y=d.y;d.y=d.gy;try{_ddi(d);}finally{d.y=y;}};
spawnAll=function(){
  G.mons=[];
  for(const s of MAP.spots)for(let i=0;i<s.cnt;i++){
    const x=s.cnt===1?s.x+s.w/2:s.x+80+(s.w-160)*(i+.5)/s.cnt+rand(-30,30);
    const m=spawnMon(s.mon,ri(s.lv[0],s.lv[1]),x,GY);m.x0=s.x+30;m.x1=s.x+s.w-30;m.vx=0;G.mons.push(m);}
};
bakeMini=function(){
  const c=document.createElement('canvas');setupCanvas(c,118,78);const g=c.getContext('2d');g.setTransform(dpr,0,0,dpr,0,0);
  const sx=118/WORLD.w,sy=78/WORLD.h,gy=GY*sy;
  const sky=g.createLinearGradient(0,0,0,78);sky.addColorStop(0,{grass:'#8fd3ff',snow:'#c9e3f5',lava:'#5a2a2a'}[MAP.theme]);sky.addColorStop(1,'#ffffff');g.fillStyle=sky;g.fillRect(0,0,118,78);
  for(const s of MAP.spots){g.fillStyle=s.col;g.fillRect(s.x*sx,gy-14,s.w*sx,14);}
  for(const s of MAP.safes){g.fillStyle='rgba(255,226,110,.9)';g.fillRect(s.x*sx,gy-14,s.w*sx,14);}
  g.fillStyle=MAP.base;g.fillRect(0,gy,118,78-gy);
  g.fillStyle='rgba(27,34,51,.55)';for(const p of MAP.platforms||[])g.fillRect(p.x*sx,p.y*sy,Math.max(2,p.w*sx),2);
  for(const p of MAP.portals){g.fillStyle=p.col;g.strokeStyle='#1b2233';g.lineWidth=1;g.beginPath();g.arc(p.x*sx,gy-5,3,0,TAU);g.fill();g.stroke();}
  MINIBG=c;
};

/* --- nền: trời + núi xa + lớp giữa (cuộn chậm), mặt đất, bậc đá --- */
const SKY={grass:['#7cc8ff','#d9f1ff'],snow:['#a9cbe6','#eef6fb'],lava:['#3a1414','#a2462a']};
function tileX(im,x0,y,h,vw){const w=h*im.w/im.h;let x=Math.floor(x0/w)*w;for(;x<x0+vw+w;x+=w)ctx.drawImage(im.i,x,y,w+1,h);}
drawGround=function(vw,vh){
  const th=MAP.theme,cx=G.cam.x,cy=G.cam.y;
  // trời (gradient) và lớp xa
  const sk=SKY[th]||SKY.grass,g=ctx.createLinearGradient(0,cy,0,GY);g.addColorStop(0,sk[0]);g.addColorStop(1,sk[1]);ctx.fillStyle=g;ctx.fillRect(cx-2,cy-2,vw+4,vh+4);
  const far=S('far_'+th);
  if(far){const h=Math.max(GY-cy+40,vh*.85),y=GY+30-h,px=cx*.82;ctx.save();ctx.translate(px,0);tileX(far,cx-px,y,h,vw);ctx.restore();}
  const mid=S('mid_'+th);
  if(mid){const h=vh*.42,y=GY-h*.94,px=cx*.5;ctx.save();ctx.translate(px,0);tileX(mid,cx-px,y,h,vw);ctx.restore();}
  // mặt đất: dải cắt ngang, mép trên đúng y mặt đất
  const gr=S('ground_'+th);
  if(gr){const h=Math.max(WH-GY+60,(cy+vh-GY)+20)/(1-gr.top),y=GY-h*gr.top+4;tileX(gr,cx,y,h,vw);}
  else{ctx.fillStyle=MAP.base;ctx.fillRect(cx-2,GY,vw+4,vh);ctx.fillStyle='rgba(0,0,0,.12)';ctx.fillRect(cx-2,GY,vw+4,6);}
  // bậc đá nổi
  const pl=S('plat_'+th);
  for(const p of MAP.platforms||[]){if(p.x+p.w<cx-40||p.x>cx+vw+40)continue;
    if(pl){const w=p.w*1.12,h=w*pl.h/pl.w;ctx.drawImage(pl.i,p.x-w*.06,p.y-h*pl.top+3,w,h);}
    else{ctx.fillStyle='#7a5a3a';ctx.beginPath();ctx.roundRect?ctx.roundRect(p.x,p.y,p.w,22,10):ctx.rect(p.x,p.y,p.w,22);ctx.fill();ctx.fillStyle='#5aa14e';ctx.fillRect(p.x,p.y-4,p.w,8);}}
};

/* --- người chơi: chạy trái/phải, nhảy, đứng trên bậc đá --- */
const platUnder=(x,y0,y1)=>{let best=null;for(const p of MAP.platforms||[])if(x>p.x+6&&x<p.x+p.w-6&&p.y>=y0-1&&p.y<=y1+1&&(!best||p.y<best.y))best=p;return best;};
let jumpQ=0,jWas=false,dropQ=0;
window.HSNC_JUMP=()=>{jumpQ=.15;};
const _dash=dashP;
dashP=function(a,len,time,o){_dash(Math.cos(a)>=0?0:Math.PI,len,time,o);}; // lướt ngang
respawnPlayer=function(){P.dead=0;P.x=MAP.spawn.x;P.y=GY;P.gvy=0;P.hp=P.maxHp;P.flash=0;for(const m of G.mons)if(!m.dead&&m.state==='chase')m.state='return';};
updatePlayer=function(dt){
  const p=P;if(p.gvy==null){p.gvy=0;}
  if(p.dead>0){p.dead-=dt;if(p.dead<=0)respawnPlayer();return;}
  if(G.trans){p.moving=false;return;}
  p.atkCd=Math.max(0,p.atkCd-dt);for(let i=0;i<6;i++)if(p.cds[i]>0)p.cds[i]=Math.max(0,p.cds[i]-dt);p.gcd=Math.max(0,p.gcd-dt);p.potCd=Math.max(0,p.potCd-dt);
  for(let i=p.buffs.length-1;i>=0;i--){p.buffs[i].t-=dt;if(p.buffs[i].t<=0)p.buffs.splice(i,1);}
  p.swing=Math.max(0,p.swing-dt/p.swingDur);p.comboT-=dt;if(p.comboT<=0)p.combo=0;p.flash-=dt;
  // trọng lực (cả khi đang lướt)
  const ground=()=>{const y0=p.y;p.gvy+=GRAV*dt;let ny=p.y+p.gvy*dt;
    if(p.gvy>=0){const pl=dropQ>0?null:platUnder(p.x,y0,ny);if(pl&&y0<=pl.y+1){ny=pl.y;p.gvy=0;}if(ny>=GY){ny=GY;p.gvy=0;}}
    p.y=ny;p.air=!(p.gvy===0&&(p.y===GY||!!platUnder(p.x,p.y,p.y)));
    if(!p.air&&p.y<GY&&!platUnder(p.x,p.y-1,p.y+1))p.air=true;};
  dropQ=Math.max(0,dropQ-dt);jumpQ=Math.max(0,jumpQ-dt);
  if(p.dash){
    const d=p.dash;p.x=clamp(p.x+d.vx*dt,40,WORLD.w-40);p.moving=true;p.walk+=dt*2;
    if(d.mult){for(const m of G.mons){if(m.dead||d.set.has(m))continue;if(Math.abs(m.x-p.x)<60+m.t.r&&Math.abs(m.y-p.y)<110){d.set.add(m);hitMon(m,patk()*d.mult,{kb:180});statusMon(m,{stun:d.stun});}}}
    d.sp-=dt;if(d.sp<=0){d.sp=.045;fx({k:'spark',x:p.x,y:p.y-20,max:.25,col:'#ffffff'});}
    d.t-=dt;if(d.t<=0){const e=d.end;p.dash=null;if(e)e();}
    ground();p.vy=0;return;
  }
  const ix=(keys.ArrowRight||keys.KeyD?1:0)-(keys.ArrowLeft||keys.KeyA?1:0)+joy.x;
  const up=!!(keys.ArrowUp||keys.KeyW||keys.KeyK)||joy.y<-.62,down=!!(keys.ArrowDown||keys.KeyS)||joy.y>.7;
  if(up&&!jWas)jumpQ=.15;jWas=up;
  const manual=Math.abs(ix)>.18;
  if(manual){p.focus=null;G.moveTarget=null;p.npcGo=null;}
  if(p.focus&&p.focus.dead)p.focus=null;
  let dx=0,inReach=false;
  if(manual)dx=clamp(ix,-1,1);
  else if(p.focus){const f=p.focus,ddx=f.x-p.x,need=reachOf()-10+f.t.r*.5;if(Math.abs(ddx)>need*.9)dx=Math.sign(ddx);else if(Math.abs(f.y-p.y)<120||CLS[p.cls].reach>200)inReach=true;}
  else if(G.moveTarget){const ddx=G.moveTarget.x-p.x;if(Math.abs(ddx)>8)dx=Math.sign(ddx);else G.moveTarget=null;}
  // nhảy (đứng trên đất hoặc bậc đá), xuống bậc đá bằng phím xuống
  if(jumpQ>0&&!p.air){p.gvy=-JUMP;p.air=true;jumpQ=0;fx({k:'poof',x:p.x,y:p.y,max:.35,r:16});}
  if(down&&!p.air&&p.y<GY){dropQ=.25;p.y+=2;p.air=true;}
  ground();
  p.moving=dx!==0;
  if(p.moving){const spd=p.spd*bm('spd')*(p.swing>0?.85:1)*(p.air?.92:1);p.vx=dx*spd;p.x=clamp(p.x+p.vx*dt,40,WORLD.w-40);if(!p.air)p.walk+=dt*Math.abs(dx);if(!p.focus)p.face=dx>0?1:-1;}else p.vx=0;
  if(p.air){p.moving=true;} // giữ một tư thế khi đang bay lên/rơi xuống
  p.vy=0;
  if(p.focus&&Math.abs(p.focus.x-p.x)>4)p.face=p.focus.x>p.x?1:-1;
  if(p.atkCd<=0&&(atkHeld||inReach))basicAttack();
  if(inSafe(p))p.hp=Math.min(p.maxHp,p.hp+p.maxHp*.08*dt);
  if(!p.air)for(const pt of MAP.portals)if(Math.abs(p.x-pt.x)<46&&p.y>=GY-1){G.trans={t:0,pt,sw:false};G.moveTarget=null;p.focus=null;break;}
};

/* --- quái: tuần tra và đuổi theo mặt đất, tăng tốc/giảm tốc mượt (không giật cục) --- */
updateMons=function(dt){
  const pIn=P.dead<=0&&!inSafe(P);
  for(let i=0;i<G.mons.length;i++){
    const m=G.mons[i];if(m.vx==null)m.vx=0;
    if(m.dead){m.respawn-=dt;if(m.respawn<=0){m.dead=false;m.hp=m.hpMax;m.x=m.sx;m.y=GY;m.vx=0;m.state='idle';fx({k:'poof',x:m.x,y:m.y,max:.5,r:m.t.r});}continue;}
    if(Math.abs(m.x-P.x)>2200){if(m.state!=='idle'){m.state='idle';m.x=m.sx;m.hp=m.hpMax;}continue;}
    m.flash-=dt;m.cd-=dt;m.shoot-=dt;m.lunge=Math.max(0,m.lunge-dt);m.breath=Math.max(0,m.breath-dt);
    if(m.kx){m.x=clamp(m.x+m.kx*dt,30,WORLD.w-30);const k=Math.pow(.02,dt);m.kx*=k;if(Math.abs(m.kx)<4)m.kx=0;}
    m.ky=0;m.y=GY;
    if(m.slow>0)m.slow-=dt;
    if(m.pois){const q=m.pois;q.t-=dt;q.acc+=dt;if(q.acc>=.5){q.acc-=.5;hitMon(m,q.dps*.5,{dot:true});}if(q.t<=0)m.pois=null;if(m.dead)continue;}
    let want=0;const sf=m.slow>0?.4:1,spd=m.t.spd*sf;
    if(m.stun>0){m.stun-=dt;m.vx*=Math.pow(.001,dt);m.x+=m.vx*dt;continue;}
    const dx=P.x-m.x,ady=Math.abs(P.y-m.y),home=Math.abs(m.x-m.sx);
    if(m.state==='idle'){
      m.wt-=dt;if(m.wt<=0){m.wt=rand(2,4.5);m.wx=clamp(m.sx+rand(-150,150),m.x0||40,m.x1||WORLD.w-40);}
      const d=m.wx-m.x;if(Math.abs(d)>10)want=Math.sign(d)*spd*.35;
      if(pIn&&Math.abs(dx)<m.t.aggro&&ady<180)m.state='chase';
    }else if(m.state==='chase'){
      if(!pIn||home>700)m.state='return';
      else{
        const adx=Math.abs(dx);
        // trễ: đến gần thì đứng đánh, bị bỏ xa hơn tầm mới đuổi tiếp (không khựng ở mép tầm đánh)
        if(m.hold&&adx>m.t.range*1.05)m.hold=false;else if(!m.hold&&adx<m.t.range*.75)m.hold=true;
        if(!m.hold)want=Math.sign(dx)*spd;
        if(Math.abs(dx)>2)m.face=dx>=0?1:-1;
        if(Math.hypot(dx,P.y-m.y)<=m.t.range+14&&m.cd<=0){m.cd=m.t.cd;m.lunge=.25;hurtPlayer(m.atk);monHitFx(m);}
        if(m.t.boss&&m.shoot<=0&&Math.abs(dx)<560&&Math.abs(dx)>110){m.shoot=2.6;m.breath=.6;const a=Math.atan2(P.y-30-(m.y-m.t.h*.5),P.x-m.x);for(let k=-1;k<=1;k++)shoot('efire',a+k*.22,300,m.atk*.7,12,640,false,0,true,m.x,m.y-m.t.h*.35);G.projs.slice(-3).forEach(q=>{q.fc=m.t.fire;});breathFx(m);}
      }
    }else{
      const d=m.sx-m.x;want=Math.sign(d)*spd*1.2;m.hp=Math.min(m.hpMax,m.hp+m.hpMax*.25*dt);
      if(Math.abs(d)<12){m.state='idle';m.hp=m.hpMax;want=0;}
    }
    // tăng/giảm tốc mượt
    m.vx+=(want-m.vx)*Math.min(1,dt*7);
    if(Math.abs(m.vx)<3&&want===0)m.vx=0;
    m.x=clamp(m.x+m.vx*dt,30,WORLD.w-30);
    if(m.vx>12)m.face=m.state==='chase'?m.face:1;else if(m.vx<-12)m.face=m.state==='chase'?m.face:-1;
    m.mv=Math.abs(m.vx)/Math.max(1,m.t.spd);m.walk+=dt*(.4+m.mv*1.6);
    for(let j=i+1;j<G.mons.length;j++){const o=G.mons[j];if(o.dead)continue;const ddx=o.x-m.x,min=(m.t.r+o.t.r)*.55;if(Math.abs(ddx)<min){const push=(min-Math.abs(ddx))*.5*(ddx>=0?1:-1);m.x-=push*Math.min(1,dt*10);o.x+=push*Math.min(1,dt*10);}}
  }
};

/* --- hiệu ứng đòn đánh của quái (ảnh riêng, không vẽ dính vào quái) --- */
const MONFX={boar:2,wolf:1,bear:0,dragon:0};
function monHitFx(m){const f=window.HSNC_SFX;if(!f||!(window.HSNC_FXOK&&HSNC_FXOK('mon',0)))return;
  const n=MONFX[m.t.kind]??2,dir=P.x>=m.x?1:-1;
  f({c:'mon',n,x:P.x-dir*10,y:P.y-34,h:n===2?70:64,max:.32,a:'pop',flip:dir<0,rot:n===0?(dir>0?-.2:.2):0});}
function breathFx(m){const f=window.HSNC_SFX;const n={dragon:3,dragon2:4,dragon3:5}[m.type]??3;if(!f||!(window.HSNC_FXOK&&HSNC_FXOK('mon',n)))return;
  const H=(m.t.h||200)/.94*MS,hover=(-70-Math.sin(G.time*2.2+m.id)*12)*MS,face=P.x>=m.x?1:-1;m.face=face;
  const mx=m.x+face*H*.72,my=m.y+hover-H*.58,a=Math.atan2(P.y-30-my,(P.x-mx)*face);
  f({c:'mon',n,x:mx,y:my,h:90,max:.65,a:'pop',flip:face<0,rot:clamp(a,-.7,.7),px:.04,py:.5,glow:.6});}

/* --- vẽ quái: thân nhún, chân bước (lắc dải chân), rồng bay lơ lửng --- */
const _dm=drawMon,MS=.76;          // quái nhỏ lại cho cân với nhân vật
// khung hoạt ảnh quái (ChatGPT vẽ): 0 đứng, 1-4 bước chạy / vỗ cánh, 5 đánh
const MF={};
for(const k in (window.HSNC_MON||{}))MF[k]=HSNC_MON[k].map(f=>{const im=new Image();im.src=f.u;return {i:im,hr:f.hr,ar:f.ar,cx:f.cx};});
const mReady=k=>MF[k]&&MF[k].every(f=>f.i.complete&&f.i.naturalWidth);
drawMon=function(m){
  const sp=monSprite(m);if(!sp||!sp.c)return _dm(m);
  const t=G.time,r=m.t.r,k=m.t.k||1,fly=m.t.kind==='dragon',mv=m.mv||0;
  const hover=fly?-70-Math.sin(t*2.2+m.id)*12:0,ph=m.walk*(fly?3:9);
  ctx.save();ctx.translate(m.x,m.y);ctx.scale(MS,MS);
  ctx.globalAlpha=fly?.5:1;ctx.drawImage(shadowSpr(),-m.t.sw*1.3*(fly?.8:1),r*.12-r*.5,m.t.sw*2.6*(fly?.8:1),r);ctx.globalAlpha=1;
  if(m.flash>0&&Math.floor(t*30)%2)ctx.globalAlpha=.55;
  ctx.translate(0,hover);ctx.scale(m.face,1);ctx.translate(m.lunge>0?Math.sin(m.lunge/.25*Math.PI)*10*k:0,0);
  const W=sp.w,H=sp.h,X=sp.x,Y=-H*.97,img=sp.c,iw=img.naturalWidth||img.width,ih=img.naturalHeight||img.height;
  if(mReady(m.type)){
    // vẽ theo khung: H là chiều cao khung đứng; neo giữa thân để đổi khung không bị trượt
    const F=MF[m.type],fi=Math.floor(fly?G.time*7+m.id:m.walk*5.5)%4;
    // rồng: luôn vỗ cánh (hơi thở là hiệu ứng riêng); thú: khung vồ khi đánh
    const q=fly?F[1+fi]:m.lunge>0?F[5]:mv>.06?F[1+fi]:F[0];
    const fh=H*q.hr,fw=fh*q.ar,breathe=!fly&&mv<.06&&m.lunge<=0?Math.sin(t*2+m.id)*.015:0;
    ctx.save();ctx.scale(1,1+breathe);ctx.drawImage(q.i,-q.cx*H,-fh,fw,fh);ctx.restore();
  }
  else if(fly){const fl=Math.sin(ph)*.04;ctx.scale(1,1+fl);ctx.drawImage(img,X,Y,W,H);}
  else{
    const step=Math.sin(ph),bob=-Math.abs(Math.cos(ph))*3*Math.min(1,mv*1.2),breathe=m.state==='idle'&&mv<.05?Math.sin(t*2+m.id)*.012:0;
    const cut=.64;                                      // phần trên = thân, phần dưới = chân
    ctx.save();ctx.translate(0,bob);ctx.rotate(step*.025*Math.min(1,mv*1.5));ctx.scale(1,1+breathe);
    ctx.drawImage(img,0,0,iw,ih*cut,X,Y,W,H*cut+.5);ctx.restore();
    // chân: nghiêng qua lại theo bước chạy
    const sk=step*.28*Math.min(1,mv*1.4),ly=Y+H*cut;
    ctx.save();ctx.translate(0,ly);ctx.transform(1,0,-sk,1,0,0);ctx.drawImage(img,0,ih*cut,iw,ih*(1-cut),X,0,W,H*(1-cut));ctx.restore();
  }
  ctx.restore();
  // các nhãn trạng thái, máu, tên: dùng lại phần vẽ cũ nhưng không vẽ lại thân
  const y0=m.y;m.y=m.y+hover*MS+m.t.h*(1-MS);
  if(m.stun>0){ctx.font='22px sans-serif';ctx.textAlign='center';ctx.lineWidth=3;ctx.strokeStyle=INK;const sx=m.x+Math.sin(t*9)*8;ctx.strokeText('★ ★',sx,m.y-m.t.h-22);ctx.fillStyle='#ffd23f';ctx.fillText('★ ★',sx,m.y-m.t.h-22);}
  if(m.slow>0||m.pois){ctx.lineWidth=3;ctx.strokeStyle=m.pois?'#6fcf3f':'#6fb8ff';ctx.beginPath();ctx.ellipse(m.x,y0+r*.12,m.t.sw+4,r*.4+2,0,0,TAU);ctx.stroke();}
  const ly=m.y-m.t.h-8,near=P&&Math.abs(m.x-P.x)<430;
  if(near||m.hp<m.hpMax||m.t.boss||(P&&P.focus===m)){
    if(m.hp<m.hpMax||m.t.boss){const bw=m.t.boss?96:48;ctx.fillStyle='#0f1422';ctx.fillRect(m.x-bw/2-1.5,ly-1.5,bw+3,8);ctx.fillStyle='#d9345a';ctx.fillRect(m.x-bw/2,ly,bw*Math.max(0,m.hp/m.hpMax),5);}
    ctx.font='15px "Patrick Hand",sans-serif';ctx.textAlign='center';ctx.lineWidth=4;ctx.strokeStyle=PAPER;
    const lab='Lv.'+m.lv+' '+m.t.n;ctx.strokeText(lab,m.x,ly-4);ctx.fillStyle=(P&&m.lv>P.lv+3)?'#c0143f':INK;ctx.fillText(lab,m.x,ly-4);
  }
  m.y=y0;
};

/* --- camera xa như game cuộn ngang: thấy khoảng 700 đơn vị chiều cao, nhân vật nhỏ, thấy rộng --- */
const _rs=resize;
resize=function(){_rs();scale=clamp(H/700,.5,1.1);};
{const st=document.createElement('style');st.textContent=`
#app #hud #log#log{left:max(12px,env(safe-area-inset-left,0px));right:auto;transform:none;top:calc(96px + env(safe-area-inset-top,0px));bottom:auto;width:min(330px,40vw);min-width:0;align-items:flex-start}
#app #hud #log#log div{font-size:12px;padding:3px 9px}
#app #boss{top:calc(48px + env(safe-area-inset-top,0px))}
#app #hud #buffs{top:auto;bottom:calc(150px + env(safe-area-inset-bottom,0px))}
@media (max-height:420px){#app #hud #log#log{top:calc(72px + env(safe-area-inset-top,0px));width:min(280px,34vw)}#app #hud #log#log div{font-size:11px}
 #app #hud#hud{--hs:.72}#hud#hud .hpAv{width:48px;height:48px}#hud#hud .hpLv{left:30px;top:32px;transform:scale(.85);transform-origin:0 0}
 #hud#hud .hpBox{width:clamp(140px,21vw,190px);padding:4px 10px 5px 18px}#app #hud#hud #statPlate .who{font-size:13px}
 #app #hud#hud .ib{width:34px;height:34px}#app #hud#hud .ib img{width:24px;height:24px}#app #hud#hud #mini{width:92px;height:58px}#app #hud#hud #zoneName{font-size:10px}
 #app #hud#hud #joy{width:104px;height:104px}#app #hud#hud #knob{width:46px;height:46px;margin:-23px 0 0 -23px}
 #hud#hud .hcur div{height:22px;font-size:12px}#hud#hud .hcur img{width:20px;height:20px}}`;document.head.append(st);}
/* --- nút nhảy trên điện thoại --- */
{const b=document.createElement('button');b.type='button';b.id='bJump';b.className='rbtn sm';b.setAttribute('aria-label','Nhảy (W)');
  b.innerHTML='<svg viewBox="0 0 24 24" width="30" height="30" aria-hidden="true"><path d="M12 3l7 8h-4.5v6h-5v-6H5z" fill="#fff" stroke="#16224a" stroke-width="1.8" stroke-linejoin="round"/><rect x="7" y="19" width="10" height="2.4" rx="1.2" fill="#16224a"/></svg>';
  b.addEventListener('pointerdown',e=>{e.preventDefault();window.HSNC_JUMP();});$('btns').append(b);
  const st=document.createElement('style');st.textContent='#app #hud #bJump{background:radial-gradient(circle at 38% 30%,#fff,#ffe9a8 50%,#f2b632)}';document.head.append(st);
  // đặt cạnh nút đánh (toạ độ theo tâm nút đánh, như giao diện trong hud.js)
  const a=181*Math.PI/180;b.style.left='calc(50% + '+(Math.cos(a)*238).toFixed(1)+'px)';b.style.top='calc(50% - '+(Math.sin(a)*238).toFixed(1)+'px)';}
{const h=$('hint');if(h)h.textContent='A/D hoặc ←/→: đi · W/↑: nhảy · S/↓: xuống bậc · Space: đánh · 1-6: kỹ năng · H: bình máu · I: túi đồ · U: kỹ năng · E: nói chuyện';}
}catch(err){console.error('Góc nhìn ngang lỗi:',err);}
