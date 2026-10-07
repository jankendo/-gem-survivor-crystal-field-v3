extends RefCounted
class_name UIActionGate
# Presentation-time guard; never consulted by simulation or RNG.
var last: Dictionary = {}
func allow(key: String, now_ms: int = -1, delay_ms: int = 300) -> bool:
 if now_ms < 0: now_ms = Time.get_ticks_msec()
 if last.has(key) and now_ms-int(last[key]) < delay_ms: return false
 last[key] = now_ms
 return true
