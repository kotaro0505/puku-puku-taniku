extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const OpeningStoryOverlayClass = preload("res://scripts/opening_story_overlay.gd")
const HabitatAwakeningOverlayClass = preload("res://scripts/habitat_awakening_overlay.gd")
const SeedPodStoryOverlayClass = preload("res://scripts/seed_pod_story_overlay.gd")
const HabitatSecondAwakeningOverlayClass = preload("res://scripts/habitat_second_awakening_overlay.gd")
const JureJureFirstEncounterOverlayClass = preload("res://scripts/jurejure_first_encounter_overlay.gd")
const HabitatRestorationUIClass = preload("res://scripts/habitat_restoration_ui.gd")
const StoryContinueButtonStyleClass = preload("res://scripts/story_continue_button_style.gd")
const StandardStoryDialoguePanelClass = preload("res://scripts/standard_story_dialogue_panel.gd")

const ENDING_THANKS := {
	"ja": "あそんでくれてありがとう！\nぷくぷく！たにくらいふ",
	"hiragana": "あそんでくれて ありがとう！\nぷくぷく！たにくらいふ",
	"en": "Thank you for playing!\nPuku Puku! Taniku Life",
}
const ENDING_CREDIT := "Produced by オハナ屋農園"


func _ready() -> void:
	_test_localized_continuation_copy()
	await _test_story_overlay_continuation_buttons()
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _test_scripted_dialog_continuation(game)
	await _test_tutorial_dialog_continuation(game)
	_test_ending_credit(game)
	await _test_get_to_catalog_unlock_handoff(game)
	_test_visible_copy_has_no_internal_paths(game)
	game._reset_progression_state()
	print("RELEASE_POLISH_B_SMOKE_OK continuation=6_overlays+scripted+collection+tutorial_9_pages locales=3 tutorial_speakers=8_pages_localized+system_none speaker_top_gap=8 greenhouse_dialogue_shared=5_contexts standard_style=true inside_panels=true input=button+fullscreen_single_step operation_guides=no_continue obsolete_keys=removed ending=exact_all_locales get_to_catalog=5_contexts no_intermediate_foreground=true internal_paths=clean")
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
		{"overlay": HabitatAwakeningOverlayClass.new(), "button": "instruction_label", "panel_property": "text_back", "text_property": "dialogue_label", "standard_panel": true, "dialog_keys": HabitatAwakeningOverlayClass.DIALOG_KEYS},
		{"overlay": SeedPodStoryOverlayClass.new(), "button": "tap_hint", "text_property": "story_text", "standard_panel": true, "dialog_keys": SeedPodStoryOverlayClass.DIALOG_KEYS},
		{"overlay": HabitatSecondAwakeningOverlayClass.new(), "button": "instruction_label", "text_property": "dialogue_label", "standard_panel": true, "dialog_keys": HabitatSecondAwakeningOverlayClass.DIALOG_KEYS},
		{"overlay": JureJureFirstEncounterOverlayClass.new(), "button": "tap_hint", "text_property": "dialogue_label", "standard_panel": true, "dialog_keys": JureJureFirstEncounterOverlayClass.DIALOG_KEYS},
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
			var uses_standard_panel := bool(spec.get("standard_panel", false))
			_assert_standard_continue_button(button, panel, dialogue_text, locale, not uses_standard_panel)
			if overlay is HabitatAwakeningOverlay and locale == "ja":
				assert((dialogue_text as Label).text == "記録では、ここで間違いないはずなんだけど……。")
			assert(dialogue_text.get_theme_font_size("font_size") == 20)
			var expected_text_color: Color = StandardStoryDialoguePanelClass.TEXT_COLOR if uses_standard_panel else spec["text_color"]
			assert(dialogue_text.get_theme_color("font_color").is_equal_approx(expected_text_color))
			var expected_panel_rect := Rect2(StandardStoryDialoguePanelClass.DEFAULT_POSITION, StandardStoryDialoguePanelClass.PANEL_SIZE) if uses_standard_panel else spec["panel_rect"] as Rect2
			assert(panel.position.is_equal_approx(expected_panel_rect.position))
			assert(panel.size.is_equal_approx(expected_panel_rect.size))
			var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			var expected_panel_bg: Color = StandardStoryDialoguePanelClass.PANEL_BACKGROUND if uses_standard_panel else spec["panel_bg"]
			assert(panel_style != null and panel_style.bg_color.is_equal_approx(expected_panel_bg))
			assert(panel_style.border_width_left == (4 if uses_standard_panel else 2) and panel_style.corner_radius_top_left == 24)
			var tap_area := overlay.find_child("StoryTapArea", true, false) as Button
			assert(tap_area != null and tap_area.pressed.get_connections().size() == 1)
			if uses_standard_panel:
				_assert_standard_dialogue_panel(panel, button, dialogue_text)
				assert(panel.get_script() == StandardStoryDialoguePanelClass)
				assert(panel.is_ancestor_of(button))
				assert(panel.get_parent() == tap_area.get_parent() and panel.get_index() > tap_area.get_index())
			else:
				assert(button.get_parent() == tap_area.get_parent() and button.get_index() > tap_area.get_index())
			if overlay is OpeningStoryOverlay:
				for page_index in range(OpeningStoryOverlayClass.PAGE_TEXT_KEYS.size()):
					overlay._show_page(page_index)
					await get_tree().process_frame
					_assert_standard_continue_button(button, panel, dialogue_text, locale, not uses_standard_panel)
			else:
				for key_value in spec.get("dialog_keys", []):
					var dialogue_key := str(key_value)
					if dialogue_key.begins_with("_"):
						continue
					(dialogue_text as Label).text = Localizer.text(locale, dialogue_key)
					await get_tree().process_frame
					_assert_standard_continue_button(button, panel, dialogue_text, locale, not uses_standard_panel)
					if uses_standard_panel:
						_assert_standard_dialogue_panel(panel, button, dialogue_text)
			if uses_standard_panel and locale == "ja":
				overlay.start(locale)
				await get_tree().process_frame
				_prepare_overlay_for_input_check(overlay)
				var starting_page := int(overlay.get("page_index"))
				button.pressed.emit()
				assert(int(overlay.get("page_index")) == starting_page + 1)
				_prepare_overlay_for_input_check(overlay)
				tap_area.pressed.emit()
				assert(int(overlay.get("page_index")) == starting_page + 2)
			overlay.visible = false
		overlay.queue_free()
	await get_tree().process_frame
	var restoration := HabitatRestorationUIClass.new()
	add_child(restoration)
	await get_tree().process_frame
	restoration.start_recovery_slides()
	# The production card becomes visible after the image fade. This style test
	# drives pages directly, so expose it before asking Containers for layout.
	restoration.ending_story_card.visible = true
	await get_tree().process_frame
	var restoration_panel := restoration.find_child("StoryTextPanel", true, false) as Control
	for locale in Localizer.SUPPORTED_LANGUAGES:
		restoration.set_language(locale)
		for slide_index in range(3):
			restoration.slide_index = slide_index
			restoration._show_slide()
			await get_tree().process_frame
			_assert_standard_continue_button(restoration.ending_continue, restoration_panel, restoration.ending_body, locale)
	assert(restoration_panel.position.is_equal_approx(HabitatRestorationUIClass.RECOVERY_CARD_POSITION))
	assert(restoration_panel.size.is_equal_approx(HabitatRestorationUIClass.RECOVERY_CARD_SIZE))
	assert(restoration_panel.find_children("*", "Label", true, false).size() == 1)
	var restoration_panel_style := restoration_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(restoration_panel_style != null and restoration_panel_style.bg_color.is_equal_approx(HabitatRestorationUIClass.RECOVERY_CARD_BACKGROUND))
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
	assert(normal.border_color.is_equal_approx(StoryContinueButtonStyleClass.BORDER_COLOR))
	assert(normal.border_width_left == StoryContinueButtonStyleClass.BORDER_WIDTH)
	assert(normal.corner_radius_top_left == StoryContinueButtonStyleClass.CORNER_RADIUS)
	assert(normal.shadow_size == 6 and normal.shadow_offset.is_equal_approx(Vector2(0, 3)))
	var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed := button.get_theme_stylebox("pressed") as StyleBoxFlat
	var hover_pressed := button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
	var disabled := button.get_theme_stylebox("disabled") as StyleBoxFlat
	assert(hover != null and hover.bg_color.is_equal_approx(StoryContinueButtonStyleClass.BACKGROUND_COLOR))
	assert(pressed != null and pressed.bg_color.is_equal_approx(StoryContinueButtonStyleClass.PRESSED_BACKGROUND_COLOR))
	assert(hover_pressed != null and hover_pressed.bg_color.is_equal_approx(StoryContinueButtonStyleClass.PRESSED_BACKGROUND_COLOR))
	assert(disabled != null and disabled.bg_color.is_equal_approx(StoryContinueButtonStyleClass.BACKGROUND_COLOR))
	for state_style in [hover, pressed, hover_pressed, disabled]:
		assert(state_style.border_color.is_equal_approx(StoryContinueButtonStyleClass.BORDER_COLOR))
		assert(state_style.border_width_left == StoryContinueButtonStyleClass.BORDER_WIDTH)
	assert(button.get_theme_stylebox("focus") is StyleBoxEmpty)
	assert(button.focus_mode == Control.FOCUS_ALL)
	assert(button.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE)
	assert(not button.toggle_mode and not button.keep_pressed_outside)
	for color_name in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		assert(button.get_theme_color(color_name).is_equal_approx(StoryContinueButtonStyleClass.FONT_COLOR))
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


