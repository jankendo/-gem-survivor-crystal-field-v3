extends RefCounted
class_name TestContext
var assertions := 0
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
 assertions += 1
 if not condition: failures.append(message)
func equal(a, b, message: String) -> void: check(a == b, message + " expected=" + str(b) + " actual=" + str(a))
