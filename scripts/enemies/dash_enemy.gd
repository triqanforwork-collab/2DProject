extends "res://scripts/enemies/enemy.gd"

@export var dash_speed := 360.0
@export var dash_duration := 0.28
@export var windup_duration := 0.4
@export var recovery_duration := 0.65

var dash_direction := Vector2.ZERO
var dash_left := 0.0
var preparing := false
var dash_has_hit := false
var warning_line: Line2D


func _physics_process(delta: float) -> void:
	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_direction * dash_speed
		move_and_slide()
		if not dash_has_hit and is_instance_valid(player) and global_position.distance_to(player.global_position) < 38.0:
			player.take_damage(attack_damage, global_position)
			dash_has_hit = true
		if dash_left <= 0.0:
			velocity = Vector2.ZERO
			attack_cooldown_left = maxf(attack_cooldown_left, recovery_duration)
		return
	if preparing:
		velocity = Vector2.ZERO
		return
	super(delta)


func attack_player() -> void:
	if preparing or dash_left > 0.0 or not is_instance_valid(player):
		return
	preparing = true
	dash_direction = global_position.direction_to(player.global_position)
	attack_cooldown_left = attack_cooldown
	play_attack_animation()
	show_warning()
	await get_tree().create_timer(windup_duration).timeout
	if is_dead:
		return
	preparing = false
	dash_has_hit = false
	dash_left = dash_duration
	if is_instance_valid(warning_line):
		warning_line.queue_free()


func show_warning() -> void:
	warning_line = Line2D.new()
	warning_line.width = 4.0
	warning_line.default_color = Color(1.0, 0.25, 0.15, 0.65)
	warning_line.points = PackedVector2Array([Vector2.ZERO, dash_direction * dash_speed * dash_duration])
	add_child(warning_line)
