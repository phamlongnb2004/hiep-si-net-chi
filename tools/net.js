
/* ===== CHẾ ĐỘ ONLINE ===== */
try{
const NET={ws:null,token:null,user:null,id:0,on:false,offline:false,others:new Map(),online:0,lastSt:0,lastSave:0,saveQ:false,retry:0,server:''};
window.__net=NET;
const LS={get(k){try{return localStorage.getItem(k);}catch(e){return null;}},set(k,v){try{v==null?localStorage.removeItem(k):localStorage.setItem(k,v);}catch(e){}}};
const defServer=()=>{const c=window.HSNC_CONFIG&&window.HSNC_CONFIG.server;if(c)return c;if(/^https?:$/.test(location.protocol)&&location.host)return location.origin;return '';};
NET.server=(LS.get('hsnc-server')||defServer()).replace(/\/+$/,'');
NET.token=LS.get('hsnc-token');NET.user=LS.get('hsnc-user');

/* --- giao diện --- */
const css=document.createElement('style');css.textContent=`
#netLogin{background:rgba(16,21,42,.72);display:grid;place-items:center;padding:16px max(16px,env(safe-area-inset-right,0px)) 16px max(16px,env(safe-area-inset-left,0px));z-index:30}
#netLogin .box{width:min(420px,100%);background:var(--paper);border:3px solid var(--ink);box-shadow:6px 7px 0 var(--ink);padding:18px 20px 16px;display:grid;gap:10px}
#netLogin h2{margin:0;font:30px/1 var(--f-display);letter-spacing:.5px}
#netLogin p{margin:0;font-size:15.5px}
#netLogin label{display:grid;gap:3px;font-size:15px}
#netLogin input{padding:8px 10px;background:#fff;border:2.5px solid var(--ink);border-radius:9px 4px 10px 4px;font-size:17px}
#netLogin .row{display:flex;gap:8px;flex-wrap:wrap}
#netLogin .row .big{flex:1 1 140px}
#netLogin .msg{min-height:1.3em;font-size:15px;color:var(--red)}
#netLogin .msg.ok{color:#1f8a4a}
#netLogin details{font-size:14.5px}
#netLogin summary{cursor:pointer;opacity:.8}
#netLogin .link{background:none;border:0;padding:0;text-decoration:underline;font-size:15px;opacity:.8;justify-self:start}
#netBadge{position:absolute;left:50%;top:12px;transform:translateX(-50%);background:rgba(16,21,42,.82);color:#f3ead0;font-size:14px;padding:2px 12px;border-radius:9px 4px 9px 4px;pointer-events:none;white-space:nowrap}
#netBadge i{display:inline-block;width:9px;height:9px;border-radius:50%;background:#3fa66b;margin-right:6px;vertical-align:1px}
#netBadge.off i{background:#d9345a}
#chatBar{position:absolute;left:50%;bottom:calc(14px + env(safe-area-inset-bottom,0px));transform:translateX(-50%);width:min(520px,calc(100% - 32px));display:flex;gap:6px;z-index:5}
#chatBar input{flex:1;min-width:0;padding:8px 10px;border:2.5px solid var(--ink);border-radius:9px 4px 10px 4px;font-size:16px;background:#fff}
#chatBar button{padding:6px 14px;border:2.5px solid var(--ink);background:var(--hl);border-radius:9px 4px 9px 4px;box-shadow:2px 3px 0 var(--ink)}
#chatBtn{position:absolute;left:max(16px,env(safe-area-inset-left,0px));top:150px;pointer-events:auto;padding:4px 12px;border:2.5px solid var(--ink);background:#bcd3ff;border-radius:9px 4px 9px 4px;box-shadow:2px 3px 0 var(--ink);font-size:15px;display:none}
.touch #chatBtn{display:block}
`;document.head.append(css);

const app=$('app');
const box=document.createElement('section');box.id='netLogin';box.className='overlay';
box.innerHTML=`<form class="box wob" id="netForm" autocomplete="on">
<h2>Hiệp Sĩ Online</h2>
<p>Đăng nhập để chơi cùng mọi người. Nhân vật được lưu trên máy chủ.</p>
<label for="netUser">Tên tài khoản<input id="netUser" maxlength="16" autocomplete="username" required></label>
<label for="netPass">Mật khẩu<input id="netPass" type="password" maxlength="72" autocomplete="current-password" required></label>
<div class="msg" id="netMsg" role="status"></div>
<div class="row"><button class="big" type="submit" id="netLoginBtn">Đăng nhập</button><button class="big alt" type="button" id="netRegBtn">Tạo tài khoản</button></div>
<details id="netSrvBox"><summary>Máy chủ: <span id="netSrvTxt"></span></summary>
<label for="netSrv" style="margin-top:6px">Địa chỉ máy chủ<input id="netSrv" placeholder="https://ten-game.onrender.com" inputmode="url" autocomplete="off"></label></details>
<button class="link" type="button" id="netOffline">Chơi offline trên máy này</button>
</form>`;
app.append(box);
const badge=document.createElement('div');badge.id='netBadge';badge.hidden=true;$('hud').append(badge);
const chatBar=document.createElement('form');chatBar.id='chatBar';chatBar.hidden=true;chatBar.innerHTML='<input id="chatIn" maxlength="120" placeholder="Nhập tin nhắn, Enter để gửi" autocomplete="off"><button type="submit">Gửi</button>';app.append(chatBar);
const chatBtn=document.createElement('button');chatBtn.id='chatBtn';chatBtn.type='button';chatBtn.textContent='Chat';$('hud').append(chatBtn);

const msg=(t,ok)=>{const m=$('netMsg');m.textContent=t||'';m.className='msg'+(ok?' ok':'');};
const srvTxt=()=>{$('netSrvTxt').textContent=NET.server||'chưa đặt';$('netSrv').value=NET.server;};
srvTxt();if(!NET.server)$('netSrvBox').open=true;
if(NET.user)$('netUser').value=NET.user;
const setServer=()=>{const v=$('netSrv').value.trim().replace(/\/+$/,'');if(v&&!/^https?:\/\//.test(v)){msg('Địa chỉ máy chủ cần bắt đầu bằng https:// hoặc http://');return false;}NET.server=v;LS.set('hsnc-server',v||null);srvTxt();return true;};
$('netSrv').addEventListener('change',setServer);

async function auth(kind){
  if(!setServer())return;
  if(!NET.server){msg('Hãy nhập địa chỉ máy chủ trước.');$('netSrvBox').open=true;return;}
  const user=$('netUser').value.trim(),pass=$('netPass').value;
  if(!user||!pass){msg('Nhập tên tài khoản và mật khẩu.');return;}
  msg(kind==='register'?'Đang tạo tài khoản…':'Đang đăng nhập…',true);
  try{
    const r=await fetch(NET.server+'/api/'+kind,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user,pass})});
    const d=await r.json().catch(()=>({}));
    if(!r.ok){msg(d.error||'Máy chủ báo lỗi '+r.status);return;}
    NET.token=d.token;NET.user=d.user;LS.set('hsnc-token',d.token);LS.set('hsnc-user',d.user);$('netPass').value='';
    connect();
  }catch(e){msg('Không kết nối được máy chủ. Kiểm tra mạng hoặc địa chỉ máy chủ. Máy chủ miễn phí có thể mất khoảng 1 phút để thức dậy.');}
}
$('netForm').addEventListener('submit',e=>{e.preventDefault();auth('login');});
$('netRegBtn').addEventListener('click',()=>auth('register'));
$('netOffline').addEventListener('click',()=>{NET.offline=true;box.hidden=true;$('start').querySelector('.note').textContent='Đang chơi offline: tiến trình lưu trên máy này, không thấy người chơi khác.';});

