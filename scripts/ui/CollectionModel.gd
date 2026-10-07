extends RefCounted
class_name CollectionModel
const KINDS: Array[String]=["weapons","passives","evolutions","combos","characters","quests"]
const LABELS: Array[String]=["武器","パッシブ","進化","連携","キャラクター","クエスト"]
var db: GameDatabase
var entries: Array[Dictionary]=[]
var filtered: Array[int]=[]
var query:=""
var category:=0
var status:=0
var sorting:=0
var page:=0
const PAGE_SIZE:=8
func _init(database: GameDatabase) -> void:
 db=database
 for k in range(KINDS.size()):
  var kind:=KINDS[k]
  var definitions: Dictionary=db.table(kind)
  if kind=="combos":
   definitions={}
   for d in db.table("weapon_combo_attacks").get("combos",[]): definitions[d.id]=d
  for id in definitions:
   var d: Dictionary=definitions[id]
   var name:=str(d.get("name_ja",d.get("display_name_ja",id)))
   entries.append({"kind":kind,"id":str(id),"name":name,"definition":d,"search":(name+" "+str(d.get("description_ja",""))+" "+LABELS[k]+" "+str(d.get("tags",[]))+" "+str(d.get("category",""))).to_lower(),"owned":false,"ratio":0.0})
func update(save: Dictionary) -> void:
 var conditions:=ConditionSystem.new()
 for entry in entries:
  var id: String=entry.id
  var p: Dictionary=save.progression
  match entry.kind:
   "quests": entry.owned=p.quests.has(id); entry.ratio=1.0 if entry.owned else conditions.progress_ratio(save,entry.definition.condition)
   "evolutions": entry.owned=bool(p.get("evolved_weapons",{}).get(entry.definition.weapon,false))
   "combos": entry.owned=p.collection.has(entry.definition.weapon_a) and p.collection.has(entry.definition.weapon_b)
   _: entry.owned=p.unlocked.has(id) or bool(entry.definition.get("initial",false)) or ShopSystem.new().condition(entry.kind,id,db).get("type","")=="initial"
 filtered.clear()
 for i in range(entries.size()):
  var e:=entries[i]
  if category>0 and e.kind!=KINDS[category-1]: continue
  if status==1 and not e.owned: continue
  if status==2 and e.owned: continue
  if status==3 and (e.kind!="quests" or e.owned or e.ratio<=0): continue
  if not query.strip_edges().is_empty() and not e.search.contains(query.strip_edges().to_lower()): continue
  filtered.append(i)
 if sorting==1: filtered.sort_custom(func(a,b): return entries[a].name.naturalnocasecmp_to(entries[b].name)<0)
 elif sorting==2: filtered.sort_custom(func(a,b): return int(entries[a].owned)>int(entries[b].owned) if entries[a].owned!=entries[b].owned else a<b)
 elif sorting==3: filtered.sort_custom(func(a,b): return float(entries[a].ratio)>float(entries[b].ratio) if entries[a].ratio!=entries[b].ratio else a<b)
 page=clampi(page,0,maxi(0,(filtered.size()-1)/PAGE_SIZE))
