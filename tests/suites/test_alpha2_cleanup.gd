extends RefCounted
func tags() -> Array: return ["unit","UI","release","performance"]
func run(t: TestContext,tree: SceneTree) -> void:
 var initial_nodes:=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 for cycle in range(6):
  var app=load("res://scenes/Main.tscn").instantiate()
  app.save_path="user://qa_cleanup.save"
  tree.root.add_child(app)
  app.set_physics_process(false); app.set_process(false)
  app.start_run("noah","attack",600+cycle)
  app.controller.show_equipment(); app.controller.progression.slot(0);app.controller.back()
  app.controller.end_run();app.controller.home()
  t.check(app.run==null and app.controller.feedback.previous_run==null,"run references released cycle"+str(cycle))
  app.controller.show_collection();app.controller.collection.open_detail(0);app.controller.back()
  app.queue_free()
  for frame in range(8): await tree.process_frame
  t.equal(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),initial_nodes,"all scene nodes cleaned cycle"+str(cycle))
