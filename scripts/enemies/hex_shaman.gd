extends "res://scripts/enemies/ranged_enemy.gd"

var shield_cooldown := 2.0


func _physics_process(delta: float) -> void:
	super(delta)
	if is_dead:
		return
	shield_cooldown -= delta
	if shield_cooldown <= 0.0:
		shield_cooldown = 8.0
		shield_nearest_ally()


func shield_nearest_ally() -> void:
	var nearest: Node2D
	var nearest_distance := 240.0
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if candidate == self or not candidate is Node2D or not candidate.has_method("grant_shield"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if nearest != null:
		nearest.call("grant_shield")
		AudioManager.play_sfx(&"magic_cast", 1.15, -5.0)