func _assert_standard_dialogue_panel(panel: Control, button: Button, dialogue_text: Control) -> void:
	assert(panel.get_script() == StandardStoryDialoguePanelClass)
	var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(panel_style.bg_color.is_equal_approx(StandardStoryDialoguePanelClass.PANEL_BACKGROUND))
	assert(panel_style.border_color.is_equal_approx(StandardStoryDialoguePanelClass.PANEL_BORDER))
	assert(dialogue_text.get_theme_color("font_color").is_equal_approx(StandardStoryDialoguePanelClass.TEXT_COLOR))
	var speaker := panel.find_child("StorySpeaker", true, false) as Label
	var portrait := panel.find_child("SpeakerPortrait", true, false) as TextureRect
	assert(speaker != null and portrait != null)
	assert(speaker.get_theme_color("font_color").is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_COLOR))
	assert(speaker.position.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_POSITION))
	assert(speaker.size.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_SIZE))
	assert(speaker.get_line_height() <= speaker.size.y + 0.5)
	if portrait.is_visible_in_tree():
		assert(not portrait.get_global_rect().intersects(dialogue_text.get_global_rect()))
		assert(speaker.is_visible_in_tree())
		assert(speaker.get_global_rect().end.y <= portrait.get_global_rect().position.y + 0.5)
	assert(not button.get_global_rect().intersects(_visible_label_text_rect(dialogue_text as Label)))
	var text_label := dialogue_text as Label
	assert(text_label.get_line_count() * text_label.get_line_height() <= text_label.size.y + 0.5, "standard dialogue text is clipped: lines=%d line_height=%d size=%s text=%s" % [text_label.get_line_count(), text_label.get_line_height(), text_label.size, text_label.text])


