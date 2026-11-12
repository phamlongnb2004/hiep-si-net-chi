# Kiểm tra bản đồ đi lại được: mọi mặt đứng (đất, thanh) tới được từ chỗ xuất hiện và quay về được (nhảy lên tối đa ~150px,
# leo thang/dây, nhảy qua khe), mọi cổng và khu quái nằm trên mặt tới được. Dùng: python3 tools/maps/check-reach.py [chỉ số bản đồ ...]
# (auto trong game: client/tools/check_nav.gd, chạy bằng HSNC_PREVIEW=navcheck)
import json, sys, os
D = json.load(open(os.path.join(os.path.dirname(__file__), '../../shared/data.json')))
UP = 150.0   # nhảy lên tối đa (đỉnh ~160)
GAP = 120.0
def gy(T, x):
    for i in range(len(T)-1):
        x0,y0=T[i]; x1,y1=T[i+1]
        if x0 <= x <= x1 and x1 > x0:
            return y0 + (y1-y0)*(x-x0)/(x1-x0)
    return T[-1][1]
def analyze(mi):
    M = D['maps'][mi]; T = M.get('terr') or [[0,600],[M['w'],600]]; W = M['w']
    nodes = []  # (a, b, yfun, kind)
    a = 0.0
    for i in range(1, len(T)):
        if abs(T[i][1]-T[i-1][1]) > 30 and abs(T[i][0]-T[i-1][0]) <= 12:
            cut = (T[i][0]+T[i-1][0])/2
            nodes.append(('g', a, cut)); a = cut
    nodes.append(('g', a, W))
    for p in M.get('plats', []):
        nodes.append(('p', p[0], p[2], p))
    def y(n, x):
        if n[0] == 'g': return gy(T, min(max(x, n[1]+1), n[2]-1))
        p = n[3]; t = (x - p[0])/(p[2]-p[0]) if p[2] != p[0] else 0
        return p[1] + (p[3]-p[1])*min(max(t,0),1)
    N = len(nodes); E = {i:set() for i in range(N)}
    def surf_at(x, yy, below=True):
        best=None; bd=1e9
        for j,n in enumerate(nodes):
            if n[1]-1 <= x <= n[2]+1:
                ny = y(n, x); d = ny - yy
                if (d >= -2 if below else abs(d) < 30) and d < bd: bd=d; best=j
        return best
    for i,n in enumerate(nodes):
        # đi ra mép / rơi xuyên thanh → rơi xuống mặt bên dưới
        for x in ([n[1]-2, n[2]+2] if n[0]=='p' else []) + ([n[1]+5 + k*(n[2]-n[1]-10)/8 for k in range(9)] if n[0]=='p' else []):
            j = surf_at(x, y(n, min(max(x,n[1]),n[2]))+3)
            if j is not None and j != i: E[i].add(j)
        if n[0]=='g':
            # sang đoạn đất kế bên (vách)
            for j,m in enumerate(nodes):
                if m[0]=='g' and j!=i and (abs(m[1]-n[2])<1 or abs(m[2]-n[1])<1):
                    xe = n[2] if abs(m[1]-n[2])<1 else n[1]
                    hn = y(n, xe-3 if xe==n[2] else xe+3); hm = y(m, xe+3 if xe==n[2] else xe-3)
                    if hn - hm <= UP: E[i].add(j)   # lên được (hoặc xuống)
        # nhảy lên thanh phía trên (xuyên từ dưới) trong khoảng chồng ngang
        for j,m in enumerate(nodes):
            if m[0]!='p' or j==i: continue
            lo = max(n[1], m[1]); hi = min(n[2], m[2])
            xs = [lo + k*(hi-lo)/10 for k in range(11)] if hi > lo else []
            # nhảy chéo tới mép thanh
            xs += [m[1]-GAP*0.5, m[2]+GAP*0.5]
            for x in xs:
                if not (n[1] <= x <= n[2]): continue
                xm = min(max(x, m[1]), m[2])
                d = y(n, x) - y(m, xm)
                if 0 < d <= UP and abs(xm-x) <= GAP: E[i].add(j); break
        # đi/nhảy từ mép mặt này sang mặt khác (cầu nối vách, khe hở): lên tối đa UP, xuống tùy ý
        for xe, sg in ((n[1], -1), (n[2], 1)):
            ye = y(n, xe - sg*2)
            for j,m in enumerate(nodes):
                if j == i: continue
                for dx in (0, 20, 50, 80, GAP):
                    xm = xe + sg*dx
                    if m[1]-1 <= xm <= m[2]+1:
                        d = ye - y(m, xm)
                        if d <= UP and d > -400: E[i].add(j); break
    for r in M.get('ropes', []):
        x, yt, yb = r[0], r[1], r[2]
        top = surf_at(x, yt-1); bot = surf_at(x, yb-1)
        if top is not None and bot is not None and top != bot: E[top].add(bot); E[bot].add(top)
        elif bot is None or top is None: print('  thang lơ lửng', r, top, bot)
    # thành phần liên thông mạnh: từ spawn đi tới đâu, từ đâu về được spawn
    sp = M.get('spawn', {'x':220,'y':600}); s = surf_at(sp['x'], sp['y']-40)
    def reach(src, adj):
        seen={src}; st=[src]
        while st:
            u=st.pop()
            for v in adj[u]:
                if v not in seen: seen.add(v); st.append(v)
        return seen
    R = {i:set() for i in range(N)}
    for u in E:
        for v in E[u]: R[v].add(u)
    fw = reach(s, E); bw = reach(s, R)
    bad = []
    for i,n in enumerate(nodes):
        tag = []
        if i not in fw: tag.append('KHÔNG TỚI ĐƯỢC')
        if i not in bw: tag.append('KHÔNG QUAY LẠI ĐƯỢC')
        if tag: bad.append((n[:3] if n[0]=='g' else ('p',)+tuple(n[3]), ' + '.join(tag), round(y(n,(n[1]+n[2])/2))))
    print(mi, M['name'], 'w', W, '| mặt', N, '| lỗi', len(bad))
    for b in bad: print('   ', b)
    # điểm cần tới: cổng, khu quái
    for p in M.get('portals', []):
        j = surf_at(p['x'], p['y']-40)
        if j is None or j not in fw or j not in bw: print('    CỔNG lỗi', p['label'], p['x'], p['y'], j)
    for sp_ in M.get('spots', []):
        if 'p' in sp_:
            j = len([n for n in nodes if n[0]=='g']) + sp_['p']
        else:
            j = surf_at(sp_['x'] + sp_['w']/2, 0)
            j = surf_at(sp_['x'] + sp_['w']/2, y(nodes[j], sp_['x']+sp_['w']/2) - 40) if j is not None else None
        if j is None or j not in fw or j not in bw: print('    KHU QUÁI lỗi', sp_['n'], sp_.get('x'), sp_.get('p'), j)
for mi in (map(int, sys.argv[1:]) if len(sys.argv) > 1 else range(len(D['maps']))):
    analyze(mi)
