extends SceneTree
var scene
func _initialize() -> void:
 scene = load("res://scenes/Main.tscn").instantiate()
 root.add_child(scene)
 call_deferred("verify")
func verify() -> void:
 if not scene.db.errors.is_empty():
  push_error("Exported database validation failed")
  quit(1)
  return
 if ResourceLoader.exists("res://tests/test_runner.gd"):
  push_error("Tests leaked into exported pack")
  quit(1)
  return
 print("PACK_MAIN_AND_DATABASE_PASS")
 call_deferred("finish")
func finish() -> void:
 quit()
