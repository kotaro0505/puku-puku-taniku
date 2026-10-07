extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const OpeningStoryOverlayClass = preload("res://scripts/opening_story_overlay.gd")
const HabitatAwakeningOverlayClass = preload("res://scripts/habitat_awakening_overlay.gd")
const SeedPodStoryOverlayClass = preload("res://scripts/seed_pod_story_overlay.gd")
const HabitatSecondAwakeningOverlayClass = preload("res://scripts/habitat_second_awakening_overlay.gd")
const JureJureFirstEncounterOverlayClass = preload("res://scripts/jurejure_first_encounter_overlay.gd")

const ENDING_THANKS := "THANK YOU FOR PLAYING\nPUKU PUKU TANIKU!"
const ENDING_CREDIT := "PRODUCED BY OHANAYA NOUEN"


func _ready() -> void:
	_test_localized_continuation_copy()
	await _test_story_overlay_continuation_copy()
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_test_scripted_dialog_continuation(game)
	_test_ending_credit(game)
	await _test_get_to_catalog_unlock_handoff(game)
	_test_visible_copy_has_no_internal_paths(game)
	game._reset_progression_state()
	print("RELEASE_POLISH_B_SMOKE_OK continuation=5_overlays+scripted locales=3 obsolete_keys=removed ending=exact_all_locales get_to_catalog=5_contexts no_intermediate_foreground=true internal_paths=clean")
	get_tree().quit()


func _test_localized_continuation_copy() -> void:
	for locale in Localizer.SUPPORTED_LANGUAGES:
		var expected := "Continue" if locale == "en" else "つづける"
		assert(Localizer.text(locale, "continue") == expected)
		assert(not (Localizer.TEXT.get(locale, {}) as Dictionary).has("opening_story_tap"))
		assert(not (Localizer.TEXT.get(locale, {}) as Dictionary).has("next"))
		assert(Localizer.text(locale, "tap_to_close") != expected)
	assert("\n" not in Localizer.text("ja", "awakening_promise_3"))
	assert("\n" not in Localizer.text("hiragana", "awakening_promise_3"))
	for key in ["story_trio_3", "story_habitat_found_1", "awakening_memory", "awakening_promise_3", "final_theme_girl", "jurejure_confront_girl_1", "story_complete_2"]:
		assert("\n" not in Localizer.text("en", key))


func _test_story_overlay_continuation_copy() -> void:
	var overlay_specs := [
		{"overlay": OpeningStoryOverlayClass.new(), "hint": "tap_hint", "start_args": [false, 0]},
		{"overlay": HabitatAwakeningOverlayClass.new(), "hint": "instruction_label", "start_args": []},
		{"overlay": SeedPodStoryOverlayClass.new(), "hint": "tap_hint", "start_args": []},
		{"overlay": HabitatSecondAwakeningOverlayClass.new(), "hint": "instruction_label", "start_args": []},
		{"overlay": JureJureFirstEncounterOverlayClass.new(), "hint": "tap_hint", "start_args": []},
	]
	for spec_value in overlay_specs:
		var spec: Dictionary = spec_value
		var overlay: Control = spec["overlay"]
		add_child(overlay)
		await get_tree().process_frame
		for locale in Localizer.SUPPORTED_LANGUAGES:
			if overlay is OpeningStoryOverlay:
				overlay.start(false, 0, locale)
			else:
				overlay.start(locale)
			var hint: Label = overlay.get(str(spec["hint"]))
			assert(hint != null and hint.text == Localizer.text(locale, "continue"))
			overlay.visible = false
		overlay.queue_free()
	await get_tree().process_frame


func _test_scripted_dialog_continuation(game: Node) -> void:
	game._start_scripted_dialog("release_polish_b", [{"speaker": "panda", "text": "test"}])
	assert(game.intro_overlay.visible)
	assert(game.intro_continue_button.text == Localizer.text(game.language_code, "continue"))
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false


func _test_ending_credit(game: Node) -> void:
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(Localizer.text(locale, "restoration_thank_you") == ENDING_THANKS)
		assert(Localizer.text(locale, "restoration_product_by") == ENDING_CREDIT)
		game.habitat_restoration_ui.set_language(locale)
		assert(game.habitat_restoration_ui.ending_thank_you_label.text == ENDING_THANKS)
		assert(game.habitat_restoration_ui.ending_product_label.text == ENDING_CREDIT)
		assert(game.habitat_restoration_ui.ending_product_label.get_minimum_size().x <= game.habitat_restoration_ui.ending_product_label.size.x)


func _test_get_to_catalog_unlock_handoff(game: Node) -> void:
	var contexts := ["round_result_new", "forest_gacha", "fusion_lab", "scripted_dialog_card:test", "armadillo_gift"]
	var series_ids := ["gummy", "metal", "sweets", "glow", "jewel"]
	game._reset_progression_state()
	for index in range(contexts.size()):
		game.species_get_overlay.visible = false
		game.catalog_series_unlock_overlay.reset_overlay()
		game.species_get_queue.clear()
		var series_entries: Array = game._series_species_entries(series_ids[index])
		assert(not series_entries.is_empty())
		var entry: Dictionary = series_entries[0]
		var species_id := str(entry.get("species_id", ""))
		assert(not species_id.is_empty())
		assert(game._register_species_discovery(species_id, true))
		assert(game.catalog_series_unlock_notice_queue == [series_ids[index]])
		game._queue_species_get(entry, true, contexts[index])
		game._show_next_species_get()
		assert(game.species_get_overlay.visible and not game.catalog_series_unlock_overlay.visible)
		# The close animation itself is already covered by the overlay smoke. Drive
		# its completion callback synchronously here so every acquisition context
		# proves that no ordinary foreground can occupy the handoff frame.
		game.species_get_overlay.visible = false
		game.species_get_overlay.busy = false
		game._on_species_get_overlay_closed(contexts[index])
		assert(game.catalog_series_unlock_overlay.visible)
		assert(game.catalog_series_unlock_overlay.current_context == contexts[index])
		assert(not game.result_overlay.visible and not game.play_overlay.visible)
		game.catalog_series_unlock_overlay.reset_overlay()
		game.catalog_series_unlock_active_id = ""


func _test_visible_copy_has_no_internal_paths(game: Node) -> void:
	game.opening_overlay.visible = false
	var no_candidates: Array[Dictionary] = []
	game.fusion_lab_ui.open_lab(no_candidates, {})
	for locale in Localizer.SUPPORTED_LANGUAGES:
		game.fusion_lab_ui.set_language(locale)
		_assert_visible_text_safe(game.fusion_lab_ui)
	game.fusion_lab_ui.close_lab()
	for value in HabitatAwakeningOverlayClass.DIALOG_KEYS:
		if str(value).begins_with("_pause_"):
			assert(not (Localizer.TEXT["ja"] as Dictionary).has(str(value)))


func _assert_visible_text_safe(root: Node) -> void:
	for node in root.find_children("*", "", true, false):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		var text_value := ""
		if node is Label:
			text_value = (node as Label).text
		elif node is Button:
			text_value = (node as Button).text
		var lowered := text_value.to_lower()
		assert("http://" not in lowered)
		assert("https://" not in lowered)
		assert("res://" not in lowered)
		assert("user://" not in lowered)
		assert("_pause_" not in lowered)
