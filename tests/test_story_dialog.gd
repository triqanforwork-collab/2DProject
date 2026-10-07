extends SceneTree


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	var progression = root.get_node("ProgressionManager")
	# Loaded at runtime: the dialog uses autoloads that do not exist when this test is parsed.
	var story_dialog: GDScript = load("res://scripts/ui/story_dialog.gd")

	# Seen flags: first time only, survive save/load, cleared by reset.
	progression.reset_progression()
	assert(progression.mark_story_seen(&"monk_welcome"))
	assert(not progression.mark_story_seen(&"monk_welcome"))
	var data: Dictionary = progression.get_save_data()
	progression.load_save_data(data)
	assert(not progression.mark_story_seen(&"monk_welcome"))
	progression.reset_progression()
	assert(progression.mark_story_seen(&"monk_welcome"))

	# Every story page has text; every Monk line list is non-empty.
	for page in StoryData.INTRO + StoryData.ENDING:
		assert(not str(page["text"]).is_empty())
		assert(StoryData.load_story_image(str(page["image"])) != null)
	for stone_id in [&"water", &"earth", &"light", &"air"]:
		assert(not StoryData.MONK_STONE_ACTIVATED[stone_id].is_empty())

	# Dialog: first advance finishes typing, then pages move on, last page closes.
	var host := Node.new()
	root.add_child(host)
	var done := [false]
	var run := func() -> void:
		await story_dialog.play_pages(host, StoryData.INTRO.slice(0, 2))
		done[0] = true
	run.call()
	await process_frame
	var dialog = host.get_child(0)
	assert(dialog.text_label.visible_ratio < 1.0)
	dialog._advance()
	assert(dialog.text_label.visible_ratio == 1.0 and dialog.page_index == 0)
	dialog._advance()
	assert(dialog.page_index == 1 and dialog.next_button.text == "ĐÓNG")
	dialog._advance()
	dialog._advance()
	await process_frame
	assert(done[0])

	# Monk dialog closes with skip.
	done[0] = false
	var run_monk := func() -> void:
		await story_dialog.play_monk(host, StoryData.MONK_WELCOME)
		done[0] = true
	run_monk.call()
	await process_frame
	host.get_child(-1)._finish()
	await process_frame
	assert(done[0])

	print("Story dialog test passed.")
	quit()