func _prepare_overlay_for_input_check(overlay: Control) -> void:
	if overlay is HabitatAwakeningOverlay:
		overlay.waiting_for_arrival_lookaround = false
		overlay.transitioning = false
	elif overlay is SeedPodStoryOverlay:
		overlay.transitioning = false
		overlay.story_image.modulate.a = 1.0
	elif overlay is JureJureFirstEncounterOverlay:
		overlay.transitioning = false


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
	assert(game.intro_dialog_panel.get_script() == StandardStoryDialoguePanelClass)
	var greenhouse_panel_style := game.intro_dialog_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(greenhouse_panel_style != null and greenhouse_panel_style.bg_color.is_equal_approx(Color(0.97, 0.90, 0.75, 0.96)))
	assert(game.intro_continue_button.text == Localizer.text(game.language_code, "continue"))
	_assert_standard_continue_button(game.intro_continue_button, game.intro_dialog_panel, game.intro_dialogue_label, game.language_code)
	_assert_standard_dialogue_panel(game.intro_dialog_panel, game.intro_continue_button, game.intro_dialogue_label)
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


func _test_tutorial_dialog_continuation(game: Node) -> void:
	var first_play_pages := [
		{"key": "tutorial_normal_sprout", "speaker": "panda"},
		{"key": "tutorial_normal_growth", "speaker": "girl"},
		{"key": "tutorial_normal_jelly", "speaker": "armadillo"},
		{"key": "tutorial_normal_jellied", "speaker": "panda"},
		{"key": "tutorial_normal_new_panda", "speaker": "panda"},
		{"key": "tutorial_normal_new_girl", "speaker": "girl"},
	]
	for locale in Localizer.SUPPORTED_LANGUAGES:
		game._set_language(locale)
		for page_value in first_play_pages:
			var page: Dictionary = page_value
			game._show_first_play_tutorial_custom_dialog(str(page["key"]), str(page["speaker"]))
			await get_tree().process_frame
			await get_tree().process_frame
			_assert_tutorial_dialog_continue(game, locale, str(page["speaker"]))
			assert(game.tutorial_guide_message.text == Localizer.text(locale, str(page["key"])))
			game._hide_first_play_tutorial_overlay()
		for page_index in range(3):
			game.puku_buyback_tutorial_active = true
			game.puku_buyback_tutorial_index = page_index
			game._show_puku_buyback_tutorial_page()
			await get_tree().process_frame
			await get_tree().process_frame
			_assert_tutorial_dialog_continue(game, locale, "panda" if page_index < 2 else "")
			var key: String = ["puku_buyback_1", "puku_buyback_2", "puku_buyback_2_endless"][page_index]
			assert(game.tutorial_guide_message.text == Localizer.text(locale, key))
			game._hide_first_play_tutorial_overlay()
		game.puku_buyback_tutorial_active = false

	# Both visible and full-screen controls advance exactly one page. The visible
	# control is above the transparent hit area, so a real pointer event cannot
	# reach both controls on the same release.
	game._set_language("ja")
	game.first_play_tutorial_active = true
	game.first_play_tutorial_phase = "growth_dialogs"
	game.first_play_tutorial_message_index = 0
	game._show_first_play_tutorial_custom_dialog("tutorial_normal_sprout", "panda")
	var first_play_index: int = game.first_play_tutorial_message_index
	game.tutorial_continue_button.pressed.emit()
	assert(game.first_play_tutorial_message_index == first_play_index + 1)
	assert(not game.first_play_tutorial_dialog_visible)
	game.first_play_tutorial_message_index = 0
	game.first_play_tutorial_wait_remaining = 0.0
	game._show_first_play_tutorial_custom_dialog("tutorial_normal_sprout", "panda")
	game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_message_index == 1)
	assert(not game.first_play_tutorial_dialog_visible)

	game.puku_buyback_tutorial_active = true
	game.puku_buyback_tutorial_index = 0
	game._show_puku_buyback_tutorial_page()
	game.tutorial_continue_button.pressed.emit()
	assert(game.puku_buyback_tutorial_index == 1)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "puku_buyback_2"))
	game.tutorial_guide_button.pressed.emit()
	assert(game.puku_buyback_tutorial_index == 2)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "puku_buyback_2_endless"))
	game.puku_buyback_tutorial_active = false
	game._hide_first_play_tutorial_overlay()

	# Instructions that require gameplay input intentionally keep the dialogue
	# text but never show a misleading continuation action.
	game.first_play_harvest_guide_active = true
	game.tutorial_harvest_plant = null
	game._show_tutorial_harvest_spotlight()
	await get_tree().process_frame
	assert(game.tutorial_guide_overlay.visible and game.tutorial_dialog_panel.visible)
	assert(not game.tutorial_continue_button.visible and not game.tutorial_continue_button.is_visible_in_tree())
	assert(not game.tutorial_portrait_slot.visible and not game.tutorial_speaker_label.visible and game.tutorial_speaker_label.text.is_empty())
	game.first_play_harvest_guide_active = false
	game._hide_first_play_tutorial_overlay()
	game._show_tutorial_guide("play_open")
	assert(game.tutorial_guide_overlay.visible and not game.tutorial_dialog_panel.visible)
	assert(not game.tutorial_continue_button.visible)
	assert(not game.tutorial_portrait_slot.visible and not game.tutorial_speaker_label.visible and game.tutorial_speaker_label.text.is_empty())
	game._hide_first_play_tutorial_overlay()
	game.first_play_tutorial_active = false

	# The later Puku-gauge explanation uses the standard greenhouse dialogue
	# component and therefore also retains a visible continuation button.
	game.puku_gauge_intro_complete = false
	game._start_puku_gauge_intro_dialog()
	await get_tree().process_frame
	_assert_standard_continue_button(game.intro_continue_button, game.intro_dialog_panel, game.intro_dialogue_label, "ja")
	assert(game.intro_continue_button.is_visible_in_tree())
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false


