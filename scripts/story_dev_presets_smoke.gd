extends Node

const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")


func _ready() -> void:
	assert(not StoryDevPresetsClass.available(false))
	assert(StoryDevPresetsClass.available(true))
	await _test_act3_and_crisis_presets()
	await _test_restoration_and_101cm_presets()
	await _test_ending_presets()
	print("STORY_DEV_PRESETS_SMOKE_OK production_hidden=true endless_does_not_grant_debug=true explicit_debug_only=true act3_ready=true crisis_ready=7 restoration=0,4 ending=true thank_you=true harvestable_101=true")
	get_tree().quit()


func _new_game():
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	assert(game.habitat_debug_enabled)
	assert(game.story_dev_panel != null)
	assert(game.find_child("StoryDevOpen", true, false) != null)
	for preset_id in StoryDevPresetsClass.PRESET_IDS:
		assert(game.story_dev_panel.find_child("StoryPreset_%s" % preset_id, true, false) != null)
	assert(game.story_dev_panel.find_child("StoryDevSpawn101", true, false) != null)
	game.habitat_debug_enabled = false
	game._open_story_dev()
	assert(not game.story_dev_panel.visible)
	game.endless_greenhouse.configure(true)
	assert(not game._trial_dev_controls_enabled())
	game.settings_overlay.visible = true
	game._open_story_dev()
	assert(not game.story_dev_panel.visible)
	assert(game.settings_overlay.visible)
	game.habitat_debug_enabled = true
	assert(game._is_endless_greenhouse_enabled())
	game.settings_overlay.visible = true
	game._open_story_dev()
	assert(game.story_dev_panel.visible)
	assert(not game.settings_overlay.visible)
	game.story_dev_panel.close()
	return game


func _test_act3_and_crisis_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.ACT3_READY)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(game.current_mode == "greenhouse")
	assert(game._unique_fantasy_species_get_count() == 24)
	assert(game.act3_unlocked)
	assert(game.act3_intro_pending)
	assert(not game.act3_intro_seen)
	game.current_mode = "habitat"
	game.habitat_visit_id += 1
	game._apply_mode()
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "act3_intro")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	result = game._apply_story_dev_preset(StoryDevPresetsClass.CRISIS_READY)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(game.current_mode == "habitat")
	assert(game._unique_jurejure_species_get_count() == 7)
	assert(game.jurejure_battle_count == 7)
	assert(game.jurejure_battle_win_count == 7)
	assert(StoryProgressionClass.exploitation_is_started(game.story_progression_state))
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(game.story_progression_state))
	assert(not game.habitat_crisis_started)
	assert(not game.habitat_crisis_pending)
	assert(game._jurejure_reward_candidates().size() == 3)
	var reward_id: String = game._grant_jurejure_battle_reward()
	assert(not reward_id.is_empty())
	assert(game._unique_jurejure_species_get_count() == 8)
	assert(game.habitat_crisis_pending)
	assert(not game.habitat_crisis_started)
	game.current_mode = "greenhouse"
	game._apply_mode()
	game.habitat_visit_id += 1
	game.current_mode = "habitat"
	game._apply_mode()
	game._try_start_pending_story_event()
	assert(game.habitat_crisis_started)
	game.free()
	await get_tree().process_frame


func _test_restoration_and_101cm_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.RESTORATION_ZERO)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 0)
	assert(bool(game._restoration_state().get("jurejure_joined", false)))
	assert(HabitatRestorationClass.new_species_count(game._restoration_state()) == 3)
	assert(game.habitat_restoration_ui.lamp_panel.visible)
	for lamp in game.habitat_restoration_ui.lamp_labels:
		assert(lamp.text == "○")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	result = game._apply_story_dev_preset(StoryDevPresetsClass.RESTORATION_FOUR)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	var restoration: Dictionary = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(restoration) == 4)
	for index in 4:
		var snapshot: Dictionary = HabitatRestorationClass.returned_plants(restoration)[index]
		assert(not game._catalog_entry(str(snapshot.get("species_id", ""))).is_empty())
		assert(float(snapshot.get("diameter_cm", 0.0)) >= 100.0)
		assert(game.habitat_restoration_ui.lamp_labels[index].text == "●")
	assert(game.habitat_restoration_ui.lamp_labels[4].text == "○")
	game._save()
	game.free()
	await get_tree().process_frame
	game = await _new_game()
	restoration = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(restoration) == 4)
	assert(game.habitat_crisis_started)
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))

	game._spawn_story_dev_101_colorata()
	assert(game.current_mode == "greenhouse")
	assert(game.play_active)
	assert(game.plants.size() == 1)
	var plant = game.plants[0]
	assert(str(plant.data.get("species_id", "")) == "colorata")
	assert(is_equal_approx(float(plant.diameter_cm), 101.0))
	assert(plant.state == "growing")
	assert(not plant.jelly_checks_enabled)
	plant.harvest()
	assert(not game.habitat_restoration_ui.prompt_layer.visible)
	assert(HabitatRestorationClass.returned_count(restoration) == 5)
	assert(str(HabitatRestorationClass.returned_plants(restoration)[4].get("species_id", "")) == "colorata")
	assert(float(HabitatRestorationClass.returned_plants(restoration)[4].get("diameter_cm", 0.0)) >= 100.0)
	assert(HabitatRestorationClass.pending_return_stage(restoration) == 5)
	assert(game.current_mode == "greenhouse")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.result_overlay.visible)
	game._toggle_mode()
	await get_tree().create_timer(1.2).timeout
	assert(game.current_mode == "habitat")
	assert(game.scripted_dialog_kind == "restoration_return_5")
	_finish_dialog(game)
	await get_tree().create_timer(1.2).timeout
	assert(HabitatRestorationClass.ending_phase(restoration) == "slides")
	assert(game.habitat_restoration_ui.ending_layer.visible)
	game.free()
	await get_tree().process_frame


func _test_ending_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.ENDING_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 5)
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "slides")
	assert(not bool(game._restoration_state().get("full_recovery_revealed", false)))
	await get_tree().create_timer(1.2).timeout
	assert(game.habitat_restoration_ui.ending_layer.visible)
	assert(game.habitat_restoration_ui.slide_index == 0)
	game.habitat_restoration_ui._advance_ending()
	game.habitat_restoration_ui._advance_ending()
	game.habitat_restoration_ui._advance_ending()
	await get_tree().create_timer(1.0).timeout
	assert(game.scripted_dialog_kind == "restoration_final")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "restoration_epilogue")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_layer.visible)
	assert(game.habitat_restoration_ui.slide_index == 99)
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "thank_you")
	game.habitat_restoration_ui._advance_ending()
	await get_tree().process_frame
	assert(bool(game._restoration_state().get("thank_you_seen", false)))
	assert(game.finale_complete)
	assert(game.current_mode == "greenhouse")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	result = game._apply_story_dev_preset(StoryDevPresetsClass.THANK_YOU_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "thank_you")
	assert(bool(game._restoration_state().get("full_recovery_revealed", false)))
	assert(not bool(game._restoration_state().get("thank_you_seen", false)))
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_layer.visible)
	assert(game.habitat_restoration_ui.slide_index == 99)
	assert(game.audio_manager.current_bgm_key == "greenhouse")
	game.free()
	await get_tree().process_frame


func _finish_dialog(game) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
