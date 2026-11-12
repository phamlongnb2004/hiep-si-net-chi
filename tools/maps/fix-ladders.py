# Thang nối hai bậc nổi: đặt thang trong phần chồng nhau của hai bậc (kéo bậc trên lùi sang trái nếu cần)
import json, os
P = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'shared', 'data.json')
D = json.load(open(P))
def gy(M, x):
    T = M['terr']
    for (x0, y0), (x1, y1) in zip(T, T[1:]):
        if x0 <= x <= x1 and x1 > x0: return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
for i, M in enumerate(D['maps'][13:], 13):
    for r in M['ropes']:
        if abs(gy(M, r[0]) - r[2]) < 2: continue
        up = [p for p in M['plats'] if abs(p[1] - r[1]) < 2 and p[0] <= r[0] <= p[2]]
        lo = [p for p in M['plats'] if abs(p[1] - r[2]) < 2 and len(p) < 5]
        if not up or not lo or any(p[0] <= r[0] <= p[2] for p in lo): continue
        L = min(lo, key=lambda p: min(abs(p[2] - r[0]), abs(p[0] - r[0]))); U = up[0]
        if L[2] < U[0] + 60:
            U[0] = L[2] - 60
        r[0] = (max(U[0], L[0]) + min(U[2], L[2])) // 2
        print(i, 'thang', r, 'trên', U[:3], 'dưới', L[:3])
for s in D['maps'][13]['spots']:
    if s['n'] == 'Sườn Gấu Trúc': s['w'] = 330
json.dump(D, open(P, 'w'), ensure_ascii=False, indent=1)