func _assert_tutorial_dialog_continue(game: Node, locale: String, speaker_id: String) -> void:
	var button := game.tutorial_continue_button as Button
	var panel := game.tutorial_dialog_panel as Control
	var dialogue := game.tutorial_guide_message as Label
	var portrait_slot := game.tutorial_portrait_slot as Control
	var portrait := game.tutorial_panda_portrait as TextureRect
	var speaker := game.tutorial_speaker_label as Label
	var has_speaker := not speaker_id.is_empty()
	assert(game.tutorial_guide_overlay.visible and panel.visible)
	assert(button.visible and button.is_visible_in_tree())
	assert(panel.is_ancestor_of(button))
	assert(game.tutorial_guide_button.get_index() < panel.get_index())
	assert(str(button.get_meta("target", "")) in ["first_play_dialog", "puku_buyback"])
	_assert_standard_continue_button(button, panel, dialogue, locale)
	assert(dialogue.get_line_count() * dialogue.get_line_height() <= dialogue.size.y + 0.5, "tutorial dialogue text is clipped: locale=%s size=%s text=%s" % [locale, dialogue.size, dialogue.text])
	assert(portrait_slot.visible == has_speaker)
	assert(portrait.visible == has_speaker)
	assert(speaker.visible == has_speaker)
	if has_speaker:
		assert(portrait_slot.is_visible_in_tree() and portrait.is_visible_in_tree() and speaker.is_visible_in_tree())
		assert(speaker.text == Localizer.text(locale, "story_speaker_" + speaker_id))
		assert(speaker.position.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_POSITION))
		assert(speaker.size.y == StandardStoryDialoguePanelClass.SPEAKER_LABEL_SIZE.y)
		assert(speaker.get_theme_font_size("font_size") == 17)
		assert(speaker.get_theme_color("font_color").is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_COLOR))
		assert(speaker.get_line_height() <= speaker.size.y + 0.5)
		assert(portrait_slot.get_global_rect().grow(0.5).encloses(speaker.get_global_rect()))
		assert(portrait_slot.get_global_rect().grow(0.5).encloses(portrait.get_global_rect()))
		assert(speaker.get_global_rect().end.y <= portrait.get_global_rect().position.y + 0.5)
		assert(not portrait.get_global_rect().intersects(button.get_global_rect()))
		assert(not portrait.get_global_rect().intersects(dialogue.get_global_rect()))
	else:
		assert(speaker.text.is_empty())


func _test_ending_credit(game: Node) -> void:
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(Localizer.text(locale, "restoration_thank_you") == str(ENDING_THANKS[locale]))
		assert(Localizer.text(locale, "restoration_product_by") == ENDING_CREDIT)
		game.habitat_restoration_ui.set_language(locale)
		assert(game.habitat_restoration_ui.ending_thank_you_label.text == str(ENDING_THANKS[locale]))
		assert(game.habitat_restoration_ui.ending_product_label.text == ENDING_CREDIT)
		assert(game.habitat_restoration_ui.ending_thank_you_label.get_minimum_size().x <= game.habitat_restoration_ui.ending_thank_you_label.size.x)
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
		var expected_page_name: String = game._species_get_catalog_page_name(entry,game.language_code)
		var story_catalog_card: bool = contexts[index].begins_with("scripted_dialog_card:")
		var expected_badge: String = Localizer.text(game.language_code,"original_catalog_new" if story_catalog_card else "new")
		assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text==expected_badge)
		assert(not expected_page_name.is_empty() and game.species_get_overlay.series_label.visible and game.species_get_overlay.series_label.text==expected_page_name)
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
