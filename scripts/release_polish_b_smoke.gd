extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const OpeningStoryOverlayClass = preload("res://scripts/opening_story_overlay.gd")
const HabitatAwakeningOverlayClass = preload("res://scripts/habitat_awakening_overlay.gd")
const SeedPodStoryOverlayClass = preload("res://scripts/seed_pod_story_overlay.gd")
const HabitatSecondAwakeningOverlayClass = preload("res://scripts/habitat_second_awakening_overlay.gd")
const JureJureFirstEncounterOverlayClass = preload("res://scripts/jurejure_first_encounter_overlay.gd")
const HabitatRestorationUIClass = preload("res://scripts/habitat_restoration_ui.gd")
const StoryContinueButtonStyleClass = preload("res://scripts/story_continue_button_style.gd")

const ENDING_THANKS := "THANK YOU FOR PLAYING\nPUKU PUKU TANIKU!"
const ENDING_CREDIT := "PRODUCED BY OHANAYA NOUEN"


func _ready() -> void:
	_test_localized_continuation_copy()
	await _test_story_overlay_continuation_buttons()
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _test_scripted_dialog_continuation(game)
	_test_ending_credit(game)
	await _test_get_to_catalog_unlock_handoff(game)
	_test_visible_copy_has_no_internal_paths(game)
	game._reset_progression_state()
	print("RELEASE_POLISH_B_SMOKE_OK continuation=6_overlays+scripted+collection locales=3 standard_style=true inside_panels=true fullscreen_tap_preserved=true obsolete_keys=removed ending=exact_all_locales get_to_catalog=5_contexts no_intermediate_foreground=true internal_paths=clean")
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
	for key in ["story_habitat_found_1", "awakening_memory", "awakening_promise_3", "final_theme_girl", "story_complete_2"]:
		assert("\n" not in Localizer.text("en", key))
	assert(Localizer.text("en", "story_trio_3") == "I can't believe it.\nPlants lost for so long\nare right before our eyes...")
	assert(Localizer.text("en", "jurejure_confront_girl_1") == "Succulents went extinct long ago\nbecause of people like you!")


