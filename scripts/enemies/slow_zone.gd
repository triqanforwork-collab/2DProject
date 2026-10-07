extends Area2D

var lifetime := 2.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 44.0
	shape_node.shape = circle
	add_child(shape_node)
	queue_redraw()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("apply_slow"):
			body.call("apply_slow", 0.55, 0.2)
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 44.0, Color(0.7, 0.75, 0.9, 0.16))
	draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 32, Color(0.8, 0.85, 1.0, 0.45), 2.0)
