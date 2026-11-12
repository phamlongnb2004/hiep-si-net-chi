# Dữ liệu bản đồ 2-5 của đợt 1 (chỉ số 15-22) + nối cổng từ Rừng Trúc Mây. Chạy sau m01-data.py.
import json, os
P = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'shared', 'data.json')
D = json.load(open(P)); maps = D['maps']; MO = D['mons']
assert len(maps) >= 15
del maps[15:]

def mob(n, kind, gold, r, h, rng, spd, afx, ab=None, fly=0, cd=1.4):
    o = {"n": n, "kind": kind, "hp": 0, "atk": 0, "def": 0, "exp": 0, "gold": gold, "aggro": 240, "cd": cd, "drop": 0.3, "boss": False,
         "r": r, "h": h, "range": rng, "spd": spd, "afx": afx}
    if ab: o["ab"] = ab
    if fly: o["fly"] = fly
    return o
def boss(n, kind, hp, atk, df, exp, gold, h, sk, afx):
    return {"n": n, "kind": kind, "hp": hp, "atk": atk, "def": df, "exp": exp, "gold": gold, "aggro": 520, "cd": 1.8, "drop": 1, "boss": True,
            "r": 74, "h": h, "range": 115, "spd": 80, "sk": sk, "skcd": [4.5, 6.5], "afx": afx}
