extends SceneTree


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	var boss = load("res://scenes/bosses/Water/Turtle.tscn").instantiate()
	root.add_child(boss)
	await physics_frame

	var started := Time.get_ticks_msec()
	boss.die()
	await boss.tree_exited
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	assert(elapsed >= 4.3 and elapsed <= 5.3, "Boss vanish should take ~4.7s, took (%.2fs)." % elapsed)

	print("Boss vanish test passed in %.2fs." % elapsed)
	quit()
