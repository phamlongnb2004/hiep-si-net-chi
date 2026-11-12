import json
import os
P=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','shared','data.json')
D=json.load(open(P))
M=D['mons']
M['bmonkey']={"n":"Khỉ Trúc","kind":"bmonkey","hp":0,"atk":0,"def":0,"exp":0,"gold":[22,40],"aggro":240,"cd":1.2,"drop":0.3,"boss":False,"r":30,"h":82,"range":50,"spd":115,"afx":"dust_feather"}
M['bpanda']={"n":"Gấu Trúc Chiến","kind":"bpanda","hp":0,"atk":0,"def":0,"exp":0,"gold":[26,46],"aggro":230,"cd":1.7,"drop":0.3,"boss":False,"r":40,"h":100,"range":62,"spd":70,"afx":"bamboo_smash","ab":{"k":"sweep","n":3,"r":150,"m":1.5}}
M['bviper']={"n":"Rắn Lục Trúc","kind":"bviper","hp":0,"atk":0,"def":0,"exp":0,"gold":[24,44],"aggro":240,"cd":1.4,"drop":0.3,"boss":False,"r":30,"h":60,"range":50,"spd":95,"afx":"poison_splash","ab":{"k":"spit","cd":3.2,"min":110,"max":400,"sp":330,"m":0.8,"pois":[3,0.12]}}
M['pandaking']={"n":"Vương Gấu Trúc","kind":"pandaking","hp":3300,"atk":40,"def":25,"exp":5200,"gold":[460,660],"aggro":520,"cd":1.8,"drop":1,"boss":True,"r":72,"h":228,"range":115,"spd":80,
 "sk":[{"k":"slam","n":"Đập Gậy Trúc","a":"s1","wind":0.9,"len":330,"m":1.7,"kb":240,"fx":"bamboo_smash"},
       {"k":"spin","n":"Lăn Tròn","a":"s2","wind":0.6,"t":1.3,"spd":500,"r":85,"m":0.7,"every":0.3,"fx":"bamboo_roll"},
       {"k":"spikes","n":"Trúc Mọc Ngầm","a":"s3","wind":1.0,"len":460,"m":1.6,"stun":1.2,"fx":"bamboo_spikes"}],
 "skcd":[4.5,6.5],"afx":"bamboo_smash"}
maps=D['maps']
assert len(maps) in (13,15)
del maps[13:]
m4=maps[4]
m4['safes']=[s for s in m4['safes'] if s['name']!='Cổng Rừng Trúc']+[{"x":5040,"w":360,"name":"Cổng Rừng Trúc"}]
m4['portals']=[p for p in m4['portals'] if p['to']!=13]+[{"x":5340,"y":600,"to":13,"tx":220,"ty":600,"label":"Rừng Trúc Mây","lv":"Cấp 40-43"}]
for s in m4['spots']:
    if s['n']=='Hang Cá Sấu': s['w']=300
maps.append({"name":"Rừng Trúc Mây","lv":"Cấp 40-43","w":5600,"h":720,"theme":"bamboo","village":False,"spawn":{"x":220,"y":600},
 "safes":[{"x":0,"w":440,"name":"Cổng Đầm Lầy"},{"x":2650,"w":220,"name":"Hang Vương Gấu Trúc"}],
 "npcs":[],"houses":[],"fountain":None,
 "terr":[[0,600],[1400,600],[1400,505],[1700,505],[1700,410],[2300,410],[2300,600],[2600,600],[2600,505],[2900,505],[2900,600],[2950,600],[2950,640],[3500,640],[3500,600],[4300,600],[4300,505],[4650,505],[4650,410],[5000,410],[5000,600],[5600,600]],
 "portals":[{"x":60,"y":600,"to":4,"tx":5180,"ty":600,"label":"Đầm Lầy Sương Độc","lv":"Cấp 30-40"},
            {"x":2760,"y":505,"to":14,"tx":220,"ty":600,"label":"Hang Vương Gấu Trúc","lv":"Trùm · Cấp 43+","arena":1}],
 "spots":[{"n":"Rặng Khỉ Trúc","mon":"bmonkey","lv":[40,41],"cnt":6,"x":450,"w":900},
          {"n":"Ngọn Trúc Khỉ","mon":"bmonkey","lv":[41,41],"cnt":2,"x":900,"w":260,"p":0},
          {"n":"Đỉnh Trúc","mon":"bmonkey","lv":[41,42],"cnt":2,"x":1180,"w":240,"p":1},
          {"n":"Đồi Gấu Trúc","mon":"bpanda","lv":[41,42],"cnt":5,"x":1710,"w":580},
          {"n":"Bến Trúc","mon":"bpanda","lv":[42,42],"cnt":2,"x":2310,"w":280},
          {"n":"Bè Trúc","mon":"bviper","lv":[42,42],"cnt":2,"x":3000,"w":250,"p":2},
          {"n":"Bè Trúc Trên","mon":"bviper","lv":[42,43],"cnt":2,"x":3270,"w":230,"p":3},
          {"n":"Lùm Rắn Lục","mon":"bviper","lv":[42,43],"cnt":5,"x":3520,"w":760},
          {"n":"Tháp Rắn","mon":"bviper","lv":[43,43],"cnt":2,"x":3980,"w":260,"p":5},
          {"n":"Sườn Gấu Trúc","mon":"bpanda","lv":[42,43],"cnt":5,"x":4310,"w":650},
          {"n":"Chòi Khỉ","mon":"bmonkey","lv":[43,43],"cnt":2,"x":4700,"w":280,"p":6},
          {"n":"Cuối Rừng Khỉ","mon":"bmonkey","lv":[42,43],"cnt":4,"x":5010,"w":480}],
 "plats":[[900,490,1160,490],[1180,380,1420,380],[3000,520,3250,520],[3270,420,3500,420],[3700,490,3960,490],[3980,380,4240,380],[4700,300,4980,300]],
 "ropes":[[1140,490,600,"ladder"],[1210,380,490,"ladder"],[3030,520,640,"ladder"],[3300,420,520,"ladder"],[3730,490,600,"ladder"],[4010,380,490,"ladder"],[4730,300,410,"ladder"]],
 "water":[[2950,3500,612]],"lava":[]})
maps.append({"name":"Hang Vương Gấu Trúc","lv":"Khu trùm","w":2000,"h":720,"theme":"bamboocave","village":False,"spawn":{"x":220,"y":600},
 "safes":[{"x":0,"w":420,"name":"Lối ra"}],"npcs":[],"houses":[],"fountain":None,
 "terr":[[0,600],[2000,600]],
 "portals":[{"x":60,"y":600,"to":13,"tx":2760,"ty":505,"label":"Rừng Trúc Mây","lv":"Ra khỏi khu trùm"}],
 "arena":{"from":13,"gx":2760,"req":43,"ofs":18},
 "spots":[{"n":"Vương Gấu Trúc","mon":"pandaking","lv":[45,45],"cnt":1,"x":850,"w":700}],
 "plats":[[560,490,820,490],[1400,490,1660,490]],"ropes":[],"water":[],"lava":[]})
json.dump(D,open(P,'w'),ensure_ascii=False,indent=1)
print('ok',len(maps))
