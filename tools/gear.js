
/* ===== TRANG BỊ THEO PHÁI: 4 bộ đồ mỗi phái (Thường → Huyền Thoại), icon ChatGPT vẽ, mặc áo đổi diện mạo ===== */
try{
const GA=window.HSNC_GEAR||{};
const SLOTI={hat:0,armor:1,cape:2,weapon:3};
// tên bộ đồ theo phái và cấp hiếm
const SETN={
  sword:['Tân Binh','Lam Ưng','Tử Vương','Long Thần'],
  archer:['Lá Rừng','Ngân Diệp','Tinh Dạ','Phượng Hoàng'],
  mage:['Tập Sự','Băng Tuyết','Nguyệt Ảnh','Thái Dương'],
  fighter:['Bóng Đêm','Lam Phong','Quỷ Ảnh','Hỏa Long']};
const NOUN={
  sword:{hat:'Mũ Giáp',armor:'Giáp Kỵ Sĩ',cape:'Áo Choàng',weapon:'Kiếm'},
  archer:{hat:'Mũ Trùm',armor:'Áo Giáp Lá',cape:'Áo Choàng',weapon:'Cung'},
  mage:{hat:'Nón Phép',armor:'Pháp Bào',cape:'Khăn Choàng',weapon:'Trượng'},
  fighter:{hat:'Khăn Đầu',armor:'Võ Phục',cape:'Khăn Choàng',weapon:'Găng Vuốt'}};
const CLSK=Object.keys(SETN);
// tỉ lệ hiếm: quái thường rất ít ra đồ xịn, trùm dễ hơn
const W_MOB=[80,16.5,3.1,.4],W_BOSS=[30,48,18.5,3.5];
RAR.forEach((r,i)=>{r.w=W_MOB[i];});
const pickW=ws=>{let x=Math.random()*ws.reduce((a,b)=>a+b),k=0;for(;k<ws.length;k++){x-=ws[k];if(x<0)break;}return Math.min(k,ws.length-1);};

/* --- ảnh icon --- */
const GI={};let gLeft=0;
for(const c in GA){GI[c]=GA[c].map(row=>row.map(u=>{const im=new Image();gLeft++;im.onload=im.onerror=()=>{if(--gLeft===0){ICONS.clear();G.drops&&G.drops.forEach(d=>{d.ic=null;});}};im.src=u;return im;}));}
const gImg=it=>{const r=GI[it.cls]&&GI[it.cls][it.tier|0];const im=r&&r[SLOTI[it.slot]];return im&&im.complete&&im.naturalWidth?im:null;};

/* --- tạo đồ --- */
const _gi=genItem;
genItem=function(lvl,boss,cls){
  // 3/4 số đồ rơi ra đúng phái đang chơi, còn lại là đồ phái khác (bán lấy vàng)
  const c=Math.random()<.75&&SETN[cls]?cls:CLSK[ri(0,CLSK.length-1)];
  const rk=pickW(boss?W_BOSS:W_MOB),R=RAR[rk],m=R.m,base=3+lvl*1.4,slot=pick(SLOT_ORDER),st={};
  if(slot==='hat'){st.def=Math.round(base*.6*m);st.hp=Math.round(base*3*m);}
  else if(slot==='armor'){st.def=Math.round(base*m);st.hp=Math.round(base*5*m);}
  else if(slot==='cape'){st.spd=Math.round((2+lvl*.3)*m);st.def=Math.round(base*.4*m);}
  else st.atk=Math.round(base*1.3*m);
  return{id:Date.now()+Math.random(),slot,cls:c,tier:rk,style:0,wk:slot==='weapon'?c:undefined,col:R.c.length===7?R.c:'#8a93a8',r:rk,lvl,name:NOUN[c][slot]+' '+SETN[c][rk],st};
};
// đồ cũ (trước khi có phái) thuộc về phái của nhân vật
const fixIt=(it,cls)=>{if(!it)return;if(!SETN[it.cls])it.cls=SETN[it.wk]?it.wk:cls;it.tier=clamp(it.r|0,0,3);if(it.slot==='weapon')it.wk=it.cls;};
const _sg=startGame;
startGame=function(...a){
  _sg(...a);
  if(P){P.inv.forEach(it=>fixIt(it,P.cls));for(const k of SLOT_ORDER){const it=P.eq[k];fixIt(it,P.cls);if(it&&it.cls!==P.cls){P.eq[k]=null;if(P.inv.length<30)P.inv.push(it);}}recalc(true);}
};
// diện mạo ghép từng món: thân theo bộ của áo, mũ và áo choàng là lớp riêng theo bộ của chính món đó (-1 = không mặc)
const tierOf=it=>it&&(!P||it.cls===P.cls)?clamp(it.tier|0,0,3):-1;
window.HSNC_TIER=eq=>tierOf(eq&&eq.armor);   // -1 = chưa mặc áo (quần áo vải thô)
window.HSNC_LOOK=eq=>({a:tierOf(eq&&eq.armor),h:tierOf(eq&&eq.hat),c:tierOf(eq&&eq.cape)});
// gói gọn để gửi qua mạng: một số 0..99
window.HSNC_LOOKN=eq=>{const l=HSNC_LOOK(eq);return (l.a+1)+5*(l.h+1)+25*(l.c+1);};

/* --- vẽ icon --- */
const _dia2=drawItemArt;
drawItemArt=function(it){
  const im=gImg(it);if(!im)return _dia2(it);
  const S=86,f=S/Math.max(im.naturalWidth,im.naturalHeight),w=im.naturalWidth*f,h=im.naturalHeight*f;
  if(it.r>=1){const rc=RAR[it.r].c,g=ctx.createRadialGradient(48,48,4,48,48,52);g.addColorStop(0,rc+'66');g.addColorStop(1,rc+'00');ctx.fillStyle=g;ctx.fillRect(0,0,96,96);}
  ctx.fillStyle='rgba(27,34,51,.18)';ctx.beginPath();ctx.ellipse(48,90,28,4.5,0,0,TAU);ctx.fill();
  ctx.drawImage(im,48-w/2,48-h/2,w,h);
  if(it.r>=2){const rc=RAR[it.r].c;sparkle(12,16,7,rc);sparkle(84,22,5,'#fff6c9');if(it.r>=3){sparkle(82,78,6,rc);sparkle(12,72,4,'#fff6c9');}}
};

/* --- đồ rơi trên đất: nhỏ gọn --- */
const _dd2=drawDrop;
drawDrop=function(d){
  if(d.k!=='item'||!d.item)return _dd2(d);
  const it=d.item,R=RAR[it.r],bob=Math.sin(G.time*4+d.x)*2.2,S=it.r>=2?34:30;
  ctx.save();ctx.translate(d.x,d.y);
  ctx.fillStyle='rgba(27,34,51,.22)';ctx.beginPath();ctx.ellipse(0,1,10,3.5,0,0,TAU);ctx.fill();
  if(it.r>=1){const g=ctx.createRadialGradient(0,-14+bob,1,0,-14+bob,22);g.addColorStop(0,R.c+'aa');g.addColorStop(1,R.c+'00');ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,-14+bob,22,0,TAU);ctx.fill();}
  if(!d.ic)d.ic=iconCanvas(it,48);
  ctx.drawImage(d.ic,-S/2,-S-2+bob,S,S);
  if(it.r>=3){ctx.globalCompositeOperation='lighter';const a=.35+Math.sin(G.time*5)*.15;const g=ctx.createLinearGradient(0,-90,0,0);g.addColorStop(0,'rgba(255,200,60,0)');g.addColorStop(1,'rgba(255,200,60,'+a+')');ctx.fillStyle=g;ctx.fillRect(-4,-90,8,88);ctx.globalCompositeOperation='source-over';}
  ctx.restore();
};

