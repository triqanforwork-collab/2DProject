extends Area2D

var direction := Vector2.RIGHT
var speed := 260.0
var damage := 1
var lifetime := 4.0
var frame_time := 0.0
var sprite: Sprite2D
var projectile_color := Color(0.55, 0.9, 1.0, 0.9)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 35
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(origin: Vector2, aim_direction: Vector2, hit_damage: int, texture: Texture2D = null, hframes := 1, projectile_speed := 260.0, tint := Color.WHITE, texture_rotation := 0.0) -> void:
	global_position = origin
	direction = aim_direction.normalized()
	damage = hit_damage
	speed = projectile_speed
	projectile_color = tint
	rotation = direction.angle()
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = maxi(hframes, 1)
	sprite.modulate = tint
	sprite.rotation = texture_rotation
	sprite.scale = Vector2.ONE * (0.75 if texture != null else 1.0)
	add_child(sprite)
	if texture == null:
		sprite.queue_free()
		sprite = null
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	frame_time += delta
	if sprite != null and sprite.hframes > 1 and frame_time >= 0.08:
		frame_time = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	if sprite == null:
		draw_circle(Vector2.ZERO, 9.0, projectile_color)
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)


func _on_body_entered(body: Node) -> void:
	_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_hit(area.get_parent())


func _hit(target: Node) -> void:
	if target != null and target.is_in_group("player") and target.has_method("take_damage"):
		target.call("take_damage", damage, global_position)
	queue_free()