/* --- kết nối --- */
function connect(){
  if(!NET.token||!NET.server)return;
  const u=NET.server.replace(/^http/,'ws')+'/ws?token='+encodeURIComponent(NET.token);
  let ws;try{ws=new WebSocket(u);}catch(e){msg('Địa chỉ máy chủ không hợp lệ.');return;}
  NET.ws=ws;
  ws.onmessage=ev=>{let m;try{m=JSON.parse(ev.data);}catch(e){return;}onMsg(m);};
  ws.onclose=ev=>{
    const was=NET.on;NET.on=false;NET.others.clear();showBadge();
    if(ev.code===4001){NET.token=null;LS.set('hsnc-token',null);box.hidden=false;msg('Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.');return;}
    if(ev.code===4002){box.hidden=false;msg('Tài khoản vừa đăng nhập ở nơi khác.');return;}
    if(!was&&!box.hidden){msg('Không kết nối được máy chủ. Máy chủ miễn phí có thể đang khởi động, thử lại sau ít giây.');return;}
    NET.retry=Math.min(NET.retry+1,6);setTimeout(connect,1000*NET.retry*NET.retry);
  };
}
function onMsg(m){
  if(m.t==='welcome'){
    NET.on=true;NET.id=m.id;NET.online=m.online;NET.retry=0;showBadge();
    const first=!NET.gotSave;NET.gotSave=true;box.hidden=true;
    if(first&&G.state==='menu')applySave(m.save);
    else if(P&&G.state!=='menu')log('Đã kết nối lại máy chủ.','#9be05a');
  }else if(m.t==='ps'){
    const now=performance.now(),seen=new Set();
    for(const s of m.p){const id=s[0];seen.add(id);let o=NET.others.get(id);
      if(!o){o={id,x:s[1],y:s[2],tx:s[1],ty:s[2],bubble:null};NET.others.set(id,o);}
      o.tx=s[1];o.ty=s[2];o.face=s[3];o.mv=s[4];o.sw=s[5];o.cls=s[6];o.lv=s[7];o.n=s[8];o.hp=s[9];o.dead=s[10];o.at=now;
      if(o.sw&&!o.swing)o.swing=1;}
    for(const id of NET.others.keys())if(!seen.has(id))NET.others.delete(id);
  }else if(m.t==='gone')NET.others.delete(m.id);
  else if(m.t==='count'){NET.online=m.online;showBadge();}
  else if(m.t==='chat'){
    if(G.state!=='menu')log((m.all?'[Thế giới] ':'')+m.n+': '+m.text,m.id===NET.id?'#ffd23f':'#9be05a');
    const o=NET.others.get(m.id);if(o)o.bubble={text:m.text,t:5};
    if(m.id===NET.id&&P)NET.myBubble={text:m.text,t:5};
  }else if(m.t==='err'&&m.msg&&G.state!=='menu')log(m.msg,'#ff8a8a');
}
function showBadge(){
  if(NET.offline||!NET.token){badge.hidden=true;return;}
  badge.hidden=false;badge.className=NET.on?'':'off';
  badge.innerHTML='<i></i>'+(NET.on?'Online · '+NET.online+' người':'Mất kết nối, đang nối lại…');
}