SPIT = {"k": "spit", "cd": 3.2, "min": 110, "max": 400, "sp": 330, "m": 0.8, "pois": [3, 0.12]}
CHARGE = {"k": "charge", "cd": 4.5, "min": 150, "max": 380, "spd": 560, "m": 1.4}
SWEEP = {"k": "sweep", "n": 3, "r": 150, "m": 1.5}
SHELL = {"k": "shell", "every": 7, "t": 2.4, "def": 3}
ZAP = {"k": "zap", "slow": 0.45, "t": 1.6}
BOOM = {"k": "boom", "r": 120, "m": 1.3, "delay": 0.7}
MO.update({
 "dscorp": mob("Bọ Cạp Cát", "dscorp", [26, 48], 34, 70, 55, 95, "poison_splash", SPIT),
 "dcamel": mob("Lạc Đà Gai", "dcamel", [28, 50], 40, 100, 60, 75, "dust_feather", CHARGE, cd=1.7),
 "dmummy": mob("Xác Ướp", "dmummy", [28, 52], 32, 90, 60, 70, "dust_feather", SWEEP, cd=1.6),
 "scorpking": boss("Bọ Cạp Hoàng Đế", "scorpking", 3900, 44, 28, 6300, [520, 740], 200, [
   {"k": "cone", "n": "Chích Độc", "a": "s1", "wind": 0.8, "len": 420, "m": 1.3, "pois": [4, 0.22], "zone": 4, "fx": "desert_sting", "zfx": "poison_splash"},
   {"k": "pull", "n": "Bão Cát", "a": "s2", "wind": 0.6, "t": 2.6, "r": 420, "pull": 45, "m": 0.4, "every": 0.5, "fx": "desert_sandstorm"},
   {"k": "rain", "n": "Chui Cát Đột Kích", "a": "s3", "wind": 1.0, "cnt": 6, "r": 85, "m": 1.5, "slow": [0.5, 2], "fx": "desert_erupt"}], "dust_feather"),
 "ceagle": mob("Đại Bàng Hẻm Núi", "ceagle", [30, 54], 32, 85, 55, 120, "claw", fly=60),
 "clizard": mob("Thằn Lằn Đá", "clizard", [30, 54], 36, 72, 58, 90, "dust_feather", SWEEP, cd=1.5),
 "cpebble": mob("Golem Cuội", "cpebble", [32, 56], 36, 88, 55, 65, "shockwave", SHELL, cd=1.7),
 "redgolem": boss("Golem Núi Đỏ", "redgolem", 4600, 48, 32, 7500, [580, 820], 235, [
   {"k": "rain", "n": "Ném Tảng Đá", "a": "s1", "wind": 1.0, "cnt": 5, "r": 95, "m": 1.7, "fx": "canyon_boulder"},
   {"k": "spikes", "n": "Dậm Nứt Đất", "a": "s2", "wind": 1.0, "len": 480, "m": 1.6, "stun": 1.2, "fx": "canyon_quake"},
   {"k": "sweep", "n": "Lớp Giáp Đá", "a": "s3", "wind": 0.8, "r": 380, "m": 1.5, "fx": "canyon_shards"}], "shockwave"),
 "sfox": mob("Cáo Hoa", "sfox", [32, 58], 32, 78, 55, 120, "claw", CHARGE, cd=1.3),
 "spixie": mob("Tinh Linh Cánh Hoa", "spixie", [32, 58], 26, 70, 50, 100, "electric", ZAP, fly=50),
 "sncat": mob("Ninja Mèo", "sncat", [34, 60], 30, 86, 58, 115, "claw", SWEEP, cd=1.2),
 "ninetail": boss("Hồ Ly Chín Đuôi", "ninetail", 5300, 52, 34, 8800, [640, 900], 225, [
   {"k": "rain", "n": "Hoa Vũ", "a": "s1", "wind": 0.9, "cnt": 7, "r": 85, "m": 1.3, "slow": [0.5, 2], "fx": "sakura_petals"},
   {"k": "beam", "n": "Lửa Cáo", "a": "s2", "wind": 1.0, "len": 620, "m": 1.6, "kb": 240, "fx": "sakura_foxfire"},
   {"k": "summon", "n": "Phân Thân", "a": "s3", "wind": 0.7, "mon": "sfox", "fx": "sakura_smoke", "cnt": 3}], "claw"),
 "ggnome": mob("Nấm Lùn", "ggnome", [34, 62], 28, 76, 50, 80, "spores", BOOM, cd=1.5),
 "gfly": mob("Đom Đóm Khổng Lồ", "gfly", [34, 62], 28, 72, 50, 105, "electric", ZAP, fly=50),
 "gsnail": mob("Ốc Sên Phát Quang", "gsnail", [36, 64], 36, 74, 55, 55, "bubbles", SHELL, cd=1.7),
 "shroommom": boss("Mẹ Nấm Cổ Thụ", "shroommom", 6100, 56, 37, 10200, [700, 980], 240, [
   {"k": "cone", "n": "Bào Tử Độc", "a": "s1", "wind": 0.8, "len": 440, "m": 1.3, "pois": [4, 0.24], "zone": 4, "fx": "glow_spore", "zfx": "spores"},
   {"k": "summon", "n": "Triệu Nấm Con", "a": "s2", "wind": 0.7, "mon": "ggnome", "fx": "glow_sprout", "cnt": 3},
   {"k": "spikes", "n": "Rễ Trói", "a": "s3", "wind": 1.0, "len": 480, "m": 1.6, "stun": 1.3, "fx": "glow_roots"}], "spores"),
})
L = lambda a: [a, a]
def spots(*S):
    out = []
    for s in S:
        n, mon, lv, cnt, x, w = s[:6]; o = {"n": n, "mon": mon, "lv": lv, "cnt": cnt, "x": x, "w": w}
        if len(s) > 6: o["p"] = s[6]
        out.append(o)
    return out
def lad(*R): return [[x, t, b, "ladder"] for x, t, b in R]
def arena(name, theme, frm, gx, gy, req, ofs, boss_mon, blv):
    return {"name": name, "lv": "Khu trùm", "w": 2000, "h": 720, "theme": theme, "village": False, "spawn": {"x": 220, "y": 600},
            "safes": [{"x": 0, "w": 420, "name": "Lối ra"}], "npcs": [], "houses": [], "fountain": None, "terr": [[0, 600], [2000, 600]],
            "portals": [{"x": 60, "y": 600, "to": frm, "tx": gx, "ty": gy, "label": maps[frm]["name"] if frm < len(maps) else "", "lv": "Ra khỏi khu trùm"}],
            "arena": {"from": frm, "gx": gx, "req": req, "ofs": ofs},
            "spots": [{"n": D['mons'][boss_mon]['n'], "mon": boss_mon, "lv": [blv, blv], "cnt": 1, "x": 850, "w": 700}],
            "plats": [[560, 490, 820, 490], [1400, 490, 1660, 490]], "ropes": [], "water": [], "lava": []}
