extends "res://scripts/enemies/ranged_enemy.gd"


func _ready() -> void:
	shot_count = 3
	spread_degrees = 16.0
	super()
