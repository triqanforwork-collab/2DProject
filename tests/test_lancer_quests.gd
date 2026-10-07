extends SceneTree


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	var progression = root.get_node("ProgressionManager")
	progression.reset_progression()

	# Old saves (no "lancer_quests") keep already-open regions open.
	var old_save: Dictionary = progression.get_save_data()
	old_save.erase("lancer_quests")
	progression.load_save_data(old_save)
	assert(progression.get_lancer_quest_state(&"water") == "done")
	progression.reset_progression()
	assert(progression.get_lancer_quest_state(&"water") == "")

	progression.get_node("/root/ProgressionManager").mark_story_seen(&"monk_welcome")
	var main = load("res://scenes/maps/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	var controller = get_first_node_in_group_safe("lancer_quest_controller")
	assert(controller != null and controller.get_spots().size() >= 6)

	# Water: one herb, picking it reaches the goal.
	controller.start_quest(&"water")
	await process_frame
	var items := _quest_items(controller)
	assert(items.size() == 1)
	items[0].interact(null)
	await process_frame
	assert(int(progression.get_lancer_quest(&"water")["progress"]) == 1)
	assert(_quest_items(controller).is_empty())

	# Earth: three ores, picked ones stay picked after a save/load.
	controller.start_quest(&"earth")
	await process_frame
	_quest_items(controller)[0].interact(null)
	await process_frame
	progression.load_save_data(progression.get_save_data())
	await process_frame
	assert(int(progression.get_lancer_quest(&"earth")["progress"]) == 1)
	assert(_quest_items(controller).size() == 2)

	# Quests run one at a time in real play (each gate needs the previous stone).
	progression.update_lancer_quest(&"earth", {"state": "done"})

	# Light: right order advances, wrong order resets; riddle has one line per pillar.
	controller.start_quest(&"light")
	await process_frame
	assert(controller.get_light_riddle().size() == 3)
	var order: Array = progression.get_lancer_quest(&"light")["spots"]
	_pillar_at(controller, int(order[0])).interact(null)
	await process_frame
	assert(int(progression.get_lancer_quest(&"light")["progress"]) == 1)
	_pillar_at(controller, int(order[2])).interact(null)
	await process_frame
	assert(int(progression.get_lancer_quest(&"light")["progress"]) == 0)

	progression.update_lancer_quest(&"light", {"state": "done"})

	# Air: catching the wisp counts and respawns it elsewhere.
	controller.start_quest(&"air")
	await process_frame
	var wisps := controller.get_children().filter(func(node): return node.has_signal("caught") and not node.is_queued_for_deletion())
	assert(wisps.size() == 1)
	wisps[0].caught.emit()
	await process_frame
	assert(int(progression.get_lancer_quest(&"air")["progress"]) == 1)

	print("Lancer quests test passed.")
	quit()


func get_first_node_in_group_safe(group: StringName) -> Node:
	return root.get_tree().get_first_node_in_group(group)


func _quest_items(controller: Node) -> Array:
	return controller.get_children().filter(func(node): return node.has_signal("activated") and not node.is_queued_for_deletion())


func _pillar_at(controller: Node, spot_index: int) -> Node:
	for item in _quest_items(controller):
		if item.spot_index == spot_index:
			return item
	return null
