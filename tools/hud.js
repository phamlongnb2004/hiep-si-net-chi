
/* ===== GIAO DIỆN TRONG GAME KIỂU MOBILE CHIBI: chân dung + thanh máu, nút đánh tròn lớn, kỹ năng xếp vòng cung ===== */
try{
const HA=window.HSNC_HUD||{skills:{},ui:{}},UIC=HA.ui||{};
const css=`
#app #hud{--hk:#16224a;--hg1:#ffe9a3;--hg2:#f2b632;--hg3:#a8650c;font-family:'Nunito',sans-serif}
#app #hud .hz{position:absolute;pointer-events:none}
/* --- chân dung + máu --- */
#app #hud #statPlate{top:calc(8px + env(safe-area-inset-top,0px));left:max(10px,env(safe-area-inset-left,0px));width:auto;min-width:0;background:none;border:0;box-shadow:none;padding:0;display:flex;align-items:center;gap:0}
#hud .hpAv{position:relative;z-index:2;width:66px;height:66px;border-radius:50%;flex:none;border:3px solid var(--hk);background:radial-gradient(circle at 50% 35%,#fdf6d8,#9fc7ff 70%,#5b86d6);box-shadow:0 0 0 3px var(--hg2),0 0 0 6px var(--hk),0 6px 12px rgba(0,0,0,.35);overflow:hidden}
#hud .hpAv i{position:absolute;inset:0;background-repeat:no-repeat;background-size:auto 205%;background-position:50% 4%}
#hud .hpLv{position:absolute;z-index:3;left:44px;top:46px;min-width:30px;height:24px;padding:0 6px;border-radius:12px;background:linear-gradient(#ffe066,#f29e0b);border:2.5px solid var(--hk);font:800 13px/19px 'Baloo 2',sans-serif;color:var(--hk);text-align:center;box-shadow:0 2px 0 var(--hk)}
#hud .hpBox{margin-left:-14px;padding:6px 14px 8px 22px;min-width:0;width:clamp(170px,26vw,240px);background:linear-gradient(180deg,rgba(32,46,92,.92),rgba(16,24,52,.92));border:2.5px solid var(--hk);border-radius:0 18px 18px 0;box-shadow:inset 0 1.5px 0 rgba(255,255,255,.25),0 5px 10px rgba(0,0,0,.3)}
#app #hud #statPlate .who{display:flex;align-items:baseline;gap:7px;color:#fff;font:800 14.5px/1.1 'Baloo 2',sans-serif;white-space:nowrap;overflow:hidden}
#app #hud #statPlate .who span{font:700 12px 'Nunito',sans-serif;color:#ffd86b}
#app #hud #statPlate .who span:last-child{display:none}
#app #hud #statPlate .bar{height:15px;margin-top:4px;border:2px solid #0b1020;border-radius:9px;background:#0b1020}
#app #hud #statPlate .bar.xp{height:9px;margin-top:3px;border-width:1.5px}
#app #hud #statPlate .bar.hp i{border-radius:7px;background:linear-gradient(180deg,#ff9fb3,#f0385f 55%,#b41c43)}
#app #hud #statPlate .bar.xp i{border-radius:5px;background:linear-gradient(180deg,#fff3a8,#ffcb2f 55%,#e08e00)}
#app #hud #statPlate .bar span{font:800 11px 'Nunito',sans-serif}
#app #hud #statPlate .bar.xp span{display:none}
/* --- tiền tệ --- */
#hud .hcur{position:absolute;top:calc(10px + env(safe-area-inset-top,0px));left:50%;transform:translateX(-50%);display:flex;gap:6px;pointer-events:none}
#hud .hcur div{display:flex;align-items:center;gap:3px;height:26px;padding:0 10px 0 3px;border-radius:14px;background:rgba(14,22,48,.78);border:2px solid rgba(255,255,255,.35);color:#fff;font:800 13.5px 'Nunito',sans-serif;white-space:nowrap}
#hud .hcur img{width:24px;height:24px;margin:-2px 0}
#hud .hcur b{font-weight:800}
/* --- góc phải: bản đồ + nút tròn --- */
#app #hud #infoPlate{top:calc(8px + env(safe-area-inset-top,0px));right:max(10px,env(safe-area-inset-right,0px));width:auto;background:none;border:0;box-shadow:none;padding:0;display:flex;gap:8px;align-items:flex-start;pointer-events:none}
#hud .hmap{position:relative;pointer-events:auto}
#app #hud #mini{display:block;margin:0;width:118px;height:78px;border:3px solid var(--hk);border-radius:14px;box-shadow:0 0 0 2.5px var(--hg2),0 0 0 5px var(--hk),0 6px 12px rgba(0,0,0,.35)}
#app #hud #zoneName{position:absolute;left:50%;bottom:-13px;transform:translateX(-50%);max-width:132px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin:0;padding:1px 10px;border-radius:10px;background:linear-gradient(#ffe066,#f29e0b);border:2px solid var(--hk);color:var(--hk);font:800 11.5px/1.3 'Baloo 2',sans-serif}
#hud .hico{display:flex;flex-direction:column;gap:6px;pointer-events:auto}
#app #hud .ib{position:relative;width:44px;height:44px;margin:0;padding:0;border-radius:50%;border:2.5px solid var(--hk);background:radial-gradient(circle at 35% 28%,#fff,#d9ecff 50%,#8fb7f0);box-shadow:0 3px 0 var(--hk),0 5px 8px rgba(0,0,0,.3);display:grid;place-items:center;font-size:0;color:transparent;cursor:pointer;pointer-events:auto;top:auto;left:auto;right:auto;bottom:auto}
#app #hud .ib img{width:32px;height:32px;pointer-events:none}
#app #hud .ib:active{transform:translateY(2px);box-shadow:0 1px 0 var(--hk)}
#app #hud .ib small{position:absolute;right:-5px;bottom:-5px;font:800 9.5px/14px 'Nunito',sans-serif;color:#fff;background:var(--hk);border-radius:7px;padding:0 4px}
.touch #hud .ib small{display:none}
#hud .hico2{display:flex;flex-direction:column;gap:6px}
/* --- cụm nút chiến đấu --- */
#app #hud #btns{position:absolute;right:max(14px,env(safe-area-inset-right,0px));bottom:calc(14px + env(safe-area-inset-bottom,0px));width:96px;height:96px;display:block;pointer-events:none;transform-origin:100% 100%;transform:scale(var(--hs,1))}
#app #hud #sbar{position:absolute;right:max(14px,env(safe-area-inset-right,0px));bottom:calc(14px + env(safe-area-inset-bottom,0px));width:96px;height:96px;display:block;pointer-events:none;transform-origin:100% 100%;transform:scale(var(--hs,1))}
#app #hud .rbtn,#app #hud .sbtn{position:absolute;left:50%;top:50%;margin:0;padding:0;border-radius:50%;overflow:hidden;display:grid;place-items:center;pointer-events:auto;font-size:0;line-height:1}
#app #hud .rbtn span,#app #hud .sbtn > b{display:none}
#app #hud .rbtn img,#app #hud .sbtn img{position:relative;pointer-events:none}
#app #hud .rbtn.atk{width:96px;height:96px;transform:translate(-50%,-50%);border:4px solid var(--hk);background:radial-gradient(circle at 38% 30%,#fff7c7,#ffd23f 45%,#e98b00 80%,#b85d00);box-shadow:0 0 0 3px #fff3,0 5px 0 var(--hk),0 10px 18px rgba(0,0,0,.4),inset 0 -6px 10px rgba(150,60,0,.35),inset 0 4px 0 rgba(255,255,255,.7)}
#app #hud .rbtn.atk img{width:66px;height:66px;filter:drop-shadow(0 3px 0 rgba(0,0,0,.25))}
#app #hud .rbtn.atk:active{transform:translate(-50%,-46%) scale(.95)}
#app #hud .rbtn.sm{width:54px;height:54px;transform:translate(-50%,-50%);border:3px solid var(--hk);box-shadow:0 4px 0 var(--hk),0 7px 12px rgba(0,0,0,.35),inset 0 3px 0 rgba(255,255,255,.75)}
#app #hud .rbtn.sm img{width:38px;height:38px}
#app #hud .rbtn.sm:active{transform:translate(-50%,-44%)}
#app #hud #bPot{background:radial-gradient(circle at 38% 30%,#fff,#ffd3dc 50%,#f07a95)}
#app #hud #bRoll{background:radial-gradient(circle at 38% 30%,#fff,#cdf7d7 50%,#5fc77f)}
#hud .pc{position:absolute;right:-2px;bottom:-2px;min-width:20px;height:20px;padding:0 4px;border-radius:10px;background:var(--hk);color:#fff;font:800 12px/20px 'Nunito',sans-serif;text-align:center;z-index:2}
#app #hud #bPot{overflow:visible}
#app #hud .sbtn{width:56px;height:56px;transform:translate(-50%,-50%);border:3px solid var(--hk);background:#1d2950;box-shadow:0 4px 0 var(--hk),0 7px 12px rgba(0,0,0,.35)}
#app #hud .sbtn img{width:100%;height:100%;border-radius:50%}
#app #hud .sbtn .cd{position:absolute;left:0;right:0;bottom:auto;top:0;height:0;background:rgba(10,16,36,.62);z-index:1;pointer-events:none}
#app #hud .sbtn small{position:absolute;left:auto;right:3px;top:auto;bottom:2px;z-index:2;font:800 10px/1 'Nunito',sans-serif;color:#fff;opacity:1;text-shadow:0 1px 2px #000}
.touch #hud .sbtn small{display:none}
#app #hud .sbtn .lk{position:absolute;inset:0;z-index:2;display:grid;place-items:center;padding-top:20px;font:800 11px/1 'Baloo 2',sans-serif;color:#fff;text-shadow:0 1px 2px #000;opacity:1;bottom:auto}
#app #hud .sbtn .lk:empty{display:none}
#app #hud .sbtn.off{opacity:1;background:#1d2950}
#app #hud .sbtn.off img{filter:grayscale(.85) brightness(.55)}
#app #hud .sbtn.off .lk{background:url(${UIC.lock||''}) 50% 28%/22px no-repeat}
#app #hud .sbtn:active{transform:translate(-50%,-44%)}
#app #hud .sbtn.rdy{animation:hRdy .5s ease-out}
@keyframes hRdy{0%{box-shadow:0 0 0 0 #fff,0 4px 0 var(--hk)}100%{box-shadow:0 0 0 14px rgba(255,255,255,0),0 4px 0 var(--hk)}}
/* --- cần điều khiển --- */
#app #hud #joy{left:max(26px,env(safe-area-inset-left,0px));bottom:calc(22px + env(safe-area-inset-bottom,0px));width:132px;height:132px;border:0;background:radial-gradient(circle,rgba(255,255,255,.08) 0 52%,rgba(255,255,255,.28) 53% 56%,rgba(20,30,60,.18) 57% 100%);box-shadow:0 0 0 3px rgba(255,255,255,.55),0 0 0 6px rgba(22,34,74,.35)}
#app #hud #joy::before{content:"";position:absolute;inset:8px;border-radius:50%;background:conic-gradient(from -8deg,rgba(255,255,255,.6) 0 16deg,transparent 0 74deg,rgba(255,255,255,.6) 0 106deg,transparent 0 164deg,rgba(255,255,255,.6) 0 196deg,transparent 0 254deg,rgba(255,255,255,.6) 0 286deg,transparent 0 344deg,rgba(255,255,255,.6) 0);-webkit-mask:radial-gradient(circle,transparent 0 86%,#000 87%);mask:radial-gradient(circle,transparent 0 86%,#000 87%)}
#app #hud #knob{width:58px;height:58px;margin:-29px 0 0 -29px;opacity:1;border:3px solid var(--hk);background:radial-gradient(circle at 36% 30%,#fff,#d5e6ff 45%,#7ea6ec);box-shadow:0 4px 0 var(--hk),0 7px 12px rgba(0,0,0,.35)}
/* --- khác --- */
#app #hud #buffs{top:calc(86px + env(safe-area-inset-top,0px));left:max(12px,env(safe-area-inset-left,0px))}
#app #hud #log{bottom:calc(14px + env(safe-area-inset-bottom,0px));left:50%;transform:translateX(-50%);width:min(340px,calc(100% - 420px));min-width:200px;align-items:center}
.touch #app #hud #log,#app.touch #hud #log{bottom:calc(14px + env(safe-area-inset-bottom,0px))}
#app #hud #log div{font:700 13px 'Nunito',sans-serif;border-radius:12px}
#app #hud #bTalk{bottom:calc(64px + env(safe-area-inset-bottom,0px));left:50%;padding:6px 18px 6px 8px;display:flex;align-items:center;gap:6px;border-radius:22px;font:800 17px 'Baloo 2',sans-serif;background:linear-gradient(#ffe066,#ffb703);box-shadow:0 4px 0 var(--hk),0 6px 12px rgba(0,0,0,.3)}
#app #hud #bTalk[hidden]{display:none}
#app #hud #bTalk img{width:32px;height:32px}
#app #hud #hint{bottom:calc(4px + env(safe-area-inset-bottom,0px));font-size:12.5px;opacity:.6}
#app #hud #chatBtn{position:relative;left:auto;top:auto;display:grid}
#app #hud #netBadge{top:calc(42px + env(safe-area-inset-top,0px));font-size:11.5px;padding:3px 10px;opacity:.9}
@media (max-height:420px){#app #hud{--hs:.86}#app #hud #mini{width:100px;height:66px}#hud .hpAv{width:56px;height:56px}#hud .hpLv{left:36px;top:38px}#app #hud .ib{width:40px;height:40px}#app #hud .ib img{width:28px;height:28px}#app #hud #joy{width:118px;height:118px}}
@media (max-height:340px){#app #hud{--hs:.74}#hud .hcur{display:none}}
@media (max-width:640px){#hud .hcur{top:auto;bottom:calc(4px + env(safe-area-inset-bottom,0px))}}
`;
document.head.append(Object.assign(document.createElement('style'),{textContent:css}));

const img=(u,c)=>{const i=document.createElement('img');i.alt='';i.draggable=false;if(u)i.src=u;if(c)i.className=c;return i;};
const hud=$('hud');

/* chân dung */
const sp=$('statPlate');sp.classList.remove('wob');
const av=el('div','hpAv'),avI=el('i'),lvB=el('div','hpLv');av.append(avI);
const hLvE=$('hLv'),box=el('div','hpBox');while(sp.firstChild)box.append(sp.firstChild);
lvB.append(hLvE);sp.append(av,lvB,box);
let avCls='';
const setAv=()=>{if(!P)return;const t=window.HSNC_TIER?HSNC_TIER(P.eq):0,A=window.HSNC_ANIM||{},k=A['body_'+P.cls+'_'+t]?'body_'+P.cls+'_'+t:t&&A[P.cls+'_'+t]?P.cls+'_'+t:P.cls;if(k===avCls)return;avCls=k;const f=window.HSNC_ANIM&&HSNC_ANIM[k];avI.style.backgroundImage=f?'url('+f[0].u+')':'';};

/* tiền tệ */
const ip=$('infoPlate');ip.classList.remove('wob');
const cur=el('div','hcur');
[['gold','goldV'],['pot','potV'],['stone','stoneV']].forEach(([ic,id])=>{const d=el('div');d.append(img(UIC[ic]),$(id));cur.append(d);});
hud.append(cur);
ip.querySelectorAll('.kv').forEach(k=>k.remove());

/* bản đồ + nút tròn */
const mapW=el('div','hmap');mapW.append($('mini'),$('zoneName'));
const mkIb=(b,ic,key,label)=>{b.className='ib';b.replaceChildren(img(UIC[ic]));if(key)b.append(el('small','',key));b.setAttribute('aria-label',label);b.title=label;return b;};
const col1=el('div','hico');
col1.append(mkIb($('menuBtn'),'menu','','Menu'),mkIb($('skBtn'),'book','U','Bảng kỹ năng'),mkIb($('bBag'),'bag','I','Túi đồ'));
const col2=el('div','hico');
const cb=$('chatBtn');if(cb){mkIb(cb,'chat','Enter','Chat');col2.append(cb);}
ip.replaceChildren(col2,col1,mapW);

/* nút chiến đấu: toạ độ tương đối tâm nút đánh, góc tính theo độ (180 = bên trái, 90 = phía trên) */
const at=(e,r,deg)=>{const a=deg*Math.PI/180;e.style.left='calc(50% + '+(Math.cos(a)*r).toFixed(1)+'px)';e.style.top='calc(50% - '+(Math.sin(a)*r).toFixed(1)+'px)';};
const bA=$('bAtk');bA.querySelector('span')?.remove();bA.prepend(img(UIC.atk));bA.setAttribute('aria-label','Đánh (Space)');
const bP=$('bPot');bP.className='rbtn sm';bP.removeAttribute('style');bP.querySelector('span')?.remove();const pc=el('b','pc','0');bP.append(img(UIC.pot),pc);bP.setAttribute('aria-label','Bình máu (H)');
const bR=$('bRoll');bR.classList.add('sm');bR.querySelector('span')?.remove();bR.append(img(UIC.roll));bR.setAttribute('aria-label','Lăn (Shift)');
at(bR,170,184);at(bP,168,96);
const tk=$('bTalk');tk.prepend(img(UIC.talk));

/* kỹ năng: 3 nút vòng trong, 3 nút vòng ngoài */
const POS=[[92,180],[92,135],[92,90],[166,160],[166,136],[166,112]];
const _bs=buildSbar;
buildSbar=function(){
  _bs();
  const ic=(HA.skills||{})[P.cls]||[];
  SB.forEach((q,i)=>{q.e.prepend(img(ic[i]));at(q.e,POS[i][0],POS[i][1]);q.rdy=true;});
};
const _uh=updateHUD;
updateHUD=function(){
  _uh();setAv();
  const pv=String(P.pots);if(pc._v!==pv){pc._v=pv;pc.textContent=pv;}
  for(let i=0;i<SB.length;i++){const q=SB[i],r=!!P.sk[i]&&P.cds[i]<=0;if(r&&q.rdy===false){q.e.classList.remove('rdy');void q.e.offsetWidth;q.e.classList.add('rdy');}q.rdy=r;}
};
/* --- chống đơ: một lỗi trong một khung hình không được làm dừng cả vòng lặp game --- */
const _fr=frame;let fErr=0;
frame=function(now){let done=false;try{_fr(now);done=true;}catch(e){if(fErr++<5)console.error('Lỗi khung hình:',e);}if(!done)requestAnimationFrame(frame);};
// vào game là cập nhật bảng máu ngay, không đợi khung hình sau
const _sg2=startGame;
startGame=function(...a){_sg2(...a);try{if(P)updateHUD();}catch(e){}};
if(/[?&]hsnctest\b/.test(location.search))window.__T={start:(c,n)=>{G.state='menu';startGame(c,n);},get P(){return P;},get G(){return G;},get scale(){return scale;}};
}catch(err){console.error('Giao diện trong game lỗi:',err);}
