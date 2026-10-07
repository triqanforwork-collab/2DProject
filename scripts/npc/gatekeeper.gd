extends CharacterBody2D

@export var gate_enabled := false
@export_enum("water", "earth", "light", "air", "life") var region_id := "water"
@export_multiline var dialog_message := "Bạn có muốn di chuyển đến Region này không?"
@export_file("*.tscn") var target_scene_path := ""

const PORTRAIT_OFFSET := Vector2(96, 80)
const PORTRAIT_SIZE := Vector2(128, 128)

@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var interaction_in_progress := false
var quest_marker: Label


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

	if gate_enabled and not ResourceLoader.exists(target_scene_path):
		push_error("Gatekeeper target scene does not exist: %s" % target_scene_path)

	_create_quest_marker()
	ProgressionManager.lancer_quest_changed.connect(_update_quest_marker.unbind(1))
	ProgressionManager.region_unlocked.connect(_update_quest_marker.unbind(1))
	ProgressionManager.progression_reset.connect(_update_quest_marker)
	_update_quest_marker()


func interact(_player: Node) -> void:
	if not gate_enabled or interaction_in_progress:
		return

	var dialog := get_tree().get_first_node_in_group("confirmation_dialog")
	if dialog == null:
		push_error("Gatekeeper could not find the shared confirmation dialog.")
		return

	if not ProgressionManager.is_region_unlocked(StringName(region_id)):
		var locked_callback := Callable(self, "_on_locked_dialog_closed")
		dialog.connect("option_selected", locked_callback, CONNECT_ONE_SHOT)
		var locked_opened := bool(dialog.call(
			"open_dialog",
			"Cổng %s Region chưa mở. Hãy kích hoạt Viên Đá Năng Lượng trước đó." % region_id.capitalize(),
			"Đã hiểu",
			"Đóng"
		))
		if not locked_opened:
			if dialog.is_connected("option_selected", locked_callback):
				dialog.disconnect("option_selected", locked_callback)
			return
		interaction_in_progress = true
		return

	interaction_in_progress = true
	var quest_handled := await _handle_quest()
	interaction_in_progress = false
	if quest_handled:
		return

	var callback := Callable(self, "_on_dialog_choice_made")
	dialog.connect("choice_made", callback, CONNECT_ONE_SHOT)
	var opened := bool(dialog.call("open_dialog", dialog_message))
	if not opened:
		if dialog.is_connected("choice_made", callback):
			dialog.disconnect("choice_made", callback)
		return

	interaction_in_progress = true


func _on_dialog_choice_made(accepted: bool) -> void:
	interaction_in_progress = false
	if accepted:
		SceneLoader.change_scene(target_scene_path)


func _on_locked_dialog_closed(_option_index: int) -> void:
	interaction_in_progress = false


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not gate_enabled or not body.is_in_group("player"):
		return

	if body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)

# Runs this guardian's quest conversation. Returns true when it replaces the
# travel dialog (quest offered, still in progress, or a Life blessing given).
func _handle_quest() -> bool:
	var region := StringName(region_id)
	var life_quest := ProgressionManager.get_lancer_quest(&"life")
	var visited: Array = life_quest.get("visited", [])
	if region != &"life" and str(life_quest.get("state", "")) == "active" and region_id not in visited:
		visited = visited.duplicate()
		visited.append(region_id)
		ProgressionManager.update_lancer_quest(&"life", {"visited": visited, "progress": visited.size()})
		await _say([StoryData.LIFE_BLESSINGS[region]])
		return true

	var quest_data: Dictionary = StoryData.LANCER_QUESTS[region]
	var quest := ProgressionManager.get_lancer_quest(region)
	match str(quest.get("state", "")):
		"":
			var controller := get_tree().get_first_node_in_group("lancer_quest_controller")
			if controller == null:
				return false # No quest support in this scene; keep the gate usable.
			controller.start_quest(region)
			await _say(quest_data["offer"] + _get_extra_lines(region))
			return true
		"active":
			if int(quest.get("progress", 0)) >= int(quest_data["goal"]):
				ProgressionManager.update_lancer_quest(region, {"state": "done"})
				await _say(quest_data["complete"])
				return false
			await _say(quest_data["reminder"] + _get_extra_lines(region))
			return true
	return false


func _get_extra_lines(region: StringName) -> Array:
	var controller := get_tree().get_first_node_in_group("lancer_quest_controller")
	if region == &"light" and controller != null:
		return controller.get_light_riddle()
	return []


func _say(lines: Array) -> void:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0) as AtlasTexture
	var portrait := AtlasTexture.new()
	portrait.atlas = frame.atlas
	portrait.region = Rect2(frame.region.position + PORTRAIT_OFFSET, PORTRAIT_SIZE)
	await StoryDialog.play_speaker(self, name_label.text, portrait, lines)


# Floating "!" (quest or blessing to give) / "?" (quest ready to hand in) above the head.
func _create_quest_marker() -> void:
	quest_marker = Label.new()
	quest_marker.size = Vector2(60, 60)
	quest_marker.position = Vector2(-26, -118)
	quest_marker.z_index = 20
	quest_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_marker.add_theme_font_size_override("font_size", 46)
	quest_marker.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	quest_marker.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0))
	quest_marker.add_theme_constant_override("outline_size", 12)
	add_child(quest_marker)
	var bob := quest_marker.create_tween().set_loops()
	bob.tween_property(quest_marker, "position:y", -128.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(quest_marker, "position:y", -118.0, 0.5).set_trans(Tween.TRANS_SINE)


func _update_quest_marker() -> void:
	quest_marker.text = _get_quest_marker_text()
	quest_marker.visible = not quest_marker.text.is_empty()


func _get_quest_marker_text() -> String:
	var region := StringName(region_id)
	if not gate_enabled or not ProgressionManager.is_region_unlocked(region):
		return ""
	var life_quest := ProgressionManager.get_lancer_quest(&"life")
	if region != &"life" and str(life_quest.get("state", "")) == "active" and region_id not in life_quest.get("visited", []):
		return "!"
	var quest := ProgressionManager.get_lancer_quest(region)
	match str(quest.get("state", "")):
		"":
			return "!"
		"active":
			return "?" if int(quest.get("progress", 0)) >= int(StoryData.LANCER_QUESTS[region]["goal"]) else ""
	return ""
