
/* ===== GÓC NHÌN NGANG (kiểu game nhập vai cuộn ngang): mặt đất nằm ngang, đi trái/phải, nhảy, bậc đá, nền nhiều lớp ===== */
try{
const SA=window.HSNC_SIDE||{};
const GY=600,WH=720;                 // y của mặt đất (chân nhân vật), chiều cao thế giới
const GRAV=2100,JUMP=760;            // trọng lực, lực nhảy (nhảy cao ~135)
window.HSNC_GY=GY;
const SI={};
for(const k in SA){const im=new Image();im.src=SA[k].u;SI[k]={i:im,w:SA[k].w,h:SA[k].h,top:SA[k].top||0,wall:SA[k].wall||0,tk:SA[k].tk||0};}
const S=k=>{const a=SI[k];return a&&a.i.complete&&a.i.naturalWidth?a:null;};

/* --- bản đồ dạng dải ngang --- */
const R=(x,w)=>({x,y:0,w,h:WH});
const spotsRow=(x0,list,w)=>list.map((s,i)=>Object.assign({x:x0+i*w,y:0,w:w-40,h:WH},s));
const plats=(spots)=>{const a=[];spots.forEach((s,i)=>{a.push({x:s.x+s.w*.18,y:GY-125,w:230});if(i%2===0)a.push({x:s.x+s.w*.55,y:GY-245,w:190});else a.push({x:s.x+s.w*.62,y:GY-125,w:200});});return a;};
const M0={name:'Làng Hiệp Sĩ',lv:'Khu an toàn',w:2600,h:WH,theme:'grass',base:'#5c9e3f',village:true,spawn:{x:1300,y:GY},
  safes:[Object.assign(R(0,2600),{name:'Làng Hiệp Sĩ'})],spots:[],
  npcs:[{id:'shop',x:880,y:GY,name:'Thương Nhân Bảo',role:'Cửa hàng · Sách kỹ năng'},{id:'smith',x:1720,y:GY,name:'Thợ Rèn Cương',role:'Lò rèn · Cường hóa đồ'}],
  houses:[[230,0],[520,1],[2080,2],[2370,3]],fountain:1300,platforms:[],
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
/* --- địa hình nhiều tầng kiểu Ngọc Rồng: bậc cao thấp, đồi, dốc nối nhau (mặt đất không còn là một đường thẳng) --- */
// mỗi bản đồ có MAP.terr = các điểm [x,y] của mặt đất; giữa hai điểm là đoạn thẳng (bằng hoặc dốc)
function terrBuild(M,seed){
  const r=mulberry(seed),pts=[[0,GY]],MAXS=105;   // bậc cao nhất nhảy lên được (nhảy cao ~135)
  // đoạn bằng ở độ cao y từ x0 tới x1; đổi độ cao bằng vách đứng (như khối đất Ninja School), cao quá thì xếp bậc thang
  const lvl=(y,x0,x1)=>{const L=pts[pts.length-1];
    if(Math.abs(L[1]-y)<1){if(pts.length===1)pts.push([x1,y]);else L[0]=Math.max(L[0],x1);return;}
    let cy=L[1],x=Math.max(L[0],x0-Math.ceil(Math.abs(y-cy)/MAXS-1)*80);
    if(x>L[0])pts.push([x,cy]);
    while(Math.abs(y-cy)>MAXS){cy+=Math.sign(y-cy)*Math.round(Math.abs(y-cy)/2);pts.push([x,cy]);x+=80;pts.push([x,cy]);}
    pts.push([x,y]);pts.push([Math.max(x1,x+40),y]);};
  if(M.village){ // làng: hai bên là khối đất cao có nhà, giữa là quảng trường
    lvl(GY-82,0,700);lvl(GY,760,1840);lvl(GY-82,1900,M.w);
  }else{
    for(const s of M.safes)if(s.x<10)lvl(GY,0,s.x+s.w-40);
    const H=[0,-95,-190];let cur=0;
    M.spots.forEach((s,i)=>{
      const opt=[0,1,2].filter(v=>v!==cur);let n=i===0?1:opt[Math.floor(r()*opt.length)];cur=n;
      lvl(GY+H[n],s.x+40,s.x+s.w-20);
    });
    const last=M.safes.find(s=>s.x>10);if(last)lvl(GY,last.x+20,M.w);
  }
  const L=pts[pts.length-1];if(L[0]<M.w)pts.push([M.w,L[1]]);
  M.terr=pts;
  M.platforms=[];   // không còn khối nổi lơ lửng: độ cao đến từ các tầng đất
}
function gYm(M,x){const t=M&&M.terr;if(!t)return GY;if(x<=t[0][0])return t[0][1];
  let lo=0,hi=t.length-1;while(hi-lo>1){const m=(lo+hi)>>1;if(t[m][0]<=x)lo=m;else hi=m;}
  const a=t[lo],b=t[hi];return b[0]===a[0]?b[1]:a[1]+(b[1]-a[1])*clamp((x-a[0])/(b[0]-a[0]),0,1);}
const gY=x=>gYm(MAP,x);
window.HSNC_gY=x=>gY(x);
MAPS.forEach((M,i)=>terrBuild(M,977+i*53));
// đặt lại mọi thứ đứng trên mặt đất theo địa hình
MAPS.forEach(M=>{
  for(const p of M.platforms||[]){const off=GY-p.y;p.y=Math.min(gYm(M,p.x),gYm(M,p.x+p.w/2),gYm(M,p.x+p.w))-off;}
  for(const n of M.npcs||[])n.y=gYm(M,n.x);
  for(const p of M.portals){p.y=gYm(M,p.x);const D=MAPS[p.to];if(D)p.ty=gYm(D,p.tx);}
  M.spawn.y=gYm(M,M.spawn.x);
});


/* --- dựng bản đồ: cảnh vật đứng trên mặt đất, luôn nằm sau nhân vật --- */
const BACK=200;                      // y sắp xếp của cảnh nền: vẫn trong vùng camera nhìn thấy, nhưng nhỏ hơn y của mọi nhân vật (thấp nhất ~220 khi nhảy từ bậc cao) nên luôn vẽ trước
genDecor=function(){
  const M=MAP,r=mulberry(4242+MAPI*31),th=THEMES[M.theme];DECOR=[];FLATS.clear();
  const add=(o,gy)=>{o.gy=gYm(M,o.x)+(gy==null?0:gy-GY);o.y=BACK+DECOR.length*.001;DECOR.push(o);};
  const busy=x=>M.portals.some(p=>Math.abs(p.x-x)<120)||(M.npcs||[]).some(n=>Math.abs(n.x-x)<130)||(M.fountain&&Math.abs(M.fountain-x)<110)||(M.houses||[]).some(h=>Math.abs(h[0]-x)<110);
  // hàng cây, đá, bụi phía sau
  for(let x=40;x<M.w-40;x+=70+r()*90){if(busy(x))continue;if(Math.abs(gYm(M,x-46)-gYm(M,x+46))>2)continue;const k=r();
    if(k<.5)add({k:'tree',x,s:.85+r()*.5,v:th.trees[Math.floor(r()*3)]},GY-6-r()*10);
    else if(k<.75)add({k:'bush',x,s:.8+r()*.5},GY-2);else add({k:'rock',x,s:.7+r()*.6},GY-2);}
  (M.houses||[]).forEach(h=>add({k:'house',x:h[0],v:h[1]},GY-4));
  if(M.fountain)add({k:'fountain',x:M.fountain},GY-2);
  for(const n of M.npcs||[])add({k:'npc',x:n.x,n},GY);
  for(const s of M.spots){let sx=s.x+60;while(sx<s.x+s.w/2&&Math.abs(gYm(M,sx-50)-gYm(M,sx+50))>1)sx+=10;add({k:'sign',x:sx,txt:s.n+' · Cấp '+s.lv[0]+(s.lv[1]>s.lv[0]?'-'+s.lv[1]:'')},GY-1);}
  for(const p of M.portals)add({k:'portal',x:p.x,p},GY);
};
const SGN=new Map();
function themedSign(d){const th=MAP.theme;if(th==='grass')return null;const key=th+'|'+d.txt;if(SGN.has(key))return SGN.get(key);
  const sp=getSpr('sign|'+d.txt,d.txt);if(!sp||!sp.c||!sp.c.width)return null;
  const c=document.createElement('canvas');c.width=sp.c.width;c.height=sp.c.height;const g=c.getContext('2d');g.drawImage(sp.c,0,0);
  try{const im=g.getImageData(0,0,c.width,c.height),a=im.data;
    for(let i=0;i<a.length;i+=4){const r=a[i],gg=a[i+1],b=a[i+2];if(a[i+3]<8||!(gg>r*1.12&&gg>b*1.05&&gg>50))continue;const l=(r+gg+b)/3;
      if(th==='lava'){a[i]=Math.min(255,l*.55+30);a[i+1]=l*.32;a[i+2]=l*.3;}else{const v=Math.min(255,l*1.15+70);a[i]=v*.93;a[i+1]=v*.97;a[i+2]=v;}}
    g.putImageData(im,0,0);}catch(e){return null;}
  const o={c,w:sp.w,h:sp.h,ax:sp.ax,ay:sp.ay};SGN.set(key,o);return o;}
const _ddi=drawDecorItem;
drawDecorItem=function(d){if(d.gy==null)return _ddi(d);
  if(d.k==='sign'){const t=themedSign(d);if(t){ctx.drawImage(t.c,d.x-t.ax,d.gy-t.ay,t.w,t.h);return;}}const y=d.y;d.y=d.gy;try{_ddi(d);}finally{d.y=y;}};
spawnAll=function(){
  G.mons=[];
  for(const s of MAP.spots)for(let i=0;i<s.cnt;i++){
    const x=s.cnt===1?s.x+s.w/2:s.x+80+(s.w-160)*(i+.5)/s.cnt+rand(-30,30);
    const m=spawnMon(s.mon,ri(s.lv[0],s.lv[1]),x,gY(x));m.x0=s.x+30;m.x1=s.x+s.w-30;m.vx=0;G.mons.push(m);}
};
bakeMini=function(){
  const c=document.createElement('canvas');setupCanvas(c,118,78);const g=c.getContext('2d');g.setTransform(dpr,0,0,dpr,0,0);
  const sx=118/WORLD.w,sy=78/WORLD.h,gy=GY*sy;
  const sky=g.createLinearGradient(0,0,0,78);sky.addColorStop(0,{grass:'#8fd3ff',snow:'#c9e3f5',lava:'#5a2a2a'}[MAP.theme]);sky.addColorStop(1,'#ffffff');g.fillStyle=sky;g.fillRect(0,0,118,78);
  for(const s of MAP.spots){g.fillStyle=s.col;g.fillRect(s.x*sx,gYm(MAP,s.x+s.w/2)*sy-14,s.w*sx,14);}
  for(const s of MAP.safes){g.fillStyle='rgba(255,226,110,.9)';g.fillRect(s.x*sx,gYm(MAP,s.x+s.w/2)*sy-14,s.w*sx,14);}
  g.fillStyle=MAP.base;g.beginPath();g.moveTo(0,78);for(const t of (MAP.terr||[[0,GY],[WORLD.w,GY]]))g.lineTo(t[0]*sx,t[1]*sy);g.lineTo(118,78);g.closePath();g.fill();
  g.fillStyle='rgba(27,34,51,.55)';for(const p of MAP.platforms||[])g.fillRect(p.x*sx,p.y*sy,Math.max(2,p.w*sx),2);
  for(const p of MAP.portals){g.fillStyle=p.col;g.strokeStyle='#1b2233';g.lineWidth=1;g.beginPath();g.arc(p.x*sx,p.y*sy-5,3,0,TAU);g.fill();g.stroke();}
  MINIBG=c;
};

/* --- nền: trời + núi xa + lớp giữa (cuộn chậm), mặt đất, bậc đá --- */
const CAPW=118;   // bề ngang mảnh mép khối (đơn vị thế giới), cùng tỉ lệ với dải mặt đất
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
  // lớp sương phủ cảnh nền: đẩy núi/vách nền ra xa, mặt đất đi được nổi rõ phía trước
  {const hz={grass:['rgba(210,235,255,.16)',0],snow:['rgba(225,238,252,.2)',0],lava:['rgba(30,6,8,.42)','rgba(255,90,40,.10)']}[th];
   if(hz){ctx.fillStyle=hz[0];ctx.fillRect(cx-2,cy-2,vw+4,vh+4);
     if(hz[1]){const e=ctx.createLinearGradient(0,GY-260,0,GY);e.addColorStop(0,'rgba(255,90,40,0)');e.addColorStop(1,hz[1]);ctx.fillStyle=e;ctx.fillRect(cx-2,GY-260,vw+4,260);}}}
  // mặt đất theo địa hình: mỗi đoạn (bằng/dốc) vẽ dải đất nghiêng theo đoạn đó, mép cỏ bám đúng mặt đất
  const T=MAP.terr||[[0,GY],[WORLD.w,GY]],hh=Math.max(WH-GY+260,(cy+vh-GY)+240);
  for(let i=0;i<T.length-1;i++){const [x0,y0]=T[i],[x1,y1]=T[i+1];if(x1<=x0||x1<cx-4||x0>cx+vw+4)continue;
    const k=(y1-y0)/(x1-x0),a0=Math.max(x0,cx-4),a1=Math.min(x1,cx+vw+4);
    ctx.save();ctx.beginPath();ctx.rect(a0-.6,cy-50,a1-a0+1.2,vh+300);ctx.clip();
    ctx.translate(x0,y0-GY);ctx.transform(1,k,0,1,0,0);ctx.translate(-x0,0);
    if(gr){const h=hh/(1-gr.top),y=GY-h*gr.top+4;tileX(gr,a0-2,y,h,a1-a0+4);}
    else{ctx.fillStyle=MAP.base;ctx.fillRect(a0-1,GY,a1-a0+2,hh);ctx.fillStyle='rgba(0,0,0,.12)';ctx.fillRect(a0-1,GY,a1-a0+2,6);}
    ctx.restore();
  }
  // vách khối đất (kiểu Ninja School): mặt vách tối dần, mép cỏ chìa ra, bóng đổ xuống nền thấp
  for(let i=0;i<T.length-1;i++){const [x0,y0]=T[i],[x1,y1]=T[i+1];if(x1!==x0||Math.abs(y1-y0)<2||x0<cx-60||x0>cx+vw+60)continue;
    const top=Math.min(y0,y1),bot=Math.max(y0,y1),dir=y1<y0?1:-1;   // dir: khối cao nằm bên phải (1) hay trái (-1)
    const cap=S((dir>0?'capL_':'capR_')+th);
    ctx.save();
    // bóng đổ trên nền thấp, sát chân vách
    const sh=ctx.createRadialGradient(x0-dir*6,bot,2,x0-dir*6,bot,46);sh.addColorStop(0,'rgba(0,0,0,.28)');sh.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=sh;ctx.beginPath();ctx.ellipse(x0-dir*14,bot+2,48,9,0,0,TAU);ctx.fill();
    // mép khối đất vẽ sẵn (vách + cỏ chìa ra), mặt trên khớp đúng mặt đất của khối cao
    if(cap){const wc=cap.tk&&gr?cap.w*(hh/(1-gr.top))/gr.h/cap.tk:CAPW,Hc=wc*cap.h/cap.w,dx=x0-cap.wall*wc+(dir>0?-3:3);ctx.drawImage(cap.i,dx,top-cap.top*Hc,wc,Hc);ctx.restore();continue;}
    // mặt vách: dải tối ở mép khối cao
    const g=ctx.createLinearGradient(x0,0,x0+dir*22,0);g.addColorStop(0,'rgba(20,12,6,.55)');g.addColorStop(1,'rgba(20,12,6,0)');
    ctx.fillStyle=g;ctx.fillRect(dir>0?x0:x0-22,top+10,22,bot-top+30);
    ctx.fillStyle='rgba(20,12,6,.5)';ctx.fillRect(dir>0?x0:x0-2.5,top+8,2.5,bot-top+30);
    ctx.restore();
  }
  // bậc đá nổi
  const pl=S('plat_'+th);
  for(const p of MAP.platforms||[]){if(p.x+p.w<cx-40||p.x>cx+vw+40)continue;
    if(pl){const w=p.w*1.12,h=w*pl.h/pl.w;ctx.drawImage(pl.i,p.x-w*.06,p.y-h*pl.top+3,w,h);}
    else{ctx.fillStyle='#7a5a3a';ctx.beginPath();ctx.roundRect?ctx.roundRect(p.x,p.y,p.w,22,10):ctx.rect(p.x,p.y,p.w,22);ctx.fill();ctx.fillStyle='#5aa14e';ctx.fillRect(p.x,p.y-4,p.w,8);}}
};

/* --- người chơi: chạy trái/phải, nhảy, đứng trên bậc đá --- */
// vách đất: chân thấp hơn mặt khối phía trước thì không đi xuyên qua được
const wallAt=(x,y)=>gY(x)<y-3;
let bumpQ=0;
function moveX(o,nx){nx=clamp(nx,40,WORLD.w-40);if(wallAt(nx,o.y)){bumpQ=.12;return false;}o.x=nx;return true;}
const platUnder=(x,y0,y1)=>{let best=null;for(const p of MAP.platforms||[])if(x>p.x+6&&x<p.x+p.w-6&&p.y>=y0-1&&p.y<=y1+1&&(!best||p.y<best.y))best=p;return best;};
let jumpQ=0,jWas=false,dropQ=0;
window.HSNC_JUMP=()=>{jumpQ=.15;};
const _dash=dashP;
dashP=function(a,len,time,o){_dash(Math.cos(a)>=0?0:Math.PI,len,time,o);}; // lướt ngang
respawnPlayer=function(){P.dead=0;P.x=MAP.spawn.x;P.y=gY(P.x);P.gvy=0;P.hp=P.maxHp;P.flash=0;for(const m of G.mons)if(!m.dead&&m.state==='chase')m.state='return';};
updatePlayer=function(dt){
  const p=P;if(p.gvy==null){p.gvy=0;}
  if(p.dead>0){p.dead-=dt;if(p.dead<=0)respawnPlayer();return;}
  if(G.trans){p.moving=false;return;}
  p.atkCd=Math.max(0,p.atkCd-dt);for(let i=0;i<6;i++)if(p.cds[i]>0)p.cds[i]=Math.max(0,p.cds[i]-dt);p.gcd=Math.max(0,p.gcd-dt);p.potCd=Math.max(0,p.potCd-dt);
  for(let i=p.buffs.length-1;i>=0;i--){p.buffs[i].t-=dt;if(p.buffs[i].t<=0)p.buffs.splice(i,1);}
  p.swing=Math.max(0,p.swing-dt/p.swingDur);p.comboT-=dt;if(p.comboT<=0)p.combo=0;p.flash-=dt;
  // trọng lực (cả khi đang lướt)
  const ground=()=>{const y0=p.y,g0=gY(p.x);p.gvy+=GRAV*dt;let ny=p.y+p.gvy*dt;
    if(p.gvy>=0){const pl=dropQ>0?null:platUnder(p.x,y0,ny);if(pl&&y0<=pl.y+1){ny=pl.y;p.gvy=0;}
      else if(ny>=g0){ny=g0;p.gvy=0;}
      else if(!p.air&&g0-ny<20&&!platUnder(p.x,y0-1,y0+1)){ny=g0;p.gvy=0;}}   // đi xuống dốc: bám đất, không bị bay
    p.y=ny;const g1=gY(p.x);p.air=!(p.gvy===0&&(Math.abs(p.y-g1)<1||!!platUnder(p.x,p.y,p.y)));
    if(!p.air&&p.y<g1-1&&!platUnder(p.x,p.y-1,p.y+1))p.air=true;};
  dropQ=Math.max(0,dropQ-dt);jumpQ=Math.max(0,jumpQ-dt);
  if(p.dash){
    const d=p.dash;moveX(p,p.x+d.vx*dt);p.moving=true;p.walk+=dt*2;
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
  if(down&&!p.air&&p.y<gY(p.x)-2){dropQ=.25;p.y+=2;p.air=true;}
  ground();
  p.moving=dx!==0;
  if(p.moving){const spd=p.spd*bm('spd')*(p.swing>0?.85:1)*(p.air?.92:1);p.vx=dx*spd;if(!moveX(p,p.x+p.vx*dt)&&!manual&&!p.air&&gY(p.x+dx*24)>p.y-125){jumpQ=.15;}/* tự bước lên chỉ khi đang tự đi tới mục tiêu; tự điều khiển thì phải bấm nhảy */if(!p.air)p.walk+=dt*Math.abs(dx);if(!p.focus)p.face=dx>0?1:-1;}else p.vx=0;
  if(p.air){p.moving=true;} // giữ một tư thế khi đang bay lên/rơi xuống
  p.vy=0;
  if(p.focus&&Math.abs(p.focus.x-p.x)>4)p.face=p.focus.x>p.x?1:-1;
  if(p.atkCd<=0&&(atkHeld||inReach))basicAttack();
  if(inSafe(p))p.hp=Math.min(p.maxHp,p.hp+p.maxHp*.08*dt);
  if(!p.air)for(const pt of MAP.portals)if(Math.abs(p.x-pt.x)<46&&p.y>=gY(p.x)-1){G.trans={t:0,pt,sw:false};G.moveTarget=null;p.focus=null;break;}
};

/* --- quái: tuần tra và đuổi theo mặt đất, tăng tốc/giảm tốc mượt (không giật cục) --- */
updateMons=function(dt){
  const pIn=P.dead<=0&&!inSafe(P);
  for(let i=0;i<G.mons.length;i++){
    const m=G.mons[i];if(m.vx==null)m.vx=0;
    if(m.dead){m.respawn-=dt;if(m.respawn<=0){m.dead=false;m.hp=m.hpMax;m.x=m.sx;m.y=gY(m.x);m.vx=0;m.state='idle';fx({k:'poof',x:m.x,y:m.y,max:.5,r:m.t.r});}continue;}
    if(Math.abs(m.x-P.x)>2200){if(m.state!=='idle'){m.state='idle';m.x=m.sx;m.hp=m.hpMax;}continue;}
    m.flash-=dt;m.cd-=dt;m.shoot-=dt;m.lunge=Math.max(0,m.lunge-dt);m.breath=Math.max(0,m.breath-dt);
    if(m.kx){m.x=clamp(m.x+m.kx*dt,30,WORLD.w-30);const k=Math.pow(.02,dt);m.kx*=k;if(Math.abs(m.kx)<4)m.kx=0;}
    m.ky=0;m.y=gY(m.x);
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
        if(!m.hold&&!(m.breath>0))want=Math.sign(dx)*spd;   // đang phun hơi thở: đứng yên, giữ hướng
        if(Math.abs(dx)>2&&!(m.breath>0))m.face=dx>=0?1:-1;
        if(Math.hypot(dx,P.y-m.y)<=m.t.range+14&&m.cd<=0&&!(m.wind>0)){m.cd=m.t.cd;m.wind=.24;}
        if(m.wind>0){m.wind-=dt;m.hold=true;if(m.wind<=0){m.lunge=.25;if(Math.hypot(P.x-m.x,P.y-m.y)<=m.t.range+30){hurtPlayer(m.atk);monHitFx(m);}}}
        // rồng: lấy hơi rồi khạc một luồng dài về phía người chơi (không bắn viên tròn nữa)
        if(m.t.kind==='dragon'&&m.shoot<=0&&!m.br&&Math.abs(dx)<500&&Math.abs(dx)>120){m.shoot=3.6;m.breath=BR_T;startBreath(m);}
      }
    }else{
      const d=m.sx-m.x;want=Math.sign(d)*spd*1.2;m.hp=Math.min(m.hpMax,m.hp+m.hpMax*.25*dt);
      if(Math.abs(d)<12){m.state='idle';m.hp=m.hpMax;want=0;}
    }
    // tăng/giảm tốc mượt
    m.vx+=(want-m.vx)*Math.min(1,dt*7);
    if(Math.abs(m.vx)<3&&want===0)m.vx=0;
    m.x=clamp(m.x+m.vx*dt,30,WORLD.w-30);
    if(!(m.breath>0)){if(m.vx>12)m.face=m.state==='chase'?m.face:1;else if(m.vx<-12)m.face=m.state==='chase'?m.face:-1;}
    m.mv=Math.abs(m.vx)/Math.max(1,m.t.spd);m.walk+=dt*(.4+m.mv*1.6);
    for(let j=i+1;j<G.mons.length;j++){const o=G.mons[j];if(o.dead)continue;const ddx=o.x-m.x,min=(m.t.r+o.t.r)*.55;if(Math.abs(ddx)<min){const push=(min-Math.abs(ddx))*.5*(ddx>=0?1:-1);m.x-=push*Math.min(1,dt*10);o.x+=push*Math.min(1,dt*10);}}
  }
};

