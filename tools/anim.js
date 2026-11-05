
/* ===== HOẠT ẢNH NHÂN VẬT: đứng thở, 4 bước đi, đòn đánh (khung hình ChatGPT vẽ) + ghép mũ, áo choàng theo từng món ===== */
try{
const AF=window.HSNC_ANIM||{},LA=window.HSNC_LAYER||{};
const img=u=>{const im=new Image();im.src=u;return im;};
const FR={};
for(const k in AF)FR[k]=AF[k].map(f=>({i:img(f.u),w:f.w,h:f.h,ax:f.ax,tp:f.tp,hc:f.hc}));
const LY={};
for(const c in LA)LY[c]={hat:(LA[c].hat||[]).map(f=>({i:img(f.u),w:f.w,h:f.h})),cape:(LA[c].cape||[]).map(f=>({i:img(f.u),w:f.w,h:f.h}))};
const ok=f=>f&&f.i.complete&&f.i.naturalWidth;
const ready=k=>FR[k]&&FR[k].every(ok);
// thân không mũ, không áo choàng: "body_<phái>_<bộ>"; nếu chưa có thì dùng tờ đi bộ cũ (đã có sẵn mũ/áo choàng)
const bodyKey=(c,t)=>ready('body_'+c+'_'+t)?'body_'+c+'_'+t:ready('body_'+c+'_0')?'body_'+c+'_0':null;
// vị trí ghép theo phái (đơn vị hiển thị, gốc = giữa hai chân, chiều x là hướng mặt)
// hx: tâm đầu, hw: bề rộng mũ, hb: mũ lún xuống dưới đỉnh tóc (tính theo hw), cx/cy: điểm treo áo choàng ở vai sau, ch: chiều cao áo choàng
const FIT={
  sword:{hx:3,hw:48,hb:.66,cx:-2,cy:.47,ch:46},
  archer:{hx:4,hw:44,hb:.52,cx:-2,cy:.49,ch:44},
  mage:{hx:2,hw:52,hb:.42,cx:-2,cy:.48,ch:46},
  fighter:{hx:3,hw:44,hb:.74,cx:-1,cy:.47,ch:44}};
window.HSNC_FIT=FIT;
const decode=n=>({a:n%4,h:Math.floor(n/4)%5-1,c:Math.floor(n/20)-1});
const BOB=[0,2.2,0,2.2];          // khung chân dang (1,3) thấp, khung chân lướt qua (2,4) nảy lên
const _dh2=drawHero;
drawHero=function(o){
  const look=o.look!=null?decode(o.look|0):(window.HSNC_LOOK?HSNC_LOOK(o.eq):{a:0,h:-1,c:-1});
  const bk=bodyKey(o.cls,look.a);
  // chưa có thân tách lớp: dùng tờ đi bộ theo bộ áo (kiểu cũ)
  const legacy=!bk,tk=look.a?o.cls+'_'+look.a:o.cls,key=bk||(ready(tk)?tk:o.cls),set=FR[key];
  if(!set||!ready(key))return _dh2(o);
  const t=o.t||0,mv=!!o.moving,sw=o.swing||0,face=o.face||1;
  const ph=t*8.5,fi=Math.floor(ph)%4,fr=ph-Math.floor(ph);
  let q=set[0];
  if(sw>0)q=set[5];else if(mv)q=set[1+fi];
  ctx.save();
  let al=o.alpha!=null?o.alpha:1;if(o.flash>0&&Math.floor(G.time*30)%2)al*=.5;ctx.globalAlpha=al;
  if(o.aura){const g=ctx.createRadialGradient(0,-42,5,0,-42,70);g.addColorStop(0,o.aura+'88');g.addColorStop(1,o.aura+'00');ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,-42,70,0,TAU);ctx.fill();}
  const up=mv&&sw<=0?BOB[fi]+(BOB[(fi+1)%4]-BOB[fi])*fr:0;
  const sk=1-up*.05;
  ctx.drawImage(shadowSpr(),-28*sk,-8,56*sk,19);
  if(mv&&sw<=0){const d=(fi%2===0)?fr:1;if(d<1){ctx.fillStyle='rgba(225,212,182,.75)';for(let i=0;i<3;i++){const u=d;ctx.globalAlpha=al*(1-u)*.8;ctx.beginPath();ctx.arc(-face*(6+i*7+u*10),-2-u*5-i,2+u*3.5,0,TAU);ctx.fill();}ctx.globalAlpha=al;}}
  ctx.scale(face,1);
  let sy=1,sx=1;
  if(mv&&sw<=0){ctx.rotate(.03);}
  else if(sw<=0){const b=Math.sin(G.time*2.6+(o.t||0)*.3);sy=1+b*.016;sx=1-b*.008;}
  const lunge=sw>0?Math.sin(Math.min(1,(1-sw)*1.3)*Math.PI)*6:0;
  ctx.translate(lunge,-up);ctx.scale(sx,sy);
  const F=FIT[o.cls],L=LY[o.cls];
  // áo choàng: sau lưng, đung đưa theo bước chạy
  const cp=!legacy&&F&&L&&look.c>=0?L.cape[look.c]:null;
  if(ok(cp)){const ch=F.ch*(sw>0?.96:1),cw=ch*cp.w/cp.h,sway=mv?Math.sin(t*8.5*Math.PI/2)*.07+.12:sw>0?.18:Math.sin(G.time*2)*.03;
    ctx.save();ctx.translate(F.cx,-q.h*(1-F.cy));ctx.rotate(sway);ctx.drawImage(cp.i,-cw*.92,-ch*.06,cw,ch);ctx.restore();}
  ctx.drawImage(q.i,-q.ax,-q.h,q.w,q.h);
  // mũ: đặt trên đỉnh tóc của đúng khung hình đang vẽ
  const ht=!legacy&&F&&L&&look.h>=0?L.hat[look.h]:null;
  if(ok(ht)&&q.tp){
    // đầu lệch bao nhiêu so với khung đứng yên thì mũ lệch theo bấy nhiêu
    const hx=F.hx+(q.hc!=null&&set[0].hc!=null?q.hc-set[0].hc:0);
    const x0=hx-F.hw*.32,x1=hx+F.hw*.32,n=q.tp.length;let top=q.h;
    for(let j=0;j<n;j++){const cx=(j+.5)/n*q.w-q.ax;if(cx>=x0&&cx<=x1)top=Math.min(top,q.tp[j]);}
    const hw=F.hw,hh=hw*ht.h/ht.w,y=-q.h+top+hw*F.hb;
    ctx.drawImage(ht.i,hx-hw/2,y-hh,hw,hh);
  }
  ctx.restore();
};
}catch(err){console.error('Hoạt ảnh nhân vật lỗi:',err);}
