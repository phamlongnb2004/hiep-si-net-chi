
/* ===== HOẠT ẢNH NHÂN VẬT: đứng thở, 4 bước đi, đòn đánh (khung hình ChatGPT vẽ) ===== */
try{
const AF=window.HSNC_ANIM||{};
const FR={};
for(const k in AF){FR[k]=AF[k].map(f=>{const im=new Image();im.src=f.u;return {i:im,w:f.w,h:f.h,ax:f.ax};});}
const ready=k=>FR[k]&&FR[k].every(f=>f.i.complete&&f.i.naturalWidth);
const BOB=[0,2.2,0,2.2];          // khung chân dang (1,3) thấp, khung chân lướt qua (2,4) nảy lên
const _dh2=drawHero;
drawHero=function(o){
  const set=FR[o.cls];if(!set||!ready(o.cls))return _dh2(o);
  const t=o.t||0,mv=!!o.moving,sw=o.swing||0,face=o.face||1;
  const ph=t*8.5,fi=Math.floor(ph)%4,fr=ph-Math.floor(ph);
  let q=set[0];
  if(sw>0)q=set[5];else if(mv)q=set[1+fi];
  ctx.save();
  let al=o.alpha!=null?o.alpha:1;if(o.flash>0&&Math.floor(G.time*30)%2)al*=.5;ctx.globalAlpha=al;
  if(o.aura){const g=ctx.createRadialGradient(0,-42,5,0,-42,70);g.addColorStop(0,o.aura+'88');g.addColorStop(1,o.aura+'00');ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,-42,70,0,TAU);ctx.fill();}
  // nảy theo khung, nội suy mượt sang khung kế
  const up=mv&&sw<=0?BOB[fi]+(BOB[(fi+1)%4]-BOB[fi])*fr:0;
  // bóng co lại khi nhân vật nảy lên
  const sk=1-up*.05;
  ctx.drawImage(shadowSpr(),-28*sk,-8,56*sk,19);
  // bụi chân: một cụm nhỏ mỗi khi chân chạm đất
  if(mv&&sw<=0){const d=(fi%2===0)?fr:1;if(d<1){ctx.fillStyle='rgba(225,212,182,.75)';for(let i=0;i<3;i++){const u=d;ctx.globalAlpha=al*(1-u)*.8;ctx.beginPath();ctx.arc(-face*(6+i*7+u*10),-2-u*5-i,2+u*3.5,0,TAU);ctx.fill();}ctx.globalAlpha=al;}}
  ctx.scale(face,1);
  let sy=1,sx=1;
  if(mv&&sw<=0){ctx.rotate(.03);}                                     // nghiêng nhẹ về trước khi đi
  else if(sw<=0){const b=Math.sin(G.time*2.6+(o.t||0)*.3);sy=1+b*.016;sx=1-b*.008;} // thở khi đứng yên
  const lunge=sw>0?Math.sin(Math.min(1,(1-sw)*1.3)*Math.PI)*6:0;
  ctx.translate(lunge,-up);ctx.scale(sx,sy);
  ctx.drawImage(q.i,-q.ax,-q.h,q.w,q.h);
  ctx.restore();
};
}catch(err){console.error('Hoạt ảnh nhân vật lỗi:',err);}
