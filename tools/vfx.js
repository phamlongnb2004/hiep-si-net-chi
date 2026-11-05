
/* ===== HIỆU ỨNG CHIÊU (ảnh ChatGPT vẽ): chém, xoáy, khiên, cầu lửa, sét, băng, độc, rồng lửa… ===== */
try{
const XA=window.HSNC_FX||{};
const XI={};
const ld=f=>{const im=new Image();im.src=f.u;return{i:im,w:f.w,h:f.h};};
for(const c in XA)if(Array.isArray(XA[c]))XI[c]=XA[c].map(ld);
// chuỗi khung theo thời gian (đòn đánh của quái): {claw:[6 khung], bite, hit, fire, poison, ice}
const XS={};for(const n in (XA.seq||{}))XS[n]=XA.seq[n].map(ld);
const seqOk=n=>XS[n]&&XS[n].every(f=>f.i.complete&&f.i.naturalWidth);
window.HSNC_SEQOK=seqOk;
const X=(c,k)=>{const s=XI[c],f=s&&s[k];return f&&f.i.complete&&f.i.naturalWidth?f:null;};
const ease=u=>1-Math.pow(1-u,3);

/* --- một hiệu ứng ảnh: vị trí, kích thước, xoay, kiểu chuyển động --- */
function sfx(o){o.k='spr';o.t=0;o.sd=Math.random()*999;G.fx.push(o);return o;}
function drawSeq(f){
  // phát lần lượt các khung, mỗi lần chuyển khung thì trộn mờ hai khung liền nhau cho mượt
  const F=XS[f.seq],N=F.length,u=clamp(f.t/f.max,0,1),pos=Math.min(N-1.0001,u*N),i=Math.floor(pos),fr=pos-i;
  let x=f.x,y=f.y;if(f.follow&&P){x=P.x+(f.ox||0);y=P.y+(f.oy||0);}
  if(f.at&&!f.at.dead){x=f.at.x+(f.ox||0);y=f.at.y+(f.oy||0);}
  const q=F[0],h=f.h,w=h*q.w/q.h,s=1+(f.grow||0)*u;
  ctx.save();ctx.translate(x,y);if(f.flip)ctx.scale(-1,1);if(f.rot)ctx.rotate(f.rot);ctx.scale(s,s);
  const px=f.px!=null?f.px:.5,py=f.py!=null?f.py:.5;
  const draw=(k,al)=>{if(al<=.01)return;const g=F[Math.min(N-1,k)];ctx.globalAlpha=al*(f.al||1);ctx.drawImage(g.i,-w*px,-h*py,w,h);};
  draw(i,1-fr);draw(i+1,fr);
  if(f.glow){ctx.globalCompositeOperation='lighter';draw(i,(1-fr)*.3*f.glow);draw(i+1,fr*.3*f.glow);}
  ctx.restore();
}
function drawSpr(f){
  if(f.seq){if(seqOk(f.seq))drawSeq(f);return;}
  const im=X(f.c,f.n);if(!im)return;
  const u=clamp(f.t/f.max,0,1);let x=f.x,y=f.y,s=f.s||1,a=1,rot=f.rot||0;
  if(f.follow&&P){x=P.x+(f.ox||0);y=P.y+(f.oy||0);}
  switch(f.a){
    case 'pop':s*=.55+.45*ease(Math.min(1,u*2.4));a=u<.65?1:1-(u-.65)/.35;break;          // bung ra rồi mờ dần
    case 'grow':s*=.25+1.05*ease(u);a=1-u*u;break;                                          // sóng lan rộng
    case 'aura':s*=.9+Math.sin(G.time*7)*.05+(u<.15?(u/.15-1)*.4:0);a=Math.min(1,u*6,(1-u)*4);break; // bao quanh người
    case 'drop':{const v=ease(Math.min(1,u/.35));y-=(1-v)*260;a=u<.7?1:1-(u-.7)/.3;s*=u>.35?1+(u-.35)*.12:1;break;} // từ trời rơi xuống
    case 'dash':s*=.7+.3*ease(u);a=1-u;break;
    case 'flick':a=Math.min(1,u*8)*(1-Math.pow(u,3));s*=1+Math.sin(G.time*30+f.sd)*.04;break; // chớp nháy (sét)
    default:a=1-u;
  }
  if(a<=0)return;
  const h=f.h*s,w=h*im.w/im.h;
  ctx.save();ctx.globalAlpha=a*(f.al||1);ctx.translate(x,y+(f.dy||0));
  if(f.flip)ctx.scale(-1,1);
  if(rot)ctx.rotate(rot);
  ctx.drawImage(im.i,-w*(f.px!=null?f.px:.5),-h*(f.py!=null?f.py:.5),w,h);
  if(f.glow){ctx.globalCompositeOperation='lighter';ctx.globalAlpha=a*.35*f.glow;ctx.drawImage(im.i,-w*(f.px!=null?f.px:.5),-h*(f.py!=null?f.py:.5),w,h);}
  ctx.restore();
}

/* --- thay hiệu ứng vẽ tay bằng ảnh --- */
const _df=drawFx;
drawFx=function(f){
  if(f.k==='spr')return drawSpr(f);
  const c=P?P.cls:'sword';
  if(f.k==='slash'&&(c==='sword'||c==='fighter')&&X(c,0)){
    const u=clamp(f.t/f.max,0,1),im=X(c,0),h=(f.range||90)*1.25*(.8+.3*ease(u)),w=h*im.w/im.h,fl=Math.cos(f.ang)<0;
    ctx.save();ctx.globalAlpha=1-u*u;ctx.translate(f.x+Math.cos(f.ang)*(f.range||90)*.45,f.y-26+Math.sin(f.ang)*(f.range||90)*.25);
    if(fl)ctx.scale(-1,1);ctx.rotate((fl?-1:1)*Math.atan2(Math.sin(f.ang)*.6,Math.abs(Math.cos(f.ang))));
    ctx.drawImage(im.i,-w/2,-h/2,w,h);ctx.restore();return;}
  if(f.k==='spin'&&c==='sword'&&X('sword',1)){
    const u=clamp(f.t/f.max,0,1),im=X('sword',1),w=(f.range||110)*2.3*(.7+.3*ease(u)),h=w*im.h/im.w;
    ctx.save();ctx.globalAlpha=1-u*u;ctx.translate(f.x,f.y-14);ctx.scale(1,1);ctx.rotate(Math.sin(u*9)*.04);
    ctx.drawImage(im.i,-w/2,-h/2,w,h);ctx.restore();return;}
  if(f.k==='meteor'&&X('mage',1)){
    const u=clamp(f.t/f.max,0,1);ctx.save();
    ctx.globalAlpha=.55;ctx.setLineDash([8,6]);ctx.strokeStyle='#ff6a2a';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(f.x,f.y,f.r*(.5+.5*u),f.r*(.5+.5*u)*.6,0,0,TAU);ctx.stroke();ctx.setLineDash([]);
    if(u>.3){const v=(u-.3)/.7,im=X('mage',1),h=120,w=h*im.w/im.h;ctx.globalAlpha=1;ctx.drawImage(im.i,f.x-(1-v)*170-w*.62,f.y-(1-v)*430-h*.78,w,h);}
    ctx.restore();return;}
  if(f.k==='bolt'&&X('mage',3)){
    const u=clamp(f.t/f.max,0,1),im=X('mage',3),h=230,w=h*im.w/im.h;
    ctx.save();ctx.globalAlpha=Math.min(1,u*8)*(1-u*u);ctx.drawImage(im.i,f.x2-w/2,f.y2-h*.92,w,h);
    ctx.globalCompositeOperation='lighter';ctx.globalAlpha*=.5;ctx.drawImage(im.i,f.x2-w/2,f.y2-h*.92,w,h);ctx.restore();return;}
  if(f.k==='zone'){
    const n={ice:['mage',2],poison:['archer',2],fire:['mage',5]}[f.kind],im=n&&X(n[0],n[1]);
    if(im){const a=Math.max(0,Math.min(1,f.t/.25,(f.max-f.t)/.5));ctx.save();
      if(f.kind==='fire'){
        ctx.globalAlpha=a*.5;ctx.fillStyle='rgba(255,110,30,.35)';ctx.beginPath();ctx.ellipse(f.x,f.y,f.r,f.r*.6,0,0,TAU);ctx.fill();
        // cột lửa bùng lên rải rác trong vùng
        for(let i=0;i<9;i++){const ph=((G.time*.9+i*.37+f.sd*.01)%1),ang=(i*2.399+f.sd)%TAU,rd=Math.sqrt((i+.5)/9)*f.r*.85,px=f.x+Math.cos(ang)*rd,py=f.y+Math.sin(ang)*rd*.6;
          const h=(70+(i%3)*22)*Math.sin(ph*Math.PI),w=h*im.w/im.h;ctx.globalAlpha=a*Math.sin(ph*Math.PI);ctx.drawImage(im.i,px-w/2,py-h*.95,w,h);}
      }else{const w=f.r*2.25,h=w*im.h/im.w;ctx.globalAlpha=a*(.85+Math.sin(G.time*3)*.08);ctx.drawImage(im.i,f.x-w/2,f.y-h*.55,w,h);}
      ctx.restore();return;}
  }
  return _df(f);
};

/* --- đạn: cầu lửa, khí công, tên phát sáng --- */
const _dp=drawProj;
drawProj=function(pr){
  const k=pr.type==='fire'?['mage',0]:pr.type==='ki'?['fighter',1]:pr.type==='arrow'&&pr.sk?['archer',0]:null,im=k&&X(k[0],k[1]);
  if(!im)return _dp(pr);
  const a=Math.atan2(pr.vy,pr.vx),h=pr.type==='ki'?78:pr.type==='fire'?(pr.r>12?62:48):34,w=h*im.w/im.h;
  ctx.save();ctx.translate(pr.x,pr.y-26);ctx.rotate(a);ctx.drawImage(im.i,-w*.7,-h/2,w,h);
  ctx.globalCompositeOperation='lighter';ctx.globalAlpha=.3;ctx.drawImage(im.i,-w*.7,-h/2,w,h);ctx.restore();
};

/* --- hiệu ứng riêng cho từng chiêu --- */
const SP={
  sword:[null,null,
    ()=>sfx({c:'sword',n:2,follow:1,oy:-34,h:150,max:1.1,a:'aura',al:.9}),
    a=>sfx({c:'sword',n:3,x:P.x,y:P.y-30,h:70,max:.4,a:'dash',flip:Math.cos(a)<0,px:.85}),
    ()=>{sfx({c:'sword',n:4,x:P.x,y:P.y-10,h:300,max:.6,a:'grow'});},
    ()=>{for(let i=0;i<3;i++)after(i*.3,()=>{if(P)sfx({c:'sword',n:5,x:P.x,y:P.y+6,h:250,max:.75,a:'drop',py:.95,glow:1});});}],
  mage:[null,null,null,null,
    ()=>sfx({c:'mage',n:4,follow:1,oy:-36,h:150,max:1.2,a:'aura',al:.85}),null],
  archer:[null,null,null,
    a=>sfx({c:'archer',n:3,x:P.x,y:P.y-18,h:90,max:.5,a:'pop'}),null,
    ()=>sfx({c:'archer',n:5,follow:1,oy:-60,h:200,max:1.7,a:'aura',al:.75})],
  fighter:[null,null,
    ()=>sfx({c:'fighter',n:2,follow:1,oy:-30,h:150,max:1.2,a:'aura',al:.9}),
    a=>sfx({c:'fighter',n:3,follow:1,ox:Math.cos(a)*60,oy:-34+Math.sin(a)*30,h:110,max:.55,a:'pop',flip:Math.cos(a)<0}),
    ()=>sfx({c:'fighter',n:4,x:P.x,y:P.y-6,h:240,max:.7,a:'grow'}),
    ()=>sfx({c:'fighter',n:5,follow:1,oy:-40,h:190,max:1.5,a:'aura',al:.9})]
};
window.HSNC_SFX=sfx;window.HSNC_FXOK=X;
const _cs=castSkill;
castSkill=function(i){
  const before=P&&P.cds?P.cds[i]:1,n0=G.projs.length;
  _cs(i);
  if(!P||before>0||!(P.cds[i]>0))return; // chiêu chưa được dùng (đang hồi, chưa học…)
  for(let k=n0;k<G.projs.length;k++)G.projs[k].sk=1;
  const f=SP[P.cls]&&SP[P.cls][i];if(f&&XI[P.cls])try{f(P.aim);}catch(e){}
};
// đạn chiêu có nổ lan: vẽ vụ nổ khi đạn biến mất
let live=new Map();
const _up=update;
update=function(dt){
  // thiên thạch chạm đất: nổ lửa
  if(P&&G.state==='play')for(const f of G.fx)if(f.k==='meteor'&&!f.done&&!f.boom&&f.t+dt>=f.max){f.boom=1;sfx({c:'archer',n:4,x:f.x,y:f.y-30,h:170,max:.5,a:'pop'});}
  _up(dt);
  if(!P)return;
  const now=new Map();for(const p of G.projs)if(p.splash&&!p.enemy)now.set(p,[p.x,p.y]);
  for(const [p,xy] of live)if(!now.has(p)&&p.trav<p.range-4){const big=p.splash>=100;sfx({c:'archer',n:4,x:xy[0],y:xy[1]-24,h:big?190:110,max:big?.55:.4,a:'pop'});}
  live=now;
};
}catch(err){console.error('Hiệu ứng chiêu lỗi:',err);}