def base(name, lv, theme, terr, safes, portals, sp, plats, ropes, water=()):
    return {"name": name, "lv": lv, "w": terr[-1][0], "h": 720, "theme": theme, "village": False, "spawn": {"x": 220, "y": 600},
            "safes": safes, "npcs": [], "houses": [], "fountain": None, "terr": terr, "portals": portals, "spots": sp,
            "plats": plats, "ropes": ropes, "water": list(water), "lava": []}

# nối Rừng Trúc Mây (13) -> Sa Mạc (15)
m13 = maps[13]
m13["safes"] = [s for s in m13["safes"] if s["name"] != "Cổng Sa Mạc"] + [{"x": 5240, "w": 360, "name": "Cổng Sa Mạc"}]
m13["portals"] = [p for p in m13["portals"] if p["to"] != 15] + [{"x": 5540, "y": 600, "to": 15, "tx": 220, "ty": 600, "label": "Sa Mạc Cát Vàng", "lv": "Cấp 43-46"}]
for s in m13["spots"]:
    if s["n"] == "Cuối Rừng Khỉ": s["w"] = 220; s["cnt"] = 3

# 15 Sa Mạc Cát Vàng
maps.append(base("Sa Mạc Cát Vàng", "Cấp 43-46", "desert",
  [[0,600],[1000,600],[1300,530],[1800,530],[2100,600],[2550,600],[2550,505],[2950,505],[2950,600],[3500,600],[3500,640],[4100,640],[4100,600],[4500,600],[4500,505],[4850,505],[4850,410],[5300,410],[5300,600],[5800,600]],
  [{"x":0,"w":440,"name":"Cổng Rừng Trúc"},{"x":2640,"w":220,"name":"Hang Bọ Cạp Hoàng Đế"},{"x":5360,"w":440,"name":"Cổng Hẻm Núi"}],
  [{"x":60,"y":600,"to":13,"tx":5380,"ty":600,"label":"Rừng Trúc Mây","lv":"Cấp 40-43"},
   {"x":2750,"y":505,"to":16,"tx":220,"ty":600,"label":"Hang Bọ Cạp Hoàng Đế","lv":"Trùm · Cấp 46+","arena":1},
   {"x":5740,"y":600,"to":17,"tx":220,"ty":600,"label":"Hẻm Núi Đá Đỏ","lv":"Cấp 46-49"}],
  spots(("Bãi Bọ Cạp","dscorp",[43,44],5,450,540),("Gò Bọ Cạp","dscorp",L(44),2,650,260,0),("Đồi Lạc Đà","dcamel",[44,45],5,1310,480),
        ("Mỏm Lạc Đà","dcamel",L(45),2,1400,260,1),("Bậc Xác Ướp","dmummy",L(45),2,2150,250,5),("Lăng Xác Ướp","dmummy",[45,46],5,2960,520),
        ("Bè Cạp","dscorp",L(45),2,3550,250,2),("Bè Cạp Trên","dscorp",[45,46],2,3820,240,3),("Ốc Đảo Lạc Đà","dcamel",[45,46],4,4110,380),
        ("Đền Xác Ướp","dmummy",L(46),5,4860,430),("Tháp Xác Ướp","dmummy",L(46),2,4880,270,4)),
  [[650,490,910,490],[1400,420,1660,420],[3550,520,3800,520],[3820,420,4060,420],[4880,300,5150,300],[2150,490,2400,490]],
  lad((890,490,600),(1430,420,530),(3570,520,640),(3840,420,520),(4900,300,410),(2380,490,600)), [[3500,4100,612]]))
