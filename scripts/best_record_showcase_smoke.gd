extends Node

const BestRecordShowcaseClass = preload("res://scripts/best_record_showcase.gd")
const Localizer = preload("res://scripts/game_localizer.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_prepare_safe_main_state(game)
	_test_empty_record_is_inert(game)
	await _test_record_view_and_share(game)
	_test_opening_guards(game)
	game.queue_free()
	print("BEST_RECORD_SHOWCASE_SMOKE_OK modes=greenhouse+habitat gating=play+modal+dialog scale=linear output=1080x1920 controls_excluded=true result=removed")
	get_tree().quit()


func _prepare_safe_main_state(game) -> void:
	game.endless_greenhouse.configure(false)
	game._reset_progression_state()
	game.opening_finished = true
	game.intro_story_complete = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_tutorial_complete = true
	game.puku_gauge_intro_complete = true
	game.normal_play_tutorial_complete = true
	game.seed_pod_gauge_discovery_complete = true
	game.seed_pod_first_reward_seen = true
	game.puku_buyback_tutorial_complete = true
	game.first_play_tutorial_active = false
	game.puku_buyback_tutorial_active = false
	game.first_seed_pod_reward_event_active = false
	game.habitat_lookaround_active = false
	game.jurejure_intro_camera_active = false
	game.jurejure_first_encounter_active = false
	game.scripted_dialog_kind = ""
	game.tutorial_dialog_kind = ""
	game.current_mode = "greenhouse"
	game.play_active = false
	game.play_modal_open = false
	game.arrangement_scene_active = false
	game.arrangement_transitioning = false
	game.catalog_preview_mode_active = false
	game.greenhouse_area_drag_tracking = false
	for overlay in [
		game.opening_overlay,
		game.opening_story_overlay,
		game.habitat_awakening_overlay,
		game.seed_pod_story_overlay,
		game.habitat_second_awakening_overlay,
		game.jurejure_first_encounter_overlay,
		game.tutorial_guide_overlay,
		game.intro_overlay,
		game.result_overlay,
		game.play_overlay,
		game.shop_overlay,
		game.settings_overlay,
		game.encyclopedia_overlay,
		game.species_get_overlay,
		game.catalog_series_unlock_overlay,
		game.forest_gacha_ui,
		game.fusion_lab_ui,
		game.arrangement_ui,
		game.puku_puku_battle,
		game.collection_complete_overlay,
		game.habitat_plant_panel,
		game.habitat_dev_panel,
		game.story_dev_panel,
		game.jelly_dev_overlay,
	]:
		if overlay:
			overlay.visible = false
	game._update_play_ui()


func _test_empty_record_is_inert(game) -> void:
	game.bests = {}
	game._update_best_ui()
	game._update_play_ui()
	assert(game.best_panel.visible)
	assert(game.best_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(not game._best_record_showcase_can_open())
	game._open_best_record_showcase()
	assert(not game.best_record_showcase.visible)


func _test_record_view_and_share(game) -> void:
	game.bests = {"missing_species": 499.0, "colorata": 100.0, "laui": 500.0}
	game.language_code = "ja"
	game._update_best_ui()
	game._update_play_ui()
	var record: Dictionary = game._global_best_record()
	assert(str(record.species_id) == "laui" and is_equal_approx(float(record.size), 500.0))
	assert(game.best_label.text == Localizer.text("ja", "best_record", [500.0]), "the established top HUD value changed")
	assert(game.best_panel.get_rect() == Rect2(Vector2(204.0, 122.0), Vector2(168.0, 65.0)), "top record panel layout changed")
	assert(game.best_panel.mouse_filter == Control.MOUSE_FILTER_STOP and game._best_record_showcase_can_open())
	var panel_point: Vector2 = game.best_panel.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = panel_point
	press.pressed = true
	assert(game._best_record_panel_owns_pointer_event(press), "record-panel input could leak to the world")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = panel_point
	release.pressed = false
	game._on_best_panel_gui_input(release)
	await get_tree().process_frame
	var showcase = game.best_record_showcase
	assert(showcase.visible and game.current_mode == "greenhouse")
	assert(not game.main_status_hud.visible and not game.best_panel.visible)
	assert(not game.result_overlay.visible and game.result_overlay.get_child_count() == 0, "removed result UI was revived")
	assert(str(showcase.current_record.species_id) == "laui" and is_equal_approx(float(showcase.current_record.size), 500.0))
	assert(showcase.preview_root.get_node_or_null("HabitatBackground") is TextureRect)
	assert(showcase.preview_root.get_node_or_null("GirlScaleReference") is Sprite2D)
	assert(showcase.preview_root.get_node_or_null("RecordPlant") is Polygon2D)
	assert(showcase.title_label.text == Localizer.text("ja", "best_showcase_title"))
	assert(showcase.species_label.text == Localizer.species_name("ja", showcase.current_entry))
	assert(showcase.size_label.text == Localizer.text("ja", "best_showcase_size", [500.0]))
	assert(showcase.close_button.visible and showcase.share_button.visible)
	assert(showcase.preview_root.get_rect() == Rect2(Vector2.ZERO, BestRecordShowcaseClass.PREVIEW_SIZE))
	assert(showcase.preview_plant.visible and showcase.preview_plant.polygon.size() >= 3)
	for point in showcase.preview_plant.polygon:
		assert(Rect2(Vector2.ZERO, BestRecordShowcaseClass.PREVIEW_SIZE).grow(0.01).has_point(point), "record plant was not clipped to the viewer: %s" % point)
	var px_100 := BestRecordShowcaseClass.plant_diameter_pixels(100.0)
	var px_500 := BestRecordShowcaseClass.plant_diameter_pixels(500.0)
	var px_1000 := BestRecordShowcaseClass.plant_diameter_pixels(1000.0)
	var px_2000 := BestRecordShowcaseClass.plant_diameter_pixels(2000.0)
	assert(is_equal_approx(px_500 / px_100, 5.0))
	assert(is_equal_approx(px_1000 / px_500, 2.0), "500cm to 1000cm record art stopped scaling linearly")
	assert(is_equal_approx(px_2000 / px_1000, 2.0), "record art gained a practical size cap")
	var entry: Dictionary = showcase.current_entry.duplicate(true)
	var texture: Texture2D = showcase.current_texture
	showcase.open_record(entry, 10000.0, texture, "ja")
	assert(showcase.preview_plant.visible and showcase.preview_plant.polygon.size() >= 3, "very large record artwork disappeared")
	assert(float(showcase.last_preview_debug.plant_diameter_pixels) == BestRecordShowcaseClass.plant_diameter_pixels(10000.0))
	showcase.open_record(entry, 500.0, texture, "hiragana")
	assert(showcase.title_label.text == Localizer.text("hiragana", "best_showcase_title"))
	assert(showcase.size_label.text == Localizer.text("hiragana", "best_showcase_size", [500.0]))
	showcase.open_record(entry, 500.0, texture, "en")
	assert(showcase.title_label.text == Localizer.text("en", "best_showcase_title"))
	assert(showcase.size_label.text == Localizer.text("en", "best_showcase_size", [500.0]))
	showcase.open_record(entry, 500.0, texture, "ja")
	var bests_before := JSON.stringify(game.bests)
	var output_composition := Control.new()
	output_composition.size = Vector2(BestRecordShowcaseClass.OUTPUT_SIZE)
	showcase.add_child(output_composition)
	var output_debug: Dictionary = showcase._build_composition(output_composition, Vector2(BestRecordShowcaseClass.OUTPUT_SIZE), entry, 500.0, texture, "ja")
	var output_children: Array[String] = showcase._child_names(output_composition)
	assert(output_children == ["HabitatBackground", "HabitatAtmosphere", "PlantGroundShadow", "RecordPlant", "GirlScaleReference", "TopReadabilityShade", "BottomReadabilityShade", "RecordHeader", "RecordFooter"])
	assert(not "BestRecordCloseButton" in output_children and not "BestRecordShareButton" in output_children)
	assert(is_equal_approx(float(output_debug.plant_diameter_pixels) / float(showcase.last_preview_debug.plant_diameter_pixels), 1080.0 / 576.0))
	output_composition.queue_free()
	var output_path := "user://best-record-showcase-smoke.png"
	if DisplayServer.get_name() != "headless":
		var generated_path: String = await showcase.create_share_image(output_path)
		assert(generated_path == output_path and FileAccess.file_exists(output_path))
		var image := Image.load_from_file(output_path)
		assert(image != null and image.get_size() == BestRecordShowcaseClass.OUTPUT_SIZE)
		for corner in [Vector2i(0, 0), Vector2i(1079, 0), Vector2i(0, 1919), Vector2i(1079, 1919)]:
			assert(image.get_pixelv(corner).a > 0.99)
		assert(showcase.last_share_debug.root_children == output_children)
		print("BEST_RECORD_SHOWCASE_IMAGE=%s" % ProjectSettings.globalize_path(output_path))
	var real_share_handler := Callable(game, "_on_best_record_share_requested")
	assert(showcase.share_requested.is_connected(real_share_handler))
	showcase.share_requested.disconnect(real_share_handler)
	var captured_requests: Array = []
	var capture_request := func(value: Dictionary) -> void: captured_requests.append(value)
	showcase.share_requested.connect(capture_request)
	showcase.set_share_state("", false)
	showcase.share_button.pressed.emit()
	assert(captured_requests.size() == 1 and str(captured_requests[0].species_id) == "laui")
	assert(showcase.share_in_progress and showcase.share_button.disabled and showcase.close_button.disabled)
	showcase.share_requested.disconnect(capture_request)
	showcase.share_requested.connect(real_share_handler)
	showcase.set_share_state("", false)
	game._close_best_record_showcase()
	assert(not showcase.visible and game.main_status_hud.visible and game.best_panel.visible)
	assert(JSON.stringify(game.bests) == bests_before, "viewing or sharing mutated the record data")
	assert(game.best_panel.mouse_filter == Control.MOUSE_FILTER_STOP)


func _test_opening_guards(game) -> void:
	game.play_active = true
	game._update_play_ui()
	assert(not game._best_record_showcase_can_open() and game.best_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var play_event := InputEventMouseButton.new()
	play_event.button_index = MOUSE_BUTTON_LEFT
	play_event.position = game.best_panel.get_global_rect().get_center()
	play_event.pressed = true
	assert(not game._best_record_panel_owns_pointer_event(play_event))
	game.play_active = false
	game.settings_overlay.visible = true
	game._update_best_record_panel_interaction()
	assert(not game._best_record_showcase_can_open() and game.best_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	game.settings_overlay.visible = false
	game.intro_overlay.visible = true
	game.scripted_dialog_kind = "story"
	game._update_best_record_panel_interaction()
	assert(not game._best_record_showcase_can_open())
	game.intro_overlay.visible = false
	game.scripted_dialog_kind = ""
	game.current_mode = "habitat"
	game._update_play_ui()
	assert(game._best_record_showcase_can_open() and game.best_panel.mouse_filter == Control.MOUSE_FILTER_STOP)
	game._open_best_record_showcase()
	assert(game.best_record_showcase.visible and game.current_mode == "habitat")
	game._close_best_record_showcase()
	game.current_mode = "greenhouse"
	game._update_play_ui()
