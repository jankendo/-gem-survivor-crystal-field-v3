extends RefCounted
class_name UIStrings
var db: GameDatabase
const CATEGORIES: Dictionary={"ranged":"遠距離","area":"範囲","melee":"近接","deploy":"設置","poison":"毒","knockback":"押し出し","explosion":"爆発","summon":"召喚","crystal":"結晶","gem":"Gem回収","laser":"光線","lightning":"雷","":""}
func _init(database: GameDatabase) -> void: db=database
func category(id: String) -> String:
 return CATEGORIES.get(id,"特殊")
func name(kind: String,id: String) -> String:
 var d=db.table(kind).get(id,{})
 if not d is Dictionary: return "未登録"
 return str(d.get("name_ja",d.get("display_name_ja","未登録")))
func number(value) -> String:
 if value is float or value is int: return str(int(value)) if is_equal_approx(float(value),roundf(float(value))) else String.num(float(value),2)
 return str(value)
func condition(c: Dictionary) -> String:
 var type := str(c.get("type",""))
 var value := number(c.get("value",c.get("count",c.get("seconds",c.get("cost",1)))))
 var terrain: String = {"star_plain":"星原","mine_chamber":"鉱床部屋","danger_den":"危険巣","crystal_corridor":"結晶廊下","relic_vault":"遺物庫","safe_room":"安全な部屋"}.get(c.get("terrain",""),"指定の地形")
 match type:
  "initial": return "初期解放"
  "currency_sink": return "購入で永久解放"
  "currency": return "クリスタル貨 "+value+"以上を所持"
  "weapon_level": return name("weapons",str(c.get("weapon","")))+"をLv"+number(c.get("level",1))+"に成長"
  "weapon_kills": return name("weapons",str(c.get("weapon","")))+"で"+value+"体撃破"
  "boss_defeat": return name("bosses",str(c.get("boss","")))+"を撃破"
  "evolved_weapon": return name("weapons",str(c.get("weapon","")))+"を進化"
  "character_unlocked": return name("characters",str(c.get("character","")))+"を解放"
  "terrain_time": return str(terrain)+"で累計"+value+"秒生存"
  "terrain_kills": return str(terrain)+"で累計"+value+"体撃破"
  "terrain_crystals": return str(terrain)+"で結晶を"+value+"個破壊"
  "terrain_boss_defeat": return str(terrain)+"でボスを撃破"
  "gimmick_count": return name("field_gimmicks",str(c.get("gimmick","")))+"を"+value+"回利用"
  "field_drop_count": return "指定のコアを"+value+"個回収"
  "exploration_rank": return "探索ランク"+str(c.get("rank",c.get("value","A")))+"以上を達成"
  "secret_ghost": return "遺物庫を探索し、瀕死の状態を生き延びる"
  "secret_reaper": return "高難度のボスを撃破"
  "secret_collector": return "Gemを続けて回収し、吸収コンボを達成"
  "secret_void_mapper": return "1ランで12部屋以上を探索し、探索ランクS以上"
  "secret_abyss_merchant": return "累計25000貨とルーン契約20回を達成"
  "specific_title": return "指定の称号を取得"
 var labels := {"survive_seconds":"生存時間（秒）","survive_runs":"生存ラン数","total_kills":"累計撃破数","total_crystals":"累計結晶破壊","total_rooms":"累計探索部屋","rooms_discovered":"累計探索部屋","rooms_in_run":"1ランの探索部屋","total_contracts":"ルーン契約数","exploration_chain":"探索チェーン","max_combo":"吸収コンボ","cursed_relics":"呪いの遺物","shortcut_walls":"近道壁の破壊","cursed_walls":"結晶破壊","currency_paid":"累計獲得貨","danger_time":"危険巣の滞在（秒）"}
 return str(labels.get(type,"達成条件"))+": "+value
func damage_name(source: String) -> String:
 if source.begins_with("weapon:"): return name("weapons",source.get_slice(":",1))
 if source.begins_with("combo:"):
  for d in db.table("weapon_combo_attacks").get("combos",[]):
   if d.id==source.get_slice(":",1): return str(d.display_name_ja)+"（連携）"
 return {"enemy":"敵との接触","boss":"ボスの攻撃","boss:contact":"ボスとの接触","boss:telegraph":"ボスの予告攻撃","self:overclock":"技拡張の反動","field:mining":"結晶採掘","field:lightning":"雷導結晶","field:meteor":"流星の予告攻撃","field:gem":"Gem回収の効果","field:explosion":"結晶の爆発","field:reflect":"結晶の反射弾","status:poison":"毒状態"}.get(source,"その他のダメージ")
