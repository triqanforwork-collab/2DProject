extends "res://scripts/enemies/enemy.gd"

const SLOW_ZONE_SCRIPT := preload("res://scripts/enemies/slow_zone.gd")


func attack_player() -> void:
	if not is_instance_valid(player):
		return
	var zone := SLOW_ZONE_SCRIPT.new()
	get_tree().current_scene.add_child(zone)
	zone.global_position = player.global_position
	super()
