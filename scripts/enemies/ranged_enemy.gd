extends "res://scripts/enemies/enemy.gd"

const PROJECTILE_SCRIPT := preload("res://scripts/enemies/enemy_projectile.gd")

@export var preferred_range := 190.0
@export var retreat_range := 105.0
@export var projectile_speed := 260.0
@export var projectile_texture: Texture2D
@export var projectile_hframes := 1
@export var projectile_tint := Color.WHITE
@export var projectile_texture_rotation := 0.0
@export var shot_count := 1
@export var spread_degrees := 12.0

var strafe_sign := 1.0


func update_attack_hitbox_state() -> void:
	can_attack_player = (
		is_instance_valid(player)
		and global_position.distance_to(player.global_position) <= attack_range
		and has_line_of_sight()
	)


func has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func chase_player(direction: Vector2) -> void:
	var distance := global_position.distance_to(player.global_position)
	if distance < retreat_range:
		direction = player.global_position.direction_to(global_position)
	elif distance <= preferred_range:
		direction = direction.orthogonal() * strafe_sign
		if randf() < 0.01:
			strafe_sign *= -1.0
	else:
		super(direction)
		return
	direction = (direction + get_separation_direction() * 0.45).normalized()
	velocity = direction * speed
	play_animation(move_animation)
	move_and_slide()
	update_sprite_direction(direction)


func attack_player() -> void:
	if is_dead or not is_instance_valid(player):
		return
	var base_direction := global_position.direction_to(player.global_position + player.velocity * 0.18)
	for index in shot_count:
		var centered := float(index) - float(shot_count - 1) * 0.5
		spawn_projectile(base_direction.rotated(deg_to_rad(spread_degrees * centered)))
	play_attack_animation()
	AudioManager.play_sfx(&"enemy_attack", randf_range(0.92, 1.08), -4.0)
	attack_cooldown_left = attack_cooldown


func spawn_projectile(direction: Vector2) -> void:
	var projectile := PROJECTILE_SCRIPT.new()
	get_tree().current_scene.add_child(projectile)
	projectile.setup(global_position, direction, attack_damage, projectile_texture, projectile_hframes, projectile_speed, projectile_tint, projectile_texture_rotation)