/* --- hiệu ứng đòn đánh của quái (ảnh riêng, không vẽ dính vào quái) --- */
const MONFX={boar:'hit',wolf:'bite',bear:'claw',dragon:'claw'},MONFX1={boar:2,wolf:1,bear:0,dragon:0};
function monHitFx(m){const f=window.HSNC_SFX;if(!f)return;
  const dir=P.x>=m.x?1:-1,sq=MONFX[m.t.kind]||'hit';
  if(window.HSNC_SEQOK&&HSNC_SEQOK(sq))f({seq:sq,x:P.x-dir*6,y:P.y-36,h:sq==='hit'?84:72,max:sq==='bite'?.42:.38,flip:dir<0,rot:sq==='claw'?(dir>0?-.15:.15):0,glow:.6,grow:.08,follow:1,ox:-dir*6,oy:-36});
  else if(window.HSNC_FXOK&&HSNC_FXOK('mon',0)){const n=MONFX1[m.t.kind]??2;f({c:'mon',n,x:P.x-dir*10,y:P.y-34,h:n===2?70:64,max:.32,a:'pop',flip:dir<0});}}
function breathFx(m){const f=window.HSNC_SFX;if(!f)return;const sq={dragon:'fire',dragon2:'poison',dragon3:'ice'}[m.type]||'fire';
  const H=(m.t.h||200)/.94*MS,hover=(-70-Math.sin(G.time*2.2+m.id)*12)*MS,face=P.x>=m.x?1:-1;m.face=face;
  const mx=m.x+face*H*.72,my=m.y+hover-H*.58,a=clamp(Math.atan2(P.y-30-my,(P.x-mx)*face),-.7,.7);
  if(window.HSNC_SEQOK&&HSNC_SEQOK(sq))f({seq:sq,x:mx,y:my,h:110,max:.9,flip:face<0,rot:a,px:.02,py:.5,glow:.5,at:m,ox:face*H*.72,oy:hover-H*.58});
  else if(window.HSNC_FXOK)f({c:'mon',n:{fire:3,poison:4,ice:5}[sq],x:mx,y:my,h:90,max:.65,a:'pop',flip:face<0,rot:a,px:.04,py:.5,glow:.6});}