/* --- túi đồ: chỉ mặc được đồ cùng phái --- */
const css=document.createElement('style');css.textContent=`
#grid .cell.oc{filter:grayscale(.55);opacity:.72}
#grid .cell .cl{position:absolute;left:2px;top:2px;font:800 9.5px/1 'Nunito',sans-serif;color:#fff;background:#16224a;border-radius:6px;padding:2px 4px}
#detail .clsn{font-weight:800}#detail .clsn.bad{color:#d9345a}
`;document.head.append(css);
const _rb=renderBag;
renderBag=function(){
  _rb();
  const cells=$('grid').children;
  for(let i=0;i<cells.length;i++){const it=P.inv[i];if(it&&it.cls&&it.cls!==P.cls){cells[i].classList.add('oc');cells[i].append(el('div','cl',CLS[it.cls].n));}}
  let it=null;if(sel)it=sel.from==='inv'?P.inv[sel.idx]:P.eq[sel.slot];
  if(!it||!it.cls)return;
  const d=$('detail'),own=it.cls===P.cls,p=el('p','clsn'+(own?'':' bad'),'Phái: '+CLS[it.cls].n+(own?'':' (bạn không mặc được)'));
  const h=d.querySelector('h4');if(h&&h.nextSibling)d.insertBefore(p,h.parentNode.nextSibling);else d.append(p);
  if(it.slot==='armor'&&own)d.insertBefore(el('p','','Bộ '+SETN[it.cls][it.tier|0]+': mặc vào sẽ đổi diện mạo nhân vật.'),p.nextSibling);
  if(!own&&sel.from==='inv'){const b=[...d.querySelectorAll('.btnrow button')].find(x=>x.textContent==='Mặc');if(b){b.disabled=true;b.textContent='Không cùng phái';}}
};
}catch(err){console.error('Trang bị lỗi:',err);}
