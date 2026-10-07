# Air quest wind spirit: floats in place, gets startled when the player comes
# close, then flies to another quest spot. Touching it counts as a catch.
class_name QuestWisp
extends Area2D

signal caught

const COLOR := Color(0.6, 0.95, 1.0)
const STARTLE_RADIUS := 140.0
const STARTLE_TIME := 0.5 # window in which a dash can still reach it
const FLY_SPEED := 240.0 # faster than walking (200), slower than dashing

var spots: Array[Vector2] = []
var player: Node2D
var is_moving := false
var startled_time := 0.0
var core: Sprite2D


func setup(flee_spots: Array[Vector2]) -> QuestWisp:
	spots = flee_spots
	collision_layer = 0
	collision_mask = 2

	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 26.0
	add_child(shape)

	core = Sprite2D.new()
	core.texture = StoryDialog.make_glow_texture()
	core.scale = Vector2(3.2, 3.2)
	core.modulate = Color(COLOR, 0.95)
	core.position.y = -24
	add_child(core)

	var trail := CPUParticles2D.new()
	trail.texture = core.texture
	trail.amount = 24
	trail.lifetime = 0.9
	trail.position.y = -24
	trail.local_coords = false
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 10.0
	trail.spread = 180.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 10.0
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = 0.4
	trail.scale_amount_max = 1.0
	trail.color = COLOR
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	trail.color_ramp = fade
	add_child(trail)

	body_entered.connect(_on_body_entered)
	return self


func _process(delta: float) -> void:
	core.position.y = -24 + sin(Time.get_ticks_msec() / 250.0) * 5.0
	if is_moving:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return

	if global_position.distance_to(player.global_position) > STARTLE_RADIUS:
		startled_time = 0.0
		return
	startled_time += delta
	if startled_time >= STARTLE_TIME:
		_fly_away()


func _fly_away() -> void:
	var target := _pick_flee_spot()
	is_moving = true
	startled_time = 0.0
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, global_position.distance_to(target) / FLY_SPEED)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	is_moving = false


# A spot far enough from the player to be a chase, but not across the whole island.
func _pick_flee_spot() -> Vector2:
	var candidates := spots.filter(func(spot: Vector2) -> bool:
		var distance := global_position.distance_to(spot)
		return distance > 250.0 and distance < 700.0 and spot.distance_to(player.global_position) > STARTLE_RADIUS
	)
	if candidates.is_empty():
		candidates = spots.filter(func(spot: Vector2) -> bool: return spot.distance_to(player.global_position) > 250.0)
	return candidates.pick_random() if not candidates.is_empty() else global_position


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		caught.emit()
