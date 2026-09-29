extends Node

const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const HabitatRestorationUIClass = preload("res://scripts/habitat_restoration_ui.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")
const Localizer = preload("res://scripts/game_localizer.gd")


func _ready() -> void:
	_test_restoration_state_machine()
	_test_localization_contract()
	await _test_integrated_final_chapter()
	print("HABITAT_RESTORATION_SMOKE_OK post_crisis=7 new_gets=3 joined=true lamps=5 threshold=100 returned=5 medals=5 stages=0..5 slides=3 finale=true epilogue=true thank_you=true save_resume=true")
	get_tree().quit()


func _test_restoration_state_machine() -> void:
	var progression := StoryProgressionClass.default_runtime_state()
	StoryProgressionClass.begin_habitat_crisis(progression)
	var restoration: Dictionary = StoryProgressionClass.restoration_state(progression)
	assert(bool(restoration.get("tracking_started", false)))
	assert(not StoryProgressionClass.record_restoration_new_get(progression, "colorata", true))
	assert(not StoryProgressionClass.record_restoration_new_get(progression, "affinis", true))
	assert(StoryProgressionClass.record_restoration_new_get(progression, "shaviana", true))
	assert(HabitatRestorationClass.new_species_count(restoration) == 3)
	# The home event stays queued until the preceding post-crisis conversation
	# has actually completed.
	assert(StoryProgressionClass.peek_story_event(progression).is_empty())
	progression["post_crisis_greenhouse_pending"] = true
	StoryProgressionClass.complete_post_crisis_greenhouse(progression)
	assert(StoryProgressionClass.peek_story_event(progression) == StoryProgressionClass.EVENT_RESTORATION_JOIN_HOME)
	StoryProgressionClass.complete_restoration_join_home(progression)
	assert(bool(restoration.get("join_habitat_pending", false)))
	StoryProgressionClass.complete_restoration_join_habitat(progression)
	assert(StoryProgressionClass.restoration_is_started(progression))

	assert(not HabitatRestorationClass.can_offer_return(restoration, 99.99))
	assert(HabitatRestorationClass.can_offer_return(restoration, 100.0))
	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 100.0,
		"visual_scale": 5.9,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	# Declining is represented by not committing the offered snapshot.
	assert(HabitatRestorationClass.returned_count(restoration) == 0)
	for index in 5:
		var plant := snapshot.duplicate(true)
		plant["diameter_cm"] = 100.0 + float(index) * 20.0
		assert(HabitatRestorationClass.add_returned_plant(restoration, plant) == index + 1)
		assert(HabitatRestorationClass.pending_return_stage(restoration) == index + 1)
		if index < 4:
			HabitatRestorationClass.complete_return_event(restoration, index + 1)
	assert(HabitatRestorationClass.returned_count(restoration) == 5)
	var returned: Array = HabitatRestorationClass.returned_plants(restoration)
	assert(str(returned[0].get("species_id", "")) == "colorata")
	assert(is_equal_approx(float(returned[0].get("diameter_cm", 0.0)), 100.0))
	assert(is_equal_approx(float(returned[4].get("diameter_cm", 0.0)), 180.0))
	# The rain does not fully clear before the ending slides reveal recovery.
	assert(HabitatRestorationClass.restoration_stage(restoration) == 4)
	HabitatRestorationClass.begin_recovery_slides(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "slides")
	HabitatRestorationClass.reveal_full_recovery(restoration)
	assert(HabitatRestorationClass.restoration_stage(restoration) == 5)
	assert(HabitatRestorationClass.ending_phase(restoration) == "final")
	assert(JureJureSystemClass.habitat_bgm_key(true, true, true) == "habitat")
	HabitatRestorationClass.mark_final_dialog_complete(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "epilogue")
	HabitatRestorationClass.mark_epilogue_complete(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "thank_you")

	var reloaded := StoryProgressionClass.normalize_runtime_state(progression.duplicate(true), {
		"habitat_crisis_started": true,
	})
	var restored_state: Dictionary = StoryProgressionClass.restoration_state(reloaded)
	assert(HabitatRestorationClass.returned_count(restored_state) == 5)
	assert(HabitatRestorationClass.ending_phase(restored_state) == "thank_you")
	HabitatRestorationClass.complete_ending(restored_state)
	assert(bool(restored_state.get("ending_seen", false)))
	assert(bool(restored_state.get("thank_you_seen", false)))


func _test_localization_contract() -> void:
	var keys := [
		"post_crisis_greenhouse_armadillo_2",
		"restoration_join_home_armadillo",
		"restoration_join_mouse_hurry",
		"restoration_lamp_title",
		"restoration_return_confirm",
		"restoration_return_1_armadillo",
		"restoration_return_2_girl",
		"restoration_return_3_girl_2",
		"restoration_return_4_panda",
		"restoration_return_5_system",
		"restoration_slide_1",
		"restoration_slide_2",
		"restoration_slide_3",
		"restoration_final_girl_2",
		"restoration_epilogue_mouse",
		"restoration_thank_you",
		"restoration_product_by",
	]
	for language in ["ja", "hiragana", "en"]:
		for key in keys:
			var value := Localizer.text(language, key)
			assert(not value.is_empty() and value != key)


