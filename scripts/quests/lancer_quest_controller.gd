# Lives on the "QuestSpots" node in Main Area. Its Marker2D children are the
# possible quest item spots; each marker's "hint" metadata describes where it is
# (used in the Light riddle). Spots are picked at random when a quest starts and
# saved, so items stay put across Continue.
extends Node2D

const HERB_SHEET := preload("res://assets/tiny_swords/terrain/bushes/Bushe2.png")
const ORE_TEXTURE := preload("res://assets/tiny_swords/terrain/rocks/Rock2.png")
const PILLAR_TEXTURE := preload("res://assets/tiny_swords/terrain/rocks/Rock4.png")
const HERB_COLOR := Color(0.55, 1.0, 0.85)
const ORE_COLOR := Color(1.0, 0.62, 0.25)
const PILLAR_COLOR := Color(1.0, 0.9, 0.45)
const SPAWN_GROUP := &"quest_spawn"


func _ready() -> void:
	add_to_group("lancer_quest_controller")
	ProgressionManager.lancer_quest_changed.connect(_on_quest_changed)
	_refresh_spawns.call_deferred()


func start_quest(region_id: StringName) -> void:
	var goal := int(StoryData.LANCER_QUESTS[region_id]["goal"])
	var spot_count := 1 if region_id == &"air" else goal
	var spots := range(get_spots().size())
	spots.shuffle()
	ProgressionManager.update_lancer_quest(region_id, {
		"state": "active",
		"progress": 0,
		"spots": spots.slice(0, spot_count) if region_id != &"life" else [],
		"visited": [],
	})


func get_spots() -> Array[Marker2D]:
	var spots: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			spots.append(child)
	return spots


func get_light_riddle() -> Array:
	var spots := get_spots()
	var lines := []
	var quest_spots: Array = ProgressionManager.get_lancer_quest(&"light").get("spots", [])
	for order in quest_spots.size():
		var spot := spots[int(quest_spots[order])]
		lines.append(StoryData.LIGHT_RIDDLE[order] % str(spot.get_meta("hint", "đâu đó trên đảo")))
	return lines


func _on_quest_changed(_region_id: StringName) -> void:
	_refresh_spawns()


# Rebuilds every quest object from saved state; simple and always in sync.
func _refresh_spawns() -> void:
	for node in get_tree().get_nodes_in_group(SPAWN_GROUP):
		node.queue_free()

	var spots := get_spots()
	for region_id in [&"water", &"earth", &"light", &"air"]:
		var quest := ProgressionManager.get_lancer_quest(region_id)
		if str(quest.get("state", "")) != "active":
			continue
		var progress := int(quest.get("progress", 0))
		var quest_spots: Array = quest.get("spots", [])
		var goal := int(StoryData.LANCER_QUESTS[region_id]["goal"])

		match region_id:
			&"water", &"earth":
				var picked: Array = quest.get("picked", [])
				for spot_index in quest_spots:
					if int(spot_index) in picked.map(func(value): return int(value)):
						continue
					_spawn_collectible(region_id, int(spot_index), spots)
			&"light":
				for order in quest_spots.size():
					var pillar := _spawn_item(PILLAR_TEXTURE, PILLAR_COLOR, 1.6, int(quest_spots[order]), spots)
					pillar.set_lit(order < progress)
					pillar.activated.connect(_on_pillar_activated.bind(order))
			&"air":
				if progress < goal and not quest_spots.is_empty():
					_spawn_wisp(int(quest_spots[0]), spots)


func _spawn_collectible(region_id: StringName, spot_index: int, spots: Array[Marker2D]) -> void:
	var item: QuestItem
	if region_id == &"water":
		var herb := AtlasTexture.new()
		herb.atlas = HERB_SHEET
		herb.region = Rect2(0, 0, 128, 128)
		item = _spawn_item(herb, HERB_COLOR, 0.8, spot_index, spots)
	else:
		item = _spawn_item(ORE_TEXTURE, ORE_COLOR, 1.1, spot_index, spots)
	item.activated.connect(_on_collectible_activated.bind(region_id))


func _spawn_item(texture: Texture2D, color: Color, sprite_scale: float, spot_index: int, spots: Array[Marker2D]) -> QuestItem:
	var item := QuestItem.new().setup(texture, color, sprite_scale, spot_index)
	item.position = spots[spot_index].position
	item.add_to_group(SPAWN_GROUP)
	add_child(item)
	return item


func _spawn_wisp(spot_index: int, spots: Array[Marker2D]) -> void:
	var flee_spots: Array[Vector2] = []
	for spot in spots:
		flee_spots.append(spot.global_position)
	var wisp := QuestWisp.new().setup(flee_spots)
	wisp.position = spots[spot_index].position
	wisp.add_to_group(SPAWN_GROUP)
	wisp.caught.connect(_on_wisp_caught, CONNECT_ONE_SHOT)
	add_child(wisp)


func _on_collectible_activated(item: QuestItem, region_id: StringName) -> void:
	var quest := ProgressionManager.get_lancer_quest(region_id)
	var picked: Array = quest.get("picked", []).duplicate()
	picked.append(item.spot_index)
	AudioManager.play_sfx(&"energy_pickup")
	ProgressionManager.update_lancer_quest(region_id, {"picked": picked, "progress": picked.size()})


func _on_pillar_activated(_item: QuestItem, order: int) -> void:
	var progress := int(ProgressionManager.get_lancer_quest(&"light").get("progress", 0))
	if order < progress:
		return
	if order == progress:
		AudioManager.play_sfx(&"upgrade")
		ProgressionManager.update_lancer_quest(&"light", {"progress": progress + 1})
		return
	# Wrong order: every pillar falls asleep again.
	AudioManager.play_sfx(&"denied")
	ProgressionManager.update_lancer_quest(&"light", {"progress": 0})


# Each catch respawns the wisp at a random spot away from the player until the goal is reached.
func _on_wisp_caught() -> void:
	var quest := ProgressionManager.get_lancer_quest(&"air")
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var spots := get_spots()
	var far_spots := range(spots.size()).filter(func(index: int) -> bool:
		return player == null or spots[index].global_position.distance_to(player.global_position) > 300.0
	)
	var next: int = far_spots.pick_random() if not far_spots.is_empty() else 0
	AudioManager.play_sfx(&"magic_cast")
	ProgressionManager.update_lancer_quest(&"air", {"progress": int(quest.get("progress", 0)) + 1, "spots": [next]})