/* --- RỒNG KHẠC: lấy hơi (sáng dần ở miệng, hút tia vào) -> há mồm khạc luồng dài tới người chơi
       -> giữ, rung lửa -> tan; hạt bay dọc luồng, mặt đất bị cháy/đóng băng/nhiễm độc; sát thương theo luồng --- */
const BR_T=1.75,BR_C=.5,BR_E=1.35;              // tổng thời gian, hết lấy hơi, ngừng phun
// màu theo tuổi hạt (0 mới phun -> 1 tan): lõi sáng -> màu chính -> khói
const BRK={dragon:{n:'fire',col:[[255,250,220],[255,214,90],[255,140,30],[230,70,20],[90,40,30]],core:'255,240,190',c1:'255,190,60',c2:'255,90,20',g:'rgba(40,10,0,',rise:-70,smoke:'60,40,35'},
  dragon2:{n:'poison',col:[[235,255,190],[190,250,90],[120,215,50],[70,160,40],[60,80,40]],core:'225,255,170',c1:'190,255,90',c2:'90,200,40',g:'rgba(40,90,20,',rise:-25,smoke:'50,70,35'},
  dragon3:{n:'ice',col:[[225,248,255],[150,215,255],[90,175,245],[60,130,220],[190,220,250]],core:'215,245,255',c1:'140,210,255',c2:'60,140,230',g:'rgba(200,235,255,',rise:25,smoke:'200,225,245'}};