/* --- bản lưu trên máy chủ --- */
let SRV=null;
function applySave(sv){
  SRV=sv&&CLS[sv.cls]?sv:null;
  const bc=$('btnContinue');
  if(SRV){bc.hidden=false;bc.textContent='Tiếp tục: '+String(SRV.name).slice(0,14)+' · '+CLS[SRV.cls].n+' Lv.'+(SRV.lv|0);bc.onclick=()=>startGame(SRV.cls,SRV.name,SRV);}
  else bc.hidden=true;
  $('nameIn').value=String(NET.user||'Hiệp Sĩ').slice(0,14);
  $('start').querySelector('.note').textContent='Đang chơi online với tài khoản '+NET.user+'. Nhân vật tự lưu lên máy chủ. Bấm Enter trong game để chat.';
}
const snap=()=>({cls:P.cls,name:P.name,lv:P.lv,exp:P.exp,gold:P.gold,pots:P.pots,kills:P.kills,inv:P.inv,eq:P.eq,map:MAPI,mv:2,stones:P.stones,sk:P.sk,books:P.books});
const _save=save;
save=function(){
  _save();
  if(!P||!NET.on||NET.offline)return;
  const now=performance.now();
  if(now-NET.lastSave<4000){NET.saveQ=true;return;}
  NET.lastSave=now;NET.saveQ=false;
  try{NET.ws.send(JSON.stringify({t:'save',d:snap()}));}catch(e){}
};
window.addEventListener('pagehide',()=>{if(P&&NET.on)try{NET.ws.send(JSON.stringify({t:'save',d:snap()}));}catch(e){}});