func _test_integrated_final_chapter() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	game._reset_progression_state()
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.play_overlay.visible = false
	game.current_mode = "greenhouse"
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_crisis_started = true
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	StoryProgressionClass.begin_habitat_crisis(game.story_progression_state)
	game.story_progression_state["post_crisis_greenhouse_pending"] = true
	game._start_post_crisis_greenhouse_event()
	assert(game.scripted_dialog_kind == "post_crisis_greenhouse")
	assert(game.scripted_dialog_pages.size() == 7)
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "育った多肉は、今までどおり原生地にぼくが持って行くよ。")
	assert(str(game.scripted_dialog_pages[6].get("text", "")) == "うん！とにかくやってみよう！")
	_finish_dialog(game)

	for species_id in ["colorata", "affinis", "shaviana"]:
		StoryProgressionClass.record_restoration_new_get(game.story_progression_state, species_id, true)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "restoration_join_home")
	assert(game.scripted_dialog_pages.size() == 3)
	# Inspect the destination scene without waiting for the production fade.
	StoryProgressionClass.complete_restoration_join_home(game.story_progression_state)
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game.current_mode = "habitat"
	game._apply_mode()
	game._start_restoration_join_habitat_event()
	assert(game.scripted_dialog_kind == "restoration_join_habitat")
	assert(game.scripted_dialog_pages.size() == 19)
	assert(str(game.scripted_dialog_pages[0].get("text", "")).begins_with("はぁー"))
	assert("早くするんだチュー" in str(game.scripted_dialog_pages[18].get("text", "")))
	StoryProgressionClass.complete_restoration_join_habitat(game.story_progression_state)
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._update_play_ui()
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))
	assert(game.habitat_restoration_ui.lamp_labels.size() == 5)
	assert(game.habitat_restoration_ui.lamp_panel.visible)

	for stage in range(1, 6):
		var pages: Array[Dictionary] = game._restoration_return_pages(stage)
		assert(pages.size() == [5, 5, 7, 7, 2][stage - 1])
	assert(str(game._restoration_return_pages(5)[0].get("text", "")) == "5株の多肉を原生地に還した！")

	var restoration: Dictionary = game._restoration_state()
	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 120.0,
		"visual_scale": 7.0,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	# A real NO decision closes the prompt and never mutates the durable count.
	game.pending_restoration_snapshot = snapshot.duplicate(true)
	game.habitat_restoration_ui.show_return_prompt(snapshot)
	game.habitat_restoration_ui._decide(false)
	assert(HabitatRestorationClass.returned_count(restoration) == 0)
	for index in 5:
		var plant := snapshot.duplicate(true)
		plant["diameter_cm"] = 100.0 + 15.0 * float(index)
		assert(HabitatRestorationClass.add_returned_plant(restoration, plant) == index + 1)
		if index < 4:
			HabitatRestorationClass.complete_return_event(restoration, index + 1)
	game.story_progression_state["restoration"] = restoration
	game.habitat_restoration_ui.update_lamps(5, true)
	for lamp in game.habitat_restoration_ui.lamp_labels:
		assert(lamp.text == "●")

	game.current_mode = "habitat"
	game._apply_mode()
	game._build_habitat_items(true)
	var medals: Array[Node] = []
	for child in game.habitat_items_root.get_children():
		if child.name.begins_with("RestorationMedalPlant"):
			medals.append(child)
	assert(medals.size() == 5)
	assert(medals[4].scale.x > medals[0].scale.x)
	game.habitat_crisis_atmosphere.activate()
	game.habitat_crisis_atmosphere.set_habitat_visible(true)
	game.habitat_crisis_atmosphere.set_restoration_stage(3)
	assert(game.habitat_crisis_atmosphere.visible)
	assert(game.habitat_items_root.find_children("RestorationWildSprout*", "Sprite3D", true, false).size() >= 1)
	HabitatRestorationClass.begin_recovery_slides(restoration)
	HabitatRestorationClass.reveal_full_recovery(restoration)
	game.habitat_crisis_atmosphere.set_restoration_stage(5)
	assert(not game.habitat_crisis_atmosphere.visible)

	game._start_restoration_final_event()
	assert(game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "戻ったね……。")
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._start_restoration_epilogue_event()
	assert(game.scripted_dialog_pages.size() == 6)
	assert("SDGs" in str(game.scripted_dialog_pages[2].get("text", "")))
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._show_restoration_thank_you()
	assert(game.habitat_restoration_ui.ending_layer.visible)
	assert(game.habitat_restoration_ui.ending_title.text.contains("ありがとう"))
	assert(game.habitat_restoration_ui.character_row.get_child_count() == 6)
	assert(game.audio_manager.current_bgm_key == "greenhouse")
	game.habitat_restoration_ui.reset_view()
	game.free()
	await get_tree().process_frame


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
