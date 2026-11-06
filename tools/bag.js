
/* ===== HÀNH TRANG (túi đồ) kiểu game mobile: cột thẻ bên trái, lưới ô đồ ở giữa, bảng thông tin + nút ở bên phải ===== */
try{
const BUI=(window.HSNC_HUD||{}).ui||{};
const bcss=`
body:has(#bag:not([hidden])) #hud{visibility:hidden}
#bag.overlay{z-index:80;background:rgba(8,12,28,.62);display:grid;place-items:center;padding:8px max(10px,env(safe-area-inset-right,0px)) 8px max(10px,env(safe-area-inset-left,0px));backdrop-filter:blur(3px)}
#bag .bg2{--k:#16224a;--g1:#ffe9a3;--g2:#f2b632;--g3:#a8650c;position:relative;width:min(860px,100%);height:min(392px,100%);display:flex;flex-direction:column;border-radius:22px;
  background:linear-gradient(180deg,#2a3a74,#18224a 60%,#131b3c);border:3px solid var(--k);box-shadow:0 0 0 3px var(--g2),0 0 0 6px var(--k),0 14px 30px rgba(0,0,0,.5);font-family:'Nunito',sans-serif;color:#eaf0ff;overflow:hidden}
#bag .bgHead{flex:none;display:flex;align-items:center;gap:10px;height:46px;padding:0 10px 0 12px;background:linear-gradient(180deg,rgba(255,255,255,.10),rgba(255,255,255,0));border-bottom:2px solid rgba(0,0,0,.25)}
#bag .bgTitle{display:flex;align-items:center;gap:6px;height:34px;padding:0 16px 0 6px;border-radius:17px;background:linear-gradient(#ffe066,#f29e0b);border:2.5px solid var(--k);box-shadow:0 3px 0 var(--k);font:800 18px/1 'Baloo 2',sans-serif;color:var(--k)}
#bag .bgTitle img{width:30px;height:30px;margin:-4px 0}
#bag .bgCur{margin-left:auto;display:flex;gap:6px}
#bag .bgCur span{display:flex;align-items:center;gap:3px;height:28px;padding:0 10px 0 3px;border-radius:14px;background:rgba(8,12,30,.6);border:2px solid rgba(255,255,255,.28);font:800 13.5px 'Nunito',sans-serif;white-space:nowrap}
#bag .bgCur img{width:24px;height:24px}
#bag .bgX{width:36px;height:36px;margin:0;padding:0;border-radius:50%;border:2.5px solid var(--k);background:radial-gradient(circle at 38% 30%,#fff,#ffb3b3 50%,#e0485f);box-shadow:0 3px 0 var(--k);font:900 17px/1 'Nunito',sans-serif;color:#fff;text-shadow:0 1.5px 0 #8a1d33;cursor:pointer}
#bag .bgX:active{transform:translateY(2px);box-shadow:0 1px 0 var(--k)}
#bag .bgBody{flex:1;min-height:0;display:grid;grid-template-columns:58px minmax(0,auto) minmax(220px,1fr);gap:10px;padding:10px}
#bag .bgTabs{display:flex;flex-direction:column;gap:8px}
#bag .bgTabs button{position:relative;width:58px;height:62px;margin:0;padding:4px 0 0;border-radius:14px;border:2.5px solid var(--k);background:linear-gradient(180deg,#3a4c8c,#26336a);box-shadow:0 3px 0 var(--k);color:#c9d6ff;font:800 10.5px/1.1 'Nunito',sans-serif;display:flex;flex-direction:column;align-items:center;gap:2px;cursor:pointer}
#bag .bgTabs button img,#bag .bgTabs button canvas{width:34px;height:34px}
#bag .bgTabs button[aria-selected=true]{background:linear-gradient(180deg,#ffe98f,#f5b52c);color:var(--k);box-shadow:0 3px 0 var(--k),0 0 0 2px #fff6 inset}
#bag .bgMain{min-width:0;display:flex;flex-direction:column;gap:8px}
#bag .bgGrid{display:grid;grid-template-columns:repeat(8,var(--cs,46px));grid-auto-rows:var(--cs,46px);gap:5px;padding:8px;border-radius:16px;background:rgba(6,10,26,.45);border:2px solid rgba(0,0,0,.35);box-shadow:inset 0 2px 6px rgba(0,0,0,.4)}
#bag .bc{position:relative;margin:0;padding:3px;border-radius:10px;border:2px solid #34437a;background:radial-gradient(circle at 50% 38%,#33447e,#1b2550 75%);box-shadow:inset 0 1px 0 rgba(255,255,255,.12);cursor:pointer;overflow:visible}
#bag .bc.empty{background:rgba(255,255,255,.04);border:2px dashed rgba(160,180,255,.18);box-shadow:none;cursor:default}
#bag .bc canvas,#bag .bc img.ic{display:block;width:100%;height:100%;object-fit:contain;pointer-events:none;filter:drop-shadow(0 2px 1px rgba(0,0,0,.45))}
#bag .bc.r1{border-color:#3f86ff;background:radial-gradient(circle at 50% 40%,#3a63c6,#1b2a63 75%);box-shadow:inset 0 0 8px rgba(80,150,255,.55)}
#bag .bc.r2{border-color:#b464f0;background:radial-gradient(circle at 50% 40%,#7a45c0,#2a1d5c 75%);box-shadow:inset 0 0 9px rgba(190,110,255,.6)}
#bag .bc.r3{border-color:#ffb31f;background:radial-gradient(circle at 50% 40%,#d7841c,#4a2a10 78%);box-shadow:inset 0 0 10px rgba(255,190,60,.75),0 0 6px rgba(255,180,40,.55);animation:bgGlow 1.6s ease-in-out infinite}
@keyframes bgGlow{50%{box-shadow:inset 0 0 14px rgba(255,210,90,.95),0 0 10px rgba(255,190,50,.8)}}
#bag .bc.sel{outline:3px solid #fff;outline-offset:1px;box-shadow:0 0 0 5px var(--g2)}
#bag .bc.oc canvas{filter:grayscale(.75) brightness(.7)}
#bag .bc .lv{position:absolute;left:-2px;bottom:-3px;padding:0 4px;border-radius:6px;background:rgba(8,12,30,.85);font:800 9.5px/14px 'Nunito',sans-serif;color:#fff}
#bag .bc .up{position:absolute;right:-3px;top:-4px;padding:0 4px;border-radius:6px;background:linear-gradient(#ffe066,#f29e0b);border:1.5px solid var(--k);font:900 9.5px/12px 'Nunito',sans-serif;color:var(--k)}
#bag .bc .n{position:absolute;right:-2px;bottom:-3px;padding:0 4px;border-radius:6px;background:rgba(8,12,30,.85);font:800 11px/15px 'Nunito',sans-serif;color:#fff}
#bag .bc .better{position:absolute;right:-3px;bottom:-4px;width:16px;height:16px;border-radius:50%;background:#2fbf63;border:1.5px solid #0b3a1c;color:#fff;font:900 10px/13px 'Nunito',sans-serif;text-align:center}
#bag .bc .lock{position:absolute;right:-3px;top:-4px;width:17px;height:17px;border-radius:50%;background:#e0485f;border:1.5px solid #5a0f1d;display:grid;place-items:center}
#bag .bc .lock img{width:12px;height:12px}
#bag .bgFoot{display:flex;align-items:center;gap:8px;font:800 12.5px 'Nunito',sans-serif;color:#c9d6ff}
#bag .bgFoot .cap{padding:3px 10px;border-radius:10px;background:rgba(8,12,30,.5)}
#bag .bgFoot .cap.full{color:#ff8fa3}
#bag .bb{margin:0;height:34px;padding:0 14px;border-radius:12px;border:2.5px solid var(--k);background:linear-gradient(180deg,#8fd0ff,#3a8de0);box-shadow:0 3px 0 var(--k),inset 0 2px 0 rgba(255,255,255,.55);font:800 13.5px/1 'Nunito',sans-serif;color:#fff;text-shadow:0 1.5px 0 rgba(0,0,0,.35);cursor:pointer;white-space:nowrap}
#bag .bb:active{transform:translateY(2px);box-shadow:0 1px 0 var(--k)}
#bag .bb:disabled{filter:grayscale(1);opacity:.55;cursor:default;transform:none}
#bag .bb.gold{background:linear-gradient(180deg,#ffe98f,#f5a623);color:var(--k);text-shadow:none}
#bag .bb.red{background:linear-gradient(180deg,#ffa0b2,#e0485f)}
#bag .bb.sm{height:28px;padding:0 10px;font-size:12px}
#bag .bgInfo{min-width:0;display:flex;flex-direction:column;gap:6px;padding:10px 12px;border-radius:16px;background:linear-gradient(180deg,rgba(255,255,255,.07),rgba(255,255,255,.02));border:2px solid rgba(0,0,0,.3);overflow:auto}
#bag .bgInfo .ih{display:flex;gap:10px;align-items:center}
#bag .bgInfo .ii{flex:none;width:58px;height:58px;padding:4px;border-radius:12px}
#bag .bgInfo .ii canvas,#bag .bgInfo .ii img{width:100%;height:100%;object-fit:contain}
#bag .bgInfo h4{margin:0;font:800 16.5px/1.15 'Baloo 2',sans-serif;text-shadow:0 1.5px 0 rgba(0,0,0,.5)}
#bag .bgInfo .chip{display:inline-block;margin-top:3px;padding:1px 8px;border-radius:8px;font:800 11px/16px 'Nunito',sans-serif;color:#fff}
#bag .bgInfo .ln{display:flex;justify-content:space-between;gap:8px;font:700 13px/1.35 'Nunito',sans-serif;color:#c9d6ff}
#bag .bgInfo .ln b{color:#fff;font-weight:800}
#bag .bgInfo .ln.bad b{color:#ff8fa3}
#bag .bgInfo .st{font:800 13.5px/1.35 'Nunito',sans-serif;color:#7dffa8}
#bag .bgInfo .st i{font-style:normal;font-weight:800;margin-left:6px}
#bag .bgInfo .st i.u{color:#7dffa8}#bag .bgInfo .st i.d{color:#ff8fa3}#bag .bgInfo .st i.s{color:#9aa6c8}
#bag .bgInfo .note{font:700 12px/1.35 'Nunito',sans-serif;color:#9fb0e0}
#bag .bgInfo hr{width:100%;margin:2px 0;border:0;border-top:1.5px dashed rgba(160,180,255,.25)}
#bag .bgInfo .btns{margin-top:auto;display:flex;gap:8px;flex-wrap:wrap;padding-top:4px}
#bag .bgInfo .btns .bb{flex:1}
/* thẻ nhân vật */
#bag .bgChar{display:grid;grid-template-columns:64px minmax(130px,1fr) 64px;grid-template-rows:auto auto;gap:8px 10px;align-items:center;padding:8px;border-radius:16px;background:rgba(6,10,26,.45);border:2px solid rgba(0,0,0,.35)}
#bag .bgChar .pv{grid-row:1/3;grid-column:2;height:150px;border-radius:14px;background:radial-gradient(circle at 50% 70%,#4a63b8,#1b2550 70%);display:grid;place-items:center;position:relative}
#bag .bgChar .pv canvas{width:150px;height:160px}
#bag .bgChar .pv .nm{position:absolute;left:0;right:0;bottom:4px;text-align:center;font:800 12.5px 'Baloo 2',sans-serif;color:#ffd86b;text-shadow:0 1.5px 0 #000}
#bag .bgChar .es{display:flex;flex-direction:column;align-items:center;gap:2px;font:800 10.5px 'Nunito',sans-serif;color:#9fb0e0}
#bag .bgChar .es .bc{width:58px;height:58px}
#bag .bgStats{display:grid;grid-template-columns:1fr 1fr;gap:3px 14px;padding:8px 12px;border-radius:14px;background:rgba(6,10,26,.35)}
#bag .bgStats div{display:flex;justify-content:space-between;font:700 12.5px 'Nunito',sans-serif;color:#c9d6ff}
#bag .bgStats b{color:#fff}
@media (max-height:380px){#bag .bg2{height:100%}#bag .bgHead{height:40px}#bag .bgBody{padding:8px;gap:8px}#bag .bgTabs button{height:54px}#bag .bgChar .pv{height:120px}#bag .bgChar .pv canvas{width:120px;height:128px}}
@media (max-width:640px){#bag .bgBody{grid-template-columns:50px minmax(0,auto) minmax(170px,1fr)}#bag .bgTabs button{width:50px}#bag .bgCur span:nth-child(2){display:none}}
`;
const st=document.createElement('style');st.textContent=bcss;document.head.append(st);

const BAG={tab:'inv',sellArm:-1};
const bag=$('bag');for(const c of bag.children)c.style.display='none';   // giữ khung cũ (mã khởi động còn dùng), chỉ ẩn đi
const root=el('div','bg2');bag.append(root);
const head=el('div','bgHead'),ttl=el('div','bgTitle'),cur=el('div','bgCur'),bx=el('button','bgX','✕');bx.type='button';bx.setAttribute('aria-label','Đóng (I)');
const icon=(k,c)=>{const i=document.createElement('img');i.src=BUI[k]||'';i.alt='';if(c)i.className=c;return i;};
ttl.append(icon('bag'),document.createTextNode('Hành Trang'));head.append(ttl,cur,bx);
const body=el('div','bgBody'),tabs=el('nav','bgTabs'),main=el('div','bgMain'),info=el('aside','bgInfo');body.append(tabs,main,info);root.append(head,body);
bx.onclick=()=>closeBag();
const tInv=el('button');tInv.type='button';tInv.append(icon('bag'),el('span','','Túi đồ'));
const tChar=el('button');tChar.type='button';const tcv=document.createElement('canvas');tChar.append(tcv,el('span','','Nhân vật'));
tabs.append(tInv,tChar);
tInv.onclick=()=>{BAG.tab='inv';sel=null;renderBag();};tChar.onclick=()=>{BAG.tab='char';sel=null;renderBag();};

const fmt=n=>Math.round(n).toLocaleString('vi-VN');
const rc=it=>RAR[it.r].c==='#8a93a8'?'#e6ecff':RAR[it.r].c;
const own=it=>!it.cls||it.cls===P.cls;
// một ô đồ (trang bị hoặc vật phẩm xếp chồng)
function cell(it,isSel,onTap){
  const b=el('button','bc');b.type='button';
  if(!it){b.classList.add('empty');b.disabled=true;return b;}
  if(it.stack){b.append(icon(it.stack,'ic'),el('span','n',String(it.n)));}
  else{
    b.classList.add('r'+it.r);const ic=iconCanvas(it,56,true);b.append(ic,el('span','lv','Lv'+it.lvl));
    if(it.up)b.append(el('span','up','+'+it.up));
    if(!own(it)){b.classList.add('oc');const l=el('span','lock');l.append(icon('lock'));b.append(l);}
    else if(BAG.tab==='inv'&&score(it)>score(P.eq[it.slot]))b.append(el('span','better','▲'));
    b.setAttribute('aria-label',it.name);
  }
  if(isSel)b.classList.add('sel');
  b.onclick=onTap;return b;
}
function statRows(it,cmp){
  const out=[];for(const k of ['atk','def','hp','spd']){const v=E(it,k),c=cmp?E(cmp,k):0;if(!v&&!c)continue;
    const p=el('div','st','+'+fmt(v)+' '+STAT_N[k]);
    if(cmp){const d=v-c;p.append(el('i',d>0?'u':d<0?'d':'s',d>0?'▲'+fmt(d):d<0?'▼'+fmt(-d):'='));}
    out.push(p);}
  return out;
}
const line=(a,b,bad)=>{const d=el('div','ln'+(bad?' bad':''));d.append(el('span','',a),el('b','',String(b)));return d;};
function infoEmpty(){
  info.append(el('h4','',BAG.tab==='inv'?'Chọn một món đồ':'Trang phục đang mặc'));
  info.append(el('div','note',BAG.tab==='inv'?'Chạm vào ô để xem chỉ số và so sánh với đồ đang mặc. ▲ xanh: tốt hơn đồ đang mặc. Ổ khoá đỏ: đồ của phái khác.':'Chạm vào ô trang bị để xem hoặc tháo ra. Mặc áo để đổi diện mạo nhân vật; cường hoá đồ ở Thợ Rèn Cương trong Làng.'));
  info.append(el('hr'));
  info.append(line('Bình máu',P.pots+' / 20'),line('Đá cường hoá',P.stones),line('Vàng',fmt(P.gold)));
}
function infoItem(it,from,idx){
  const ih=el('div','ih'),ii=el('div','bc ii r'+it.r);ii.append(iconCanvas(it,64,true));
  const t=el('div');const h=el('h4','',iname(it));h.style.color=rc(it);t.append(h);
  const ch=el('span','chip',RAR[it.r].n+' · '+SLOT_N[it.slot]);ch.style.background=RAR[it.r].c;t.append(ch);ih.append(ii,t);info.append(ih);
  info.append(line('Cấp đồ',it.lvl));
  if(it.cls)info.append(line('Phái',CLS[it.cls].n+(own(it)?'':' – không mặc được'),!own(it)));
  if(it.up)info.append(line('Cường hoá','+'+it.up));
  info.append(el('hr'));
  const cmp=from==='inv'&&own(it)?P.eq[it.slot]:null;
  statRows(it,cmp).forEach(r=>info.append(r));
  if(from==='inv'&&own(it))info.append(el('div','note',cmp?'So với '+iname(cmp)+' đang mặc':'Ô '+SLOT_N[it.slot].toLowerCase()+' đang trống'));
  if(it.slot==='armor'&&it.cls&&own(it)&&window.SETN_)info.append(el('div','note','Bộ '+SETN_[it.cls][it.tier|0]+': mặc vào đổi diện mạo.'));
  const bt=el('div','btns');
  if(from==='inv'){
    const be=el('button','bb gold',own(it)?'Mặc':'Khác phái');be.type='button';be.disabled=!own(it);
    be.onclick=()=>{const item=P.inv[idx],old=P.eq[item.slot];P.eq[item.slot]=item;P.inv.splice(idx,1);if(old)P.inv.push(old);sel=null;recalc(true);save();renderBag();};
    const price=sellPrice(it),arm=BAG.sellArm===idx,bs=el('button','bb red',arm?'Bán thật? +'+fmt(price):'Bán +'+fmt(price));bs.type='button';
    bs.onclick=()=>{if(it.r>=2&&!arm){BAG.sellArm=idx;renderBag();return;}P.gold+=price;P.inv.splice(idx,1);sel=null;BAG.sellArm=-1;save();renderBag();};
    bt.append(be,bs);
  }else{
    const bu=el('button','bb',P.inv.length>=30?'Túi đầy':'Tháo ra');bu.type='button';bu.disabled=P.inv.length>=30;
    bu.onclick=()=>{const item=P.eq[sel.slot];P.eq[sel.slot]=null;P.inv.push(item);sel=null;recalc(true);save();renderBag();};bt.append(bu);
  }
  info.append(bt);
}
function infoStack(k){
  const ih=el('div','ih'),ii=el('div','bc ii');ii.append(icon(k));const t=el('div');
  if(k==='pot'){
    t.append(el('h4','','Bình Máu'));const ch=el('span','chip','Tiêu hao');ch.style.background='#e0485f';t.append(ch);ih.append(ii,t);info.append(ih);
    info.append(el('div','st','Hồi 45% máu tối đa'),line('Đang có',P.pots+' / 20'),el('div','note','Phím H hoặc nút bình máu khi đang đánh.'));
    const bt=el('div','btns'),bu=el('button','bb gold','Dùng');bu.type='button';bu.disabled=P.pots<=0||P.hp>=P.maxHp;bu.onclick=()=>{usePotion();renderBag();};
    const bb=el('button','bb','Mua (30 vàng)');bb.type='button';bb.disabled=P.gold<30||P.pots>=20;bb.onclick=()=>{if(P.gold>=30&&P.pots<20){P.gold-=30;P.pots++;save();renderBag();}};
    bt.append(bu,bb);info.append(bt);
  }else{
    t.append(el('h4','','Đá Cường Hoá'));const ch=el('span','chip','Nguyên liệu');ch.style.background='#3a8de0';t.append(ch);ih.append(ii,t);info.append(ih);
    info.append(line('Đang có',P.stones),el('div','note','Rơi ra khi đánh quái. Mang tới Thợ Rèn Cương trong Làng để cường hoá trang bị.'));
  }
}
const _drawPrev=drawBagPreview;
const pvC=document.createElement('canvas');setupCanvas(pvC,150,160);
drawBagPreview=function(){
  if(BAG.tab!=='char'||!P)return;
  withCanvas(pvC,150,160,()=>{ctx.translate(75,146);ctx.scale(1.85,1.85);seed(3);drawHero({cls:P.cls,face:1,t:G.time,moving:false,swing:0,eq:P.eq,aura:auraOf()});});
};
setupCanvas(tcv,34,34);
renderBag=function(){
  if(!P)return;
  // tiêu đề: tiền
  cur.replaceChildren();const cg=el('span');cg.append(icon('gold'),el('b','',fmt(P.gold)));const cs=el('span');cs.append(icon('stone'),el('b','',fmt(P.stones)));cur.append(cg,cs);
  tInv.setAttribute('aria-selected',String(BAG.tab==='inv'));tChar.setAttribute('aria-selected',String(BAG.tab==='char'));
  withCanvas(tcv,34,34,()=>{ctx.translate(17,33);ctx.scale(.42,.42);seed(3);drawHero({cls:P.cls,face:1,t:0,moving:false,swing:0,eq:P.eq});});
  main.replaceChildren();info.replaceChildren();
  let it=null;if(sel){it=sel.from==='inv'?P.inv[sel.idx]:sel.from==='eq'?P.eq[sel.slot]:{stack:sel.k};if(!it)sel=null;}
  if(!sel||sel.from!=='inv'||sel.idx!==BAG.sellArm)BAG.sellArm=-1;
  if(BAG.tab==='inv'){
    const g=el('div','bgGrid');
    // ô kích thước theo chỗ trống (vừa màn hình điện thoại nằm ngang)
    const H=root.clientHeight||360,cs=Math.max(34,Math.min(48,Math.floor((H-46-20-8-40-16-15)/4)));g.style.setProperty('--cs',cs+'px');
    g.append(cell({stack:'pot',n:P.pots},sel&&sel.k==='pot',()=>{sel={from:'stk',k:'pot'};renderBag();}));
    g.append(cell({stack:'stone',n:P.stones},sel&&sel.k==='stone',()=>{sel={from:'stk',k:'stone'};renderBag();}));
    for(let i=0;i<30;i++){const x=P.inv[i];g.append(cell(x,!!(sel&&sel.from==='inv'&&sel.idx===i),()=>{sel={from:'inv',idx:i};renderBag();}));}
    const ft=el('div','bgFoot'),cp=el('span','cap'+(P.inv.length>=30?' full':''),'Túi: '+P.inv.length+' / 30');
    const so=el('button','bb sm','Sắp xếp');so.type='button';so.onclick=()=>{const ord={weapon:0,armor:1,hat:2,cape:3};P.inv.sort((a,b)=>(own(b)-own(a))||(b.r-a.r)||(ord[a.slot]-ord[b.slot])||(b.lvl-a.lvl));sel=null;save();renderBag();};
    const sj=el('button','bb sm red','Bán đồ thường');sj.type='button';const junk=P.inv.filter(x=>x.r===0&&!(own(x)&&score(x)>score(P.eq[x.slot])));sj.disabled=!junk.length;
    sj.title='Bán hết đồ Thường không tốt hơn đồ đang mặc';
    sj.onclick=()=>{let g2=0;P.inv=P.inv.filter(x=>{if(junk.includes(x)){g2+=sellPrice(x);return false;}return true;});P.gold+=g2;sel=null;save();renderBag();if(g2)log('Bán '+junk.length+' món đồ thường được '+g2+' vàng.','#ffd86b');};
    ft.append(cp,so,sj);main.append(g,ft);
  }else{
    const c=el('div','bgChar');
    const slotEl=(k,col,row)=>{const w=el('div','es');w.style.gridColumn=col;w.style.gridRow=row;const x=P.eq[k];
      w.append(cell(x||null,!!(sel&&sel.from==='eq'&&sel.slot===k),()=>{sel={from:'eq',slot:k};renderBag();}),el('span','',SLOT_N[k]));
      if(!x){const b=w.firstChild;b.disabled=true;}return w;};
    const pv=el('div','pv');pv.append(pvC,el('div','nm',P.name+' · '+CLS[P.cls].n));
    c.append(slotEl('hat',1,1),pv,slotEl('armor',3,1),slotEl('weapon',1,2),slotEl('cape',3,2));
    const sg=el('div','bgStats');
    [['Cấp',P.lv],['Máu',fmt(P.maxHp)],['Công',fmt(P.atk)],['Thủ',fmt(P.def)],['Tốc',Math.round(P.spd)],['Chí mạng',Math.round(P.crit*100)+'%'],['Hạ quái',fmt(P.kills)],['Đá',P.stones]].forEach(r=>{const d=el('div');d.append(el('span','',r[0]),el('b','',String(r[1])));sg.append(d);});
    main.append(c,sg);drawBagPreview();
  }
  if(!sel)infoEmpty();else if(sel.from==='stk')infoStack(sel.k);else infoItem(it,sel.from,sel.idx);
};
}catch(err){console.error('Hành trang lỗi:',err);}
