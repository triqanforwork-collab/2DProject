extends CanvasLayer

@onready var health_bar: TextureProgressBar = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/HealthBar/Fill
@onready var health_value: Label = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/HealthBar/HealthValue
@onready var mana_bar: TextureProgressBar = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/ManaBar/Fill
@onready var mana_value: Label = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/ManaBar/ManaValue
@onready var energy_value: Label = $ScreenAnchor/HUDPanel/InnerMargin/Content/HealthSection/EnergyRow/EnergyMargin/EnergyContent/EnergyValue

var player: Node
var quest_label: Label


func _ready() -> void:
	player = get_parent()
	if player == null:
		return

	if player.has_signal("health_changed"):
		player.connect("health_changed", _on_health_changed)
	if player.has_signal("mana_changed"):
		player.connect("mana_changed", _on_mana_changed)

	if not EnergyManager.energy_changed.is_connected(_on_energy_changed):
		EnergyManager.energy_changed.connect(_on_energy_changed)
	_on_energy_changed(EnergyManager.carried_energy)
	_create_quest_label()
	_sync_from_player.call_deferred()


func _sync_from_player() -> void:
	if not is_instance_valid(player):
		return

	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_on_mana_changed(int(player.get("mana")), int(player.get("max_mana")))


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	var safe_maximum := maxi(maximum_health, 1)
	var display_health := clampi(current_health, 0, safe_maximum)
	health_bar.max_value = safe_maximum
	health_bar.value = display_health
	health_value.text = "%d / %d" % [display_health, safe_maximum]


func _on_mana_changed(current_mana: int, maximum_mana: int) -> void:
	var safe_maximum := maxi(maximum_mana, 1)
	var display_mana := clampi(current_mana, 0, safe_maximum)
	mana_bar.max_value = safe_maximum
	mana_bar.value = display_mana
	mana_value.text = "%d / %d" % [display_mana, safe_maximum]

func _on_energy_changed(current_energy: int) -> void:
	energy_value.text = str(maxi(current_energy, 0))


# One-line tracker for the active Lancer quest, under the HUD panel.
func _create_quest_label() -> void:
	quest_label = Label.new()
	quest_label.position = Vector2(26, 126)
	quest_label.add_theme_font_size_override("font_size", 16)
	quest_label.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_label.add_theme_constant_override("outline_size", 4)
	quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quest_label)
	ProgressionManager.lancer_quest_changed.connect(_update_quest_label.unbind(1))
	_update_quest_label()


func _update_quest_label() -> void:
	quest_label.text = ""
	for region_id in ProgressionManager.STONE_ORDER:
		var quest := ProgressionManager.get_lancer_quest(region_id)
		if str(quest.get("state", "")) != "active":
			continue
		var data: Dictionary = StoryData.LANCER_QUESTS[region_id]
		var progress := int(quest.get("progress", 0))
		var goal := int(data["goal"])
		if progress >= goal:
			quest_label.text = "Nhiệm vụ: " + StoryData.QUEST_RETURN_HUD % data["guardian"]
		else:
			quest_label.text = "Nhiệm vụ: " + str(data["hud"]) % [progress, goal]
		return
