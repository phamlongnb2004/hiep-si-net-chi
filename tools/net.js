
/* ===== CHẾ ĐỘ ONLINE ===== */
try{
const NET={ws:null,token:null,user:null,id:0,on:false,offline:false,others:new Map(),online:0,lastSt:0,lastSave:0,saveQ:false,retry:0,server:''};
window.__net=NET;
const LS={get(k){try{return localStorage.getItem(k);}catch(e){return null;}},set(k,v){try{v==null?localStorage.removeItem(k):localStorage.setItem(k,v);}catch(e){}}};
const defServer=()=>{const c=window.HSNC_CONFIG&&window.HSNC_CONFIG.server;if(c)return c;if(/^https?:$/.test(location.protocol)&&location.host)return location.origin;return '';};
NET.server=(LS.get('hsnc-server')||defServer()).replace(/\/+$/,'');
NET.token=LS.get('hsnc-token');NET.user=LS.get('hsnc-user');

/* --- giao diện (kiểu chữ và màu ở tools/ui.js) --- */
const css=document.createElement('style');css.textContent=`
#netBadge{position:absolute;left:50%;top:calc(10px + env(safe-area-inset-top,0px));transform:translateX(-50%);background:rgba(22,34,74,.85);color:#fff;font:800 13.5px/1 'Nunito',sans-serif;padding:6px 14px;border-radius:999px;border:2px solid rgba(255,255,255,.5);pointer-events:none;white-space:nowrap}
#netBadge i{display:inline-block;width:9px;height:9px;border-radius:50%;background:#3ccf91;margin-right:7px;vertical-align:0;box-shadow:0 0 8px #3ccf91}
#netBadge.off i{background:#ff6b6b;box-shadow:0 0 8px #ff6b6b}
#chatBar{position:absolute;left:50%;bottom:calc(14px + env(safe-area-inset-bottom,0px));transform:translateX(-50%);width:min(520px,calc(100% - 32px));display:flex;gap:8px;z-index:5}
#chatBar input{flex:1;min-width:0;padding:10px 14px;border:3px solid #16224a;border-radius:16px;font:700 16px 'Nunito',sans-serif;background:#fff;color:#16224a}
#chatBar button{padding:8px 18px;border:3px solid #16224a;background:linear-gradient(#ffe066,#ffb703);border-radius:16px;box-shadow:0 4px 0 #16224a;font:800 16px 'Baloo 2',sans-serif;color:#16224a}
#chatBtn{position:absolute;left:max(16px,env(safe-area-inset-left,0px));top:150px;pointer-events:auto;padding:6px 14px;border:3px solid #16224a;background:linear-gradient(#a8e6ff,#5cc8ff);border-radius:14px;box-shadow:0 4px 0 #16224a;font:800 15px 'Baloo 2',sans-serif;color:#16224a;display:none}
.touch #chatBtn{display:block}
`;document.head.append(css);

const app=$('app');
const EYE='<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="M12 5C6.5 5 2.7 9.4 1.5 12c1.2 2.6 5 7 10.5 7s9.3-4.4 10.5-7C21.3 9.4 17.5 5 12 5zm0 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8z" fill="currentColor"/></svg>';
const box=document.createElement('section');box.id='netLogin';box.className='overlay';
box.innerHTML=`<div class="ui-wrap">
<div class="ui-logo" aria-hidden="true"><span class="l1"><b class="o">Hiệp Sĩ</b><b class="f">Hiệp Sĩ</b></span><span class="l2"><b class="o">Nét Chì</b><b class="f">Nét Chì</b></span><span class="ribbon">ONLINE</span></div>
<form class="ui-card" id="netForm" autocomplete="on" novalidate>
 <div class="ui-tabs" role="tablist">
  <button type="button" role="tab" id="tabLogin" aria-selected="true">Đăng nhập</button>
  <button type="button" role="tab" id="tabReg" aria-selected="false">Đăng ký</button>
  <i class="ui-tabpill" aria-hidden="true"></i>
 </div>
 <p class="ui-hint" id="netHint">Chào mừng hiệp sĩ trở lại!</p>
 <label class="ui-field"><span>Tên tài khoản</span><input id="netUser" maxlength="16" autocomplete="username" placeholder="3–16 ký tự" required></label>
 <label class="ui-field"><span>Mật khẩu</span><input id="netPass" type="password" maxlength="72" autocomplete="current-password" placeholder="Ít nhất 6 ký tự" required><button type="button" class="ui-eye" id="netEye" aria-label="Hiện mật khẩu">${EYE}</button></label>
 <label class="ui-field" id="netPass2Row" hidden><span>Nhập lại mật khẩu</span><input id="netPass2" type="password" maxlength="72" autocomplete="new-password" placeholder="Gõ lại mật khẩu ở trên"></label>
 <div class="ui-msg" id="netMsg" role="status" aria-live="polite"></div>
 <button class="ui-btn big-cta" type="submit" id="netLoginBtn"><span>Đăng nhập</span></button>
 <details class="ui-srv" id="netSrvBox"><summary>Máy chủ: <b id="netSrvTxt"></b></summary>
  <label class="ui-field"><span>Địa chỉ máy chủ</span><input id="netSrv" placeholder="https://..." inputmode="url" autocomplete="off"></label></details>
</form></div>`;
app.append(box);
const badge=document.createElement('div');badge.id='netBadge';badge.hidden=true;$('hud').append(badge);
const chatBar=document.createElement('form');chatBar.id='chatBar';chatBar.hidden=true;chatBar.innerHTML='<input id="chatIn" maxlength="120" placeholder="Nhập tin nhắn, Enter để gửi" autocomplete="off"><button type="submit">Gửi</button>';app.append(chatBar);
const chatBtn=document.createElement('button');chatBtn.id='chatBtn';chatBtn.type='button';chatBtn.textContent='Chat';$('hud').append(chatBtn);

// chưa đăng nhập thì chưa cho vào màn chọn nhân vật
$('start').hidden=true;
let MODE='login';
const msg=(t,ok)=>{const m=$('netMsg');m.textContent=t||'';m.className='ui-msg'+(t?(ok?' ok':' bad'):'');if(t&&!ok){m.classList.remove('shake');void m.offsetWidth;m.classList.add('shake');}};
const setMode=k=>{MODE=k;const reg=k==='register';$('tabLogin').setAttribute('aria-selected',String(!reg));$('tabReg').setAttribute('aria-selected',String(reg));
  $('netPass2Row').hidden=!reg;$('netLoginBtn').firstChild.textContent=reg?'Tạo tài khoản':'Đăng nhập';
  $('netPass').autocomplete=reg?'new-password':'current-password';$('netHint').textContent=reg?'Tạo tài khoản mới để bắt đầu phiêu lưu.':'Chào mừng hiệp sĩ trở lại!';
  box.querySelector('.ui-card').dataset.mode=k;msg('');};
$('tabLogin').addEventListener('click',()=>setMode('login'));
$('tabReg').addEventListener('click',()=>setMode('register'));
$('netEye').addEventListener('click',()=>{const show=$('netPass').type==='password';['netPass','netPass2'].forEach(i=>$(i).type=show?'text':'password');$('netEye').classList.toggle('on',show);$('netEye').setAttribute('aria-label',show?'Ẩn mật khẩu':'Hiện mật khẩu');});
const srvTxt=()=>{$('netSrvTxt').textContent=NET.server?NET.server.replace(/^https?:\/\//,''):'chưa đặt';$('netSrv').value=NET.server;};
srvTxt();if(!NET.server)$('netSrvBox').open=true;
if(NET.user)$('netUser').value=NET.user;
const setServer=()=>{const v=$('netSrv').value.trim().replace(/\/+$/,'');if(v&&!/^https?:\/\//.test(v)){msg('Địa chỉ máy chủ cần bắt đầu bằng https:// hoặc http://');return false;}NET.server=v;LS.set('hsnc-server',v||null);srvTxt();return true;};
$('netSrv').addEventListener('change',setServer);
const busy=on=>{const b=$('netLoginBtn');b.disabled=on;b.classList.toggle('loading',on);};

async function auth(kind){
  if(!setServer())return;
  if(!NET.server){msg('Hãy nhập địa chỉ máy chủ trước.');$('netSrvBox').open=true;return;}
  const user=$('netUser').value.trim(),pass=$('netPass').value;
  if(!user){msg('Nhập tên tài khoản.');$('netUser').focus();return;}
  if(!pass){msg('Nhập mật khẩu.');$('netPass').focus();return;}
  if(kind==='register'){
    if(!/^[\p{L}\p{N}_ ]{3,16}$/u.test(user)){msg('Tên tài khoản 3–16 ký tự, gồm chữ, số, dấu cách hoặc _.');return;}
    if(pass.length<6){msg('Mật khẩu cần ít nhất 6 ký tự.');return;}
    if(pass!==$('netPass2').value){msg('Hai mật khẩu chưa khớp nhau.');$('netPass2').focus();return;}
  }
  msg(kind==='register'?'Đang tạo tài khoản…':'Đang đăng nhập…',true);busy(true);
  try{
    const r=await fetch(NET.server+'/api/'+kind,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user,pass})});
    const d=await r.json().catch(()=>({}));
    if(!r.ok){busy(false);msg(d.error||'Máy chủ báo lỗi '+r.status);return;}
    NET.token=d.token;NET.user=d.user;LS.set('hsnc-token',d.token);LS.set('hsnc-user',d.user);$('netPass').value='';$('netPass2').value='';
    msg(kind==='register'?'Tạo tài khoản thành công!':'Đăng nhập thành công!',true);
    connect();
  }catch(e){busy(false);msg('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');}
}
$('netForm').addEventListener('submit',e=>{e.preventDefault();auth(MODE);});
NET.logout=()=>{const t=NET.token;NET.token=null;LS.set('hsnc-token',null);if(t&&NET.server)fetch(NET.server+'/api/logout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:t})}).catch(()=>{});try{NET.ws&&NET.ws.close();}catch(e){}setTimeout(()=>location.reload(),150);};

/* --- kết nối --- */
function connect(){
  if(!NET.token||!NET.server)return;
  const u=NET.server.replace(/^http/,'ws')+'/ws?token='+encodeURIComponent(NET.token);
  if(NET.ws&&NET.ws.readyState<2){NET.ws.onclose=null;try{NET.ws.close();}catch(e){}}
  let ws;try{ws=new WebSocket(u);}catch(e){busy(false);msg('Địa chỉ máy chủ không hợp lệ.');return;}
  NET.ws=ws;
  ws.onmessage=ev=>{let m;try{m=JSON.parse(ev.data);}catch(e){return;}onMsg(m);};
  ws.onclose=ev=>{
    if(ws!==NET.ws)return;
    const was=NET.on;NET.on=false;NET.others.clear();showBadge();
    if(ev.code===4001){NET.token=null;LS.set('hsnc-token',null);box.hidden=false;$('start').hidden=true;busy(false);msg('Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.');return;}
    if(ev.code===4002){box.hidden=false;$('start').hidden=true;busy(false);msg('Tài khoản vừa đăng nhập ở nơi khác.');return;}
    if(!was&&!NET.gotSave){busy(false);box.hidden=false;msg('Không kết nối được máy chủ, đang thử lại…');}
    NET.retry=Math.min(NET.retry+1,6);setTimeout(connect,1000*NET.retry*NET.retry);
  };
}
function onMsg(m){
  if(m.t==='welcome'){
    NET.on=true;NET.id=m.id;NET.online=m.online;NET.retry=0;showBadge();
    const first=!NET.gotSave;NET.gotSave=true;busy(false);box.hidden=true;if(G.state==='menu'){$('start').hidden=false;window.__ui&&window.__ui.enterStart();}
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
  if(!NET.token){badge.hidden=true;return;}
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
  $('start').querySelector('.note').textContent='Nhân vật tự lưu lên máy chủ. Trong game bấm Enter để chat.';window.__ui&&window.__ui.setUser(NET.user);
}
const snap=()=>({cls:P.cls,name:P.name,lv:P.lv,exp:P.exp,gold:P.gold,pots:P.pots,kills:P.kills,inv:P.inv,eq:P.eq,map:MAPI,mv:2,stones:P.stones,sk:P.sk,books:P.books});
const _save=save;
save=function(){
  _save();
  if(!P||!NET.on)return;
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
if(NET.token&&NET.server){busy(true);msg('Đang vào lại tài khoản '+(NET.user||'')+'…',true);connect();
  setTimeout(()=>{if(!NET.on&&!NET.gotSave){busy(false);msg('Chưa kết nối được máy chủ, đang thử lại. Bạn cũng có thể đăng nhập lại.');}},9000);}
showBadge();
}catch(err){console.error('Online lỗi:',err);}
