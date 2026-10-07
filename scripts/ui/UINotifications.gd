extends RefCounted
class_name UINotifications
const CAPACITY := 4
var entries: Array = []
func add(key: String,text: String,priority: int = 1,now_ms: int = -1) -> void:
 if now_ms<0: now_ms=Time.get_ticks_msec()
 for entry in entries:
  if entry.key==key:
   entry.text=text
   entry.until=now_ms+5000
   return
 if entries.size()>=CAPACITY:
  var weakest := 0
  for i in range(entries.size()):
   if entries[i].priority<entries[weakest].priority: weakest=i
  if entries[weakest].priority>priority: return
  entries.remove_at(weakest)
 entries.append({"key":key,"text":text,"priority":priority,"until":now_ms+5000})
func current(now_ms: int = -1) -> String:
 if now_ms<0: now_ms=Time.get_ticks_msec()
 var best := -1
 for i in range(entries.size()-1,-1,-1):
  if entries[i].until<=now_ms: entries.remove_at(i)
 for i in range(entries.size()):
  if best<0 or entries[i].priority>entries[best].priority: best=i
 return "" if best<0 else str(entries[best].text)
