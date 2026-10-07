extends "res://scripts/enemies/enemy.gd"

const PROJECTILE_SCRIPT := preload("res://scripts/enemies/enemy_projectile.gd")


func attack_player() -> void:
	if not is_instance_valid(player):
		return
	super()
	var direction := global_position.direction_to(player.global_position)
	for angle in [-18.0, 0.0, 18.0]:
		var flame := PROJECTILE_SCRIPT.new()
		get_tree().current_scene.add_child(flame)
		flame.setup(global_position, direction.rotated(deg_to_rad(angle)), attack_damage, null, 1, 190.0, Color(1.0, 0.45, 0.1))
		flame.lifetime = 0.38