maps.append(arena("Hang Bọ Cạp Hoàng Đế", "desertcave", 15, 2750, 505, 46, 21, "scorpking", 48))
# 17 Hẻm Núi Đá Đỏ
maps.append(base("Hẻm Núi Đá Đỏ", "Cấp 46-49", "canyon",
  [[0,600],[800,600],[800,505],[1500,505],[1500,410],[2000,410],[2000,690],[2600,690],[2600,410],[3100,410],[3100,600],[3800,600],[3800,505],[4300,505],[4300,600],[4700,600],[4700,690],[5100,690],[5100,600],[5800,600]],
  [{"x":0,"w":440,"name":"Cổng Sa Mạc"},{"x":2740,"w":220,"name":"Lò Golem Núi Đỏ"},{"x":5360,"w":440,"name":"Cổng Anh Đào"}],
  [{"x":60,"y":600,"to":15,"tx":5580,"ty":600,"label":"Sa Mạc Cát Vàng","lv":"Cấp 43-46"},
   {"x":2850,"y":410,"to":18,"tx":220,"ty":600,"label":"Lò Golem Núi Đỏ","lv":"Trùm · Cấp 49+","arena":1},
   {"x":5740,"y":600,"to":19,"tx":220,"ty":600,"label":"Thung Lũng Anh Đào","lv":"Cấp 49-52"}],
  spots(("Bãi Cuội","cpebble",[46,47],4,450,340),("Tổ Đại Bàng","ceagle",[46,47],2,480,260,0),("Vách Thằn Lằn","clizard",L(47),5,810,680),
        ("Mỏm Đại Bàng","ceagle",[47,48],2,1000,260,1),("Đỉnh Cuội","cpebble",[47,48],4,1510,480),("Ngọn Đại Bàng","ceagle",L(48),2,1600,260,2),
        ("Đáy Hẻm","clizard",[47,48],4,2050,500),("Lòng Hẻm Thằn Lằn","clizard",[48,49],5,3110,680),("Giàn Đại Bàng","ceagle",L(48),2,3300,260,4),
        ("Gò Cuội Đỏ","cpebble",[48,49],4,3810,480),("Mỏ Đại Bàng","ceagle",L(49),2,3900,260,5),("Vực Thằn Lằn","clizard",L(49),3,4710,380),
        ("Cuối Hẻm","cpebble",L(49),3,5110,240)),
  [[480,490,740,490],[1000,400,1260,400],[1600,300,1860,300],[2000,410,2600,410,"bridge"],[3300,490,3560,490],[3900,400,4160,400],[4700,600,5100,600,"bridge"]],
  lad((720,490,600),(1030,400,505),(1630,300,410),(3540,490,600),(3920,400,505)) + [[2300,410,690,"rope"],[4900,600,690,"rope"]]))
maps.append(arena("Lò Golem Núi Đỏ", "canyoncave", 17, 2850, 410, 49, 24, "redgolem", 51))
# 19 Thung Lũng Anh Đào
maps.append(base("Thung Lũng Anh Đào", "Cấp 49-52", "sakura",
  [[0,600],[1200,600],[1200,505],[1900,505],[1900,600],[2300,600],[2300,640],[2900,640],[2900,600],[3000,600],[3000,505],[3400,505],[3400,600],[4300,600],[4300,505],[4600,505],[4600,410],[5200,410],[5200,600],[5800,600]],
  [{"x":0,"w":440,"name":"Cổng Hẻm Núi"},{"x":3090,"w":220,"name":"Đền Hồ Ly"},{"x":5360,"w":440,"name":"Cổng Rừng Nấm"}],
  [{"x":60,"y":600,"to":17,"tx":5580,"ty":600,"label":"Hẻm Núi Đá Đỏ","lv":"Cấp 46-49"},
   {"x":3200,"y":505,"to":20,"tx":220,"ty":600,"label":"Đền Hồ Ly","lv":"Trùm · Cấp 52+","arena":1},
   {"x":5740,"y":600,"to":21,"tx":220,"ty":600,"label":"Rừng Nấm Phát Sáng","lv":"Cấp 52-55"}],
  spots(("Đồi Cáo Hoa","sfox",[49,50],5,450,740),("Cành Tinh Linh","spixie",L(50),2,500,260,0),("Ngọn Tinh Linh","spixie",[50,51],2,800,260,1),
        ("Sân Ninja","sncat",[50,51],5,1210,680),("Mái Tinh Linh","spixie",L(51),2,1350,260,2),("Bờ Cáo","sfox",[50,51],3,1910,380),
        ("Cầu Ninja","sncat",L(51),2,2350,250,3),("Cầu Ninja Trên","sncat",[51,52],2,2620,240,4),("Rừng Anh Đào","sfox",[51,52],5,3410,880),
        ("Hoa Tinh Linh","spixie",L(52),2,3600,260,5),("Đỉnh Hoa","spixie",L(52),2,3900,260,6),("Đồi Ninja","sncat",L(52),5,4610,580),
        ("Tháp Tinh Linh","spixie",L(52),2,4700,260,7)),
  [[500,480,760,480],[800,380,1060,380],[1350,400,1610,400],[2350,520,2600,520],[2620,420,2860,420],[3600,490,3860,490],[3900,380,4160,380],[4700,300,4960,300]],
  lad((740,480,600),(820,380,480),(1370,400,505),(2370,520,640),(2640,420,520),(3840,490,600),(3920,380,490),(4720,300,410)), [[2300,2900,612]]))
