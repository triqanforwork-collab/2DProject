# A glowing world object the player uses with Interact (herb, ore, light pillar).
# LancerQuestController creates these and decides what activating one means.
class_name QuestItem
extends Area2D

signal activated(item: QuestItem)

var spot_index := -1
var glow_color := Color.WHITE
var sprite: Sprite2D
var glow: CPUParticles2D
var halo: Sprite2D


func setup(texture: Texture2D, color: Color, sprite_scale: float, index: int) -> QuestItem:
	spot_index = index
	glow_color = color
	collision_layer = 0
	collision_mask = 2

	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 42.0
	add_child(shape)

	# Pulsing ground halo so the item stands out from ordinary bushes and rocks.
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo = Sprite2D.new()
	halo.texture = StoryDialog.make_glow_texture()
	halo.material = additive
	halo.scale = Vector2(5.5, 3.2)
	halo.position.y = -6
	add_child(halo)
	var pulse := create_tween().set_loops()
	pulse.tween_property(halo, "scale", Vector2(6.5, 3.8), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(halo, "scale", Vector2(5.5, 3.2), 0.9).set_trans(Tween.TRANS_SINE)

	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.offset.y = -texture.get_height() * 0.35
	add_child(sprite)

	glow = CPUParticles2D.new()
	glow.texture = StoryDialog.make_glow_texture()
	glow.material = additive
	glow.amount = 20
	glow.lifetime = 1.8
	glow.position.y = -16
	glow.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	glow.emission_sphere_radius = 28.0
	glow.direction = Vector2.UP
	glow.spread = 35.0
	glow.gravity = Vector2(0, -10)
	glow.initial_velocity_min = 6.0
	glow.initial_velocity_max = 18.0
	glow.scale_amount_min = 0.8
	glow.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	glow.color_ramp = fade
	add_child(glow)
	set_lit(true)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	return self


# Lit items glow brightly; unlit ones (sleeping pillars) only shimmer faintly.
func set_lit(lit: bool) -> void:
	glow.color = glow_color if lit else Color(glow_color, 0.4)
	glow.amount = 20 if lit else 8
	halo.modulate = Color(glow_color, 0.55 if lit else 0.2)
	sprite.modulate = Color(1.35, 1.35, 1.2) if lit else Color.WHITE


func interact(_player: Node) -> void:
	activated.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
