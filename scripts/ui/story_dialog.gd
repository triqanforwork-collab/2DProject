# Typewriter story UI with two layouts:
# - play_pages(): full-screen story pages (image + text box), used for intro/ending.
# - play_speaker() / play_monk(): bottom dialogue box with a portrait (Monk, Lancers).
# Both lock the player while open and free themselves when finished.
class_name StoryDialog
extends CanvasLayer

signal finished

const CHARS_PER_SECOND := 45.0
const GOLD := Color(0.86, 0.7, 0.38)
const TEXT_COLOR := Color(0.95, 0.94, 0.9)
const BUTTON_COLOR := Color(0.47, 0.38, 0.24)
const IMAGE_BORDER_COLOR := Color(0.62, 0.95, 0.85)
const FIREFLY_COLOR := Color(0.85, 1.0, 0.55)
const FIREFLY_COUNT := 45
const MONK_PORTRAIT_SHEET := preload("res://assets/npc/Monk/Idle.png")

var pages: Array = []
var page_index := 0
var is_finished := false
var text_label: Label
var image_rect: TextureRect
var next_button: Button
var type_tween: Tween


static func play_pages(parent: Node, story_pages: Array) -> void:
	var dialog := StoryDialog.new()
	parent.add_child(dialog)
	dialog._build_story_layout()
	await dialog._run(story_pages)


static func play_monk(parent: Node, lines: Array) -> void:
	var portrait := AtlasTexture.new()
	portrait.atlas = MONK_PORTRAIT_SHEET
	portrait.region = Rect2(48, 40, 96, 96)
	await play_speaker(parent, "Monk", portrait, lines)


static func play_speaker(parent: Node, speaker: String, portrait: Texture2D, lines: Array) -> void:
	var dialog := StoryDialog.new()
	parent.add_child(dialog)
	dialog._build_speaker_layout(speaker, portrait)
	await dialog._run(lines)


# Soft round dot used by fireflies and quest item glows.
static func make_glow_texture() -> GradientTexture2D:
	var glow := GradientTexture2D.new()
	glow.width = 16
	glow.height = 16
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(0.5, 0.0)
	glow.gradient = Gradient.new()
	glow.gradient.set_color(0, Color.WHITE)
	glow.gradient.set_color(1, Color(1, 1, 1, 0))
	return glow


func _init() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS


func _run(story_pages: Array) -> void:
	if story_pages.is_empty():
		queue_free()
		return

	pages = story_pages
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("set_cinematic_locked"):
		player.set_cinematic_locked(true)

	_show_page(0)
	await finished

	if is_instance_valid(player) and player.has_method("set_cinematic_locked"):
		player.set_cinematic_locked(false)
	queue_free()


func _show_page(index: int) -> void:
	page_index = index
	var page = pages[index]
	var text := str(page.get("text", "")) if page is Dictionary else str(page)

	if image_rect != null and page is Dictionary:
		image_rect.texture = StoryData.load_story_image(str(page.get("image", "")))
		image_rect.modulate.a = 0.0
		create_tween().tween_property(image_rect, "modulate:a", 1.0, 0.35)

	text_label.text = text
	text_label.visible_ratio = 0.0
	if type_tween != null and type_tween.is_valid():
		type_tween.kill()
	type_tween = create_tween()
	type_tween.tween_property(text_label, "visible_ratio", 1.0, maxf(text.length() / CHARS_PER_SECOND, 0.1))
	next_button.text = "ĐÓNG" if index == pages.size() - 1 else "TIẾP"


func _advance() -> void:
	if is_finished:
		return
	if type_tween != null and type_tween.is_running():
		type_tween.kill()
		text_label.visible_ratio = 1.0
		return
	if page_index + 1 < pages.size():
		_show_page(page_index + 1)
	else:
		_finish()


func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _on_background_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		_advance()