maps.append(arena("Đền Hồ Ly", "sakuracave", 19, 3200, 505, 52, 27, "ninetail", 54))
# 21 Rừng Nấm Phát Sáng
maps.append(base("Rừng Nấm Phát Sáng", "Cấp 52-55", "glow",
  [[0,600],[700,600],[700,505],[1300,505],[1300,600],[2000,600],[2000,505],[2300,505],[2300,410],[2900,410],[2900,600],[3500,600],[3500,690],[4000,690],[4000,600],[4800,600],[4800,505],[5800,505]],
  [{"x":0,"w":440,"name":"Cổng Anh Đào"},{"x":2490,"w":220,"name":"Hang Mẹ Nấm"}],
  [{"x":60,"y":600,"to":19,"tx":5580,"ty":600,"label":"Thung Lũng Anh Đào","lv":"Cấp 49-52"},
   {"x":2600,"y":410,"to":22,"tx":220,"ty":600,"label":"Hang Mẹ Nấm","lv":"Trùm · Cấp 55+","arena":1}],
  spots(("Bãi Nấm Lùn","ggnome",[52,53],3,450,240),("Mũ Nấm Đom Đóm","gfly",L(53),2,450,240,0),("Gò Ốc Sáng","gsnail",L(53),5,710,580),
        ("Ngọn Đom Đóm","gfly",[53,54],2,800,260,1),("Làng Nấm Lùn","ggnome",[53,54],5,1310,680),("Tán Đom Đóm","gfly",L(54),2,1450,260,2),
        ("Tán Nấm Cao","gfly",L(54),2,1740,260,3),("Bậc Ốc Sáng","gsnail",L(54),3,2010,280),("Đỉnh Nấm","ggnome",[54,55],2,2720,170),
        ("Thung Ốc Sáng","gsnail",[54,55],5,2910,580),("Nấm Đom Đóm","gfly",L(55),2,3050,260,4),("Hồ Đom Đóm","gfly",L(55),2,3550,250,5),
        ("Rừng Nấm Lùn","ggnome",L(55),4,4010,780),("Nấm Đêm","gfly",L(55),2,4200,260,6),("Đồi Ốc Sáng","gsnail",L(55),5,4810,900),
        ("Ngọn Nấm Cuối","gfly",L(55),2,5000,260,7)),
  [[450,480,690,480],[800,400,1060,400],[1450,480,1710,480],[1740,380,2000,380],[3050,490,3310,490],[3550,560,3800,560],[4200,480,4460,480],[5000,400,5260,400]],
  lad((670,480,600),(820,400,505),(1690,480,600),(1760,380,480),(3290,490,600),(3570,560,690),(4440,480,600),(5020,400,505)), [[3500,4000,650]]))
maps.append(arena("Hang Mẹ Nấm", "glowcave", 21, 2600, 410, 55, 30, "shroommom", 57))
for m in maps[15:]:
    for p in m["portals"]:
        if not p.get("label"): p["label"] = maps[p["to"]]["name"]
json.dump(D, open(P, 'w'), ensure_ascii=False, indent=1)
print('ok', len(maps))
