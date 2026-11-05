
/* ===== GIAO DIỆN MỞ ĐẦU KIỂU CHIBI: đảo giữa biển, mây trôi, sóng lấp lánh, chim bay ===== */
try{
const UA=window.HSNC_UI||{};
const ui=window.__ui={};
const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;

const css=document.createElement('style');css.textContent=`
/* Bố cục: cảnh đảo phủ kín màn hình, logo nổi ở trên, thẻ kem bo tròn viền xanh đậm như nút game chibi */
:root{
  --ui-ink:#16224a; --ui-ink2:#2b3a6b; --ui-cream:#fffaf0; --ui-sky:#5cc8ff; --ui-sea:#13b5c8;
  --ui-sun:#ffd23f; --ui-sun2:#ff9f1c; --ui-mint:#3ccf91; --ui-coral:#ff6b6b; --ui-muted:#5a6a95;
  --ui-disp:'Baloo 2','Nunito',system-ui,sans-serif; --ui-body:'Nunito','Segoe UI',system-ui,sans-serif;
  --f-display:var(--ui-disp); --f-body:var(--ui-body);
}
#uiScene{position:absolute;inset:0;overflow:hidden;z-index:12;pointer-events:none;background:#4fb8ff;opacity:0;transition:opacity .6s}
#uiScene.on{opacity:1}
#uiScene .bg{position:absolute;inset:-3%;background-size:cover;background-position:50% 62%;animation:uiKen 38s ease-in-out infinite alternate}
#uiScene .shade{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 30%,rgba(255,255,255,0) 40%,rgba(10,30,70,.28) 100%)}
#uiScene .cloud{position:absolute;left:0;will-change:transform;filter:drop-shadow(0 6px 10px rgba(40,80,140,.18));animation:uiDrift linear infinite}
#uiScene canvas{position:absolute;inset:0;width:100%;height:100%}
#uiScene .gull{position:absolute;width:34px;height:14px;animation:uiFly linear infinite}
#uiScene .gull svg{width:100%;height:100%;animation:uiFlap .5s ease-in-out infinite alternate;transform-origin:50% 60%}
@keyframes uiKen{from{transform:scale(1) translate(0,0)}to{transform:scale(1.07) translate(-1.2%,-1%)}}
@keyframes uiDrift{from{transform:translateX(-35vw)}to{transform:translateX(115vw)}}
@keyframes uiFly{from{transform:translate(-10vw,0)}50%{transform:translate(50vw,-4vh)}to{transform:translate(112vw,2vh)}}
@keyframes uiFlap{from{transform:scaleY(1)}to{transform:scaleY(-.55)}}

#netLogin,#start{z-index:20;background:transparent!important;font-family:var(--ui-body);color:var(--ui-ink)}
#netLogin{z-index:30;display:block;padding:0}
.ui-wrap{min-height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:clamp(10px,2.4vh,22px);padding-block:max(18px,env(safe-area-inset-top,0px)) max(18px,env(safe-area-inset-bottom,0px));padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}

/* Logo */
.ui-logo{position:relative;display:flex;flex-direction:column;align-items:center;line-height:.86;animation:uiBob 3.2s ease-in-out infinite;text-align:center}
.ui-logo .l1,.ui-logo .l2{position:relative;display:block;font-family:var(--ui-disp);font-weight:800;letter-spacing:.5px}
.ui-logo .o,.ui-logo .f{display:block;white-space:nowrap}
.ui-logo .o{position:absolute;inset:0;color:var(--ui-ink);-webkit-text-stroke:var(--sw) var(--ui-ink);text-shadow:0 6px 0 var(--ui-ink),0 12px 20px rgba(10,30,80,.35)}
.ui-logo .f{position:relative;color:var(--c1);-webkit-text-fill-color:var(--c1);text-shadow:0 -2px 0 var(--c0),0 3px 0 var(--c2)}
.ui-logo .l1{--sw:14px;--c0:#fff6b8;--c1:#ffd23f;--c2:#ff9f1c;font-size:clamp(46px,10vw,92px)}
.ui-logo .l2{--sw:12px;--c0:#ffffff;--c1:#8fdcff;--c2:#3aa8ff;font-size:clamp(34px,7.2vw,66px);margin-top:4px}
.ui-logo .ribbon{position:relative;margin-top:10px;padding:4px 18px 3px;font:800 clamp(13px,2.2vw,17px)/1.2 var(--ui-disp);letter-spacing:4px;color:#fff;-webkit-text-stroke:0;text-shadow:0 2px 0 rgba(0,0,0,.25);background:linear-gradient(#ff8a8a,#ff5d6c);border:3px solid var(--ui-ink);border-radius:999px;box-shadow:0 4px 0 var(--ui-ink)}
.ui-logo::after{content:"";position:absolute;inset:-20% -12%;background:radial-gradient(closest-side,rgba(255,255,255,.35),rgba(255,255,255,0));z-index:-1}
.ui-logo.small{animation:none;flex-direction:row;gap:10px;align-items:baseline}
.ui-logo.small .l1{--sw:9px;font-size:clamp(26px,4.6vw,40px)}
.ui-logo.small .l2{--sw:8px;font-size:clamp(22px,3.8vw,32px);margin:0}
.ui-logo.small .ribbon{display:none}
@keyframes uiBob{50%{transform:translateY(-8px) rotate(-.6deg)}}

/* Thẻ */
.ui-card,#start .startsheet{position:relative;background:rgba(255,250,240,.94);border:4px solid var(--ui-ink);border-radius:28px;box-shadow:0 8px 0 var(--ui-ink),0 24px 46px rgba(10,30,80,.35);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px)}
.ui-card{width:min(400px,100%);padding:16px 20px 16px;display:grid;gap:11px;animation:uiPop .55s cubic-bezier(.2,1.6,.4,1) both}
.ui-card::before,#start .startsheet::before{content:"";position:absolute;inset:6px;border:2px dashed rgba(22,34,74,.14);border-radius:22px;pointer-events:none}
@keyframes uiPop{from{opacity:0;transform:translateY(24px) scale(.92)}to{opacity:1;transform:none}}
.ui-tabs{position:relative;display:grid;grid-template-columns:1fr 1fr;background:#e3efff;border:3px solid var(--ui-ink);border-radius:999px;padding:4px}
.ui-tabs button{position:relative;z-index:1;border:0;background:none;padding:7px 0 6px;font:800 17px/1 var(--ui-disp);color:var(--ui-muted);border-radius:999px;cursor:pointer;transition:color .2s}
.ui-tabs button[aria-selected=true]{color:var(--ui-ink)}
.ui-tabpill{position:absolute;top:4px;bottom:4px;left:4px;width:calc(50% - 4px);background:linear-gradient(#fff,#ffe9a3);border:2px solid var(--ui-ink);border-radius:999px;box-shadow:0 3px 0 var(--ui-ink);transition:transform .35s cubic-bezier(.3,1.5,.5,1)}
.ui-card[data-mode=register] .ui-tabpill{transform:translateX(100%)}
.ui-hint{margin:0;text-align:center;font:700 15px var(--ui-body);color:var(--ui-muted)}
.ui-field{position:relative;display:grid;gap:4px;font:800 14px var(--ui-body);color:var(--ui-ink2)}
.ui-field[hidden]{display:none!important}
.ui-field input{width:100%;padding:11px 14px;background:#f2f8ff;border:3px solid #bcd3f2;border-radius:16px;font:700 17px var(--ui-body);color:var(--ui-ink);outline:none;transition:border-color .2s,box-shadow .2s,background .2s;-webkit-user-select:text;user-select:text}
.ui-field input::placeholder{color:#9aaed0;font-weight:600}
.ui-field input:focus{border-color:var(--ui-sky);background:#fff;box-shadow:0 0 0 4px rgba(92,200,255,.28)}
.ui-eye{position:absolute;right:8px;bottom:7px;width:36px;height:34px;border:0;border-radius:12px;background:transparent;color:#8ea4c8;display:grid;place-items:center;cursor:pointer}
.ui-eye.on{color:var(--ui-sky)}
.ui-field:has(.ui-eye) input{padding-right:48px}
.ui-msg{min-height:1.4em;text-align:center;font:800 14.5px var(--ui-body);border-radius:12px;padding:0 6px}
.ui-msg.bad{color:#c2304a}
.ui-msg.ok{color:#178a5c}
.ui-msg.shake{animation:uiShake .4s}
@keyframes uiShake{20%,60%{transform:translateX(-6px)}40%,80%{transform:translateX(6px)}}
.ui-srv{font:700 13px var(--ui-body);color:var(--ui-muted);text-align:center}
.ui-srv summary{cursor:pointer;list-style:none}
.ui-srv summary::-webkit-details-marker{display:none}
.ui-srv b{font-weight:800}
.ui-srv .ui-field{margin-top:8px;text-align:left}

/* Nút kẹo 3D */
.ui-btn,#start .big{position:relative;overflow:hidden;cursor:pointer;font:800 21px/1 var(--ui-disp);letter-spacing:.4px;color:var(--ui-ink);padding:13px 24px 11px;background:linear-gradient(#fff3a6,#ffd23f 45%,#ffab1f);border:3.5px solid var(--ui-ink);border-radius:18px;box-shadow:0 6px 0 var(--ui-ink),inset 0 -5px 0 rgba(200,90,0,.25),inset 0 3px 0 rgba(255,255,255,.7);transition:transform .12s,box-shadow .12s,filter .2s;text-shadow:0 1px 0 rgba(255,255,255,.6)}
.ui-btn:hover,#start .big:hover{filter:brightness(1.05);transform:translateY(-2px)}
.ui-btn:active,#start .big:active{transform:translateY(5px);box-shadow:0 1px 0 var(--ui-ink),inset 0 -3px 0 rgba(200,90,0,.25)}
.ui-btn::after,#start .big::after{content:"";position:absolute;top:-50%;left:-40%;width:30%;height:200%;background:linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,.75),rgba(255,255,255,0));transform:rotate(20deg);animation:uiShine 3.6s ease-in-out infinite}
@keyframes uiShine{0%,62%{left:-40%}100%{left:140%}}
.ui-btn:disabled{filter:saturate(.6);cursor:default}
.ui-btn.loading span::after{content:"";display:inline-block;width:1.2em;text-align:left;animation:uiDots 1s steps(4) infinite}
@keyframes uiDots{0%{content:""}25%{content:"."}50%{content:".."}75%{content:"..."}}
#start .big.alt{background:linear-gradient(#d9f6ff,#7fd6ff 50%,#3aa8ff);box-shadow:0 6px 0 var(--ui-ink),inset 0 -5px 0 rgba(0,60,160,.22),inset 0 3px 0 rgba(255,255,255,.7)}
.ui-ghost{border:3px solid var(--ui-ink);background:#fff;border-radius:14px;padding:6px 12px;font:800 14px var(--ui-disp);color:var(--ui-ink);box-shadow:0 4px 0 var(--ui-ink);cursor:pointer}
.ui-ghost:active{transform:translateY(3px);box-shadow:0 1px 0 var(--ui-ink)}
.ui-star{position:fixed;width:14px;height:14px;pointer-events:none;z-index:99;background:var(--c);clip-path:polygon(50% 0,62% 38%,100% 50%,62% 62%,50% 100%,38% 62%,0 50%,38% 38%);animation:uiBurst .7s ease-out forwards}
@keyframes uiBurst{to{transform:translate(var(--dx),var(--dy)) rotate(200deg) scale(.2);opacity:0}}

/* Màn chọn nhân vật */
#start{display:block!important;padding:0!important}
#start[hidden]{display:none!important}
#start .ui-wrap{justify-content:flex-start;gap:12px}
#start .ui-top{width:min(980px,100%);display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
#start .ui-user{display:flex;align-items:center;gap:8px;background:rgba(255,250,240,.92);border:3px solid var(--ui-ink);border-radius:999px;padding:4px 6px 4px 14px;box-shadow:0 4px 0 var(--ui-ink);font:800 15px var(--ui-body)}
#start .ui-user i{width:10px;height:10px;border-radius:50%;background:var(--ui-mint);box-shadow:0 0 8px var(--ui-mint)}
#start .startsheet{width:min(980px,100%);padding:18px clamp(14px,2.6vw,26px) 18px;animation:uiPop .55s cubic-bezier(.2,1.5,.4,1) both;color:var(--ui-ink)}
#start .startsheet h1{font:800 clamp(28px,4.6vw,38px)/1.05 var(--ui-disp);color:var(--ui-ink);text-shadow:none;transform:none;margin:0 0 2px;width:auto}
#start .startsheet h1::after{display:none}
#start .tag{margin:2px 0 12px;font:700 15.5px/1.4 var(--ui-body);color:var(--ui-muted)}
#start #cards{gap:14px}
#start .card{position:relative;background:linear-gradient(180deg,#ffffff,#eef6ff);border:3.5px solid var(--ui-ink);border-radius:22px;box-shadow:0 6px 0 var(--ui-ink);padding:10px 10px 14px;color:var(--ui-ink);cursor:pointer;transition:transform .2s cubic-bezier(.3,1.6,.5,1),box-shadow .2s;animation:uiPop .5s cubic-bezier(.2,1.6,.4,1) both}
#start .card:nth-child(2){animation-delay:.07s}#start .card:nth-child(3){animation-delay:.14s}#start .card:nth-child(4){animation-delay:.21s}
#start .card:hover{transform:translateY(-4px)}
#start .card canvas{border-radius:16px;background:radial-gradient(ellipse at 50% 78%,rgba(92,200,255,.35),rgba(92,200,255,0) 70%)}
#start .card h3{font:800 23px/1.1 var(--ui-disp);color:var(--ui-ink)}
#start .card .desc{font:700 14px/1.35 var(--ui-body);color:var(--ui-muted)}
#start .card .sk{font:800 12.5px/1.3 var(--ui-body);color:#2f7bd8}
#start .card[aria-pressed=true]{background:linear-gradient(180deg,#fffbe2,#ffe38a);transform:translateY(-6px);box-shadow:0 10px 0 var(--ui-ink),0 0 0 4px #fff,0 0 26px 6px rgba(255,210,63,.75)}
#start .card[aria-pressed=true]::after{content:"Đã chọn";position:absolute;top:-12px;left:50%;transform:translateX(-50%);background:var(--ui-coral);color:#fff;font:800 12px/1 var(--ui-disp);padding:5px 10px 4px;border:2.5px solid var(--ui-ink);border-radius:999px;white-space:nowrap}
#start .mrow{font:800 12px var(--ui-body);color:var(--ui-ink2)}
#start .track{height:10px;background:#dfe9f7;border:2px solid var(--ui-ink);border-radius:999px}
#start .track i{background:linear-gradient(90deg,#ff9f1c,#ffd23f);border-radius:999px}
#start .startrow{gap:12px;margin-top:18px}
#start .startrow label{font:800 15px var(--ui-body);color:var(--ui-ink2)}
#start .startrow input{flex:1 1 180px;padding:11px 14px;background:#f2f8ff;border:3px solid #bcd3f2;border-radius:16px;font:700 17px var(--ui-body);color:var(--ui-ink)}
#start .startrow input:focus{outline:none;border-color:var(--ui-sky);box-shadow:0 0 0 4px rgba(92,200,255,.28)}
#start #btnStart{animation:uiPulse 1.8s ease-in-out infinite}
@keyframes uiPulse{50%{box-shadow:0 6px 0 var(--ui-ink),0 0 0 6px rgba(255,210,63,.35),inset 0 -5px 0 rgba(200,90,0,.25),inset 0 3px 0 rgba(255,255,255,.7)}}
#start .note{font:700 13.5px var(--ui-body);color:var(--ui-muted);opacity:1}
@media (max-width:640px){.ui-logo .l1{--sw:10px}.ui-logo .l2{--sw:9px}#start .startrow .big{flex:1 1 100%}}
@media (max-height:560px){
  #netLogin .ui-wrap{flex-direction:row;justify-content:center;align-items:center;gap:4vw}
  #netLogin .ui-logo .l1{font-size:clamp(34px,7vw,64px)}#netLogin .ui-logo .l2{font-size:clamp(26px,5vw,46px)}
  .ui-card{gap:7px;padding:10px 16px 10px;width:min(360px,100%)}
  .ui-hint{display:none}.ui-field{gap:2px}.ui-field input{padding:7px 12px;font-size:15.5px}
  .ui-btn{padding:10px 20px 9px;font-size:18px}.ui-tabs button{padding:5px 0 4px}
  #start .ui-wrap{gap:8px}#start .startsheet{padding:12px 16px}#start .tag{display:none}
}
@media (max-height:560px) and (max-width:520px){#netLogin .ui-logo{display:none}}

/* Chỉ chơi ngang: điện thoại cầm dọc thì che game và nhắc xoay */
#uiRotate{position:fixed;inset:0;z-index:100;display:none;flex-direction:column;align-items:center;justify-content:center;gap:22px;text-align:center;padding:24px max(24px,env(safe-area-inset-right,0px)) 24px max(24px,env(safe-area-inset-left,0px));background:radial-gradient(ellipse at 50% 35%,#7fd6ff,#3aa8ff 55%,#1f6fd1);color:#fff;font-family:var(--ui-body)}
@media (orientation:portrait) and (pointer:coarse){#uiRotate{display:flex}}
#uiRotate .ph{width:92px;height:150px;border:6px solid var(--ui-ink);border-radius:22px;background:linear-gradient(#fffaf0,#ffe9a3);box-shadow:0 8px 0 var(--ui-ink);position:relative;animation:uiTurn 2.4s cubic-bezier(.5,0,.3,1) infinite}
#uiRotate .ph::before{content:"";position:absolute;left:50%;top:9px;width:26px;height:6px;margin-left:-13px;border-radius:6px;background:var(--ui-ink)}
#uiRotate .ph::after{content:"⟳";position:absolute;inset:0;display:grid;place-items:center;font:800 46px/1 var(--ui-disp);color:var(--ui-sun2)}
@keyframes uiTurn{0%,20%{transform:rotate(0)}55%,80%{transform:rotate(-90deg)}100%{transform:rotate(0)}}
#uiRotate h2{margin:0;font:800 30px/1.1 var(--ui-disp);color:#fff;text-shadow:0 3px 0 var(--ui-ink),0 0 14px rgba(0,0,0,.25);-webkit-text-stroke:2px var(--ui-ink);paint-order:stroke fill}
#uiRotate p{margin:0;max-width:300px;font:700 16px/1.45 var(--ui-body);color:#eaf7ff}
#uiRotate .ui-btn{font-size:18px}
@media (prefers-reduced-motion:reduce){#uiScene *,#uiRotate .ph,.ui-logo,.ui-btn::after,#start .big::after,#start #btnStart{animation:none!important}}
`;document.head.append(css);

/* --- cảnh đảo --- */
const app=$('app');
const scene=document.createElement('div');scene.id='uiScene';scene.className='on';scene.setAttribute('aria-hidden','true');
const bg=document.createElement('div');bg.className='bg';
if(UA.bgSmall)bg.style.backgroundImage=`url(${UA.bgSmall})`;
if(UA.bg){const im=new Image();im.onload=()=>{bg.style.backgroundImage=`url(${UA.bg})`;};im.src=UA.bg;}
scene.append(bg);
const cv=document.createElement('canvas');scene.append(cv);
const sh=document.createElement('div');sh.className='shade';scene.append(sh);
(UA.clouds||[]).concat(UA.clouds||[]).slice(0,8).forEach((c,i)=>{
  const im=document.createElement('img');im.className='cloud';im.alt='';im.src=c.u;
  const s=.45+((i*37)%10)/14,dur=70+((i*53)%60);
  im.style.width=Math.round(c.w*s)+'px';im.style.top=(2+((i*19)%30))+'%';
  im.style.opacity=String(.75+((i*7)%3)/10);im.style.animationDuration=dur+'s';im.style.animationDelay=(-(i*dur/8+((i*31)%20)))+'s';
  scene.append(im);
});
for(let i=0;i<3;i++){const g=document.createElement('div');g.className='gull';
  g.innerHTML='<svg viewBox="0 0 40 16"><path d="M2 12 Q10 2 20 10 Q30 2 38 12" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round"/></svg>';
  g.style.top=(14+i*7)+'%';g.style.animationDuration=(26+i*9)+'s';g.style.animationDelay=(-i*11)+'s';g.style.transform='scale('+(1-i*.2)+')';scene.append(g);}
app.insertBefore(scene,$('cv').nextSibling);

// lấp lánh trên mặt biển và quanh logo
const g2=cv.getContext('2d');let W=0,H=0,D=1;const TW=[];
const fit=()=>{D=Math.min(2,devicePixelRatio||1);W=scene.clientWidth;H=scene.clientHeight;cv.width=W*D;cv.height=H*D;};
const star=(x,y,r,a)=>{g2.globalAlpha=a;g2.beginPath();g2.moveTo(x,y-r);g2.quadraticCurveTo(x,y,x+r,y);g2.quadraticCurveTo(x,y,x,y+r);g2.quadraticCurveTo(x,y,x-r,y);g2.quadraticCurveTo(x,y,x,y-r);g2.fill();};
function tick(t){
  const on=typeof G!=='undefined'&&G.state==='menu';
  scene.classList.toggle('on',on);
  if(on&&!reduce){
    if(W!==scene.clientWidth||H!==scene.clientHeight)fit();
    g2.setTransform(D,0,0,D,0,0);g2.clearRect(0,0,W,H);g2.fillStyle='#fff';
    while(TW.length<70)TW.push({x:Math.random(),y:.58+Math.random()*.42,p:Math.random()*6.28,s:.6+Math.random()*1.4,v:.6+Math.random()});
    for(const o of TW){o.p+=.016*o.v;const a=Math.max(0,Math.sin(o.p));if(o.p>6.28){o.p=0;o.x=Math.random();o.y=.58+Math.random()*.42;}
      star(o.x*W+Math.sin(t/2000+o.y*9)*6,o.y*H,3.5*o.s*a+.5,a*.85);}
    // bụi sáng bay lên
    for(let i=0;i<14;i++){const u=((t/9000)+i/14)%1,x=(i*97%100)/100*W+Math.sin(t/1500+i)*20;g2.globalAlpha=.5*Math.sin(u*Math.PI);g2.beginPath();g2.arc(x,H*(1-u*.9),1.6+(i%3),0,6.28);g2.fill();}
    g2.globalAlpha=1;
  }
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);

/* --- tia sao khi bấm nút --- */
const COLORS=['#ffd23f','#ff6b6b','#5cc8ff','#3ccf91','#ffffff','#ff9f1c'];
document.addEventListener('pointerdown',e=>{
  const b=e.target.closest('.ui-btn,#start .big,#start .card,.ui-tabs button');if(!b||reduce)return;
  for(let i=0;i<10;i++){const s=document.createElement('i');s.className='ui-star';const a=Math.random()*6.28,d=40+Math.random()*50;
    s.style.left=(e.clientX-7)+'px';s.style.top=(e.clientY-7)+'px';s.style.setProperty('--c',COLORS[i%COLORS.length]);
    s.style.setProperty('--dx',Math.cos(a)*d+'px');s.style.setProperty('--dy',Math.sin(a)*d+'px');document.body.append(s);setTimeout(()=>s.remove(),750);}
},true);


/* --- chỉ chơi ngang --- */
const rot=document.createElement('div');rot.id='uiRotate';rot.setAttribute('role','alert');
rot.innerHTML='<div class="ph" aria-hidden="true"></div><h2>Xoay ngang để chơi</h2><p>Hiệp Sĩ Nét Chì chỉ chơi được khi cầm điện thoại nằm ngang. Hãy xoay máy lại nhé!</p><button type="button" class="ui-btn" id="uiRotBtn"><span>Chơi toàn màn hình ngang</span></button>';
document.body.append(rot);
const lockLand=async()=>{try{const el=document.documentElement;if(!document.fullscreenElement&&el.requestFullscreen)await el.requestFullscreen({navigationUI:'hide'});}catch(e){}
  try{if(screen.orientation&&screen.orientation.lock)await screen.orientation.lock('landscape');}catch(e){}};
$('uiRotBtn').addEventListener('click',lockLand);
if(!(document.documentElement.requestFullscreen&&screen.orientation&&screen.orientation.lock))$('uiRotBtn').hidden=true;
// lần chạm đầu tiên trên điện thoại: xin khóa ngang (Android hỗ trợ khi toàn màn hình)
if(matchMedia('(pointer:coarse)').matches)document.addEventListener('pointerup',function once(){document.removeEventListener('pointerup',once,true);if(!matchMedia('(display-mode: fullscreen)').matches)lockLand();},true);

/* --- màn chọn nhân vật --- */
const st=$('start'),sheet=st.querySelector('.startsheet');
const wrap=document.createElement('div');wrap.className='ui-wrap';
const top=document.createElement('div');top.className='ui-top';
top.innerHTML='<div class="ui-logo small" aria-hidden="true"><span class="l1"><b class="o">Hiệp Sĩ</b><b class="f">Hiệp Sĩ</b></span><span class="l2"><b class="o">Nét Chì</b><b class="f">Nét Chì</b></span></div><div class="ui-user"><i></i><span id="uiUserName">Đang tải…</span><button type="button" class="ui-ghost" id="uiLogout">Đổi tài khoản</button></div>';
sheet.parentNode.insertBefore(wrap,sheet);wrap.append(top,sheet);
sheet.classList.remove('wob');
sheet.querySelector('h1').textContent='Chọn nhân vật';
sheet.querySelector('.tag').textContent='Mỗi lớp nhân vật có 6 kỹ năng riêng. Chọn một hiệp sĩ, đặt tên rồi bắt đầu phiêu lưu.';
$('uiLogout').addEventListener('click',()=>window.__net&&window.__net.logout());
ui.setUser=n=>{$('uiUserName').textContent=n||'';};
ui.enterStart=()=>{sheet.style.animation='none';void sheet.offsetWidth;sheet.style.animation='';st.querySelectorAll('.card').forEach(c=>{c.style.animation='none';void c.offsetWidth;c.style.animation='';});};
}catch(err){console.error('Giao diện mở đầu lỗi:',err);}