func _test_story_overlay_continuation_buttons() -> void:
	var overlay_specs := [
		{"overlay": OpeningStoryOverlayClass.new(), "button": "tap_hint", "panel_property": "text_panel", "text_property": "story_text", "panel_rect": Rect2(14, 586, 548, 414), "panel_bg": Color(0.105, 0.055, 0.035, 0.92), "text_color": Color("#fff6df")},
		{"overlay": HabitatAwakeningOverlayClass.new(), "button": "instruction_label", "panel_property": "text_back", "text_property": "dialogue_label", "panel_rect": Rect2(24, 744, 528, 226), "panel_bg": Color(0.08, 0.06, 0.05, 0.90), "text_color": Color("#fff6df"), "dialog_keys": HabitatAwakeningOverlayClass.DIALOG_KEYS},
		{"overlay": SeedPodStoryOverlayClass.new(), "button": "tap_hint", "text_property": "story_text", "panel_rect": Rect2(14, 730, 548, 240), "panel_bg": Color(0.105, 0.055, 0.035, 0.92), "text_color": Color("#fff6df"), "dialog_keys": SeedPodStoryOverlayClass.DIALOG_KEYS},
		{"overlay": HabitatSecondAwakeningOverlayClass.new(), "button": "instruction_label", "text_property": "dialogue_label", "panel_rect": Rect2(24, 744, 528, 226), "panel_bg": Color(0.07, 0.045, 0.09, 0.92), "text_color": Color("#fff7ff"), "dialog_keys": HabitatSecondAwakeningOverlayClass.DIALOG_KEYS},
		{"overlay": JureJureFirstEncounterOverlayClass.new(), "button": "tap_hint", "text_property": "dialogue_label", "panel_rect": Rect2(24, 758, 528, 220), "panel_bg": Color(0.08, 0.045, 0.025, 0.92), "text_color": Color("#fff6df"), "dialog_keys": JureJureFirstEncounterOverlayClass.DIALOG_KEYS},
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
			await get_tree().process_frame
			var button := overlay.get(str(spec["button"])) as Button
			var panel: Control = overlay.get(str(spec.get("panel_property", ""))) as Control
			if panel == null:
				panel = overlay.find_child("StoryTextPanel", true, false) as Control
			var dialogue_text := overlay.get(str(spec["text_property"])) as Control
			_assert_standard_continue_button(button, panel, dialogue_text, locale, true)
			if overlay is HabitatAwakeningOverlay and locale == "ja":
				assert((dialogue_text as Label).text == "記録では、ここで間違いないはずなんだけど……。")
				assert(button.position.is_equal_approx(Vector2(163, 898)))
			assert(dialogue_text.get_theme_font_size("font_size") == 20)
			assert(dialogue_text.get_theme_color("font_color").is_equal_approx(spec["text_color"]))
			var expected_panel_rect: Rect2 = spec["panel_rect"]
			assert(panel.position.is_equal_approx(expected_panel_rect.position))
			assert(panel.size.is_equal_approx(expected_panel_rect.size))
			var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			var expected_panel_bg: Color = spec["panel_bg"]
			assert(panel_style != null and panel_style.bg_color.is_equal_approx(expected_panel_bg))
			assert(panel_style.border_width_left == 2 and panel_style.corner_radius_top_left == 24)
			var tap_area := overlay.find_child("StoryTapArea", true, false) as Button
			assert(tap_area != null and tap_area.pressed.get_connections().size() == 1)
			assert(button.get_parent() == tap_area.get_parent() and button.get_index() > tap_area.get_index())
			if overlay is OpeningStoryOverlay:
				for page_index in range(OpeningStoryOverlayClass.PAGE_TEXT_KEYS.size()):
					overlay._show_page(page_index)
					await get_tree().process_frame
					_assert_standard_continue_button(button, panel, dialogue_text, locale, true)
			else:
				for key_value in spec.get("dialog_keys", []):
					var dialogue_key := str(key_value)
					if dialogue_key.begins_with("_"):
						continue
					(dialogue_text as Label).text = Localizer.text(locale, dialogue_key)
					await get_tree().process_frame
					_assert_standard_continue_button(button, panel, dialogue_text, locale, true)
			overlay.visible = false
		overlay.queue_free()
	await get_tree().process_frame
	var restoration := HabitatRestorationUIClass.new()
	add_child(restoration)
	await get_tree().process_frame
	restoration.start_recovery_slides()
	await get_tree().process_frame
	var restoration_panel := restoration.find_child("StoryTextPanel", true, false) as Control
	for locale in Localizer.SUPPORTED_LANGUAGES:
		restoration.set_language(locale)
		for slide_index in range(3):
			restoration.slide_index = slide_index
			restoration._show_slide()
			await get_tree().process_frame
			_assert_standard_continue_button(restoration.ending_continue, restoration_panel, restoration.ending_body, locale)
	assert(restoration_panel.position.is_equal_approx(Vector2(38, 78)))
	assert(restoration_panel.size.is_equal_approx(Vector2(500, 818)))
	var restoration_panel_style := restoration_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(restoration_panel_style != null and restoration_panel_style.bg_color.is_equal_approx(Color(0.12, 0.18, 0.13, 0.84)))
	restoration.queue_free()
	await get_tree().process_frame


func _assert_standard_continue_button(button: Button, panel: Control, dialogue_text: Control, locale: String, panel_bottom_aligned := false) -> void:
	assert(button != null and panel != null and dialogue_text != null)
	assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(button.text == Localizer.text(locale, "continue"))
	assert(button.custom_minimum_size.is_equal_approx(StoryContinueButtonStyleClass.BUTTON_SIZE))
	assert(button.size.is_equal_approx(StoryContinueButtonStyleClass.BUTTON_SIZE))
	assert(button.get_theme_font_size("font_size") == StoryContinueButtonStyleClass.FONT_SIZE)
	assert(button.get_theme_color("font_color").is_equal_approx(StoryContinueButtonStyleClass.FONT_COLOR))
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(normal != null and normal.bg_color.is_equal_approx(StoryContinueButtonStyleClass.BACKGROUND_COLOR))
	assert(normal.border_width_left == StoryContinueButtonStyleClass.BORDER_WIDTH)
	assert(normal.corner_radius_top_left == StoryContinueButtonStyleClass.CORNER_RADIUS)
	assert(normal.shadow_size == 6 and normal.shadow_offset.is_equal_approx(Vector2(0, 3)))
	var button_rect := button.get_global_rect()
	assert(panel.get_global_rect().grow(0.5).encloses(button_rect))
	if panel_bottom_aligned:
		var panel_rect := panel.get_global_rect()
		var dialogue_rect := dialogue_text.get_global_rect()
		assert(is_equal_approx(panel_rect.end.y - button_rect.end.y, StoryContinueButtonStyleClass.PANEL_BOTTOM_MARGIN))
		assert(button_rect.position.y - dialogue_rect.end.y >= StoryContinueButtonStyleClass.TEXT_BUTTON_GAP - 0.5, "continue button is too close to dialogue: button=%s dialogue=%s" % [button_rect, dialogue_rect])
		var text_label := dialogue_text as Label
		assert(text_label.get_line_count() * text_label.get_line_height() <= text_label.size.y + 0.5, "dialogue text is clipped: lines=%d line_height=%d size=%s" % [text_label.get_line_count(), text_label.get_line_height(), text_label.size])
	var visible_text_rect := _visible_label_text_rect(dialogue_text as Label)
	assert(not button_rect.intersects(visible_text_rect), "continue button overlaps visible text: button=%s text=%s" % [button_rect, visible_text_rect])
	assert(button.pressed.get_connections().size() >= 1)


func _visible_label_text_rect(label: Label) -> Rect2:
	var content_height := minf(label.size.y, float(label.get_line_count() * label.get_line_height()))
	var top := label.global_position.y
	if label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		top += (label.size.y - content_height) * 0.5
	elif label.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		top += label.size.y - content_height
	return Rect2(Vector2(label.global_position.x, top), Vector2(label.size.x, content_height))


func _test_scripted_dialog_continuation(game: Node) -> void:
	game._start_scripted_dialog("release_polish_b", [{"speaker": "panda", "text": "test"}])
	await get_tree().process_frame
	assert(game.intro_overlay.visible)
	assert(game.intro_dialog_panel.size.is_equal_approx(Vector2(496, 255)))
	var greenhouse_panel_style := game.intro_dialog_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(greenhouse_panel_style != null and greenhouse_panel_style.bg_color.is_equal_approx(Color(0.97, 0.90, 0.75, 0.96)))
	assert(game.intro_continue_button.text == Localizer.text(game.language_code, "continue"))
	_assert_standard_continue_button(game.intro_continue_button, game.intro_dialog_panel, game.intro_dialogue_label, game.language_code)
	game.collection_complete_overlay.visible = true
	game._show_collection_complete_card()
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_standard_continue_button(game.collection_complete_continue_button, game.collection_complete_card, game.collection_complete_message_label, game.language_code)
	game.collection_complete_card.visible = false
	game.collection_complete_overlay.visible = false
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
