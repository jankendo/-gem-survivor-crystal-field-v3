#!/usr/bin/env python3
import json,pathlib,sys,math
root=pathlib.Path(__file__).resolve().parents[1]
errors=[]
def unique(pairs):
 d={}
 for k,v in pairs:
  if k in d: errors.append('duplicate JSON ID: '+k)
  d[k]=v
 return d
def walk(v,path):
 if isinstance(v,dict):
  for k,x in v.items():
   if isinstance(x,(int,float)) and not isinstance(x,bool):
    if not math.isfinite(x): errors.append(path+'.'+k+' non-finite')
    if (k.endswith('_probability') or k.endswith('_chance')) and not 0<=x<=1: errors.append(path+'.'+k+' probability')
   if isinstance(x,str) and x.startswith('res://assets/') and not (root/x[6:]).is_file(): errors.append(path+'.'+k+' missing '+x)
   walk(x,path+'.'+k)
 elif isinstance(v,list):
  for i,x in enumerate(v): walk(x,path+f'[{i}]')
tables={}
for p in (root/'data').glob('*.json'):
 try: tables[p.stem]=json.loads(p.read_text(encoding="utf-8"),object_pairs_hook=unique)
 except Exception as e: errors.append(str(p)+': '+str(e))
for k,v in tables.items(): walk(v,k)
for id,d in tables['evolutions'].items():
 for k,table in [('weapon','weapons'),('passive','passives')]:
  if d[k] not in tables[table]: errors.append(id+' invalid '+k)
for d in tables['weapon_combo_attacks']['combos']:
 for k in ['weapon_a','weapon_b']:
  if d[k] not in tables['weapons']: errors.append(d['id']+' invalid '+k)
for id,d in tables['v3_weapons'].items():
 if id not in tables['weapons'] or d['cooldown']<=0 or d['damage']<0 or d['targets']<1: errors.append(id+' invalid runtime')
for evolution,variants in tables["overclocks"].items():
 for variant in variants:
  if variant["id"] not in tables["v3_overclocks"]: errors.append("missing overclock "+variant["id"])
print(json.dumps({'ok':not errors,'tables':len(tables),'errors':errors},ensure_ascii=False))
sys.exit(bool(errors))