/* --- gửi vị trí, nội suy người chơi khác --- */
const _upd=update;
update=function(dt){
  _upd(dt);
  const now=performance.now();
  if(NET.on&&P&&now-NET.lastSt>100){NET.lastSt=now;
    try{NET.ws.send(JSON.stringify({t:'st',m:MAPI,x:P.x,y:P.y,f:P.face,mv:P.moving?1:0,sw:P.swing>0?1:0,c:P.cls,lv:P.lv,n:P.name,hp:P.hp/P.maxHp,dead:P.dead>0?1:0}));}catch(e){}}
  if(NET.saveQ&&now-NET.lastSave>4000)save();
  const k=Math.min(1,dt*12);
  for(const o of NET.others.values()){
    const d=Math.hypot(o.tx-o.x,o.ty-o.y);
    if(d>400){o.x=o.tx;o.y=o.ty;}else{o.x+=(o.tx-o.x)*k;o.y+=(o.ty-o.y)*k;}
    o.swing=Math.max(0,(o.swing||0)-dt*3);if(o.sw&&o.swing<=0)o.swing=1;
    if(o.bubble&&(o.bubble.t-=dt)<=0)o.bubble=null;
  }
  if(NET.myBubble&&(NET.myBubble.t-=dt)<=0)NET.myBubble=null;
};
function bubble(x,y,text){
  ctx.font='15px "Patrick Hand",sans-serif';const w=Math.min(240,ctx.measureText(text).width+18),t=text.length>34?text.slice(0,33)+'…':text;
  ctx.fillStyle='rgba(255,255,255,.95)';ctx.strokeStyle=INK;ctx.lineWidth=2;
  ctx.beginPath();ctx.roundRect?ctx.roundRect(x-w/2,y-26,w,24,8):ctx.rect(x-w/2,y-26,w,24);ctx.fill();ctx.stroke();
  ctx.fillStyle=INK;ctx.textAlign='center';ctx.fillText(t,x,y-9);
}
const _pd=playerDraw;
playerDraw=function(){
  const L=[...NET.others.values()].sort((a,b)=>a.y-b.y);
  const draw=o=>{
    if(!CLS[o.cls])return;
    ctx.save();ctx.translate(o.x,o.y);
    drawHero({cls:o.cls,face:o.face||1,t:o.mv?G.time+o.id:G.time+o.id*.7,moving:!!o.mv,swing:o.swing||0,eq:null,alpha:o.dead?.35:null});
    ctx.restore();
    ctx.font='16px "Patrick Hand",sans-serif';ctx.textAlign='center';ctx.lineWidth=4;ctx.strokeStyle=PAPER;const lab=o.n+' · Lv.'+o.lv;
    ctx.strokeText(lab,o.x,o.y-104);ctx.fillStyle='#1f7a3a';ctx.fillText(lab,o.x,o.y-104);
    ctx.fillStyle='#0f1422';ctx.fillRect(o.x-21,o.y-99,42,6);ctx.fillStyle='#3fa66b';ctx.fillRect(o.x-20,o.y-98,40*(o.hp||0),4);
    if(o.bubble)bubble(o.x,o.y-114,o.bubble.text);
  };
  for(const o of L)if(o.y<=P.y)draw(o);
  _pd();
  if(NET.myBubble)bubble(P.x,P.y-114,NET.myBubble.text);
  for(const o of L)if(o.y>P.y)draw(o);
};

/* --- chat --- */
const openChat=()=>{if(!NET.on||G.state!=='play')return;chatBar.hidden=false;$('chatIn').focus();};
const closeChat=()=>{chatBar.hidden=true;$('chatIn').value='';$('chatIn').blur();};
chatBar.addEventListener('submit',e=>{e.preventDefault();const v=$('chatIn').value.trim();
  if(v&&NET.on){const all=/^\/(tg|all|w)\s+/i.test(v);try{NET.ws.send(JSON.stringify({t:'chat',text:all?v.replace(/^\/\S+\s+/,''):v,all}));}catch(e){}}
  closeChat();});
$('chatIn').addEventListener('keydown',e=>{if(e.code==='Escape'){e.preventDefault();closeChat();}e.stopPropagation();});
window.addEventListener('keydown',e=>{if((e.code==='Enter'||e.code==='NumpadEnter')&&chatBar.hidden&&G.state==='play'&&!typing()){e.preventDefault();openChat();}},true);
chatBtn.addEventListener('click',openChat);

/* --- khởi động --- */
if(NET.token&&NET.server){box.hidden=true;$('start').querySelector('.note').textContent='Đang kết nối máy chủ…';
  const ws0=()=>{connect();setTimeout(()=>{if(!NET.on&&!NET.offline){box.hidden=false;msg('Chưa kết nối được máy chủ, đang thử lại. Bạn có thể đăng nhập lại hoặc chơi offline.');}},9000);};ws0();}
showBadge();
}catch(err){console.error('Online lỗi:',err);}