// đốm mềm dựng sẵn cho từng màu (vẽ nhanh, không nhấp nháy)
const BRS={};
function brSprite(kn,i){const key=kn+i;if(BRS[key])return BRS[key];const c=BRK[kn].col[i],cv=document.createElement('canvas');cv.width=cv.height=64;const x=cv.getContext('2d'),e=x.createRadialGradient(32,32,0,32,32,32);
  e.addColorStop(0,`rgba(${c},1)`);e.addColorStop(.45,`rgba(${c},.55)`);e.addColorStop(1,`rgba(${c},0)`);x.fillStyle=e;x.fillRect(0,0,64,64);return BRS[key]=cv;}
// khung rồng theo thời gian khạc: 0 lấy hơi, 1 bắt đầu há, 2-4 há rộng (vỗ cánh qua lại, không giật), 5 ngậm lại
function brFrame(t){if(t<BR_C*.7)return 0;if(t<BR_C)return 1;if(t>BR_E+.1)return 5;return [2,3,4,3][Math.floor((t-BR_C)*6)%4];}
function startBreath(m){const kn=BRK[m.type]?m.type:'dragon';m.br={t:0,kn,k:BRK[kn],parts:[],hit:0,ground:null,reach:0,em:0};m.face=P.x>=m.x?1:-1;G.fx.push({k:'dbr',m,t:0,max:BR_T+.9});}
function breathGeo(m){
  const mo=m.mouth||{x:m.x+m.face*80,y:m.y-120},tx=P.x,ty=P.y-28,face=m.face;
  let a=Math.atan2(ty-mo.y,(tx-mo.x)*face);a=clamp(a,-.15,1.05);   // chĩa xuống phía người chơi
  const L=clamp(Math.hypot(tx-mo.x,ty-mo.y)+80,260,620);
  return {mo,a,L,face,dx:Math.cos(a)*face,dy:Math.sin(a)};
}
function updBreath(m,dt){
  const b=m.br;b.t+=dt;const g=breathGeo(m),k=b.k,on=b.t>BR_C&&b.t<BR_E;b.g=g;
  // độ vươn của luồng: phun ra nhanh, giữ, khi tắt thì đuôi luồng rời miệng bay đi
  b.reach=on?Math.min(g.L,b.reach+dt*g.L*3.2):b.reach;
  if(b.t<BR_C){ // lấy hơi: tia sáng bị hút vào miệng
    if(Math.random()<dt*34){const r=rand(55,110),aa=rand(0,TAU);b.parts.push({x:g.mo.x+Math.cos(aa)*r,y:g.mo.y+Math.sin(aa)*r*.7,vx:0,vy:0,life:.32,max:.32,s:rand(5,9),pull:1});}
  }else if(on){
    // phun liên tục ~260 hạt/giây từ miệng, bay theo hướng luồng, nở to dần
    b.em+=dt*150;const sp=g.L/.5;                     // tới cuối luồng trong ~0,5 giây
    while(b.em>=1){b.em-=1;const da=rand(-.13,.13),ca=Math.cos(da),sa=Math.sin(da),dx=g.dx*ca-g.dy*sa*g.face,dy=g.dy*ca+g.dx*sa*g.face,v=sp*rand(.85,1.08),l=rand(.42,.56),o=rand(0,dt);
      b.parts.push({x:g.mo.x+dx*v*o,y:g.mo.y+dy*v*o,vx:dx*v,vy:dy*v,life:l,max:l,s:rand(.8,1.2),spin:rand(0,TAU)});}
    // chỗ luồng chạm đất
    for(let d=20;d<=b.reach;d+=12){const x=g.mo.x+g.dx*d,y=g.mo.y+g.dy*d,gy=gY(x);if(y>=gy-8){b.ground={x,y:gy-6,t:b.ground?b.ground.t:0};break;}}
    // sát thương theo luồng (4 lần/giây)
    b.hit-=dt;
    if(b.hit<=0&&P.dead<=0&&!inSafe(P)){
      const px=P.x-g.mo.x,py=P.y-30-g.mo.y,along=px*g.dx+py*g.dy,across=Math.abs(-px*g.dy+py*g.dx);
      if(along>0&&along<b.reach+20&&across<24+along*.16){b.hit=.25;hurtPlayer(m.atk*.42);}
    }
  }
  if(b.ground)b.ground.t+=dt;
  for(let i=b.parts.length-1;i>=0;i--){const q=b.parts[i];q.life-=dt;
    if(q.pull){q.x+=(g.mo.x-q.x)*Math.min(1,dt*9);q.y+=(g.mo.y-q.y)*Math.min(1,dt*9);}
    else{q.x+=q.vx*dt;q.y+=q.vy*dt;const dr=Math.pow(.35,dt);q.vx*=dr;q.vy=q.vy*dr+k.rise*dt*2.2+Math.sin(G.time*13+q.spin*6)*dt*90;
      {const gq=gY(q.x)-6;if(q.y>gq){q.y=gq;q.vy=-Math.abs(q.vy)*.15;q.vx*=1.02;}}}   // chạm đất thì loang ra
    if(q.life<=0)b.parts.splice(i,1);}
  if(b.t>=BR_T+.9){m.br=null;}
}
const _um2=updateMons;
updateMons=function(dt){for(const m of G.mons)m.px=m.x;_um2(dt);for(const m of G.mons){if(m.px==null||m.dead)continue;if(Math.abs(gY(m.x)-gY(m.px))>6){m.x=m.px;m.vx=0;if(m.kx)m.kx=0;}m.y=gY(m.x);}for(const m of G.mons)if(m.br){if(m.dead||m.stun>0&&m.br.t<BR_C){m.br=null;continue;}updBreath(m,dt);}};
function drawBreath(f){
  const m=f.m,b=m&&m.br;if(!b||m.dead||!b.g)return;
  const g=b.g,k=b.k,t=b.t,kn=b.kn,fade=t<BR_E?1:Math.max(0,1-(t-BR_E)/.35);
  // vết trên mặt đất (cháy / độc / băng), sáng dịu, không chớp
  if(b.ground){const gr=b.ground,a=Math.min(1,gr.t*3)*(t>BR_E?Math.max(0,1-(t-BR_E)/.9):1);
    ctx.save();ctx.globalAlpha=a*.7;const e=ctx.createRadialGradient(gr.x,gr.y,4,gr.x,gr.y,90);e.addColorStop(0,k.g+'.75)');e.addColorStop(1,k.g+'0)');
    ctx.fillStyle=e;ctx.beginPath();ctx.ellipse(gr.x,gr.y,95,20,0,0,TAU);ctx.fill();
    ctx.globalCompositeOperation='lighter';ctx.globalAlpha=a*.45*(.92+Math.sin(G.time*6)*.08);const e2=ctx.createRadialGradient(gr.x,gr.y,2,gr.x,gr.y,70);e2.addColorStop(0,'rgba('+k.c1+',.9)');e2.addColorStop(1,'rgba('+k.c2+',0)');
    ctx.fillStyle=e2;ctx.beginPath();ctx.ellipse(gr.x,gr.y-4,70,15,0,0,TAU);ctx.fill();ctx.restore();}
  // khói/khí (vẽ thường, không cộng sáng) cho phần hạt già: làm luồng có khối
  ctx.save();
  for(const q of b.parts){if(q.pull)continue;const u=1-q.life/q.max;if(u<.45)continue;
    const r=(10+u*44)*q.s;ctx.globalAlpha=(kn==='dragon3'?.16:.22)*Math.sin((u-.45)/.55*Math.PI);ctx.drawImage(brSprite(kn,4),q.x-r,q.y-r,r*2,r*2);}
  for(const q of b.parts){if(q.pull)continue;const u=1-q.life/q.max;if(u<.12||u>.85)continue;
    const r=(8+u*40)*q.s*.8;ctx.globalAlpha=.3*Math.sin((u-.12)/.73*Math.PI);ctx.drawImage(brSprite(kn,u<.45?2:3),q.x-r,q.y-r,r*2,r*2);}
  ctx.restore();
  ctx.save();ctx.globalCompositeOperation='lighter';
  // hạt: lửa/khí nở to dần, đổi màu theo tuổi
  for(const q of b.parts){
    if(q.pull){const a=q.life/q.max;ctx.globalAlpha=.9*(1-a)+.1;const r=q.s*(.6+a);ctx.drawImage(brSprite(kn,1),q.x-r,q.y-r,r*2,r*2);continue;}
    const u=1-q.life/q.max,ci=Math.min(3,Math.floor(u*4.6)),r=(8+u*40)*q.s;
    ctx.globalAlpha=Math.min(1,(1-u)*1.6)*(kn==='dragon3'?.2:.28);ctx.drawImage(brSprite(kn,ci),q.x-r,q.y-r,r*2,r*2);
    if(kn==='dragon3'&&u>.25&&(q.spin*10|0)%3===0){ctx.globalAlpha=(1-u);ctx.fillStyle='#fff';const s=2.2;ctx.save();ctx.translate(q.x,q.y);ctx.rotate(q.spin+u*4);ctx.fillRect(-s*2,-s*.3,s*4,s*.6);ctx.fillRect(-s*.3,-s*2,s*.6,s*4);ctx.restore();}}
  // ánh sáng ở miệng: chỉ khi lấy hơi sắp khạc, khạc ra thì tắt nhanh
  const glow=t<BR_C?t/BR_C:Math.max(0,1-(t-BR_C)/.12);
  if(glow>0){const R=24+glow*30+Math.sin(G.time*9)*2,e=ctx.createRadialGradient(g.mo.x,g.mo.y,0,g.mo.x,g.mo.y,R);e.addColorStop(0,'rgba(255,255,255,'+(.85*glow)+')');e.addColorStop(.35,'rgba('+k.c1+','+(.6*glow)+')');e.addColorStop(1,'rgba('+k.c2+',0)');ctx.globalAlpha=1;ctx.fillStyle=e;ctx.beginPath();ctx.arc(g.mo.x,g.mo.y,R,0,TAU);ctx.fill();}
  ctx.restore();
}
const _dfx=drawFx;
drawFx=function(f){if(f.k==='dbr')return drawBreath(f);return _dfx(f);};