func _build_story_layout() -> void:
	var background := ColorRect.new()
	background.color = Color(0.04, 0.04, 0.09)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.gui_input.connect(_on_background_input)
	add_child(background)
	_add_fireflies()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)

	# Glowing border frame; the inner panel clips the image to rounded corners.
	var frame := PanelContainer.new()
	var frame_style := _make_box_style(IMAGE_BORDER_COLOR, 0, 4)
	frame_style.set_corner_radius_all(16)
	frame_style.shadow_color = Color(IMAGE_BORDER_COLOR, 0.45)
	frame_style.shadow_size = 14
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(frame)

	var image_mask := PanelContainer.new()
	var mask_style := _make_box_style(Color(0.04, 0.04, 0.09), 0, 0)
	mask_style.set_corner_radius_all(12)
	image_mask.add_theme_stylebox_override("panel", mask_style)
	image_mask.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	image_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(image_mask)

	image_rect = TextureRect.new()
	image_rect.custom_minimum_size = Vector2(200, 200)
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_mask.add_child(image_rect)

	var panel := _make_text_panel(24)
	panel.custom_minimum_size = Vector2(780, 170)
	column.add_child(panel)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	_add_buttons(buttons, Vector2(240, 54))


# Soft glowing dots drifting over the dark background, fading in and out.
func _add_fireflies() -> void:
	var screen_size := get_viewport().get_visible_rect().size

	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])

	var fireflies := CPUParticles2D.new()
	fireflies.texture = make_glow_texture()
	fireflies.amount = FIREFLY_COUNT
	fireflies.lifetime = 7.0
	fireflies.preprocess = 7.0
	fireflies.position = screen_size * 0.5
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = screen_size * 0.5
	fireflies.direction = Vector2.UP
	fireflies.spread = 180.0
	fireflies.gravity = Vector2.ZERO
	fireflies.initial_velocity_min = 6.0
	fireflies.initial_velocity_max = 22.0
	fireflies.tangential_accel_min = -8.0
	fireflies.tangential_accel_max = 8.0
	fireflies.scale_amount_min = 0.6
	fireflies.scale_amount_max = 1.4
	fireflies.color = FIREFLY_COLOR
	fireflies.color_ramp = fade
	fireflies.hue_variation_min = -0.04
	fireflies.hue_variation_max = 0.04
	add_child(fireflies)


func _build_speaker_layout(speaker: String, portrait: Texture2D) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_background_input)
	add_child(dim)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _make_box_style(Color(0.1, 0.09, 0.08, 0.96), 3, 14))
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 16
	box.offset_right = -16
	box.offset_top = -200
	box.offset_bottom = -16
	box.gui_input.connect(_on_background_input)
	add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.add_theme_stylebox_override("panel", _make_box_style(Color(0.2, 0.18, 0.15), 2, 4))
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait_frame)

	var portrait_rect := TextureRect.new()
	portrait_rect.texture = portrait
	portrait_rect.custom_minimum_size = Vector2(130, 130)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait_rect)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	var name_label := Label.new()
	name_label.text = speaker
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 22)
	column.add_child(name_label)

	text_label = _make_text_label(22)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	_add_buttons(buttons, Vector2(150, 44))


func _make_text_panel(font_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.13, 0.12, 0.11, 0.97), 3, 22))
	panel.gui_input.connect(_on_background_input)
	text_label = _make_text_label(font_size)
	panel.add_child(text_label)
	return panel


func _make_text_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_buttons(container: HBoxContainer, button_size: Vector2) -> void:
	var skip_button := _make_button("BỎ QUA", button_size)
	skip_button.pressed.connect(_finish)
	container.add_child(skip_button)

	next_button = _make_button("TIẾP", button_size)
	next_button.pressed.connect(_advance)
	container.add_child(next_button)


func _make_button(text: String, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_stylebox_override("normal", _make_box_style(BUTTON_COLOR, 0, 0))
	button.add_theme_stylebox_override("hover", _make_box_style(BUTTON_COLOR.lightened(0.15), 0, 0))
	button.add_theme_stylebox_override("pressed", _make_box_style(BUTTON_COLOR.darkened(0.2), 0, 0))
	button.pressed.connect(AudioManager.play_sfx.bind(&"ui_click"))
	return button


func _make_box_style(color: Color, border: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(border)
	style.border_color = GOLD
	style.set_corner_radius_all(6)
	style.set_content_margin_all(padding)
	return style
