extends RefCounted
class_name RunRng

var rng := RandomNumberGenerator.new()
var run_seed: int = 1

func set_seed_value(value: int) -> void:
	run_seed = value
	rng.seed = value

func stream_seed(stream_name: String, salt = "") -> int:
	var text := "%d:%s:%s" % [run_seed, stream_name, str(salt)]
	var value := 2166136261
	for i in range(text.length()):
		value = int((value ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
	if value == 0:
		value = 1
	return value

func stream_rng(stream_name: String, salt = ""):
	var child := RunRng.new()
	child.set_seed_value(stream_seed(stream_name, salt))
	return child

func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		return 0
	return rng.randi_range(0, max_exclusive - 1)

func range_int(min_value: int, max_value: int) -> int:
	if max_value <= min_value:
		return min_value
	return rng.randi_range(min_value, max_value)

func range_float(min_value: float, max_value: float) -> float:
	if max_value <= min_value:
		return min_value
	return rng.randf_range(min_value, max_value)

func chance(probability: float) -> bool:
	return rng.randf() < probability

func choice(items: Array):
	if items.is_empty():
		return null
	return items[next_int(items.size())]

func shuffled(items: Array) -> Array:
	var result = items.duplicate(true)
	for index in range(result.size() - 1, 0, -1):
		var swap_index = range_int(0, index)
		var value = result[index]
		result[index] = result[swap_index]
		result[swap_index] = value
	return result

func weighted_choice(weighted_items: Array) -> Dictionary:
	var total := 0.0
	for item in weighted_items:
		total += float(item.get("weight", 0.0))
	if total <= 0.0:
		return {}
	var roll := rng.randf() * total
	var cursor := 0.0
	for item in weighted_items:
		cursor += float(item.get("weight", 0.0))
		if roll <= cursor:
			return item
	return weighted_items.back()

func snapshot() -> Dictionary:
	return {
		"run_seed": run_seed,
		"state": rng.state
	}

func restore(data: Dictionary) -> void:
	run_seed = int(data.get("run_seed", 1))
	rng.seed = run_seed
	if data.has("state"):
		rng.state = int(data["state"])