/* --- vẽ quái: thân nhún, chân bước (lắc dải chân), rồng bay lơ lửng --- */
const _dm=drawMon,MS=.76;          // quái nhỏ lại cho cân với nhân vật
// khung hoạt ảnh quái (ChatGPT vẽ): 0 đứng, 1-4 bước chạy / vỗ cánh, 5 đánh
const MF={};
for(const k in (window.HSNC_MON||{}))MF[k]=HSNC_MON[k].map(f=>{const im=new Image();im.src=f.u;return {i:im,hr:f.hr,ar:f.ar,cx:f.cx,mx:f.mx,my:f.my,cy:f.cy};});
const mReady=k=>MF[k]&&MF[k].every(f=>f.i.complete&&f.i.naturalWidth);
drawMon=function(m){
  const sp=monSprite(m);if(!sp||!sp.c)return _dm(m);
  const t=G.time,r=m.t.r,k=m.t.k||1,fly=m.t.kind==='dragon',mv=m.mv||0;
  const hover=fly?-70-Math.sin(t*2.2+m.id)*12:0,ph=m.walk*(fly?3:9);
  ctx.save();ctx.translate(m.x,m.y);ctx.scale(MS,MS);
  ctx.globalAlpha=fly?.5:1;ctx.drawImage(shadowSpr(),-m.t.sw*1.3*(fly?.8:1),r*.12-r*.5,m.t.sw*2.6*(fly?.8:1),r);ctx.globalAlpha=1;
  if(m.flash>0&&Math.floor(t*30)%2)ctx.globalAlpha=.55;
  ctx.translate(0,hover);ctx.scale(m.face,1);{const wu=m.wind>0?1-m.wind/.24:0;if(wu>0){ctx.translate(-wu*9*k,0);ctx.scale(1+wu*.06,1-wu*.07);}}ctx.translate(m.lunge>0?Math.sin(m.lunge/.25*Math.PI)*10*k:0,0);
  const W=sp.w,H=sp.h,X=sp.x,Y=-H*.97,img=sp.c,iw=img.naturalWidth||img.width,ih=img.naturalHeight||img.height;
  if(mReady(m.type)){
    // vẽ theo khung: H là chiều cao khung đứng; neo giữa thân để đổi khung không bị trượt
    const F=MF[m.type],fi=Math.floor(fly?G.time*7+m.id:m.walk*5.5)%4;
    // rồng: luôn vỗ cánh (hơi thở là hiệu ứng riêng); thú: khung vồ khi đánh
    let q=fly?F[1+fi]:m.lunge>0?F[5]:mv>.06?F[1+fi]:F[0];
    const BF=m.br&&MF[m.type+'_br'];
    if(BF&&mReady(m.type+'_br'))q=BF[brFrame(m.br.t)];
    const fh=H*q.hr,fw=fh*q.ar,breathe=!fly&&mv<.06&&m.lunge<=0?Math.sin(t*2+m.id)*.015:0;
    // rồng: giữ tâm thân ở cùng độ cao ở mọi khung (bay lẫn khạc) để không bị nhảy khi đổi khung
    let y0=-fh;if(fly&&q.cy!=null){const R=F.ref||(F.ref=F.slice(1,5).map(z=>z.hr*(1-(z.cy??.6))).sort((x,y)=>x-y)[1]);y0=-R*H-q.cy*fh;}
    ctx.save();ctx.scale(1,1+breathe);ctx.drawImage(q.i,-q.cx*H,y0,fw,fh);ctx.restore();
    if(fly){const lx=-q.cx*H+(q.mx!=null?q.mx:.92)*fw,ly=y0+(q.my!=null?q.my:.38)*fh;m.mouth={x:m.x+MS*m.face*lx,y:m.y+MS*(hover+ly)};}
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
